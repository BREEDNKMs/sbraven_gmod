-- effects/eff_burst_area_sphere_scale_smooth.lua
-- Exponential smoothing scale interpolation.
-- Final scale is taken directly from data:GetScale().
-- No PARTICLE_SCALE_OVERRIDE, no max cap, and no SetMaterial calls.

local DEFAULT_LIFETIME = 2.0
local MIN_START_SCALE = 0.001
local MODEL_BOUNDING_RADIUS = 54.6953125 -- in model units (hammer units)
local DEFAULT_RAMPUP = 0.08 -- seconds to visually reach target (practical)

local ROTATION_AXIS = Vector(-0.92168778, 0.36867511, -0.12070813) -- decoded normalized axis (best-effort)
if ROTATION_AXIS:Length() == 0 then ROTATION_AXIS = Vector(0,0,1) end
ROTATION_AXIS:Normalize()

function EFFECT:Init(data) 
    -- set model (model already has refract material) 
    self:SetModel("models/stellarblade/SM_C_SliceSphere_03.mdl") 

    -- position & orientation 
    self:SetPos(data:GetOrigin()) 
    self:SetAngles(data:GetAngles() or Angle(0,0,0)) 

    -- lifetime 
    local duration = data:GetMagnitude() 
    if duration == 0 or duration == nil then duration = DEFAULT_LIFETIME end 
    self.Lifetime = duration 
    self.SpawnTime = CurTime() 

    -- target scale is directly the effect data's scale (user requested)
    local s = data:GetScale()
    if not s or s <= 0 then s = 1 end
    self.TargetScale = s

    -- start from a small non-zero scale
    self.CurrentScale = MIN_START_SCALE
    self:SetModelScale(self.CurrentScale, 0)

    -- ramp settings
    self.RampUpTime = DEFAULT_RAMPUP
    -- time constant tau: smaller tau -> faster response. Use RampUpTime/3 so ~95% reached in RampUpTime.
    if self.RampUpTime > 0 then
        self._tau = self.RampUpTime / 3.0
    else
        self._tau = 0.0001
    end

    -- render bounds scaled by target scale (model bounding radius provided in hammer units)
    local worldRadius = MODEL_BOUNDING_RADIUS * math.max(self.TargetScale, 1)
    self:SetRenderBounds(Vector(-worldRadius, -worldRadius, -worldRadius), Vector(worldRadius, worldRadius, worldRadius))

    -- color start (white, zero alpha — alpha driven by scale)
    self.Color = Color(255,255,255,0)
    self:SetColor(self.Color)

    -- rotation: use decoded rotation axis + small spin seeded from the effect's entity index (try to be deterministic-ish)
    local seed = math.max(1, math.floor((data:GetEntity() and IsValid(data:GetEntity()) and data:GetEntity():EntIndex()) or CurTime() * 1000) )
    -- util.SharedRandom is deterministic by-key; include seed for variation
    local spinBase = util.SharedRandom("burst_spin_base", 0, 360, true) + (seed % 360)
    self.SpinRate = util.SharedRandom("burst_spin_rate", 20, 90, true) -- degrees per second
    self.InitialSpin = spinBase
    self:SetLocalAngularVelocity(ROTATION_AXIS:Angle()) 

    -- timing for scale ramp and fade
    self.RampUpTime = 0.08 -- quick scale-up (~0.08s matching Niagara)
    self.FadeOutStartNorm = 0.7 -- start fading at 70% of life
    self.FadeOutDurNorm = 0.3 -- fade-out over last 30%

    -- cache some values for speed
    self.NextThink = 0
	self:SetRenderMode(1) 
end

-- Exponential smoothing helper:
-- dt = frame time, tau = time constant
-- alpha = 1 - exp(-dt / tau)
-- new = old + (target - old) * alpha
local function exp_smooth(current, target, dt, tau)
    if tau <= 0 or dt <= 0 then
        return target
    end
    local alpha = 1 - math.exp(-dt / tau)
    return current + (target - current) * alpha
end

function EFFECT:Think()
	local now = CurTime()
	local elapsed = now - self.SpawnTime
	local ageNorm = math.Clamp(elapsed / self.Lifetime, 0, 1)
	if ageNorm >= 1 then
		Material("sprites/ma_c_rrfecationsphere_01_1"):SetUndefined("$SilhouetteThickness",newAlpha) 
		return false
	end

	local dt = FrameTime()
	-- update scale using exponential smoothing (frame-rate independent)
	if self.TargetScale and self.TargetScale > 0 then
		self.CurrentScale = exp_smooth(self.CurrentScale, self.TargetScale, dt, self._tau)
	else
		self.CurrentScale = exp_smooth(self.CurrentScale, MIN_START_SCALE, dt, self._tau)
	end

	-- apply the computed model scale
	if self.CurrentScale <= 0 then self.CurrentScale = MIN_START_SCALE end
	self:SetModelScale(self.CurrentScale, 0)
	
	local spinAngle = (self.InitialSpin + (elapsed * self.SpinRate)) % 360
	local axisAng = self:GetLocalAngularVelocity() -- angle representing axis direction
	local totalAng = Angle(axisAng.p, axisAng.y, axisAng.r)
	totalAng:RotateAroundAxis(ROTATION_AXIS, spinAngle)
	-- self:SetAngles(totalAng)
	-- self:SetLocalAngularVelocity(AngleRand()) 
	self:InvalidateBoneCache() 
	self:SetupBones() 

	-- alpha envelope tied to scale: alpha follows CurrentScale / TargetScale for consistent visual
	local fadeInRatio = 0
	if self.TargetScale > 0 then
		fadeInRatio = math.Clamp(self.CurrentScale / self.TargetScale, 0, 1)
	end
	local alpha = 255 * fadeInRatio

	-- fade-out starting at 70% normalized life
	if ageNorm >= 0.7 then
		local t = math.Clamp((ageNorm - 0.7) / 0.3, 0, 1)
		alpha = alpha * (1 - t)
	end
	self.Color.a = math.floor(math.Clamp(alpha, 0, 255))
	self:SetColor(self.Color) 
	local newAlpha = math.Remap(self.Color.a,255,0,0,2) 
	self:SetCycle(ageNorm) 
	ageNorm = math.Remap(ageNorm,0,1,0,2) 
	-- the velocity isn't here to move sphere around 
	-- local tempVel = self:GetForward()-(self:GetForward()*(ageNorm*1)) 
	-- tempVel = tempVel * 0.035 
	-- print(ageNorm,self.Color) 
	-- self:SetLocalVelocity(tempVel) -- it sets a material proxy which makes sphere age 
	self:SetNextClientThink(CurTime()+FrameTime()) 
	Material("sprites/ma_c_rrfecationsphere_01_1"):SetFloat("$SilhouetteThickness",newAlpha) 
	-- Material("sprites/ma_c_rrfecationsphere_01_1"):SetUndefined("$SilhouetteColor",Vector(self.Color.r,self.Color.g,self.Color.b)) 
    return true
end