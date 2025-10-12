-- ============================================================
-- Raven Weapon Buff Trail Sparks (Looping)
-- File: effects/mi_a_gpusparks_01.lua
-- Derived from NS_D_RavenHuman_WPBuffTrail_01 / NE_SpriteM
-- ============================================================

EFFECT.MatFrames = {
    Material("sprites/t_a_amberparticle_01_000"),
    Material("sprites/t_a_amberparticle_01_001"),
    Material("sprites/t_a_amberparticle_01_002"),
    Material("sprites/t_a_amberparticle_01_003")
}

EFFECT.NumFrames  = #EFFECT.MatFrames
EFFECT.FrameRate  = 4
EFFECT.ScaleConst = 1
EFFECT.NumSpots   = 6
EFFECT.ColorTint  = Vector(0, 88, 255)
-- EFFECT.ColorTint  = Vector(255, 128, 26)
EFFECT.ParticleLife = 0.6
EFFECT.VelocityScale = 100
EFFECT.LengthScale = 3.5
EFFECT.Width = 60
EFFECT.CurlStrength = 80
EFFECT.OrbitSpeed = 2.5
EFFECT.DebugDraw = false

EFFECT.BakedOffsets = {
	Vector(  0,   0,  30),
	Vector( 25,  10,  10),
	Vector(-25,  10,  10),
	Vector( 15, -15,  -5),
	Vector(-15, -15,  -5),
	Vector(  0,   0, -20)
}

-- ============================================================
-- Utility Curves / Noise
-- ============================================================
local function BrightnessCurve(frac)
	if frac < 0.3 then
		return Lerp(frac / 0.3, 0.0, 1.0)
	else
		return Lerp((frac - 0.3) / 0.7, 1.0, 0.0)
	end
end

local function AlphaCurve(frac)
	if frac < 0.2 then
		return Lerp(frac / 0.2, 0.0, 1.0)
	else
		return Lerp((frac - 0.2) / 0.8, 1.0, 0.0)
	end
end

local function CurlNoise(pos, t, scale)
	local x = pos.x * 0.05 + t * 0.8
	local y = pos.y * 0.05 + t * 0.8
	local z = pos.z * 0.05 + t * 0.8
	return Vector(
		math.sin(y + z) - math.cos(y - z),
		math.sin(z + x) - math.cos(z - x),
		math.sin(x + y) - math.cos(x - y)
	):GetNormalized() * scale
end


-- ============================================================
-- Init
-- ============================================================
function EFFECT:Init(data)
	self.Ent = data:GetEntity()
	if !IsValid(self.Ent) then return end
	print("created effect",self,data:GetFlags()) 

	-- Flag = 1  →  kill effect on same entity
	if data:GetFlags() == 1 then
		for _, fx in ipairs(ents.GetAll()) do
			if fx:GetClass() == "class CLuaEffect" and fx.Ent == self.Ent then
				SafeRemoveEntity(fx)
			end
		end
		SafeRemoveEntity(self)
		return
	end
	local cleanup = { } -- necessary because some number ends up in inherited Lua tables, I don't know why 
	for k,v in ipairs(self.MatFrames) do 
		if type(v) == "IMaterial" then 
			table.insert(cleanup,v) 
		end 
	end 
	print("progressing") 
	self.MatFrames = cleanup 
	self.NumFrames = #self.MatFrames 
	-- self.DieTime = CurTime() + self.LifeTime
	self.Origin = self.Ent:WorldSpaceCenter()
	self.Emitter = ParticleEmitter(self.Origin, true)
	self.Emitter:SetNearClip(16, 128)
	self.NextEmit = 0
	self.EmitInterval = 0.05 -- 20 Hz check
	PrintTable(self.MatFrames) 
	print(#self.MatFrames) 

	for i = 1, self.NumSpots do
		local offset = self.BakedOffsets[i]
		if offset then
			self:SpawnSparkParticle(offset)
		else
			-- fallback if not enough baked offsets
			self:SpawnSparkParticle(VectorRand() * 20)
		end
	end
end

-- ============================================================
-- Spawn Particle
-- ============================================================
function EFFECT:SpawnSparkParticle(localOffset)
	if not self.Emitter then return end

	-- Scale Unreal → Source
	local offset = localOffset * self.ScaleConst
	local spawnPos = self.Origin + offset

	local dir = offset:GetNormalized()
	local vel = dir * (self.VelocityScale * self.ScaleConst) + VectorRand() * 10

	local p = self.Emitter:Add(self.MatFrames[1], spawnPos)
	if not p then return end
	print("spawnPos",p,spawnPos) 

	p:SetVelocity(vel)
	p:SetDieTime(self.ParticleLife + math.Rand(-0.2, 0.2))
	p:SetStartAlpha(0)
	p:SetEndAlpha(0)
	p:SetStartSize(self.Width)
	p:SetEndSize(0)
	p:SetAirResistance(6)
	p:SetGravity(Vector(0, 0, 0))
	p:SetLighting(false)
	p:SetCollide(false)

	p:SetRoll(math.Rand(0, 360))
	p:SetRollDelta(0)

	local col = self.ColorTint * 255
	p:SetColor(col.x, col.y, col.z)

	p.BaseOffset = offset
	p.RavenVel = vel

	-- Particle self-thinking
	p:SetThinkFunction(function(part)
		local frac = 1 - (part:GetLifeTime() / part:GetDieTime())
		local bright = BrightnessCurve(frac)
		local alpha = AlphaCurve(frac)
		local curPos = part:GetPos()
		local dt = FrameTime()

		-- Curl noise turbulence
		local curl = CurlNoise(curPos, CurTime(), self.CurlStrength * self.ScaleConst)
		local vel = part:GetVelocity()
		vel:Add(curl * dt * 20)

		-- Orbit around base offset (acts like AttractorPoint)
		local orbitCenter = self.Origin + part.BaseOffset
		local toCenter = (orbitCenter - curPos)
		local dist = toCenter:Length()
		if dist > 0.01 then
			local tangent = Vector(-toCenter.y, toCenter.x, 0):GetNormalized()
			local orbitForce = tangent * self.OrbitSpeed * 80 * self.ScaleConst
			vel:Add(orbitForce * dt)
		end

		part:SetVelocity(vel)

		-- Align to velocity (VelocityAligned)
		local ang = vel:Angle()
		part:SetAngles(ang)

		-- local len = math.Clamp(vel:Length() * self.LengthScale, 6, 56)
		-- print("SetStartSize in Think:",len,"CurTime()",CurTime()) 
		-- part:SetStartSize(len) -- let 
		part:SetEndSize(0)

		local tint = self.ColorTint * bright * 255
		part:SetColor(tint.x, tint.y, tint.z)
		part:SetStartAlpha(alpha * 255)
		
		local age = p:GetLifeTime()
		local life = p:GetDieTime()

		local lifeFrac = age / life
		local frame = math.floor(lifeFrac * (self.NumFrames - 0.001)) + 1

		-- Safety clamp
		frame = math.Clamp(frame, 1, self.NumFrames)
		p:SetMaterial(self.MatFrames[frame])

		part:SetNextThink(CurTime() + FrameTime())
	end)
	p:SetNextThink(CurTime() + FrameTime())

	if self.DebugDraw then
		debugoverlay.Cross(spawnPos, 3, 1, Color(0, 255, 255))
	end
end

-- ============================================================
-- Think / Render
-- ============================================================
function EFFECT:Think()
	if not IsValid(self.Ent) or not self.Ent:Alive() then return false end
	if not self.Emitter or not self.Emitter:IsValid() then return false end

	self.Origin = self.Ent:WorldSpaceCenter()

	-- Periodically emit new sparks if pool below target
	if CurTime() > self.NextEmit then
		self.NextEmit = CurTime() + self.EmitInterval
		if self.Emitter:GetNumActiveParticles() < self.NumSpots then
			for i = 1, self.NumSpots - self.Emitter:GetNumActiveParticles() do
				local offset = self.BakedOffsets[math.random(1, #self.BakedOffsets)]
				self:SpawnSparkParticle(offset)
			end
		end
	end

	return true
end

function EFFECT:Render()
	-- handled by emitter
end
