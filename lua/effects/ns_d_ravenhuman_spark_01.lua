function EFFECT:Init(data) 
    local ent = data:GetEntity()
    local entPos = IsValid(ent) and ent:GetPos() or nil
    local localPos = data:GetOrigin() or vector_origin
    local ang = data:GetAngles() or Angle(0,0,0)
    local life = math.max(0.01, data:GetMagnitude() or 0.6)
    local scale = math.max(0.01, data:GetScale() or 1.0)
	self:SetOwner(data:GetEntity()) 
	self.CreationTime = CurTime() 
	self.DieTime = life 
	-- print("magnitude is:",life) 

    -- resolve world-space origin
    local origin = entPos or localPos or vector_origin
    if localPos and localPos != vector_origin then
        origin = localPos
        -- if entPos and localPos:Distance(entPos) > 10000 then
            -- origin = entPos + localPos
        -- end
    end
	
	self.Attachment = data:GetAttachment() 
	self:Think() 
	-- print("finish ns_d_ravenhuman_spark_01") 
end 

function EFFECT:Think() 
	-- print("self:GetCreationTime()",self:GetCreationTime()) 
	if CurTime() > self.CreationTime + self.DieTime then return false end 
	local sparkPos, sparkNormal, sparkSurfaceProps, sparkEntity, sparkHitBox = self:GetEffectPos() 
	local ef = EffectData() 
	ef:SetOrigin(sparkPos) 
	ef:SetNormal(sparkNormal) 
	ef:SetStart(self:GetOwner():GetOwner():EyePos()) 
	ef:SetFlags(2) 
	ef:SetEntity(sparkEntity) 
	ef:SetSurfaceProp(sparkSurfaceProps) 
	ef:SetHitBox(sparkHitBox) 
	-- util.Effect("MetalSpark",ef) 
	util.Effect("Impact_GMOD",ef) 
	util.Effect("StunstickImpact",ef) 
	self:SetNextClientThink(CurTime()+FrameTime()) -- fixups thinking during pause 
	return true 
end 

function EFFECT:GetEffectPos()
    local ent = self:GetOwner() 
	-- print("ent is:",ent) 
    if !IsValid(ent) then return nil end 
	if IsValid(ent:GetOwner()) then 
		if ent:GetOwner().ShouldDrawLocalPlayer and !ent:GetOwner():ShouldDrawLocalPlayer() then return ent:GetOwner():GetPos() + (ent:GetOwner():GetRight()*ent:GetOwner():BoundingRadius()), ent:GetOwner():GetUp(),-1,self,0 end 
	end 

    -- Try bone "ValveBiped.Bip01_R_Hand" like your example
    local boneIdx = ent:LookupBone("ValveBiped.Bip01_R_Hand")
    if boneIdx then
		-- print("boneIdx:",boneIdx) 
        local m = ent:GetBoneMatrix(boneIdx) 
		-- print("m:",m) 
        if m then
			-- print("GetBoneMatrix:",m) 
            local pos, up = m:GetTranslation(), m:GetUp() 
			up = Vector(0,0,1) -- the sword is aiming at wrong dir; force the sparks to appear beneath. remove this override when animation issues are solved 
            if pos then 
				-- print("pos,up:",pos,up) 
				local tr = util.TraceLine({start = pos + (up * 50), endpos = pos + (up * -100), filter = {self, self:GetOwner(), self:GetOwner():GetOwner()}}) 
				-- debugoverlay.Line(pos + (up * 50),pos + (up * -100),FrameTime()*20,color_white) 
				-- debugoverlay.Cross(tr.HitPos,10,FrameTime()*20) 
				return tr.HitPos, tr.HitNormal, tr.SurfaceProps, tr.Entity, tr.HitBox 
			end
        end
    end 

    -- fallback to attachment, if present
    local att = ent:GetAttachment(self.Attachment)
    if att and att.Pos then return att.Pos end

    return ent:EyePos() 
end 

function EFFECT:Render() 
	-- draw a sprite 
	local pos = self:GetEffectPos() 
	self:SetPos(pos) 
	-- print(self:GetEffectPos()) 
	-- render.SetMaterial(Material("sprites/blueflare1_noz_gmod")) 
	-- render.DrawSprite(self:GetPos(),32,32,color_white) 
	-- self:DrawModel() 
end 