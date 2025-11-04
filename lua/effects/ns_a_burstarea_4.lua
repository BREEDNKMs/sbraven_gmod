local MaterialFrames = {
    "sprites/T_A_BreakCrystal_01_1.vmt",
    "sprites/T_A_BreakCrystal_01_2.vmt",
    "sprites/T_A_BreakCrystal_01_3.vmt",
    "sprites/T_A_BreakCrystal_01_4.vmt",
    "sprites/T_A_BreakCrystal_01_5.vmt",
    "sprites/T_A_BreakCrystal_01_6.vmt",
    "sprites/T_A_BreakCrystal_01_7.vmt",
    "sprites/T_A_BreakCrystal_01_8.vmt"
} 

local function GetAlphaFromCurve(fraction)
    local peakTime = 0.9

    if fraction < peakTime then
        -- Ramp up from 0 to 255 over the first 90% of the life
        return math.Clamp((fraction / peakTime) * 255, 0, 255)
    else
        -- Ramp down from 255 to 0 over the last 10% of the life
        local timeAfterPeak = fraction - peakTime
        local fadeDuration = 1.0 - peakTime
        return math.Clamp((1.0 - (timeAfterPeak / fadeDuration)) * 255, 0, 255)
    end
end

function EFFECT:Init(data)
    self:SetPos(data:GetOrigin())

    -- Burst scaling and lifetime multipliers
    self.Scale    = data:GetScale() ~= 0 and data:GetScale() or 1
    self.LifeTime = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1

    -- Deterministic seed (from Niagara User.Seed01 = 22)
    math.randomseed(22)

    -- Niagara User.Radius = 300
    local radius = 1200 * self.Scale

    -- Niagara User.LineSpawnRate = 240 (particle density)
    local baseCount = 240
    local count = math.floor(baseCount * self.Scale)

    -- Particle scale multiplier (Niagara ParticleScale = 1.75)
    local sizeMult = 1.75 * self.Scale

    local emitter = ParticleEmitter(self:GetPos())
    if not emitter then return end

    for i = 1, count do
        -- Random radial direction
        local dir = VectorRand():GetNormalized()
            local ang = math.rad( (i / count) * 360 ) + math.Rand(0, math.rad(6)) -- slight jitter
        local r = radius * math.sqrt(math.Rand(0, 1))
        local dir2D = Vector(math.cos(ang), math.sin(ang), 0)
        local pos = self:GetPos() + dir2D * r + Vector(0, 0, math.Rand(-60, 60)) -- small Z jitter

		
		local RandomMaterialFrame = MaterialFrames[math.random(1,#MaterialFrames)] 
        local particle = emitter:Add(RandomMaterialFrame, pos)
        if particle then
			particle.StartPos = pos 
            -- Velocity outward, scaled
            particle:SetVelocity(dir2D * math.Rand(200, 400) * self.Scale)

            -- Lifetime (short sparks, 0.4–0.8s scaled by LifeTime)
            local life = math.Rand(0.6, 1.2) * self.LifeTime
            particle:SetDieTime(life)

            -- Start/end size
            local startSize = math.Rand(10, 18) * sizeMult
            particle:SetStartSize(startSize)
            particle:SetEndSize(startSize) 

            -- Rotation
            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(math.Rand(-4, 4))

            -- Color fade (white → yellow → orange → transparent)
            particle:SetColor(255, 200, 120) -- warm crystal (values clamped 0-255)
            particle:SetStartAlpha(0)
            particle:SetEndAlpha(0)

            -- Gravity/drag for natural spark falloff
            particle:SetGravity(Vector(0, 0, -400))
			particle:SetCollide(true)
            particle:SetAirResistance(50)

            -- Animate material frames over lifetime
            particle:SetThinkFunction(self.ParticleThink)
            particle:SetNextThink(CurTime())
        end
    end

    emitter:Finish()
end

function EFFECT:ParticleThink()
    -- Calculate how far along the particle is in its life (0.0 to 1.0)
    local lifetimeFraction = (self:GetLifeTime() / self:GetDieTime()) 
    lifetimeFraction = math.Clamp(lifetimeFraction, 0, 1)

    -- 1. SET ALPHA based on the T_Gradient_Horizon_03 curve
    local currentAlpha = GetAlphaFromCurve(lifetimeFraction)
	local r,g,b = self:GetColor() 
    self:SetStartAlpha(currentAlpha)
    self:SetEndAlpha(currentAlpha)

    -- 2. SIMULATE CURL NOISE for swirling motion
    local pos = self:GetPos()
    local center = self.StartPos
    local toCenter = (center - pos):GetNormalized()
    local swirlForce = toCenter:Cross(Vector(0,0,1)) * 150
    self:SetVelocity(self:GetVelocity() + swirlForce * FrameTime())
    
    -- Keep thinking until the particle dies
    self:SetNextThink(CurTime())
    return true
end

function EFFECT:Think()
    -- Effect ends when all particles die
    return false
end

function EFFECT:Render()
    -- Rendering handled by particles themselves
end
