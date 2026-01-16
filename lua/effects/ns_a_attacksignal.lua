--[[
  EFFECT: NS_A_AttackSignal
  
  Description:
  Recreates the multi-layered "Attack Signal" slash/parry effect from Stellar Blade.
  This effect is composed of multiple, precisely layered sprites that activate 
  simultaneously to create a single, impactful flash. Each layer uses a different
  material and rendering order to build up the final look.

  The VMT files for these materials should be located in the 'materials/sprites/' folder.
]]

EFFECT.Mat = {} -- Table to hold all the material references

-- Pre-cache all the materials that will be used by the effect emitters.
-- This is more efficient than loading them individually inside the Init function.
EFFECT.Mat[1] = Material("sprites/MA_A_RainbowRings")
EFFECT.Mat[2] = Material("sprites/MI_E_Mario_Cross01")
EFFECT.Mat[3] = Material("sprites/MI_E_LensFlare_05")
EFFECT.Mat[4] = Material("sprites/MI_E_LensFlare_02")
EFFECT.Mat[5] = Material("sprites/MI_E_LensFlare_03")
EFFECT.Mat[6] = Material("sprites/MA_A_ParShapeBlur_01")

-- I think MA_A_RainbowRings is a curve map on how the materials to be rendered will have its color set 
-- I don't know how source would handle this 
-- so I just omit 

function EFFECT:Init(data)
    local pos   = data:GetOrigin()
    local life = math.max(0.01, data:GetMagnitude() or 0.6) 
    local scale = data:GetScale() 
	scale = scale * 10 
    self.Emitter = ParticleEmitter(pos, false)

    -- Cross Flare (bluish white)
    self:CreateParticle(pos, scale*1.5, self.Mat[2], 0.2, 200, 45, false, Color(200,220,255), 0, "shrink")

    -- Sharp Lens Flare (neutral white, no velocity)
    self:CreateParticle(pos, scale*1.2, self.Mat[3], 0.25, 230, 0, false, Color(255,255,255), 0, "steady")

    -- Blurred Lens Flare (slight magenta tint)
    self:CreateParticle(pos, scale * 2.0, self.Mat[4], 0.3, 220, 90, false, Color(255,200,220), 0)

    -- Secondary Lens Flare (warm tint)
    self:CreateParticle(pos, scale * 1.8, self.Mat[5], 0.3, 255, 25, false, Color(255,220,200), 0)

    -- Rainbow Rings (rotating, additive)
    -- self:CreateParticle(pos, scale*1.0, self.Mat[1], 0.4, 180, 0, true, Color(255,255,255), 0, "expand")

    -- Tertiary Lens Flare (cool tint)
    self:CreateParticle(pos, scale * 2.2, self.Mat[5], 0.35, 255, -25, false, Color(200,240,255), 0)

    -- Background Shape Blur (soft, faint)
    self:CreateParticle(pos, scale * 2.5, self.Mat[6], 0.25, 150, 0, false, Color(255,255,255), 0)
end

function EFFECT:CreateParticle(pos, size, mat, lifetime, start_alpha, angle, should_rotate, col, velMag, mode)
    local particle = self.Emitter:Add(mat, pos)
    if not particle then return end

    particle:SetDieTime(lifetime)
    particle:SetStartAlpha(start_alpha) 
    particle:SetEndAlpha(0)

    if mode == "shrink" then
        particle:SetStartSize(size * 1.1)
        particle:SetEndSize(size * 0.9)
    elseif mode == "expand" then
        particle:SetStartSize(size * 0.6)
        particle:SetEndSize(size * 1.2)
    elseif mode == "steady" then
        particle:SetStartSize(size)
        particle:SetEndSize(size * 0.95)
    else
        -- default expand
        particle:SetStartSize(size * 0.5)
        particle:SetEndSize(size)
    end

    particle:SetRoll(angle)
    if should_rotate then
        particle:SetRollDelta(math.Rand(-150, 150))
    end
    if col then particle:SetColor(col.r, col.g, col.b) end
	-- print("color:",col) 
    particle:SetVelocity(VectorRand() * 5)
    particle:SetAirResistance(100)
    particle:SetGravity(Vector(0,0,20))
end

-- The Render() function is called for every frame the effect is active.
-- Since all logic is handled by the particle properties (fade, scale), we just need an empty function.
function EFFECT:Render()
    -- Intentionally left blank.
    -- The engine handles rendering based on the properties set in Init().
end

-- Think() is called for logic ticks. Not needed here.
function EFFECT:Think()
	if self.Emitter then 
		if self.Emitter:IsValid() then self.Emitter:Finish() end 
	end 
    return false -- Return false when the effect is finished to clean it up
end