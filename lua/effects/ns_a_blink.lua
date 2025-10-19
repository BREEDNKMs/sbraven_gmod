local function SafeMaterial(path)
    local mat = Material(path)
    if mat and not mat:IsError() then return mat end
    return Material("sprites/white")
end

-- Material bindings (replace with your actual materials)
local MAT_LENS  = SafeMaterial("sprites/MI_B_LensCircle_01_23")
local MAT_AFTER = SafeMaterial("sprites/MI_B_LensCircle_01_15_AfterDof")
local MAT_FLARE = SafeMaterial("sprites/MI_A_Flares_01_8")
local MAT_SPARK = SafeMaterial("sprites/MI_A_GPUSparks_01_Tr_000")
local MAT_SMOKE = SafeMaterial("sprites/MI_Smokes_Ad_01_2")
local MAT_BLUR  = SafeMaterial("sprites/MI_A_ParNoiseBlur_01_1")

function EFFECT:Init(data)
    local ent = data:GetEntity()
    local entPos = IsValid(ent) and ent:GetPos() or nil
    local localPos = data:GetOrigin() or vector_origin
    local ang = data:GetAngles() or Angle(0,0,0)
    local life = math.max(0.01, data:GetMagnitude() or 0.6)
    local scale = math.max(0.01, data:GetScale() or 1.0)
	self.Entity = data:GetEntity() 
	-- print("magnitude is:",life) 

    -- resolve world-space origin
    local origin = entPos or localPos or vector_origin
    if localPos and localPos ~= vector_origin then
        origin = localPos
        if entPos and localPos:Distance(entPos) > 10000 then
            origin = entPos + localPos
        end
    end
	
	self.Attachment = data:GetAttachment() 
    self.Origin = origin
    self.Angles = ang
    self.Life = life
    self.Scale = scale
    self.StartTime = CurTime()
    self.EndTime = self.StartTime + life
    self.Alive = true
    self.LastThink = CurTime()
    self.SmokeAccumulator = 0
    self.GlintAccumulator = 0

    self.Emitter = ParticleEmitter(self.Origin)
    if not self.Emitter then return end

    -- ======================================================
    -- BURST EMITTERS (one-shot at init)
    -- ======================================================

    -- Main lens flare burst
    do
        local p = self.Emitter:Add(MAT_LENS, self.Origin)
        if p then
            p:SetVelocity(Vector(0,0,0))
            p:SetDieTime(0.08 + life * 0.2)
            p:SetStartAlpha(255)
            p:SetEndAlpha(0)
            p:SetStartSize(3.2 * scale)
            p:SetEndSize(16.0 * scale)
            p:SetRoll(math.Rand(0,360))
            p:SetLighting(false)
        end

        local p2 = self.Emitter:Add(MAT_AFTER, self.Origin)
        if p2 then
            p2:SetVelocity(Vector(0,0,0))
            p2:SetDieTime(0.25 + life * 0.2)
            p2:SetStartAlpha(180)
            p2:SetEndAlpha(0)
            p2:SetStartSize(6.4 * scale)
            p2:SetEndSize(24.0 * scale)
            p2:SetRoll(math.Rand(0,360))
            p2:SetLighting(false)
        end
    end

    -- Directional sparks
    do
        local count = math.Clamp(10 + life * 40, 12, 32)
        for i = 1, count do
            local dir = VectorRand()
            dir.z = math.abs(dir.z) * 0.6 + 0.2
            if ang and ang ~= Angle(0,0,0) then
                dir = (dir * 0.6 + ang:Forward() * 0.4):GetNormalized()
            end

            local speed = math.Rand(250, 600)
            local p = self.Emitter:Add(MAT_SPARK, origin + dir * 2)
            if p then
                p:SetVelocity(dir * speed)
                p:SetDieTime(math.Rand(0.15, 0.25))
                p:SetStartAlpha(255)
                p:SetEndAlpha(0)
                p:SetStartSize(0.3 * scale)
                p:SetEndSize(0.1 * scale)
                p:SetAirResistance(6)
                p:SetGravity(Vector(0, 0, -80))
                p:SetLighting(false)
            end
        end
    end

    -- Target flare flash
    do
        local p = self.Emitter:Add(MAT_FLARE, origin)
        if p then
            p:SetVelocity(Vector(0,0,0))
            p:SetDieTime(0.15)
            p:SetStartAlpha(255)
            p:SetEndAlpha(0)
            p:SetStartSize(2.4 * scale)
            p:SetEndSize(6.4 * scale)
            p:SetRoll(math.Rand(0,360))
            p:SetLighting(false)
        end
    end

    -- Blur / distortion layer
    do
        local p = self.Emitter:Add(MAT_BLUR, origin)
        if p then
            p:SetVelocity(Vector(0,0,0))
            p:SetDieTime(life)
            p:SetStartAlpha(160)
            p:SetEndAlpha(0)
            p:SetStartSize(6.4 * scale)
            p:SetEndSize(0.0 * scale)
            p:SetRoll(math.Rand(0,360))
            p:SetLighting(false)
        end
    end

    -- Light flash
    local dlight = DynamicLight(self:EntIndex() or 0)
    if dlight then
        dlight.pos = self.Origin
        dlight.r = 255
        dlight.g = 220
        dlight.b = 255
        dlight.Brightness = 2.4
        dlight.Decay = 2000
        dlight.Size = 25.6 * scale
        dlight.DieTime = CurTime() + math.min(life, 0.5)
    end
end

function EFFECT:Think()
    if not self.EndTime or not self.Emitter then return false end
    local now = CurTime()
    if now >= self.EndTime then
        self.Alive = false
        self.Emitter:Finish()
        return false
    end
	
	-- update self.Origin 
	if self.Attachment > 0 then 
		self.Origin = self.Entity:GetAttachment(self.Attachment).Pos 
	end 

    local dt = now - (self.LastThink or now)
    self.LastThink = now

    local tfrac = math.Clamp((now - self.StartTime) / self.Life, 0, 1)
    local life = self.Life
    local scale = self.Scale

    -- ================================
    -- Continuous emission per frame
    -- ================================

    -- Smoke (NE_SmokeM): spawn ~100 particles per sec, originally 24 
	-- print("self.SmokeAccumulator:",self.SmokeAccumulator) 
    self.SmokeAccumulator = self.SmokeAccumulator + dt * 100
    while self.SmokeAccumulator >= 1 do
        self.SmokeAccumulator = self.SmokeAccumulator - 1
        local rdir = VectorRand() * 6
        local p = self.Emitter:Add(MAT_SMOKE, self.Origin + rdir)
        if p then
			-- print(p) 
            p:SetVelocity(VectorRand() * 40 + Vector(0,0,20))
            p:SetDieTime(math.Rand(0.8, 1.4) * life)
            p:SetStartAlpha(240)
            p:SetEndAlpha(0)
            p:SetStartSize(math.Rand(2, 6) * scale)
            p:SetEndSize(math.Rand(3, 6) * scale)
            p:SetRoll(math.Rand(0,360))
            p:SetLighting(false)
        end
    end

    -- Small glints (SpriteM001_2 / M002_1): ~100 per sec, originally 14 
    self.GlintAccumulator = self.GlintAccumulator + dt * 100
	-- print("self.GlintAccumulator:",self.GlintAccumulator) 
    while self.GlintAccumulator >= 1 do
        self.GlintAccumulator = self.GlintAccumulator - 1
        local offset = VectorRand() * 8
		for i = 1, 1 do 
			local p = self.Emitter:Add(MAT_FLARE, self.Origin + offset)
			if p then
				-- print(p) 
				p:SetVelocity(VectorRand() * 48)
				p:SetDieTime(0.2 + math.Rand(0.1, 0.2))
				p:SetStartAlpha(200)
				p:SetEndAlpha(0)
				p:SetStartSize(5.4 * scale)
				p:SetEndSize(8.4 * scale)
				p:SetLighting(false)
			end
		end 
    end

    return true
end
function EFFECT:Render() end -- override to disable DrawModel() rendering 