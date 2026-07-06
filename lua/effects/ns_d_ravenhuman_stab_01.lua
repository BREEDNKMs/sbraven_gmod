-- local self = Entity(140) 
local t = 0.2 
local startScale = Vector(1,1,5) 
function EFFECT:Init(data) 
	self:SetModel("models/stellarblade/sm_a_cone_01.mdl") 
	local ang = -data:GetAngles() 
	local ent = data:GetEntity():IsWeapon() and data:GetEntity():GetOwner() or data:GetEntity() 
	self:SetOwner(ent) 
	ang = -ang + (ent:GetForward():Angle()) 
	-- local matrix = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip01_R_Hand")) 
	-- matrix = matrix:GetRight():Angle() 
	self:SetAngles(ang) 
	self.CreationTime = CurTime() 
	self:SetMaterial("sprites/MI_B_MeshShockWv_01_2_2") 
	self:SetColor(Color(170,255,255,255)) 
	self.Color = self:GetColor() 
	self.subModels = {
		[ClientsideModel("models/stellarblade/sm_a_cone_01.mdl",RENDERGROUP_BOTH)] = {Vector(1.2,1.2,5),"sprites/MA_C_RrfecationSphere_01_1"}, 
		-- [ClientsideModel("models/stellarblade/sm_a_shockwv_02.mdl",RENDERGROUP_BOTH)] = {Vector(0.4,0.4,20),"sprites/MI_B_MeshShockWv_01_2_2"}, 
		[ClientsideModel("models/stellarblade/sm_a_cone_01.mdl",RENDERGROUP_BOTH)] = {Vector(0.2,0.2,5),"sprites/MI_D_MeshShockWv_Ad_01_2"}} 

	for k,v in pairs(self.subModels) do 
		k:SetPos(self:GetPos()) 
		if k:GetModel() == "models/stellarblade/sm_a_shockwv_02.mdl" then 
			k:SetAngles(self:GetAngles() + Angle(180,0,0)) 
			k:SetColor(Color(170,255,255)) 
			k.Color = k:GetColor() 
		else 
			k:SetAngles(self:GetAngles()) 
			k.Color = Color(255,255,255,255) 
		end 
		k:SetMaterial(v[2]) 
		local m = Matrix() 
		m:Scale(v[1] * (1-1)) 
		k:EnableMatrix("RenderMultiply",m) 
	end 
	-- print("ns_d_ravenhuman_stab_01") 
	-- print(data:GetScale()) 
	-- print(data:GetMagnitude()) 
	-- print(data:GetEntity()) 
	-- print(data:GetHitBox()) 
	-- print(data:GetStart()) 
	self:SetRenderMode(RENDERMODE_TRANSCOLOR) 
	self.Emitter = ParticleEmitter(self:GetPos()) 
	
	
	-- debugoverlay.Cross(self:GetPos() + (self:GetUp()*-40),32) 
	local circleCenter = self:GetPos() + (self:GetUp() * -40)
    local segments = 256 -- Adjust for more/fewer crosses in the circle ring
    
    for i = 1, segments do
        local rotationAng = self:GetForward():Angle()
        -- Rotate around the spike's Up axis to form a flat horizontal ring around it
        rotationAng:RotateAroundAxis(self:GetUp(), (i / segments) * 360)
        
        local crossPos = circleCenter + (rotationAng:Forward() * 8)
		
		crossPos = crossPos + (self:GetUp() *math.Rand(-4,4)) -- delta 
		local velocity = rotationAng:Forward()*(math.random(450,500))
        -- Syntax: Cross(pos, size, lifetime, color, ignoreZ)
        -- debugoverlay.Cross(crossPos, 8, 3, Color(0, 255, 255), true) 
		local p = self.Emitter:Add("effects/spark",crossPos) 
		p:SetDieTime(0.1) 
		p:SetStartSize(math.Rand(3.7,4.2)) 
		p:SetEndSize(0) 
		p:SetVelocity(velocity) 
		p:SetColor(math.random(50,170),255,255) 
		p:SetStartAlpha(255) 
		p:SetEndAlpha(255) 
		p:SetRoll(math.rad((i / -segments) * 360)) 
    end
	
	local segments2 = 50 
	for i = 1, segments2 do 
		local rotationAng = self:GetForward():Angle()
        -- Rotate around the spike's Up axis to form a flat horizontal ring around it
        rotationAng:RotateAroundAxis(self:GetUp(), (i / segments) * 360)
		local crossPos = circleCenter + (rotationAng:Forward() * math.Rand(-40,40))
		
		crossPos = crossPos + (self:GetUp() *math.Rand(-4,4)) -- delta 
		local velocity = rotationAng:Forward()*(math.random(0,300))
        -- Syntax: Cross(pos, size, lifetime, color, ignoreZ)
        -- debugoverlay.Cross(crossPos, 8, 3, Color(0, 255, 255), true) 
		local p = self.Emitter:Add("effects/spark",crossPos) 
		p:SetDieTime(0.3) 
		p:SetStartSize(math.Rand(3.7,4.2)) 
		p:SetEndSize(0) 
		p:SetVelocity(velocity) 
		p:SetColor(math.random(50,170),255,255) 
		p:SetStartAlpha(255) 
		p:SetEndAlpha(255) 
		p:SetRoll(math.rad((i / -segments) * 360)) 
		
	end 
	-- put a circle made of debugoverlay.Cross around self:GetPos() + (self:GetUp()*-40) with a range of 32 
end 

function EFFECT:Think() 
	local Cycle = math.Clamp((CurTime() - self.CreationTime) / t, 0, 1) 
	if Cycle >= 1 then self:DisableMatrix("RenderMultiply") for k,v in pairs(self.subModels) do SafeRemoveEntity(k) end SafeRemoveEntity(model1) if IsValid(self.Emitter) then  self.Emitter:Finish() end return false end 
	return true 
end 

function EFFECT:Render(flags) 
	-- print("rendering:",self,self:GetPos()) 
	-- self:SetPos(self.Origin) 
	local Cycle = math.Clamp((CurTime() - self.CreationTime) / t, 0, 1) 
	local Scale = startScale * (1-Cycle) 
	Scale = Scale * self:GetModelScale() 
	
	local m = Matrix() 
	m:Scale(Scale) 
	self:EnableMatrix("RenderMultiply",m) 
	self:SetMaterial("sprites/MI_B_MeshShockWv_01_2_2") 
	local NewColor = self.Color:Lerp(Color(0,0,0,255),Cycle) 
	self:SetColor(NewColor) 
	-- print(NewColor) 
	self:DrawModel() 
	for k,v in pairs(self.subModels) do 
		k:SetPos(self:GetPos()) 
		-- print(k:GetModel()) 
		if k:GetModel() == "models/stellarblade/sm_a_shockwv_02.mdl" then 
			-- k:SetAngles(self:GetAngles() + Angle(180,0,0)) 
			k:SetAngles(self:GetAngles() + Angle(0,0,0)) 
			-- k:SetColor(Color(170,255,255)) 
		else 
			k:SetAngles(self:GetAngles()) 
		end 
		k:SetMaterial(v[2]) 
		local NewColor = k.Color:Lerp(Color(0,0,0,255),Cycle) 
		k:SetColor(NewColor) 
		local m = Matrix() 
		m:Scale(v[1] * (1-Cycle)) 
		
		-- k:AddEffects(EF_NODRAW)  
		
		k:EnableMatrix("RenderMultiply",m) 
	end 
	if Cycle >= 1 then self:DisableMatrix("RenderMultiply") for k,v in pairs(self.subModels) do SafeRemoveEntity(k) end SafeRemoveEntity(model1) end 
	-- print(1-Cycle) 
end 
