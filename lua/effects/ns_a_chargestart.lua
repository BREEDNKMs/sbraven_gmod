-- ns_a_chargestart uses targetequipment 
local NE_FlareM = { } 
NE_FlareM.Material = Material("sprites/mi_b_lenscircle_01_15_afterdof") 

EFFECT.MAT = "sprites/physg_glow1.vmt"

local easeMethods = {
    math.ease.InBack, math.ease.InBounce, math.ease.InCirc, math.ease.InCubic,
    math.ease.InElastic, math.ease.InExpo, math.ease.InOutBack, math.ease.InOutBounce,
    math.ease.InOutCirc, math.ease.InOutCubic, math.ease.InOutElastic, math.ease.InOutExpo,
    math.ease.InOutQuad, math.ease.InOutQuart, math.ease.InOutQuint, math.ease.InOutSine,
    math.ease.InQuad, math.ease.InQuart, math.ease.InQuint, math.ease.InSine,
    math.ease.OutBack, math.ease.OutBounce, math.ease.OutCirc, math.ease.OutCubic,
    math.ease.OutElastic, math.ease.OutExpo, math.ease.OutQuad, math.ease.OutQuart,
    math.ease.OutQuint, math.ease.OutSine
}


function EFFECT:Init(data) 
    self.Origin = data:GetOrigin() or vector_origin 
	self.LocalPos = data:GetStart() 
	self.Entity = data:GetEntity() 
	self:SetOwner(self.Entity) 
	-- self:SetPos(data:GetOrigin()) 
	self:SetAngles(data:GetAngles()) 
	self.Scale = data:GetScale() * 1 
	-- print("scale is",self.Scale) 
	self.LifeTime = data:GetMagnitude() * 1 
	-- print("LifeTime is",self.LifeTime) 
    self.CreationTime = CurTime() 
    self.Emitter = ParticleEmitter(self.Origin, false) 
	self:AddEffects(EF_FOLLOWBONE) 
	local handBone = self.Entity:LookupBone("ValveBiped.Bip01_R_Hand") 
	print("handBone is:",handBone) 
	-- local parentPos = self.Entity:GetBoneMatrix(handBone) 
	self:SetParent(self.Entity,handBone) 
	self:SetLocalPos(vector_origin) 
	
	self:NE_SpriteM_Init(data) 
end 

-- Safe unclamped lerp for vectors (some math.ease variants expect unclamped values)
local function VecLerpUnclamped(t, a, b)
    return a + (b - a) * t
end

-- Quadratic bezier evaluation between a (start), b (bend), c (end) for parameter t
local function QuadraticBezier(a, b, c, t)
    local omt = 1 - t
    return a * (omt * omt) + b * (2 * omt * t) + c * (t * t)
end

function EFFECT:NE_SpriteM_Init(data) 
	local origin = self:GetPos() 
	
	local SpawnParticleCumuls = function(pos) 
		
		for i = 1, 50 do
			-- Random spawn offset (VectorRand-like but within -500..500 on each axis)
			local spawnOffset = Vector(
				math.Rand(-40, 40),
				math.Rand(-40, 40),
				math.Rand(-40, 40)
			)
			local spawnPos = pos + spawnOffset
			local endPos = origin -- as requested, end position is data:GetOrigin()

			local p = self.Emitter:Add(self.MAT, spawnPos)

			-- life between 1 and 2 seconds
			local life = math.Rand(1, 2)
			p:SetDieTime(life) -- (SetDieTime expects seconds lifetime)
			p.SpawnTime = CurTime()
			p.TotalLife = life

			-- cache start/end on particle as requested
			p.SpawnPosition = spawnPos
			p.EndPosition = endPos

			-- pick a random easing method and cache it
			local ease = easeMethods[math.random(1, #easeMethods)] or math.ease.InOutQuad
			p.EaseFunction = ease

			-- bend point: midpoint with a randomized perpendicular-ish offset
			local mid = (spawnPos + endPos) * 0.5
			-- offset magnitude proportional to distance (so long shots bend more)
			local dist = spawnPos:Distance(endPos)
			local offset = VectorRand() * (dist * 0.25 + 20)
			p.BendPoint = mid + offset

			-- visual properties
			p:SetStartAlpha(255)
			p:SetEndAlpha(255)
			p:SetStartSize(0.2)
			p:SetEndSize(0.5)
			p:SetRoll(math.Rand(0, 360))
			p:SetRollDelta(math.Rand(-90, 90))
			p:SetColor(255, 255, 255)
			p:SetAirResistance(30)
			p:SetVelocity(Vector(0, 0, 0))
			p:SetCollide(false)

			-- Keep last position for velocity fallback
			p.LastPos = spawnPos

			-- Think function: manually place the particle along a quadratic-bezier path
			p:SetThinkFunction(function(part)
				-- Protect if the particle already died or missing fields
				local now = CurTime()
				local age = now - (part.SpawnTime or 0)
				local lifeLen = part.TotalLife or 1

				if age >= lifeLen then
					-- let the particle die naturally (SetDieTime was already set)
					return
				end

				local t = age / lifeLen
				-- We intentionally do NOT clamp t before passing to the ease function in case
				-- the easing method expects unclamped input. However, we will guard against nil.
				local easeFunc = part.EaseFunction or math.ease.InOutQuad
				local te = 0
				-- Protect ease call (some custom ease libs might error if given nil)
				local ok, res = pcall(easeFunc, t)
				if ok and type(res) == "number" then
					te = res
				else
					te = math.Clamp(t, 0, 1)
				end

				-- Evaluate quadratic bezier using eased parameter
				local newPos = QuadraticBezier(part.SpawnPosition, part.BendPoint, part.EndPosition, te)

				-- Manually set particle position
				part:SetPos(newPos)

				-- Update velocity roughly (helps lighting/particles that sample velocity)
				local dt = FrameTime()
				if dt > 0 then
					local vel = (newPos - part.LastPos) / dt
					part:SetVelocity(vel)
				end
				part.LastPos = newPos

				-- schedule next think (small interval)
				part:SetNextThink(CurTime() + FrameTime())
			end)
			p:SetNextThink(CurTime() + FrameTime())
		end
		
	end 
	
	for i = 1, 4 do 
		SpawnParticleCumuls(self:GetPos() + VectorRand(-100,100)) 
	end 
	local dlight = DynamicLight(self.Entity:EntIndex()) 
	dlight.brightness = 10 
	dlight.decay = 1000 
	dlight.dietime = CurTime() + FrameTime() 
	dlight.pos = self:GetPos() 
	dlight.size = 20 
	dlight.r = 0 
	dlight.g = 255 
	dlight.b = 255 
	dlight.style = 0 
	dlight.dir = -self:GetOwner():GetOwner():GetUp() 
end 

function EFFECT:Think() 
	-- print(self,"pos is:",self:GetPos()) 
	if CurTime() > self.CreationTime + self.LifeTime then 
		if IsValid(self.Emitter) then self.Emitter:Finish() end 
		-- disable dlight if it hadn't removed itself 
		local dlight = DynamicLight(self.Entity:EntIndex()) 
		dlight.dietime = CurTime() 
		dlight.brightness = 0 
		dlight.size = 9999 
		dlight.r = 0 
		dlight.g = 0 
		dlight.b = 0 
		dlight.nomodel = true 
		dlight.pos = self:GetPos() 
		dlight.dir = -self:GetOwner():GetOwner():GetUp() 
		return false 
	end 
	local dlight_scale = 1200 
	local Cycle = math.Clamp((CurTime() - self.CreationTime) / self.LifeTime, 0, 1) 
	-- print("ns_a_chargestart cycle:",Cycle) 
	local dlight = DynamicLight(self.Entity:EntIndex()) 
	dlight.brightness = 1 * (1-Cycle) 
	print("brightness is:",1 * (1-Cycle)) 
	dlight.decay = 1000 
	dlight.dietime = CurTime() + FrameTime() 
	dlight.pos = self:GetPos() 
	dlight.size = dlight_scale * Cycle 
	dlight.r = 0 * (1-Cycle) 
	dlight.g = 255 * (1-Cycle) 
	dlight.b = 255 * (1-Cycle) 
	dlight.minlight = 100 * (1-Cycle) 
	dlight.innerangle = 0 
	dlight.outerangle = 100 
	dlight.style = 0
	dlight.dir = -self:GetOwner():GetOwner():GetUp() 
	return true 
end 

function EFFECT:Render() 
	local mat = NE_FlareM.Material 
	render.SetMaterial(mat) 
	local scale = math.sin(CurTime()*1/engine.AbsoluteFrameTime()) * 32 
	render.DrawSprite(self:GetPos(),128+scale,128+scale) 
end 