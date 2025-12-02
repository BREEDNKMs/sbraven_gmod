local tblWeapons = { "raven_blade" } 

player_manager.AddValidModel( "Raven", "models/alvaroports/SBRavenPM.mdl" ) 
player_manager.AddValidHands( "Raven", "models/alvaroports/SBRavenVM.mdl", 0, "0000000" ) 
list.Set( "PlayerOptionsAnimations", "Raven", { "Idle_subtle" } )

local flRescale = 0.42 
local flRescale = 1 

local NPC = {
	Name = "Raven (Friend)",
	Class = "npc_sb_raven",
	Category = "Other",
	Weapons = tblWeapons,
	Model = "models/alvaroports/sbravenpm.mdl",
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PLAYER }
} 

list.Set( "NPC", "CH_M_NA_53", NPC ) 

NPC = {
	Name = "Raven (Enemy)",
	Class = "npc_sb_raven",
	Category = "Other",
	Weapons = tblWeapons,
	Model = "models/alvaroports/sbravenpm.mdl",
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PORTAL_TURRET }
} 

list.Set( "NPC", "CH_M_NA_53_enemy", NPC ) 

hook.Add("PostPlayerDraw","sbravenpm_coreglow",function(ply) 
	if !IsValid(ply) then return end 
	if !ply:Alive() then return end 
	local attachment = { ["FX_Core_01"] = 8, ["FX_Core_02"] = 4, ["FX_Core_03"] = 2, ["FX_Core_04"] = 2} 
	for attachmentname, scale in pairs(attachment) do 
		local attachmentid = ply:LookupAttachment(attachmentname) 
		if attachmentid > 0 then 
			local Pos = ply:GetAttachment(attachmentid).Pos -- Pos will be used 
			local Material = Material("sprites/t_a_shineflare_02") 
			render.SetMaterial(Material) 
			for i = 1,math.random(1,3) do 
				render.DrawSprite(Pos,scale,scale,Color(0,255,255)) 
			end 
		end 
	end 
end) 

-- flIntervalUsed: time interval (float)
-- layerID: optional layer index (number) - when provided and valid, use layer (gesture) sequence movement
-- Returns: moved, newPosition (Vector), newAngles (Angle), bMoveSeqFinished (bool)
local function GetIntervalMovement(ent, flIntervalUsed, layerID)
    local useLayer = false
    if layerID ~= nil and ent.IsValidLayer and ent:IsValidLayer(layerID) then
        useLayer = true
    end

    -- choose sequence/cycle/playback/duration source (layer vs main)
    local sequence
    local playbackRate
    local cycle
    local duration

    if useLayer then
        sequence = ent:GetLayerSequence(layerID)
        cycle = ent:GetLayerCycle(layerID) or 0
        playbackRate = ent:GetLayerPlaybackRate(layerID) or ent:GetPlaybackRate() or 1
        duration = ent:SequenceDuration(sequence) or 0
    else
        local sequenceFromOuter = seq -- keep previous behavior if `seq` exists in outer scope
        sequence = sequenceFromOuter or ent:GetSequence()
        if not sequence or sequence < 0 then
            return false, ent:GetPos(), ent:GetLocalAngles(), false
        end
        cycle = ent:GetCycle() or 0
        playbackRate = ent:GetPlaybackRate() or 1
        duration = ent:SequenceDuration(sequence)
    end

    local flComputedCycleRate = (duration ~= 0) and (1 / duration) or 0
    local flNextCycle = cycle + flIntervalUsed * flComputedCycleRate * playbackRate
    local bMoveSeqFinished = false

    -- Determine whether sequence loops by checking STUDIO_LOOPING flag (bit 1) via GetSequenceInfo
    local function SequenceLoopsByFlags(ent, seqid)
        if not seqid then return false end
        if not ent.GetSequenceInfo then return false end
        local info = ent:GetSequenceInfo(seqid)
        if not info or not info.flags then return false end
        return bit.band(info.flags, 1) >= 1 -- 1 == STUDIO_LOOPING
    end

    local bSeqLoops = SequenceLoopsByFlags(ent, sequence)

    if not bSeqLoops and flNextCycle > 1.0 then
        if flComputedCycleRate * playbackRate ~= 0 then
            flIntervalUsed = cycle / (flComputedCycleRate * playbackRate)
        else
            flIntervalUsed = 0
        end
        flNextCycle = 1.0
        bMoveSeqFinished = true
    end

    -- get root movement for the sequence (startCycle -> flNextCycle)
    local ok, deltaPos, deltaAng = ent:GetSequenceMovement(sequence, cycle, flNextCycle)
    if not ok then
        return false, ent:GetPos(), ent:GetLocalAngles(), bMoveSeqFinished
    end

    -- if using a layer, scale the root movement by layer weight so partial blends are respected
    if useLayer then
        local weight = ent.GetLayerWeight and ent:GetLayerWeight(layerID) or 1
        if deltaPos and weight ~= 1 then
            deltaPos = deltaPos * weight
        end
        if deltaAng and weight ~= 1 then
            deltaAng = Angle(deltaAng.p * weight, deltaAng.y * weight, deltaAng.r * weight)
        end
    end

    -- apply entity local angles to delta position (same as original)
    local localAngles = ent:GetLocalAngles()
    if deltaPos then deltaPos:Rotate(localAngles) end
    local newPosition = ent:GetPos() + (deltaPos or Vector(0,0,0))
    local newAngles = Angle(0, localAngles.y + (deltaAng and deltaAng.y or 0), 0)

    return true, newPosition, newAngles, bMoveSeqFinished
end 

hook.Add("Think", "StellarBlade_RunSkills", function() 
	if SERVER then 
		for _,ENT in ents.Iterator() do 
			StellarBlade.MaintainMoveTable(ENT) 
			if !ENT.SBAI_SkillUseCount then ENT.SBAI_SkillUseCount = { } end 
			if ENT.SBAI_ActiveSkill and ENT.SBAI_ActiveSkill.Name then 
				StellarBlade.ProcessActiveSkill(ENT,ENT.SBAI_ActiveSkill) 
			end 
			if ENT.SBAI_ActiveShow or ENT.SBAI_ActiveShow_alt then
				-- scripted_ents.Get("npc_sb_raven").SBAI_MaintainShow(ENT) 
				StellarBlade.MaintainShow(ENT,ENT.SBAI_ActiveShow) 
				StellarBlade.MaintainShow(ENT,ENT.SBAI_ActiveShow_alt) 
				for layerID = 0, 15 do 
					if ENT:IsValidLayer(layerID) then 
						-- print(layerID) 
						local bMoved, newPosition, newAngles, bMoveSeqFinished = GetIntervalMovement(ENT,FrameTime(),layerID) -- true, newPosition, newAngles, bMoveSeqFinished 
						if bMoved then 
							local moveResult = IterativeHybridMoveLimit(ENT, ENT:GetPos(), newPosition) 
							ENT:SetLocalPos(moveResult.vEndPosition) 
							local angles = ENT:GetLocalAngles() 
							ENT:SetLocalAngles(Angle(angles.x,newAngles.y,angles.z)) 
						end 
					end 
				end 
			end 
		end 
	end 
end) 

-- Helper: returns true if vecSpot is inside ent's forward 2D view cone.
-- Uses ent:IsInViewCone for NPCs and mirrors the C++ logic for players/others.
local function FInViewCone(ent, vecSpot)
	-- Prefer the engine implementation for NPCs if present
	if ent.IsInViewCone then return ent:IsInViewCone(vecSpot) end

	-- For players / other entities: replicate CBaseCombatCharacter::FInViewCone(Vector)
	if !IsValid(ent) then error("Entity expected, got "..tostring(ent)) end

	local eyePos = ent:EyePos() 
	local los = vecSpot - eyePos
	los.z = 0
	los = los:GetNormalized() -- returns a normalized vector

	local facingDir = ent.GetEyeAngles and ent:GetEyeAngles():Forward() or ent:GetForward()
	if !facingDir then return false end
	facingDir.z = 0
	facingDir = facingDir:GetNormalized()

	-- m_flFieldOfView in Source is stored as a dot-product threshold (not degrees).
	-- Many NPCs/players may not expose this var; fallback to 0.5 (≈60° cone) if missing.
	local fov = ent:GetInternalVariable("m_flFieldOfView") or nil
	if type(fov) ~= "number" then fov = 0.5 end

	local dot = facingDir:Dot(los)
	return dot > fov
end

hook.Add("EntityTakeDamage", "StellarBlade_DamageEffects", function(target, dmginfo) 
	local attacker = dmginfo:GetAttacker() 
	local inflictor = dmginfo:GetInflictor() 
	
	if target.SBAI_ActiveSkill and target.SBAI_ActiveSkill.Name then 
		local SkillStepTable = target.SBAI_ActiveSkill.Data 
		local Type = SkillStepTable.Type 
		local SkillResultAlias = SkillStepTable.SkillResultAlias 
		if Type == "ESBSkillActiveStepType::SkillActiveStepType_Parry" then 
		
			-- local TargetFilterAlias = SkillStepTable.OverrideTargetFilterAlias 
			-- if !TargetFilterAlias or TargetFilterAlias == "None" then 
				-- if target.SBAI_SkillTable then TargetFilterAlias = target.SBAI_SkillTable.TargetFilterAlias end -- default to SkillTable 
			-- end 
			
			local TargetFilterAlias = target.SBAI_SkillTable.TargetFilterAlias 
			
			-- SkillHitDetectionType_None               = 0,
			-- SkillHitDetectionType_TargetFilter       = 1,
			-- SkillHitDetectionType_ActiveCollision    = 2,
			-- SkillHitDetectionType_TargetFilter_ActiveCollision = 3,
			-- SkillHitDetectionType_MAX                = 4,
			
			local HitDetectionType = SkillStepTable.HitDetectionType 
			-- if string.find(HitDetectionType,"TargetFilter") then 
			local tableofhittargets = StellarBlade.TargetFilter(target,TargetFilterAlias) 
			-- end 
			-- print("TargetFilterAlias:",TargetFilterAlias) 
			-- PrintTable(tableofhittargets) 
			if !table.HasValue(tableofhittargets,attacker) then return end 
		
			local DamagePosition = dmginfo:GetReportedPosition() 
			if DamagePosition:IsZero() then DamagePosition = dmginfo:GetDamagePosition() end 
			if DamagePosition:IsZero() then 
				local inflictor = dmginfo:GetInflictor() 
				if IsValid(inflictor) then 
					DamagePosition = inflictor:GetShootPos() 
				end 
			end 
			local inViewCone = false 
			if target:IsNPC() then 
				inViewCone = target:IsInViewCone(DamagePosition) 
			else 
				inViewCone = FInViewCone(target,DamagePosition) 
			end 
			
			if inViewCone then 
				dmginfo:ScaleDamage(0) 
				if SkillResultAlias != "None" then 
					-- StellarBlade.StartSkillResult(target,dmginfo:GetAttacker(),SkillResultAlias) 
					StellarBlade.StartSkillSelfResult(target,SkillResultAlias) 
					if IsValid(dmginfo:GetAttacker()) then 
						StellarBlade.StartSkillTargetResult(dmginfo:GetAttacker(),SkillResultAlias) 
					end 
				end 
				
				if IsValid(attacker) then 
					if target.SBAI_SkillTable then 
						if !target.SBAI_SkillTable.OnTakeDamage_ParriedEntities then 
							target.SBAI_SkillTable.OnTakeDamage_ParriedEntities = { } 
						end 
						
						if !target.SBAI_SkillTable.OnTakeDamage_ParriedEntities[attacker] then 
							target.SBAI_SkillTable.OnTakeDamage_ParriedEntities[attacker] = 
							{	["Time"] = CurTime(), 
								["Capabilities"] = attacker.CapabilitiesGet and attacker:CapabilitiesGet() or nil 
							} 
						end 
					end 
					if attacker.SBAI_ActiveSkill and attacker.SBAI_ActiveSkill.Type == "ESBSkillActiveStepType::SkillActiveStepType_Hit" then 
						-- force NextStepAliasWhenJustParry 
					
					-- custom parry result data 
					-- for Stellar Blade Actor --> HL2 NPC Interaction 
					elseif attacker:GetClass() == "npc_antlion" then 
						attacker:SetSchedule(ai.GetScheduleID("SCHED_ANTLION_FLIP")) 
					elseif attacker:GetClass() == "npc_hunter" then 
						attacker:SetCondition(attacker:ConditionID("COND_HUNTER_STAGGERED")) 
					elseif isbool(attacker:GetInternalVariable("m_fIsTorso")) then -- is based on npc_basezombie 
						attacker:SetSchedule(ai.GetScheduleID("SCHED_FLINCH_PHYSICS")) 
						-- at that point, remove attacker's range and melee capabilities for 3 seconds 
						-- or until the SBAI_SkillTable is done 
					elseif attacker.SetSchedule and attacker:SelectWeightedSequence(ACT_SMALL_FLINCH) > 1 or attacker:SelectWeightedSequence(ACT_BIG_FLINCH) > 1 then 
						attacker:SetSchedule(SCHED_BIG_FLINCH) 
					elseif attacker.TaskFail then 
						attacker:TaskFail(tostring(target).. " parried attack") 
						local thinkDelayed = attacker:SetSaveValue("m_flNextDecisionTime",3) 
					else 
						-- local thinkDelayed = attacker:SetSaveValue("m_flNextDecisionTime",3) 
						-- if player, apply some viewpunch and drop player's active weapon 
						-- most players will go regrab their dropped weapon 
					end 
				end 
			end 
		end 
	end 
end) 

game.AddParticles( "particles/raven.pcf" ) 
PrecacheParticleSystem("ravencoreglow_2") 
PrecacheParticleSystem("ravencoreglow_4") 
PrecacheParticleSystem("ravencoreglow_8") 

--==============================================================================
-- HELPER: Quaternion to Angle Conversion
--==============================================================================
--[[
    Converts a quaternion from the JSON data into a Garry's Mod Angle.
    This function also handles the conversion from Unreal Engine's left-handed
    coordinate system to Source Engine's right-handed system. This is typically
    done by negating the Yaw and Roll.

    @param q A table representing the quaternion, e.g., {X=0, Y=0, Z=0, W=1}.
    @returns A GMod Angle object.
]]-- 

local function QuaternionToAngle(q)
    if not q then return Angle(0, 0, 0) end

    local w, x, y, z = q.W, q.X, q.Y, q.Z

    -- Roll (x-axis rotation)
    local t0 = 2.0 * (w * x + y * z)
    local t1 = 1.0 - 2.0 * (x * x + y * y)
    local roll = math.atan2(t0, t1)

    -- Pitch (y-axis rotation)
    local t2 = 2.0 * (w * y - z * x)
    -- Clamp the value to the valid range for asin [-1, 1]
    t2 = math.max(-1.0, math.min(1.0, t2))
    local pitch = math.asin(t2)

    -- Yaw (z-axis rotation)
    local t3 = 2.0 * (w * z + x * y)
    local t4 = 1.0 - 2.0 * (y * y + z * z)
    local yaw = math.atan2(t3, t4)

    -- Convert radians to degrees and create the angle.
    -- Negate Yaw and Roll for Left-Handed (UE) to Right-Handed (Source) conversion.
    return Angle(math.deg(pitch), -math.deg(yaw), -math.deg(roll))
end

--==============================================================================
-- HELPER: Quaternion SLERP
--==============================================================================
-- Performs spherical linear interpolation between two quaternions.
-- q1, q2 are tables {X, Y, Z, W}
-- t is interpolation factor [0,1]
local function QuaternionSlerp(q1, q2, t)
    -- Compute dot product
    local dot = q1.X*q2.X + q1.Y*q2.Y + q1.Z*q2.Z + q1.W*q2.W

    -- If dot < 0, negate one quaternion to take the shortest path
    if dot < 0 then
        q2 = {X=-q2.X, Y=-q2.Y, Z=-q2.Z, W=-q2.W}
        dot = -dot
    end

    local theta0 = math.acos(math.min(dot,1)) -- angle between
    local sinTheta0 = math.sin(theta0)

    -- If very close, fall back to linear interpolation
    if sinTheta0 < 1e-6 then
        return {
            X = (1-t)*q1.X + t*q2.X,
            Y = (1-t)*q1.Y + t*q2.Y,
            Z = (1-t)*q1.Z + t*q2.Z,
            W = (1-t)*q1.W + t*q2.W
        }
    end

    local s1 = math.sin((1-t)*theta0) / sinTheta0
    local s2 = math.sin(t*theta0) / sinTheta0

    return {
        X = s1*q1.X + s2*q2.X,
        Y = s1*q1.Y + s2*q2.Y,
        Z = s1*q1.Z + s2*q2.Z,
        W = s1*q1.W + s2*q2.W
    }
end 

-- Map of SB InterpTypes to GMod math.ease functions
local EasingFunctions = {
    ["InterpType_Step"] = function(f) return f >= 1 and 1 or 0 end,
    ["InterpType_Liner"] = function(f) return f end,
    ["InterpType_SinOut"] = math.ease.OutSine,
    ["InterpType_SinIn"] = math.ease.InSine,
    ["InterpType_ExpoIn"] = math.ease.InExpo,
    ["InterpType_SinInOut"] = math.ease.InOutSine,
    ["InterpType_ExpoInOut"] = math.ease.InOutExpo,
    ["InterpType_ExpoOut"] = math.ease.OutExpo,
    ["InterpType_CircularOut"] = math.ease.OutCirc,
    ["InterpType_CircularIn"] = math.ease.InCirc,
    ["InterpType_EaseIn"] = math.ease.InQuad, -- Using Quad as a generic EaseIn
    ["InterpType_CircularInOut"] = math.ease.InOutCirc,
    ["InterpType_EaseInOut"] = math.ease.InOutQuad, -- Using Quad as a generic EaseInOut
    ["InterpType_EaseOut"] = math.ease.OutQuad -- Using Quad as a generic EaseOut
}

StellarBlade = StellarBlade or {} 

-- Minimal parser: returns a plain array table 
-- Input is a string like "[{\"Alias\":\"HitStun\", \"Time\":1.5}, {\"Alias\":\"KnockDownForward_Eve\"}, {\"Alias\":\"KnockDownBackward_Eve\"}]" 
-- Output is: { 
-- [1] = { ["Alias"] = "HitStun", ["Time"] = 1.5 } 
-- [2] = { ["Alias"] = "KnockDownForward_Eve" } 
-- [3] = { ["Alias"] = "KnockDownBackward_Eve" } } 
StellarBlade.ParseTableStrings = function(input)
    if !input then error("no input to ParseTableStrings") end

    local t = input

    if type(input) == "string" then
        t = util.JSONToTable(input)
        if type(t) != "table" then return input end
    end

    -- If passed a single effect object (table with Alias) convert to array
    if type(t) == "table" and t.Alias != nil and t[1] == nil then
        t = { t }
    end

    local out = {}

    for i, entry in ipairs(t) do
        if type(entry) == "table" then
            local e = {}
            for k, v in pairs(entry) do
                if type(v) == "string" then
                    local n = tonumber(v)
                    if n ~= nil then
                        e[k] = n
                    else
                        e[k] = v
                    end
                else
                    e[k] = v
                end
            end
            out[#out + 1] = e
        else
            -- non-table entry: wrap as Alias string
            out[#out + 1] = { Alias = tostring(entry) }
        end
    end

    return out
end

StellarBlade.AddEffect = function(self, strEffect, ...)
    local EffectTable = scripted_ents.Get("npc_sb_raven").SBAI_GetEffectTable(self, strEffect)
    if !EffectTable then error("EffectTable not found for "..strEffect) end

    -- Ensure our container exists
    self.SB_EffectAlias = self.SB_EffectAlias or {}
    local curEffects = self.SB_EffectAlias

    -- Ensure per-effect list exists (always treat as array of instances)
    if !curEffects[strEffect] then
        curEffects[strEffect] = {}
    end

    -- Prepare a fresh instance from canonical table (copy)
    local template = SB_EffectTable and SB_EffectTable[1] and SB_EffectTable[1].Rows and SB_EffectTable[1].Rows[strEffect]
    local newInstance = template and table.Copy(template) or {}

    -- The effect definition (metadata) from npc table (may include Overlap too)
    local Overlap = EffectTable.Overlap

    local chosenIndex = nil

    if Overlap == "ESBEffectOverlap::EffectOverlap_Overlap" then
        -- If there is already an instance, merge into the first one (numeric fields are added, others overridden).
        if #curEffects[strEffect] >= 1 then
            chosenIndex = 1
            local exist = curEffects[strEffect][chosenIndex]
            -- Merge numeric values: add numbers; otherwise override/assign
            for k, v in pairs(newInstance) do
                if k == "Time" then continue end
                local ev = exist[k]
                if type(v) == "number" and type(ev) == "number" then
                    exist[k] = ev + v
                else
                    exist[k] = v
                end
            end
            -- preserve (or update) Overlap field if provided
            if EffectTable.Overlap then
                exist.Overlap = EffectTable.Overlap
            end
        else
            -- no existing instance: append new one
            table.insert(curEffects[strEffect], newInstance)
            chosenIndex = #curEffects[strEffect]
        end

    elseif Overlap == "ESBEffectOverlap::EffectOverlap_Change" then
        -- Insert new instance at index 1 (becomes the primary / changed effect)
		if curEffects[strEffect][1] then 
			curEffects[strEffect][1]:Remove() 
		end 
        curEffects[strEffect][1] = newInstance
        chosenIndex = 1

    elseif Overlap == "ESBEffectOverlap::EffectOverlap_Unique" then
        -- Always append a new instance (unique stacking)
        table.insert(curEffects[strEffect], newInstance)
        chosenIndex = #curEffects[strEffect]

    else
        -- Unknown/unspecified overlap: default to single-instance replace behaviour
        curEffects[strEffect][1] = newInstance
        chosenIndex = 1
    end

    -- The instance we're working with
    local curEffect = curEffects[strEffect][chosenIndex]

    -- ensure curEffect exists (defensive)
    if !curEffect then
        curEffect = newInstance
        curEffects[strEffect][chosenIndex or 1] = curEffect
    end

    -- timestamp / lifetime anchor
	curEffect.IsMarkedForDeletion = false 
	curEffect.Name = strEffect 
	curEffect.Outer = self 
	curEffect.chosenIndex = chosenIndex 
    curEffect.EndTime = CurTime() + curEffect.LifeTime 
    curEffect.Time = CurTime() 

    -- Process vararg key/value pairs and write into chosen instance
    local args = { ... }
    local n = #args
    for i = 1, n, 2 do
        local key = args[i]
        local val = args[i + 1]
        if key ~= nil then
            -- try to convert numeric-like strings to numbers
            if type(val) == "string" then
                local num = tonumber(val)
                if num ~= nil then
                    val = num
                end
            end
            curEffect[tostring(key)] = val
        end
    end

    -- Handle life type if you need to perform special registration/tracking
    local LifeType = curEffect.LifeType
    if LifeType == "ESBEffectLifeType::EffectLifeType_Infinite" then
        -- keep as-is (no time limit)
    elseif LifeType == "ESBEffectLifeType::EffectLifeType_SkillDependent" then
        -- curEffect.ActiveSkill = self.SBAI_SkillTable and self.SBAI_SkillTable.SkillName
    elseif LifeType == "ESBEffectLifeType::EffectLifeType_StepDependent" then
        -- handle step-dependent logic if needed
    elseif LifeType == "ESBEffectLifeType::EffectLifeType_IndependentTime" then
        -- curEffect.ExpireTime = CurTime() + (EffectTable.LifeTime or curEffect.LifeTime or 0)
    end
    -- (extend cases as you need)

    -- Process dispel flags: curEffect.DispelFlagsArray may be an array of strings/flags
    local DispelFlagsArray = curEffect.DispelFlagsArray
    if type(DispelFlagsArray) == "table" and next(DispelFlagsArray) then
        local toRemoveAliases = {}
        for _, dispFlag in ipairs(DispelFlagsArray) do
            if not dispFlag then continue end
            -- iterate over all effect aliases present on the entity
            for existName, existInstances in pairs(curEffects) do
                if existName != strEffect then -- don't remove the effect we just added
                    -- existInstances is an array of instance tables
                    for _, existInstance in ipairs(existInstances) do
                        local existFlag = existInstance and existInstance.Flag
                        if existFlag == dispFlag or existName == dispFlag then
                            toRemoveAliases[existName] = true
                            break
                        end
                    end
                end
            end
        end

        -- Remove matching aliases (call your RemoveEffect helper which likely removes whole alias)
        for EffectName, EffectAlias in pairs(toRemoveAliases) do
            -- StellarBlade.RemoveEffect(self, name)
            -- also clean local table in case RemoveEffect doesn't
            -- curEffects[name] = nil
        end
    end 
	
	curEffect.Remove = function() 
		-- if !curEffects[strEffect][chosenIndex] then return end 
		-- if curEffects[strEffect][chosenIndex] != curEffect then return end 
		local strEffect = curEffect.Name 
		local chosenIndex = curEffect.chosenIndex 
		if !curEffect.IsMarkedForDeletion then 
			curEffect.IsMarkedForDeletion = true 
			StellarBlade.OnRemoveEffect(curEffect.Outer,curEffect) 
			table.remove(curEffects[strEffect],chosenIndex) 
			print("removing effect:",strEffect,self) 
		end 
	end 
	
	function curEffect:CanActivate() -- passes activation conditions 
		return true 
	end 
	
	function curEffect:IsActive() 
		return true 
	end 
	
	function curEffect:IsLifeTypeValid() 
		-- fade according to life type 
		local LifeType = self.LifeType

		if LifeType == "ESBEffectLifeType::EffectLifeType_Infinite" then
			-- do nothing (infinite)
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_SkillDependent" then
			if !self.Outer.SBAI_SkillTable then 
				-- self:Remove() 
				return false 
				-- StellarBlade.RemoveEffect(self, Effect) 
			end
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_StepDependent" then
			if !self.Outer.SBAI_ActiveSkill then 
				-- self:Remove() 
				return false 
				-- StellarBlade.RemoveEffect(self, Effect) 
			end
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_IndependentTime" then
			if CurTime() > self.LifeTime + self.Time then 
				-- self:Remove() 
				return false 
				-- StellarBlade.RemoveEffect(self, Effect) 
			end
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_StanceDependent" then
			-- keep as-is for now
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_CharacterGetupTime" then
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_ProjectileDependent" then
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_BeforeNextSkill" then
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_CharacterGroggyEndTime" then
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_NextSkillDependent" then
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_LevelSequenceDependent" then
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_EquipmentDependent" then
		elseif LifeType == "ESBEffectLifeType::EffectLifeType_LevelSequenceDependentWithoutPlayable" then
		end 
		return true 
	end 
	
	function curEffect:IsValid() -- this is called by the engine every time any hook gets called 
	-- if IsValid returns false, the hooks referenced as this table will be destructed 
		if !IsValid(curEffect.Outer) then return false end 
		if !self:IsLifeTypeValid() then 
			self:Remove() 
			return false 
		end 
		return IsValid(curEffect.Outer) or !self.IsMarkedForDeletion 
	end 
	
	function curEffect:Think() 
		-- print(self.Outer,strEffect) -- all of these are valid 
	end 
	
	function curEffect:EntityTakeDamage(target,dmginfo)	
		if target != self.Outer then return end 
		local Damage = dmginfo:GetDamage()
		local CalculationValue = self.CalculationValue 
		for i = 1,10 do 
			local ActorStat 
		end 

		if self.StatType == "ESBActorStatType::ActorStatType_MinimumHP" and CalculationValue then
			local Health = target:Health()
			local MaxHealth = target:GetMaxHealth()
			local MinHealth = MaxHealth * (CalculationValue * 0.01)

			-- predicted health after taking damage
			local NewHealth = Health - Damage

			-- if new health would go below minimum threshold
			if NewHealth < MinHealth then
				-- clamp the damage so HP stops at minimum
				local AllowedDamage = math.max(0, Health - MinHealth)

				if AllowedDamage <= 0 then
					-- completely negate the damage
					dmginfo:SetDamage(0)
					return true
				else
					dmginfo:SetDamage(AllowedDamage)
				end
			end
		elseif self.StatType == "ESBActorStatType::ActorStatType_HitDefenseLevel" then 
			local level = self.CalculationValue
			if level == 0 then return end -- nothing to do

			local old = dmginfo:GetDamage() 
			-- if old <= 0 then return end
			-- level >= 0: factor = 1 / (1 + level)
			-- level  < 0: factor = 1 - level    (so -1 -> 2x, -2 -> 3x, etc)
			local factor = level >= 0 and 1 / (1 + level) or 1 - level
			local newDamage = old * factor

			-- safety clamp (optional): do not allow negative damage
			-- if newDamage < 0 then newDamage = 0 end

			dmginfo:SetDamage(newDamage)
		end 
		print("dmginfo:",dmginfo) 
		
	end 
	
	function curEffect:PostEntityTakeDamage(target,dmginfo) 
		-- print("PostEntityTakeDamage:",target,dmginfo) 
		local attacker = dmginfo:GetAttacker() 
		if IsValid(attacker) and attacker.SB_EffectAlias then 
			for EffectName, EffectInstances in pairs(attacker.SB_EffectAlias) do 
				for EffectInstance, EffectTable in pairs(EffectInstances) do 
					local ConditionChainType = EffectTable.ConditionChainType 
					local ConditionChainSelfEffectAliasArray, ConditionChainTargetEffectAliasArray = EffectTable.ConditionChainSelfEffectAliasArray, EffectTable.ConditionChainTargetEffectAliasArray 
					if ConditionChainType == "ESBEffectConditionChainType::EffectConditionChainType_HitTarget" then 
						for k,v in ipairs(ConditionChainSelfEffectAliasArray) do 
							StellarBlade.AddEffect(attacker,v) 
						end 
						
						for k,v in ipairs(ConditionChainTargetEffectAliasArray) do 
							StellarBlade.AddEffect(target,v) 
						end 
					end 
					
					if ConditionChainType == "ESBEffectConditionChainType::EffectConditionChainType_DeadTarget" and !target:Alive() then 
						for k,v in ipairs(ConditionChainSelfEffectAliasArray) do 
							StellarBlade.AddEffect(attacker,v) 
						end 
						
						for k,v in ipairs(ConditionChainTargetEffectAliasArray) do 
							StellarBlade.AddEffect(target,v) 
						end 
					end 
				end 
			end 
		end 
	end 
	
	hook.Add("Think",curEffect,curEffect.Think) 
	hook.Add("EntityTakeDamage",curEffect,curEffect.EntityTakeDamage) 
	hook.Add("PostEntityTakeDamage",curEffect,curEffect.PostEntityTakeDamage) 
	print("added effect:",strEffect,self) 
	
	-- fully initialized 
	StellarBlade.OnAddEffect(self,curEffect) 
	
    -- Optionally return chosenIndex and curEffect for caller convenience
    return chosenIndex, curEffect
end


StellarBlade.ApplyEffectAction = function(self,EffectTable,Action,ActionValue) 
	ParsedActionValue = StellarBlade.ParseTableStrings(ActionValue) 
	if Action == "ESBEffectAction::EffectAction_None" then 
	
	elseif Action == "ESBEffectAction::EffectAction_SkillCancel" then 
		-- print("calling EffectAction_SkillCancel") 
		self.SBAI_ActiveSkill = nil 
		self.SBAI_SkillTable = nil 
	elseif Action == "ESBEffectAction::EffectAction_TimeScale" then -- simple 
	-- "{\"TotalTime\":0.5, \"FadeInTime\":0.05, \"FadeOutTime\":0.1, \"TimeScale\":0.1}" 
		game.SetTimeScale(ParsedActionValue[1].TimeScale) 
		timer.Simple(ParsedActionValue[1].TotalTime, function() 
			game.SetTimeScale(1) 
		end) 
	elseif Action == "ESBEffectAction::EffectAction_SkillCancelUnImmune" then -- unused 
	elseif Action == "ESBEffectAction::EffectAction_ResetSkillCommandCoolTime" then 
		if self.SBAI_SkillTimers then 
			self.SBAI_SkillTimers[ActionValue] = nil 
		end 
	elseif Action == "ESBEffectAction::EffectAction_ResetSkillCommandUsableCount" then 
	elseif Action == "ESBEffectAction::EffectAction_ResetSkillUsableGroup" then 
	elseif Action == "ESBEffectAction::EffectAction_ActiveSkillCombinationCrossKey" then 
	elseif Action == "ESBEffectAction::EffectAction_SummonActor" then 
	elseif Action == "ESBEffectAction::EffectAction_ActiveInteraction" then 
	elseif Action == "ESBEffectAction::EffectAction_RecoveryItems" then 
	elseif Action == "ESBEffectAction::EffectAction_AreaTimeScale" then 
	elseif Action == "ESBEffectAction::EffectAction_TargetEncroachment" then 
	elseif Action == "ESBEffectAction::EffectAction_AdditiveSkillCommandCoolTime" then 
	elseif Action == "ESBEffectAction::EffectAction_AdditiveSkillCoolTime" then 
	elseif Action == "ESBEffectAction::EffectAction_ShowUI" then 
	elseif Action == "ESBEffectAction::EffectAction_PlayTheater" then 
	elseif Action == "ESBEffectAction::EffectAction_PlayTheaterParam" then 
	elseif Action == "ESBEffectAction::EffectAction_StopTheater" then 
	elseif Action == "ESBEffectAction::EffectAction_AdditiveSkillEnergyAmount" then 
	elseif Action == "ESBEffectAction::EffectAction_LockOnConstructorActor" then 
	elseif Action == "ESBEffectAction::EffectAction_LockOnMainActor" then 
	elseif Action == "ESBEffectAction::EffectAction_ItemRefill" then 
	elseif Action == "ESBEffectAction::EffectAction_WarpToSafeLocation" then 
	elseif Action == "ESBEffectAction::EffectAction_MountingEquipment" then 
	elseif Action == "ESBEffectAction::EffectAction_UnmountingEquipment" then 
	elseif Action == "ESBEffectAction::EffectAction_WarpCamp" then 
	elseif Action == "ESBEffectAction::EffectAction_TryLinkBreak" then 
	elseif Action == "ESBEffectAction::EffectAction_ConstructorActorSkillCancelWhenDispel" then 
	elseif Action == "ESBEffectAction::EffectAction_CancelEventMove" then 
	elseif Action == "ESBEffectAction::EffectAction_Revival" then 
	elseif Action == "ESBEffectAction::EffectAction_TransformCharacter" then -- unused 
	elseif Action == "ESBEffectAction::EffectAction_Possess" then -- unused 
	elseif Action == "ESBEffectAction::EffectAction_ChangeTribe" then 
	elseif Action == "ESBEffectAction::EffectAction_TPSMiniGame" then 
	elseif Action == "ESBEffectAction::EffectAction_TPSNikke" then 
	elseif Action == "ESBEffectAction::EffectAction_TPSNikkeAimTriggerEffect" then 
	elseif Action == "ESBEffectAction::EffectAction_TPSNikkeBulletTriggerEffect" then 
	elseif Action == "ESBEffectAction::EffectAction_RecoveryCollisionGroup" then 
	elseif Action == "ESBEffectAction::EffectAction_Scan" then 
	elseif Action == "ESBEffectAction::EffectAction_NotifyTagEvent" then 
	elseif Action == "ESBEffectAction::EffectAction_FishingMode" then 
	elseif Action == "ESBEffectAction::EffectAction_TPS_ZoomIn" then 
	elseif Action == "ESBEffectAction::EffectAction_DroneFixedPosition" then 
	elseif Action == "ESBEffectAction::EffectAction_CancelAllAttacks" then 
	elseif Action == "ESBEffectAction::EffectAction_ClearAllProjectile" then 
	elseif Action == "ESBEffectAction::EffectAction_FishingCasting" then 
	elseif Action == "ESBEffectAction::EffectAction_FishingSuccess" then 
	elseif Action == "ESBEffectAction::EffectAction_AttachEquipment" then 
	elseif Action == "ESBEffectAction::EffectAction_ImmediateDeath" then 
	elseif Action == "ESBEffectAction::EffectAction_ImmediateDeathPossibleRevival" then 
	elseif Action == "ESBEffectAction::EffectAction_ScreenEffect" then 
	elseif Action == "ESBEffectAction::EffectAction_TPSTutorial" then 
	elseif Action == "ESBEffectAction::EffectAction_UIClientEvent" then 
	elseif Action == "ESBEffectAction::EffectAction_RetryPlayGame" then 
	elseif Action == "ESBEffectAction::EffectAction_FixedLocation" then 
	elseif Action == "ESBEffectAction::EffectAction_CancelInteraction" then 
	elseif Action == "ESBEffectAction::EffectAction_DisableSliceMesh" then 
	elseif Action == "ESBEffectAction::EffectAction_ClearAllTargetingMe" then 
	elseif Action == "ESBEffectAction::EffectAction_ZoneEventActorDestruction" then 
	elseif Action == "ESBEffectAction::EffectAction_ArcEventSpawn" then 
	elseif Action == "ESBEffectAction::EffectAction_Countdown" then 
	elseif Action == "ESBEffectAction::EffectAction_ActionAssist_Repulse" then 
	elseif Action == "ESBEffectAction::EffectAction_ActionAssist_Blink" then 
	elseif Action == "ESBEffectAction::EffectAction_MonsterWarp" then 
	elseif Action == "ESBEffectAction::EffectAction_AttachOverrideStencil" then 
	elseif Action == "ESBEffectAction::EffectAction_ForceLOD0" then 
	elseif Action == "ESBEffectAction::EffectAction_BlockCamera" then 
	elseif Action == "ESBEffectAction::EffectAction_SelfiePhotoMode" then 
	elseif Action == "ESBEffectAction::EffectAction_UseSkill" then 
	elseif Action == "ESBEffectAction::EffectAction_SkillCoolTimeScale" then 
	elseif Action == "ESBEffectAction::EffectAction_ResetTPSAimPosition" then 
	elseif Action == "ESBEffectAction::EffectAction_HideAllProjectile" then 
	elseif Action == "ESBEffectAction::EffectAction_ClearAllProjectileMadeBy" then 
		for k,v in ents.Iterator() do 
			if IsValid(v:GetOwner()) and v:GetOwner() == self then 
				SafeRemoveEntity(v) 
			end 
		end 
	elseif Action == "ESBEffectAction::EffectAction_MAX" then 

	else -- unlikely 
	
	end 
end 

local ESBEffectCalculationType = { } 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_Static"] = function(ent,CalculationValue,StatValue) return CalculationValue+StatValue end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_PhysicDamage"] = function(ent,CalculationValue,StatValue) 
	local AttackPower = ent.PhysicAttackPower 
	if !AttackPower then AttackPower = 100 end 
	return StatValue + (CalculationValue * AttackPower) 
end 

ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_ShieldDamage"] = function(ent,CalculationValue,StatValue) 
	local AttackPower = ent.PhysicAttackPower 
	if !AttackPower then AttackPower = 100 end 
	return StatValue + (CalculationValue * AttackPower) 
end 

ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_StaminaDamage"] = function(ent,CalculationValue,StatValue) 
	local AttackPower = ent.PhysicAttackPower 
	if !AttackPower then AttackPower = 100 end 
	return StatValue + (CalculationValue * AttackPower) 
end 

ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_MaxHPRate"] = function(ent,CalculationValue,StatValue) -- set health to given hp percentage 
	-- return math.Remap(input,0,100,0,ent:GetMaxHealth())  
	return StatValue + (ent:GetMaxHealth() * (CalculationValue / 100)) 
end 

ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_MaxHPValue"] = function(ent,CalculationValue,StatValue) return CalculationValue end -- unused 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_FallingDamage"] = function(ent,CalculationValue,StatValue) 
	return hook.Run("GetFallDamage",ent,ent:GetVelocity():Length()*CalculationValue) + StatValue 
end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_StaticPercent"] = function(ent,CalculationValue,StatValue) return CalculationValue end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_StaticPercentRate"] = function(ent,CalculationValue,StatValue) 
	print("CalculationValue:",CalculationValue,"StatValue:",StatValue) 
	return StatValue + (StatValue * (CalculationValue / 100)) 
end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_EffectAttackPower"] = function(ent,CalculationValue,StatValue) 
	local AttackPower = ent.PhysicAttackPower 
	if !AttackPower then AttackPower = 100 end 
	return StatValue + (CalculationValue * AttackPower) 
end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_MaxShieldRate"] = function(ent,CalculationValue,StatValue) return 0 end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_HealStatic"] = function(ent,CalculationValue,StatValue) return CalculationValue+StatValue end -- clamp this 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_HealMaxHPRate"] = function(ent,CalculationValue,StatValue) return 0 end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_CurrentTachyGaugeRate"] = function(ent,CalculationValue,StatValue) return 0 end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_SetStatValue"] = function(ent,CalculationValue,StatValue) return CalculationValue end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_MaxStaminaRate"] = function(ent,CalculationValue,StatValue) return 0 end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_HealMaxHPRateByTumbler"] = function(ent,CalculationValue,StatValue) return 0 end 

local test1 = false 
if test1 then 
local ent = Entity(1) 
	-- get stat value first 
	local attribute = StellarBlade.ActorStats(ent)["ESBActorStatType::ActorStatType_HP"] 
	-- calculate using ESBEffectCalculationType 
	local calculatedattribute = ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_SetStatValue"](ent,200,ent:Health()) 
	-- now apply calculated property 
	StellarBlade.ActorStats(ent)["ESBActorStatType::ActorStatType_HP"] = calculatedattribute 
end 

local test2 = false 
if test2 then 
	local effecttoassign = "P_Eve_Buff_HPRecoverWhenAttack" 
	if Entity(1).SB_EffectAlias then 
		if Entity(1).SB_EffectAlias and Entity(1).SB_EffectAlias[effecttoassign] and Entity(1).SB_EffectAlias[effecttoassign][1] then 
			Entity(1).SB_EffectAlias[effecttoassign][1]:Remove() 
		end 
	end 
	StellarBlade.AddEffect(Entity(1),effecttoassign) 
end 


local statProxyMT = {}

-- getters: if stat not stored on proxy table, these functions are used
local statGetters = {
	["ESBActorStatType::ActorStatType_None"] = function(proxy)
        -- prefer actual engine health for truth (fallback to stored)
        return 0 -- or nil 
    end,
	
    ["ESBActorStatType::ActorStatType_HP"] = function(proxy)
        -- prefer actual engine health for truth (fallback to stored)
        if IsValid(proxy.Outer) then
            return proxy.Outer:Health()
        end
        return rawget(proxy, "ESBActorStatType::ActorStatType_HP")
    end,

    ["ESBActorStatType::ActorStatType_MaxHP"] = function(proxy)
        local ent = proxy.Outer
        if IsValid(ent) then
            return ent:GetMaxHealth() or rawget(proxy, "ESBActorStatType::ActorStatType_MaxHP") or 100
        end
        return rawget(proxy, "ESBActorStatType::ActorStatType_MaxHP") or 100
    end,
	
	["ESBActorStatType::ActorStatType_MaxHPValue"] = function(proxy)
        local ent = proxy.Outer
        if IsValid(ent) then
            return ent:GetMaxHealth() or rawget(proxy, "ESBActorStatType::ActorStatType_MaxHP") or 100
        end
        return rawget(proxy, "ESBActorStatType::ActorStatType_MaxHP") or 100
    end,
	
	["ESBActorStatType::ActorStatType_MaxHPRate"] = function(proxy)
        local ent = proxy.Outer
        if IsValid(ent) then
            return ent:GetMaxHealth() or rawget(proxy, "ESBActorStatType::ActorStatType_MaxHP") or 100
        end
        return rawget(proxy, "ESBActorStatType::ActorStatType_MaxHP") or 100
    end,

    ["ESBActorStatType::ActorStatType_Shield"] = function(proxy)
        local ent = proxy.Outer
        if IsValid(ent) then
            return ent:Armor()
        end
        return rawget(proxy, "ESBActorStatType::ActorStatType_Shield") or 0
    end,

    ["ESBActorStatType::ActorStatType_MinimumHP"] = function(proxy)
        -- store as percent (e.g. 75 means 75%)
        return rawget(proxy, "ESBActorStatType::ActorStatType_MinimumHP") or 0
    end,
	
	["ESBActorStatType::ActorStatType_HitDefenseLevel"] = function(proxy)
        -- store as percent (e.g. 75 means 75%)
        return rawget(proxy, "ESBActorStatType::ActorStatType_HitDefenseLevel") or 0
    end,
    -- add other getters as needed
}

-- setters: called whenever someone writes proxy["key"] = value (or via __call)
local statSetters = {
	["ESBActorStatType::ActorStatType_None"] = function(proxy, value)
        return 0 
    end,
	
    ["ESBActorStatType::ActorStatType_HP"] = function(proxy, value)
        local ent = proxy.Outer
        if IsValid(ent) then
            ent:SetHealth(math.floor(value))
        end
        -- rawset(proxy, "ESBActorStatType::ActorStatType_HP", value) 
        hook.Run("SB_StatChanged", ent, "HP", value)
    end,

    ["ESBActorStatType::ActorStatType_MaxHP"] = function(proxy, value)
        local ent = proxy.Outer
        -- try to use engine setter if present, otherwise store it
        if IsValid(ent) then
            ent:SetMaxHealth(value)
        end
        -- rawset(proxy, "ESBActorStatType::ActorStatType_MaxHP", value)
        hook.Run("SB_StatChanged", ent, "MaxHP", value)
    end,

	["ESBActorStatType::ActorStatType_MaxHPValue"] = function(proxy, value)
        local ent = proxy.Outer
        -- try to use engine setter if present, otherwise store it
        if IsValid(ent) then
            ent:SetMaxHealth(value)
        end
        -- rawset(proxy, "ESBActorStatType::ActorStatType_MaxHP", value)
        hook.Run("SB_StatChanged", ent, "MaxHP", value)
    end,
	
	["ESBActorStatType::ActorStatType_MaxHPRate"] = function(proxy, value)
        local ent = proxy.Outer
        -- try to use engine setter if present, otherwise store it
        if IsValid(ent) then
			local curMaxHp = ent:GetMaxHealth() 
			curMaxHp = curMaxHp + (curMaxHp * (value / 100)) 
            ent:SetMaxHealth(curMaxHp)
        end
        -- rawset(proxy, "ESBActorStatType::ActorStatType_MaxHP", value)
        hook.Run("SB_StatChanged", ent, "MaxHP", value)
    end,

    ["ESBActorStatType::ActorStatType_Shield"] = function(proxy, value)
        local ent = proxy.Outer
        if IsValid(ent) then
            ent:SetArmor(math.floor(value))
        end
        -- rawset(proxy, "ESBActorStatType::ActorStatType_Shield", value)
        hook.Run("SB_StatChanged", ent, "Shield", value)
    end,

    ["ESBActorStatType::ActorStatType_MinimumHP"] = function(proxy, value)
        -- store percent floor
        -- rawset(proxy, "ESBActorStatType::ActorStatType_MinimumHP", value)
        hook.Run("SB_StatChanged", proxy.Outer, "MinimumHP", value)
    end,
	
	["ESBActorStatType::ActorStatType_HitDefenseLevel"] = function(proxy, value)
        -- store percent floor
        rawset(proxy, "ESBActorStatType::ActorStatType_HitDefenseLevel", value)
        hook.Run("SB_StatChanged", proxy.Outer, "MinimumHP", value)
    end,
    -- add other setters as needed
}

-- __index: return stored value if present, otherwise use statGetters mapping
statProxyMT.__index = function(self, key)
    -- if direct stored value exists, Lua won't call __index; but check anyway
    local stored = rawget(self, key)
    if stored != nil then return stored end

    local g = statGetters[key]
    if g then
        return g(self)
    end

    return nil
end

-- __newindex: when someone does proxy[key] = value
statProxyMT.__newindex = function(self, key, value)
    local s = statSetters[key]
    if s then
        s(self, value)
    else
        -- default: just store on proxy
        rawset(self, key, value)
        hook.Run("SB_StatChanged", self.Outer, key, value)
    end
	return nil 
end

-- __call: set key/value pair via proxy("key", value)
-- This writes into the proxy itself (using existing setter logic).
statProxyMT.__call = function(self, key, value)
    if key == nil then
        return nil
    end

    -- use metamethod assignment to trigger setter logic
	rawset(self,key,value) 
    -- self[key] = value

    -- return stored value for convenience
    return rawget(self, key)
end

-- statProxyMT.__gc = function(self, key, value)
	-- print("garbage collector",self,key,value)
-- end

-- Utility: create/ensure proxy for an entity
function StellarBlade.ActorStats(ent,forceReset) 
    if !IsValid(ent) then return nil end
    if ent.ESBActorStatType and getmetatable(ent.ESBActorStatType) == statProxyMT and !forceReset then
        return ent.ESBActorStatType
    end

    local proxy = {}
    proxy.Outer = ent
    setmetatable(proxy, statProxyMT)
    ent.ESBActorStatType = proxy 
    return proxy
end 

StellarBlade.OnAddEffect = function(self,EffectTable) 
	local StatType = EffectTable.StatType 
	local StatCalculationType = EffectTable.StatCalculationType 
	local CalculationValue = EffectTable.CalculationValue 
	
	local attribute = StellarBlade.ActorStats(self)[StatType] 
	print("attribute is:",attribute) 
	if attribute then 
		-- calculate using ESBEffectCalculationType 
		local calculatedattribute = ESBEffectCalculationType[StatCalculationType](self,CalculationValue,attribute) 
		print("calculatedattribute is:",calculatedattribute) 
		
		-- calculate previous 
		EffectTable.previousactorstat = calculatedattribute - attribute 
		print(EffectTable.previousactorstat) 
		-- now apply calculated property 
		StellarBlade.ActorStats(self)[StatType] = calculatedattribute 
	end 

    StellarBlade.SetMoveTable(self, EffectTable.MoveAlias) 

    for idx = 1, 5 do 
        local actKey = "Action" .. idx 
        local valKey = "ActionValue" .. idx 
        local Action, ActionValue = EffectTable[actKey], EffectTable[valKey] 
        if Action then 
            StellarBlade.ApplyEffectAction(self, EffectTable, Action, ActionValue) 
        end 
    end 
	
	for idx = 1, 10 do 
		local ActorState = "ActorState"..idx 
		local DelayActorState = "DelayActorState"..idx 
		ActorState = EffectTable[ActorState] 
		DelayActorState = EffectTable[DelayActorState] 
		StellarBlade.ActorApplyState(self,ActorState,DelayActorState) 
	end 
end 

StellarBlade.OnRemoveEffect = function(self,EffectTable) 
	local StatType = EffectTable.StatType 
	local StatCalculationType = EffectTable.StatCalculationType 
	local CalculationValue = EffectTable.CalculationValue 
	
	local attribute = StellarBlade.ActorStats(self)[StatType] 
	if EffectTable.bStatRestore and EffectTable.previousactorstat then 
		print(EffectTable.previousactorstat) 
		StellarBlade.ActorStats(self)[StatType] = StellarBlade.ActorStats(self)[StatType] - EffectTable.previousactorstat 
	end 
	
	-- cleanup ActorState (1-5) 
	for idx = 1, 10 do 
		local ActorState = "ActorState"..idx 
		local DelayActorState = "DelayActorState"..idx 
		ActorState = EffectTable[ActorState] 
		DelayActorState = EffectTable[DelayActorState] 
		if self[ActorState] then 
			self[ActorState]:Remove() 
		end 
		-- StellarBlade.ActorApplyState(self,ActorState,DelayActorState) 
	end 
	hook.Remove("Think",EffectTable) 
	hook.Remove("EntityTakeDamage",EffectTable) 
	hook.Remove("PostEntityTakeDamage",EffectTable) 
end 

-- Updated AddEffectFromTable to accept the plain array table produced by ParseTableStrings
StellarBlade.AddEffectFromTable = function(self, tblEffect) 
	-- print("called AddEffectFromTable") 
    if type(tblEffect) != "table" then error("table expected, got",type(tblEffect))  end

    for _, v in ipairs(tblEffect) do
        if type(v) == "table" and v.Alias then
            -- build vararg list from all keys except Alias
            local args = {}
            for k, val in pairs(v) do
                if k ~= "Alias" then
                    table.insert(args, k)
                    -- convert numeric-like strings to numbers (to match ParseTableStrings behavior)
                    if type(val) == "string" then
                        local num = tonumber(val)
                        if num ~= nil then
                            val = num
                        end
                    end
                    table.insert(args, val)
                end
            end

            -- call AddEffect passing unpacked args
            StellarBlade.AddEffect(self, v.Alias, unpack(args))
        end
    end
end 

StellarBlade.RemoveEffectLifeTypes = function(self, strLifeType)
    if !self.SB_EffectAlias then return end

    for EffectName, EffectInstances in pairs(self.SB_EffectAlias) do
        -- If the stored value isn't an array (defensive), fall back to checking the effect table metadata
        if type(EffectInstances) != "table" then
            local EffectTable = scripted_ents.Get("npc_sb_raven").SBAI_GetEffectTable(self, EffectName)
            if EffectTable and strLifeType == EffectTable.LifeType then
                self.SB_EffectAlias[EffectName] = nil
            end
        else
            -- iterate backwards to safely remove array entries
            for i = #EffectInstances, 1, -1 do
                local inst = EffectInstances[i]
                local life = inst and inst.LifeType
                if !inst or life == strLifeType then
					inst:Remove() 
                    -- table.remove(EffectInstances, i)
                end
            end

            -- if no instances left, remove the alias entirely
            if #EffectInstances == 0 then
                self.SB_EffectAlias[EffectName] = nil
            end
        end
    end
end 

StellarBlade.CanActorApplyState = function(self,ActorState) 
	-- reject ActorState if we have their immune states already set 
	local anti = { } 
	anti["ESBActorState::ActorState_BlockMove"] = "ESBActorState::ActorState_ImmuneBlockMove"
	anti["ESBActorState::ActorState_BlockSkill"] = "ESBActorState::ActorState_ImmuneBlockSkill"
	anti["ESBActorState::ActorState_Down"] = "ESBActorState::ActorState_ImmuneDown"
	anti["ESBActorState::ActorState_Groggy"] = "ESBActorState::ActorState_ImmuneGroggy"
	-- anti["ESBActorState::ActorState_ImmuneSkillCancel"] = "" 
	anti["ESBActorState::ActorState_Airborne"] = "ESBActorState::ActorState_ImmuneAirborne"
	anti["ESBActorState::ActorState_KnockBack"] = "ESBActorState::ActorState_ImmuneKnockBack"
	if anti[ActorState] then 
		if self[anti[ActorState]] then 
			return false 
		end 
	end 
	return true 
end 

StellarBlade.ActorApplyState = function(self,ActorState) 
	-- lookup whether the state is set in character's table 
	if !StellarBlade.CanActorApplyState(self,ActorState) then return false end 
	if !self[ActorState] then 
		self[ActorState] = {["Name"] = ActorState} 
		local ActorState = self[ActorState] 
		ActorState.Time = CurTime() 
		ActorState.Outer = self 
		ActorState.IsMarkedForDeletion = false 
		
		function ActorState:Remove() 
			if !self.IsMarkedForDeletion then 
				self.IsMarkedForDeletion = true 
				-- Entity(1):ChatPrint("removing: "..self.Name) 
				ProtectedCall(function() 
				
				hook.Remove("Think",ActorState) 
				hook.Remove("EntityTakeDamage",ActorState) 
				hook.Remove("PostEntityTakeDamage",ActorState) 
				hook.Remove("SetupMove",ActorState) -- player only 
				hook.Remove("Move",ActorState) -- player only 
				hook.Remove("FinishMove",ActorState) -- player only 
				
				if self.Name == "ESBActorState::ActorState_BlockMove" then 
					
				elseif self.Name == "ESBActorState::ActorState_BlockingBehavior" then 
					if self.Outer:IsPlayer() then 
						self.Outer:Freeze(false) 
					else 
						-- self.Outer:SetMoveType(MOVETYPE_STEP) 
					end 
				elseif self.Name == "ESBActorState::ActorState_BlockSprint" then 
					if self.Outer:IsPlayer() then 
						self.Outer:SprintEnable() 
					end 
				elseif self.Name == "ESBActorState::ActorState_Cloaking" then 
					self.Outer:RemoveFlags(FL_NOTARGET) 
				elseif self.Name == "ESBActorState::ActorState_NoDamageNoHit" then 
					self.Outer:SetSaveValue("m_takedamage",2) 
				elseif self.Name == "ESBActorState::ActorState_NoDamage" then 
					self.Outer:SetSaveValue("m_takedamage",2) 
				end 
				
				end) 
				
				if self.Outer[ActorState.Name] then 
					self.Outer[ActorState.Name] = nil 
				end 
			end 
		end 
		
		function ActorState:IsValid() 
			if self.IsMarkedForDeletion then return false end 
			return IsValid(ActorState.Outer) 
		end 
		
		function ActorState:Think() 
			if self.Name == "ESBActorState::ActorState_BlockRevival" then 
				if self.Outer.NextSpawnTime then 
					self.Outer.NextSpawnTime = CurTime() + 1 
				end 
			end 
		end 
		
		function ActorState:EntityTakeDamage(target,dmginfo) 
			if target == self.Outer then 
				
			end 
		end 
		
		function ActorState:PostEntityTakeDamage(target,dmginfo) 
		
		end 
		
		function ActorState:SetupMove(target,mv,cmd) 
			if self.Name == "ESBActorState::ActorState_BlockMove" then 
				mv:SetVelocity( vector_origin ) 
			end 
		end 
		
		function ActorState:Move(target,mv) 
			if self.Name == "ESBActorState::ActorState_BlockMove" then 
				mv:SetVelocity( vector_origin ) 
			end 
		end 
		
		function ActorState:FinishMove(target,mv) 
			if self.Name == "ESBActorState::ActorState_BlockMove" then 
				-- print("in FinishMove",self.Name,target,mv) 
				mv:SetVelocity( vector_origin ) 
			end 
		end 
		
		hook.Add("Think",ActorState,ActorState.Think) 
		hook.Add("EntityTakeDamage",ActorState,ActorState.EntityTakeDamage) 
		hook.Add("PostEntityTakeDamage",ActorState,ActorState.PostEntityTakeDamage) 
		hook.Add("SetupMove",ActorState,ActorState.SetupMove) -- player only 
		hook.Add("Move",ActorState,ActorState.Move) -- player only 
		hook.Add("FinishMove",ActorState,ActorState.FinishMove) -- player only 
		-- initialize state beneath 
		-- ActorState_None                          = 0,
		-- ActorState_BlockMove                     = 1,
		if ActorState.Name == "ESBActorState::ActorState_BlockMove" then 
			if self.SetMoveDelay then 
				self:SetMoveDelay(1) 
			end 
		-- ActorState_BlockSkill                    = 2,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockSkill" then 
			-- StartSkill will return false if character has this state 
			-- also prevent engine NPCs from deciding 
		-- ActorState_NoDamageNoHit                 = 3,
		elseif ActorState.Name == "ESBActorState::ActorState_NoDamageNoHit" then 
			self:SetSaveValue("m_takedamage",0) 
		-- ActorState_NoDamage                      = 4,
		elseif ActorState.Name == "ESBActorState::ActorState_NoDamage" then 
			self:SetSaveValue("m_takedamage",1) 
		-- ActorState_Cloaking                      = 5,
		elseif ActorState.Name == "ESBActorState::ActorState_Cloaking" then 
			self:AddFlags(FL_NOTARGET) 
		-- ActorState_Down                          = 6,
		elseif ActorState.Name == "ESBActorState::ActorState_Down" then 
		-- ActorState_Groggy                        = 7,
		elseif ActorState.Name == "ESBActorState::ActorState_Groggy" then 
		-- ActorState_Airborne                      = 8,
		elseif ActorState.Name == "ESBActorState::ActorState_Airborne" then 
			self:RemoveFlags(FL_ONGROUND) 
		-- ActorState_KnockBack                     = 9,
		elseif ActorState.Name == "ESBActorState::ActorState_KnockBack" then -- play ACT_BIG_FLINCH 
		-- ActorState_BlockFalling                  = 10,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockFalling" then 
		-- ActorState_BlockShieldRegen              = 11,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockShieldRegen" then 
		-- ActorState_BlockRotation                 = 12,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockRotation" then 
		-- ActorState_ImmuneBlockMove               = 13,
		elseif ActorState.Name == "ESBActorState::ActorState_ImmuneBlockMove" then 
		-- ActorState_ImmuneBlockSkill              = 14,
		elseif ActorState.Name == "ESBActorState::ActorState_ImmuneBlockSkill" then 
		-- ActorState_ImmuneDown                    = 15,
		elseif ActorState.Name == "ESBActorState::ActorState_ImmuneDown" then 
		-- ActorState_ImmuneGroggy                  = 16,
		elseif ActorState.Name == "ESBActorState::ActorState_ImmuneGroggy" then 
		-- ActorState_ImmuneSkillCancel             = 17,
		elseif ActorState.Name == "ESBActorState::ActorState_ImmuneSkillCancel" then 
		-- ActorState_ImmuneAirborne                = 18,
		elseif ActorState.Name == "ESBActorState::ActorState_ImmuneAirborne" then 
		-- ActorState_ImmuneKnockBack               = 19,
		elseif ActorState.Name == "ESBActorState::ActorState_ImmuneKnockBack" then 
		-- ActorState_BlockingBehavior              = 20,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockingBehavior" then 
			if self:IsPlayer() then 
				self:Freeze(true) 
			else 
				
			end 
		-- ActorState_BlockSkillUnImmune            = 21,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockSkillUnImmune" then 
		-- ActorState_Tumble                        = 22,
		elseif ActorState.Name == "ESBActorState::ActorState_Tumble" then 
		-- ActorState_Stealth                       = 23,
		elseif ActorState.Name == "ESBActorState::ActorState_Stealth" then 
		-- ActorState_BlockStaminaRegen             = 24,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockStaminaRegen" then 
		-- ActorState_BlockSprint                   = 25,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockSprint" then 
			if self:IsPlayer() then 
				self:SprintDisable() 
			end 
		-- ActorState_Breakfall                     = 26,
		elseif ActorState.Name == "ESBActorState::ActorState_Breakfall" then 
		-- ActorState_Immortal                      = 27,
		elseif ActorState.Name == "ESBActorState::ActorState_Immortal" then 
		-- ActorState_BlockJump                     = 28,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockJump" then 
		-- ActorState_BlockHPRegen                  = 29,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockHPRegen" then 
		-- ActorState_BattleMode                    = 30,
		elseif ActorState.Name == "ESBActorState::ActorState_BattleMode" then 
			if self:IsNPC() then 
				self:SetNPCState(NPC_STATE_ALERT) 
			end 
		-- ActorState_BlockParry                    = 31,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockParry" then 
		-- ActorState_DelayDeath                    = 32,
		elseif ActorState.Name == "ESBActorState::ActorState_DelayDeath" then 
		-- ActorState_BlockRuleMove                 = 33,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockRuleMove" then 
		-- ActorState_BlockRuleMoveRotation         = 34,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockRuleMoveRotation" then 
		-- ActorState_BlockHuddleUpAction           = 35,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockHuddleUpAction" then 
		-- ActorState_DisableTimeScale              = 36,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableTimeScale" then 
		-- ActorState_DisableLockOn                 = 37,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableLockOn" then 
		-- ActorState_HideHUD                       = 38,
		elseif ActorState.Name == "ESBActorState::ActorState_HideHUD" then 
		-- ActorState_BlockAI                       = 39,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockAI" then 
		-- ActorState_BlockOverlapMove              = 40,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockOverlapMove" then 
		-- ActorState_DisableLookAtTargetBySkill    = 41,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableLookAtTargetBySkill" then 
		-- ActorState_NoScan                        = 42,
		elseif ActorState.Name == "ESBActorState::ActorState_NoScan" then 
		-- ActorState_NoScanHUD                     = 43,
		elseif ActorState.Name == "ESBActorState::ActorState_NoScanHUD" then 
		-- ActorState_KeepDetectTarget              = 44,
		elseif ActorState.Name == "ESBActorState::ActorState_KeepDetectTarget" then 
		-- ActorState_DisableRuleMoveBlockArea      = 45,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableRuleMoveBlockArea" then 
		-- ActorState_NarrowVision                  = 46,
		elseif ActorState.Name == "ESBActorState::ActorState_NarrowVision" then 
		-- ActorState_BlockBodySuitChange           = 47,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockBodySuitChange" then 
		-- ActorState_NotTargeted                   = 48,
		elseif ActorState.Name == "ESBActorState::ActorState_NotTargeted" then 
		-- ActorState_Rage                          = 49,
		elseif ActorState.Name == "ESBActorState::ActorState_Rage" then 
		-- ActorState_DisableHitStop                = 50,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableHitStop" then 
		-- ActorState_DoubleJump                    = 51,
		elseif ActorState.Name == "ESBActorState::ActorState_DoubleJump" then 
		-- ActorState_DisableLockonTarget           = 52,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableLockonTarget" then 
		-- ActorState_DisableMountingEquipment      = 53,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableMountingEquipment" then 
		-- ActorState_DisableLockOnMissile          = 54,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableLockOnMissile" then 
		-- ActorState_BlockRevival                  = 55,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockRevival" then 
		-- ActorState_DisableTPSBulletChange        = 56,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableTPSBulletChange" then 
		-- ActorState_BlockBetaGaugeEnergySkill     = 57,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockBetaGaugeEnergySkill" then 
		-- ActorState_BlockHPEnergySkill            = 58,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockHPEnergySkill" then 
		-- ActorState_BlockStaminaEnergySkill       = 59,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockStaminaEnergySkill" then 
		-- ActorState_BlockBurstGaugeEnergySkill    = 60,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockBurstGaugeEnergySkill" then 
		-- ActorState_InfiniteBetaGaugeEnergy       = 61,
		elseif ActorState.Name == "ESBActorState::ActorState_InfiniteBetaGaugeEnergy" then 
		-- ActorState_HideLockOnUI                  = 62,
		elseif ActorState.Name == "ESBActorState::ActorState_HideLockOnUI" then 
		-- ActorState_DisableControllerInput        = 63,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableControllerInput" then 
		-- ActorState_ActiveWeakPointDamage         = 64,
		elseif ActorState.Name == "ESBActorState::ActorState_ActiveWeakPointDamage" then 
		-- ActorState_PeacefulMode                  = 65,
		elseif ActorState.Name == "ESBActorState::ActorState_PeacefulMode" then 
		-- ActorState_DisableAutoLockOnWhenUnlockon = 66,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableAutoLockOnWhenUnlockon" then 
		-- ActorState_BlockItemUseHeal              = 67,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockItemUseHeal" then 
		-- ActorState_BlockItemUseUtil              = 68,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockItemUseUtil" then 
		-- ActorState_BlockItemInteraction          = 69,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockItemInteraction" then 
		-- ActorState_DisablePlayDeadShow           = 70,
		elseif ActorState.Name == "ESBActorState::ActorState_DisablePlayDeadShow" then 
		-- ActorState_DisablePlayDespawnShow        = 71,
		elseif ActorState.Name == "ESBActorState::ActorState_DisablePlayDespawnShow" then 
		-- ActorState_TachyMode                     = 72,
		elseif ActorState.Name == "ESBActorState::ActorState_TachyMode" then 
		-- ActorState_EnableFishingTakeBack         = 73,
		elseif ActorState.Name == "ESBActorState::ActorState_EnableFishingTakeBack" then 
		-- ActorState_BlockInteraction              = 74,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockInteraction" then 
		-- ActorState_EnableDetectCamp              = 75,
		elseif ActorState.Name == "ESBActorState::ActorState_EnableDetectCamp" then 
		-- ActorState_EnableDetectNikkeLostGoods    = 76,
		elseif ActorState.Name == "ESBActorState::ActorState_EnableDetectNikkeLostGoods" then 
		-- ActorState_NotUsedBattleAnimSwitchDelay  = 77,
		elseif ActorState.Name == "ESBActorState::ActorState_NotUsedBattleAnimSwitchDelay" then 
		-- ActorState_DisableDetectCamp             = 78,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableDetectCamp" then 
		-- ActorState_DisableDeadSkill              = 79,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableDeadSkill" then 
		-- ActorState_DisableLookAtIK               = 80,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableLookAtIK" then 
		-- ActorState_EnableDetectCan               = 81,
		elseif ActorState.Name == "ESBActorState::ActorState_EnableDetectCan" then 
		-- ActorState_UseOnlyComboSkill             = 82,
		elseif ActorState.Name == "ESBActorState::ActorState_UseOnlyComboSkill" then 
		-- ActorState_NotTPSAutoTargeted            = 83,
		elseif ActorState.Name == "ESBActorState::ActorState_NotTPSAutoTargeted" then 
		-- ActorState_NotTPSMagnet                  = 84,
		elseif ActorState.Name == "ESBActorState::ActorState_NotTPSMagnet" then 
		-- ActorState_BlockEventMove                = 85,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockEventMove" then 
		-- ActorState_BlockItemGainShow             = 86,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockItemGainShow" then 
		-- ActorState_EnableFishingMode             = 87,
		elseif ActorState.Name == "ESBActorState::ActorState_EnableFishingMode" then 
		-- ActorState_DisableScreenEffect           = 88,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableScreenEffect" then 
		-- ActorState_BlockDetectCan                = 89,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockDetectCan" then 
		-- ActorState_DisableLowHealthAlertScreenEffect = 90,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableLowHealthAlertScreenEffect" then 
		-- ActorState_PossibleInteraction           = 91,
		elseif ActorState.Name == "ESBActorState::ActorState_PossibleInteraction" then 
		-- ActorState_Fusion1Mode                   = 92,
		elseif ActorState.Name == "ESBActorState::ActorState_Fusion1Mode" then 
		-- ActorState_Fusion2Mode                   = 93,
		elseif ActorState.Name == "ESBActorState::ActorState_Fusion2Mode" then 
		-- ActorState_EnableExtraSprint             = 94,
		elseif ActorState.Name == "ESBActorState::ActorState_EnableExtraSprint" then 
		-- ActorState_DisableShield                 = 95,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableShield" then 
		-- ActorState_DisableMonsterWarp            = 96,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableMonsterWarp" then 
		-- ActorState_DisableActionAssist           = 97,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableActionAssist" then 
		-- ActorState_BlockMoveInputBlock           = 98,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockMoveInputBlock" then 
		-- ActorState_DisableeLockOnControl         = 99,
		elseif ActorState.Name == "ESBActorState::ActorState_DisableeLockOnControl" then 
		-- ActorState_BlockItemUseBullet            = 100,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockItemUseBullet" then 
		-- ActorState_AutoLockonTargetAfterTPS      = 101,
		elseif ActorState.Name == "ESBActorState::ActorState_AutoLockonTargetAfterTPS" then 
		-- ActorState_SelfiePhotoMode               = 102,
		elseif ActorState.Name == "ESBActorState::ActorState_SelfiePhotoMode" then 
		-- ActorState_ProjectileNoHit               = 103,
		elseif ActorState.Name == "ESBActorState::ActorState_ProjectileNoHit" then 
		-- ActorState_UsePlayerAIPositioning        = 104,
		elseif ActorState.Name == "ESBActorState::ActorState_UsePlayerAIPositioning" then 
		-- ActorState_BlockInteractionWithNotiUI    = 105,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockInteractionWithNotiUI" then 
		-- ActorState_Max                           = 106,
		elseif ActorState.Name == "ESBActorState::ActorState_Max" then 
		
		else 
		end 
	end 
end 

StellarBlade.ActorApplyStat = function(self,StatType,StatCalculationType,CalculationMultipleValue,CalculationValue) 

	
end 

StellarBlade.CanStartSkill = function(self,SkillName) 

end 

StellarBlade.StartSkill = function(self,SkillName) 
	local CheckCooldown = self.SBAI_SkillTimers and self.SBAI_SkillTimers[SkillName] -- returns Time, ["M_Raven_SlashChain"] = 216 
	local UsableCount = self.SBAI_SkillUseCount and self.SBAI_SkillUseCount[SkillName] -- returns Time, ["M_Raven_SlashChain"] = 216 
	local SkillTable = SB_SkillTable[1].Rows[SkillName] 
	if SkillTable.UsableCount > 0 and UsableCount and UsableCount > SkillTable.UsableCount then 
		Entity(1):ChatPrint(SkillName.." not activated, max amount used "..tostring(SkillTable.UsableCount)) 
		return false 
	end 
	
	if self["ESBActorState::ActorState_BlockSkill"] then return false end 
	if !CheckCooldown or CheckCooldown and CurTime() >= CheckCooldown then 
		self.SBAI_SkillTable = SkillTable 
		local FirstSkillActiveAlias = SkillTable.FirstSkillActiveAlias 
		-- This now correctly handles all the data-driven setup for the first step 
		local bSkillStep = StellarBlade.SetSkillStep(self,FirstSkillActiveAlias) 
		if !bSkillStep then Entity(1):ChatPrint("skill start failed for ".. FirstSkillActiveAlias) self.SBAI_ActiveSkill = nil self.SBAI_SkillTable = nil return false end 
		if !self.SBAI_SkillTimers then self.SBAI_SkillTimers = { } end 
		if !self.SBAI_SkillUseCount then self.SBAI_SkillUseCount = { } end 
		self.SBAI_SkillTimers[SkillName] = CurTime() + SkillTable.CoolTime 
		self.SBAI_SkillUseCount[SkillName] = self.SBAI_SkillUseCount[SkillName] or 1 
		Entity(1):ChatPrint("starting "..SkillName.." at CurTime:"..tostring(CurTime())) 
		self.SBAI_SkillTable.Remove = function() 
			-- reset activity to ACT_IDLE 
			self:ResetIdealActivity(ACT_IDLE) 
			-- for players, reset attack gesture 
			if self:IsPlayer() then 
				self:AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_RESET, true ) 
				BroadcastLua("if IsValid(Entity("..self:EntIndex()..")) then Entity("..self:EntIndex().."):AnimRestartGesture(0,ACT_RESET,true) end ") 
			end 
			-- destruct skill table 
			self.SBAI_SkillTable = nil 
			-- also destruct skill step table if exists 
		end 
		return true 
	end 
	return false 
end 

StellarBlade.StartSkillCommand = function(self,SkillName) 
	local CheckCooldown = self.SBAI_SkillTimers and self.SBAI_SkillTimers[SkillName] -- returns Time, ["M_Raven_SlashChain"] = 216 
	local SkillCommandTable = SB_SkillCommandTable[1].Rows[SkillName] 
	local SkillNameFromSkillCommandTable = SkillCommandTable.SkillAlias 
	local SkillTable = SB_SkillTable[1].Rows[SkillNameFromSkillCommandTable] 
	if self["ESBActorState::ActorState_BlockSkill"] then return false end 
	if !CheckCooldown or CheckCooldown and CurTime() >= CheckCooldown then 
		self.SBAI_SkillTable = SkillTable 
		local FirstSkillActiveAlias = SkillTable.FirstSkillActiveAlias 
		-- This now correctly handles all the data-driven setup for the first step 
		local bSkillStep = StellarBlade.SetSkillStep(self,FirstSkillActiveAlias) 
		if !bSkillStep then Entity(1):ChatPrint("skill start failed for ".. FirstSkillActiveAlias) self.SBAI_ActiveSkill = nil self.SBAI_SkillTable = nil return false end 
		if !self.SBAI_SkillTimers then self.SBAI_SkillTimers = { } end 
		self.SBAI_SkillTimers[SkillName] = CurTime() + SkillTable.CoolTime 
		Entity(1):ChatPrint("starting "..SkillName.." at CurTime:"..tostring(CurTime())) 
		return true 
	end 
	return false 
end 

-- Helper: apply render state recursively (pulled out so we can use it on start & end)
local function ApplyRenderState(ent, hide)
	if !IsValid(ent) then return end
	if hide == nil then hide = false end 

	if hide then
		ent:SetRenderMode(RENDERMODE_NONE)
		ent:SetColor(Color(255, 255, 255, 0))
	else
		ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
		ent:SetColor(Color(255, 255, 255, 255))
	end

	-- Include weapon and children
	local wep = ent.GetActiveWeapon and ent:GetActiveWeapon()
	if IsValid(wep) then
		if hide then
			wep:SetRenderMode(RENDERMODE_NONE)
			wep:SetColor(Color(255, 255, 255, 0))
		else
			wep:SetRenderMode(RENDERMODE_TRANSCOLOR)
			wep:SetColor(Color(255, 255, 255, 255))
		end
	end

	for _, child in ipairs(ent:GetChildren()) do
		if IsValid(child) then
			if hide then
				child:SetRenderMode(RENDERMODE_NONE)
				child:SetColor(Color(255, 255, 255, 0))
			else
				child:SetRenderMode(RENDERMODE_TRANSCOLOR)
				child:SetColor(Color(255, 255, 255, 255))
			end
		end
	end
end

StellarBlade.SetShow = function(self,showpath) 
	-- scripted_ents.Get("npc_sb_raven").SBAI_SetShow(self,showPath) 
	if !showpath then return false end 
	if #showpath == 0 then return false end 
	if !string.find(showpath,"data_static") then -- append correct path if setshow has been directly called 
		showpath = "data_static/SB/Content/Art/Show/"..showpath..".json" 
	end 
	SB_ImportJSON(showpath) 
	self.SBAI_ActiveShow = {["Time"] = CurTime(),["RunTime"] = CurTime(), ["Cycle"] = 0} 
	self.SBAI_ActiveShow.Dir = showpath 
	local showname = string.GetFileFromFilename( showpath ) 
	showname = string.StripExtension(showname) 
	self.SBAI_ActiveShow.Name = showname 
	self.SBAI_ActiveShow.Frame = 0 
	self.SBAI_ActiveShow.Stopped = false 
	showname = "SB_"..showname 
	-- self:SBAI_MaintainShow() 
	-- scripted_ents.Get("npc_sb_raven").SBAI_MaintainShow(self) 
	StellarBlade.MaintainShow(self,self.SBAI_ActiveShow) 
	return showname -- return true on animation play, false on not play 
end 

StellarBlade.SetShow_alt = function(self,showpath) 
	-- scripted_ents.Get("npc_sb_raven").SBAI_SetShow(self,showPath) 
	if !showpath then return false end 
	if #showpath == 0 then return false end 
	if !string.find(showpath,"data_static") then -- append correct path if setshow has been directly called 
		showpath = "data_static/SB/Content/Art/Show/"..showpath..".json" 
	end 
	SB_ImportJSON(showpath) 
	self.SBAI_ActiveShow_alt = {["Time"] = CurTime(),["RunTime"] = CurTime(), ["Cycle"] = 0} 
	self.SBAI_ActiveShow_alt.Dir = showpath 
	local showname = string.GetFileFromFilename( showpath ) 
	showname = string.StripExtension(showname) 
	self.SBAI_ActiveShow_alt.Name = showname 
	self.SBAI_ActiveShow_alt.Frame = 0 
	self.SBAI_ActiveShow_alt.Stopped = false 
	showname = "SB_"..showname 
	-- self:SBAI_MaintainShow() 
	-- scripted_ents.Get("npc_sb_raven").SBAI_MaintainShow(self) 
	StellarBlade.MaintainShow(self,self.SBAI_ActiveShow_alt) 
	return showname -- return true on animation play, false on not play 
end 

StellarBlade.MaintainShow = function(self,SBAI_ActiveShow) 
	local flRescale = 0.42 
	if !SBAI_ActiveShow or SBAI_ActiveShow.Stopped then return end
	if !SBAI_ActiveShow.Name then return end

	local showname = "SB_" .. SBAI_ActiveShow.Name
	local showdata = _G[showname]
	if !showdata then return end

	-- Find SBShowData entry
	local showEntry
	for _, data in pairs(showdata) do
		if data.Type == "SBShowData" then
			showEntry = data
			break
		end
	end
	if !showEntry then return end

	local props = showEntry.Properties
	local endTime = props.EndTime or 0
	if endTime <= 0 then return end

	-- Advance elapsed time
	local Elapsed = CurTime() - (SBAI_ActiveShow.RunTime or CurTime())
	SBAI_ActiveShow.Elapsed = (SBAI_ActiveShow.Elapsed or 0) + Elapsed
	SBAI_ActiveShow.RunTime = CurTime()

	-- Create triggered list if not yet present
	SBAI_ActiveShow.TriggeredKeys = SBAI_ActiveShow.TriggeredKeys or {} 
	SBAI_ActiveShow.ScheduledEndKeys = SBAI_ActiveShow.ScheduledEndKeys or {}
	SBAI_ActiveShow.EndedKeys = SBAI_ActiveShow.EndedKeys or {} 
	
	local function HandleShowKeyEnd(data)
		local props = data.Properties or {}

		if data.Type == "SBShowActorKey" then
			local bUseActorHidden = props.bUseActorHidden 
			if isstring(bUseActorHidden) then 
				bUseActorHidden = tobool(bUseActorHidden) 
			-- revert the actor to the opposite render state
				-- print("hidden end is:",bUseActorHidden) 
				ApplyRenderState(self, !bUseActorHidden) 
			end 
			-- PrintTable(data) 

		-- add additional end-behaviours here as required, e.g. for particle detach / stop,
		-- animbp resets, etc. For now we keep it minimal since most cases are type-specific.
		end
	end

	-- Iterate all entries (SBShowAnimKey, SBShowActorKey, SBShowSoundKey, etc.)
	for _, data in ipairs(showdata) do
		local props = data.Properties or {}
		local StartTime = props.StartTime or 0 

		-- Skip if not reached yet or already triggered
		-- print("SBAI_ActiveShow.Elapsed:",SBAI_ActiveShow.Elapsed) 
		if SBAI_ActiveShow.Elapsed < StartTime then
			continue
		end
		if SBAI_ActiveShow.TriggeredKeys[data.Name] then
			continue
		end

		-- Mark as triggered
		SBAI_ActiveShow.TriggeredKeys[data.Name] = true
		-- Entity(1):ChatPrint("SBShowAnimKey: Triggered "..data.Name.." at time: "..(CurTime() - SBAI_ActiveShow.Time)) 
		
		local CheckShowKeyTag = data.Properties.CheckShowKeyTag 
		-- static_assert(offsetof(USBShowKey, CheckShowKeyTag) == 0x000028, "Member 'USBShowKey::CheckShowKeyTag' has a wrong offset!");
		-- static_assert(offsetof(USBShowKey, CheckNoneShowKeyTag) == 0x000038, "Member 'USBShowKey::CheckNoneShowKeyTag' has a wrong offset!");
		-- static_assert(offsetof(USBShowKey, IsBattle) == 0x000048, "Member 'USBShowKey::IsBattle' has a wrong offset!");
		-- static_assert(offsetof(USBShowKey, StartTime) == 0x00004C, "Member 'USBShowKey::StartTime' has a wrong offset!");
		-- static_assert(offsetof(USBShowKey, bKeepPlaying) == 0x000050, "Member 'USBShowKey::bKeepPlaying' has a wrong offset!");
		-- static_assert(offsetof(USBShowKey, bCheckHitLevel) == 0x000051, "Member 'USBShowKey::bCheckHitLevel' has a wrong offset!");
		-- static_assert(offsetof(USBShowKey, bEnable) == 0x000052, "Member 'USBShowKey::bEnable' has a wrong offset!");
		-- static_assert(offsetof(USBShowKey, bNeedsExecutionKey) == 0x000053, "Member 'USBShowKey::bNeedsExecutionKey' has a wrong offset!");
		-- static_assert(offsetof(USBShowKey, Duration) == 0x000054, "Member 'USBShowKey::Duration' has a wrong offset!");
		
		-- SCHEDULE END: determine duration and schedule end-handling
		local duration = props.Duration
		-- If no duration (or <=0) make it last until end of the show
		if not duration or duration <= 0 then
			-- last until show end
			-- EndAt is the elapsed-time in show where it should end
			local EndAt = endTime
			SBAI_ActiveShow.ScheduledEndKeys[data.Name] = { EndAt = EndAt, Data = data }
			-- If we already passed EndAt, end immediately
			if SBAI_ActiveShow.Elapsed >= EndAt then
				-- immediate end
				if not SBAI_ActiveShow.EndedKeys[data.Name] then
					SBAI_ActiveShow.EndedKeys[data.Name] = true
					HandleShowKeyEnd(data)
					SBAI_ActiveShow.ScheduledEndKeys[data.Name] = nil
				end
			end
		else
			-- Normal: end at StartTime + duration
			local EndAt = StartTime + duration
			SBAI_ActiveShow.ScheduledEndKeys[data.Name] = { EndAt = EndAt, Data = data }
			-- If duration is zero or already passed, end immediately
			if SBAI_ActiveShow.Elapsed >= EndAt then
				if not SBAI_ActiveShow.EndedKeys[data.Name] then
					SBAI_ActiveShow.EndedKeys[data.Name] = true
					HandleShowKeyEnd(data)
					SBAI_ActiveShow.ScheduledEndKeys[data.Name] = nil
				end
			end
		end
		
		-- === Handle key types ===
		if data.Type == "SBShowAnimKey" then
			local Target = props.Target or "ESBShowActorTarget::ShowActorTarget_MainActor"
			local anim = props.AnimResourcePath and string.GetFileFromFilename(props.AnimResourcePath)
			if anim then
				if Target == "ESBShowActorTarget::ShowActorTarget_MainActor" then 
					if self:IsPlayer() then 
						self:AddVCDSequenceToGestureSlot(0,self:LookupSequence(anim),0,true) 
						BroadcastLua("if IsValid(Entity("..self:EntIndex()..")) then Entity("..self:EntIndex().."):AddVCDSequenceToGestureSlot(0,"..self:LookupSequence(anim)..",0,true) end") 
					else 
						scripted_ents.Get("npc_sb_raven").NPC_StartScriptedActivity(self,anim, true) 
					end 
				elseif Target == "ESBShowActorTarget::ShowActorTarget_OtherActor" then 
					-- Optional: handle other actor animations 
				end 
			end 

		elseif data.Type == "SBShowActorKey" then 
			local bUseActorHidden = props.bUseActorHidden 
			if isstring(bUseActorHidden) then 
				bUseActorHidden = tobool(bUseActorHidden) 
			-- Apply immediately (no timer here; revert is scheduled via ScheduledEndKeys above)
				print("hidden is:",bUseActorHidden) 
				ApplyRenderState(self, bUseActorHidden)

			-- (previous timer.Simple revert removed because we now schedule end above)
			-- The ScheduledEndKeys / HandleShowKeyEnd will revert when duration/endTime is reached. 
			end 


		elseif data.Type == "SBShowSoundKey" or data.Type == "SBShowCharSESoundKey" then 
			local CuePath
			local TargetForCharacterVoice = data.Properties.TargetForCharacterVoice 
			if TargetForCharacterVoice and TargetForCharacterVoice == "ESBShowCharacterParticleTarget::ShowCharParticleTarget_OtherActor" then 
				if self.GetEnemy and IsValid(self:GetEnemy()) then 
					TargetForCharacterVoice = self:GetEnemy() 
				elseif IsValid(self.PickTarget) then 
					TargetForCharacterVoice = self.PickTarget
				else 
					TargetForCharacterVoice = self 
				end 
			end 
			if !TargetForCharacterVoice then TargetForCharacterVoice = self end 
			if data.Type == "SBShowCharSESoundKey" then 
				-- skip emitting char sounds on HL2 characters 
				if self:IsPlayer() and self:GetModel() != "models/alvaroports/sbravenpm.mdl" then 
					print("not raven",self) 
					continue 
				end 
				if !self:IsPlayer() and !scripted_ents.IsBasedOn(self:GetClass(),"npc_sb_raven") and self:GetClass() != "npc_sb_raven" then 
					print("not raven",self) 
					continue 
				end 
				local key = props.CharacterReactKey or props.CharacterVoiceKey 
				if key then 
					local lookup = StellarBlade.LookupCharacterSound(self,key) 
					CuePath = lookup and lookup.ObjectPath 
				else 
					if data.Properties.Sound then 
						CuePath = string.StripExtension(data.Properties.Sound.ObjectPath) 
					end 
				end 
				if CuePath then
					CuePath = string.gsub(CuePath, "/L10N/[^/]+", "")
				end
			else
				CuePath = props.SoundSoftObject and props.SoundSoftObject.AssetPathName
				if !CuePath and props.Sound then
					CuePath = props.Sound.ObjectPath
				end
			end

			if CuePath then
				CuePath = string.sub(CuePath, 6)
				CuePath = "addons/sbraven/data_static/SB/Content" .. CuePath
				CuePath = string.StripExtension(CuePath) .. ".json"

				local SoundScript = StellarBlade.BuildSoundScript(self,CuePath)
				if SoundScript then
					if SoundScript.Delay and SoundScript.Delay != 0 then
						timer.Simple(SoundScript.Delay, function()
							if IsValid(self) then
								TargetForCharacterVoice:EmitSound(SoundScript.SoundPath, 100, SoundScript.Pitch, SoundScript.Volume)
							end
						end)
					else
						TargetForCharacterVoice:EmitSound(SoundScript.SoundPath, 100, SoundScript.Pitch, SoundScript.Volume)
					end
				end
			end
		elseif data.Type == "SBShowActorAnimKey" then -- used for Eve in Menu mode, for her facial expressions 
		elseif data.Type == "SBShowActorCompVisibleKey" then -- used to draw or hide actors and children in Menu mode 
		elseif data.Type == "SBShowActorEventNotificationKey" then -- fires Properties.EventName in Menu mode 
		elseif data.Type == "SBShowAnimBPSetValueKey" then 
			-- Prepare AnimBP entry
			self.SBAI_AnimationBlueprint = self.SBAI_AnimationBlueprint or {}
			local animData = {
				Name = data.Name,
				StartTime = data.StartTime or 0,
				Duration = data.Duration or 0,
				CurveKeys = (data.Value and data.Value.EditorCurveData and data.Value.EditorCurveData.Keys) or {},
				RecoverValue = data.RecoverValue,
				RecoverTime = data.RecoverTime,
				RecoverWaitTime = data.RecoverWaitTime,
				Target = data.Target or "Self",
				StartSysTime = CurTime(),
			}
			self.SBAI_AnimationBlueprint[data.Name] = animData

			local function GetCurveValue(keys, t)
				if not keys or #keys == 0 then return 0 end
				if #keys == 1 then return keys[1].Value or 0 end

				for i = 1, #keys - 1 do
					local k1, k2 = keys[i], keys[i + 1]
					if t >= k1.Time and t <= k2.Time then
						local frac = (t - k1.Time) / (k2.Time - k1.Time)
						return Lerp(frac, k1.Value or 0, k2.Value or 0)
					end
				end
				return keys[#keys].Value or 0
			end

			local function ApplyValue(ent, varName, value)
				if not IsValid(ent) then return end
				-- You can replace this with your custom AnimBP binding handler
				ent[varName] = value
			end

			-- Determine target entity
			local targetEnt = self
			if animData.Target == "ESBShowActorTarget::ShowActorTarget_OtherActor" and IsValid(SBAI_ActiveShow.OtherActor) then
				targetEnt = SBAI_ActiveShow.OtherActor
			end

			-- Interpolation logic
			local function AdvanceAnimBP()
				if not IsValid(self) or not IsValid(targetEnt) then return end
				if SBAI_ActiveShow ~= currentShow then
					-- Instantly set to target and stop
					local lastValue = GetCurveValue(animData.CurveKeys, 1.0)
					ApplyValue(targetEnt, animData.Name, lastValue)
					return
				end

				local elapsed = CurTime() - animData.StartSysTime
				local norm = math.Clamp(elapsed / animData.Duration, 0, 1)
				local value = GetCurveValue(animData.CurveKeys, norm)
				ApplyValue(targetEnt, animData.Name, value)

				if norm < 1 then
					timer.Simple(0.01, AdvanceAnimBP)
				else
					-- Reached end — handle recovery if any
					if animData.RecoverValue ~= nil then
						timer.Simple(animData.RecoverWaitTime or 0, function()
							if not IsValid(self) or not IsValid(targetEnt) then return end
							if SBAI_ActiveShow ~= currentShow then return end

							local startVal = value
							local endVal = animData.RecoverValue
							local StartTime = CurTime()

							local function RecoverStep()
								if not IsValid(self) or not IsValid(targetEnt) then return end
								local rElapsed = CurTime() - StartTime
								local rNorm = math.Clamp(rElapsed / (animData.RecoverTime or 0.5), 0, 1)
								local v = Lerp(rNorm, startVal, endVal)
								ApplyValue(targetEnt, animData.Name, v)
								if rNorm < 1 and SBAI_ActiveShow == currentShow then
									timer.Simple(0.01, RecoverStep)
								end
							end

							RecoverStep()
						end)
					end
				end
			end

			-- Start interpolation
			local currentShow = SBAI_ActiveShow
			AdvanceAnimBP()

		elseif data.Type == "SBShowAnimBlendSpaceKey" then -- play blend anim, used by Eve 
		elseif data.Type == "SBShowAnimByMeshSlotKey" then -- play anim on given mesh slot. for example if meshslot is ESBMesh_Body, it plays on actor 
		-- but if it is ESBMesh_Weapon2, it plays on weapon 
		elseif data.Type == "SBShowAnimNodeGroundCollisionKey" then -- used only by Tentacle 
		--[[ 
		  {
		"Type": "SBShowAnimNodeGroundCollisionKey",
		"Name": "SBShowAnimNodeGroundCollisionKey_0",
		"Outer": "M_Tentacle_Stamp",
		"Class": "UScriptClass'SBShowAnimNodeGroundCollisionKey'",
		"Flags": "RF_Public | RF_Transactional | RF_WasLoaded | RF_LoadCompleted",
		"Properties": {
		  "StartBone": "Bip001-Spine",
		  "EndBone": "Skin_Tentacle_End",
		  "StartTime": 0.95,
		  "Duration": 0.4
		}
	  }, 
	  --]] 
		elseif data.Type == "SBShowAnimTransitKey" then -- used while eve is aiming with weapons 
		elseif data.Type == "SBShowCableKey" then -- used by droid npcs, attach cables to TargetAttachBoneName 
		elseif data.Type == "SBShowCamAnimKey" then -- enables camera motion on target using Properties.MatineeCameraAnimObjectPath.ObjectPath
		elseif data.Type == "SBShowCamShakeKey" then
			local props = data.Properties
			if !props then continue end

			local duration = props.Duration or (props.CameraShakeParams and props.CameraShakeParams.OscillationDuration) or 0.3
			local scale = props.ShakeScale or 1
			local params = props.CameraShakeParams or {}

			-- Pick one axis as base amplitude and frequency (Unreal just mixes them, we’ll average)
			local loc = params.LocOscillation or {}
			local rot = params.RotOscillation or {}
			local ampX = (loc.X and loc.X.Amplitude or 0)
			local ampY = (loc.Y and loc.Y.Amplitude or 0)
			local ampZ = (loc.Z and loc.Z.Amplitude or 0)
			local rollAmp = (rot.Roll and rot.Roll.Amplitude or 0)

			-- Compute approximate amplitude
			local amplitude = (ampX + ampY + ampZ + rollAmp) / math.max(1, (ampX>0 and 1 or 0) + (ampY>0 and 1 or 0) + (ampZ>0 and 1 or 0) + (rollAmp>0 and 1 or 0))
			if amplitude == 0 then amplitude = 5 end -- fallback

			local freqX = (loc.X and loc.X.Frequency or 0)
			local freqY = (loc.Y and loc.Y.Frequency or 0)
			local freqZ = (loc.Z and loc.Z.Frequency or 0)
			local rollFreq = (rot.Roll and rot.Roll.Frequency or 0)
			local frequency = (freqX + freqY + freqZ + rollFreq) / math.max(1, (freqX>0 and 1 or 0) + (freqY>0 and 1 or 0) + (freqZ>0 and 1 or 0) + (rollFreq>0 and 1 or 0))
			if frequency == 0 then frequency = 40 end -- fallback

			amplitude = amplitude * scale

			local originEnt = self
			local pos = IsValid(originEnt) and originEnt:GetPos() or vector_origin
			local radius = 5000
			local airshake = true
			local filter = nil
			util.ScreenShake(pos, amplitude, frequency, duration, radius, airshake, filter)
			-- Debug print
			-- Entity(1):ChatPrint(string.format("[SBAI-ShowData] CamShake: amp=%.1f, freq=%.1f, dur=%.2f ", amplitude, frequency, duration))

		elseif data.Type == "SBShowChangeAttachTo" then -- call function with named parameter after passing some conditions 
		elseif data.Type == "SBShowClientEventKey" then 
		elseif data.Type == "SBShowControlCamLagSpeedKey" then 
		elseif data.Type == "SBShowControlCameraVolumeKey" then 
		elseif data.Type == "SBShowControlLockOnTargetBoneKey" then 
		elseif data.Type == "SBShowCreateDestructibleKey" then -- creates a debris at local origin. those meshes are unlikely to exist. they aren't used by raven anyway 
		elseif data.Type == "SBShowCreateStaticMeshKey" then -- creates a mesh at given location and socketname for specific time. 
		elseif data.Type == "SBShowData" then 
		elseif data.Type == "SBShowDeactiveParticleKey" then 
		elseif data.Type == "SBShowDecalKey" then -- sprite at given socketname and relative location till duration 
		elseif data.Type == "SBShowDynamicPhysicBStopKey" then -- disable phys bone follower 
		elseif data.Type == "SBShowDynamicPhysicBonesKey" then -- enable phys bone follower 
		elseif data.Type == "SBShowEffectKey" then -- set given effect to the EffectAlias table 
		-- not to be confused with particles 
		elseif data.Type == "SBShowFlyKey" then -- set flying 
			self.bFlyMoveSet = data.Properties.bFlyOnOff  
		elseif data.Type == "SBShowHitReactionKey" then -- hit gesture 
		-- contains hit animation path relative to direction 
		elseif data.Type == "SBShowLockOnTargetKey" then -- aims Eve eye angles to the target bone set by NPC for given duration 
		elseif data.Type == "SBShowMaterialChangeKey" then -- change character's material with given material instance 
		elseif data.Type == "SBShowMaterialCollectionParamKey" then -- something like overlay 
		elseif data.Type == "SBShowMaterialParamKey" then 
		elseif data.Type == "SBShowMeshVertexShakeKey" then -- used by Eve 
		elseif data.Type == "SBShowNiagaraKey" then -- directly spawn niagara system, only 3 examples 
		elseif data.Type == "SBShowNotifyEventKey" then -- call given event 
		elseif data.Type == "SBShowParticleKey" then -- creates niagara system with properties, the most difficult and advanced system 
			local AssetName 
			-- PrintTable(data) 
			if data.Properties and data.Properties.NiagaraSystem and data.Properties.NiagaraSystem.NiagaraSystemPath then 
				AssetName = string.GetExtensionFromFilename(data.Properties.NiagaraSystem.NiagaraSystemPath.AssetPathName) 
			end 
			if AssetName then 
				local CustomTimeDilation = data.Properties.CustomTimeDilation 
				local SocketName = data.Properties.SocketName -- attachment 
				local bAttach = data.Properties.bAttach 
				local ParticleScale = data.Properties.ParticleScale 
				local bUseTargetEquipment = data.Properties.bUseTargetEquipment 
				local RelativeLocation = data.Properties.RelativeLocation 
				local RelativeRotation = data.Properties.RelativeRotation 
				
				ParticleScale = ParticleScale and ParticleScale * 10 or 10 
				if RelativeLocation then -- convert to proper Vector table 
					RelativeLocation = Vector(RelativeLocation.X,RelativeLocation.Y,RelativeLocation.Z) * flRescale 
				end 
				local relAng = angle_zero
				if RelativeRotation then -- convert to proper Angle table 
					relAng = Angle(RelativeRotation.Pitch or 0, RelativeRotation.Yaw or 0, RelativeRotation.Roll or 0)
				end 
				
				local ef = EffectData() 
				local EffectEntity = bUseTargetEquipment and IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon() or self 
				
				local worldPos = EffectEntity:GetPos() 
				local worldAng = EffectEntity:GetLocalAngles() -- use world-space angles, not GetLocalAngles()
				local foundAttachmentIndex = nil
				local foundBoneID = nil

				if SocketName and EffectEntity:LookupAttachment(SocketName) and EffectEntity:LookupAttachment(SocketName) != 0 then
					local attachmentIndex = EffectEntity:LookupAttachment(SocketName)
					foundAttachmentIndex = attachmentIndex
					
					local att = EffectEntity:GetAttachment(EffectEntity:LookupAttachment(SocketName))
					if att and att.Pos and att.Ang then
						worldPos = att.Pos
						worldAng = att.Ang
						-- Let effect know we used an attachment index (so engine can parent)
						ef:SetAttachment(EffectEntity:LookupAttachment(SocketName))
					end
					
					-- Try to find the Bone ID for that attachment via model info
					local model = EffectEntity:GetModel() or nil
					if model then
						local mInfo = util.GetModelInfo(model) 
						if istable(mInfo) and istable(mInfo.Attachments) then
							-- find an attachment entry with matching name (some models index attachments numerically)
							for k, v in ipairs(mInfo.Attachments) do
								if istable(v) and v.Name and v.Name == SocketName then
									foundBoneID = v.Bone
									break
								end
							end
							-- fallback: sometimes the numeric index matches attachmentIndex
							if !foundBoneID and mInfo.Attachments[attachmentIndex] and mInfo.Attachments[attachmentIndex].Bone then
								foundBoneID = mInfo.Attachments[attachmentIndex].Bone
							end
						end
					end

					-- store boneID into effect data using SetHitBox (we're repurposing hitbox field)
					if foundBoneID then
						ef:SetHitBox(foundBoneID)
					end
				end
				
				if not foundBoneID or foundBoneID == 0 then
					local fallbackBoneName = "ValveBiped.Bip01_R_Hand"
					local boneID, boneEntity = nil, nil

					-- try the effect entity (weapon) first
					if EffectEntity.LookupBone then
						local bid = EffectEntity:LookupBone(fallbackBoneName)
						if bid and bid ~= -1 then
							boneID = bid
							boneEntity = EffectEntity
						end
					end

					-- then try the actor/player (self)
					if (not boneID or boneID == -1) and IsValid(self) and self.LookupBone then
						local bid = self:LookupBone(fallbackBoneName)
						if bid and bid ~= -1 then
							boneID = bid
							boneEntity = self
						end
					end

					-- If we found a bone, use its world matrix as our origin/angles and save boneID in ef
					if boneID and boneID != -1 and boneEntity and boneEntity.GetBoneMatrix then
						local mat = boneEntity:GetBoneMatrix(boneID)
						if mat then
							local matPos = mat:GetTranslation()
							local matAng = mat:GetAngles()
							if matPos and matAng then
								worldPos = matPos
								worldAng = matAng
								foundBoneID = boneID
								ef:SetHitBox(foundBoneID) 
							end
						end
					end
				end
				

				-- If requested, prefer bone matrix world transform (works well on server where weapon may be parented to root)
				if bUseTargetEquipment and foundBoneID and EffectEntity.GetBoneMatrix then
					local mat = EffectEntity:GetBoneMatrix(foundBoneID)
					if mat then
						-- GetTranslation / GetAngles give world-space translation & rotation for that bone
						local matPos = mat:GetTranslation()
						local matAng = mat:GetAngles()
						if matPos and matAng then
							worldPos = matPos
							worldAng = matAng
							-- ensure bone saved into effect data (if not already)
							ef:SetHitBox(foundBoneID) 
						end
					end
				end 
				if !foundBoneID or foundBoneID <= 0 then ef:SetHitBox(0) end 
				print("found bone ID:",foundBoneID,SocketName,EffectEntity) 
					
				if RelativeLocation then
					-- LocalToWorld(localPos, localAng, originPos, originAng)
					local finalPos, finalAng = LocalToWorld(RelativeLocation, relAng, worldPos, worldAng)
					worldPos, worldAng = finalPos, finalAng
				end
				ef:SetAngles(worldAng) 
				ef:SetEntity(EffectEntity) 
				ef:SetMagnitude(data.Properties.Duration or 0) -- use as effect timer 
				ef:SetOrigin(worldPos) -- contains finalized position 
				ef:SetScale(ParticleScale) -- scale 
				ef:SetStart(RelativeLocation and RelativeLocation or vector_origin) 
				util.Effect(AssetName,ef) 
				-- debugoverlay.Cross(worldPos,10,2) 
				-- debugoverlay.Cross(Pos,10,5) 
			elseif data.Properties.bUsePhysParticle then 
				local PhysParticleSet = data.Properties.PhysParticleSet 
				local bPlayPhysParticleOnHitLocation = data.Properties.bPlayPhysParticleOnHitLocation 
				PhysParticleSet = PhysParticleSet.ObjectName 
			else 
				print("AssetName not found for "..data.Type) 
			end 
		elseif data.Type == "SBShowPlayShowKey" then -- play show at given path 
			local ObjectPath = data.Properties and data.Properties.ShowData and data.Properties.ShowData.ObjectPath 
			if ObjectPath then 
				ObjectPath = string.StripExtension(ObjectPath) 
				print("object path is:",ObjectPath) 
				ObjectPath = string.sub(ObjectPath,7) 
				ObjectPath = "data_static/SB/Content/"..ObjectPath..".json" 
				print("updated object path is:",ObjectPath) 
				StellarBlade.SetShow_alt(self,ObjectPath) 
			end 
		elseif data.Type == "SBShowPlayTheaterKey" then -- play scripted event 
		elseif data.Type == "SBShowPoseSnapshotKey" then -- used only by CH_M_NA_29_Bot 
		elseif data.Type == "SBShowPostProcessKey" then -- enables post process with given parameters 
		elseif data.Type == "SBShowPostProcessMaterialKey" then 
		elseif data.Type == "SBShowProjectileKey" then -- handled in SkillStepTable 
		-- used by Raven in: 
		-- M_Raven_BackJumpCombo 
		-- M_Raven_EvadeBackSwordAura 
		-- M_Raven_SwordAuraCombo 
		elseif data.Type == "SBShowRadialForceKey" then
			local props = data.Properties or {}
			if not props.bFireImpulse then continue end

			local base = self
			if !IsValid(base) then continue end

			-- Compute blast origin
			local rel = props.RelativeLocation or { X = 0, Y = 0, Z = 0 }
			local origin = base:GetPos() + base:GetForward() * (rel.X or 0)
			origin = origin + base:GetRight() * (rel.Y or 0)
			origin = origin + base:GetUp() * (rel.Z or 0)

			local radius = props.Radius or 300
			local impulse = props.ImpulseStrength or 500
			local velChange = props.bImpulseVelChange or false
			local destructDmg = props.DestructibleDamage or 0
			local dmgRadius = props.DestructibleCheckRadius or radius
			local ignoreOwner = props.bIgnoreOwningActor or false

			local attacker = base
			local dir = Vector(0, 0, 1)

			-- Debug
			Entity(1):ChatPrint(string.format("[SBAI-ShowData] RadialForce blast at %s (R=%.0f, Impulse=%.0f)", tostring(origin), radius, impulse))

			-- Find nearby entities
			local affected = ents.FindInSphere(origin, radius)
			for _, ent in ipairs(affected) do
				if not IsValid(ent) then continue end
				if ignoreOwner and ent == base then continue end

				-- Compute direction and strength falloff
				local dirVec = (ent:GetPos() + ent:OBBCenter() - origin)
				local dist = dirVec:Length()
				dirVec:Normalize()
				local falloff = 1 - math.Clamp(dist / radius, 0, 1)
				local strength = impulse * falloff

				-- Apply physics impulse
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					if velChange then
						phys:ApplyForceCenter(dirVec * strength * 50) -- scaled for visible kick
					else
						phys:ApplyForceOffset(dirVec * strength, ent:GetPos())
					end
				end

				-- Apply damage
				if destructDmg > 0 and dist <= dmgRadius then
					local dmginfo = DamageInfo()
					dmginfo:SetDamage(destructDmg * falloff)
					dmginfo:SetAttacker(IsValid(attacker) and attacker or ent)
					dmginfo:SetInflictor(IsValid(self) and self or attacker)
					dmginfo:SetDamageType(DMG_BLAST)
					dmginfo:SetDamageForce(dirVec * strength * 30)

					-- Simulated trace
					local tr = util.TraceLine({
						start = origin,
						endpos = ent:GetPos() + ent:OBBCenter(),
						filter = base
					})
					if tr.Hit then
						ent:DispatchTraceAttack(dmginfo, tr, dirVec)
					else
						ent:TakeDamageInfo(dmginfo)
					end
				end
			end

		elseif data.Type == "SBShowRagdollKey" then -- has ability to fade between ragdoll status and become normal again. right now just become ragdoll. 
			self:BecomeRagdoll() -- fades at Properties.Duration 
		elseif data.Type == "SBShowRuleMoveKey" then -- already handled in OverrideMode 
		elseif data.Type == "SBShowSetAIDecoratorKey" then -- Eve only 
		elseif data.Type == "SBShowSkillResultKey" then 
		elseif data.Type == "SBShowSoundAdjusterKey" then 
		  -- {
		-- "Type": "SBShowSoundAdjusterKey",
		-- "Name": "SBShowSoundAdjusterKey_0",
		-- "Outer": "M_DollHead_ChaseBomb",
		-- "Class": "UScriptClass'SBShowSoundAdjusterKey'",
		-- "Flags": "RF_Public | RF_Transactional | RF_WasLoaded | RF_LoadCompleted",
		-- "Properties": {
		  -- "StartTime": 0.13195346
		-- }
	  -- },
		elseif data.Type == "SBShowSoundEventKey" then -- start labeled soundevent 
		elseif data.Type == "SBShowTimeScaleKey" then -- slow down game time. ignore for now. 
			if not data.Properties then continue end
			local bEnable = false 
			if !bEnable then continue end 
			local props = data.Properties
			if props.bEnable == false then continue end

			local blendIn  = props.BlendInTime or 0
			local blendOut = props.BlendOutTime or 0
			local duration = props.Duration or 0
			local targetScale = props.TimeScale or 1
			local startTime = props.StartTime or 0

			local showName = data.Outer or "UnknownShow"
			SBAI_ActiveShow = SBAI_ActiveShow or showName
			self.SBAI_TimeScaleKeys = self.SBAI_TimeScaleKeys or {}

			-- Create key state
			local keyID = "SBShowTimeScaleKey_" .. tostring(CurTime()) .. "_" .. tostring(math.random(1000,9999))
			local keyState = {
				StartTime = startTime,
				BlendInTime = blendIn,
				BlendOutTime = blendOut,
				Duration = duration,
				TargetScale = targetScale,
				StartScale = game.GetTimeScale(),
				Active = true
			}

			self.SBAI_TimeScaleKeys[keyID] = keyState

			-- Compute blend curves and schedule transitions
			local function BlendToTarget(target, blendTime)
				if blendTime <= 0 then
					game.SetTimeScale(target)
					return
				end

				local start = game.GetTimeScale()
				local elapsed = 0

				local function StepBlend()
					if not IsValid(self) then return end
					if not keyState.Active then return end
					if SBAI_ActiveShow ~= showName then
						-- Another show took over; restore instantly
						game.SetTimeScale(1)
						keyState.Active = false
						return
					end

					elapsed = elapsed + 0.01
					local frac = math.Clamp(elapsed / blendTime, 0, 1)
					local newScale = Lerp(frac, start, target)
					game.SetTimeScale(newScale)

					if frac < 1 then
						timer.Simple(0.01, StepBlend)
					else
						-- Finalize
						game.SetTimeScale(target)
					end
				end

				StepBlend()
			end

			-- Start after StartTime offset
			timer.Simple(startTime, function()
				if not IsValid(self) then return end
				if not keyState.Active then return end
				if SBAI_ActiveShow ~= showName then return end

				-- Blend in
				BlendToTarget(targetScale, blendIn)

				-- Stay at target for (duration - blend in - blend out)
				local holdTime = math.max(0, duration - (blendIn + blendOut))
				local totalActiveTime = blendIn + holdTime

				-- Blend out (back to 1x)
				timer.Simple(totalActiveTime, function()
					if not IsValid(self) then return end
					if not keyState.Active then return end
					if SBAI_ActiveShow ~= showName then return end
					BlendToTarget(1, blendOut)
				end)

				-- Full cleanup
				timer.Simple(duration + 0.05, function()
					if self.SBAI_TimeScaleKeys then
						keyState.Active = false
						self.SBAI_TimeScaleKeys[keyID] = nil
					end
				end)
			end)
		elseif data.Type == "SBShowTrailKey" then -- create train on given attachment for given duration, uses Niagara ParticleSystem 
		elseif data.Type == "SBShowUIStudioSequenceKey" then -- testing stuff 
		elseif data.Type == "SBShowVibrationKey" then -- vibration on playstation console 
		elseif data.Type == "SBShowVisibilityKey" then 
		elseif data.Type == "SBShowWindVolumeKey" then 
		
		else -- unhandled Key 
		
		end 
	end 
	
	-- Check scheduled end keys each Think and run their end handlers when elapsed >= EndAt
	if SBAI_ActiveShow.ScheduledEndKeys then
		for k, entry in pairs(SBAI_ActiveShow.ScheduledEndKeys) do
			if not entry or not entry.EndAt or not entry.Data then
				SBAI_ActiveShow.ScheduledEndKeys[k] = nil
				continue
			end
			if SBAI_ActiveShow.EndedKeys[k] then
				-- already ended; cleanup schedule
				SBAI_ActiveShow.ScheduledEndKeys[k] = nil
				continue
			end

			if SBAI_ActiveShow.Elapsed >= entry.EndAt then
				-- trigger end
				SBAI_ActiveShow.EndedKeys[k] = true
				HandleShowKeyEnd(entry.Data)
				SBAI_ActiveShow.ScheduledEndKeys[k] = nil
			end
		end
	end

	-- Auto-stop at end
	if SBAI_ActiveShow.Elapsed >= endTime then
		SBAI_ActiveShow.Stopped = true
		-- Optional: cleanup or callback here 
		-- self:SetNoDraw(false) 
		return
	end
end 

StellarBlade.ProcessActiveSkill = function(self,tbl)
    local Name = tbl.Name
    if !Name then return end
    local SkillStepTable = tbl.Data 
    if !SkillStepTable then return end 
	local Time = tbl.Time -- start time 
	local Duration = SkillStepTable.Duration 
	local EndTime = Time + Duration 
	self.SBAI_ActiveSkill.Cycle = math.Clamp((CurTime() - Time)/Duration,0,1) 
	local Type = SkillStepTable.Type -- get skill step type 
    -- Determine the current target. Prioritize the locked target if it exists and is valid.
    local currentTarget = nil
    if IsValid(tbl.LockedTarget) then
        if tbl.LockedTarget:Alive() then
            currentTarget = tbl.LockedTarget
        else
            -- [NEW] Failsafe: If the locked target is dead, end the skill immediately.
            -- Entity(1):ChatPrint("Locked target died. Ending skill.")
            -- self.SBAI_ActiveSkill = nil 
            -- return
        end
    else
        -- If there's no locked target, use the NPC's current enemy.
        currentTarget = self:IsNPC() and self:GetEnemy() or StellarBlade.PickTarget(self) 
    end 
    -- [NEW] Handle persistent "bLookAtTarget": Keep looking at the target during the step
	local bLookAtTarget = SkillStepTable.bLookAtTarget 
	-- override bLookAtTarget to always look at target when performing a hit 
	-- otherwise, use bLookAtTarget value 
	-- for some reason, bLookAtTarget is mostly false even in SkillActiveStepType_Hit 
	-- something else may be controlling the boolean 
	bLookAtTarget = (Type == "ESBSkillActiveStepType::SkillActiveStepType_Hit" or Type == "ESBSkillActiveStepType::SkillActiveStepType_Parry") and true or bLookAtTarget 
    if bLookAtTarget and IsValid(currentTarget) then
        local angleToTarget = (currentTarget:GetPos() - self:GetPos()):Angle().y
        if self.SetIdealYawAndUpdate then self:SetIdealYawAndUpdate(angleToTarget, -1) 
		else
			self:SetEyeAngles(Angle(self:EyeAngles().x,angleToTarget,self:EyeAngles().z)) 
		end 
    end 
	if Type == "ESBSkillActiveStepType::SkillActiveStepType_Parry" then -- parries incoming attack, used by eve, raven and some other npcs 
	-- to be filled 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Hit" then 
		local bEveryFrameHitCheck = SkillStepTable.bEveryFrameHitCheck 
		StellarBlade.CheckSkillHit(self,SkillStepTable,bEveryFrameHitCheck) 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Hold" then -- unused 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_SuperParry" then -- unused 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Item" then -- eve only: use item 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Guard" then -- eve only: put sword / wings in front to parry 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_None" then -- default action 
	
	end 

	-- Check if the duration for the current step has elapsed

	if CurTime() >= EndTime then
		StellarBlade.RemoveEffectLifeTypes(self,"ESBEffectLifeType::EffectLifeType_StepDependent") 
		-- step finished: advance to next step or clear
		local NextStepAlias = SkillStepTable.NextStepAlias
		if NextStepAlias and NextStepAlias != "None" then
			-- Transition to the next skill step
			StellarBlade.SetSkillStep(self,NextStepAlias) 
			StellarBlade.ProcessActiveSkill(self,self.SBAI_ActiveSkill) 
		else
			-- No next step, so the skill is finished 
			StellarBlade.RemoveEffectLifeTypes(self,"ESBEffectLifeType::EffectLifeType_SkillDependent") 
			self.SBAI_ActiveSkill = nil 
			self.SBAI_SkillTable = nil 
		end

	else
	
	end 
end 

StellarBlade.CheckSkillHit = function(self,SkillStepTable,bEveryFrameHitCheck) 
	local ID = SkillStepTable.ID 
	-- trace attack from weapon / radius / sphere / whatever is AttackDirection and deal damage 
	-- for now, do default damage action 
	if !bEveryFrameHitCheck then 
		if self.SBAI_ActiveSkill.Hit then 
			return true 
		end 
	end 
	local event,etime,cycle,types,options = util.GetAnimEventIDByName("EVENT_WEAPON_MELEE_HIT"), CurTime(), self:GetCycle(), 0, self.PhysicAttackPower or 1100 
	-- adjust melee damage depending on step options 
	options = options * SkillStepTable.SkillAttackDamageRate 
	local enemy = self.GetEnemy and self:GetEnemy() or StellarBlade.PickTarget(self) 
	-- print(enemy) 
	if self.GetEnemy and !IsValid(self:GetEnemy()) then -- pick random enemy 
		if #self:GetKnownEnemies() > 0 then 
			enemy = self:GetKnownEnemies()[1] 
		end 
	end 
	local tableofhittargets = { } 
	if IsValid(enemy) then 
		local curHealth = enemy:Health()
		-- tableofhittargets = self:NPC_MeleeAttack(event,etime,cycle,types,options) 
		-- print("invoking TargetFilter with filtername:",SkillStepTable.OverrideTargetFilterAlias) 
		local TargetFilterAlias = SkillStepTable.OverrideTargetFilterAlias 
		if !TargetFilterAlias or TargetFilterAlias == "None" then 
			if self.SBAI_SkillTable then TargetFilterAlias = self.SBAI_SkillTable.TargetFilterAlias end -- default to SkillTable 
		end 
		
		-- SkillHitDetectionType_None               = 0,
		-- SkillHitDetectionType_TargetFilter       = 1,
		-- SkillHitDetectionType_ActiveCollision    = 2,
		-- SkillHitDetectionType_TargetFilter_ActiveCollision = 3,
		-- SkillHitDetectionType_MAX                = 4,
		
		local HitDetectionType = SkillStepTable.HitDetectionType 
		if string.find(HitDetectionType,"TargetFilter") then 
			tableofhittargets = StellarBlade.TargetFilter(self,TargetFilterAlias,self.SBAI_ActiveSkill.Cycle) 
		end 
		
		if string.find(HitDetectionType,"ActiveCollision") then 
			if table.IsEmpty(tableofhittargets) then tableofhittargets = ents.FindInPVS(self) end 
			-- originally, characters have a SBCollisionGroupComponent 
			-- they lead to character's collision group data asset such as CH_M_NA_53_Raven_Collision 
			-- those assets have names, bones used, pos and ang data such as AttackCollisionGroupArray[1].GroupName = "Collision_Weapon"
			-- print("SkillStepTable.AttackCollisionGroupArray",SkillStepTable.AttackCollisionGroupArray) 
			if string.find(SkillStepTable.AttackCollisionGroupArray,"Collision_WeaponAndHandR") then 
				local M_Raven_UpperArmR = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_R_UpperArm") 
				local M_Raven_ForearmR = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_R_Forearm") 
				local M_Raven_HandR = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_R_Hand") 
				local Collision_Weapon = StellarBlade.CheckWeaponCollision(self,tableofhittargets) 
				local result = { } 
				table.Add(result, M_Raven_UpperArmR) 
				table.Add(result, M_Raven_ForearmR) 
				table.Add(result, M_Raven_HandR) 
				table.Add(result, Collision_Weapon) 
				tableofhittargets = result 
			elseif string.find(SkillStepTable.AttackCollisionGroupArray,"Collision_Weapon") then 
				tableofhittargets = StellarBlade.CheckWeaponCollision(self,tableofhittargets) 
			elseif string.find(SkillStepTable.AttackCollisionGroupArray,"Collision_LegLExtended") then 
				local M_Raven_ThighL = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_L_Thigh") 
				local M_Raven_CalfL = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_L_Calf") 
				local M_Raven_FootL = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_L_Foot") 
				local result = { } 
				table.Add(result, M_Raven_ThighL) 
				table.Add(result, M_Raven_CalfL) 
				table.Add(result, M_Raven_FootL) 
				tableofhittargets = result 
			elseif string.find(SkillStepTable.AttackCollisionGroupArray,"Collision_LegL") then 
				local M_Raven_ThighL = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_L_Thigh") 
				local M_Raven_CalfL = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_L_Calf") 
				local M_Raven_FootL = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_L_Foot") 
				local result = { } 
				table.Add(result, M_Raven_ThighL) 
				table.Add(result, M_Raven_CalfL) 
				table.Add(result, M_Raven_FootL) 
				tableofhittargets = result 
			elseif string.find(SkillStepTable.AttackCollisionGroupArray,"Collision_LegR") then 
				local M_Raven_ThighR = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_R_Thigh") 
				local M_Raven_CalfR = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_R_Calf") 
				local M_Raven_FootR = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_R_Foot") 
				local result = { } 
				table.Add(result, M_Raven_ThighR) 
				table.Add(result, M_Raven_CalfR) 
				table.Add(result, M_Raven_FootR) 
				tableofhittargets = result 
			elseif string.find(SkillStepTable.AttackCollisionGroupArray,"Collision_ArmL") then 
				local M_Raven_UpperArmL = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_L_UpperArm") 
				local M_Raven_ForearmL = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_L_Forearm") 
				local M_Raven_HandL = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_L_Hand") 
				local result = { } 
				table.Add(result, M_Raven_UpperArmL) 
				table.Add(result, M_Raven_ForearmL) 
				table.Add(result, M_Raven_HandL) 
				tableofhittargets = result 
			elseif string.find(SkillStepTable.AttackCollisionGroupArray,"Collision_ArmR") then 
				local M_Raven_UpperArmR = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_R_UpperArm") 
				local M_Raven_ForearmR = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_R_Forearm") 
				local M_Raven_HandR = StellarBlade.CheckHitboxCollision(self,tableofhittargets,"ValveBiped.Bip01_R_Hand") 
				local result = { } 
				table.Add(result, M_Raven_UpperArmR) 
				table.Add(result, M_Raven_ForearmR) 
				table.Add(result, M_Raven_HandR) 
				tableofhittargets = result 
			end 
		end 
		for k,v in pairs(tableofhittargets) do 
			local dmgtype = DMG_SLASH+DMG_ALWAYSGIB 
			if v:IsVehicle() then -- make vehicle driver npcs vulnerable to this slash 
				local driver = v:GetDriver() 
				if IsValid(driver) then 
					if driver:IsNPC() then 
						driver:SetSaveValue("m_takedamage",2) 
					end 
				end 
			elseif v:GetClass() == "npc_combinegunship" or v:GetClass() == "npc_strider" then 
				dmgtype = DMG_BLAST 
			elseif v:GetClass() == "prop_dropship_container" then 
				dmgtype = DMG_AIRBOAT + DMG_BLAST 
			end 
		
			if v != self then 
				local NearestPoint = scripted_ents.Get("cycler_actor2").NearestPoint2(v,self:GetShootPos()) 
				local dmg = DamageInfo() 
				dmg:SetAttacker(self) 
				dmg:SetWeapon(IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon() or self) 
				dmg:SetInflictor(IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon() or self) 
				dmg:SetDamage(options) 
				dmg:SetReportedPosition(self:GetShootPos()) 
				dmg:SetDamageType(dmgtype) 
				dmg:SetDamagePosition(NearestPoint) 
				scripted_ents.Get("npc_sb_raven").NPC_CalculateMeleeDamageForce(self,dmg,self:GetAimVector(),v:GetPos(),1) 
				local tempTable = { -- even though we generate a table of a traceRes, this function uses only hitpos and hitnormal 
				Entity = v, 
				Hit = true, 
				-- HitPos = v:NearestPoint(self:IsWeapon() and self:GetOwner():EyePos() or self:EyePos()),
				HitPos = scripted_ents.Get("cycler_actor2").NearestPoint2(v,self:IsWeapon() and self:GetOwner():EyePos() or self:EyePos()),
				HitNormal = self:GetAimVector(), 
				HitWorld = false, 
				HitMaterial = v:GetMaterial(), 
				
				-- Normal = (self:NearestPoint(v:EyePos()) - v:GetPos()):GetNormalized(), 
				Normal = (scripted_ents.Get("cycler_actor2").NearestPoint2(self,v:EyePos()) - v:GetPos()):GetNormalized(), 
				StartPos = nearestpoint 
				} 
				v:DispatchTraceAttack(dmg,tempTable) 
			end 
		end 
		local newHealth = enemy:Health() -- will have decreased if damage is applied

		--- START: Added Damage Check Logic ---

		local bDamageBlocked = false -- Initialize the variable to false.

		-- Proceed only if the intended enemy was actually in the list of entities hit by the attack.
		if tableofhittargets and table.HasValue(tableofhittargets, enemy) then
			local intendedDamage = options
			local actualDamageDealt = curHealth - newHealth
			local damagePercentage = 0

			-- Avoid division by zero if the skill was not meant to do damage.
			if intendedDamage > 0 then
				damagePercentage = actualDamageDealt / intendedDamage
			end

			-- Check various conditions to see if damage was blocked or prevented.
			-- We set bDamageBlocked to true if ANY of these conditions are met.

			-- Condition 1: The enemy is a player and the GM:PlayerShouldTakeDamage hook returns false.
			local playerHookBlocked = enemy:IsPlayer() and hook.Run("GM:PlayerShouldTakeDamage", enemy, self) == false
			local ai_block_damage = enemy:IsNPC() and cvars.Bool("ai_block_damage") == true 

			-- Condition 2: The enemy has God Mode enabled.
			local isGodMode = enemy:IsFlagSet(FL_GODMODE)

			-- Condition 3: The enemy's internal takedamage variable is set to 0 (DAMAGE_NO) or less.
			-- (or 1) is a safeguard in case the variable is missing, defaulting to a state that takes damage.
			local takeDamageDisabled = (enemy:GetInternalVariable("m_takedamage") or 1) < 1

			-- Condition 4: The actual damage applied was less than 10% of what was intended.
			local lowDamage = damagePercentage < 0.1

			if playerHookBlocked or isGodMode or takeDamageDisabled or lowDamage or ai_block_damage then
				bDamageBlocked = true
			end
		end
	else 
		-- tableofhittargets = scripted_ents.Get("npc_sb_raven").NPC_MeleeAttack(self,event,etime,cycle,types,options) 
	end 
	
	if !tableofhittargets then tableofhittargets = { } end 
    --- END: Added Damage Check Logic --

	for k,v in pairs(tableofhittargets) do 
	
		if IsValid(v) and v != self then 		
			if self.SBAI_ActiveSkill then self.SBAI_ActiveSkill.Hit = true end 
			local Disposition = self.Disposition and self:Disposition(v) or v.Disposition and v:Disposition(self) or D_NU 
			-- Disposition = D_HT -- override temporarily 
			if Disposition == D_HT or Disposition == D_FR then 
			
				-- activate TargetMoveAliasArray on target 
				
				for _, TargetMoveAliasArray in ipairs(SkillStepTable.TargetMoveAliasArray) do 
					StellarBlade.SetMoveTable(v,TargetMoveAliasArray) 
				end 
	
				-- activate TargetShowPath "TargetShowPath": "CH_M_NA_53_Raven/Skill/M_Raven_Slash", 
				-- print("ShowPath is:",SkillStepTable.TargetShowPath) 
				if SkillStepTable.TargetShowPath != "None" then 
					local showpath = "addons/sbraven/data_static/SB/Content/Art/Show/" 
					showpath = showpath..SkillStepTable.TargetShowPath..".json" 
					StellarBlade.SetShow_alt(v,showpath) 
				end 
				
				-- "SkillResultAlias": "M_Raven_ChaseCombo_Hit2",
				-- "SkillResultAliasWhenParry": "M_Raven_ChaseCombo_Parry2",
				-- "SkillResultAliasWhenJustParry": "M_Common_ParryJustEffect",
				-- "SkillResultAliasWhenPerfectParry": "None",
				-- "SkillResultAliasWhenSuperParry": "None",
				-- "SkillResultAliasWhenGuard": "M_Raven_ChaseCombo_Guard2",
				-- "SkillResultAliasWhenBreakGuard": "None",
				-- "SkillResultElementType": "ESBElementType::Element_None",
				-- "SkillResultElementAmount": 0.0, 
				
				local SkillResultAlias = SkillStepTable.SkillResultAlias 
				
				-- prioritize SkillResultAliasWhenParry, JustParry, PerfectParry, SuperParry, Guard, BreakGuard 
				
				if SkillResultAlias != "None" then -- applied on self and target 
					-- StellarBlade.StartSkillResult(self,v,SkillResultAlias) 
					StellarBlade.StartSkillSelfResult(self,SkillResultAlias) 
					StellarBlade.StartSkillTargetResult(v,SkillResultAlias) 
				end 
				
				if SkillStepTable.NextStepAliasWhenParry != "None" then -- player blocked your attack. 
				-- this will be reinterpreted as: trace attack to GetEnemy hit something else 
				end 
				
				if SkillStepTable.NextStepAliasWhenParryJust != "None" then -- interpret as: getenemy is invincible or total damage is lesser than %10 
					if bDamageBlocked then 
						StellarBlade.SetSkillStep(self,SkillStepTable.NextStepAliasWhenParryJust) 
						Entity(1):ChatPrint("Enemy in JustParry, calling "..SkillStepTable.NextStepAliasWhenParryJust) 
					end 
				end 
				
				if SkillStepTable.NextStepAliasWhenPerfectParry != "None" then -- player performed parry right at HitTime 
				-- this will be reinterpreted as: GetEnemy damaged us right at hit event 
				-- implemented in ON_LIGHT_DAMAGE 
				end 
				
				if SkillStepTable.NextStepAliasWhenSuperParry != "None" then -- unused, probably back dodge 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenGuard != "None" then 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenBreakGuard != "None" then 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenCancel != "None" then -- when player wins the interaction 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenPerfectHit != "None" then -- unused 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenHoldRelease != "None" then 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenHoldAndDualSenseTriggerEffectWeaponFired != "None" then 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenAttacked != "None" then -- when the target is hit during skill, implemented in ON_LIGHT_DAMAGE 
					
				end 
				
				if SkillStepTable.NextStepAliasWhenNoTarget != "None" then 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenLinkBreak != "None" then -- same as NextStepAliasWhenCancel 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenInvalidItemConsume != "None" then 
				
				end 
				
				if SkillStepTable.NextStepAliasWhenHit != "None" then 
					local Enemy = self.GetEnemy and self:GetEnemy() or StellarBlade.PickTarget(self) 
					if v == Enemy then 
						StellarBlade.SetSkillStep(self,SkillStepTable.NextStepAliasWhenHit) 
					end 
				end 
			end 
		end 
	end 
end 

StellarBlade.TargetFilter = function(ent, filter, Cycle) 
	local flRescale = 1 
    local TargetFilterTable = _G["SB_TargetFilterTable"][1].Rows[filter] 
	if !IsValid(ent) then error("Expected Entity, got NULL Entity!") return end 
	if !filter then print("input a filter") end 
	if filter == "None" then return {} end 
    if !TargetFilterTable then return {ent:GetEnemy()} end 
	
    local tableEmpty = table.Empty
    local ents_FindInSphere = ents.FindInSphere
    local ents_FindInCone = ents.FindInCone
    local math_max = math.max
    local math_min = math.min
    local math_cos = math.cos
    local math_rad = math.rad
    local util_TraceLine = util.TraceLine

    -- Base vectors
    local origin = ent:GetPos() 
    local forward = ent:GetForward() -- ent:GetForward() is better, but can be GetAimVector as well 
	local right = ent:GetRight() 
	local up = ent:GetUp() 
	
	local ShapeForwardDistance = TargetFilterTable.ShapeForwardDistance * flRescale 
	local ShapeRightDistance = TargetFilterTable.ShapeRightDistance * flRescale 
	local ShapeUpDistance = TargetFilterTable.ShapeUpDistance * flRescale 
	
	local TargetCheckValue1 = TargetFilterTable.TargetCheckValue1 * flRescale 
	local TargetCheckValue2 = TargetFilterTable.TargetCheckValue2 * flRescale 
	local TargetCheckValue3 = TargetFilterTable.TargetCheckValue3 * flRescale 
	
	local bDynamicShapeScale = TargetFilterTable.bDynamicShapeScale 
	local MinShapeScale, MaxShapeScale = TargetFilterTable.MinShapeScale, TargetFilterTable.MaxShapeScale 
	
	if tobool(bDynamicShapeScale) then 
		-- use Min, MaxShapeScale to multiply FarDistance, NearDistance based on Cycle (0-1) 
	
	end 
	
	local FarDistance = TargetFilterTable.FarDistance * flRescale 
	local NearDistance = TargetFilterTable.NearDistance * flRescale 

    -- Shape offsets
	local offsetOrigin = origin + forward * ShapeForwardDistance + right * ShapeRightDistance + up * ShapeUpDistance

    local candidates = {}
	local function cheapReject(t)
        if !IsValid(t) then return true end
        if t == ent then return true end
        if !t:IsSolid() then return true end
        if t:GetCollisionGroup() == COLLISION_GROUP_NONE then return true end
        if t:IsFlagSet(FL_DONTTOUCH) then return true end
        return false
    end
    -- Step 1: Candidate pool
    local shape = TargetFilterTable.TargetCheckShape or ""
	if shape == "ESBCheckShape::CheckShape_2DArc" then
        local far = FarDistance or 0
        local near = NearDistance or 0
        local angleWidth = TargetCheckValue1 or 0        -- total degrees
        local angleOffset = TargetCheckValue2 or 0       -- rotation offset in degrees
        local centerRadius = TargetCheckValue3 or 0      -- optional fixed radius (0 = unused)
        local tol = math.max(16, (far - near) * 0.25)    -- tolerance for fixed-radius checks (tweakable)

        -- helper: rotate forward vector by yaw degrees (returns normalized vec)
        local function RotateForwardYawVec(fwd, yawDeg)
            local ang = fwd:Angle()
            ang.y = ang.y + yawDeg
            local v = ang:Forward()
            v.z = 0
            return v:GetNormalized()
        end

        -- build candidate list then filter
        candidates = ents_FindInSphere(offsetOrigin, far) -- cheap broad-phase first
        local kept = {}
        for _, cand in ipairs(candidates) do
            if cheapReject(cand) then goto cont end

            -- 2D distance
            -- local to = cand:NearestPoint(offsetOrigin) -- or cand:GetPos(); NearestPoint is safer for big objects
            local to = scripted_ents.Get("cycler_actor2").NearestPoint2(cand,offsetOrigin)  -- or cand:GetPos(); NearestPoint is safer for big objects
            local dir = to - offsetOrigin
            local dist2d = Vector(dir.x, dir.y, 0):Length()

            if dist2d < near or dist2d > far then goto cont end

            -- fixed-center behavior (optional)
            if centerRadius > 0 then
                if math.abs(dist2d - centerRadius) > tol then goto cont end
            end

            -- if full circle, keep
            if angleWidth >= 360 then
                table.insert(kept, cand)
                goto cont
            end

            -- angular check: rotate forward by offset, compare with target dir
            local centerDir = RotateForwardYawVec(forward, angleOffset)
            local targetDir = Vector(dir.x, dir.y, 0)
            if targetDir:Length() == 0 then goto cont end
            targetDir:Normalize()

            local dot = math_max(-1, math_min(1, centerDir:Dot(targetDir)))
            local angBetween = math.deg(math.acos(dot))

            if angBetween <= (angleWidth * 0.5) then
                table.insert(kept, cand)
            end

            ::cont::
        end

        -- replace candidates with filtered list
        candidates = kept

        -- --- Visualization 
		local lifetime = 0.8
		local segs = 36
		local center = offsetOrigin
		local fw2 = forward
		fw2.z = 0
		fw2:Normalize()
		-- arc parameters
		local half = angleWidth * 0.5
		local startAng = -half + angleOffset
		local endAng = half + angleOffset

		-- rings / sector depending on centerRadius
		if centerRadius > 0 then
			-- draw ring at centerRadius (small thickness)
			local innerR = math.max(0, centerRadius - 4)
			local outerR = centerRadius + 4
			for r = innerR, outerR, (outerR - innerR) do
				local lastP = nil
				for i = 0, segs do
					local t = i / segs
					local a = math.rad( startAng + (endAng - startAng) * t )
					local p = center + Vector(math.cos(a), math.sin(a), 0) * r
					if lastP then debugoverlay.Line(lastP, p, lifetime, Color(200,200,50,255)) end
					lastP = p
				end
			end
			debugoverlay.Text(center + fw2 * centerRadius, string.format("2DArc R=%.0f W=%.1f O=%.1f", centerRadius, angleWidth, angleOffset), lifetime)
		else
			-- draw sector between near and far as ring-ish sector
			local segCount = segs
			local lastOuter = nil
			local lastInner = nil
			for i = 0, segCount do
				local t = i / segCount
				local a = math.rad( startAng + (endAng - startAng) * t )
				local dirv = Vector(math.cos(a), math.sin(a), 0)
				local outerP = center + dirv * far
				local innerP = center + dirv * near
				if lastOuter then debugoverlay.Line(lastOuter, outerP, lifetime, Color(180,180,255,255)) end
				if lastInner then debugoverlay.Line(lastInner, innerP, lifetime, Color(180,180,255,255)) end
				debugoverlay.Line(innerP, outerP, lifetime, Color(120,220,120,255)) -- radial connector
				lastOuter = outerP
				lastInner = innerP
			end
			debugoverlay.Text(center + fw2 * ((near + far) * 0.5), string.format("2DArc N=%.0f F=%.0f W=%.1f O=%.1f", near, far, angleWidth, angleOffset), lifetime)
		end

		-- draw forward axis to see orientation
		debugoverlay.Axis(center, forward:Angle(), 12, lifetime)
		
        -- done for this shape; candidates now contains arc-matching ents
	elseif shape == "ESBCheckShape::CheckShape_3DArc" then
        local far = FarDistance or 0
        local near = NearDistance or 0
        local rawAngle = TargetFilterTable.TargetCheckValue1 or 0    -- can be negative to indicate flip
        local yawOffset = TargetFilterTable.TargetCheckValue2 or 0
        local centerRadius = TargetFilterTable.TargetCheckValue3 or 0

        -- Interpret angle: sign = flip axis (point backwards), magnitude = cone aperture (0..360)
        local flip = (rawAngle < 0)
        local coneAngle = math.min(360, math.abs(rawAngle or 0))
        -- tolerance for ring matching when centerRadius > 0; tweak if you want thinner/thicker band
        local ringTol = math.max(8, (far - near) * 0.25)

        -- Broad-phase collect (cheap)
        local rawCandidates = ents_FindInSphere(offsetOrigin, far)
        local kept = {}

        -- helper: make rotated axis direction (apply yaw offset and flip)
        local function MakeAxisDir(baseForward, yawDeg, doFlip)
            local a = baseForward:Angle()
            a.y = a.y + yawDeg
            if doFlip then a.y = a.y + 180 end
            local v = a:Forward()
            return v:GetNormalized()
        end

        local axisDir = MakeAxisDir(forward, yawOffset, flip)

        for _, cand in ipairs(rawCandidates) do
            if cheapReject(cand) then goto cont3 end

            -- use nearest point for better accuracy with big entities
			local p = scripted_ents.Get("cycler_actor2").NearestPoint2(cand,offsetOrigin)  -- or cand:GetPos(); NearestPoint is safer for big objects
            local dir3 = p - offsetOrigin
            local dist = dir3:Length()
            if dist < near or dist > far then print("distance rejected:",cand) goto cont3 end

            -- center-radius enforcement only if centerRadius is within [near, far]
            local enforceRing = false
            if centerRadius > 0 and centerRadius >= near and centerRadius <= far then
                enforceRing = true
            end

            if enforceRing then
                if math.abs(dist - centerRadius) > ringTol then
                    -- rejected by ring
                    -- print("rejected:", cand, ", math.abs(dist - centerRadius) > ringTol. dist:", dist, "centerRadius:", centerRadius, "ringTol:", ringTol)
                    goto cont3
                end
            end


            -- full-sphere shortcut
            if coneAngle >= 360 then
                table.insert(kept, cand)
                goto cont3
            end

            -- angular check in 3D
            if dir3:Length() == 0 then goto cont3 end
            local dirNorm = dir3 / dir3:Length()
            local dot = axisDir:Dot(dirNorm)
            dot = math_max(-1, math_min(1, dot))
            local angleBetween = math.deg(math.acos(dot))

            if angleBetween <= (coneAngle * 0.5) then
                table.insert(kept, cand)
            else 
				-- print("rejected ",cand,"angleBetween <= (coneAngle * 0.5). angleBetween:",angleBetween,"coneAngle:",coneAngle) 
			end 

            ::cont3::
        end
		-- print("candidates = kept:",#kept) 
		-- PrintTable(candidates) 
        candidates = kept

        -- Visualization (server-side debugoverlay)
        if SERVER and debugging then
            local lifetime = 0.8
            local segs = 36
            local halfRad = math.rad(coneAngle * 0.5)

            -- axis angle (for axis visual)
            local axisAng = forward:Angle()
            axisAng.y = axisAng.y + yawOffset
            if flip then axisAng.y = axisAng.y + 180 end

            -- draw axis that represents the cone's center direction
            debugoverlay.Axis(offsetOrigin, axisAng, 16, lifetime)

            -- draw near/far spherical bounds (wire-ish via circles)
            local function DrawCircleAtDistance(dist, col)
                if dist <= 0 then return end
                local center = offsetOrigin + axisDir * dist
                -- radius of circle (perpendicular to axis)
                local radius = dist * math.tan(halfRad)
                -- fallback for very narrow cones
                if radius <= 0.001 then
                    debugoverlay.Line(offsetOrigin, center, lifetime, col)
                    return
                end

                local baseAng = axisDir:Angle()
                local rightV = baseAng:Right()
                local upV = baseAng:Up()
                local lastP = nil
                for i = 0, segs do
                    local t = i / segs
                    local a = t * math.pi * 2
                    local p = center + rightV * math.cos(a) * radius + upV * math.sin(a) * radius
                    if lastP then debugoverlay.Line(lastP, p, lifetime, col) end
                    lastP = p
                end
            end

            -- draw far and near rings (if near > 0 show inner ring)
            DrawCircleAtDistance(far, Color(200,200,50,255))
            if near > 0 then
                DrawCircleAtDistance(near, Color(160,160,255,255))
            end

            -- if centerRadius specified, draw a highlighted ring at that distance
            if centerRadius > 0 then
                local ringActive = (centerRadius >= near and centerRadius <= far)
                local center = offsetOrigin + axisDir * centerRadius
                local radiusCenter = centerRadius * math.tan(halfRad)

                if ringActive then
                    -- active (enforced) ring color
                    local colActive = Color(255,180,50,255)
                    if radiusCenter > 0.001 then
                        local baseAng = axisDir:Angle()
                        local rightV = baseAng:Right()
                        local upV = baseAng:Up()
                        local lastP = nil
                        for i = 0, segs do
                            local t = i / segs
                            local a = t * math.pi * 2
                            local p = center + rightV * math.cos(a) * radiusCenter + upV * math.sin(a) * radiusCenter
                            if lastP then debugoverlay.Line(lastP, p, lifetime, colActive) end
                            lastP = p
                        end
                    else
                        debugoverlay.Sphere(center, 6, lifetime, Color(255,180,50,255))
                    end
                    debugoverlay.Text(offsetOrigin + axisDir * math_min(far, math.max(16, centerRadius)), string.format("3DArc R=%.0f W=%.1f O=%.1f (ring ACTIVE)", centerRadius, coneAngle, yawOffset), lifetime)
                else
                    -- ignored ring color (dim/grey) — shows why ring wasn't enforced
                    local colIgnored = Color(120,120,120,120)
                    if radiusCenter > 0.001 then
                        local baseAng = axisDir:Angle()
                        local rightV = baseAng:Right()
                        local upV = baseAng:Up()
                        local lastP = nil
                        for i = 0, segs do
                            local t = i / segs
                            local a = t * math.pi * 2
                            local p = center + rightV * math.cos(a) * radiusCenter + upV * math.sin(a) * radiusCenter
                            if lastP then debugoverlay.Line(lastP, p, lifetime, colIgnored) end
                            lastP = p
                        end
                    else
                        debugoverlay.Sphere(center, 6, lifetime, colIgnored)
                    end
                    debugoverlay.Text(offsetOrigin + axisDir * (far * 0.5), string.format("3DArc N=%.0f F=%.0f W=%.1f O=%.1f (ring IGNORED)", near, far, coneAngle, yawOffset), lifetime)
                end
            else
                debugoverlay.Text(offsetOrigin + axisDir * (far * 0.5), string.format("3DArc N=%.0f F=%.0f W=%.1f O=%.1f", near, far, coneAngle, yawOffset), lifetime)
            end

            -- rim points / radial lines
            if coneAngle > 0 and coneAngle < 360 then
                local rimCenter = offsetOrigin + axisDir * far
                local rimRadius = far * math.tan(halfRad)
                if rimRadius > 0.001 then
                    local baseAng = axisDir:Angle()
                    local rightV = baseAng:Right()
                    local upV = baseAng:Up()
                    for i = 0, segs - 1 do
                        local a1 = (i / segs) * math.pi * 2
                        local a2 = ((i + 1) / segs) * math.pi * 2
                        local p1 = rimCenter + rightV * math.cos(a1) * rimRadius + upV * math.sin(a1) * rimRadius
                        local p2 = rimCenter + rightV * math.cos(a2) * rimRadius + upV * math.sin(a2) * rimRadius
                        debugoverlay.Line(p1, p2, lifetime, Color(200,200,50,255))
                        if (i % 4) == 0 then debugoverlay.Line(offsetOrigin, p1, lifetime, Color(120,220,120,255)) end
                    end
                else
                    debugoverlay.Line(offsetOrigin, offsetOrigin + axisDir * far, lifetime, Color(255,100,100,255))
                end
            else
                debugoverlay.Sphere(offsetOrigin, math_min(12, far * 0.05), lifetime, Color(180,180,255,255))
            end
        else
            debugoverlay.Cross(offsetOrigin, 8, 1, Color(255,0,0,255))
        end

    elseif shape == "ESBCheckShape::CheckShape_3DCircle" then
        local radius = FarDistance or (TargetCheckValue1 or 0)
        candidates = ents.FindInSphere(offsetOrigin, radius) 
		-- debugoverlay.Sphere(offsetOrigin, radius, 0.5,Color(100,100,100,100)) 
	elseif shape == "ESBCheckShape::CheckShape_3DBox" then
		local val1 = TargetCheckValue1 or 0 -- half-size X (right)
		local val2 = TargetCheckValue2 or 0 -- half-size Y (forward)
		local val3 = TargetCheckValue3 or 0 -- half-size Z (up)

		-- Define the oriented box in world space
		local start = origin
		local endpos = origin + forward * (ShapeForwardDistance or 0)

		-- Define local AABB extents in actor’s local basis
		local localMins = Vector(-val1, -val2, -val3)
		local localMaxs = Vector(val1, val2, val3)

		-- Find entities within that oriented box
		candidates = ents.FindAlongRay(start, endpos, localMins, localMaxs) 
	else -- default action 
        candidates = ents.FindInPVS(ent) 
    end 

    -- Step 2: Filter out self
	-- expang this depending on Target type 
	--[[ 
	Target_None                              = 0,
	Target_Self                              = 1,
	Target_SpecifiedTargetes                 = 2, -- unused 
	Target_Ally                              = 3, -- kamikaze NPCs 
	Target_AllyWithSelf                      = 4, -- only used by heal grenade 
	Target_Enemy                             = 5,
	Target_All                               = 6,
	Target_AllWithoutSelf                    = 7,
	Target_Owner                             = 8,
	Target_LockOn                            = 9,
	Target_AIDetectTarget                    = 10,
	Target_AIDetectSubTarget                 = 11,
	Target_MAX                               = 12,
	--]] 
	local TargetType = TargetFilterTable.TargetType 
    local filtered = {}
	
	if TargetType == "ESBTargetActor::Target_Self" then 
		filtered[1] = ent 
	elseif TargetType == "ESBTargetActor::Target_Enemy" then 
		local enemy = ent.GetEnemy and ent:GetEnemy() 
		if !IsValid(enemy) then 
			for _,target in ipairs(candidates) do 
				if target.GetEnemy and IsValid(target:GetEnemy()) and target:GetEnemy() == ent then 
					table.insert(filtered,target) 
				end 
			end 
		else 
			table.insert(filtered,enemy) 
		end 
		-- table.insert(filtered,ent.GetEnemy and ent:GetEnemy() or ent.PickTarget) 
	elseif TargetType == "ESBTargetActor::Target_Owner" then 
		filtered[1] = IsValid(ent:GetOwner()) and ent:GetOwner() 
	elseif TargetType == "ESBTargetActor::Target_All" then 
		for _, target in ipairs(candidates) do
			if IsValid(target) 
				and target:IsSolid()
				and target:GetCollisionGroup() != COLLISION_GROUP_NONE
				and !target:IsFlagSet(FL_DONTTOUCH)
				and target:Alive() 
			then
				table.insert(filtered, target)
			end
		end 
	elseif TargetType == "ESBTargetActor::Target_Ally" then 
		for _, target in ipairs(candidates) do 
			local Disposition = ent.Disposition and (ent:Disposition(target) == D_LI) or target.Disposition and target:Disposition(ent) == D_LI 
			if Disposition then 
				table.insert(filtered, target) 
			end 
		end 
	elseif TargetType == "ESBTargetActor::Target_AllyWithSelf" then 
		for _, target in ipairs(candidates) do 
			local Disposition = ent.Disposition and (ent:Disposition(target) == D_LI) or target.Disposition and target:Disposition(ent) == D_LI 
			if Disposition then 
				table.insert(filtered, target) 
			end 
		end 
		table.insert(filtered,ent) 
	else -- default action 
		for _, target in ipairs(candidates) do
			if IsValid(target)
				and target != ent
				and target:IsSolid()
				and target:GetCollisionGroup() != COLLISION_GROUP_NONE
				and !target:IsFlagSet(FL_DONTTOUCH)
				and target:Alive() 
			then
				-- print("candidates at step 2:",target) 
				table.insert(filtered, target)
			end
		end 
	end 

    -- Step 3: Distance check
    local nearDist = NearDistance or 0
    local farDist  = FarDistance or math.huge 
    local distFiltered = {}
    for _, target in ipairs(filtered) do
        local distSqr = offsetOrigin:DistToSqr(target:GetPos())
        if distSqr >= nearDist * nearDist and distSqr <= farDist * farDist then
            table.insert(distFiltered, target)
        end
    end
	-- print("past dist check") 

    -- Step 4: Shape checks (2D circle / 3D cylinder)
    local val1  = TargetCheckValue1 or 0
    local val2  = TargetCheckValue2 or 0
    local tmp = {}
	
	print("shape check is:",shape) 
	if shape == "ESBCheckShape::CheckShape_2DCircle" then
		local radius = FarDistance
		if radius == 0 or not radius then
			radius = TargetCheckValue1 or 0
		end
		print("circle radius:",radius) 
		local radiusSqr = radius * radius
		local tmp = {}

		for _, target in ipairs(distFiltered) do
			local tpos = target:GetPos()
			local d2d = Vector(tpos.x, tpos.y, offsetOrigin.z):DistToSqr(offsetOrigin)
			if d2d <= radiusSqr then
				table.insert(tmp, target)
			end
		end
		distFiltered = tmp

    elseif shape == "ESBCheckShape::CheckShape_3DCylinder" then		
		local radius = FarDistance 
		local height = TargetCheckValue1 
		for _, target in ipairs(distFiltered) do 
			local targetHeight = math.abs(target:GetPos().z - offsetOrigin.z) 
			if targetHeight <= height then 
				if offsetOrigin:Distance2D(target:GetPos()) < radius then 
					table.insert(tmp, target) 
				end 
			end 
		end 
		distFiltered = tmp 
    end
	-- print("past custom filters:") 

    -- Step 4b: Line of sight check
    if !TargetFilterTable.bDisableBlockingCheck then
        local losFiltered = {}
        for _, candidate in ipairs(distFiltered) do
            local targetPos = TargetFilterTable.bBlockingCheckWithTopLocation
                and candidate:EyePos()
                or candidate:WorldSpaceCenter()

            local tr = util.TraceLine({
                start = ent:GetShootPos(),
                endpos = targetPos,
                filter = ent,
                collisiongroup = COLLISION_GROUP_PROJECTILE,
                mask = MASK_SHOT
            })
            if tr.Entity == candidate or tr.Fraction >= 1 then
                table.insert(losFiltered, candidate)
            elseif IsValid(tr.Entity) and (IsValid(candidate:GetParent()) and candidate:GetParent() == tr.Entity or candidate.GetVehicle and IsValid(candidate:GetVehicle()) and candidate:GetVehicle() == tr.Entity) then 
				table.insert(losFiltered,tr.Entity) 
			end 
        end 
        distFiltered = losFiltered 
    end 

    -- Step 5: Sorting
    local sortType = TargetFilterTable.SortType
    if sortType == "ESBActorSortType::ActorSortType_Near" then
        table.sort(distFiltered, function(a,b) return offsetOrigin:DistToSqr(a:GetPos()) < offsetOrigin:DistToSqr(b:GetPos()) end)
    elseif sortType == "ESBActorSortType::ActorSortType_Far" then
        table.sort(distFiltered, function(a,b) return offsetOrigin:DistToSqr(a:GetPos()) > offsetOrigin:DistToSqr(b:GetPos()) end)
    elseif sortType == "ESBActorSortType::ActorSortType_LowHp" then
        table.sort(distFiltered, function(a,b) return (a.Health and a:Health() or 0) < (b.Health and b:Health() or 0) end)
    elseif sortType == "ESBActorSortType::ActorSortType_HighHp" then
        table.sort(distFiltered, function(a,b) return (a.Health and a:Health() or 0) > (b.Health and b:Health() or 0) end)
    end
	
	-- print("multiple targets:",TargetFilterTable.bMultipleTargets) 
    -- Step 6: Multiple vs single target
    if TargetFilterTable.bMultipleTargets then
        return distFiltered
    elseif #distFiltered > 0 then
        return { distFiltered[1] }
    end

    return {}
end 

--[[
    Checks weapon collision for a given entity.
    Uses the active weapon’s collision bounds and the owner's right-hand bone
    to cast a rotated FindAlongRay.
    Only entities within the provided entityList are kept.
]]-- 

StellarBlade.CheckWeaponCollision = function(self, entityList)
    local wep = self:GetActiveWeapon() 
	if !IsValid(wep) then wep = self end 
    -- 1. Get the Collision Bounds of the weapon (Local Space)
    local mins, maxs = wep:GetCollisionBounds()

    -- 2. Get the Hand Bone Matrix (Simulating the visual bonemerge on the server)
    local boneIndex = self:LookupBone("ValveBiped.Bip01_R_Hand")
    if !boneIndex then return {} end

    local matrix = self:GetBoneMatrix(boneIndex)
    local bonePos = matrix:GetTranslation()
    local boneAng = matrix:GetAngles()
	boneAng:RotateAroundAxis(Vector(0,0,0),90) 
	mins.z = mins.z * 2 
	maxs.z = maxs.z * 2 

    -- 3. Calculate the "Fat" Axis-Aligned Bounding Box (AABB)
    -- We must rotate all 8 corners of the local bounds to find the true World Min/Max
    -- because standard collision checks (FindInBox) do not support rotation.
    local corners = {
        Vector(mins.x, mins.y, mins.z),
        Vector(mins.x, mins.y, maxs.z),
        Vector(mins.x, maxs.y, mins.z),
        Vector(mins.x, maxs.y, maxs.z),
        Vector(maxs.x, mins.y, mins.z),
        Vector(maxs.x, mins.y, maxs.z),
        Vector(maxs.x, maxs.y, mins.z),
        Vector(maxs.x, maxs.y, maxs.z),
    }

    local worldMins = Vector(math.huge, math.huge, math.huge)
    local worldMaxs = Vector(-math.huge, -math.huge, -math.huge)

    for _, corner in ipairs(corners) do
        -- Transform the local corner into world space relative to the hand
        local worldPt = LocalToWorld(corner, angle_zero, bonePos, boneAng)

        -- Expand the world bounds to fit this point
        if worldPt.x < worldMins.x then worldMins.x = worldPt.x end
        if worldPt.y < worldMins.y then worldMins.y = worldPt.y end
        if worldPt.z < worldMins.z then worldMins.z = worldPt.z end

        if worldPt.x > worldMaxs.x then worldMaxs.x = worldPt.x end
        if worldPt.y > worldMaxs.y then worldMaxs.y = worldPt.y end
        if worldPt.z > worldMaxs.z then worldMaxs.z = worldPt.z end
    end

    -- 4. Find all entities within the calculated "Fat" AABB
    local hitEnts = ents.FindInBox(worldMins, worldMaxs)

    -- 5. Filter: Keep only entities that were in the original entityList
    local filtered = {}
    local hitAnything = false

    for _, ent in ipairs(hitEnts) do
        if IsValid(ent) and table.HasValue(entityList, ent) then
            table.insert(filtered, ent)
            hitAnything = true
        end
    end

    -- 6. Visualization
    -- RED Rotated Box: Represents the precise visual weapon alignment (OBB)
    -- debugoverlay.BoxAngles(bonePos, mins, maxs, boneAng, 0.1, Color(255, 0, 0, 10))
    
    -- BLUE Wireframe Box: Represents the actual detection area (AABB)
    -- Use SweptBox with 0 distance to draw a clean wireframe
    local debugColor = hitAnything and Color(0, 255, 0, 50) or Color(0, 255, 255, 5)
    -- debugoverlay.SweptBox(vector_origin, vector_origin, worldMins, worldMaxs, angle_zero, 0.1, debugColor)

    return filtered
end

--[[ 
    Checks whether a given entity’s specified hitbox collides with any entities in entityList.
    @param owner      (Entity) The entity whose hitbox will be checked.
    @param entityList (table)  List of entities to test against.
    @param hitboxID   (number|string) Hitbox index or bone name.
    @param hitboxSet  (number) Optional: hitbox set index (default = 0).
    @return table     List of entities intersecting this hitbox.
]]-- 
StellarBlade.CheckHitboxCollision = function(owner, entityList, hitboxID, hitboxSet) 
    if !IsValid(owner) or !istable(entityList) then return {} end 
    hitboxSet = hitboxSet or 0 

    -- 1. Convert bone name -> hitbox ID if string was given
    if isstring(hitboxID) then
        local numHitBoxes = owner:GetHitBoxCount(hitboxSet)
        for i = 0, numHitBoxes - 1 do
            local boneIndex = owner:GetHitBoxBone(i, hitboxSet)
            local boneName = owner:GetBoneName(boneIndex)
            if boneName == hitboxID then
                hitboxID = i
                break
            end
        end
    end

    if !isnumber(hitboxID) then return {} end

    -- 2. Fetch hitbox bounds (Local to the bone)
    local mins, maxs = owner:GetHitBoxBounds(hitboxID, hitboxSet)
    if !mins or !maxs then return {} end

    -- 3. Fetch hitbox orientation via Bone Matrix
    local boneIndex = owner:GetHitBoxBone(hitboxID, hitboxSet)
    if !boneIndex then return {} end

    -- Use GetBoneMatrix to ensure we match the logic of CheckWeaponCollision
    local matrix = owner:GetBoneMatrix(boneIndex)
    if not matrix then return {} end
    
    local bonePos = matrix:GetTranslation()
    local boneAng = matrix:GetAngles()

    -- 4. Calculate the "Fat" Axis-Aligned Bounding Box (AABB)
    -- Just like the weapon check, we rotate the 8 corners of the hitbox 
    -- into world space to find the absolute min/max bounds.
    local corners = {
        Vector(mins.x, mins.y, mins.z),
        Vector(mins.x, mins.y, maxs.z),
        Vector(mins.x, maxs.y, mins.z),
        Vector(mins.x, maxs.y, maxs.z),
        Vector(maxs.x, mins.y, mins.z),
        Vector(maxs.x, mins.y, maxs.z),
        Vector(maxs.x, maxs.y, mins.z),
        Vector(maxs.x, maxs.y, maxs.z),
    }

    local worldMins = Vector(math.huge, math.huge, math.huge)
    local worldMaxs = Vector(-math.huge, -math.huge, -math.huge)

    for _, corner in ipairs(corners) do
        -- Transform the local corner into world space relative to the bone
        local worldPt = LocalToWorld(corner, angle_zero, bonePos, boneAng)

        -- Expand the world bounds to fit this point
        if worldPt.x < worldMins.x then worldMins.x = worldPt.x end
        if worldPt.y < worldMins.y then worldMins.y = worldPt.y end
        if worldPt.z < worldMins.z then worldMins.z = worldPt.z end

        if worldPt.x > worldMaxs.x then worldMaxs.x = worldPt.x end
        if worldPt.y > worldMaxs.y then worldMaxs.y = worldPt.y end
        if worldPt.z > worldMaxs.z then worldMaxs.z = worldPt.z end
    end

    -- 5. Find all entities within the calculated "Fat" AABB
    local hitEnts = ents.FindInBox(worldMins, worldMaxs)

    -- 6. Filter: Keep only entities that were in the original entityList
    local filtered = {}
    local hitAnything = false

    for _, ent in ipairs(hitEnts) do
        -- Ensure we don't hit ourselves
        if IsValid(ent) and ent ~= owner and table.HasValue(entityList, ent) then
            table.insert(filtered, ent)
            hitAnything = true
        end
    end

    -- 7. Visualization (Identical style to Weapon Collision)
    -- RED Rotated Box: Represents the actual hitbox orientation (OBB)
    -- debugoverlay.BoxAngles(bonePos, mins, maxs, boneAng, 0.1, Color(255, 0, 0, 10))
    
    -- BLUE Wireframe Box: Represents the actual detection area (AABB)
    local debugColor = hitAnything and Color(0, 255, 0, 50) or Color(0, 255, 255, 5)
    -- debugoverlay.SweptBox(vector_origin, vector_origin, worldMins, worldMaxs, angle_zero, 0.1, debugColor)

    -- print("Hitbox collision count:", #filtered)
    return filtered
end 

StellarBlade.StartSkillSelfResult = function(self,SkillResultAlias,HitLevel) 
	HitLevel = false 
	local SkillResult = SB_SkillResultTable[1].Rows[SkillResultAlias] 
	-- priority: critical, weakpoint, groggy, down, swimming, airborne, air, moving, common 

	local ResultSelfCriticalEffect = SkillResult.ResultSelfCriticalEffect 
	local ResultSelfCriticalShowPath = SkillResult.ResultSelfCriticalShowPath 
	
	local ResultSelfGroggyEffect = SkillResult.ResultSelfGroggyEffect 
	local ResultSelfGroggyShowPath = SkillResult.ResultSelfGroggyShowPath 
	
	local ResultSelfDownEffect = SkillResult.ResultSelfDownEffect 
	local ResultSelfDownShowPath = SkillResult.ResultSelfDownShowPath 
	
	local ResultSelfSwimmingEffect = SkillResult.ResultSelfSwimmingEffect 
	local ResultSelfSwimmingShowPath = SkillResult.ResultSelfSwimmingShowPath 
	
	local ResultSelfAirborneEffect = SkillResult.ResultSelfAirborneEffect 
	local ResultSelfAirborneShowPath = SkillResult.ResultSelfAirborneShowPath 
	
	local ResultSelfAirEffect = SkillResult.ResultSelfAirEffect 
	local ResultSelfAirShowPath = SkillResult.ResultSelfAirShowPath 
	
	local ResultSelfEventMovingEffect = SkillResult.ResultSelfEventMovingEffect 
	local ResultSelfEventMovingShowPath = SkillResult.ResultSelfEventMovingShowPath 
	
	local ResultSelfCommonEffect = SkillResult.ResultSelfCommonEffect 
	local ResultSelfCommonShowPath = SkillResult.ResultSelfCommonShowPath 
	
	local bCritical = false 
	if bCritical then 
		if ResultSelfCriticalEffect != "" then 
			local table_ResultSelfCriticalEffect = StellarBlade.ParseTableStrings(ResultSelfCriticalEffect) 
			StellarBlade.AddEffectFromTable(self,table_ResultSelfCriticalEffect) 
		end 
		StellarBlade.SetShow_alt(self,ResultSelfCriticalShowPath) 
		return true 
	end 
	
	local bWeakpoint = false 
	
	if bWeakpoint then 
		if ResultSelfCriticalEffect != "" then 
			local table_ResultSelfCriticalEffect = StellarBlade.ParseTableStrings(ResultSelfCriticalEffect) 
			StellarBlade.AddEffectFromTable(self,table_ResultSelfCriticalEffect) 
		end 
		return true 
	end 
	
	local bGroggy = false 
	
	if bGroggy then 
		if HitLevel then 
			if ResultSelfGroggyEffect != "" then 
				local table_ResultSelfGroggyEffect = StellarBlade.ParseTableStrings(ResultSelfGroggyEffect) 
				StellarBlade.AddEffectFromTable(self,table_ResultSelfGroggyEffect) 
			end 
			StellarBlade.SetShow_alt(self,ResultSelfGroggyShowPath)  
			return true 
		end 
		if ResultSelfGroggyEffect != "" then 
			local table_ResultSelfGroggyEffect = StellarBlade.ParseTableStrings(ResultSelfGroggyEffect) 
			StellarBlade.AddEffectFromTable(self,table_ResultSelfGroggyEffect) 
		end 
		StellarBlade.SetShow_alt(self,ResultSelfGroggyShowPath) 
		return true 
	end 
	
	local bDown = false 
	
	if bDown then 
		if HitLevel then 
			if ResultSelfDownEffect != "" then 
				local table_ResultSelfDownEffect = StellarBlade.ParseTableStrings(ResultSelfDownEffect) 
				StellarBlade.AddEffectFromTable(self,table_ResultSelfDownEffect) 
			end 
			StellarBlade.SetShow_alt(self,ResultSelfDownShowPath) 
			return true 
		end 
		if ResultSelfDownEffect != "" then 
			local table_ResultSelfDownEffect = StellarBlade.ParseTableStrings(ResultSelfDownEffect) 
			StellarBlade.AddEffectFromTable(self,table_ResultSelfDownEffect) 
		end 
		StellarBlade.SetShow_alt(self,ResultSelfDownShowPath) 
		return true 
	end 
	
	local bSwimming = self:WaterLevel() > 0 
	
	if bSwimming then 
		if HitLevel then 
			if ResultSelfSwimmingEffect != "" then 
				local table_ResultSelfSwimmingEffect = StellarBlade.ParseTableStrings(ResultSelfSwimmingEffect) 
				StellarBlade.AddEffectFromTable(self,table_ResultSelfSwimmingEffect) 
			end 
			StellarBlade.SetShow_alt(self,ResultSelfSwimmingShowPath) 
			return true 
		end 
		if ResultSelfSwimmingEffect != "" then 
			local table_ResultSelfSwimmingEffect = StellarBlade.ParseTableStrings(ResultSelfSwimmingEffect) 
			StellarBlade.AddEffectFromTable(self,table_ResultSelfSwimmingEffect) 
		end 
		StellarBlade.SetShow_alt(self,ResultSelfSwimmingShowPath) 
		return true 
	end 
	
	local bAirborne = self:GetMoveType() == MOVETYPE_FLY or self.GetNavType and self:GetNavType() == NAV_FLY or self:IsFlagSet(FL_FLY) 
	if bAirborne then 
		if HitLevel then 
			if ResultSelfAirborneEffect != "" then 
				local table_ResultSelfAirborneEffect = StellarBlade.ParseTableStrings(ResultSelfAirborneEffect) 
				StellarBlade.AddEffectFromTable(self,table_ResultSelfAirborneEffect) 
			end 
			StellarBlade.SetShow_alt(self,ResultSelfAirborneShowPath) 
			return true 
		end 
		if ResultSelfAirborneEffect != "" then 
			local table_ResultSelfAirborneEffect = StellarBlade.ParseTableStrings(ResultSelfAirborneEffect) 
			StellarBlade.AddEffectFromTable(self,table_ResultSelfAirborneEffect) 
		end 
		StellarBlade.SetShow_alt(self,ResultSelfAirborneShowPath) 
		return true 
	end 
	
	local bAir = !self:IsOnGround() 
	if bAir then 
		if HitLevel then 
			if ResultSelfAirEffect != "" then 
				local table_ResultSelfAirEffect = StellarBlade.ParseTableStrings(ResultSelfAirEffect) 
				StellarBlade.AddEffectFromTable(self,table_ResultSelfAirEffect) 
			end 
			StellarBlade.SetShow_alt(self,ResultSelfAirShowPath) 
			return true 
		end 
		if ResultSelfAirEffect != "" then 
			local table_ResultSelfAirEffect = StellarBlade.ParseTableStrings(ResultSelfAirEffect) 
			StellarBlade.AddEffectFromTable(self,table_ResultSelfAirEffect) 
		end 
		StellarBlade.SetShow_alt(self,ResultSelfAirShowPath) 
		return true 
	end 
	local bMoving = self.IsMoving and self:IsMoving() or !self:GetVelocity():IsZero() -- and no move aliases present 
	if bMoving then 
		if HitLevel then 
			if ResultSelfEventMovingEffect != "" then 
				local table_ResultSelfEventMovingEffect = StellarBlade.ParseTableStrings(ResultSelfEventMovingEffect) 
				StellarBlade.AddEffectFromTable(self,table_ResultSelfEventMovingEffect) 
			end 
			StellarBlade.SetShow_alt(self,ResultSelfEventMovingShowPath) 
			return true 
		end 
		if ResultSelfEventMovingEffect != "" then 
			local table_ResultSelfEventMovingEffect = StellarBlade.ParseTableStrings(ResultSelfEventMovingEffect) 
			StellarBlade.AddEffectFromTable(self,table_ResultSelfEventMovingEffect) 
		end  
		StellarBlade.SetShow_alt(self,ResultSelfEventMovingShowPath) 
		return true 
	end 
	
	local bCommon = true 
	if bCommon then 
		if HitLevel then 
			if ResultSelfCommonEffect != "" then 
				local table_ResultSelfCommonEffect = StellarBlade.ParseTableStrings(ResultSelfCommonEffect) 
				StellarBlade.AddEffectFromTable(self,table_ResultSelfCommonEffect) 
			end 
			StellarBlade.SetShow_alt(self,ResultSelfCommonShowPath) 
			return true 
		end 
		if ResultSelfCommonEffect != "" then 
			local table_ResultSelfCommonEffect = StellarBlade.ParseTableStrings(ResultSelfCommonEffect) 
			StellarBlade.AddEffectFromTable(self,table_ResultSelfCommonEffect) 
		end 
		StellarBlade.SetShow_alt(self,ResultSelfCommonShowPath) 
		return true 
	end 
end 

StellarBlade.StartSkillTargetResult = function(target,SkillResultAlias,HitLevel) 
	HitLevel = false 
	local SkillResult = SB_SkillResultTable[1].Rows[SkillResultAlias] 
	-- priority: critical, weakpoint, groggy, down, swimming, airborne, air, moving, common 

	local ResultTargetCriticalEffect = SkillResult.ResultTargetCriticalEffect 
	local ResultTargetCriticalShowPath = SkillResult.ResultTargetCriticalShowPath 
	local ResultTargetWeakpointHitEffect = SkillResult.ResultTargetWeakpointHitEffect 
	
	local ResultTargetGroggyEffect = SkillResult.ResultTargetGroggyEffect 
	local HitLevelResultTargetGroggyEffect = SkillResult.HitLevelResultTargetGroggyEffect 
	local ResultTargetGroggyShowPath = SkillResult.ResultTargetGroggyShowPath 
	local HitLevelResultTargetGroggyMoveAlias = SkillResult.HitLevelResultTargetGroggyMoveAlias 
	local ResultTargetGroggyMoveAlias = SkillResult.ResultTargetGroggyMoveAlias 
	
	local ResultTargetDownEffect = SkillResult.ResultTargetDownEffect 
	local HitLevelResultTargetDownEffect = SkillResult.HitLevelResultTargetDownEffect 
	local ResultTargetDownShowPath = SkillResult.ResultTargetDownShowPath 
	local HitLevelResultTargetDownMoveAlias = SkillResult.HitLevelResultTargetDownMoveAlias 
	local ResultTargetDownMoveAlias = SkillResult.ResultTargetDownMoveAlias 
	
	local ResultTargetSwimmingEffect = SkillResult.ResultTargetSwimmingEffect 
	local HitLevelResultTargetSwimmingEffect = SkillResult.HitLevelResultTargetSwimmingEffect 
	local ResultTargetSwimmingShowPath = SkillResult.ResultTargetSwimmingShowPath 
	local HitLevelResultTargetSwimmingMoveAlias = SkillResult.HitLevelResultTargetSwimmingMoveAlias 
	local ResultTargetSwimmingMoveAlias = SkillResult.ResultTargetSwimmingMoveAlias 

	local ResultTargetAirborneEffect = SkillResult.ResultTargetAirborneEffect 
	local HitLevelResultTargetAirborneEffect = SkillResult.HitLevelResultTargetAirborneEffect 
	local ResultTargetAirborneShowPath = SkillResult.ResultTargetAirborneShowPath 
	local HitLevelResultTargetAirborneMoveAlias = SkillResult.HitLevelResultTargetAirborneMoveAlias 
	local ResultTargetAirborneMoveAlias = SkillResult.ResultTargetAirborneMoveAlias 
	
	local ResultTargetAirEffect = SkillResult.ResultTargetAirEffect 
	local HitLevelResultTargetAirEffect = SkillResult.HitLevelResultTargetAirEffect 
	local ResultTargetAirShowPath = SkillResult.ResultTargetAirShowPath 
	local HitLevelResultTargetAirMoveAlias = SkillResult.HitLevelResultTargetAirMoveAlias 
	local ResultTargetAirMoveAlias = SkillResult.ResultTargetAirMoveAlias 
	
	local ResultTargetEventMovingEffect = SkillResult.ResultTargetEventMovingEffect 
	local HitLevelResultTargetEventMovingEffect = SkillResult.HitLevelResultTargetEventMovingEffect 
	local ResultTargetEventMovingShowPath = SkillResult.ResultTargetEventMovingShowPath 
	local HitLevelResultTargetEventMovingMoveAlias = SkillResult.HitLevelResultTargetEventMovingMoveAlias 
	local ResultTargetEventMovingMoveAlias = SkillResult.ResultTargetEventMovingMoveAlias 
	
	local ResultTargetCommonEffect = SkillResult.ResultTargetCommonEffect 
	local HitLevelResultTargetCommonEffect = SkillResult.HitLevelResultTargetCommonEffect 
	local ResultTargetCommonShowPath = SkillResult.ResultTargetCommonShowPath 
	local HitLevelResultTargetCommonMoveAlias = SkillResult.HitLevelResultTargetCommonMoveAlias 
	local ResultTargetCommonMoveAlias = SkillResult.ResultTargetCommonMoveAlias 
	
	local bCritical = false 
	if bCritical then 
		if ResultTargetCriticalEffect != "" then 
			local table_ResultTargetCriticalEffect = StellarBlade.ParseTableStrings(ResultTargetCriticalEffect) 
			StellarBlade.AddEffectFromTable(target,table_ResultTargetCriticalEffect) 
		end 
		StellarBlade.SetShow_alt(target,ResultTargetCriticalShowPath) 
		return true 
	end 
	
	local bWeakpoint = false 
	
	if bWeakpoint then 
		if ResultTargetCriticalEffect != "" then 
			local table_ResultTargetCriticalEffect = StellarBlade.ParseTableStrings(ResultTargetCriticalEffect) 
			StellarBlade.AddEffectFromTable(target,table_ResultTargetCriticalEffect) 
		end 
		return true 
	end 
	
	local bGroggy = false 
	
	if bGroggy then 
		if HitLevel then 
			if HitLevelResultTargetGroggyEffect != "" then 
				local table_HitLevelResultTargetGroggyEffect = StellarBlade.ParseTableStrings(HitLevelResultTargetGroggyEffect) 
				StellarBlade.AddEffectFromTable(target,table_HitLevelResultTargetGroggyEffect) 
			end 
			StellarBlade.SetShow_alt(target,ResultTargetGroggyShowPath) 
			StellarBlade.SetMoveTable(target,HitLevelResultTargetGroggyMoveAlias) 
			return true 
		end 
		if ResultTargetGroggyEffect != "" then 
			local table_ResultTargetGroggyEffect = StellarBlade.ParseTableStrings(ResultTargetGroggyEffect) 
			StellarBlade.AddEffectFromTable(target,table_ResultTargetGroggyEffect) 
		end 
		StellarBlade.SetShow_alt(target,ResultTargetGroggyShowPath) 
		StellarBlade.SetMoveTable(target,HitLevelResultTargetGroggyMoveAlias) 
		return true 
	end 
	
	local bDown = false 
	
	if bDown then 
		if HitLevel then 
			if HitLevelResultTargetDownEffect != "" then 
				local table_HitLevelResultTargetDownEffect = StellarBlade.ParseTableStrings(HitLevelResultTargetDownEffect) 
				StellarBlade.AddEffectFromTable(target,table_HitLevelResultTargetDownEffect) 
			end 
			StellarBlade.SetShow_alt(target,ResultTargetDownShowPath) 
			StellarBlade.SetMoveTable(target,HitLevelResultTargetDownMoveAlias) 
			return true 
		end 
		if ResultTargetDownEffect != "" then 
			local table_ResultTargetDownEffect = StellarBlade.ParseTableStrings(ResultTargetDownEffect) 
			StellarBlade.AddEffectFromTable(target,table_ResultTargetDownEffect) 
		end 
		StellarBlade.SetShow_alt(target,ResultTargetDownShowPath) 
		StellarBlade.SetMoveTable(target,HitLevelResultTargetDownMoveAlias) 
		return true 
	end 
	
	local bSwimming = target:WaterLevel() > 0 
	
	if bSwimming then 
		if HitLevel then 
			if HitLevelResultTargetSwimmingEffect != "" then 
				local table_HitLevelResultTargetSwimmingEffect = StellarBlade.ParseTableStrings(HitLevelResultTargetSwimmingEffect) 
				StellarBlade.AddEffectFromTable(target,table_HitLevelResultTargetSwimmingEffect) 
			end 
			StellarBlade.SetShow_alt(target,ResultTargetSwimmingShowPath) 
			StellarBlade.SetMoveTable(target,HitLevelResultTargetSwimmingMoveAlias) 
			return true 
		end 
		if ResultTargetSwimmingEffect != "" then 
			local table_ResultTargetSwimmingEffect = StellarBlade.ParseTableStrings(ResultTargetSwimmingEffect) 
			StellarBlade.AddEffectFromTable(target,table_ResultTargetSwimmingEffect) 
		end 
		StellarBlade.SetShow_alt(target,ResultTargetSwimmingShowPath) 
		StellarBlade.SetMoveTable(target,HitLevelResultTargetSwimmingMoveAlias) 
		return true 
	end 
	
	local bAirborne = target:GetMoveType() == MOVETYPE_FLY or target.GetNavType and target:GetNavType() == NAV_FLY or target:IsFlagSet(FL_FLY) 
	if bAirborne then 
		if HitLevel then 
			if HitLevelResultTargetAirborneEffect != "" then 
				local table_HitLevelResultTargetAirborneEffect = StellarBlade.ParseTableStrings(HitLevelResultTargetAirborneEffect) 
				StellarBlade.AddEffectFromTable(target,table_HitLevelResultTargetAirborneEffect) 
			end 
			StellarBlade.SetShow_alt(target,ResultTargetAirborneShowPath) 
			StellarBlade.SetMoveTable(target,HitLevelResultTargetAirborneMoveAlias) 
			return true 
		end 
		if ResultTargetAirborneEffect != "" then 
			local table_ResultTargetAirborneEffect = StellarBlade.ParseTableStrings(ResultTargetAirborneEffect) 
			StellarBlade.AddEffectFromTable(target,table_ResultTargetAirborneEffect) 
		end 
		StellarBlade.SetShow_alt(target,ResultTargetAirborneShowPath) 
		StellarBlade.SetMoveTable(target,HitLevelResultTargetAirborneMoveAlias) 
		return true 
	end 
	
	local bAir = !target:IsOnGround() 
	if bAir then 
		if HitLevel then 
			if HitLevelResultTargetAirEffect != "" then 
				local table_HitLevelResultTargetAirEffect = StellarBlade.ParseTableStrings(HitLevelResultTargetAirEffect) 
				StellarBlade.AddEffectFromTable(target,table_HitLevelResultTargetAirEffect) 
			end 
			StellarBlade.SetShow_alt(target,ResultTargetAirShowPath) 
			StellarBlade.SetMoveTable(target,HitLevelResultTargetAirMoveAlias) 
			return true 
		end 
		if ResultTargetAirEffect != "" then 
			local table_ResultTargetAirEffect = StellarBlade.ParseTableStrings(ResultTargetAirEffect) 
			StellarBlade.AddEffectFromTable(target,table_ResultTargetAirEffect) 
		end 
		StellarBlade.SetShow_alt(target,ResultTargetAirShowPath) 
		StellarBlade.SetMoveTable(target,HitLevelResultTargetAirMoveAlias) 
		return true 
	end 
	local bMoving = target.IsMoving and target:IsMoving() or !target:GetVelocity():IsZero() -- and no move aliases present 
	if bMoving then 
		if HitLevel then 
			if HitLevelResultTargetEventMovingEffect != "" then 
				local table_HitLevelResultTargetEventMovingEffect = StellarBlade.ParseTableStrings(HitLevelResultTargetEventMovingEffect) 
				StellarBlade.AddEffectFromTable(target,table_HitLevelResultTargetEventMovingEffect) 
			end 
			StellarBlade.SetShow_alt(target,ResultTargetEventMovingShowPath) 
			StellarBlade.SetMoveTable(target,HitLevelResultTargetEventMovingMoveAlias) 
			return true 
		end 
		if ResultTargetEventMovingEffect != "" then 
			local table_ResultTargetEventMovingEffect = StellarBlade.ParseTableStrings(ResultTargetEventMovingEffect) 
			StellarBlade.AddEffectFromTable(target,table_ResultTargetEventMovingEffect) 
		end 
		StellarBlade.SetShow_alt(target,ResultTargetEventMovingShowPath) 
		StellarBlade.SetMoveTable(target,ResultTargetEventMovingMoveAlias) 
		return true 
	end 
	
	local bCommon = true 
	if bCommon then 
		if HitLevel then 
			if HitLevelResultTargetCommonEffect != "" then 
				local table_HitLevelResultTargetCommonEffect = StellarBlade.ParseTableStrings(HitLevelResultTargetCommonEffect) 
				StellarBlade.AddEffectFromTable(target,table_HitLevelResultTargetCommonEffect) 
			end 
			StellarBlade.SetShow_alt(target,ResultTargetCommonShowPath) 
			StellarBlade.SetMoveTable(target,HitLevelResultTargetCommonMoveAlias) 
			return true 
		end 
		if ResultTargetCommonEffect != "" then 
			local table_ResultTargetCommonEffect = StellarBlade.ParseTableStrings(ResultTargetCommonEffect) 
			StellarBlade.AddEffectFromTable(target,table_ResultTargetCommonEffect) 
		end 
		StellarBlade.SetShow_alt(target,ResultTargetCommonShowPath) 
		StellarBlade.SetMoveTable(target,ResultTargetCommonMoveAlias) 
		return true 
	end 
	
	return false -- unlikely, when not handled 
end 

StellarBlade.JustParryAnticipation = function(ent) -- just parry: the parry you properly calculate its timespan 
	--- START: Added Damage Check Logic ---

	local bDamageBlocked = false -- Initialize the variable to false.

	-- Check various conditions to see if damage was blocked or prevented.
	-- We set bDamageBlocked to true if ANY of these conditions are met.

	-- Condition 1: The ent is a player and the GM:PlayerShouldTakeDamage hook returns false.
	local playerHookBlocked = ent:IsPlayer() and hook.Run("GM:PlayerShouldTakeDamage", ent, self) == false
	local ai_block_damage = ent:IsNPC() and cvars.Bool("ai_block_damage") == false 

	-- Condition 2: The ent has God Mode enabled.
	local isGodMode = ent:IsFlagSet(FL_GODMODE)

	-- Condition 3: The ent's internal takedamage variable is set to 0 (DAMAGE_NO) or less.
	-- (or 1) is a safeguard in case the variable is missing, defaulting to DAMAGE_EVENTS_ONLY.
	local takeDamageDisabled = (ent:GetInternalVariable("m_takedamage") or 1) < 1

	if playerHookBlocked or isGodMode or takeDamageDisabled or ai_block_damage then
		bDamageBlocked = true
	end
	return bDamageBlocked 
end 

StellarBlade.SetSkillStep = function(self,strSkill) 
	local SkillStepTable = SB_SkillActiveStepTable[1].Rows[strSkill]
    if !SkillStepTable then
        self.SBAI_ActiveSkill = nil -- Clear active skill if the next step is invalid
        self.SBAI_SkillTable = nil -- Clear active skill if the next step is invalid
        return false 
    end 
	local curTime = CurTime() 

    -- Store the current skill step's data 
	self.SBAI_ActiveSkill = { } 
	local SBAI_ActiveSkill = self.SBAI_ActiveSkill 
	SBAI_ActiveSkill.Name = strSkill 
	SBAI_ActiveSkill.Data = SkillStepTable 
	SBAI_ActiveSkill.Time = curTime 
	SBAI_ActiveSkill.Duration = curTime + SkillStepTable.Duration 
	SBAI_ActiveSkill.Cycle = 0 
	local StartSelfEffect = SkillStepTable.StartSelfEffect 
	local StartTargetEffect = SkillStepTable.StartTargetEffect 

    -- [NEW] Handle `bRetargeting`: Lock onto the current target if false
    if SkillStepTable.bRetargeting == false and self.GetEnemy then
        SBAI_ActiveSkill.LockedTarget = self:GetEnemy()
    else
        -- If retargeting is allowed, ensure no previous target is locked
        SBAI_ActiveSkill.LockedTarget = nil
    end 
	
	-- add self effects 
	
	if StartSelfEffect != "" then 
		StartSelfEffect = StellarBlade.ParseTableStrings(StartSelfEffect) 
		StellarBlade.AddEffectFromTable(self,StartSelfEffect) 
	end 
	
	-- add target effects 
	if IsValid(SBAI_ActiveSkill.LockedTarget) then 
		if StartTargetEffect != "" then 
			StartTargetEffect = StellarBlade.ParseTableStrings(StartTargetEffect) 
			StellarBlade.AddEffectFromTable(self,StartTargetEffect) 
		end 
	end 

    -- [NEW] Handle `StopSelfMove`: Stop the NPC from moving if true 
    if SkillStepTable.StopSelfMove and self.StopMoving then 
        self:StopMoving(true) 
        self:ClearGoal() 
    end  
	
	if SkillStepTable.ShowPath != "None" then 
		local showpath = "addons/sbraven/data_static/SB/Content/Art/Show/" 
		showpath = showpath..SkillStepTable.ShowPath..".json" 
		StellarBlade.SetShow(self,showpath) 
	end 

    -- Apply the animation/movement for this step
    local SelfMoveAliasArray = SkillStepTable.SelfMoveAliasArray
    for _, SelfMoveAlias in pairs(SelfMoveAliasArray) do
        StellarBlade.SetMoveTable(self,SelfMoveAlias)
    end 

	if #SkillStepTable.UsableTargetProjectileAliasArray > 0 then 
		for i = 1,#SkillStepTable.UsableTargetProjectileAliasArray do 
			local event,etime,cycle,types,options 
			if self.NPC_RangedAttack then 
				self:NPC_RangedAttack(event,etime,cycle,types,options) 
			elseif self:IsNPC() then 
				self.NPC_RangedProjectile = "proj_unreali_dispersionammo" 
				scripted_ents.Get("npc_unreali_female").NPC_RangedAttack(self,event,etime,cycle,types,options) 
			else 
				local proj = ents.Create("proj_unreali_dispersionammo") 
				proj:SetOwner(self) 
				proj:SetPos(self:GetShootPos()) 
				proj:SetAngles(self:GetAimVector():Angle()) 
				proj:Spawn() 
				proj:Activate() 
			end 
		end 
	end 
	return true 
end 

--==============================================================================
-- HELPER: Curve Loading and Evaluation
--==============================================================================
--[[
    Loads a CurveFloat JSON file by parsing the specific path format from the move tables.
    @param curveDataPath The raw path string from the CharacterMoveTable.
]]-- 

StellarBlade.LoadCurveData = function(curveDataPath)
    if not curveDataPath or curveDataPath == "None" then return end

    -- Extract the path between the single quotes, e.g., /Game/GameDesign/...
    local extractedPath = string.match(curveDataPath, "'(.-)'")
    if not extractedPath then return end

    -- Strip the duplicate object name at the end, which acts like an extension.
	extractedPath = string.sub(extractedPath,6) 
    extractedPath = string.StripExtension(extractedPath)

    -- Construct the final file path.
    local finalPath = "addons/sbraven/data_static/SB/Content" .. extractedPath .. ".json"

    -- This external function is expected to load the JSON into a global table.
    SB_ImportJSON(finalPath)
end 

StellarBlade.LookupCharacterSound = function(self,key) 
	key = string.upper(key) 
	local CharacterSoundSet = string.GetFileFromFilename(string.StripExtension(self.CharacterSoundSetPath or "addons/sbraven/data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_53_Raven.json")) 
	CharacterSoundSet = _G["SB_"..CharacterSoundSet] -- the CharacterSoundSet imported from JSON is now a Lua table 
	if !CharacterSoundSet or !CharacterSoundSet[1].Properties then return nil end
    -- search through all sound categories
    local categories = { "HitSounds", "ReactSounds", "EnvHitSounds", "VoiceSounds" }
    for _, category in ipairs(categories) do
        local sounds = CharacterSoundSet[1].Properties[category]
        if sounds then
            for _, entry in ipairs(sounds) do
				local parsingKey = string.upper(entry.Key) 
                if parsingKey == key then
                    local value = entry.Value
                    local soundData = {}

                    -- handle nested HitTypeArray (like in HitSounds)
                    if value.HitTypeArray then
                        for _, hit in ipairs(value.HitTypeArray) do
                            if hit.HitSound then
                                soundData = hit.HitSound
                                break
                            end
                        end
                    else
                        soundData = value
                    end

                    -- flatten SoundSource.ObjectPath into top-level
                    if soundData.SoundSource then
                        soundData.ObjectName = soundData.SoundSource.ObjectName
                        soundData.ObjectPath = soundData.SoundSource.ObjectPath
                    end

                    return soundData
                end
            end
        end
    end

    return nil
end 

StellarBlade.SetMoveTable = function(self,strEffect)
    if !SB_CharacterMoveTable or not SB_CharacterMoveTable[1] or !SB_CharacterMoveTable[1].Rows then
        print("ERROR: SB_CharacterMoveTable is not available.")
        return false
    end

    local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[strEffect]
    if !CharacterMoveTable then 
		if strEffect != "None" then 
			print("no move table", self, strEffect) 
		end 
        return false
    end

    if !self.SBAI_MoveStep then
        self.SBAI_MoveStep = {}
    end

    local newMoveStep = {
        ["MoveArrayName"] = strEffect,
        ["StartTime"] = CurTime() + (CharacterMoveTable.StartDelayTime or 0), 
        ["RunTime"] = CurTime(), 
		["LastVelocity"] = vector_origin 
    }
    table.insert(self.SBAI_MoveStep, newMoveStep)

    if CharacterMoveTable.RootMotionDataPath and CharacterMoveTable.RootMotionDataPath ~= "None" then
        local RootMotionDataPath = string.sub(CharacterMoveTable.RootMotionDataPath, 6)
        RootMotionDataPath = "addons/sbraven/data_static/SB/Content" .. RootMotionDataPath .. ".json"
        SB_ImportJSON(RootMotionDataPath)
    end
    if CharacterMoveTable.PositionInterpCurveDataPath and CharacterMoveTable.PositionInterpCurveDataPath != "None" then
        StellarBlade.LoadCurveData(CharacterMoveTable.PositionInterpCurveDataPath)
    end
    if CharacterMoveTable.StaticMoveZVAlueCurveDataPath and CharacterMoveTable.StaticMoveZVAlueCurveDataPath != "None" then
        StellarBlade.LoadCurveData(CharacterMoveTable.StaticMoveZVAlueCurveDataPath)
    end
    if CharacterMoveTable.MoveOffsetCurveDataPath and CharacterMoveTable.MoveOffsetCurveDataPath != "None" then
        StellarBlade.LoadCurveData(CharacterMoveTable.MoveOffsetCurveDataPath)
    end
    if CharacterMoveTable.RotationInterpCurveDataPath and CharacterMoveTable.RotationInterpCurveDataPath != "None" then
        StellarBlade.LoadCurveData(CharacterMoveTable.RotationInterpCurveDataPath)
    end

    return true
end 

StellarBlade.ShouldCancelMoveTable = function(self,moveStep) 
    if not moveStep then return false end
    local name = moveStep.MoveArrayName 
    local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name] 
	if self.GetEnemy then 
		if CharacterMoveTable.bStopWhenInvalidTarget and not IsValid(self:GetEnemy()) then 
			return true 
		end
	end 
	if self.IsGoalActive then 
		if CharacterMoveTable.bStopWhenInvalidNavigation and !self:IsGoalActive() then 
			return true 
		end 
	end 
	if !self:Alive() then return true end 
    return false 
end 

-- EvaluateMoveStep (improved root-motion probe)
-- Accepts moveStep table OR MoveArrayName string.
-- flInterval: live-frame interval; if < 0 => special "full final" probe
-- probeElapsed: optional explicit elapsed time (seconds) to simulate (overrides StartTime)
-- Returns: success(boolean), movePosDelta(Vector), moveAngDelta(Angle)
StellarBlade.EvaluateMoveStep = function(self, moveStepOrName, flInterval, probeElapsed)
    if not moveStepOrName then return false, Vector(0,0,0), Angle(0,0,0) end

    local isTempStep = false
    local moveStep = nil

    if type(moveStepOrName) == "table" then
        moveStep = moveStepOrName
    elseif type(moveStepOrName) == "string" then
        isTempStep = true
        -- default start/run time now; may be adjusted below for probing
        moveStep = {
            MoveArrayName = moveStepOrName,
            StartTime = CurTime(),
            RunTime = CurTime()
        }
    else
        return false, Vector(0,0,0), Angle(0,0,0)
    end

    -- Resolve CharacterMoveTable
    local name = moveStep.MoveArrayName
    if not name or not SB_CharacterMoveTable or not SB_CharacterMoveTable[1] or not SB_CharacterMoveTable[1].Rows[name] then
        return false, Vector(0,0,0), Angle(0,0,0)
    end
    local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name]

    local Time = CharacterMoveTable.Time or 0
    local moveStartTimeCfg = CharacterMoveTable.MoveStartTime or 0
    local moveEndTimeCfg = CharacterMoveTable.MoveEndTime or Time
    local moveDuration = math.max(0, moveEndTimeCfg - moveStartTimeCfg)

    -- If caller provided explicit probeElapsed, set StartTime so sampler sees that elapsed
    if probeElapsed ~= nil and isTempStep then
        moveStep.StartTime = CurTime() - probeElapsed
        moveStep.RunTime = CurTime()
    elseif flInterval and flInterval < 0 and isTempStep then
        -- Full-final probe: set StartTime so elapsed == moveDuration
        -- If duration is zero, set it to far past to force any rootmotion sampling to final frame (best-effort)
        if moveDuration > 0 then
            moveStep.StartTime = CurTime() - moveDuration
            moveStep.RunTime = CurTime()
        else
            -- moveDuration == 0: sample as if finished — set StartTime to past
            moveStep.StartTime = CurTime() - 1.0
            moveStep.RunTime = CurTime()
        end
    end

    -- If flInterval wasn't provided for live call, fall back to previous behaviour
    if flInterval == nil and type(moveStepOrName) == "table" and moveStep.RunTime then
        flInterval = CurTime() - (moveStep.RunTime or CurTime())
    end

    -- Compute normalized times
    local normalizedTime, prevNormalizedTime = 0, 0
    if flInterval and flInterval < 0 then
        normalizedTime = 1
        prevNormalizedTime = 0
    else
        local elapsedTime = nil
        if probeElapsed ~= nil then
            elapsedTime = probeElapsed
        else
            elapsedTime = CurTime() - (moveStep.StartTime or CurTime())
        end

        if moveDuration > 0 then
            local usedInterval = flInterval or 0
            normalizedTime = math.Clamp((elapsedTime - moveStartTimeCfg) / moveDuration, 0, 1)
            prevNormalizedTime = math.Clamp(((elapsedTime - usedInterval) - moveStartTimeCfg) / moveDuration, 0, 1)
        else
            normalizedTime = 0
            prevNormalizedTime = 0
        end
    end

    local interpType = CharacterMoveTable.PositionInterpType
    local easedNow = StellarBlade.GetEasedFraction(interpType, normalizedTime)
    local easedPrev = StellarBlade.GetEasedFraction(interpType, prevNormalizedTime)

    local movePosDelta = Vector(0,0,0)
    local moveAngDelta = Angle(0,0,0)
    local flRescale = 1

    -- Determine direction basis (safe fallbacks)
    local enemy = (self and self.GetEnemy and self:GetEnemy()) or nil
    if not IsValid(enemy) and StellarBlade and StellarBlade.PickTarget then
        enemy = StellarBlade.PickTarget(self)
    end
    if not IsValid(enemy) then enemy = Entity(0) end

    local directionAxis = CharacterMoveTable.PositionDirectionAxis
    local vecMoveDirection = Vector(1,0,0)
    if self and self.GetAimVector then vecMoveDirection = self:GetAimVector() or vecMoveDirection
    else vecMoveDirection = self:GetForward() end

    if directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_Target" then
        if IsValid(enemy) and enemy.GetAimVector then vecMoveDirection = enemy:GetAimVector() end
    elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_SelfToTarget" then
        if IsValid(enemy) then vecMoveDirection = (enemy:GetPos() - self:GetPos()):GetNormalized() end
    elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_InputDirectionWorld" then
        vecMoveDirection = self:GetForward() 
    elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_SelfToTarget2D" then
        if IsValid(enemy) then
            local epos = enemy:GetPos(); epos.z = 0
            local spos = self:GetPos(); spos.z = 0
            vecMoveDirection = (epos - spos):GetNormalized()
        end
    end

    local MoveType = CharacterMoveTable.MoveType

    -- Root motion: now uses moveStep.StartTime (which we adjusted above in probe mode)
    if MoveType == "ESBMoveTransformType::MoveTransformType_RootMotion" then
        local RootMotionDataPath = string.StripExtension(string.GetFileFromFilename(CharacterMoveTable.RootMotionDataPath or ""))
        local RootMotion = _G["SB_" .. RootMotionDataPath]
        if RootMotion then
            local posOffset, angOffset = StellarBlade.GetRootMotionTransform(RootMotion, moveStep.StartTime)
            if posOffset and angOffset then
                moveStep.PrevPosOffset = moveStep.PrevPosOffset or Vector(0,0,0)
                moveStep.PrevAngOffset = moveStep.PrevAngOffset or Angle(0,0,0)
                local posDelta = posOffset - moveStep.PrevPosOffset
                moveAngDelta = angOffset - moveStep.PrevAngOffset

                local rightVec = vecMoveDirection:Cross(Vector(0,0,1))
                local upVec = vecMoveDirection:Cross(Vector(0,1,0))
                movePosDelta = vecMoveDirection * posDelta.x + rightVec * posDelta.y + upVec * posDelta.z

                -- Update prev offsets on the temporary step so repeated probe calls that pass the same table can still be incremental
                moveStep.PrevPosOffset = posOffset
                moveStep.PrevAngOffset = angOffset
            end
        end

    -- Static moves (curves or linear)
    elseif MoveType == "ESBMoveTransformType::MoveTransformType_Static" then
        if CharacterMoveTable.PositionType == "ESBMovePositionType::MovePositionType_TargetSocket" then
            local target = (self.GetEnemy and self:GetEnemy()) and IsValid(self:GetEnemy()) and self:GetEnemy() or StellarBlade.PickTarget(self)
            if IsValid(target) then
                movePosDelta = target:WorldSpaceCenter() - (self and self.GetPos and self:GetPos() or Vector(0,0,0))
            end
        else
            local rightDir = vecMoveDirection:Cross(Vector(0,0,1)):GetNormalized()
            local forwardMove = CharacterMoveTable.ForwardValue or 0
            local rightMove = CharacterMoveTable.RightValue or 0
            local upMove = CharacterMoveTable.UpValue or 0
            local posCurvePath = CharacterMoveTable.PositionInterpCurveDataPath
            local zCurvePath = CharacterMoveTable.StaticMoveZVAlueCurveDataPath

            if (posCurvePath and posCurvePath ~= "None") or (zCurvePath and zCurvePath ~= "None") then
                local posMultiplier, prevPosMultiplier, zMultiplier, prevZMultiplier = 1,1,1,1
                if posCurvePath and posCurvePath ~= "None" then
                    local curveName = string.StripExtension(string.GetFileFromFilename(string.match(posCurvePath, "'(.-)'") or ""))
                    posMultiplier = StellarBlade.ApplyCurveFloat(curveName, normalizedTime)
                    prevPosMultiplier = StellarBlade.ApplyCurveFloat(curveName, prevNormalizedTime)
                end
                if zCurvePath and zCurvePath ~= "None" then
                    local curveName = string.StripExtension(string.GetFileFromFilename(string.match(zCurvePath, "'(.-)'") or ""))
                    zMultiplier = StellarBlade.ApplyCurveFloat(curveName, normalizedTime)
                    prevZMultiplier = StellarBlade.ApplyCurveFloat(curveName, prevNormalizedTime)
                end
                local totalOffset = (vecMoveDirection * forwardMove + rightDir * rightMove)
                local curvePosDelta = totalOffset * (posMultiplier - prevPosMultiplier)
                local zDelta = Vector(0,0, upMove * (zMultiplier - prevZMultiplier))
                movePosDelta = curvePosDelta + zDelta
            else
                local totalDisplacement = (vecMoveDirection * forwardMove) + (rightDir * rightMove) + (Vector(0,0,1) * upMove)
                movePosDelta = totalDisplacement * (easedNow - easedPrev)
            end
        end

    elseif MoveType == "ESBMoveTransformType::MoveTransformType_LocalAxis" then
        local forwardMove = CharacterMoveTable.ForwardValue or 0
        local rightMove = CharacterMoveTable.RightValue or 0
        local upMove = CharacterMoveTable.UpValue or 0
        local localDisplacementDelta = Vector(forwardMove, rightMove, upMove) * (easedNow - easedPrev)
        local rightVec = vecMoveDirection:Cross(Vector(0,0,1))
        local upVec = vecMoveDirection:Cross(Vector(0,1,0))
        movePosDelta = vecMoveDirection * localDisplacementDelta.x + rightVec * localDisplacementDelta.y + upVec * localDisplacementDelta.z

    elseif MoveType == "ESBMoveTransformType::MoveTransformType_WorldLocation" then
        local targetPos = Vector(CharacterMoveTable.ForwardValue or 0, CharacterMoveTable.RightValue or 0, CharacterMoveTable.UpValue or 0)
        movePosDelta = targetPos
    end

    movePosDelta = movePosDelta * flRescale
    return true, movePosDelta, moveAngDelta
end


StellarBlade.MaintainMoveTable = function(self) 
    if self.SBAI_MoveStep and #self.SBAI_MoveStep > 0 then
        local currentAng = self:GetLocalAngles() 
        local totalAngDelta = Angle(0, 0, 0) 
		local enemy = self.GetEnemy and self:GetEnemy() or nil 
		local enemyDir 

        -- Iterate backwards for safe removal
        for i = #self.SBAI_MoveStep, 1, -1 do
			
            local moveStep = self.SBAI_MoveStep[i]
			
			local flInterval = CurTime() - moveStep.RunTime 
			moveStep.RunTime = CurTime() 
			
            if CurTime() < moveStep.StartTime then continue end
			
			local ok, movePosDelta, moveAngDelta = StellarBlade.EvaluateMoveStep(self, moveStep, flInterval)
			local name = moveStep.MoveArrayName
            local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name] -- get precached movetable 
			local Time = CharacterMoveTable.Time
            local CurEndTime = moveStep.StartTime + Time
			-- print(ok,deltaPos,deltaAng) 
			-- the code commented out here is now moved to EvaluateMoveStep 
			--[[ 
            local name = moveStep.MoveArrayName
            local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name] -- get precached movetable 
            local Time = CharacterMoveTable.Time
            local CurEndTime = moveStep.StartTime + Time
            
            local moveStartTime = CharacterMoveTable.MoveStartTime or 0
            local moveEndTime = CharacterMoveTable.MoveEndTime or Time
            local moveDuration = moveEndTime - moveStartTime
            
            local normalizedTime, prevNormalizedTime = 0, 0
            if moveDuration > 0 then
                local elapsedTime = CurTime() - moveStep.StartTime
                normalizedTime = math.Clamp((elapsedTime - moveStartTime) / moveDuration, 0, 1)
                prevNormalizedTime = math.Clamp(((elapsedTime - flInterval) - moveStartTime) / moveDuration, 0, 1)
            end
            
            local interpType = CharacterMoveTable.PositionInterpType
            local easedNow = StellarBlade.GetEasedFraction(interpType, normalizedTime)
            local easedPrev = StellarBlade.GetEasedFraction(interpType, prevNormalizedTime)

            local movePosDelta = Vector(0, 0, 0)
            local moveAngDelta = Angle(0, 0, 0)
            local MoveType = CharacterMoveTable.MoveType
			local directionAxis = CharacterMoveTable.PositionDirectionAxis 
			local vecMoveDirection = self:GetAimVector() 
			if !IsValid(enemy) then 
				enemy = StellarBlade.PickTarget(self) 
			end 
			if !IsValid(enemy) then 
				enemy = Entity(0) 
			end 
			if directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_Self" then 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_Target" then 
				vecMoveDirection = enemy:GetAimVector() 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_SelfToTarget" then 
				vecMoveDirection = (enemy:GetPos() - self:GetPos()):GetNormalized() 
				-- vecMoveDirection = enemyDir or (self:GetPos() - enemy:GetPos()):GetNormalized() 
				enemyDir = vecMoveDirection 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_InputDirectionWorld" then -- relative to DefaultInputDirection, for player takedamage 
				vecMoveDirection = self:GetForward()  
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_InputDirectionLocal" then -- unused 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_HitDirection" then -- unused 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_Velocity" then -- used by Eve swimming 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_Velocity2D" then -- unused 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_SelfToTarget2D" then 
				local enemyPos = enemy:GetPos() enemyPos.z = 0 
				local selfPos = self:GetPos() selfPos.z = 0 
				vecMoveDirection = (enemyPos - selfPos):GetNormalized() 
			elseif directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_InputDirectionWorldWithoutZ" then -- relative to DefaultInputDirection, for player takedamage 
			
			end 
			-- print("directionAxis:",directionAxis,self) 
			
			-- print("moveDuration,elapsedTime,normalizedTime,prevNormalizedTime:",moveDuration,elapsedTime,normalizedTime,prevNormalizedTime) 
            if MoveType == "ESBMoveTransformType::MoveTransformType_RootMotion" then 
				-- print("in ESBMoveTransformType::MoveTransformType_RootMotion") 
        local RootMotionDataPath = string.StripExtension(string.GetFileFromFilename(CharacterMoveTable.RootMotionDataPath or ""))
		-- print("RootMotionDataPath",RootMotionDataPath) 
        local RootMotion = _G["SB_" .. RootMotionDataPath]
        if RootMotion then
			-- print("moveStep.StartTime:",moveStep.StartTime) 
            local posOffset, angOffset = StellarBlade.GetRootMotionTransform(RootMotion, moveStep.StartTime)
			-- print("posOffset,angOffset:",posOffset,angOffset) 
                    if posOffset and angOffset then
                        if not moveStep.PrevPosOffset then
                            moveStep.PrevPosOffset = Vector(0, 0, 0)
                            moveStep.PrevAngOffset = Angle(0, 0, 0)
                        end
                        local posDelta = posOffset - moveStep.PrevPosOffset
                        moveAngDelta = angOffset - moveStep.PrevAngOffset
                        -- movePosDelta = directionAngle:Forward() * posDelta.x + directionAngle:Right() * posDelta.y + directionAngle:Up() * posDelta.z
						-- print(vecMoveDirection) 
						-- posDelta = posDelta * flRescale -- rescale to approximate hammer units 
						movePosDelta = vecMoveDirection * posDelta.x + vecMoveDirection:Cross(Vector(0,0,1)) * posDelta.y + vecMoveDirection:Cross(Vector(0,1,0)) * posDelta.z 
						-- movePosDelta = vecMoveDirection * posDelta 
                        moveStep.PrevPosOffset = posOffset 
                        moveStep.PrevAngOffset = angOffset 
                    end 
                end 
				-- movePosDelta = movePosDelta * (easedNow - easedPrev) -- is the RootMotion influenced from interptype? 
            elseif MoveType == "ESBMoveTransformType::MoveTransformType_Static" then
				-- print("static") 
				if CharacterMoveTable.PositionType == "ESBMovePositionType::MovePositionType_TargetSocket" then -- TargetSocket used only by eve, static 
                    local target = IsValid(self:GetEnemy()) and self:GetEnemy() or StellarBlade.PickTarget(self) 
                    movePosDelta = target:WorldSpaceCenter() - self:GetPos()
                else
                    -- if not moveStep.MoveDir then
                        -- local directionAxis = CharacterMoveTable.PositionDirectionAxis
                        -- if directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_SelfToTarget" and IsValid(enemy) then
                            -- moveStep.MoveDir = (enemy:GetPos() - self:GetPos()):GetNormalized()
                        -- else
                            -- moveStep.MoveDir = currentAng:Forward()
                        -- end
                    -- end
					
                    local rightDir = vecMoveDirection:Cross(Vector(0, 0, 1)):GetNormalized()
                    local forwardMove = CharacterMoveTable.ForwardValue or 0
                    local rightMove = CharacterMoveTable.RightValue or 0
                    local upMove = CharacterMoveTable.UpValue or 0
                    local posCurvePath = CharacterMoveTable.PositionInterpCurveDataPath
                    local zCurvePath = CharacterMoveTable.StaticMoveZVAlueCurveDataPath
                    if (posCurvePath and posCurvePath != "None") or (zCurvePath and zCurvePath != "None") then
                        local posMultiplier, prevPosMultiplier, zMultiplier, prevZMultiplier = 1, 1, 1, 1
                        if posCurvePath and posCurvePath != "None" then
                            local curveName = string.StripExtension(string.GetFileFromFilename(string.match(posCurvePath, "'(.-)'")))
                            posMultiplier = StellarBlade.ApplyCurveFloat(curveName, normalizedTime)
                            prevPosMultiplier = StellarBlade.ApplyCurveFloat(curveName, prevNormalizedTime)
                        end
                        if zCurvePath and zCurvePath != "None" then
                           local curveName = string.StripExtension(string.GetFileFromFilename(string.match(zCurvePath, "'(.-)'")))
                            zMultiplier = StellarBlade.ApplyCurveFloat(curveName, normalizedTime)
                            prevZMultiplier = StellarBlade.ApplyCurveFloat(curveName, prevNormalizedTime)
                        end
                        local totalOffset = (vecMoveDirection * forwardMove + rightDir * rightMove)
                        local curvePosDelta = totalOffset * (posMultiplier - prevPosMultiplier)
                        local zDelta = Vector(0, 0, upMove * (zMultiplier - prevZMultiplier))
                        movePosDelta = curvePosDelta + zDelta
						-- movePosDelta = movePosDelta * (easedNow - easedPrev) 
                    else
                        local totalDisplacement = (vecMoveDirection * forwardMove) + (rightDir * rightMove) + (Vector(0,0,1) * upMove)
                        movePosDelta = totalDisplacement * (easedNow - easedPrev)
                    end
					-- movePosDelta = movePosDelta * flRescale 
                end
            elseif MoveType == "ESBMoveTransformType::MoveTransformType_LocalAxis" then 
			-- print("local") 
                local forwardMove = CharacterMoveTable.ForwardValue or 0 
                local rightMove = CharacterMoveTable.RightValue or 0 
                local upMove = CharacterMoveTable.UpValue or 0 
				-- print(forwardMove, rightMove, upMove) 
                local totalLocalDisplacement = Vector(forwardMove, rightMove, upMove) 
				-- print("totalLocalDisplacement", totalLocalDisplacement) 
				-- print(easedNow, easedPrev) 
                local localDisplacementDelta = totalLocalDisplacement * (easedNow - easedPrev) 
				-- print("localDisplacementDelta", localDisplacementDelta) 
                movePosDelta = vecMoveDirection * localDisplacementDelta.x + vecMoveDirection:Cross(Vector(0,0,1)) * localDisplacementDelta.y + vecMoveDirection:Cross(Vector(0,1,0)) * localDisplacementDelta.z 
            elseif MoveType == "ESBMoveTransformType::MoveTransformType_WorldLocation" then 
				local targetPos = Vector(CharacterMoveTable.ForwardValue,CharacterMoveTable.RightValue,CharacterMoveTable.UpValue) 
				movePosDelta = movePosDelta * (easedNow - easedPrev) 
				movePosDelta = targetPos -- lerp to targetPos using PositionInterpType 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_None" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_LinkTo" then -- link to attachment, used 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_LinkTo_Velocity" then -- unused 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_LinkFrom" then -- used 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_ZeroVelocity" then -- stop velocity, used only once 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_Airborne" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_Fly" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_Fall" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_TargetAround" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_PathWay" then 
			elseif MoveType == "ESBMoveTransformType::MoveTransformType_SwimmingDash" then 
			end 
			
			--]] 
			-- movePosDelta = movePosDelta * (easedNow - easedPrev)
			-- print(easedNow,easedPrev) 
			local velocity = movePosDelta
			-- print(velocity) 
			movePosDelta = movePosDelta * flRescale 
			-- print(movePosDelta) 

            -- Apply this move's delta and check for collision failure
            local collisionFailed = false
            if movePosDelta:LengthSqr() > 0.001 then
                local moveSuccess = true
                local targetPosForThisMove = self:GetPos() + movePosDelta

                if CharacterMoveTable.bOnGround and self.MoveGroundStep then 
					local MoveGroundStep = self:MoveGroundStep(targetPosForThisMove, enemy) 
					if self.SetMoveVelocity then self:SetMoveVelocity(velocity / flInterval) end 
					self:SetAbsVelocity(velocity / flInterval) 
                    if MoveGroundStep == 0 then moveSuccess = false end 
                else
					local moveResult = IterativeHybridMoveLimit(self, self:GetPos(), targetPosForThisMove)
					self:SetLocalPos(moveResult.vEndPosition) 
					
					-- compute per-frame velocity required to reach targetPosForThisMove
					local desiredDelta = velocity
					local desiredVelocity = desiredDelta / flInterval

					-- remove only the scripted velocity contribution from last frame
					local currentAbsVel = self:GetVelocity()
					local correctedVel = currentAbsVel - (moveStep.LastVelocity or Vector(0,0,0))

					-- apply new scripted velocity on top of external forces
					self:SetAbsVelocity(velocity / flInterval) 
					if self.SetMoveVelocity then self:SetMoveVelocity(velocity / flInterval) end 
					local phys = self:GetPhysicsObject() 
					if phys:IsValid() then 
						phys:SetVelocity(correctedVel + desiredVelocity) 
					end 

					if moveResult.fStatus ~= "OK" then
						moveSuccess = false
					end
				end

				moveStep.LastVelocity = desiredVelocity

                if !moveSuccess and CharacterMoveTable.bStopWhenCollision then
                    -- print("removing motion due to collision for", name) 
                    table.remove(self.SBAI_MoveStep, i)
                    collisionFailed = true
                end
            end
			-- print("self:GetPos():",self:GetPos()) 

            -- Only process expiration and add angle delta if the move wasn't removed for collision
            if !collisionFailed then
                totalAngDelta = totalAngDelta + moveAngDelta
                
                if CurTime() > CurEndTime or StellarBlade.ShouldCancelMoveTable(self,moveStep) then
					if tobool(CharacterMoveTable.bZeroVelocityWhenEnd) then
						-- remove only this step's contribution
						local currentAbsVel = self:GetVelocity()
						local correctedVel = currentAbsVel - (moveStep.LastVelocity or vector_origin)
						-- self:SetLocalVelocity(vector_origin)
						self:SetAbsVelocity(vector_origin) 

						moveStep.LastVelocity = vector_origin
					else 
						if self:IsPlayer() then 
							self:SetLocalVelocity(velocity / flInterval) 
						else 
							self:SetVelocity(velocity / flInterval) 
						end 
					end 
					table.remove(self.SBAI_MoveStep, i)
                end
            end
        end

        -- Apply total accumulated angle delta at the end
        local targetAng = currentAng + totalAngDelta
        if targetAng != currentAng then
            self:SetLocalAngles(targetAng)
        end
    end
end 

StellarBlade.BuildSoundScript = function(self,parsedjson) 
	if !istable(parsedjson) then
		parsedjson = SB_ImportJSON(parsedjson)
	end

	local SoundScript = {
		Entity = self,
		Pos = vector_origin,
		Volume = 1,
		Pitch = 100,
		SoundPath = Sound(""),
		RawSoundPath = "",
		Channel = CHAN_AUTO,
		Delay = 0,
		-- optional fields that may be filled from cue properties:
		MaxDistance = nil,
		Duration = nil,
		Attenuation = nil,
		SoundClass = nil,
		Concurrency = nil,
		Priority = nil
	}

	local function randBetween(a, b)
		a = tonumber(a) or 0
		b = tonumber(b) or a
		if a == b then return a end
		-- prefer math.Rand if available (GMod), else fallback
		if math.Rand then return math.Rand(a, b) end
		return a + math.random() * (b - a)
	end

	local function weightedChoice(weights)
		if not weights or #weights == 0 then return math.random(1, 1) end
		local total = 0
		for i = 1, #weights do total = total + (weights[i] or 0) end
		if total <= 0 then return math.random(1, #weights) end
		local pick = math.random() * total
		local cum = 0
		for i = 1, #weights do
			cum = cum + (weights[i] or 0)
			if pick <= cum then return i end
		end
		return #weights
	end

	-- convert ObjectName string or table to node name (e.g. "SoundNodeMixer_0")
	local function nodeNameFromObject(obj)
		if not obj then return nil end
		local s = (type(obj) == "table" and (obj.ObjectName or obj.ObjectPath) ) or tostring(obj)
		-- try :NAME' pattern
		local m = s:match(":([^']+)'")
		if m and #m > 0 then return m end
		-- trailing 'NAME' pattern
		m = s:match("([^']+)'$")
		if m and #m > 0 then return m end
		-- fallback: if it contains a dot index or path, pick last segment after dot/slash
		m = s:match("[^/%.%:]+$")
		if m and #m > 0 then return m end
		return s
	end

	-- convert Unreal asset path to game-file style:
	-- 1) remove leading "/Game/"
	-- 2) remove "L10N/<locale>/" if present
	-- 3) strip trailing ".Name" suffix
	local function unrealToGamePath(asset)
		if not asset then return nil end
		asset = tostring(asset)
		-- strip surrounding whitespace
		asset = asset:match("^%s*(.-)%s*$")
		-- strip trailing ".Name" portion if present
		asset = asset:gsub("%.[^%.%/]+$", "")
		-- remove leading /Game/
		asset = asset:gsub("^/Game/", "")
		-- remove localization prefix like "L10N/it/" or "L10N/de/"
		asset = asset:gsub("^L10N/[^/]+/", "")
		-- Also if localization appears after an initial folder (rare), remove any "/L10N/<loc>/" occurrences
		asset = asset:gsub("/L10N/[^/]+/", "/")
		-- final clean
		asset = asset:gsub("^/+", ""):gsub("/+", "/") 
		asset = asset..".wav"
		asset = string.sub(asset,7) 
		return asset
	end

	-- build lookup table
	local nodes = {}
	for _, node in ipairs(parsedjson) do
		if node and node.Name then nodes[node.Name] = node end
	end

	-- find SoundCue root
	local cue
	for _, node in ipairs(parsedjson) do
		if node.Type == "SoundCue" then cue = node; break end
	end
	if not cue or not cue.Properties or not cue.Properties.FirstNode then
		return SoundScript
	end

	-- populate SoundScript with cue-level properties if available
	local cprops = cue.Properties or {}
	if cprops.MaxDistance then SoundScript.MaxDistance = tonumber(cprops.MaxDistance) end
	if cprops.Duration then SoundScript.Duration = tonumber(cprops.Duration) end
	if cprops.AttenuationSettings then
		SoundScript.Attenuation = cprops.AttenuationSettings.ObjectPath or cprops.AttenuationSettings.ObjectName or cprops.AttenuationSettings
	end
	if cprops.SoundClassObject then
		SoundScript.SoundClass = cprops.SoundClassObject.ObjectPath or cprops.SoundClassObject.ObjectName or cprops.SoundClassObject
	end
	if cprops.ConcurrencySet then
		SoundScript.Concurrency = cprops.ConcurrencySet
	end
	if cprops.ConcurrencyOverrides then
		SoundScript.Concurrency = cprops.ConcurrencyOverrides
	end
	if cprops.Priority then SoundScript.Priority = tonumber(cprops.Priority) end
	-- cue-level volume multiplier (used as initial volume)
	local cueVolMul = tonumber(cprops.VolumeMultiplier or cprops.Volume or 1) or 1

	-- recursive traversal function
	local function TraverseNodeByName(nodeName, curVolume, curPitch, curDelay)
		if not nodeName then return nil end
		local node = nodes[nodeName]
		if not node or not node.Type then return nil end
		local props = node.Properties or {}

		curVolume = tonumber(curVolume) or 1
		curPitch = tonumber(curPitch) or 1
		curDelay = tonumber(curDelay) or 0

		if node.Type == "SoundNodeModulator" then
			local vmin = props.VolumeMin or props.Volume or props.VolumeMultiplier
			local vmax = props.VolumeMax or props.Volume or props.VolumeMultiplier or vmin
			local pmin = props.PitchMin or props.Pitch or props.PitchMultiplier
			local pmax = props.PitchMax or props.Pitch or props.PitchMultiplier or pmin
			if not vmin then vmin = 1 end
			if not vmax then vmax = vmin end
			if not pmin then pmin = 1 end
			if not pmax then pmax = pmin end
			local chosenVol = randBetween(vmin, vmax)
			local chosenPitch = randBetween(pmin, pmax)
			local child = props.ChildNodes and props.ChildNodes[1]
			if child then
				local childName = nodeNameFromObject(child)
				return TraverseNodeByName(childName, curVolume * chosenVol, curPitch * chosenPitch, curDelay)
			end
			return nil

		elseif node.Type == "SoundNodeDelay" then
			local dmin = props.DelayMin or props.Delay or 0
			local dmax = props.DelayMax or props.Delay or dmin
			local chosenDelay = randBetween(dmin, dmax)
			local child = props.ChildNodes and props.ChildNodes[1]
			if child then
				local childName = nodeNameFromObject(child)
				return TraverseNodeByName(childName, curVolume, curPitch, curDelay + chosenDelay)
			end
			return nil

		elseif node.Type == "SoundNodeRandom" then
			local children = props.ChildNodes or {}
			local weights = props.Weights or {}
			if #children == 0 then return nil end
			local idx = weightedChoice(weights)
			if idx < 1 then idx = 1 end
			if idx > #children then idx = #children end
			local chosen = children[idx]
			local childName = nodeNameFromObject(chosen)
			return TraverseNodeByName(childName, curVolume, curPitch, curDelay)

		elseif node.Type == "SoundNodeMixer" then
			local children = props.ChildNodes or {}
			local inputVolume = props.InputVolume or {}
			if #children == 0 then return nil end
			local idx = math.random(1, #children)
			local volMul = 1
			if #inputVolume == #children then
				volMul = tonumber(inputVolume[idx]) or volMul
			elseif #inputVolume == 2 then
				volMul = randBetween(inputVolume[1], inputVolume[2])
			elseif #inputVolume >= 1 then
				volMul = tonumber(inputVolume[1]) or volMul
			end
			local chosen = children[idx]
			local childName = nodeNameFromObject(chosen)
			return TraverseNodeByName(childName, curVolume * volMul, curPitch, curDelay)

		elseif node.Type == "SoundNodeWavePlayer" then
			local asset = nil
			if props.SoundWaveAssetPtr and props.SoundWaveAssetPtr.AssetPathName then
				asset = props.SoundWaveAssetPtr.AssetPathName
			elseif node.SoundWave and node.SoundWave.ObjectPath then
				asset = node.SoundWave.ObjectPath
			end
			if asset and asset ~= "" then
				-- convert to game-file path according to your rules
				local gamePath = unrealToGamePath(asset)
				if gamePath and gamePath ~= "" then
					-- store both raw converted path and Sound() object if available
					local ok, s = pcall(function() return Sound(gamePath) end)
					local looping = false
					if props.bLooping ~= nil then
						looping = (props.bLooping == true)
					elseif node.SoundWave and node.SoundWave.bLooping ~= nil then
						looping = (node.SoundWave.bLooping == true)
					end

					return {
						SoundPath = (ok and s) or gamePath,
						Raw = gamePath,
						Volume = curVolume,
						Pitch = curPitch * 100,
						Delay = curDelay,
						Looping = looping,          -- <-- new field added
					}
				end
			end
			return nil

		else
			-- unknown node: attempt to follow first child
			local child = props.ChildNodes and props.ChildNodes[1]
			if child then
				local childName = nodeNameFromObject(child)
				return TraverseNodeByName(childName, curVolume, curPitch, curDelay)
			end
			return nil
		end
	end

	-- start traversal
	local firstObj = cue.Properties.FirstNode
	local startNodeName = nodeNameFromObject(firstObj)
	local result = TraverseNodeByName(startNodeName, cueVolMul, 1, 0)

	if result then
		SoundScript.Volume = tonumber(result.Volume) or SoundScript.Volume
		SoundScript.Pitch = tonumber(result.Pitch) or SoundScript.Pitch
		SoundScript.Delay = tonumber(result.Delay) or SoundScript.Delay
		-- RawSoundPath (converted)
		SoundScript.RawSoundPath = result.Raw or tostring(result.SoundPath or "")
		-- SoundPath as Sound() object if conversion succeeded above
		SoundScript.SoundPath = result.SoundPath 
	end

	return SoundScript
end

--[[
    Calculates a value from a loaded CurveFloat table based on a normalized time.
    Handles both Linear and Cubic interpolation between keys.
    @param curveName The name of the curve, e.g., "M_Sawshark_DoubleSwingSaw_Curve".
    @param normalizedTime A value between 0.0 and 1.0 representing the progress.
    @returns The calculated float value from the curve.
]]-- 

StellarBlade.ApplyCurveFloat = function(curveName, normalizedTime)
    local curveTable = _G["SB_" .. curveName]
    if not curveTable or not curveTable[1] or not curveTable[1].Properties or not curveTable[1].Properties.FloatCurve then
		print("curveTable not found") 
        return 0
    end

    local keys = curveTable[1].Properties.FloatCurve.Keys
    if not keys or #keys == 0 then return 0 end

    -- If there's only one key, return its value.
    if #keys == 1 then return keys[1].Value end

    -- Clamp the time to be within the curve's bounds.
    normalizedTime = math.Clamp(normalizedTime, keys[1].Time, keys[#keys].Time)

    -- Find the two keys to interpolate between.
    local key1, key2
    for i = 1, #keys - 1 do
        if normalizedTime >= keys[i].Time and normalizedTime <= keys[i + 1].Time then
            key1 = keys[i]
            key2 = keys[i + 1]
            break
        end
    end

    if not key1 or not key2 then return keys[#keys].Value end
    if key1.Time == key2.Time then return key1.Value end

    -- Calculate the alpha for interpolation between the two keys.
    local alpha = (normalizedTime - key1.Time) / (key2.Time - key1.Time)

    if key1.InterpMode == "RCIM_Constant" or key1.InterpMode == "RCIM_None" then
        -- Constant/None interpolation holds the value of the first key.
        return key1.Value
    elseif key1.InterpMode == "RCIM_Linear" then
        return Lerp(alpha, key1.Value, key2.Value)
    elseif key1.InterpMode == "RCIM_Cubic" then
        local t, t2, t3 = alpha, alpha * alpha, alpha * alpha * alpha
        local p0, p1 = key1.Value, key2.Value

        -- Tangents must be scaled by the time difference between the keys.
        local timeDiff = key2.Time - key1.Time
        local m0 = key1.LeaveTangent * timeDiff
        local m1 = key2.ArriveTangent * timeDiff

        -- Cubic Hermite spline interpolation formula.
        local h00 = 2 * t3 - 3 * t2 + 1
        local h10 = t3 - 2 * t2 + t
        local h01 = -2 * t3 + 3 * t2
        local h11 = t3 - t2

        return h00 * p0 + h10 * m0 + h01 * p1 + h11 * m1
    else
        -- Default to linear interpolation if the mode is unknown.
        return Lerp(alpha, key1.Value, key2.Value)
    end
end
--[[
    Converts a linear fraction (0-1) into an eased fraction based on the interp type.
    @param interpType The string identifier from the move table.
    @param fraction The linear progress, typically normalizedTime.
    @returns The eased progress.
]]-- 
StellarBlade.GetEasedFraction = function(interpType, fraction)
    if !interpType then return fraction end
    local key = interpType:gsub("ESBInterpType::", "")
    local easeFunc = EasingFunctions[key] or EasingFunctions["InterpType_Liner"]
    return easeFunc(fraction)
end 

--==============================================================================
-- CORE: Get Interpolated Root Motion Transform
--==============================================================================
--[[
    Parses the root motion data to get the interpolated transform at a specific time.
    It calculates the current frame based on elapsed time and interpolates between
    the two nearest keyframes to ensure smooth movement.

    @param rootMotionTable The imported JSON table for the animation.
    @param startTime The CurTime() when the animation started.
    @returns Vector positionOffset, Angle angleOffset, or nil if data is invalid.
]]-- 
StellarBlade.GetRootMotionTransform = function(rootMotionTable, startTime)
    -- Ensure the root motion table is valid.
    if not rootMotionTable or not rootMotionTable[1] or not rootMotionTable[1].Properties then
        return nil, nil
    end

    local frameRate = rootMotionTable[1].Properties.FrameRate or 30

    local dataArray = rootMotionTable[1].Properties.RootMotionDataArray
    if not dataArray or not dataArray[1] then return nil, nil end

    local transformArray = dataArray[1].TransformArray
    if not transformArray or #transformArray == 0 then return nil, nil end

    local elapsedTime = CurTime() - startTime

    -- Calculate which frame we are on (can be a float).
    local currentFrame = elapsedTime * frameRate
    local frameCount = #transformArray

    -- Determine the two keyframes to interpolate between.
    local frame1_idx = math.floor(currentFrame) + 1
    local frame2_idx = frame1_idx + 1

    -- Prevent indexing out of bounds.
    if frame1_idx > frameCount then frame1_idx = frameCount end
    if frame2_idx > frameCount then frame2_idx = frameCount end

    -- Get the transform data for both frames.
    local transform1 = transformArray[frame1_idx]
    local transform2 = transformArray[frame2_idx]

    if not transform1 or not transform2 then return nil, nil end

    -- Calculate the interpolation alpha (0.0 to 1.0).
    local alpha = currentFrame - (frame1_idx - 1)
    alpha = math.Clamp(alpha, 0, 1)

    -- Extract and interpolate position (Translation).
    -- We negate the Y value to convert from UE's Left-Handed to Source's Right-Handed coordinates.
    local pos1 = Vector(transform1.Translation.X, -transform1.Translation.Y, transform1.Translation.Z)
    local pos2 = Vector(transform2.Translation.X, -transform2.Translation.Y, transform2.Translation.Z)
    local interpolatedPos = LerpVector(alpha, pos1, pos2)

       -- Rotation interpolation (now with quaternion slerp)
    local q1 = transform1.Rotation
    local q2 = transform2.Rotation
    local qInterp = QuaternionSlerp(q1, q2, alpha)

    -- Convert final quaternion to Angle once
    local interpolatedAngle = QuaternionToAngle(qInterp)

    return interpolatedPos, interpolatedAngle
end 

StellarBlade.PickTarget = function(self) 
	local Time = CurTime() 
	-- print("PickTarget",Time) 
	
	local SBAI_ActiveSkill = self.SBAI_ActiveSkill 
	if SBAI_ActiveSkill then 
		if SBAI_ActiveSkill.PickTarget then 
			if !IsValid(SBAI_ActiveSkill.PickTarget) then return end 
			if SBAI_ActiveSkill.PickTarget:Alive() then 
				return SBAI_ActiveSkill.PickTarget 
			end 
		end 
	end 
	
	if !self.SB_PickTargetTime or self.SB_PickTargetTime and Time > self.SB_PickTargetTime then 
		local bestAim, bestDist, FireDir, projStart = -1, 2500 
		local PickTarget = scripted_ents.Get("proj_unreali_skaarjprojectile").PickTarget(self,-1,bestDist) 
		self.SB_PickTarget = PickTarget 
		if SBAI_ActiveSkill then 
			SBAI_ActiveSkill.PickTarget = IsValid(PickTarget) and PickTarget or NULL  
		end 
		return PickTarget 
	else 
		return self.SB_PickTarget 
	end 
end 


StellarBlade.ClearMoveTable = function(self) self.SBAI_MoveStep = { } end 
