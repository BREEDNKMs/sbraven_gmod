-- immediate: no think 

function EFFECT:Init(data) 
    local ent = data:GetEntity()
    local entPos = IsValid(ent) and ent:GetPos() or nil
    local localPos = data:GetOrigin() 
    local ang = data:GetAngles() 
    local scale = math.max(0.01, data:GetScale() or 1.0)
    self:SetOwner(data:GetEntity()) 
    self.CreationTime = CurTime() 
    self.DieTime = data:GetMagnitude()  
    
    self.Attachment = data:GetAttachment() 
    self:Think() 
    
    -- UPDATE: Capture FloorNormal
    local Pos, Normal, FloorNormal, SurfaceProps, Entity, HitBox = self:GetEffectPos() 
    local ef = EffectData() 
    ef:SetOrigin(Pos) 

    -- UPDATE: Calculate tangent from hit normal and floor normal
    -- local hitNormal = Normal
    -- local tangent = hitNormal:Cross(FloorNormal or vector_up):GetNormalized()
	local forward = IsValid(self:GetOwner()) and IsValid(self:GetOwner():GetOwner()) and self:GetOwner():GetOwner():GetForward() or self:GetForward() 
	local ang = forward:Angle()
	ang.pitch = ang.pitch - 60  -- lift by 20 degrees upward 
	forward = ang:Forward()
	ef:SetNormal(forward)
    
    util.Effect("ManhackSparks",ef) 
    util.Effect("ManhackSparks",ef) 
    util.Effect("ManhackSparks",ef) 
    util.Effect("ManhackSparks",ef) 
    util.Effect("ManhackSparks",ef) 
    util.Effect("ManhackSparks",ef) 
    util.Effect("ManhackSparks",ef) 
    util.Effect("ManhackSparks",ef) 
    util.Effect("ManhackSparks",ef) 
    -- util.Effect("Explosion",ef) 
    -- print("finish ns_d_ravenhuman_spark_03",self:GetPos(),self:GetOwner():GetOwner():GetForward()) 
end 

function EFFECT:Think() 
	-- print("self:GetCreationTime()",self:GetCreationTime()) 
	return false 
end 

function EFFECT:GetEffectPos()
    local ent = self:GetOwner() 
    if !IsValid(ent) then return nil end 
    
    if IsValid(ent:GetOwner()) then 
        if ent:GetOwner().ShouldDrawLocalPlayer and !ent:GetOwner():ShouldDrawLocalPlayer() then 
            -- UPDATE: Added vector_up as the fallback floor normal
            return ent:GetOwner():GetPos() + (ent:GetOwner():GetRight()*ent:GetOwner():BoundingRadius()), ent:GetOwner():GetUp(), vector_up, -1, self, 0 
        end 
    end 

    local boneIdx = ent:LookupBone("ValveBiped.Bip01_R_Hand")
    if boneIdx then
        local m = ent:GetBoneMatrix(boneIdx) 
        if m then
            local pos, up = m:GetTranslation(), m:GetUp() 
            up = Vector(0,0,1) 
            if pos then 
                local tr = util.TraceLine({start = pos + (up * 50), endpos = pos + (up * -100), filter = {self, self:GetOwner(), self:GetOwner():GetOwner()}}) 
                
                -- UPDATE: Return tr.HitNormal twice (once for standard normal, once for FloorNormal)
                return tr.HitPos, tr.HitNormal, tr.HitNormal, tr.SurfaceProps, tr.Entity, tr.HitBox 
            end
        end
    end 

    local att = ent:GetAttachment(self.Attachment)
    -- UPDATE: Added vector_up as the fallback floor normal
    if att and att.Pos then return att.Pos, vector_up, vector_up end

    -- UPDATE: Added vector_up as the fallback floor normal
    return ent:EyePos(), vector_up, vector_up 
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