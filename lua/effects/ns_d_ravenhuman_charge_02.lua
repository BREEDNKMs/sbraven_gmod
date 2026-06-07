local mi_d_raven_shockwv_02 = Material("sprites/mi_d_raven_shockwv_02")
local mi_d_raven_shockwv_3 = Material("sprites/mi_d_raven_shockwv_3")

function EFFECT:Init(data)
	local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), 128, 0.5, 0
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
	
	local Sprite = self.Emitter:Add("sprites/mi_d_raven_shockwv_3", Pos)
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
		mi_d_raven_shockwv_02:SetUndefined("$emissiveblendstrength")
		mi_d_raven_shockwv_3:SetUndefined("$emissiveblendstrength")
		-- mi_d_raven_shockwv_02:SetUndefined("$emissiveblendtint")
		-- mi_d_raven_shockwv_3:SetUndefined("$emissiveblendtint")
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
		mi_d_raven_shockwv_3:SetFloat("$emissiveblendstrength", cycle)
		mi_d_raven_shockwv_02:SetFloat("$emissiveblendstrength", cycle)
		-- mi_d_raven_shockwv_3:SetVector("$emissiveblendtint", Vector(0, 2, 2))
		-- mi_d_raven_shockwv_02:SetVector("$emissiveblendtint", Vector(2.515, 4.600, 5))
		self.Emitter:Draw()
	end
end