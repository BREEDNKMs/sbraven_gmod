--[[
    Replication of Stellar Blade "NS_A_Turret_Fire" Niagara System
    - Model Bone Parent: Bip001-Head
    - Materials:
        * Core Glow:        sprites/glow04_noz_gmod
        * Lens Flare:       sprites/MI_B_LensCircle_01_15_AfterDof
        * Smoke Particles:  particle/smokesprites_0001 - 0016
        * Muzzle Sparks:    effects/yellowflare
--]]

-- Pre-cache Materials at file-scope (Zero runtime allocations)
local matInner = Material("sprites/glow04_noz_gmod")
local matOuter = Material("sprites/MI_B_LensCircle_01_15_AfterDof")
local matSpark = Material("effects/yellowflare")

local SmokeMats = {}
for i = 1, 16 do
    SmokeMats[i] = Material(string.format("particle/smokesprites_%04d", i))
end

-- >>> DEFINE YOUR LOCAL OFFSET RELATIVE TO Bip001-Head HERE <<<
-- Match this with your NS_A_Turret_Charge offset
local newOffset = Vector(0, 15, 0)

-- Reusable global vectors and colors (Zero-GC in Think & Render)
local v_RenderPos   = Vector()
local v_DirToCam    = Vector()
local v_OffsetDir   = Vector()
local v_MuzzleDir   = Vector()
local c_OuterColor  = Color(255, 105, 30, 255)
local c_InnerColor  = Color(255, 240, 200, 255)

local BOUNDS_MIN    = Vector(-500, -500, -500)
local BOUNDS_MAX    = Vector(500, 500, 500)

-- Reusable trace query for depth occlusion testing
local traceResult = {}
local traceData = {
    output = traceResult,
    mask = MASK_OPAQUE
}

function EFFECT:Init(data)
    local Pos, Ang, Scale, Flags, ent = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetFlags(), data:GetEntity()
    local Normal = Ang:Forward() 

    self.CreationTime = CurTime()
    self.Duration = 0.25 -- Total duration of optical flash & muzzle burst
    self.Scale = 1
    self.EntityTarget = IsValid(ent) and ent or nil

    -- Start tracking position immediately
    self.LastPos = Pos

    -- Determine Muzzle Forward Direction
    if Normal and Normal:LengthSqr() > 0.01 then
        v_MuzzleDir:Set(Normal)
    elseif IsValid(ent) then
        v_MuzzleDir:Set(ent:GetForward())
    else
        v_MuzzleDir:Set(Ang:Forward())
    end

    -- Bone Attachment & Local Offset
    if IsValid(ent) then
        self:SetOwner(ent)
        local headBone = ent:LookupBone("Bip001-Head")
        if headBone then
            self:FollowBone(ent, headBone)
        end
        self:SetLocalPos(newOffset)
    end
	Pos = self:GetPos() -- the new position after boneparenting 

    -- Initial Occlusion state
    self.OcclusionAlpha = 1.0
    self:SetRenderBounds(BOUNDS_MIN, BOUNDS_MAX)

    -- Dynamic Muzzle Light
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = Pos
        dlight.r = 255
        dlight.g = 130
        dlight.b = 40
        dlight.brightness = 5.0
        dlight.Decay = 2500
        dlight.Size = 450 * self.Scale
        dlight.DieTime = CurTime() + 0.12
    end

    -- -------------------------------------------------------------
    -- C++ PARTICLE EMISSION (NE_ExplosionM & NE_SparkM)
    -- Handled via internal engine particle system; 0 Lua garbage per-frame
    -- -------------------------------------------------------------
    local emitter = ParticleEmitter(Pos, false)
    if emitter then
        -- 1. NE_ExplosionM: Fiery Core Explosion Puffs
        for i = 1, 5 do
            local p = emitter:Add(SmokeMats[math.random(1, 16)], Pos)
            if p then
                p:SetVelocity(v_MuzzleDir * math.Rand(180, 420) + VectorRand() * 60)
                p:SetDieTime(math.Rand(0.45, 0.75))
                p:SetStartAlpha(math.Rand(200, 240))
                p:SetEndAlpha(0)
                -- 16x expansion matching Niagara Vector2DCurve (0.5 -> 8.0)
                p:SetStartSize(math.Rand(18, 28) * self.Scale)
                p:SetEndSize(math.Rand(120, 180) * self.Scale)
                p:SetRoll(math.Rand(-180, 180))
                p:SetRollDelta(math.Rand(-2.0, 2.0))
                p:SetAirResistance(1)
                p:SetGravity(Vector(0, 0, 35))
                p:SetColor(255, 160, 50) -- Fiery emissive start
            end
        end

        -- 2. NE_ExplosionM: Lingering Dissipating Smoke Puffs
        for i = 1, 6 do
            local p = emitter:Add(SmokeMats[math.random(1, 16)], Pos)
            if p then
                p:SetVelocity(v_MuzzleDir * math.Rand(80, 260) + VectorRand() * 50)
                p:SetDieTime(math.Rand(0.7, 1.2))
                p:SetStartAlpha(130)
                p:SetEndAlpha(0)
                p:SetStartSize(math.Rand(20, 32) * self.Scale)
                p:SetEndSize(math.Rand(140, 220) * self.Scale)
                p:SetRoll(math.Rand(-180, 180))
                p:SetRollDelta(math.Rand(-1.0, 1.0))
                p:SetAirResistance(1)
                p:SetGravity(Vector(0, 0, 25))
                p:SetColor(115, 100, 85) -- Sandy desert dust tone
            end
        end

        -- 3. NE_SparkM: High-Velocity Plasma Sparks / Ejecta
        for i = 1, 50 do
            local p = emitter:Add(matSpark, Pos)
            if p then
                p:SetVelocity(v_MuzzleDir * math.Rand(600, 1400) + VectorRand() * 220)
                p:SetDieTime(math.Rand(0.12, 1.22))
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(math.Rand(6, 10) * self.Scale)
                p:SetEndSize(0)
                p:SetStartLength(math.Rand(15, 30) * self.Scale)
                p:SetEndLength(0)
                p:SetColor(255, 210, 120)
            end
        end

        emitter:Finish()
    end
end

function EFFECT:Think()
    if (CurTime() - self.CreationTime) >= self.Duration then
        return false
    end

    if self.EntityTarget and not self.EntityTarget:IsValid() then
        return false
    end

    return true
end

function EFFECT:Render()
    local elapsed = CurTime() - self.CreationTime
    local progress = math.Clamp(elapsed / self.Duration, 0, 1)

    -- Retrieve current world position from bone parent
    self.LastPos:Set(self:GetPos())

    -- Camera Query Vector Calculations
    local eye = EyePos()
    v_DirToCam:Set(eye)
    v_DirToCam:Sub(self.LastPos)
    local dist = v_DirToCam:Length()

    -- 1. Niagara Distance Culling (Near: 4000, Far: 8000)
    if dist >= 8000 then return end

    local distFade = 1.0
    if dist > 4000 then
        distFade = 1.0 - ((dist - 4000) / 4000)
    end

    -- Normalize view direction
    if dist > 0.001 then
        v_DirToCam:Mul(1 / dist)
    else
        v_DirToCam:SetUnpacked(0, 0, 1)
    end

    -- 2. Scene Depth Offset (30 units forward to avoid muzzle geometry clipping)
    v_RenderPos:Set(self.LastPos)
    v_OffsetDir:Set(v_DirToCam)
    v_OffsetDir:Mul(30.0)
    v_RenderPos:Add(v_OffsetDir)

    -- 3. Collision Query: Scene Depth Occlusion Check
    traceData.start = eye
    traceData.endpos = v_RenderPos
    traceData.filter = self.EntityTarget
    util.TraceLine(traceData)

    local isVisible = (traceResult.Fraction >= 0.98 or not traceResult.Hit)
    local targetOcc = isVisible and 1.0 or 0.0
    self.OcclusionAlpha = math.Approach(self.OcclusionAlpha, targetOcc, FrameTime() * 20.0)

    if self.OcclusionAlpha <= 0.01 then return end

    -- 4. Niagara Curve Replications:
    -- Scale Factor Curve: Ramps 0.5 -> 1.0 in first 20%, then rapidly falls to 0.0
    local flareScale
    if progress < 0.2 then
        flareScale = Lerp(progress / 0.2, 0.5, 1.0)
    else
        flareScale = Lerp((progress - 0.2) / 0.8, 1.0, 0.0)
    end

    -- Perspective compensation for long-range readability across the desert
    local perspectiveFactor = math.max(1.0, dist * 0.0014)
    local finalScale = self.Scale * flareScale * perspectiveFactor

    -- 5. Alpha fading
    local alphaFade = (1.0 - progress) * self.OcclusionAlpha * distFade
    local outerAlpha = math.Clamp(255 * alphaFade, 0, 255)
    local innerAlpha = math.Clamp(255 * alphaFade * 1.2, 0, 255)

    -- Render Outer Chromacross Lens Flare (MI_B_LensCircle_01_15)
    c_OuterColor.a = outerAlpha
    render.SetMaterial(matOuter)
    local outerSize = finalScale * 65.0
    render.DrawSprite(v_RenderPos, outerSize, outerSize, c_OuterColor)

    -- Render Core Muzzle Flash Glow (glow04_noz_gmod)
    c_InnerColor.a = innerAlpha
    render.SetMaterial(matInner)
    local innerSize = finalScale * 38.0
    render.DrawSprite(v_RenderPos, innerSize, innerSize, c_InnerColor)
end