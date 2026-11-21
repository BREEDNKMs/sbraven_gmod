function EFFECT:Init(data) 
	local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), data:GetScale(), data:GetMagnitude(), data:GetFlags() 
	self.CreationTime = CurTime() 
	self.DieTime = Time 
	local Emitter = ParticleEmitter(Pos,tobool(Flags)) 
	self.Emitter = Emitter 
	-- self.Emitter = Emitter 
	local Sprite = Emitter:Add("sprites/ma_a_dirtmask_01",Pos) 
	Sprite:SetStartSize(Scale) 
	Sprite:SetEndSize(0) 
	Sprite:SetDieTime(Time) 
	Sprite:SetGravity(Vector(0,0,-100)) 
	Sprite:SetCollide(true) 
	Sprite:SetBounce(0.5) 
	Sprite:SetColor(255,0,0) 
	Sprite:SetStartAlpha(255) 
	Sprite:SetEndAlpha(0) 
	-- Sprite:SetVelocityScale(true) 
	-- Sprite:SetStartLength(1)
	-- Sprite:SetEndLength(1)
	-- Emitter:Finish() 
	print(self) 
	e = self 
end 

function EFFECT:Think()
	self:SetNextClientThink(CurTime() + FrameTime()) 
	local Sprite = self.Emitter:Add("sprites/glow04_noz_gmod",self:GetPos()) 
	Sprite:SetStartSize(32) 
	Sprite:SetEndSize(32) 
	Sprite:SetDieTime(1) 
	Sprite:SetGravity(vector_origin) 
	Sprite:SetCollide(false) 
	Sprite:SetBounce(0.5) 
	Sprite:SetColor(0,255,255) 
	Sprite:SetVelocity(Vector(math.random(-50,50),-1000,math.random(-50,50))) 
	Sprite:SetStartLength(100) 
	Sprite:SetEndLength(100) 
	Sprite:SetStartAlpha(255) 
	Sprite:SetEndAlpha(255) 
	return true
end

function EFFECT:Render() 
end 