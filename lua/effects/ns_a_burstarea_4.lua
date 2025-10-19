local MaterialFrames = {
    "sprites/t_a_amberparticle_01_000.vmt",
    "sprites/t_a_amberparticle_01_001.vmt",
    "sprites/t_a_amberparticle_01_002.vmt",
    "sprites/t_a_amberparticle_01_003.vmt"
}

function EFFECT:Init(data)
    self:SetPos(data:GetOrigin())

    -- Burst scaling and lifetime multipliers
    self.Scale    = data:GetScale() ~= 0 and data:GetScale() or 1
    self.LifeTime = data:GetMagnitude() ~= 0 and data:GetMagnitude() or 1

    -- Deterministic seed (from Niagara User.Seed01 = 22)
    math.randomseed(22)

    -- Niagara User.Radius = 300
    local radius = 300 * self.Scale

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
        local pos = self:GetPos() + dir * math.Rand(0, radius)

        local particle = emitter:Add(MaterialFrames[1], pos)
        if particle then
            -- Velocity outward, scaled
            particle:SetVelocity(dir * math.Rand(200, 400) * self.Scale)

            -- Lifetime (short sparks, 0.4–0.8s scaled by LifeTime)
            local life = math.Rand(0.4, 0.8) * self.LifeTime
            particle:SetDieTime(life)

            -- Start/end size
            local startSize = math.Rand(4, 8) * sizeMult
            particle:SetStartSize(startSize)
            particle:SetEndSize(0)

            -- Rotation
            particle:SetRoll(math.Rand(0, 360))
            particle:SetRollDelta(math.Rand(-4, 4))

            -- Color fade (white → yellow → orange → transparent)
            particle:SetColor(255, 255, 200)
            particle:SetStartAlpha(255)
            particle:SetEndAlpha(0)

            -- Gravity/drag for natural spark falloff
            particle:SetGravity(Vector(0, 0, -200))
            particle:SetAirResistance(50)

            -- Animate material frames over lifetime
            particle.Frame = 1
            particle.NextFrame = CurTime() + (life / #MaterialFrames)
            particle:SetThinkFunction(function(p)
                if CurTime() >= p.NextFrame then
                    p.Frame = p.Frame + 1
                    if p.Frame <= #MaterialFrames then
                        p:SetMaterial(MaterialFrames[p.Frame])
                        p.NextFrame = CurTime() + (life / #MaterialFrames)
                        p:SetNextThink(CurTime())
                    end
                end
            end)
            particle:SetNextThink(CurTime())
        end
    end

    emitter:Finish()
end

function EFFECT:Think()
    -- Effect ends when all particles die
    return false
end

function EFFECT:Render()
    -- Rendering handled by particles themselves
end
