-- effects/eff_burst_area_sphere_scale_smooth.lua
-- Exponential smoothing scale interpolation.
-- Final scale is taken directly from data:GetScale().
-- No PARTICLE_SCALE_OVERRIDE, no max cap, and no SetMaterial calls.
-- radius is 1200 

local DEFAULT_LIFETIME = 2.74 
local MIN_START_SCALE = 0.001
local MODEL_BOUNDING_RADIUS = 54.6953125/0.42 -- in model units (hammer units)
local DEFAULT_RAMPUP = 0.08 -- seconds to visually reach target (practical)

local ROTATION_AXIS = Vector(-0.92168778, 0.36867511, -0.12070813) -- decoded normalized axis (best-effort)
if ROTATION_AXIS:Length() == 0 then ROTATION_AXIS = Vector(0,0,1) end
ROTATION_AXIS:Normalize() 

-- beams 
local LASER_MAT = Material("sprites/bluelaser1") -- sprite path (vmt)
local UP_OFFSET = 300 -- beams always start 300 units above origin
local SPAWN_WINDOW = 0.2 -- all beams spawn within 0.1 seconds

local slashtime, slashinterval = 0.73852539059999, 0.26953481408759 
EFFECT.BurstAreaSlash_Slash = false 

function EFFECT:Init(data) 
    -- set model (model already has refract material) 
    self:SetModel("models/stellarblade/SM_C_SliceSphere_03.mdl") 
	print("ns_a_burstarea_1 appeared at:",CurTime()) 

    -- position & orientation 
    -- self:SetPos(data:GetOrigin()) 
    self:SetAngles(data:GetAngles() or Angle(0,0,0)) 

    -- lifetime 
    local duration = data:GetMagnitude() 
    if duration == 0 then duration = DEFAULT_LIFETIME end 
    self.DieTime = duration 
    self.CreationTime = CurTime() 

    -- target scale is directly the effect data's scale (user requested)
    local s = data:GetScale()
    if !s or s <= 0 then s = 1 end
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

	self:SetRenderMode(1) 
	
	self:Beams_Init(data) 
	self.Emitter = ParticleEmitter(self:GetPos(),false) 
	
end 

function EFFECT:Beams_Init(data) 
    self.Beams = {}

    for i = 1, 50 do
        -- random XY offset around origin in range [-200,200]
        local off = Vector(
            math.Rand(-1200, 1200),
            math.Rand(-1200, 1200),
            0
        )

        local topPos = self:GetPos() + off + Vector(0, 0, UP_OFFSET)
		
		off = Vector(
            math.Rand(-512, 512),
            math.Rand(-512, 512),
            0
        )

        -- trace down to find the surface
		
        local tr = util.TraceLine{
            start = topPos,
            endpos = self:GetPos() + Vector(0,0,-200) + off,
            collisiongroup = COLLISION_GROUP_WORLD, 
            mask = MASK_SOLID_BRUSHONLY -- world geometry; change to MASK_SOLID if you want props too
        }

        -- if we didn't hit, fallback to a fixed length
        local hitPos = tr.Hit and tr.HitPos or (topPos + Vector(0,0,-300))
        local surfaceLen = math.abs(topPos.z - hitPos.z)
        if surfaceLen <= 0 then surfaceLen = 300 end

        -- extend an equal length below the surface to "penetrate"
        local endPos = hitPos + Vector(0, 0, -surfaceLen)

        -- per-beam spawn delay (0..SPAWN_WINDOW)
        local spawnDelay = math.Rand(0, SPAWN_WINDOW)

        -- per-beam DieTime (1..2 sec)
        local life = slashtime+0.1
        local width = 70

        table.insert(self.Beams, {
            Top = topPos,
            Hit = hitPos,
            End = endPos,
			TraceResult = tr, 
            SpawnDelay = spawnDelay,
            DieTime = life,
            Spawned = false,
            CreationTime = 0,
            ExpireTime = 0,
            Width = width,
            Alpha = 255
        })
    end

    -- track if we're finished
    self.Finished = false
end 

function EFFECT:Beams_SlashSparks() 
	for BeamIndex, BeamTable in ipairs(self.Beams) do 
		local Length = BeamTable.Top:Length(Hit) 
		for i = 1, Length, 5 do 
			local SpawnPos = BeamTable.Top + (BeamTable.TraceResult.Normal*i) 
			local p = self.Emitter:Add("sprites/mi_d_raven_goldparts_1",SpawnPos) 
			p:SetAngleVelocity(AngleRand()) 
			p:SetBounce(0.5) 
			p:SetCollide(true) 
			p:SetDieTime(math.random()*7) 
			p:SetEndSize(0) 
			-- p:SetGravity(Vector(0,0,-50)) 
			p:SetColor(math.random()*255,255,255) 
			p:SetStartSize(2) 
			p:SetVelocity(VectorRand()*10) 
			p:SetThinkFunction(function(p) 
				if math.random() > 0.95 then 
					if p:GetGravity() != Vector(0,0,-50) then 
						p:SetGravity(Vector(0,0,-50)) 
					end 
				end 
				p:SetNextThink(CurTime()) 
			end) 
			p:SetNextThink(CurTime()) 
		end 
	end 
	-- self.BurstAreaSlash_Slash = true 
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

function EFFECT:Beams_Think() 
	local now = CurTime()
    local allDone = true
	local Cycle = (now - self.CreationTime) / self.DieTime 
	-- define the windows for inflate/deflate
	local inflateStart, inflateEnd = 0.80, 0.90
	local deflateStart, deflateEnd = 0.90, 1.00

    for _, b in ipairs(self.Beams) do
        -- spawn logic
        if !b.Spawned then
            if now >= self.CreationTime + b.SpawnDelay then
                b.Spawned = true
                b.SpawnTime = now
                b.ExpireTime = now + b.DieTime
                -- optionally create a small hit effect at b.Hit
                -- ParticleEffect("striderbuster_ground", b.Hit, Angle(0,0,0), LocalPlayer())
            else
                allDone = false
                continue
            end
        end
		local BeamCycle = (now - b.SpawnTime) / b.DieTime

        -- if spawned and not yet expired, we are not done
        if now < b.ExpireTime then
            allDone = false
            -- update width for fade: 1.0 -> 0.0 over DieTime
            local baseWidth = math.Clamp(20 * (1 - BeamCycle), 0, 20)
			b.Width = baseWidth
            -- b.Alpha = math.Clamp(255 * (1 - BeamCycle), 0, 255)
			-- print("BeamCycle:", BeamCycle) 
			if BeamCycle >= inflateStart and BeamCycle < inflateEnd then
				-- t goes 0..1 across the inflate window
				local t = (BeamCycle - inflateStart) / (inflateEnd - inflateStart)
				b.Width = Lerp(t, 0, 100) -- smooth 0 -> 100
			elseif BeamCycle >= deflateStart and BeamCycle <= deflateEnd then
				-- t goes 0..1 across the deflate window
				local t = (BeamCycle - deflateStart) / (deflateEnd - deflateStart)
				b.Width = Lerp(t, 100, 0) -- smooth 100 -> 0
			end
        else
            -- expired: ensure alpha zero
            b.Alpha = 0
            b.Width = 0
        end
    end

    -- If all beams expired and a tiny buffer passed, finish
    if allDone then
        -- keep this frame to render last fade pixel-perfect, then stop
        return false
    end

    return true
end 

function EFFECT:Think()
	local now = CurTime()
	local elapsed = now - self.CreationTime
	local ageNorm = math.Clamp(elapsed / self.DieTime, 0, 1) 
	local Beams_Think = self:Beams_Think() 
	if ageNorm >= 1 then 
		if !Beams_Think then 
			if IsValid(self.Emitter) then self.Emitter:Finish() end 
			return false 
		end 
		Material("sprites/ma_c_rrfecationsphere_01_1"):SetUndefined("$refractamount",newAlpha) 
		return true 
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

	-- fade-out starting at 27% normalized life
	if ageNorm >= slashinterval then
		local t = math.Clamp((ageNorm - slashinterval) / (1-slashinterval), 0, 1) 
		alpha = alpha * (t) 
		if !self.BurstAreaSlash_Slash then self:Beams_SlashSparks() self.BurstAreaSlash_Slash = true end 
	end
	self.Color.a = math.floor(math.Clamp(alpha, 0, 255))
	self:SetColor(self.Color) 
	local newAlpha = math.Remap(self.Color.a,255,0,0,0.05) 
	self:SetCycle(ageNorm) 
	-- print("newAlpha",newAlpha) 
	ageNorm = math.Remap(ageNorm,0,1,0,2) 
	-- the velocity isn't here to move sphere around 
	-- local tempVel = self:GetForward()-(self:GetForward()*(ageNorm*1)) 
	-- tempVel = tempVel * 0.035 
	-- print(ageNorm,self.Color) 
	-- self:SetLocalVelocity(tempVel) -- it sets a material proxy which makes sphere age 
	self:SetNextClientThink(CurTime()+FrameTime()) 
	-- Material("sprites/ma_c_rrfecationsphere_01_1"):SetFloat("$SilhouetteThickness",newAlpha) 
	Material("sprites/ma_c_rrfecationsphere_01_1"):SetFloat("$refractamount",newAlpha) 
	-- Material("sprites/ma_c_rrfecationsphere_01_1"):SetUndefined("$SilhouetteColor",Vector(self.Color.r,self.Color.g,self.Color.b)) 
    return true
end 

function EFFECT:Render() 
	self:DrawModel() 
	-- set material once
    render.SetMaterial(LASER_MAT)

    for _, b in ipairs(self.Beams) do
        if !b.Spawned then continue end
        if b.Alpha <= 0 then continue end
        if b.Width <= 0 then continue end

        -- dynamic texture coord offsets so the sprite texture scrolls slightly
        local texStart = 0
        local texEnd = (b.Top:Distance(b.End)) / 64 -- scale texture tiling with length

        local col = Color(255, 255, 255, math.floor(b.Alpha)) -- bluish laser with alpha

        -- Draw main beam (billboarded quad)
        render.DrawBeam(b.Top, b.End, b.Width, texStart, texEnd, col)
    end 
	-- render.SetAmbientLight(0.1,0.1,0.1) 
end 