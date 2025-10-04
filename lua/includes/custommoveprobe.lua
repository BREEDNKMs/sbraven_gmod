-- Hybrid Ground+Fly iterative move probe for GMod NPCs
-- Returns: moveTrace table:
--   .fStatus = "OK" | "BLOCKED_WORLD" | "BLOCKED_ENTITY" | "START_IN_SOLID" | "PARTIAL"
--   .vEndPosition = Vector
--   .vHitNormal = Vector
--   .pObstruction = entity or nil
--   .flDistObstructed = distance along requested vector that was blocked (0..totalDist)
--   .bKeptGround = bool  -- whether the mover stayed on standable ground the whole way
--   .bLeapRequired = bool -- whether reaching final pos requires leaving ground higher than stepHeight

local function CanStandOn(npc, ent)
    if !IsValid(ent) then return false end
    -- In Source SDK, CanStandOn checks for world, props, etc.
    -- In GMod, treat worldspawn and static props as "standable".
    if ent:IsWorld() then return true end
    -- if ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_static" then return true end
    -- You may add further logic for ladders, etc.
    return true -- literally everything is standable, even players. 
end

function IterativeHybridMoveLimit(npc, vecStart, vecEnd, stepSize, maxSteps, opts)
    if !IsValid(npc) then return end

    -- Use collision bounds for hull
    local hullMins, hullMaxs = npc:GetCollisionBounds()

    opts = opts or {}
    stepSize = stepSize or 16
    maxSteps = maxSteps or 128

    local stepHeight = opts.stepHeight or (npc.GetStepHeight and npc:GetStepHeight()) or 18
    local minStepLanding = opts.minStepLanding or (math.max(math.abs(hullMins.x), math.abs(hullMaxs.x)) * 0.33)
    local collisionMask = opts.mask or MASK_NPC

    local dirVec = (vecEnd - vecStart)
    local totalDist = dirVec:Length()
    if totalDist < 1e-4 then
        return {
            fStatus = "OK",
            vEndPosition = vecEnd,
            vHitNormal = Vector(0,0,1),
            pObstruction = nil,
            flDistObstructed = 0,
            bKeptGround = true,
            bLeapRequired = false,
        }
    end
    local dir = dirVec:GetNormalized()

    local curPos = vecStart
    local distTravelled = 0
    local keptGround = true
    local leapRequired = false
    local finalObstruction = nil
    local finalNormal = Vector(0,0,1)

    local MOVE_EPSILON = 0.0625

    local function traceHull(startp, endp)
        return util.TraceHull({
            start = startp,
            endpos = endp,
            mins = hullMins,
            maxs = hullMaxs,
            mask = collisionMask,
            filter = npc
        })
    end

    local function ProbeDown(pos, maxDrop)
        maxDrop = maxDrop or (stepHeight + 64)
        local downStart = pos + Vector(0,0,MOVE_EPSILON)
        local downEnd = pos - Vector(0,0,maxDrop)
        return util.TraceHull({
            start = downStart,
            endpos = downEnd,
            mins = hullMins,
            maxs = hullMaxs,
            mask = collisionMask,
            filter = npc
        })
    end

	local function IsStandable(tr)
		-- First, make sure the trace actually hit something.
		if not tr.Hit then return false end

		-- THE FIX: Check if the entity is the world BEFORE checking IsValid().
		if tr.Entity:IsWorld() then
			-- It's the world, so we only need to check if the surface is flat enough to stand on.
			return tr.HitNormal.z >= 0.7
		end

		-- For any other entity, now we check if it's valid.
		if not IsValid(tr.Entity) then return false end

		-- Finally, run the normal checks for valid, non-world entities.
		if tr.HitNormal.z < 0.7 then return false end
		if !CanStandOn(npc, tr.Entity) then return false end

		return true
	end

    local blockedDist = 0
    local status = "OK"

    for step = 1, maxSteps do
        local remaining = totalDist - distTravelled
        if remaining <= 0 then break end

        local seg = math.min(stepSize, remaining)
        local nextPos = curPos + dir * seg

        local tr = traceHull(curPos, nextPos)

        if tr.StartSolid then
            status = "START_IN_SOLID"
            finalObstruction = tr.Entity
            finalNormal = tr.HitNormal or Vector(0,0,1)
            blockedDist = distTravelled
            break
        end

        if tr.Hit then
            -- =================================================================
            -- 1. COLLISION DETECTED: TRY TO STEP UP
            -- This is a more robust version of your step-up logic.
            -- =================================================================
            local stepUpStart = curPos + Vector(0, 0, stepHeight)
            local stepUpEnd = nextPos + Vector(0, 0, stepHeight)
            local stepTr = traceHull(stepUpStart, stepUpEnd)

            if not stepTr.StartSolid and stepTr.Fraction > 0.01 then
                local downTr = ProbeDown(stepTr.HitPos, stepHeight * 2)
                if downTr.Hit and IsStandable(downTr) then
                    -- We successfully stepped up!
                    curPos = downTr.HitPos + Vector(0, 0, MOVE_EPSILON)
                    distTravelled = (curPos - vecStart):Length() -- Recalculate distance
                    keptGround = true
                    continue
                end
            end

            -- =================================================================
            -- 2. STEP-UP FAILED: TRY TO SLIDE
            -- This is a much safer sliding algorithm.
            -- =================================================================
            local didSlide = false
            local slideDir = dir
            for attempt = 1, 2 do
                local n = tr.HitNormal
                local dot = slideDir:Dot(n)
                slideDir = (slideDir - n * dot):GetNormalized()

                if slideDir:Dot(dir) < 0.5 then -- Don't slide too far from the original direction
                    break
                end

                local slideEnd = curPos + slideDir * seg
                local slideTr = traceHull(curPos, slideEnd)

                if not slideTr.Hit then
                    curPos = slideEnd
                    distTravelled = (curPos - vecStart):Length() -- Recalculate distance
                    didSlide = true
                    break
                else
                    tr = slideTr -- Prepare for the next slide attempt
                end
            end

            if didSlide then
                keptGround = true
                continue
            end

            -- =================================================================
            -- 3. STEP-UP AND SLIDE FAILED: WE ARE BLOCKED
            -- =================================================================
            status = tr.Entity and "BLOCKED_ENTITY" or "BLOCKED_WORLD"
            finalObstruction = tr.Entity
            finalNormal = tr.HitNormal
            blockedDist = distTravelled
            break
        else
            -- Forward move succeeded
            -- Decide whether to hug ground or leap
            local floorTr = ProbeDown(nextPos)
            if floorTr.Hit then
                local dz = vecEnd.z - floorTr.HitPos.z
                if dz > stepHeight then
                    -- Target is too high above ground -> leap
                    leapRequired = true
                    keptGround = false
                    curPos = nextPos
                else
                    -- Within step range -> snap to floor
                    if IsStandable(floorTr) then
                        curPos = floorTr.HitPos + Vector(0,0,MOVE_EPSILON)
                    else
                        -- Too steep/unstandable, treat as leap anyway
                        leapRequired = true
                        keptGround = false
                        curPos = nextPos
                    end
                end
            else
                -- No ground below -> leap
                leapRequired = true
                keptGround = false
                curPos = nextPos
            end
            distTravelled = distTravelled + seg
        end

        if (curPos - vecEnd):Length() <= 1.0 then
            status = "OK"
            break
        end
    end

    local moveTrace = {
        fStatus = status,
        vEndPosition = curPos,
        vHitNormal = finalNormal,
        pObstruction = finalObstruction,
        flDistObstructed = (status == "OK") and 0 or distTravelled,
        bKeptGround = keptGround,
        bLeapRequired = leapRequired,
    }
	-- PrintTable(moveTrace) 

    return moveTrace
end

return IterativeHybridMoveLimit 