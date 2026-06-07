function EFFECT:Init(data) 
	local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetMagnitude(), data:GetFlags() 
	self.CreationTime = CurTime() 
	self.DieTime = Time 
	local Emitter = ParticleEmitter(Pos,tobool(Flags)) 
	-- self.Emitter = Emitter 
	local Sprite = Emitter:Add("sprites/mi_d_raven_shockwv_01",Pos) 
	Sprite:SetStartSize(Scale) 
	Sprite:SetEndSize(0) 
	Sprite:SetDieTime(Time) 
	Sprite:SetGravity(Vector(0,0,-100)) 
	Sprite:SetCollide(true) 
	Sprite:SetBounce(0.5) 
	Sprite:SetColor(0,255,255) 
	Sprite:SetStartAlpha(255) 
	Sprite:SetEndAlpha(255) 
	-- Sprite:SetVelocityScale(true) 
	-- Sprite:SetStartLength(1)
	-- Sprite:SetEndLength(1)
	Emitter:Finish() 
end 

local mi_d_raven_shockwv_01 = Material("sprites/mi_d_raven_shockwv_02")

function EFFECT:Init(data)
	local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetMagnitude(), data:GetFlags()
	self.CreationTime = CurTime()
	self.DieTime = CurTime() + Time
	self.Emitter = ParticleEmitter(Pos, tobool(Flags))
	self.Emitter:SetNoDraw(true)

	local Sprite = self.Emitter:Add("sprites/mi_d_raven_shockwv_02", Pos)
	Sprite:SetStartSize(0)
	Sprite:SetEndSize(0)
	Sprite:SetDieTime(Time)
	Sprite:SetGravity(Vector(0, 0, 0))
	Sprite:SetCollide(true)
	Sprite:SetBounce(0.5)
	Sprite:SetColor(255, 255, 255)
	Sprite:SetStartAlpha(255)
	Sprite:SetEndAlpha(255)
	Sprite:SetNextThink(CurTime()+FrameTime()) 
	Sprite:SetThinkFunction(function(sprite) 
		if IsValid(self) then 
			Sprite:SetNextThink(CurTime()+FrameTime()) 
			-- print(sprite:GetLifeTime()/Time) 
			local cycle = sprite:GetLifeTime()/Time 
			local Scale = Lerp(math.ease.OutExpo(cycle),0,Scale) 
			Sprite:SetStartSize(Scale) Sprite:SetEndSize(Scale) 
		end 
	end) 
end

function EFFECT:Think()
	self:SetNextClientThink(CurTime() + FrameTime())

	if CurTime() >= self.DieTime then
		-- mi_d_raven_shockwv_01:SetUndefined("$emissiveblendstrength")
		-- mi_d_raven_shockwv_01:SetUndefined("$emissiveblendtint")
		self.Emitter:Finish()
		return false
	end

	return true
end

function EFFECT:Render()
	-- print(self,self.Emitter) 
	if IsValid(self.Emitter) then
		-- Fade $emissiveblendstrength from 1 to 0 over the effect's lifetime
		local cycle = math.Clamp((self.DieTime - CurTime()) / (self.DieTime - self.CreationTime), 0, 1)
		-- print(cycle) 
		-- mi_d_raven_shockwv_01:SetFloat("$emissiveblendstrength", cycle)
		-- mi_d_raven_shockwv_01:SetVector("$emissiveblendtint", Vector(0, 2, 2))
		self.Emitter:Draw()
	end
end