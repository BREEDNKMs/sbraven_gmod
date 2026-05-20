function EFFECT:Init(data)
    -- startup params (as requested)
    self.Entity     = data:GetEntity()
    self.Attachment = data:GetAttachment()
    self.Bone       = data:GetHitBox()      -- Bone ID
    self.LocalPos   = data:GetStart()       -- position relative to entity
    self.WorldPos   = data:GetOrigin()      -- world position
    self.LifeScalar = data:GetMagnitude() or 1 -- lifetime scalar
    self.Scale      = data:GetScale() or 1  -- scale scalar
    self.Scale = self.Scale * 0.1 

    -- === Exposed defaults (baked from provided JSON) ===
    self._USER_BRIGHTNESS = 85.0
    -- JSON color is in 0..1; convert to 0..255 for GMod Color
    self._USER_COLOR = Color(
        math.floor(0.12997448 * 255 + 0.5),
        math.floor(0.75785363 * 255 + 0.5),
        math.floor(1.0 * 255 + 0.5)
    )
    self._USER_LIFETIME = 0.135          -- seconds (base)
    self._USER_RADIUS   = 300.0          -- units (base)

    -- Compute final life / brightness / radius applying incoming scalars
    local life = self._USER_LIFETIME * (self.LifeScalar ~= 0 and self.LifeScalar or 1)
    if life <= 0 then life = 0.01 end
    self.LifeTime = life
    self.DieTime = CurTime() + self.LifeTime

    self.BaseBrightness = self._USER_BRIGHTNESS * (self.Scale != 0 and self.Scale or 1)
    self.BaseRadius     = self._USER_RADIUS * (self.Scale != 0 and self.Scale or 1)

    -- Initialize ProjectedTexture
    if CLIENT then
        self.ProjTex = ProjectedTexture()
        self.ProjTex:SetTexture("sprites/t_b_glow_01")
        self.ProjTex:SetColor(self._USER_COLOR)
        -- Point straight down to act as a localized spherical glow
        self.ProjTex:SetAngles(Angle(90, 0, 0)) 
        self.ProjTex:SetFOV(180)
    end

    -- Optional: small sprite to visualize the light core
    self.SpriteMat = Material("sprites/light_glow02_add") 

    self.CreationTime = CurTime()
end

function EFFECT:Think()
    -- Stop when lifetime is finished and clean up the ProjectedTexture
    if CurTime() >= self.DieTime then
        if IsValid(self.ProjTex) then
            self.ProjTex:Remove()
        end
        return false
    end

    -- Compute where the light should be placed:
    local pos
    if IsValid(self.Entity) then
        if self.Attachment and self.Attachment != 0 then
            local att = self.Entity:GetAttachment(self.Attachment)
            if att and att.Pos then
                pos = att.Pos
            end
        end

        if not pos and self.Bone and self.Bone >= 0 then
            local bonePos = self.Entity:GetBoneMatrix(self.Bone) 
            bonePos = bonePos and bonePos:GetTranslation() 
            if bonePos then
                pos = bonePos 
            end
        end

        if not pos then
            pos = self.Entity:LocalToWorld(self.LocalPos)
        end
    end

    -- fallback to worldpos from data or entity center
    if not pos then
        pos = self.WorldPos or (IsValid(self.Entity) and self.Entity:GetPos()) or vector_origin
    end

    -- Linear fade factor: 1.0 at spawn -> 0.0 at die time
    local remaining = math.Clamp((self.DieTime - CurTime()) / self.LifeTime, 0, 1)

    -- Update ProjectedTexture properties dynamically
    if IsValid(self.ProjTex) then
        self.ProjTex:SetPos(pos)
        
        -- Brightness fades linearly
        self.ProjTex:SetBrightness(self.BaseBrightness * remaining)
        
        -- Radius/size fades linearly mapped to FarZ and Orthographic bounds
        local currentRadius = math.max(1, self.BaseRadius * remaining)
        self.ProjTex:SetFarZ(currentRadius)
        self.ProjTex:SetOrthographic(true, -currentRadius, -currentRadius, currentRadius, currentRadius)
        
        self.ProjTex:Update()
    end

    return true
end

function EFFECT:Render()
    if CurTime() >= self.DieTime then return end

    local pos
    if IsValid(self.Entity) then
        if self.Attachment and self.Attachment != 0 then
            local att = self.Entity:GetAttachment(self.Attachment)
            if att and att.Pos then pos = att.Pos end
        end
        if not pos and self.Bone and self.Bone >= 0 then
            local bonePos = self.Entity:GetBoneMatrix(self.Bone) 
            bonePos = bonePos and bonePos:GetTranslation() 
            if bonePos then
                pos = bonePos 
            end
        end
        if not pos then
            pos = self.Entity:LocalToWorld(self.LocalPos)
        end
    end
    pos = pos or self.WorldPos or (IsValid(self.Entity) and self.Entity:GetPos()) or Vector(0,0,0)

    local remaining = math.Clamp((self.DieTime - CurTime()) / self.LifeTime, 0, 1)
    local size = math.max(2, math.floor(self.BaseRadius * remaining * 0.1)) 

    render.SetMaterial(self.SpriteMat)
    render.DrawSprite(pos, size*10, size*10, Color(self._USER_COLOR.r, self._USER_COLOR.g, self._USER_COLOR.b, math.floor(255 * remaining)))
end