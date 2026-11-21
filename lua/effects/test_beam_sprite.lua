EFFECT.Mat = Material("effects/spark") -- Change to your desired texture

function EFFECT:Init(data)
    local startPos = data:GetStart()
    local endPos   = data:GetOrigin()
    local flags    = data:GetFlags()
	local dieTime = data:GetMagnitude() 

    local diff = endPos - startPos
    local totalDist = diff:Length()
    if totalDist <= 0 then return end

    local dir = diff:GetNormalized()
    local spawnPos = (flags == 2) and endPos or startPos

    local emitter = ParticleEmitter(spawnPos)
    if not emitter then return end

    local particle = emitter:Add(self.Mat, spawnPos)
    if particle then

        particle:SetDieTime(dieTime)
        particle:SetStartSize(16)
        particle:SetEndSize(16)
        particle:SetStartAlpha(255)
        particle:SetEndAlpha(255)
        particle:SetColor(255, 255, 255)

        -- Direction of elongation determined by velocity direction
        particle:SetVelocity(dir * 0.0001)

        -- Handle behavior based on flags
        if flags == 0 then
            -- Case 0: Stays at full length throughout
            particle:SetStartLength(totalDist)
            particle:SetEndLength(totalDist)

        elseif flags == 1 then
            -- Case 1: Grows from 0 to full length over total die time
            particle:SetStartLength(0)
            particle:SetEndLength(totalDist)

        elseif flags == 2 then
			-- Case 2: Travels startPos -> endPos, shrinking totalDist -> 0
            local speed = totalDist / dieTime
            particle:SetVelocity(dir * speed)
            particle:SetStartLength(totalDist)
            particle:SetEndLength(0)

        elseif flags == 3 then
            particle:SetVelocity(dir * 0.001)
            particle:SetStartLength(0)
            particle:SetEndLength(2 * totalDist) -- Hits full length (totalDist) at 50% lifetime

            -- Phase 2 (50% to 100% life): Travels startPos -> endPos in remaining time, shrinking totalDist -> 0
            particle:SetThinkFunction(function(p)
                local remainingTime = p:GetDieTime() * 0.5
                local speed = totalDist / remainingTime
                p:SetVelocity(dir * speed)

                -- At lifetime fraction 0.5, Lerp(0.5, 2 * totalDist, 0) evaluates to totalDist (seamless handoff)
                p:SetStartLength(2 * totalDist)
                p:SetEndLength(0)
            end)

            particle:SetNextThink(CurTime() + dieTime * 0.5)
        end
    end

    emitter:Finish()
end

function EFFECT:Think()
    return false -- Effect initialization handles emitter creation
end

function EFFECT:Render()
    -- Particles render automatically
end