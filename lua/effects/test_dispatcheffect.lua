function EFFECT:Init(data) 
	local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetMagnitude(), data:GetFlags() 
	self.CreationTime = CurTime() 
	self.DieTime = Time 
	local Emitter = ParticleEmitter(Pos,tobool(Flags)) 
	-- self.Emitter = Emitter 
	local Sprite = Emitter:Add("sprites/mi_a_flares_02",Pos) 
	Sprite:SetStartSize(Scale) 
	Sprite:SetEndSize(0) 
	Sprite:SetDieTime(Time) 
	Sprite:SetGravity(Vector(0,0,-100)) 
	Sprite:SetCollide(true) 
	Sprite:SetBounce(0.5) 
	Sprite:SetColor(255,255,255) 
	Sprite:SetStartAlpha(1) 
	Sprite:SetEndAlpha(1) 
	-- Sprite:SetVelocityScale(true) 
	-- Sprite:SetStartLength(1)
	-- Sprite:SetEndLength(1)
	Emitter:Finish() 
	
end 

function EFFECT:Think() 
	self:SetNextClientThink(CurTime()+FrameTime()) 
    return false 
end 

function EFFECT:Render()
end
