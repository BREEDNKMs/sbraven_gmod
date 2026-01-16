-- Creates a DynamicLight using the entity's index and Niagara-like exposed defaults.
-- Faithful defaults (from your JSON):
--   User.Light_Brightness = 85.0
--   User.Light_color = (R=0.12997448, G=0.75785363, B=1.0, A=1.0)
--   User.Light_LifeTime = 0.135
--   User.Light_Radius = 300.0


function EFFECT:Init(data)
    -- startup params (as requested)
    self.Entity     = data:GetEntity()
    self.Attachment = data:GetAttachment()
    self.Bone       = data:GetHitBox()      -- Bone ID
    self.LocalPos   = data:GetStart()       -- position relative to entity
    self.WorldPos   = data:GetOrigin()      -- world position
    self.LifeScalar = data:GetMagnitude() or 1 -- lifetime scalar
    self.Scale      = data:GetScale() or 1  -- scale scalar
	self.Scale = self.Scale * 0.03 

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
    -- If LifeScalar is 0 or extremely small, clamp to avoid zero-division.
    local life = self._USER_LIFETIME * (self.LifeScalar ~= 0 and self.LifeScalar or 1)
    if life <= 0 then life = 0.01 end
    self.LifeTime = life
    self.DieTime = CurTime() + self.LifeTime

    self.BaseBrightness = self._USER_BRIGHTNESS * (self.Scale != 0 and self.Scale or 1)
    self.BaseRadius     = self._USER_RADIUS * (self.Scale != 0 and self.Scale or 1)

    -- dynamic light key/index:
    -- prefer the entity's index (as requested). Fallback to 0 if not valid.
    if IsValid(self.Entity) then
        -- Prefer EntIndex() when available
        self.DLightIndex = (self.Entity:EntIndex() or 0)
    else
        -- fallback unique-ish index (0 is allowed but might be shared)
        self.DLightIndex = 0
    end

    -- Optional: small sprite to visualize the light (can be removed)
    self.SpriteMat = Material("sprites/light_glow02_add") -- vanilla sprite

    -- initial creation happens in Think (so it updates every frame)
    self.CreationTime = CurTime()
end

function EFFECT:Think()
    -- Stop when lifetime is finished
    if CurTime() >= self.DieTime then
        return false
    end

    -- Compute where the light should be placed:
    local pos
    if IsValid(self.Entity) then
        -- If Attachment is set and entity supports it -> use attachment
        if self.Attachment and self.Attachment != 0 then
            local att = self.Entity:GetAttachment(self.Attachment)
            if att and att.Pos then
                pos = att.Pos
            end
        end

        -- If a bone was supplied (non-zero), try bone position
        if not pos and self.Bone and self.Bone >= 0 then
			local bonePos = self.Entity:GetBoneMatrix(self.Bone) 
			bonePos = bonePos and bonePos:GetTranslation() 
            if bonePos then
                -- GetBonePosition may return Vector or three numbers; normalize to Vector
				pos = bonePos 
            end
        end

        -- If LocalPos is provided (relative to entity), transform to world
        if !pos then
			pos = self.Entity:LocalToWorld(self.LocalPos)
        end
    end

    -- fallback to worldpos from data or entity center if none of the above worked
    if !pos then
        pos = self.WorldPos or (IsValid(self.Entity) and self.Entity:GetPos()) 
    end

    -- Linear fade factor: 1.0 at spawn -> 0.0 at die time
    local remaining = math.Clamp((self.DieTime - CurTime()) / self.LifeTime, 0, 1)

    -- Create/update dynamic light using the entity index as key
    local dlight = DynamicLight(self.DLightIndex)
    if dlight then
        dlight.pos = pos
        dlight.r = self._USER_COLOR.r
        dlight.g = self._USER_COLOR.g
        dlight.b = self._USER_COLOR.b

        -- Brightness fades linearly
        dlight.brightness = self.BaseBrightness * remaining

        -- Radius also fades linearly (keeps visual parity with brightness)
        dlight.size = math.max(1, math.floor(self.BaseRadius * remaining))

        -- decay: 1000 / fadeOutTimeInSeconds (avoid div-by-zero)
        local fadeTime = math.max(0.001, self.LifeTime)
        dlight.decay = 1000 / fadeTime

        dlight.dietime = self.DieTime

        -- Optional flags to match Niagara behavior: do not use inverse-sq falloff,
        -- and light the world/models normally.
        dlight.noworld = false
        dlight.nomodel = false

        -- style 0 default (no flicker). You can set style to experiment.
        dlight.style = 0
    end

    return true
end

function EFFECT:Render()
    -- Optionally render a small additive sprite where the light is.
    -- This helps see the effect in-game; remove if undesired.
    if CurTime() >= self.DieTime then return end

    local pos
    if IsValid(self.Entity) then
        -- attempt the same position resolution used in Think
        if self.Attachment and self.Attachment != 0 then
            local att = self.Entity:GetAttachment(self.Attachment)
            if att and att.Pos then pos = att.Pos end
        end
        if !pos and self.Bone and self.Bone >= 0 then
            local bonePos = self.Entity:GetBoneMatrix(self.Bone) 
			bonePos = bonePos and bonePos:GetTranslation() 
            if bonePos then
                pos = bonePos 
            end
        end
        if !pos then
            pos = self.Entity:LocalToWorld(self.LocalPos)
        end
    end
    pos = pos or self.WorldPos or (IsValid(self.Entity) and self.Entity:GetPos()) or Vector(0,0,0)

    local remaining = math.Clamp((self.DieTime - CurTime()) / self.LifeTime, 0, 1)
    local size = math.max(2, math.floor(self.BaseRadius * remaining * 0.1)) -- small sprite

    render.SetMaterial(self.SpriteMat)
    render.DrawSprite(pos, size*10, size*10, Color(self._USER_COLOR.r, self._USER_COLOR.g, self._USER_COLOR.b, math.floor(255 * remaining)))
end
