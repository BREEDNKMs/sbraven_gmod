--[[
    Replication of Stellar Blade "NS_A_Turret_Charge" Niagara System
    - Model Bone Parent: Bip001-Head
    - Materials:
        * Outer Chromacross: sprites/MI_B_LensCircle_01_15_AfterDof
        * Inner Core Glow:   sprites/glow04_noz_gmod
--]]

local matOuter = Material("sprites/MI_B_LensCircle_01_15_AfterDof")
local matInner = Material("sprites/glow04_noz_gmod")

-- In Source bone space: X = Forward/Back, Y = Left/Right, Z = Up/Down
local newOffset = Vector(0, 15, 0)

-- Reusable global vectors and colors (Zero-GC in Think & Render)
local v_RenderPos   = Vector()
local v_DirToCam    = Vector()
local v_OffsetDir   = Vector()
local c_OuterColor  = Color(255, 102, 38, 255)
local c_InnerColor  = Color(255, 230, 180, 255)

local BOUNDS_MIN    = Vector(-500, -500, -500)
local BOUNDS_MAX    = Vector(500, 500, 500)

-- Reusable trace query for depth occlusion testing (Zero-GC)
local traceResult = {}
local traceData = {
    output = traceResult,
    mask = MASK_OPAQUE
}

function EFFECT:Init(data)
    local Pos, Ang, Scale, Time, Flags, ent = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetMagnitude(), data:GetFlags(), data:GetEntity() -- Time is in seconds, not CurTime. 
    self.CreationTime = CurTime()
    self.DieTime = Time
    
    -- Initialize tracking variables
    self.LastPos = Pos -- Start tracking position immediately

    -- Configuration & Niagara Overrides
    self.Duration = (Time and Time > 0) and Time or 1.0
    self.Scale = 1 
    self.EntityTarget = IsValid(ent) and ent or nil

    -- Bone Attachment & Local Offset
    if IsValid(ent) then
        self:SetOwner(ent)
        local headBone = ent:LookupBone("Bip001-Head")
        if headBone then
            self:FollowBone(ent, headBone)
        end
        self:SetLocalPos(newOffset)
    end

    -- Niagara User.Age override (~0.35s initial curve progression)
    self.AgeOffset = 0.35

    -- Occlusion tracking
    self.OcclusionAlpha = 1.0

    -- Apply fixed bounding box (-500 to 500 units)
    self:SetRenderBounds(BOUNDS_MIN, BOUNDS_MAX)
end

function EFFECT:Think()
    -- Check lifetime expiration
    if (CurTime() - self.CreationTime) >= self.Duration then
        return false
    end

    -- Automatically terminate if the parent entity becomes invalid (e.g. killed mid-charge)
	if !IsValid(self:GetParent()) then return false end 

    return true
end

function EFFECT:Render()
    local curTime = CurTime()
    local elapsed = curTime - self.CreationTime
    local progress = math.Clamp(elapsed / self.Duration, 0, 1)

    -- Update position directly from the bone-followed entity
    self.LastPos:Set(self:GetPos())

    -- Camera Query vector calculations
    local eye = EyePos()
    v_DirToCam:Set(eye)
    v_DirToCam:Sub(self.LastPos)
    local dist = v_DirToCam:Length()

    -- 1. Niagara Distance Culling (User.FadeDistanceNear: 4000, User.FadeDistanceFar: 8000)
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

    -- 2. Niagara User.SceneDepthOffset (30.0 units toward camera to prevent nozzle self-clipping)
    v_RenderPos:Set(self.LastPos)
    v_OffsetDir:Set(v_DirToCam)
    v_OffsetDir:Mul(30.0)
    v_RenderPos:Add(v_OffsetDir)

    -- 3. Niagara CollisionQuery: QuerySceneDepthGPU (Smooth Occlusion)
    traceData.start = eye
    traceData.endpos = v_RenderPos
    traceData.filter = self.EntityTarget
    util.TraceLine(traceData)

    local isVisible = (traceResult.Fraction >= 0.98 or not traceResult.Hit)
    local targetOcc = isVisible and 1.0 or 0.0
    self.OcclusionAlpha = math.Approach(self.OcclusionAlpha, targetOcc, FrameTime() * 14.0)

    if self.OcclusionAlpha <= 0.01 then return end

    -- 4. Niagara Curve Progression: Scale 3.0 -> 30.0 (10x growth buildup)
    local effectiveProg = math.Clamp(progress + (self.AgeOffset * (1.0 - progress) * 0.4), 0, 1)
    local curveScale = 3.0 + (27.0 * effectiveProg)

    -- 5. Niagara SBFlicker_Emitter: High frequency jitter & pulse
    local fTime = curTime * 50.0
    local flicker = 0.88 + 0.12 * (math.sin(fTime) * math.cos(fTime * 0.65))

    -- Distance-size compensation to maintain optical glare readability at long ranges
    local perspectiveFactor = math.max(1.0, dist * 0.0012)
    local finalScale = self.Scale * curveScale * flicker * perspectiveFactor

    -- 6. Color & Alpha Calculation (User.Scale Color: R=5.0, G=1.0, B=0.5, A=1.0)
    local combinedAlpha = self.OcclusionAlpha * distFade * flicker
    local outerAlpha = math.Clamp(255 * combinedAlpha, 0, 255)
    local innerAlpha = math.Clamp(255 * combinedAlpha * math.min(1.0, effectiveProg * 1.5), 0, 255)

    -- Render Outer Chromacross Flare (MI_B_LensCircle_01_15)
    c_OuterColor.a = outerAlpha
    render.SetMaterial(matOuter)
    local outerSize = finalScale * 8.0
    render.DrawSprite(v_RenderPos, outerSize, outerSize, c_OuterColor)

    -- Render Inner Core Glow (glow04_noz_gmod - hot overdriven center)
    c_InnerColor.a = innerAlpha
    render.SetMaterial(matInner)
    local innerSize = finalScale * 3.5
    render.DrawSprite(v_RenderPos, innerSize, innerSize, c_InnerColor)
end