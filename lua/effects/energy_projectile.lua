-- File: lua/effects/energy_projectile.lua
function EFFECT:Init(data)
    -- self.Pos = data:GetOrigin()
    self.Pos = Entity(1):EyePos() 
    self.Dir = data:GetNormal() or Vector(0,0,1)
    self.LifeTime = 1
    self.DieTime = CurTime() + self.LifeTime

    self.Emitter = ParticleEmitter(self.Pos)

    -- Flash burst at spawn
    local p = self.Emitter:Add("sprites/light_glow02_add", self.Pos)
    if p then
        p:SetVelocity(self.Dir * 80)
        p:SetDieTime(0.2)
        p:SetStartAlpha(255)
        p:SetEndAlpha(0)
        p:SetStartSize(30)
        p:SetEndSize(0)
        p:SetColor(255, 255, 255)
    end

    -- Store beam points for mesh
    self.BeamPoints = {}
    self.LastPos = self.Pos
end

function EFFECT:Think()
    if CurTime() > self.DieTime then
        if self.Emitter then self.Emitter:Finish() end
        return false
    end

    -- Trail particle
    local p = self.Emitter:Add("sprites/light_glow02_add", self.Pos)
    if p then
        p:SetVelocity(self.Dir * 500)
        p:SetDieTime(0.35)
        p:SetStartAlpha(220)
        p:SetEndAlpha(0)
        p:SetStartSize(14)
        p:SetEndSize(2)
        p:SetColor(180 + math.random(0,75), 200 + math.random(0,55), 255)
        p:SetRoll(math.Rand(0, 360))
        p:SetRollDelta(math.Rand(-2, 2))
    end

    -- Advance projectile position
    self.Pos = self.Pos + self.Dir * FrameTime() * 1200

    -- Record beam trail points
    table.insert(self.BeamPoints, 1, {pos = self.Pos, time = CurTime()})
    -- Keep only recent points
    for i = #self.BeamPoints, 1, -1 do
        if CurTime() - self.BeamPoints[i].time > 0.25 then
            table.remove(self.BeamPoints, i)
        end
    end

    return true
end

function EFFECT:Render()
    -- Glowing projectile core sprite
    render.SetMaterial(Material("sprites/light_glow02_add"))
    render.DrawSprite(self.Pos, 20, 20, Color(200, 230, 255, 255))

    -- Beam mesh
    if #self.BeamPoints > 1 then
        render.SetMaterial(Material("sprites/light_glow02_add"))
        mesh.Begin(MATERIAL_TRIANGLE_STRIP, (#self.BeamPoints - 1) * 2)

        for i, point in ipairs(self.BeamPoints) do
            local age = CurTime() - point.time
            local alpha = math.Clamp(255 * (1 - age / 0.25), 0, 255)
            local size = 12 * (1 - age / 0.25)

            local right = self.Dir:Angle():Right()
            local offset = right * size

            mesh.Position(point.pos + offset)
            mesh.Color(180, 220, 255, alpha)
            mesh.TexCoord(0, 0, i / #self.BeamPoints)
            mesh.AdvanceVertex()

            mesh.Position(point.pos - offset)
            mesh.Color(180, 220, 255, alpha)
            mesh.TexCoord(0, 1, i / #self.BeamPoints)
            mesh.AdvanceVertex()
        end

        mesh.End()
    end
end
