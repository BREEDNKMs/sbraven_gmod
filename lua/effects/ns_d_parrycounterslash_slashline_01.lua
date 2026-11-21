local flConstantSpeed = 0 -- Set > 0 (e.g. 500) to override calculated speed. 0 = calculate dynamically.

function EFFECT:Init(data)
    local ent = data:GetEntity()
    if not IsValid(ent) then return end

    self:SetOwner(ent)
    
    local time = data:GetMagnitude()
    self.DieTime = 0.1 
    self.CreationTime = CurTime()
    self.LastThinkTime = CurTime()

    -- Bone 0 tracking initial setup
    local bonePos = ent:GetBonePosition(0)
    if not bonePos or bonePos:IsZero() then bonePos = ent:GetPos() end

    self.LastBonePos = bonePos
    self.MoveDir = ent:GetForward()
    self.Speed = flConstantSpeed > 0 and flConstantSpeed or 0

    self.Emitter = ParticleEmitter(bonePos, false)

    -- Particle setup helper with SetThinkFunction binding
    local function attachParticle(particle, isSpike, isTrail)
        if not particle then return end

        local localOffset = isSpike and (VectorRand() * 40) or vector_origin
        particle:SetVelocityScale(true)
        particle:SetDieTime(self.DieTime)
        particle:SetColor(128, 255, 255)

        if isSpike then
            particle:SetStartSize(4)
            particle:SetEndSize(4)
        elseif isTrail then
            particle:SetStartSize(64)
            particle:SetEndSize(4)
            particle:SetColor(255, 255, 255)
        else
            particle:SetStartSize(128)
            particle:SetEndSize(64)
        end

        particle:SetThinkFunction(function(p)
            if not IsValid(self) or not IsValid(ent) then return end

            local curBonePos = ent:GetBonePosition(0)
            if not curBonePos or curBonePos:IsZero() then curBonePos = ent:GetPos() end
			local backwards = -(self.MoveDir * (self.Speed*0.01))
			curBonePos = curBonePos + backwards 

            p:SetPos(curBonePos + localOffset)

            if self.Speed > 1 then
                local speedFactor = math.Clamp(self.Speed, 100, 2500)
				speedFactor = speedFactor * 0.2
                p:SetVelocity(self.MoveDir * speedFactor)

                if isSpike then
                    p:SetStartLength(0.1 * (speedFactor / 200))
                    p:SetEndLength(0.5 * (speedFactor / 200))
                elseif isTrail then
                    p:SetStartLength(0.5 * (speedFactor / 300))
                    p:SetEndLength(0.1 * (speedFactor / 300))
                else -- main glow 
                    p:SetStartLength(2 * (speedFactor / 400))
                    p:SetEndLength(1 * (speedFactor / 400))
                end
            end

            p:SetNextThink(CurTime())
        end)

        particle:SetNextThink(CurTime())
    end

    -- 1. Main Glow
    local mainGlow = self.Emitter:Add("sprites/glow04_noz_gmod", bonePos)
    attachParticle(mainGlow, false, false)

    -- 2. Surrounding Spikes
    for i = 1, 10 do
        local spike = self.Emitter:Add("sprites/glow04_noz_gmod", bonePos)
        attachParticle(spike, true, false)
    end

    -- 3. Trail
    local trail = self.Emitter:Add("sprites/glow04_noz_gmod", bonePos)
    attachParticle(trail, false, true)
end

function EFFECT:Think()
    local ent = self:GetOwner()
    if not IsValid(ent) or CurTime() > self.CreationTime + self.DieTime then
        if IsValid(self.Emitter) then self.Emitter:Finish() end
        return false
    end

    local curTime = CurTime()
    local dt = curTime - (self.LastThinkTime or curTime)
    self.LastThinkTime = curTime

    local curBonePos = ent:GetBonePosition(0)
    if not curBonePos or curBonePos:IsZero() then curBonePos = ent:GetPos() end

    if dt > 0 and self.LastBonePos then
        local delta = curBonePos - self.LastBonePos
        local dist = delta:Length()

        if dist > 0.001 then
            self.MoveDir = delta / dist
            
            if flConstantSpeed > 0 then
                self.Speed = flConstantSpeed
            else
                self.Speed = dist / dt
            end
        end
    end

    self.LastBonePos = curBonePos
    self:SetPos(curBonePos)
    self:SetNextClientThink(curTime + FrameTime())
    return true
end

function EFFECT:Render()
    if not IsValid(self.Emitter) then return end

    for i = 1, 5 do
        self.Emitter:Draw()
    end
end