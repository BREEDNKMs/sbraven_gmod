function EFFECT:Init(data) 
	local Pos, Ang, Scale, Time, Flags = data:GetOrigin(), data:GetAngles(), data:GetScale() * 50, data:GetMagnitude(), data:GetFlags() 
	local Start = data:GetStart() 
	local Owner = data:GetEntity() 
	local now = CurTime() 
	self.CreationTime = now 
	self.DieTime = Time 
	local Emitter = ParticleEmitter(self:GetPos(),tobool(Flags)) 
	-- self:SetPos(data:GetEntity():LocalToWorld(Start + (vector_up*5))) 
	local tr = util.TraceHull({start = data:GetEntity():EyePos(), endpos = Pos, mins = Vector(-1,-1,-1), maxs = Vector(1,1,1), filter = data:GetEntity(), collisiongroup = COLLISION_GROUP_PLAYER}) 
	
	-- self:SetPos(LocalToWorld(Start,angle_zero,data:GetEntity():GetPos(),data:GetEntity():GetForward():Angle()) + (vector_up*10)) 
	self:SetPos(tr.HitPos) 
	if IsValid(data:GetEntity()) then 
		self:SetOwner(data:GetEntity()) 
	end 
	Pos = self:GetPos() 
	-- print(data:GetOrigin(),self:GetPos(),Ang,Scale,Time,Flags) 
	-- self.Emitter = Emitter 
	local Sprite = Emitter:Add("sprites/mi_a_flares_02",self:GetPos()) 
	-- PrintTable( Material( "sprites/mi_a_flares_02" ):GetKeyValues() )
	-- Material("mi_a_flares_02"):SetFloat("
	Sprite:SetStartSize(150) 
	Sprite:SetEndSize(0) 
	Sprite:SetDieTime(0.2) 
	-- Sprite:SetGravity(Vector(0,0,-100)) 
	Sprite:SetCollide(true) 
	Sprite:SetBounce(0.5) 
	Sprite:SetColor(255,255,255) 
	Sprite:SetStartAlpha(255) 
	Sprite:SetEndAlpha(255) 
	Sprite:SetThinkFunction(function() 
		local interval = Sprite:GetLifeTime()/Sprite:GetDieTime() 
		interval = 1 - interval 
		color = 255 * interval 
		Sprite:SetColor(color,color,color) 
		-- print(interval) 
		Sprite:SetNextThink(CurTime()+FrameTime()) 
	end) 
	-- Sprite:SetVelocityScale(true) 
	-- Sprite:SetStartLength(1)
	-- Sprite:SetEndLength(1)
	Emitter:Finish() 
	for i = 1, 20 do 
		local ef = EffectData() 
		local SparkPos = LerpVector(i/20,data:GetEntity():GetPos(),self:GetPos()) 
		ef:SetOrigin(SparkPos) 
		ef:SetAngles(vector_up:Angle()) 
		ef:SetNormal(vector_up*i) 
		ef:SetMagnitude(1) 
		ef:SetScale(5) 
		ef:SetRadius(i) 
		util.Effect(math.random() > 0.5 and "ManhackSparks" or "Sparks",ef) 
	end 
	
	local ptex = ProjectedTexture() 
	ptex:SetAngles((-vector_up):Angle()) 
	ptex:SetBrightness(500) 
	ptex:SetColor(Color(255,255,255)) 
	ptex:SetFarZ(700) 
	ptex:SetFOV(180) 
	ptex:SetOrthographic(true,-700,-700,700,700) 
	ptex:SetPos(self:GetPos()) 
	ptex:SetTexture("sprites/t_b_glow_01") 
	ptex:Update() 
	hook.Add("PreDrawOpaqueRenderables",ptex,function( ptex,isDrawingDepth, isDrawSkybox, isDraw3DSkybox ) 
		-- print(ptex,isDrawingDepth, isDrawSkybox, isDraw3DSkybox) 
		-- local Pos2 = Owner:LocalToWorld(Start) + (vector_up*20) 
		-- ptex:SetPos(Pos) 
		-- print(Pos2) 
		if !IsValid(Owner) then ptex:Remove() return end 
		local tr = util.TraceHull({start = Owner:EyePos(), endpos = Pos, mins = Vector(-1,-1,-1), maxs = Vector(1,1,1), filter = Owner, collisiongroup = COLLISION_GROUP_PLAYER}) 
	
		-- self:SetPos(LocalToWorld(Start,angle_zero,data:GetEntity():GetPos(),data:GetEntity():GetForward():Angle()) + (vector_up*10)) 
		if IsValid(self) then 
			self:SetPos(tr.HitPos) 
		end 
		ptex:SetPos(tr.HitPos) 
		local interval = (CurTime() - now) / (0.2) 
		local rinterval = 1-interval 
		ptex:SetFarZ(700*rinterval) 
		ptex:SetOrthographic(true,-700*rinterval,-700*rinterval,700*rinterval,700*rinterval) 
		debugoverlay.Line(Owner:GetPos(),Pos,FrameTime()*2) 
		debugoverlay.Cross(Pos,15,FrameTime()*2) 
		ptex:Update() 
		-- print(interval) 
		if interval >= 1 then 
			ptex:Remove() 
		end 
	end) 
end 

function EFFECT:Think() 
	self:SetNextClientThink(CurTime()+FrameTime()) 
    return false 
end 

function EFFECT:Render()
end
