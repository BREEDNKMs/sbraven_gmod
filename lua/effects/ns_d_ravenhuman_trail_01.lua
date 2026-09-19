-- ns_d_ravenhuman_trail_01.lua
-- Recreated Cyro Blade Ribbon Effect inspired by Stellar Blade

local MAT_MAIN_RIBBON  = Material("sprites/mi_d_ravenhuman_ribbon_02")
local MAT_BLADE_EDGE   = Material("sprites/mi_d_raven_ribbon_01")
local MAT_SPARKS = {
    "sprites/MI_A_GPUSparks_01_Tr_000",
    "sprites/MI_A_GPUSparks_01_Tr_001",
    "sprites/MI_A_GPUSparks_01_Tr_002",
    "sprites/MI_A_GPUSparks_01_Tr_003"
}

-- ------------------------------------------------------------------
-- Helpers & Math
-- ------------------------------------------------------------------
local function CatmullRom(p0, p1, p2, p3, t)
    local t2 = t * t
    local t3 = t2 * t
    return 0.5 * (
        (2 * p1) +
        (-p0 + p2) * t +
        (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
        (-p0 + 3 * p1 - 3 * p2 + p3) * t3
    )
end

local function TransformUV(u, v, centerX, centerY, scaleX, scaleY, rotateDeg, transX, transY)
    centerX = centerX or 0.5
    centerY = centerY or 0.5
    scaleX  = scaleX  or 1
    scaleY  = scaleY  or 1
    rotateDeg = rotateDeg or 0
    transX = transX or 0
    transY = transY or 0

    local x = (u - centerX) * scaleX
    local y = (v - centerY) * scaleY

    local rad = math.rad(rotateDeg)
    local cosT = math.cos(rad)
    local sinT = math.sin(rad)
    local xr = x * cosT - y * sinT
    local yr = x * sinT + y * cosT

    return xr + centerX + transX, yr + centerY + transY
end

-- Particle update logic for cryo sparks
local function CryoSparkUpdate(particle)
    local life = particle:GetLifeTime()
    local die  = particle:GetDieTime()
    local nAge = life / die

    -- Air drag ramping
    particle:SetAirResistance(5 + (nAge * 35))

    -- Stellar Blade Cryo palette: White -> Cyan -> Sapphire -> Dark
    local r, g, b
    if nAge < 0.3 then
        local t = nAge / 0.3
        r = Lerp(t, 255, 80)
        g = Lerp(t, 255, 230)
        b = 255
    else
        local t = (nAge - 0.3) / 0.7
        r = Lerp(t, 80, 10)
        g = Lerp(t, 230, 80)
        b = Lerp(t, 255, 200)
    end
    particle:SetColor(r, g, b)

    -- Alpha fade
    local alpha = 255
    if nAge < 0.1 then
        alpha = Lerp(nAge * 10, 0, 255)
    elseif nAge > 0.6 then
        alpha = Lerp((nAge - 0.6) / 0.4, 255, 0)
    end
    particle:SetStartAlpha(alpha)

    -- Pseudo-curl noise turbulence
    local pos = particle:GetPos()
    local t = CurTime() * 3.0
    local freq = 0.04
    local amp = 150 * (1 - nAge)

    local noiseX = math.sin(pos.y * freq + t) - math.cos(pos.z * freq + t)
    local noiseY = math.sin(pos.z * freq + t) - math.cos(pos.x * freq + t)
    local noiseZ = math.sin(pos.x * freq + t) - math.cos(pos.y * freq + t)

    particle:SetVelocity(particle:GetVelocity() + Vector(noiseX, noiseY, noiseZ) * amp * FrameTime())
    particle:SetNextThink(CurTime())
end

-- ------------------------------------------------------------------
-- EFFECT Core
-- ------------------------------------------------------------------
function EFFECT:Init(data)
    self.Entity = data:GetEntity()
    if not IsValid(self.Entity) then return end
	
	self:SetParent(self.Entity) 

    -- Initialize lifetime according to data:GetMagnitude()
    local mag = data:GetMagnitude()
    self.Lifetime = (mag and mag > 0.02) and mag or 0.38

    self.Scale = math.max(0.01, data:GetScale() or 1.0)
    self.CreationTime = CurTime()
    self.SpawnEndTime = self.CreationTime + self.Lifetime
    self.Spawning = true

    -- Two-point trail storage
    self.TrailPoints = {}
    self.TotalLength = 0

    local basePos, tipPos = self:GetBladePositions()
    self.LastBase = basePos or self.Entity:GetPos()
    self.LastTip  = tipPos  or (self.LastBase + Vector(0, 0, -100))

    self.Emitter = ParticleEmitter(self.LastTip, false)
    self:AddTrailPoint(self.LastBase, self.LastTip)

    self:SetRenderBounds(Vector(-1024, -1024, -1024), Vector(1024, 1024, 1024))
end

function EFFECT:GetRenderEntity()
    if not IsValid(self.Entity) then return nil end

    if self.Entity:IsWeapon() then
        local owner = self.Entity:GetOwner()
        if IsValid(owner) and owner:IsPlayer() and owner == LocalPlayer() and not owner:ShouldDrawLocalPlayer() then
            local vm = owner:GetViewModel()
            if IsValid(vm) then return vm end
        end
    end

    return self.Entity
end

function EFFECT:GetBladePositions()
    local ent = self:GetRenderEntity()
    if not IsValid(ent) then return nil, nil end

    -- Base: ValveBiped.Bip01_R_Hand position
    -- Tip: pos + up * -100
    local boneIdx = ent:LookupBone("ValveBiped.Bip01_R_Hand")
    if boneIdx then
        local m = ent:GetBoneMatrix(boneIdx)
        if m then
            local pos = m:GetTranslation()
            local up = m:GetUp()
            if pos and up then
                return pos, pos + up * -100
            end
        end
    end

    -- Fallback
    local fallbackPos = ent:EyePos()
    local fallbackUp = ent:GetUp()
    return fallbackPos, fallbackPos + fallbackUp * -100
end

function EFFECT:AddTrailPoint(basePos, tipPos)
    local segLen = self.LastTip:Distance(tipPos)
    self.TotalLength = self.TotalLength + segLen

    table.insert(self.TrailPoints, 1, {
        base = basePos,
        tip = tipPos,
        timestamp = CurTime(),
        dist = self.TotalLength
    })

    self.LastBase = basePos
    self.LastTip = tipPos
end

function EFFECT:Think()
    if not IsValid(self.Entity) then return false end

    local now = CurTime()
    if self.Spawning and now >= self.SpawnEndTime then
        self.Spawning = false
    end

    local curBase, curTip = self:GetBladePositions()
    if curBase and curTip then
        -- Add point if blade moved
        if self.Spawning then
            if curTip:DistToSqr(self.LastTip) > 1.0 or curBase:DistToSqr(self.LastBase) > 1.0 then
                self:AddTrailPoint(curBase, curTip)
                self:SpawnSparks(curBase, curTip)
            end
        else
            self.LastBase = curBase
            self.LastTip  = curTip
        end
    end

    -- Prune points exceeding lifetime
    for i = #self.TrailPoints, 1, -1 do
        if (now - self.TrailPoints[i].timestamp) > self.Lifetime then
            table.remove(self.TrailPoints, i)
        end
    end

    -- Die when points are gone and emission stopped
    if #self.TrailPoints == 0 and not self.Spawning then
        if self.Emitter then
            self.Emitter:Finish()
        end
        return false
    end

    return true
end

function EFFECT:SpawnSparks(basePos, tipPos)
    if !IsValid(self.Emitter) then return end

    local tipDelta = tipPos - self.LastTip
    local speed = tipDelta:Length() / math.max(FrameTime(), 0.001)
    -- if speed < 12 then return end -- Only spawn sparks on deliberate swings

    local sparkCount = math.random(1,4) 
    local bladeDir = (tipPos - basePos):GetNormalized()

    for i = 1, sparkCount do
		print("sparkCount",i,sparkCount) 
        -- Bias particle distribution toward the fast-moving tip
        local frac = math.Rand(0.4, 1.0)
        local spawnPos = LerpVector(frac, basePos, tipPos)

        local p = self.Emitter:Add("effects/spark", spawnPos)
        if p then
            p:SetDieTime(math.Rand(0.3, 0.7))
            
            -- Inherit blade angular velocity + outward centrifugal spread
            local spread = VectorRand() * 25 + bladeDir * math.Rand(20, 80)
            p:SetVelocity((tipDelta * 0.4) + spread)

            local pSize = math.Rand(2.0, 4.0) * self.Scale
            p:SetStartSize(pSize)
            p:SetEndSize(0)
            p:SetStartLength(pSize * 0.8)
            p:SetEndLength(0)
            p:SetVelocityScale(true)

            p:SetThinkFunction(CryoSparkUpdate)
            p:SetNextThink(CurTime())
        end
    end
end

-- Generates a Catmull-Rom smoothed chain of blade coordinates
function EFFECT:GetSmoothedTrail(subdivisions)
    local raw = self.TrailPoints
    local count = #raw
    if count < 2 then return raw end

    local smoothed = {}
    subdivisions = subdivisions or 3

    for i = 1, count - 1 do
        local p0 = raw[math.max(i - 1, 1)]
        local p1 = raw[i]
        local p2 = raw[i + 1]
        local p3 = raw[math.min(i + 2, count)]

        local dist = p1.tip:Distance(p2.tip)
        local steps = (dist > 8) and subdivisions or 1

        for s = 0, steps - 1 do
            local t = s / steps
            table.insert(smoothed, {
                base = CatmullRom(p0.base, p1.base, p2.base, p3.base, t),
                tip  = CatmullRom(p0.tip, p1.tip, p2.tip, p3.tip, t),
                timestamp = Lerp(t, p1.timestamp, p2.timestamp),
                dist = Lerp(t, p1.dist, p2.dist)
            })
        end
    end

    table.insert(smoothed, raw[count])
    return smoothed
end

local MAT_REFRACT = Material("effects/hunterphysblast")

-- ------------------------------------------------------------------
-- RENDER
-- ------------------------------------------------------------------
function EFFECT:Render()
    if #self.TrailPoints < 2 then return end

    local smoothed = self:GetSmoothedTrail(3)
    if #smoothed < 2 then return end
	
	-- Pass 1: Distortion/Refraction (distorts the world behind the cut)
    self:RenderRefract(smoothed)

    -- Pass 2: Main Cryo Swirling Body (Full blade surface)
    self:RenderCryoBody(smoothed)

    -- Pass 3: Sharp White-Hot Cutting Rim (Concentrated at the blade tip)
    self:RenderCuttingEdge(smoothed)
end

-- ------------------------------------------------------------------
-- RENDER PASS: Cryo Distortion / Refract Ribbon
-- ------------------------------------------------------------------
function EFFECT:RenderRefract(pts)
    -- Update the screen refraction texture so the distortion samples the current frame
    render.UpdateRefractTexture()
    render.SetMaterial(MAT_REFRACT)

    local vertCount = #pts * 2
    mesh.Begin(MATERIAL_TRIANGLE_STRIP, vertCount)

    local now = CurTime()
    local refractLifetime = self.Lifetime * 0.85 -- How long distortion lingers
    local tilingLength = 300.0

    for i = 1, #pts do
        local seg = pts[i]
        local age = math.Clamp((now - seg.timestamp) / refractLifetime, 0, 1)
        
        -- Geometric fade: 1.0 (full blade length) -> 0.0 (collapsed to tip)
        local shrink = (1 - age) ^ 1.2

        -- Scale the ribbon's length down towards the tip over time
        local innerPos = LerpVector(1 - shrink, seg.base, seg.tip)
        local outerPos = seg.tip

        local u = seg.dist / tilingLength

        -- Inner edge (sampled at V = 0.0)
        mesh.Position(innerPos)
        mesh.TexCoord(0, u, 0.0)
        mesh.Color(255, 255, 255, 255)
        mesh.AdvanceVertex()

        -- Tip edge (sampled at V = 0.5: renders half the normal map)
        mesh.Position(outerPos)
        mesh.TexCoord(0, u, 0.5)
        mesh.Color(255, 255, 255, 255)
        mesh.AdvanceVertex()
    end

    mesh.End()
end

function EFFECT:RenderCryoBody(pts)
    render.SetMaterial(MAT_MAIN_RIBBON)

    local vertCount = #pts * 2
    mesh.Begin(MATERIAL_TRIANGLE_STRIP, vertCount)

    local now = CurTime()
    local lifeTime = self.Lifetime
    local tilingLength = 220.0

    for i = 1, #pts do
        local seg = pts[i]
        local age = math.Clamp((now - seg.timestamp) / lifeTime, 0, 1)
        local invAge = 1 - age

        -- Alpha envelope
        local alpha = math.sin(invAge * math.pi * 0.5) * (invAge ^ 0.6)
        local aByte = math.floor(math.Clamp(alpha * 230, 0, 255))

        -- Color: Sapphire at base to Cryo Cyan at tip
        local baseR, baseG, baseB = 10, 60, 200
        local tipR,  tipG,  tipB  = 60, 220, 255

        -- UV mapping: U along the cut arc, V across hilt-to-tip
        local u = seg.dist / tilingLength
        local tuA, tvA = TransformUV(u, 0.0, 0.5, 0.5, 1, 1, 0, 0, 0)
        local tuB, tvB = TransformUV(u, 1.0, 0.5, 0.5, 1, 1, 0, 0, 0)

        -- Vertex 1: Blade Hilt
        mesh.Position(seg.base)
        mesh.TexCoord(0, tuA, tvA)
        mesh.Color(baseR, baseG, baseB, aByte)
        mesh.AdvanceVertex()

        -- Vertex 2: Blade Tip
        mesh.Position(seg.tip)
        mesh.TexCoord(0, tuB, tvB)
        mesh.Color(tipR, tipG, tipB, aByte)
        mesh.AdvanceVertex()
    end

    mesh.End()
end

function EFFECT:RenderCuttingEdge(pts)
    render.SetMaterial(MAT_BLADE_EDGE)

    local vertCount = #pts * 2
    mesh.Begin(MATERIAL_TRIANGLE_STRIP, vertCount)

    local now = CurTime()
    local edgeLifetime = self.Lifetime * 0.7 -- Dissolves faster than the ice body
    local tilingLength = 140.0

    for i = 1, #pts do
        local seg = pts[i]
        local age = math.Clamp((now - seg.timestamp) / edgeLifetime, 0, 1)
        local invAge = 1 - age

        -- Sharp, glowing leading arc
        local alpha = math.Clamp((invAge ^ 1.8) * 255, 0, 255)

        -- Make edge extremely thin (outer 3% of the blade = ~3 units)
        -- In Stellar Blade, the white cutting arc is a razor line, not a wide ribbon
        local edgeInner = LerpVector(0.9, seg.base, seg.tip)
        local edgeOuter = seg.tip

        local u = seg.dist / tilingLength
		
		-- KEY FIX 2: UV alignment so the center-bright beam texture (Image 3) sits right on the edge
        -- We map V=0.0 to the inner border and V=0.5 (the peak white core of Image 3) to the tip
        local vInner = 0.1
        local vOuter = 0.5 
		
        -- local tuA, tvA = TransformUV(u, 0.0, 0.5, 0.5, 1, 1, 0, 0, 0)
        -- local tuB, tvB = TransformUV(u, 1.0, 0.5, 0.5, 1, 1, 0, 0, 0)

        -- Vertex 1: Inner boundary (Electric Cyan)
        mesh.Position(edgeInner)
        -- mesh.TexCoord(0, tuA, tvA)
        mesh.TexCoord(0, u, vInner)
        mesh.Color(0, 200, 255, math.floor(alpha * 0.8))
        mesh.AdvanceVertex()

        -- Vertex 2: Blade Tip (Searing White Core)
        mesh.Position(edgeOuter)
        -- mesh.TexCoord(0, tuB, tvB)
        mesh.TexCoord(0, u, vOuter)
        mesh.Color(255, 255, 255, math.floor(alpha))
        mesh.AdvanceVertex()
    end

    mesh.End()
end