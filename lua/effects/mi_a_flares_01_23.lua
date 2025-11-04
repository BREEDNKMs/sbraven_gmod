--[[
  EFFECT:         MI_A_Flares_01_23
  DESCRIPTION:    Replicates the Niagara sprite renderer effect "MI_A_Flares_01_23" for Garry's Mod.
                  This script creates a continuous, looping flare/glow effect attached to an entity.
  NOTES:          The behavior is derived from the provided JSON properties.
                  - Material:       sprites/MI_A_Flares_01_23
                  - Initial Color:  (255, 255, 255)
                  - Initial Size:   100x100
]] 

-- The material we defined in the VMT file. 
local FLARE_MATERIAL = Material("sprites/MI_A_Flares_01_23") 
EFFECT.EmitInterval = 1.0  -- 1 particle per second 

---
-- Called when the effect is first created.
-- We set up the emitter and attach it to the target entity.
-- @param {EffectData} data The data sent to the effect, containing the entity.
--
function EFFECT:Init(data)
    -- Get the entity that this effect is attached to.
    self.Entity = data:GetEntity()

    -- Ensure the entity is valid before proceeding.
    if not IsValid(self.Entity) then return end
	-- Flag = 1  →  kill effect on same entity
	if data:GetFlags() == 1 then
		for _, fx in ipairs(ents.GetAll()) do
			if fx:GetClass() == "class CLuaEffect" and fx.Ent == self.Ent then
				SafeRemoveEntity(fx)
			end
		end
		SafeRemoveEntity(self)
		return
	end

    -- Set the effect's initial position to the entity's position.
    self.Pos = self.Entity:GetPos()
    self:SetPos(self.Pos)
	self:SetParent(self.Entity) 

    -- Create a CLuaEmitter to handle the particle simulation and rendering.
    self.Emitter = ParticleEmitter(self.Pos, true)
	self.ActiveParticles = { } 
	self.NextEmit = 0 
end

---
-- Called every frame.
-- This is the main loop where we check the entity's status and emit particles.
-- @returns {boolean} false to kill the effect, true to continue.
--
function EFFECT:Think()
    -- If the entity is no longer valid or is dead, stop the effect.
    if not IsValid(self.Entity) or not self.Entity:Alive() then
        -- Gracefully release the emitter to let existing particles finish.
        if self.Emitter and self.Emitter:IsValid() then self.Emitter:Finish() end
        return false
    end
	-- print("thinking") 

    -- Update the effect's position to follow the entity.
	local pos = self.Entity:GetPos() 
	-- move this to FX_Weapon_Begin 
	local Bip01_R_Hand = self.Entity:LookupBone("ValveBiped.Bip01_R_Hand") 
	-- print(Bip01_R_Hand,self.Entity) 
	if Bip01_R_Hand then 
		pos = self.Entity:GetBoneMatrix(Bip01_R_Hand) 
		GetShootPos = IsValid(self.Entity:GetOwner()) and self.Entity:GetOwner():GetShootPos() or self:WorldSpaceCenter() 
		pos = pos and pos:GetTranslation() or GetShootPos 
	end 
    self.Pos = pos 
	if !self.Emitter or !self.Emitter:IsValid() then self.Emitter = ParticleEmitter(self.Pos, true) end 
    self.Emitter:SetPos(self.Pos)
	self.NextEmit = self.NextEmit or 0 

	if CurTime() >= self.NextEmit then 
		self.NextEmit = CurTime() + self.EmitInterval 
		for i = 1, 3 do 
			local radius = 20
			local offset = VectorRand():GetNormalized() * math.random(0, radius)
			local spawnPos = self.Pos + offset
			local particle = self.Emitter:Add(FLARE_MATERIAL, spawnPos)
			if not particle then return true end 
			table.insert(self.ActiveParticles,particle) 
			
			-- local lifeTime = 1.2
			-- particle:SetDieTime(lifeTime)

			-- ColorBinding: default VarData (1,1,1,1) → white.
			local t = CurTime()
			local flicker = 0.75 + math.sin(t * 10 + math.Rand(0, 2 * math.pi)) * 0.25
			local color = Vector(0, 0.4, 0.1) * flicker * 255
			particle:SetColor(color.x, color.y, color.z)
			particle.BaseColor = {color.x, color.y, color.z}  -- or whatever curve you apply later

			-- SpriteSizeBinding: VarData decodes to (50,50) in UE units.
			-- This has been scaled down appropriately for Hammer units.
			local baseSize = 1
			local sizeRand = math.Rand(0.8, 1.2)
			particle:SetStartSize(baseSize * sizeRand)
			particle:SetEndSize(baseSize * 0.4 * sizeRand)
			particle:SetDieTime(math.Rand(0.9, 1.4))
			particle.BaseSize = particle:GetStartSize() 

			-- Neutral velocity (VelocityBinding exists, but no default given).
			particle:SetVelocity(Vector(0, 0, 0))
			particle:SetGravity(Vector(0, 0, 0))
			particle:SetAirResistance(0)

			-- Rotation: leave neutral unless Niagara graph specifies otherwise.
			particle:SetRoll(0)
			particle:SetRollDelta(0)

			-- Initialize alpha fully opaque; fade will be handled via NormalizedAge.
			particle:SetStartAlpha(255)
			particle:SetEndAlpha(255)
			local vel = VectorRand() * 2 -- soft turbulence
			particle:SetVelocity(vel)
			particle:SetAirResistance(4)

			-- Store creation time for normalized age calculation.
			particle.createTime = CurTime()

			-- Think function to update alpha based on NormalizedAge.
			particle:SetThinkFunction(function(p)
			
				local function LerpColor(t, c1, c2)
					return Color(
						Lerp(t, c1.r, c2.r),
						Lerp(t, c1.g, c2.g),
						Lerp(t, c1.b, c2.b)
					)
				end

				
				local age = p:GetLifeTime()      -- seconds since spawn
				local dieTime = p:GetDieTime()   -- total lifetime
				local normalizedAge = age / dieTime

				-- Niagara‑style fade: ease in/out using normalized age.
				-- Example: smoothstep fade in/out.
				local fadeIn = math.min(1, normalizedAge / 0.2)           -- first 20% of life
				local fadeOut = 1 - math.max(0, (normalizedAge - 0.7) / 0.3) -- last 30% of life
				local alpha = 255 * math.Clamp(fadeIn * fadeOut, 0, 1)

				p:SetStartAlpha(alpha)
				p:SetEndAlpha(alpha)
				local curl = Vector(math.sin(CurTime() + p:GetPos().y),
							math.sin(CurTime() + p:GetPos().z),
							math.sin(CurTime() + p:GetPos().x)) * 0.5
				local newVel = p:GetVelocity() + curl
				p:SetVelocity(newVel)
				
				local function BrightnessCurve(frac)
					if frac < 0.3 then
						return Lerp(frac / 0.3, 0.2, 1.0)
					else
						return Lerp((frac - 0.3) / 0.7, 1.0, 0.0)
					end
				end
				
				local bright = BrightnessCurve(normalizedAge)
				local colorMul = 255 * bright
				
				local t = CurTime()
				local t2 = math.Clamp(age / dieTime, 0, 1)
				local flicker = 0.75 + math.sin(t * 10 + math.Rand(0, 2 * math.pi)) * 0.25
				-- local flicker = 0.8 + math.sin(CurTime() * 10 + p.Seed) * 0.2
				
				    -- Define color control points
				local c1 = Color(0, 200, 130)
				local c2 = Color(0, 150, 80)
				local c3 = Color(0, 90, 40)
				local c4 = Color(0, 20, 10)
				
				-- local color = Vector(1.0, 0.4, 0.1) * flicker * 255
				
				    -- Map normalized lifetime to color
				local col
				if t2 < 0.3 then
					col = LerpColor(t2 / 0.3, c1, c2)
				elseif t2 < 0.7 then
					col = LerpColor((t2 - 0.3) / 0.4, c2, c3)
				else
					col = LerpColor((t2 - 0.7) / 0.3, c3, c4)
				end
				-- print(col,CurTime()) 
				-- particle:SetColor(color.x, color.y, color.z)
				    p:SetColor(
						col.r * flicker,
						col.g * flicker,
						col.b * flicker
					)
					
				local fade = 1.0
				if t2 < 0.15 then fade = t2 / 0.15 end          -- Fade-in
				if t2 > 0.8 then fade = 1.0 - (t2 - 0.8) / 0.2 end  -- Fade-out
				p:SetStartAlpha(255 * fade)
				p:SetEndAlpha(255 * fade)

				
				-- p:SetColor(colorMul, colorMul, colorMul) 
				-- p:SetColor(colorMul, colorMul, colorMul) 

				-- Schedule next update.
				p:SetNextThink(CurTime() + FrameTime())
			end)
			
			particle:SetRoll(math.Rand(0, 360))
			particle:SetRollDelta(math.Rand(-2, 2)) -- slow spin

			particle:SetNextThink(CurTime() + FrameTime())
		end 
	end 

    -- Keep the effect running.
    return true
end

---
-- Called every frame to render the effect.
-- The CLuaEmitter handles all rendering automatically, so this function is empty.
--
function EFFECT:Render()
    if not (self.Emitter and self.Emitter:IsValid()) then return end

    -- remove dead
    local alive = {}
    for _, p in ipairs(self.ActiveParticles or {}) do
        if p:GetLifeTime() < p:GetDieTime() then
            table.insert(alive, p)
        end
    end
    self.ActiveParticles = alive

    local passes = 5
    local intensityStep = 0.4
    local scaleStep = 0.08

    for i = 1, passes do
        local intensity = 1.0 + (i - 1) * intensityStep
        local scale = 1.0 + (i - 1) * scaleStep

        -- apply render-space color modulation instead of mutating particles
        render.SetColorModulation(intensity, intensity, intensity)
        render.PushFilterMag(TEXFILTER.ANISOTROPIC)
        render.PushFilterMin(TEXFILTER.ANISOTROPIC)

        -- temporary offset size using stored BaseSize
        for _, p in ipairs(self.ActiveParticles) do
            if p.BaseSize then
                p:SetStartSize(p.BaseSize * scale)
                p:SetEndSize(p.BaseSize * scale * 0.8)
            end
        end

        self.Emitter:Draw()

        -- revert back to base size after each pass
        for _, p in ipairs(self.ActiveParticles) do
            if p.BaseSize then
                p:SetStartSize(p.BaseSize)
                p:SetEndSize(p.BaseSize * 0.8)
            end
        end

        render.PopFilterMag()
        render.PopFilterMin()
        render.SetColorModulation(1, 1, 1)
    end
end
