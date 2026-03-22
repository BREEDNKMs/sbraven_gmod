-- BUG: function type values are not saverestored 
-- ===== Add these client receivers near the top of the file (or anywhere in shared scope) ===== 

if CLIENT then
    StellarBlade = StellarBlade or {} 
	StellarBlade.NetworkBranchBlocked = false 
    StellarBlade.NetworkedEffects = StellarBlade.NetworkedEffects or {}

    net.Receive("SB_AddEffect", function(len)
        local ent = net.ReadEntity()
        local effectAlias = net.ReadString()
        local networkID = net.ReadString()

        if !IsValid(ent) then return end

        -- store networked info locally; clients can hook into these if needed
        StellarBlade.NetworkedEffects[networkID] = {
            Entity = ent,
            Alias  = effectAlias,
            Time   = CurTime()
        }
		
		StellarBlade.AddEffect(ent,effectAlias) 

        -- Optional client-side hook
        if StellarBlade.OnNetworkAddEffect then
            pcall(StellarBlade.OnNetworkAddEffect, ent, effectAlias, networkID)
        end
    end)

    net.Receive("SB_RemoveEffect", function(len, ent)
        local networkID = net.ReadString()
        local ent = net.ReadEntity()

        if StellarBlade.NetworkedEffects and StellarBlade.NetworkedEffects[networkID] then
            StellarBlade.NetworkedEffects[networkID] = nil
        end

        -- Optional client-side hook
        if StellarBlade.OnNetworkRemoveEffect then
            pcall(StellarBlade.OnNetworkRemoveEffect, ent, networkID)
        end
    end)
end 
-- ===== end client receivers =====

player_manager.AddValidModel( "Raven", "models/alvaroports/SBRavenPM.mdl" ) 
player_manager.AddValidHands( "Raven", "models/alvaroports/SBRavenVM.mdl", 0, "0000000" ) 
list.Set( "PlayerOptionsAnimations", "Raven", { "P_Eve_UIStudio_Default_Start", "P_Eve_UIStudio_Look_ToBody", "P_Eve_UIStudio_Look_Start", "P_Eve_UIStudio_Look_End", "P_Eve_UIStudio_Body_ToLook", "P_Eve_UIStudio_Body_Start", "P_Eve_UIStudio_Body_End" } ) 

local flRescale = 0.42 
local flRescale = 1 

local t_a_shineflare_02 = Material("sprites/t_a_shineflare_02") 
hook.Add("PostPlayerDraw","sbravenpm_coreglow",function(ply) 
	if !IsValid(ply) then return end 
	if !ply:Alive() then return end 
	local attachment = { ["FX_Core_01"] = 8, ["FX_Core_02"] = 4, ["FX_Core_03"] = 2, ["FX_Core_04"] = 2} 
	for attachmentname, scale in pairs(attachment) do 
		local attachmentid = ply:LookupAttachment(attachmentname) 
		if attachmentid > 0 then 
			local Pos = ply:GetAttachment(attachmentid).Pos -- Pos will be used 
			render.SetMaterial(t_a_shineflare_02) 
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
    if layerID != nil and ent.IsValidLayer and ent:IsValidLayer(layerID) then
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
        local sequenceFromOuter = ent:GetSequence() -- keep previous behavior if `seq` exists in outer scope 
        if !sequenceFromOuter or sequenceFromOuter < 0 then
            return false, ent:GetPos(), ent:GetLocalAngles(), false
        end 
		sequence = ent:GetSequence() 
        cycle = ent:GetCycle() 
        playbackRate = ent:GetPlaybackRate() 
        duration = ent:SequenceDuration(sequence) 
    end 

    local flComputedCycleRate = (duration != 0) and (1 / duration) or 0
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
        if deltaPos and weight != 1 then
            deltaPos = deltaPos * weight
        end
        if deltaAng and weight != 1 then
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
		for _,ent in ents.Iterator() do 
			-- if !IsValid(ent) then continue end 
			-- StellarBlade.MaintainMoveTable(ent) 
			if !ent.SBAI_SkillUseCount then ent.SBAI_SkillUseCount = { } end 
			-- also apply root movement on gestures as well 
			for layerID = 0, 15 do 
				if ent:IsValidLayer(layerID) then 
					-- print(layerID) 
					-- print("pre GetIntervalMovement:",SysTime()) 
					local bMoved, newPosition, newAngles, bMoveSeqFinished = GetIntervalMovement(ent,FrameTime(),layerID) -- true, newPosition, newAngles, bMoveSeqFinished 
					-- print(bMoved, newPosition, newAngles, bMoveSeqFinished) 
					-- print("post GetIntervalMovement:",SysTime()) 
					-- print(layerID,bMoved) 
					if bMoved then 
						local moveResult = IterativeHybridMoveLimit(ent, ent:GetPos(), newPosition) 
						ent:SetLocalPos(moveResult.vEndPosition) 
						local angles = ent:GetLocalAngles() 
						ent:SetLocalAngles(Angle(angles.x,newAngles.y,angles.z)) 
						-- newPosition = newPosition - ent:GetPos() 
						-- local newPosition2 = (newPosition/FrameTime()) - ent:GetInternalVariable("basevelocity") 
						-- newPosition = newPosition - ent:GetInternalVariable("basevelocity") 
						-- newPosition = newPosition / FrameTime() 
						-- print("newPosition:",newPosition) 
						-- print("newPosition2:",newPosition2) 
						-- print("basevelocity diff:",newPosition - ent:GetInternalVariable("basevelocity")) 
						
						-- ent:SetSaveValue("basevelocity",newPosition2) 
						-- ent:AddFlags(FL_BASEVELOCITY) 
						-- ent.movePosDelta = self.movePosDelta + newPosition 
						break 
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
	if type(fov) != "number" then fov = 0.5 end

	local dot = facingDir:Dot(los)
	return dot > fov
end

hook.Add("EntityTakeDamage", "StellarBlade_DamageEffects", function(target, dmginfo) 
	local attacker = dmginfo:GetAttacker() 
	local inflictor = dmginfo:GetInflictor() 
	
	if target.SBAI_SkillStep and target.SBAI_SkillStep.Name then 
		local SkillStepTable = target.SBAI_SkillStep.Data 
		local Type = SkillStepTable.Type 
		local Time = target.SBAI_SkillStep.Time -- start time 
		local Duration = SkillStepTable.Duration 
		local EndTime = Time + Duration 
		local SkillResultAlias = SkillStepTable.SkillResultAlias 
		if Type == "ESBSkillActiveStepType::SkillActiveStepType_Parry" then 
		
			-- local TargetFilterAlias = SkillStepTable.OverrideTargetFilterAlias 
			-- if !TargetFilterAlias or TargetFilterAlias == "None" then 
				-- if target.SBAI_SkillTable then TargetFilterAlias = target.SBAI_SkillTable.TargetFilterAlias end -- default to SkillTable 
			-- end 
			if !target.SBAI_SkillTable then return print(target,"there is a skill step but no skilltable") end 
			local TargetFilterAlias = target.SBAI_SkillTable.TargetFilterAlias 
			-- normally collision to AttackedCollisionGroupArray is considered 
			-- but most entities do not provide a consistent collision trace 
			-- it is either bbox or some other vector away from bbox 
			-- sometimes the hit direction isn't even constructed 
			-- so we will just use target filter 
			
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
			if !table.HasValue(tableofhittargets,attacker) then return end 
			local tableofhitvectors = { } 
			table.insert(tableofhitvectors, attacker.GetShootPos and attacker:GetShootPos() or attacker:EyePos()) 
			table.insert(tableofhitvectors, dmginfo:GetReportedPosition()) 
			if IsValid(inflictor) then 
				table.insert(tableofhitvectors, inflictor:EyePos()) 
			end 
			if IsValid(attacker) then 
				table.insert(tableofhitvectors, attacker:EyePos()) 
			end 
			table.insert(tableofhitvectors, dmginfo:GetReportedPosition()) 
			local inViewCone = false 
			local FinalDamagePosition = target:GetPos() 
			for _,DamagePosition in ipairs(tableofhitvectors) do 
				if !DamagePosition:IsZero() and DamagePosition != target:GetPos() then 
					if target:IsNPC() then 
						inViewCone = target:IsInViewCone(DamagePosition) 
					else 
						inViewCone = FInViewCone(target,DamagePosition) 
					end 
					if inViewCone then FinalDamagePosition = DamagePosition break end 
				end 
			end 
	
			if inViewCone then 
				dmginfo:ScaleDamage(0) 
				print("SkillResultAlias:", SkillResultAlias,attacker) 
				if SkillResultAlias != "None" then 
					-- StellarBlade.StartSkillResult(target,dmginfo:GetAttacker(),SkillResultAlias) 
					StellarBlade.StartSkillSelfResult(target,SkillResultAlias,SkillStepTable.bCritical,false) 
					if IsValid(attacker) then 
						StellarBlade.StartSkillTargetResult(attacker,SkillResultAlias,SkillStepTable.bCritical,false) 
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
					sound.EmitHint(SOUND_DANGER+SOUND_COMBAT+SOUND_MOVE_AWAY+SOUND_CONTEXT_REACT_TO_SOURCE,FinalDamagePosition,target:BoundingRadius()*4,Duration,target) 
					
					if attacker.SetCondition then 
						attacker:SetCondition(COND.HEAR_DANGER) 
					end 
					if attacker.SBAI_SkillStep and attacker.SBAI_SkillStep.Type == "ESBSkillActiveStepType::SkillActiveStepType_Hit" then 
						-- force NextStepAliasWhenJustParry 
					
					-- custom parry result data 
					-- for Stellar Blade Actor --> HL2 NPC Interaction 
					elseif attacker:GetClass() == "npc_antlion" then 
						attacker:SetSchedule(ai.GetScheduleID("SCHED_ANTLION_FLIP")) 
					elseif attacker:GetClass() == "npc_antlionguard" then 
						attacker:SetSaveValue("m_nFlinchActivity",util.GetActivityIDByName("ACT_ANTLIONGUARD_CHARGE_CRASH")) 
						attacker:SetSchedule(ai.GetScheduleID("SCHED_ANTLIONGUARD_PHYSICS_DAMAGE_HEAVY")) 
					elseif attacker:GetClass() == "npc_hunter" then 
						attacker:SetCondition(attacker:ConditionID("COND_HUNTER_STAGGERED")) 
					elseif isbool(attacker:GetInternalVariable("m_fIsTorso")) then -- is based on npc_basezombie 
						attacker:SetSchedule(ai.GetScheduleID("SCHED_FLINCH_PHYSICS")) 
						-- at that point, remove attacker's range and melee capabilities for "Duration" seconds 
						-- or until the SBAI_SkillTable is done 
					elseif attacker.SetSchedule and (attacker:SelectWeightedSequence(ACT_SMALL_FLINCH) > 1 or attacker:SelectWeightedSequence(ACT_BIG_FLINCH) > 1) then 
						attacker:SetSchedule(SCHED_BIG_FLINCH) 
					elseif attacker.TaskFail then 
						attacker:TaskFail(tostring(target).. " parried attack") 
						local thinkDelayed = attacker:SetSaveValue("m_flNextDecisionTime",Duration) 
					else 
						local thinkDelayed = attacker:SetSaveValue("m_flNextAttack",Duration) 
						-- local thinkDelayed = attacker:SetSaveValue("m_flNextDecisionTime","Duration") 
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
StellarBlade.ActorState = { } 
StellarBlade.SBAI_ActiveShow = { } 
StellarBlade.SBAI_SkillStep = { } 
StellarBlade.SBAI_SkillTable = { } 
StellarBlade.SB_EffectAlias = { } 
function StellarBlade.ActorState:Remove(effectOrName) 
	-- effectOrName may be nil / table / string
	local t = type(effectOrName)
	local targetName = nil
	if t == "table" then
		targetName = effectOrName.Name
	elseif t == "string" then
		targetName = effectOrName
	end

	-- debug print
	-- print("in ActorState:Remove(", targetName or "<none>", ")")

	-- ensure Users is a table
	self.Users = self.Users or { } 
	-- if an effect was specified: remove any matching entries (by reference first, then by name)
	if effectOrName then
		for i = #self.Users, 1, -1 do
			local u = self.Users[i]
			if u == effectOrName then
				table.remove(self.Users, i)
			elseif type(u) == "table" and targetName and u.Name == targetName then
				table.remove(self.Users, i)
			end
		end
	end

	-- if there are still users, do not remove the state
	if #self.Users > 0 then
		return false
	end
	
	if !self.IsMarkedForDeletion then 
		self.IsMarkedForDeletion = true 
		-- Entity(1):ChatPrint("removing: "..self.Name) 
		local ok, err = pcall(function() 
		
			hook.Remove("Think",self) 
			hook.Remove("EntityTakeDamage",self) 
			hook.Remove("PostEntityTakeDamage",self) 
			hook.Remove("SetupMove",self) -- player only 
			hook.Remove("Move",self) -- player only 
			hook.Remove("FinishMove",self) -- player only 
			hook.Remove("CalcMainActivity",self) -- player only 
			hook.Remove("CalcView",self) -- player only 
			hook.Remove("CalcViewModelView",self) -- player only 
			
			if self.Name == "ESBActorState::ActorState_BlockMove" then 
				if self.SetMoveDelay then self:SetMoveDelay(0) end 
			elseif self.Name == "ESBActorState::ActorState_BlockingBehavior" then 
				if self.Outer:IsPlayer() then 
					self.Outer:Freeze(false) 
				else 
					if self.Outer:IsNPC() then 
						if StellarBlade.IsRaven(self.Outer) then 
						
						else 
						
						end 
					else 
					
					end 
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
		if !ok then print("error within removal:",err) debug.Trace() end 
		
		if self.Outer and self.Outer[self.Name] then
			self.Outer[self.Name] = nil
		end
		return true 
	end 
	return false 
end 

function StellarBlade.ActorState:IsValid() 
	if self.IsMarkedForDeletion then return false end 
	return IsValid(self.Outer) 
end 

function StellarBlade.ActorState:Think() 
	local Outer = self.Outer 
	if self.Name == "ESBActorState::ActorState_BlockRevival" then 
		if Outer.NextSpawnTime then 
			Outer.NextSpawnTime = CurTime() + 1 
		end 
	elseif self.Name == "ESBActorState::ActorState_BlockMove" then -- npc block move 
		if self.SetMoveDelay then self:SetMoveDelay(0.1) end 
	elseif self.Name == "ESBActorState::ActorState_BlockRotation" then 
		if self.Outer.SetEyeAngles then self.Outer:SetEyeAngles(self.CacheAngles) else self.Outer:SetLocalAngles(self.CacheAngles) end 
	elseif self.Name == "ESBActorState::ActorState_Groggy" then 
		if !Outer:IsPlayer() then 
			local Result_State_Groggy_L,ltime = Outer:LookupSequence("Result_State_Groggy_L") -- loop 
			local Result_State_Groggy_S,stime = Outer:LookupSequence("Result_State_Groggy_S") -- start 
			local Result_State_Groggy_E,etime = Outer:LookupSequence("Result_State_Groggy_E") -- exit 
			if Outer:GetSequence() == Result_State_Groggy_S or Outer:GetSequence() == Result_State_Groggy_L then 
				if Outer:IsSequenceFinished() then 
					scripted_ents.Get("cycler_actor2").NPC_StartScriptedActivity(Outer,"Result_State_Groggy_L",true) 
				end 
			end 
		end 
	elseif self.Name == "" then 
		if Outer:IsPlayer() then 
			self:SetSaveValue("m_debugOverlays", bit.band(self:GetInternalVariable("m_debugOverlays"), bit.bnot(33554432))) 
		end 
	end 
end 

function StellarBlade.ActorState:EntityTakeDamage(target,dmginfo) 
	if target == self.Outer then 
		
	end 
end 

function StellarBlade.ActorState:PostEntityTakeDamage(target,dmginfo) 

end 

function StellarBlade.ActorState:SetupMove(target,mv,cmd) -- called only for players 
	if self.Name == "ESBActorState::ActorState_BlockMove" then 
		-- mv:SetVelocity( Vector(100,100,100)) 
	elseif self.Name == "ESBActorState::ActorState_DoubleJump" then 
		local JumpCount = 2 
		if target:GetMoveType() != MOVETYPE_WALK then return end -- don't accidentally jump in noclip 

		-- Step 1: Reset JumpCount when the player touches the ground.
		if target:OnGround() then
			self.JumpCount = 0
		else
			-- Step 2: Handle Air Jumping
			-- Check if the Jump key was *just* pressed (prevent holding)
			if mv:KeyPressed(IN_JUMP) then
				
				-- Initialize JumpCount if it doesn't exist
				self.JumpCount = self.JumpCount or 0
				
				-- Check if we have jumps left.
				-- We subtract 1 from jumpCount because the first jump is the normal ground jump.
				-- So if jumpCount is 2, we allow 1 extra air jump.
				if self.JumpCount < (JumpCount - 1) then
					
					-- The Trick: Make the player think they are on the ground (Entity(0) is the world).
					-- This tricks the CGameMovement::CheckJumpButton logic in the engine to allow the jump.
					-- References gamemovement.cpp: "if (player->GetGroundEntity() == NULL) ... return false;"
					target:SetGroundEntity(Entity(0))
					
					-- Increment the jump counter
					self.JumpCount = self.JumpCount + 1 
					target:DoCustomAnimEvent(PLAYERANIMEVENT_DOUBLEJUMP,0) -- not implemented in GM:DoAnimationEvent but may work later 
					-- mv:SetUpSpeed(500) -- did not work 
					-- mv:SetVelocity(mv:GetVelocity() + Vector(0,0,-mv:GetUpSpeed()*10)) -- did not work for up vel 
					-- mv:SetFinalJumpVelocity(Vector(200,200,200)) -- doesn't work in here 
				end
			end
		end
	end 
end 

function StellarBlade.ActorState:Move(target,mv) -- called only for players 
	if target == self.Outer then 
		if self.Name == "ESBActorState::ActorState_BlockMove" then 
			-- print("in block move:",target) 
			mv:SetForwardSpeed(0) 
			mv:SetSideSpeed(0) 
			mv:SetUpSpeed(0) 
			mv:SetFinalJumpVelocity(vector_origin) 
			-- mv:SetVelocity( vector_origin ) 
		end 
	end 
end 

function StellarBlade.ActorState:FinishMove(target,mv) -- called only for players 
	if self.Name == "ESBActorState::ActorState_BlockMove" then 
		-- print("in FinishMove",self.Name,target,mv) 
		-- mv:SetVelocity( vector_origin ) 
	end 
end 

function StellarBlade.ActorState:CalcMainActivity(ply,vel) -- called only for players 
	-- print(self,self.Outer,ply) 
	if self.Name == "ESBActorState::ActorState_Groggy" and ply == self.Outer then 
		-- Result_State_Groggy_L will be the main sequence 
		-- Groggy_S and Groggy_E will be played as Gesture Sequences, which lay on top of sequence 
		ply.CalcIdeal = ACT_INVALID
		ply.CalcSeqOverride = ply:LookupSequence("Result_State_Groggy_L") 
		return ply.CalcIdeal, ply.CalcSeqOverride 
	end 
end 

function StellarBlade.ActorState:CalcView(ply,origin,angles,fov,znear,zfar) -- called clientside only for players 
	-- print(self,self.Outer,ply) 
	if self.Name == "ESBActorState::ActorState_Groggy" and ply == self.Outer then 
		local origin = ply:GetAttachment(ply:LookupAttachment("eyes")).Pos 
		local angles = ply:GetAttachment(ply:LookupAttachment("eyes")).Ang 
		local view = { 
		origin = origin, 
		angles = angles, 
		fov = fov, 
		drawviewer = false 
		} 
		return view 
	end 
end 

function StellarBlade.ActorState:CalcViewModelView(wep, vm, oldPos, oldAng, pos, ang) -- called clientside only for players 
	-- print(self,self.Outer,ply) 
	if self.Name == "ESBActorState::ActorState_Groggy" and wep:GetOwner() == self.Outer then 
		local Pos = wep:GetOwner():GetAttachment(wep:GetOwner():LookupAttachment("eyes")).Pos 
		local Ang = wep:GetOwner():GetAttachment(wep:GetOwner():LookupAttachment("eyes")).Ang 
		return Pos, Ang 
	end 
end 

function StellarBlade.SBAI_ActiveShow:Remove() 
	self.IsMarkedForDeletion = true 
end 

function StellarBlade.SBAI_ActiveShow:Tick() 
	-- print("ticking:",self.Outer,self) 
	StellarBlade.MaintainShow(self.Outer,self) 
end 

function StellarBlade.SBAI_ActiveShow:IsValid() 
	if !IsValid(self.Outer) then return false end 
	if self.IsMarkedForDeletion then 
		if self.index then 
			table.remove(self.Outer.SBAI_ActiveShows,self.index) 
		end 
		if table.IsEmpty(self.Outer.SBAI_ActiveShows) then self.Outer.SBAI_ActiveShows = nil end 
		return false 
	end 
	return true 
end 

function StellarBlade.SBAI_ActiveShow:Initialize() 
	for k,v in pairs(StellarBlade.SBAI_ActiveShow) do 
		self[k] = v 
	end 
	setmetatable(self,{ 
		__index = function(self,key) 
			if key == "Cycle" then 
				local props = self.SBShowData.Properties 
				local EndTime = props.EndTime or 0 
				
				return math.Clamp((CurTime() - self.Time) / EndTime, 0, 1) 
			end 
		end, 
	__tostring = function(t) return tostring(t.Name).." "..t.Cycle end  

	} ) 
	hook.Add("Tick",self,self.Tick) 
end 

function StellarBlade.SBAI_SkillStep:IsActive() 
	-- print("is active",self.Data.PostStep) 
	-- print("is active",self.Data.PostStepDelay) 
	-- print("is active",CurTime() - self.Time >= self.Data.PostStepDelay) 
	if self.Stopped then return false end 
	if self.IsMarkedForDeletion then return false end 
	if self.Data.PostStep then 
		if self.Data.PostStepDelay != 0 then 
			if CurTime() - self.Time >= self.Data.PostStepDelay then 
				return false 
			end 
		else 
			return false 
		end 
	end 
	if !IsValid(self.Outer) then return false end 
	return true 
end 

function StellarBlade.SBAI_SkillStep:IsValid() 
	if self.IsMarkedForDeletion then return false end 
	if IsValid(self.Outer) and !self.Outer:Alive() then 
		self:Remove() 
	end 
	return IsValid(self.Outer) and self.Outer:Alive() 
end 

function StellarBlade.SBAI_SkillStep:Remove(stopAnimations) 
	self.IsMarkedForDeletion = true 
	pcall(self.OnRemove,self) 
	if IsValid(self.Outer) then 
		self.Outer.SBAI_SkillStep = nil 
	end 
	-- if self.Outer.SBAI_SkillTable then 
		-- self.Outer.SBAI_SkillTable:Remove(stopAnimations) 
	-- end 
end 

function StellarBlade.SBAI_SkillStep:OnRemove() 
	-- clear hooks for now 
	hook.Remove("Think",self) 
	hook.Remove("PostEntityTakeDamage",self) 
end 

function StellarBlade.SBAI_SkillStep:ShouldHitStop(target, dmginfo, wasDamageTaken) 
	if self.Data.PostStep then return true end 
	if self.Data.CanCutoff then return true end 
	if dmginfo:IsDamageType(DMG_BLAST) then return true end 
	if dmginfo:IsDamageType(DMG_SNIPER) then return true end 
	if dmginfo:IsDamageType(DMG_PHYSGUN) then return true end 
	if dmginfo:IsDamageType(DMG_CRUSH + DMG_VEHICLE + DMG_CLUB + DMG_ALWAYSGIB) then 
		if dmginfo:GetDamage() > target:GetMaxHealth() * 0.5 then return true end 
	end 
	return false 
end 

function StellarBlade.SBAI_SkillStep:PostEntityTakeDamage(target, dmginfo, wasDamageTaken) 
	if !self.Data.bIgnoreHitStop then 
		if target == self.Outer and wasDamageTaken and self:ShouldHitStop(target,dmginfo,wasDamageTaken) then 
			-- print("bIgnoreHitStop:",self.Data.bIgnoreHitStop) 
			self:Remove() 
			if target.SBAI_ActiveShows then 
				for k,v in pairs(target.SBAI_ActiveShows) do 
					if v.Remove then 
						v:Remove() 
					else 
						target.SBAI_ActiveShows[k] = nil 
					end 
				end 
			end 
			if target.SBAI_MoveTable then target.SBAI_MoveTable:Remove() end 
			local tableOptional = { } 
			tableOptional.DamageInfo = dmginfo  
			tableOptional.Constructor = IsValid(dmginfo:GetAttacker()) and dmginfo:GetAttacker() or NULL  
			tableOptional.Target = target 
			StellarBlade.CompleteTableOptional(target,tableOptional) 
			StellarBlade.AddEffect(target,"Item_C_GrenadeAreaKnockBack",tableOptional) -- has movealias Item_C_GrenadeAreaKnockBack M_Common_KnockBackWeak
			target:EmitSound("M_Raven_vo_Dmg_S_Cue") 
		end 
	end 
end 

function StellarBlade.SBAI_SkillTable:IsValid() 
	if !IsValid(self.Outer) then return false end 
	if !self.Outer.SBAI_SkillTable then return false end 
	if !self.Outer.SBAI_SkillStep then 
		self:Remove(true) 
		return false 
	end 
	if self.IsMarkedForDeletion then return false end 
	return true 
end 

function StellarBlade.SBAI_SkillTable:Remove(stopAnimations) 
	local Outer = self.Outer 
	self.IsMarkedForDeletion = true 
	-- reset activity to ACT_IDLE 
	if stopAnimations then 
		if Outer.ResetIdealActivity then Outer:ResetIdealActivity(ACT_IDLE) end 
		-- for players, reset attack gesture 
		if Outer:IsPlayer() then 
			Outer:AnimRestartGesture( GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_RESET, true ) 
			BroadcastLua("if IsValid(Entity("..Outer:EntIndex()..")) then Entity("..Outer:EntIndex().."):AnimRestartGesture(0,ACT_RESET,true) end ") 
		end 
	end 
	-- destruct skill table 
	Outer.SBAI_SkillTable = nil 
	-- also destruct skill step table if exists 
end 

function StellarBlade.SBAI_SkillTable:Tick() end 
function StellarBlade.SBAI_SkillTable:Initialize() 
	for k,v in pairs(StellarBlade.SBAI_SkillTable) do 
		self[k] = v 
	end 
	hook.Add("Tick",self, self.Tick) 
end 

function StellarBlade.SB_EffectAlias:Remove() 
	-- if !curEffects[strEffect][chosenIndex] then return end 
	-- if curEffects[strEffect][chosenIndex] != curEffect then return end 
	-- print("called effect remove",CurTime(),curEffect.Name) 
	-- debug.Trace() 
	local strEffect = self.Name 
	local chosenIndex = self.chosenIndex 
	if !self.IsMarkedForDeletion then 
		self.IsMarkedForDeletion = true 
		local tableOptional = tableOptional or self.tableOptional 
		pcall(StellarBlade.OnRemoveEffect,self.Outer,self,tableOptional) -- prevent script being halt on error 
		-- table.remove(curEffects[strEffect],chosenIndex) 
		table.remove(self.Outer.SB_EffectAlias[strEffect],chosenIndex) 
		-- print("removing effect:",strEffect,self) 
	end 
end 
function StellarBlade.SB_EffectAlias:CanActivate() -- passes activation conditions 
	return true 
end 

function StellarBlade.SB_EffectAlias:IsActive() 
	return true 
end 

function StellarBlade.SB_EffectAlias:IsLifeTypeValid() 
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
		if self.LifeTime > 0 and CurTime() > self.EndTime then 
			return false 
		end 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_StepDependent" then
		if !self.Outer.SBAI_SkillStep or self.Outer.SBAI_SkillStep and !self.Outer.SBAI_SkillStep:IsActive() then 
			return false 
		end
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_IndependentTime" then
		if CurTime() > self.EndTime then 
			return false 
		end 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_StanceDependent" then
		-- keep as-is for now
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_CharacterGetupTime" then
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_ProjectileDependent" then
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_BeforeNextSkill" then -- removed after the lifetime, or prior to starting a skill 
		if CurTime() > self.EndTime then 
			return false 
		end 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_CharacterGroggyEndTime" then
		if CurTime() > 5 + self.Time then 
			return false 
		end
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_NextSkillDependent" then
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_LevelSequenceDependent" then
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_EquipmentDependent" then
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_LevelSequenceDependentWithoutPlayable" then
	end 
	return true 
end 

function StellarBlade.SB_EffectAlias:IsValid() -- this is called by the engine every time any hook gets called 
-- if IsValid returns false, the hooks referenced as this table will be destructed 
	if !IsValid(self.Outer) then return false end 
	if self.IsMarkedForDeletion then return false end 
	if !self:IsLifeTypeValid() then 
		self:Remove() 
		return false 
	end 
	return IsValid(self.Outer) 
end 

function StellarBlade.SB_EffectAlias:Think() 
	-- print(self.Outer,strEffect,self.Cycle) -- all of these are valid 
	
	if self.LoopTargetFilterAlias != "None" then 
		for _, target in pairs(StellarBlade.TargetFilter(self.Outer,self.LoopTargetFilterAlias,self.Cycle)) do 
			for k,v in ipairs(self.LoopTargetEffectAliasArray) do 
				if !self.IsNetworkedOrigin then 
					local tableOptional = tableOptional or self.tableOptional 
					-- PrintTable(self.tableOptional) 
					StellarBlade.AddEffect(target,v,tableOptional) 
				end 
			end 
		end 
	end 
	
	if !self.bPlayOnDead then 
		if !self.Outer:Alive() then self:Remove() end 
	end 
	
	if self.bStopOnRevival then 
		if !self.Outer:Alive() then 
			self.OuterDead = true 
		elseif self.OuterDead then -- outerdead was set and outer is alive 
			self:Remove() 
		end 
	end 
end 

function StellarBlade.SB_EffectAlias:EntityTakeDamage(target,dmginfo)	
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
end 

function StellarBlade.SB_EffectAlias:PostEntityTakeDamage(target,dmginfo) -- SERVER only 
	-- 1. Validate Attacker
	local attacker = dmginfo:GetAttacker() 
	if !IsValid(attacker) then return end 

	-- 2. Validate Ownership (CRITICAL)
	-- We must check if the attacker is the actual owner of THIS effect instance (self).
	-- This prevents the hook from firing when other entities deal damage.
	-- Ensure you added 'EffectTable.Outer = self' inside 'StellarBlade.OnAddEffect'
	if attacker != self.Outer then return end 

	-- 3. Execute Logic for THIS effect only
	-- Do NOT loop through 'attacker.SB_EffectAlias'. Use 'self' directly.
	local ConditionChainType = self.ConditionChainType

	local ConditionChainSelfEffectAliasArray = self.ConditionChainSelfEffectAliasArray
	local ConditionChainTargetEffectAliasArray = self.ConditionChainTargetEffectAliasArray
	
	-- Hit Target Logic
	if ConditionChainType == "ESBEffectConditionChainType::EffectConditionChainType_HitTarget" then
		for k, v in ipairs(ConditionChainSelfEffectAliasArray) do
			StellarBlade.AddEffect(attacker, v, tableOptional)
		end
		
		for k, v in ipairs(ConditionChainTargetEffectAliasArray) do
			StellarBlade.AddEffect(target, v, tableOptional)
		end
	end
	
	-- Dead Target Logic
	if ConditionChainType == "ESBEffectConditionChainType::EffectConditionChainType_DeadTarget" and !target:Alive() then
		for k, v in ipairs(ConditionChainSelfEffectAliasArray) do
			StellarBlade.AddEffect(attacker, v, tableOptional)
		end
		
		for k, v in ipairs(ConditionChainTargetEffectAliasArray) do
			StellarBlade.AddEffect(target, v, tableOptional)
		end
	end
end 

function StellarBlade.SB_EffectAlias:Initialize(tableOptional) 
	-- print("self:",self) 
	local StartDelayTime = self.StartDelayTime 
	setmetatable(self,{ __index = function(self,key) 
		if key == "Cycle" then 
			if self.LifeType == "ESBEffectLifeType::EffectLifeType_IndependentTime" then
				-- (Current Time - Start Time) / Total Duration
				return math.Clamp((CurTime() - self.Time) / self.LifeTime, 0, 1)
			end
		end 
	end } ) 
	for k,v in pairs(StellarBlade.SB_EffectAlias) do 
		self[k] = v 
	end 
	local function Activate() 
		hook.Add("Think",self,self.Think) 
		hook.Add("EntityTakeDamage",self,self.EntityTakeDamage) 
		hook.Add("PostEntityTakeDamage",self,self.PostEntityTakeDamage) 
		-- fully initialized 
		StellarBlade.OnAddEffect(self.Outer,self,tableOptional) 
	end 
	if StartDelayTime == 0 or self.IsNetworkedOrigin then 
		Activate() 
	else 
		hook.Add("Think",self,function() 
			if CurTime() >= self.Time + StartDelayTime then 
				self.EndTime = CurTime() + self.LifeTime 
				self.Time = CurTime() 
				Activate() -- the hook.Add in Activate() will override this hook pointer 
			end 
		end ) 
	end 
end 

-- Minimal parser: returns a plain array table 
-- Input is a string like "[{\"Alias\":\"HitStun\", \"Time\":1.5}, {\"Alias\":\"KnockDownForward_Eve\"}, {\"Alias\":\"KnockDownBackward_Eve\"}]" 
-- Output is: { 
-- [1] = { ["Alias"] = "HitStun", ["Time"] = 1.5 } 
-- [2] = { ["Alias"] = "KnockDownForward_Eve" } 
-- [3] = { ["Alias"] = "KnockDownBackward_Eve" } } 
StellarBlade.ParseTableStrings = function(t) 
	if !t then error("no input to ParseTableStrings") end 

    local t2 = t

    if type(t) == "string" then
        t2 = util.JSONToTable(t)
        if type(t2) != "table" then return t end
    end

    -- If passed a single effect object (table with Alias) convert to array
    if type(t2) == "table" and t2.Alias != nil and t2[1] == nil then
        t2 = { t2 }
    end

    local out = {}

    for i, entry in ipairs(t2) do
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

if SERVER then 
	util.AddNetworkString("SB_AddEffect") 
	util.AddNetworkString("SB_RemoveEffect") 
end 

StellarBlade.AddEffect = function(self, strEffect, tableOptional, ...) 
	-- print("adding effect:",strEffect) 
	-- if tableOptional then PrintTable(tableOptional) end 
	if strEffect then 
		if strEffect == "DownFaceUP" then strEffect = "DownFaceUp" end 
	end 
    local EffectTable = scripted_ents.Get("npc_sb_raven").SBAI_GetEffectTable(self, strEffect) 
    if !EffectTable then error("EffectTable not found for "..strEffect) end 
	if !EffectTable then 
		for keyEffect,valEffect in pairs(SB_EffectCombinationTable[1].Rows) do 
			if keyEffect == "strEffect" then 
			
			end 
		end 
	end 
	
	if !StellarBlade.CanAddEffect(self, strEffect, EffectTable, tableOptional) then return false end 
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
		-- If there is already an instance, merge into the first one.
		if #curEffects[strEffect] >= 1 then
			chosenIndex = 1
			local exist = curEffects[strEffect][chosenIndex]
			
			-- BLACKLIST: Numeric keys here will Overwrite instead of Add
			local NoSumKeys = {
				["CalculationMultipleValue"] = true,
				["CalculationMultipleWhenBacksideHit"] = true
			}

			-- Merge numeric values: add numbers; otherwise override/assign
			for k, v in pairs(newInstance) do
				if k == "Time" then continue end
				local ev = exist[k]
				
				-- Only add if it's a number AND not in our blacklist
				if type(v) == "number" and type(ev) == "number" and !NoSumKeys[k] then
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
			if curEffects[strEffect][1].Remove then 
				curEffects[strEffect][1]:Remove() 
			else 
				StellarBlade.SB_EffectAlias.Remove(curEffects[strEffect][1]) 
			end 
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
	-- print(getmetatable(curEffect)) 
	-- print(getmetatable(curEffect).__index) 
	-- getmetatable(curEffect).__index = function(self,key) end 

    -- timestamp / lifetime anchor 
	local StartDelayTime = curEffect.StartDelayTime 
	curEffect.IsNetworkedOrigin = false 
	curEffect.IsMarkedForDeletion = false 
	curEffect.Name = strEffect 
	curEffect.Outer = self 
	curEffect.chosenIndex = chosenIndex 
    curEffect.EndTime = CurTime() + curEffect.LifeTime + StartDelayTime 
    curEffect.Time = CurTime() 
	if tableOptional and tableOptional.TraceResult then 
		curEffect.TraceResult = tableOptional.TraceResult 
	end 
	if tableOptional then curEffect.tableOptional = tableOptional end 
	if CLIENT then
        local stack_level = 0
        while true do
            local info = debug.getinfo(stack_level, "S")
            if !info then break end

            if info.short_src then
                local filename = string.GetFileFromFilename(info.short_src)
                -- If we find net.lua, this effect is a ROOT Networked effect.
                if filename == "net.lua" then
                    curEffect.IsNetworkedOrigin = true
                    break
                end
            end
            stack_level = stack_level + 1
        end
    end
	-- Generate a unique network identifier for this effect instance and store it
    local netID = "SBFX_" .. tostring(CurTime()) .. "_" .. tostring(math.random(0, 1e9))
    curEffect.NetworkID = netID

    -- store mapping on EffectTable for lookup by network identifier (optional)
    -- EffectTable._NetworkedInstances = EffectTable._NetworkedInstances or {}
    -- EffectTable._NetworkedInstances[netID] = curEffect

    -- Broadcast to all clients that a new effect has been added (ignore varargs/tableOptional per request)
    if SERVER then
        -- ensure netstrings exist (pcall used earlier)
        net.Start("SB_AddEffect")
            net.WriteEntity(self)        -- the affected entity
            net.WriteString(strEffect)   -- effect alias
            net.WriteString(netID)       -- unique id for this instance
        net.Broadcast()
    end
    -- Process vararg key/value pairs and write into chosen instance
    local args = { ... }
    local n = #args
    for i = 1, n, 2 do
        local key = args[i]
        local val = args[i + 1]
        if key != nil then
            -- try to convert numeric-like strings to numbers
            if type(val) == "string" then
                local num = tonumber(val)
                if num != nil then
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
	StellarBlade.SB_EffectAlias.Initialize(curEffect,tableOptional) 
    -- Optionally return chosenIndex and curEffect for caller convenience
    return chosenIndex, curEffect
end

StellarBlade.ApplyEffectAction = function(self,EffectTable,Action,ActionValue) 
	ParsedActionValue = StellarBlade.ParseTableStrings(ActionValue) 
	if Action == "ESBEffectAction::EffectAction_None" then 
	
	elseif Action == "ESBEffectAction::EffectAction_SkillCancel" then 
		-- print("calling EffectAction_SkillCancel") 
		if self.SBAI_SkillStep then self.SBAI_SkillStep:Remove() end 
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
	elseif Action == "ESBEffectAction::EffectAction_AdditiveSkillCommandCoolTime" then -- unused 
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
		local Pos = self:GetPos() -- Cache the location the player had died last time 
		self:Spawn() 
		self:SetPos(Pos) -- Teleport to cached pos 
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
	elseif Action == "ESBEffectAction::EffectAction_UseSkill" then -- Scarlet only 
		StellarBlade.StartSkill(self,ActionValue) 
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

StellarBlade.CanAddEffect = function(self, strEffect, EffectTable, tableOptional) -- EffectTable is the table of effect index, i.e. M_Raven_BackJumpCombo_HitWave_Damage 
	
	-- if the incoming effect is from network initially, permit 
	-- if the incoming effect is not networked (directly added), permit effect processing as usual 
	-- if the incoming effect roots from a networked effect, block children of root effect 
	if CLIENT then
        -- If we are currently running code inside an effect that originated from the network,
        -- we block any further AddEffect calls (branching).
        if StellarBlade.NetworkBranchBlocked then
            return false 
        end
    end
	
	if !EffectTable.bPlayOnDead then 
		if !self:Alive() then return false end 
	end 
	
	local CHECK_TRUE  = "ESBConditionCheckType::ConditionCheckType_True"
	local CHECK_FALSE = "ESBConditionCheckType::ConditionCheckType_False"
	local CHECK_NONE  = "ESBConditionCheckType::ConditionCheckType_None"

	-- map condition-field -> evaluator(function returns boolean)
	local conditionEvaluators = {
		ConditionActive_Swimming = function()
			return (self:WaterLevel() or 0) > 0
		end,
		ConditionActive_UnderWater = function()
			return (self:WaterLevel() or 0) > 2
		end,
		ConditionActive_Airborne = function()
			return self:IsFlagSet(FL_FLY)
		end,
		ConditionActive_Jump = function()
			return !self:IsOnGround()
		end,
		ConditionActive_BattleMode = function()
			local st = self.GetNPCState and self:GetNPCState() or 1 
			return (st > 1) and (st < 3)
		end,
	}

	-- iterate the remapping table instead of writing separate if/else checks
	for Condition, evaluator in pairs(conditionEvaluators) do
		local desired = EffectTable[Condition]
		-- skip if not present or explicitly NONE
		if !desired or desired == CHECK_NONE then
			-- skip check
		else
			local ok, actual = pcall(evaluator)
			if !ok then actual = false end -- defensive: evaluator failed -> treat as false

			if desired == CHECK_TRUE and !actual then
				return false
			end
			if desired == CHECK_FALSE and actual then
				return false
			end
		end
	end
	
	-- 2) ActorState checks (Active / Deactive) via remapping lists
    local actorActiveFields = {
        "ConditionActive_ActiveActorState1",
        "ConditionActive_ActiveActorState2",
        "ConditionActive_ActiveActorState3",
    }
    local actorDeactiveFields = {
        "ConditionActive_DeactiveActorState1",
        "ConditionActive_DeactiveActorState2",
        "ConditionActive_DeactiveActorState3",
    } 

    -- Active actor states: proceed only if the referenced self[field] exists
    for _, f in ipairs(actorActiveFields) do
        local stateKey = EffectTable[f]
        if stateKey and stateKey != "ESBActorState::ActorState_None" then
            local val = self[key] 
            if val == nil then
                -- required active state is not present on self -> cannot add effect
                return false
            end
        end
    end

    -- Deactive actor states: proceed only if the referenced self[field] is NOT present
    for _, f in ipairs(actorDeactiveFields) do
        local stateKey = EffectTable[f]
        if stateKey and stateKey != "ESBActorState::ActorState_None" then
            local val = self[key] 
            if val != nil then
                -- required deactive state is present on self -> cannot add effect
                return false
            end
        end
    end
	
	-- check whether the effects in CheckNoneEffectAliasArray do not exist in actor's ef table 
	for _, EffectInstances in ipairs(EffectTable.ConditionActive_CheckNoneEffectAliasArray) do 
		-- print("checking for effect instances:",EffectInstances,CurTime()) 
		if self.SB_EffectAlias and self.SB_EffectAlias[EffectInstances] then 
			-- print("found effect already bound:",EffectInstances,self.SB_EffectAlias[EffectInstances],CurTime()) 
			if !table.IsEmpty(self.SB_EffectAlias[EffectInstances]) then 
				-- print("returning false",CurTime()) 
				return false 
			end 
		end 
	end 
	
	-- -------------------------------------------------------------------------
    -- IMMUNITY CHECK (New Implementation)
    -- -------------------------------------------------------------------------
    local EffectGroupName = EffectTable.EffectGroupName

    -- Only proceed if the incoming effect actually belongs to a specific group
    if EffectGroupName != "None" and EffectGroupName != "" and self.SB_EffectAlias then
        
        -- Iterate over every Effect Name currently on the character
        for activeEffectName, effectInstances in pairs(self.SB_EffectAlias) do
            
            -- Iterate over every Instance of that Effect
            for _, activeInstance in pairs(effectInstances) do
                
                -- Check if this active instance provides any immunities
                if activeInstance.ImmuneEffectGroupArray then
                    
                    -- Loop through the immunity list
                    for _, immuneGroup in ipairs(activeInstance.ImmuneEffectGroupArray) do
                        
                        -- If the active effect grants immunity to the incoming effect's group
                        if immuneGroup == EffectGroupName then
                            -- Debug output to confirm immunity triggered (Optional)
                            -- print("Effect blocked: " .. strEffect .. " (" .. EffectGroupName .. ") blocked by " .. activeEffectName)
                            return false
                        end
                    end
                end
            end
        end
    end
	
	if tableOptional and IsValid(tableOptional.Constructor) then -- KnockDownForward_Eve - KnockDownBackward_Eve 
		local ConditionActive_MinAngleFromConstructor = math.NormalizeAngle(EffectTable.ConditionActive_MinAngleFromConstructor) 
		local ConditionActive_MaxAngleFromConstructor = math.NormalizeAngle(EffectTable.ConditionActive_MaxAngleFromConstructor) 
		if ConditionActive_MinAngleFromConstructor != 0 and ConditionActive_MaxAngleFromConstructor != 0 then 
			local Ang = tableOptional and tableOptional.TraceResult and tableOptional.TraceResult.HitNormal:GetNormalized():Angle() or self:WorldToLocalAngles((tableOptional.Constructor:GetPos() - self:GetPos()):GetNormalized():Angle()) 
			if ConditionActive_MinAngleFromConstructor < Ang.y or ConditionActive_MaxAngleFromConstructor > Ang.y then 
				return false 
			end 
		end 
	end 

	-- other generic checks could go here...

	return true
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
	local MaxStamina = StellarBlade.ActorStats(ent)["ESBActorStatType::ActorStatType_MaxStamina"] 
	local Stamina = StellarBlade.ActorStats(ent)["ESBActorStatType::ActorStatType_Stamina"] 
	return math.Clamp(CalculationValue + StatValue,0,MaxStamina) 
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
	-- print("CalculationValue:",CalculationValue,"StatValue:",StatValue) 
	return StatValue + (StatValue * (CalculationValue / 100)) 
end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_EffectAttackPower"] = function(ent,CalculationValue,StatValue) 
	-- print("called EffectAttackPower",ent,CalculationValue,StatValue) 
	print("calculating EffectAttackPower",ent) 
	local AttackPower = ent.PhysicAttackPower 
	if !AttackPower then 
		if StellarBlade.IsRaven(ent) then 
			ent.PhysicAttackPower = scripted_ents.Get("npc_sb_raven").PhysicAttackPower 
			AttackPower = ent.PhysicAttackPower 
		else 
			AttackPower = 100 
		end 
	end 
	if ent.SBAI_SkillTable then AttackPower = AttackPower + ent.SBAI_SkillTable.AttackDamageRate end 
	return StatValue + (CalculationValue * AttackPower) 
end 

ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_MaxShieldRate"] = function(ent,CalculationValue,StatValue) 
	local maxShield = 0

	-- 1. Try Standard GMod Max Armor
	if ent.GetMaxArmor then
		maxShield = ent:GetMaxArmor()
		
	-- 2. Try Internal Max Shield Variable
	elseif ent.MaxShield then
		maxShield = ent.MaxShield
		
	-- 3. Default Fallback
	else
		maxShield = 100 
	end

	-- Calculate amount based on percentage (e.g., 100.0 becomes 1.0 multiplier)
	-- This returns the MAGNITUDE of shield to be applied.
	local rate = (CalculationValue) / 100.0
	return maxShield * rate
end 

ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_HealStatic"] = function(ent,CalculationValue,StatValue) return ent:Health() >= ent:GetMaxHealth() and ent:Health() or math.min(CalculationValue+StatValue,ent:GetMaxHealth()) end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_HealMaxHPRate"] = function(ent,CalculationValue,StatValue) return 0 end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_CurrentTachyGaugeRate"] = function(ent,CalculationValue,StatValue) return 0 end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_SetStatValue"] = function(ent,CalculationValue,StatValue) return CalculationValue end 
ESBEffectCalculationType["ESBEffectCalculationType::EffectCalculationType_MaxStaminaRate"] = function(ent,CalculationValue,StatValue) 
	local maxStamina = 0 
    
    -- Check Entity Var -> Proxy Getter -> Default 
    if ent.MaxStamina then 
        maxStamina = ent.MaxStamina 
    else 
        maxStamina = 100 -- Default fallback 
    end 

    local rate = CalcValue / 100.0 
    return maxStamina * rate 
end 
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
        if ent.Armor then
            return ent:Armor()
        end
        return rawget(proxy, "ESBActorStatType::ActorStatType_Shield") or 0
    end,
	
	["ESBActorStatType::ActorStatType_MaxShieldValue"] = function(proxy)
        local ent = proxy.Outer
        if ent.GetMaxArmor then
            return ent:GetMaxArmor()
        end
        return rawget(proxy, "ESBActorStatType::ActorStatType_MaxShieldValue") or 0
    end,

	["ESBActorStatType::ActorStatType_MaxShieldRate"] = function(proxy)
        local ent = proxy.Outer
        if ent.GetMaxArmor then
            return ent:GetMaxArmor() / 100 -- modify 100 to actual max shield value 
        end
        return rawget(proxy, "ESBActorStatType::ActorStatType_MaxShieldRate") or 0
    end,

    ["ESBActorStatType::ActorStatType_MinimumHP"] = function(proxy)
        -- store as percent (e.g. 75 means 75%)
        return rawget(proxy, "ESBActorStatType::ActorStatType_MinimumHP") or 0
    end,
	
	["ESBActorStatType::ActorStatType_HitDefenseLevel"] = function(proxy)
        return rawget(proxy, "ESBActorStatType::ActorStatType_HitDefenseLevel") or 0
    end,
	
	["ESBActorStatType::ActorStatType_Stamina"] = function(proxy) 
		if proxy.Outer["ESBActorStatType::ActorStatType_Stamina"] then 
			return proxy.Outer["ESBActorStatType::ActorStatType_Stamina"] 
		end 
        return rawget(proxy, "ESBActorStatType::ActorStatType_Stamina") or 0
    end,
	
	["ESBActorStatType::ActorStatType_MaxStamina"] = function(proxy)
		-- 1. Check entity level variable first (External)
		local Outer = proxy.Outer 
		if IsValid(Outer) then 
			if StellarBlade.IsRaven(Outer) then 
				if Outer.MaxStamina then
					return proxy.Outer.MaxStamina
				else 
					return scripted_ents.Get("npc_sb_raven").MaxStamina 
				end 
			end 
		end 
		-- 2. Fallback to internal table
		return rawget(proxy, "ESBActorStatType::ActorStatType_MaxStamina") or 1
	end,
	
	["TraceResult"] = function(proxy) -- default return if no trace result 
		return {Entity = proxy.Outer, Fraction = 0.99, Hit = true, HitBox = 0, HitNoDraw = false, HitNonWorld = true, HitNormal = -proxy.Outer:GetForward(), HitPos = proxy.Outer:GetPos(), Normal = -proxy.Outer:GetForward(), StartPos = vector_origin} 
    end 
    -- add other getters as needed
}

-- setters: called whenever someone writes proxy["key"] = value (or via __call)
local statSetters = {
	["ESBActorStatType::ActorStatType_None"] = function(proxy, value)
        return 0 
    end,
	
	["ESBActorStatType::ActorStatType_HP"] = function(proxy, value)
		-- prefer actual engine health for truth (fallback to stored)
		local ent = proxy.Outer -- entity that has the effect applied 
		print("constructor is:",proxy.Constructor) 
		local requestedHP = math.floor(value) 
		local curHP = ent:Health() 

		-- If drain-by-attack is enabled, apply the *difference* as damage via the damage system
		if proxy.bDrainHpByAttack then 
			local dmginfo = proxy.DamageInfo 
			if !dmginfo then 
				dmginfo = DamageInfo() 
			end 
			local damageToDeal = curHP - requestedHP 
			-- print("damageToDeal:",damageToDeal) 
			-- print("curHP:",curHP) 
			-- print("requestedHP:",requestedHP) 

			if damageToDeal > 0 then 
				dmginfo:SetDamage(damageToDeal) 

				-- allow custom damage type, fallback to DMG_GENERIC
				local dmgType = proxy.DrainHpByAttackDamageType or DMG_GENERIC 
				-- if ent.IsKratos then dmginfo:SetDamageType(DMG_BLAST) end 
				-- print("applying damage:",dmginfo) 
				ent:DispatchTraceAttack(dmginfo, proxy.TraceResult) 
				return
			elseif damageToDeal < 0 then
				-- requestedHP > curHP -> healing: clamp to max
				local maxhp = ent:GetMaxHealth() 
				ent:SetHealth(math.Clamp(requestedHP,-1,maxhp)) 
				return
			else
				-- no change
				return 
			end 
		end 

		-- default behavior (no drain-by-attack) 
		ent:SetHealth(requestedHP) 
		return rawget(proxy, "ESBActorStatType::ActorStatType_HP") 
	end, 

    ["ESBActorStatType::ActorStatType_MaxHP"] = function(proxy, value)
        local ent = proxy.Outer
        -- try to use engine setter if present, otherwise store it
        if IsValid(ent) then
            ent:SetMaxHealth(value)
        end
        -- rawset(proxy, "ESBActorStatType::ActorStatType_MaxHP", value)
    end,

	["ESBActorStatType::ActorStatType_MaxHPValue"] = function(proxy, value)
        local ent = proxy.Outer
        -- try to use engine setter if present, otherwise store it
        if IsValid(ent) then
            ent:SetMaxHealth(value)
        end
        -- rawset(proxy, "ESBActorStatType::ActorStatType_MaxHP", value)
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
    end,

    ["ESBActorStatType::ActorStatType_Shield"] = function(proxy, value)
		-- print("ESBActorStatType::ActorStatType_Shield",value) 
		local ent = proxy.Outer
		if ent.SetArmor then
			ent:SetArmor(math.floor(value))
		else 
			rawset(proxy, "ESBActorStatType::ActorStatType_Shield", value) 
		end 
    end,

    ["ESBActorStatType::ActorStatType_MinimumHP"] = function(proxy, value)
        -- store percent floor
        -- rawset(proxy, "ESBActorStatType::ActorStatType_MinimumHP", value)
    end,
	
	["ESBActorStatType::ActorStatType_HitDefenseLevel"] = function(proxy, value)
        rawset(proxy, "ESBActorStatType::ActorStatType_HitDefenseLevel", value)
    end,
	
	["ESBActorStatType::ActorStatType_Stamina"] = function(proxy, value) 
		local Outer = proxy.Outer 
		local MaxStamina = proxy["ESBActorStatType::ActorStatType_MaxStamina"] or 1 
		Outer["ESBActorStatType::ActorStatType_Stamina"] = math.min(value,MaxStamina) 
        -- rawset(proxy, "ESBActorStatType::ActorStatType_Stamina", math.min(value,MaxStamina)) 
    end, 
	
	["ESBActorStatType::ActorStatType_MaxStamina"] = function(proxy, value)
		-- 1. Update entity variable (External)
		if proxy.Outer then 
			proxy.Outer.MaxStamina = value
		else rawset(proxy, "ESBActorStatType::ActorStatType_MaxStamina", value)
		end 
	end
    -- add other setters as needed
}

-- __index: return stored value if present, otherwise use statGetters mapping
statProxyMT.__index = function(self, key) 
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

-- Utility: create/ensure proxy for an entity 
-- use this to lookup ESBActorStat fields on any entity 
-- it will create a template ESBActorStatType table and assign to entity 
function StellarBlade.ActorStats(ent,forceReset) 
    if !IsValid(ent) then error("Tried to use NULL Entity!") end
    if ent.ESBActorStatType and getmetatable(ent.ESBActorStatType) == statProxyMT and !forceReset then
        return ent.ESBActorStatType
    end

    local proxy = {} 
    proxy.Outer = ent 
    setmetatable(proxy, statProxyMT) 
	if StellarBlade.IsRaven(ent) then 
		-- setup properties for first time setup 
		-- ESBActorStatType::ActorStatType_Stamina 
		proxy["ESBActorStatType::ActorStatType_Stamina"] = proxy["ESBActorStatType::ActorStatType_MaxStamina"] 
	end 
    ent.ESBActorStatType = proxy 
    return proxy 
end 

StellarBlade.OnAddEffect = function(self,EffectTable,tableOptional) 
	local StatType = EffectTable.StatType 
	local StatCalculationType = EffectTable.StatCalculationType 
	local StatCalculationTarget = EffectTable.StatCalculationTarget 
	local CalculationValue = EffectTable.CalculationValue 
	local CalculationMultipleValue = EffectTable.CalculationMultipleValue 
	-- print("tableOptional is:",tableOptional) 
	if StatCalculationTarget == "ESBEffectCalculationTarget::EffectCalculationTarget_Constructor" then 
		StatCalculationTarget = tableOptional and tableOptional.Constructor or self 
	elseif StatCalculationTarget == "ESBEffectCalculationTarget::EffectCalculationTarget_Target" then 
		StatCalculationTarget = tableOptional and tableOptional.Target or self 
	else 
		StatCalculationTarget = self 
	end 
	
	local ActorStats = StellarBlade.ActorStats(self) 
	ActorStats.bDrainHpByAttack = EffectTable.bDrainHpByAttack 
	local attribute = ActorStats[StatType] 
	-- local meta = getmetatable(ActorStats) 

	if tableOptional and tableOptional.DamageInfo then 
		ActorStats.DamageInfo = tableOptional.DamageInfo 
		ActorStats.TraceResult = tableOptional.TraceResult 
	end 
	
	-- print("attribute is:",attribute) 
	if attribute then 
		-- StellarBlade.ActorApplyStat = function(self,StatType,StatCalculationType,CalculationMultipleValue,CalculationValue) 
		attribute = attribute * CalculationMultipleValue 
		-- calculate using ESBEffectCalculationType 
		local calculatedattribute = ESBEffectCalculationType[StatCalculationType](StatCalculationTarget,CalculationValue,attribute) 
		-- print("calculatedattribute is:",calculatedattribute,StatCalculationType,CalculationValue,attribute,StatType) 
		-- print("StatCalculationTarget is:",StatCalculationTarget) 
		
		-- calculate previous 
		EffectTable.previousactorstat = calculatedattribute - attribute 
		-- print(EffectTable.previousactorstat) 
		-- now apply calculated property 
		ActorStats[StatType] = calculatedattribute 
		hook.Run("SB_ActorStatChanged",self,StatType,attribute,ActorStats[StatType]) 
	end 

    StellarBlade.AddMoveStep(self, EffectTable.MoveAlias) 
	local ActiveShowPath = EffectTable.ActiveShowPath 
	StellarBlade.SetShow(self,ActiveShowPath) 
	
	-- ActiveTargetEffectAliasArray, ActiveTargetResultShowPath 
	local ActiveTargetFilterAlias = EffectTable.ActiveTargetFilterAlias 
	local ActiveTargetEffectAliasArray = EffectTable.ActiveTargetEffectAliasArray 
	local ActiveTargetResultShowPath = EffectTable.ActiveTargetResultShowPath 
	if ActiveTargetResultShowPath != "" or !table.IsEmpty(ActiveTargetEffectAliasArray) then 
		for k,Target in ipairs(StellarBlade.TargetFilter(self,ActiveTargetFilterAlias)) do 
			if ActiveTargetResultShowPath != "" then 
				StellarBlade.SetShow(Target,ActiveTargetResultShowPath) 
			end 
			
			if !table.IsEmpty(ActiveTargetEffectAliasArray) then 
				for k,v in ipairs(ActiveTargetEffectAliasArray) do 
					if !EffectTable.IsNetworkedOrigin then 
						StellarBlade.AddEffect(Target,v,tableOptional) 
					end 
				end 
			end 
		end 
	end 
	
	-- Process dispel flags: curEffect.DispelFlagsArray may be an array of strings/flags
    local DispelFlagsArray = EffectTable.DispelFlagsArray
    if !table.IsEmpty(DispelFlagsArray) then
        -- local toRemoveAliases = {}
        for _, dispFlag in ipairs(DispelFlagsArray) do
            if !dispFlag then continue end
            -- iterate over all effect aliases present on the entity
            for existName, existInstances in pairs(self.SB_EffectAlias) do
                if existName != strEffect then -- don't remove the effect we just added
                    -- existInstances is an array of instance tables
                    for _, existInstance in ipairs(existInstances) do
                        local existFlag = existInstance and existInstance.Flag
                        if existFlag == dispFlag or existName == dispFlag then 
							if existInstance.Remove then 
								existInstance:Remove() 
							else 
								StellarBlade.SB_EffectAlias.Remove(existInstance) 
							end 
                            -- toRemoveAliases[existName] = true
                            -- break
                        end
                    end
                end
            end
        end
    end 

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
		StellarBlade.ActorApplyState(self,ActorState,DelayActorState,EffectTable) 
		if ActorState != "ESBActorState::ActorState_None" then 
		-- BroadcastLua("if IsValid(Entity("..self:EntIndex()..")) then StellarBlade.ActorApplyState(Entity("..self:EntIndex().."),'"..ActorState.."',"..DelayActorState..") end") 
		end 
	end 
end 

hook.Add("SB_ActorStatChanged","statprinter",function(self,StatType,oldvalue,newvalue) 

	if IsValid(self) then 
		if StatType == "ESBActorStatType::ActorStatType_Stamina" then 
			if oldvalue > 0 and newvalue == 0 then 
				if StellarBlade.IsRaven(self) then 
					local EffectAliasWhenZeroStaminaArray = self.EffectAliasWhenZeroStaminaArray or scripted_ents.Get("npc_sb_raven").EffectAliasWhenZeroStaminaArray 
					for k,v in ipairs(EffectAliasWhenZeroStaminaArray) do 
						StellarBlade.AddEffect(self,v) 
					end 
				else 
				
				end 
			end 
		end 
	end 

end) 

StellarBlade.OnRemoveEffect = function(self,EffectTable,tableOptional) 
	local StatType = EffectTable.StatType 
	local StatCalculationType = EffectTable.StatCalculationType 
	local CalculationValue = EffectTable.CalculationValue 
	
	local attribute = StellarBlade.ActorStats(self)[StatType] 
	if EffectTable.bStatRestore and EffectTable.previousactorstat then 
		StellarBlade.ActorStats(self)[StatType] = StellarBlade.ActorStats(self)[StatType] - EffectTable.previousactorstat 
		hook.Run("SB_ActorStatChanged",self,StatType,attribute,StellarBlade.ActorStats(self)[StatType]) 
	end 
	
	local DeactiveTargetFilterAlias = EffectTable.DeactiveTargetFilterAlias 
	local DeactiveTargetEffectAliasArray = EffectTable.DeactiveTargetEffectAliasArray 
	local DeactiveTargetResultShowPath = EffectTable.DeactiveTargetEffectAliasArray 
	if DeactiveTargetResultShowPath != "" or !table.IsEmpty(DeactiveTargetResultShowPath) then 
		for k,Target in ipairs(StellarBlade.TargetFilter(self,DeactiveTargetFilterAlias)) do 
			if DeactiveTargetResultShowPath != "" then 
				StellarBlade.SetShow(Target,DeactiveTargetResultShowPath) 
			end 
			
			if !table.IsEmpty(DeactiveTargetEffectAliasArray) then 
				for k,v in ipairs(DeactiveTargetEffectAliasArray) do 
					if !EffectTable.IsNetworkedOrigin then 
						StellarBlade.AddEffect(Target,v,tableOptional) 
					end 
				end 
			end 
			
		end 
	end 
	
	for k,EffectAlias in ipairs(EffectTable.ChainEffectAliasArray) do 
		if !EffectTable.IsNetworkedOrigin then 
			StellarBlade.AddEffect(self,EffectAlias,tableOptional) 
		end 
	end 
	
	-- cleanup ActorState (1-5) 
	for idx = 1, 10 do 
		local ActorState = "ActorState"..idx 
		local DelayActorState = "DelayActorState"..idx 
		ActorState = EffectTable[ActorState] 
		DelayActorState = EffectTable[DelayActorState] 
		if self[ActorState] then
			local st = self[ActorState]
			-- print("calling ActorState:Remove() ", ActorState, EffectTable.Name)
			local ok, res = pcall(function() 
				if st.Remove then 
					return st:Remove(EffectTable) 
				else -- function type values aren't saverestored 
					st = nil 
				end 
				
			end) 
			if !ok then
				print("ActorState.Remove failed:", res,EffectTable.Name)
			else
				-- print("removal status:", ok, res)
			end
			-- print("post ActorState.Remove")
		end
	end 
	hook.Remove("Think",EffectTable) 
	hook.Remove("EntityTakeDamage",EffectTable) 
	hook.Remove("PostEntityTakeDamage",EffectTable) 
end 

-- Updated AddEffectFromTable to accept the plain array table produced by ParseTableStrings
StellarBlade.AddEffectFromTable = function(self, tblEffect, tableOptional) 
    if type(tblEffect) != "table" then error("table expected, got",type(tblEffect))  end

    for _, v in ipairs(tblEffect) do
        if type(v) == "table" and v.Alias then
            -- build vararg list from all keys except Alias
            local args = {}
            for k, val in pairs(v) do
                if k != "Alias" then
					if k == "Time" then k = "LifeTime" end 
					if k == "startDelayTime" then k = "StartDelayTime" end 
                    table.insert(args, k)
                    -- convert numeric-like strings to numbers (to match ParseTableStrings behavior)
                    if type(val) == "string" then
                        local num = tonumber(val)
                        if num != nil then
                            val = num
                        end
                    end
                    table.insert(args, val)
                end
            end

            -- call AddEffect passing unpacked args
            StellarBlade.AddEffect(self, v.Alias, tableOptional, unpack(args)) 
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
					if inst.Remove then 
						inst:Remove() 
					else 
						StellarBlade.SB_EffectAlias.Remove(inst) 
					end 
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

StellarBlade.ActorApplyState = function(self,ActorState,DelayActorState,EffectTable) 
	-- lookup whether the state is set in character's table 
	if !StellarBlade.CanActorApplyState(self,ActorState) then return false end 
	if !self[ActorState] then 
		self[ActorState] = {["Name"] = ActorState} 
		local ActorState = self[ActorState] 
		ActorState.Time = CurTime() 
		ActorState.Outer = self 
		ActorState.IsMarkedForDeletion = false 
		ActorState.Users = { } 
		if EffectTable then
            table.insert(ActorState.Users, EffectTable)
        end 
		
		for k,v in pairs(StellarBlade.ActorState) do 
			ActorState[k] = v 
		end 
		
		hook.Add("Think",ActorState,ActorState.Think) 
		hook.Add("EntityTakeDamage",ActorState,ActorState.EntityTakeDamage) 
		hook.Add("PostEntityTakeDamage",ActorState,ActorState.PostEntityTakeDamage) 
		hook.Add("SetupMove",ActorState,ActorState.SetupMove) -- player only 
		hook.Add("Move",ActorState,ActorState.Move) -- player only 
		hook.Add("FinishMove",ActorState,ActorState.FinishMove) -- player only 
		hook.Add("CalcMainActivity",ActorState,ActorState.CalcMainActivity) -- player only 
		hook.Add("CalcView",ActorState,ActorState.CalcView) -- clientside player only 
		hook.Add("CalcViewModelView",ActorState,ActorState.CalcViewModelView) -- clientside player only 
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
			ActorState.CacheAngles = self.GetEyeAngles and self:GetEyeAngles() or self:GetAngles() 
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
				if self:IsNPC() then 
					if StellarBlade.IsRaven(self) then -- npc_sb_raven or baseclasses 
					
					else 
						self:SetSaveValue("m_flNextDecisionTime",10) 
					end 
				else 
				
				end 
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
			if self:IsPlayer() then 
				self:SetSaveValue("m_debugOverlays", bit.bor(self:GetInternalVariable("m_debugOverlays"), 33554432))
			end 
		-- ActorState_BlockJump                     = 28,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockJump" then 
		-- ActorState_BlockHPRegen                  = 29,
		elseif ActorState.Name == "ESBActorState::ActorState_BlockHPRegen" then 
		-- ActorState_BattleMode                    = 30,
		elseif ActorState.Name == "ESBActorState::ActorState_BattleMode" then 
			if self.SetNPCState then 
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
			-- for Eve: Enable player's double jump ability 
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
			self:SetActiveWeapon(NULL) 
			if self.SetNPCState then self:SetNPCState(1) end 
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
		end  
	else 
		-- state exists - add EffectTable to Users if provided
        if EffectTable then
            local s = self[ActorState]
            if not s.Users then s.Users = {} end

            -- add only if not already tracked (first check by reference, then by name)
            local already = false
            for _, u in ipairs(s.Users) do
                if u == EffectTable then
                    already = true
                    break
                elseif type(u) == "table" and u.Name and EffectTable.Name and u.Name == EffectTable.Name then
                    already = true
                    break
                end
            end
            if not already then
                table.insert(s.Users, EffectTable)
            end
        end
    end

    return true
end 

StellarBlade.ActorApplyStat = function(self,StatType,StatCalculationType,CalculationMultipleValue,CalculationValue) 

	
end 

StellarBlade.CanStartSkill = function(self,SkillName) 
	local CheckCooldown = self.SBAI_SkillTimers and self.SBAI_SkillTimers[SkillName] -- returns Time, ["M_Raven_SlashChain"] = 216 
	local UsableCount = self.SBAI_SkillUseCount and self.SBAI_SkillUseCount[SkillName] -- returns Time, ["M_Raven_SlashChain"] = 216 
	local SkillTable = SB_SkillTable[1].Rows[SkillName] 
	if SkillTable.UsableCount > 0 and UsableCount and UsableCount > SkillTable.UsableCount then 
		Entity(1):ChatPrint(SkillName.." not activated, max amount used "..tostring(SkillTable.UsableCount)) 
		return false 
	end 
	
	if self["ESBActorState::ActorState_BlockSkill"] then return false end 
	if !CheckCooldown or CheckCooldown and CurTime() >= CheckCooldown then 
		return true 
	end 
	
	return false 
end 

StellarBlade.StartSkill = function(self,SkillName) 
	local Realm = SERVER and " SERVER" or " CLIENT" 
	local SkillTable = SB_SkillTable[1].Rows[SkillName] 
	if StellarBlade.CanStartSkill(self,SkillName) then 
		self.SBAI_SkillTable = table.Copy(SkillTable) 
		local SBAI_SkillTable = self.SBAI_SkillTable 
		SBAI_SkillTable.Outer = self 
		local FirstSkillActiveAlias = SkillTable.FirstSkillActiveAlias 
		local target 
		-- This now correctly handles all the data-driven setup for the first step 
		if FirstSkillActiveAlias == "M_Raven_BetaSkillCounter_Cast1" then 
			target = self:GetEyeTrace().Entity 
			local _PickTarget = StellarBlade.PickTarget 
			StellarBlade.PickTarget = function() return self end 
			local success = StellarBlade.SetSkillStep(target,"P_Eve_BetaCounterRaven1_Cast1") 
			StellarBlade.PickTarget = _PickTarget 
			StellarBlade.AddEffect(self,"BlockAction",{Constructor = self, Target = target, TraceResult = self:GetEyeTrace()}, "StartDelayTime",0, "LifeTime",7) 
			-- return success 
		elseif FirstSkillActiveAlias == "M_Raven_ShieldBreakerCounter_Cast1" then 
			target = self:GetEyeTrace().Entity 
			local _PickTarget = StellarBlade.PickTarget 
			StellarBlade.PickTarget = function() return self end 
			local success = StellarBlade.SetSkillStep(target,"P_Eve_ShieldBreakerCounterRaven1_Cast1") 
			StellarBlade.PickTarget = _PickTarget 
			StellarBlade.AddEffect(self,"BlockAction",{Constructor = self, Target = target, TraceResult = self:GetEyeTrace()}, "StartDelayTime",0, "LifeTime",7) 
		else 
			local bSkillStep = StellarBlade.SetSkillStep(self,FirstSkillActiveAlias) 
			if !bSkillStep then 
				Entity(1):ChatPrint("skill start failed for ".. FirstSkillActiveAlias) 
				if self.SBAI_SkillStep then self.SBAI_SkillStep:Remove() end 
				return false 
			else 
				if !IsFirstTimePredicted() then -- in SINGLEPLAYER, doesn't call for CLIENT. 
				BroadcastLua("if IsValid(Entity("..self:EntIndex()..")) then StellarBlade.SetSkillStep(Entity("..self:EntIndex().."),'"..FirstSkillActiveAlias.."') end") 
				end 
				Entity(1):ChatPrint("starting "..SkillName.." at CurTime:"..tostring(CurTime())..Realm) 
			end 
		end 
		if !self.SBAI_SkillTimers then self.SBAI_SkillTimers = { } end 
		if !self.SBAI_SkillUseCount then self.SBAI_SkillUseCount = { } end 
		self.SBAI_SkillTimers[SkillName] = CurTime() + SkillTable.CoolTime 
		self.SBAI_SkillUseCount[SkillName] = self.SBAI_SkillUseCount[SkillName] or 1 
		
		StellarBlade.SBAI_SkillTable.Initialize(self.SBAI_SkillTable) 
		
		if IsValid(target) then 
			target.SBAI_SkillTable = SBAI_SkillTable 
			target.SBAI_SkillTable.Outer = target 
			hook.Add("Tick",target.SBAI_SkillTable, target.SBAI_SkillTable.Tick) 
		end 
		
		return true 
	end 
	return false 
end 

StellarBlade.StartSkillCommand = function(self,SkillName) 
	local SkillCommandTable = SB_SkillCommandTable[1].Rows[SkillName] 
	local SkillAlias = SkillCommandTable.SkillAlias 
	if self["ESBActorState::ActorState_BlockSkill"] then return false end 
	return StellarBlade.StartSkill(self,SkillAlias) 
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

StellarBlade.IsRaven = function(self) 
	if self:IsPlayer() and self:GetModel() == "models/alvaroports/sbravenpm.mdl" then 
		return true 
	end 
	if !self:IsPlayer() and (scripted_ents.IsBasedOn(self:GetClass(),"npc_sb_raven") or self:GetClass() == "npc_sb_raven") then 
		return true 
	end 
	return false 
end 

StellarBlade.SetShow = function(self,showpath,slot) 
	if !showpath then return false end 
	if #showpath == 0 then return false end 
	if !string.find(showpath,"data_static") then -- append correct path if setshow has been directly called 
		showpath = "data_static/SB/Content/Art/Show/"..showpath..".json" 
	end 
	SB_ImportJSON(showpath) 
	if !self.SBAI_ActiveShows then 
		self.SBAI_ActiveShows = {} 
	end 
	local SBAI_ActiveShow = {["Time"] = CurTime(),["RunTime"] = CurTime()} 
	-- self.SBAI_ActiveShow = {["Time"] = CurTime(),["RunTime"] = CurTime(), ["Cycle"] = 0} 
	SBAI_ActiveShow.Dir = showpath 
	local showname = string.GetFileFromFilename( showpath ) 
	showname = string.StripExtension(showname) 
	SBAI_ActiveShow.Name = showname 
	SBAI_ActiveShow.Frame = 0 
	SBAI_ActiveShow.Stopped = false 
	SBAI_ActiveShow.Outer = self 
	SBAI_ActiveShow.IsMarkedForDeletion = false 
	SBAI_ActiveShow.Slot = slot or "" 
	local showname = "SB_" .. SBAI_ActiveShow.Name 
	local showdata = _G[showname] 
	StellarBlade.SBAI_ActiveShow.Initialize(SBAI_ActiveShow) 
	-- if !showdata then return end 
	-- hook.Add("Tick",SBAI_ActiveShow,SBAI_ActiveShow.Tick) 
	
	-- cache some data paths to decrease loops 
	SBAI_ActiveShow.index = table.insert(self.SBAI_ActiveShows,SBAI_ActiveShow) 
	for _, SBShowData in pairs(showdata) do 
		-- print(SBShowData) 
		if istable(SBShowData) and SBShowData.Type == "SBShowData" then 
			SBAI_ActiveShow.SBShowData = SBShowData 
			break 
		end 
	end 

	-- local props = showEntry.Properties
	-- local endTime = props.EndTime or 0 
	
	showname = "SB_"..showname 
	-- self:SBAI_MaintainShow() 
	-- scripted_ents.Get("npc_sb_raven").SBAI_MaintainShow(self) 
	StellarBlade.MaintainShow(self,SBAI_ActiveShow) 
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
	showEntry = SBAI_ActiveShow.SBShowData 

	local props = showEntry.Properties
	local endTime = props.EndTime or 0 

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
		if isbool(SBAI_ActiveShow.TriggeredKeys[data.Name]) or istable(SBAI_ActiveShow.TriggeredKeys[data.Name]) and SBAI_ActiveShow.TriggeredKeys[data.Name].Stopped then
			continue
		end

		-- Mark as triggered
		SBAI_ActiveShow.TriggeredKeys[data.Name] = true 
		-- Entity(1):ChatPrint("SBShowAnimKey: Triggered "..data.Name.." at time: "..(CurTime() - SBAI_ActiveShow.Time)) 
		
		if props.CheckShowKeyTag or props.CheckNoneShowKeyTag then 
			local ShowKeyTagMap = StellarBlade.ShowKeyTagMap(self) 
			if props.CheckShowKeyTag then -- check whether the tag exists, i.e. TachyNPC 
				local succeeded = false 
				for k,v in ipairs(props.CheckShowKeyTag) do 
					for k2,v2 in ipairs(ShowKeyTagMap) do 
						if v == v2 then 
							succeeded = true 
							break 
						end 
					end 
				end 
				if !succeeded then continue end 
			end 
			
			if props.CheckNoneShowKeyTag then -- check whether the tag doesn't exist, i.e. NoReactionSlug 
				local succeeded = true 
				for k,v in ipairs(props.CheckNoneShowKeyTag) do 
					for k2,v2 in ipairs(ShowKeyTagMap) do 
						if v == v2 then 
							succeeded = false 
							break 
						end 
					end 
				end 
				if !succeeded then continue end 
			end 
		end 
		
		local IsBattle = props.IsBattle 
		if IsBattle then 
			if StellarBlade.IsBattle(self) then -- player holding weapon, npc has enemy 
				if IsBattle == "ESBConditionCheckType::ConditionCheckType_False" then continue end 
			else 
				if IsBattle == "ESBConditionCheckType::ConditionCheckType_True" then continue end 
			end 
		end 
		
		local bEnable = props.bEnable 
		if bEnable == false then continue end 
		
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
		if !duration or duration <= 0 then
			-- last until show end
			-- EndAt is the elapsed-time in show where it should end
			local EndAt = endTime
			SBAI_ActiveShow.ScheduledEndKeys[data.Name] = { EndAt = EndAt, Data = data }
			-- If we already passed EndAt, end immediately
			if SBAI_ActiveShow.Elapsed >= EndAt then
				-- immediate end
				if !SBAI_ActiveShow.EndedKeys[data.Name] then
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
				if !SBAI_ActiveShow.EndedKeys[data.Name] then
					SBAI_ActiveShow.EndedKeys[data.Name] = true
					HandleShowKeyEnd(data)
					SBAI_ActiveShow.ScheduledEndKeys[data.Name] = nil
				end
			end
		end
		
		-- === Handle key types ===
		if data.Type == "SBShowAnimKey" then 
			local Target = props.Target or "ESBShowActorTarget::ShowActorTarget_MainActor"
			local bCheckHitLevel = props.bCheckHitLevel 
			local CustomAnim = props.CustomAnim 
			local MeshSlot = props.MeshSlot 
			
			if isstring(MeshSlot) then continue end -- if you see this key value pair, the anim is intended for wings. ignore wing anims in gmod.
			
			-- ==========================================
			-- 1. HIT DIRECTION & ACTIVE ANGLE CALCULATION
			-- ==========================================
			local localYaw = 0
			-- Fallback target acquisition to calculate the angle from the attacker
			local attacker = self.LastAttacker or self.GetEnemy and IsValid(self:GetEnemy()) and self:GetEnemy() or StellarBlade.PickTarget(self)
			-- local attacker = Entity(1)
			
			if IsValid(attacker) then
				local dir = (attacker:GetPos() - self:GetPos()):GetNormalized()
				-- In Source Engine, +Yaw is Left, -Yaw is Right, 0 is Front, 180/-180 is Back
				localYaw = self:WorldToLocalAngles(dir:Angle()).yaw 
			end

			-- Check if this specific AnimKey is allowed to play based on hit angle
			local shouldPlay = true
			if props.CheckActiveType == "ESBShowAnimCheckActiveType::SelfForwardVectorAndSelfToTargetAngle" then
				local activeMin = props.ActiveMinAngle or -180
				local activeMax = props.ActiveMaxAngle or 180
				local inAngle = (localYaw >= activeMin and localYaw <= activeMax)
				
				-- Inverse logic for hits coming from OUTSIDE the frontal cone
				if props.InverseCheckActiveResult then 
					inAngle = not inAngle 
				end
				shouldPlay = inAngle
			end

			-- If this AnimKey shouldn't trigger from this angle, skip to the next JSON object
			if not shouldPlay then continue end

			-- ==========================================
			-- 2. DYNAMIC RESOURCE PATH SELECTION
			-- ==========================================
			local rawAnimPath = props.AnimResourcePath
			
			if props.AnimSequencePlayType == "ESBShowAnimSequencePlayType::UseAreaDirectionCheck" or props.AnimSequencePlayType == "ESBShowAnimSequencePlayType::DirectionalAnimation" then
				if localYaw >= -45 and localYaw <= 45 then
					rawAnimPath = props.FrontAnimResourcePath
				elseif localYaw > 45 and localYaw < 135 then
					rawAnimPath = props.LeftAnimResourcePath
				elseif localYaw < -45 and localYaw > -135 then
					rawAnimPath = props.RightAnimResourcePath
				else
					rawAnimPath = props.BackAnimResourcePath
				end
			end
			
			-- Sanitize path (e.g., "Animation/Result_Hit_Stand_Light_Bw.Result_Hit_Stand_Light_Bw" -> "Result_Hit_Stand_Light_Bw")
			local AnimResourcePath = nil
			if rawAnimPath then
				-- Get file name with extension, then strip the duplicate class extension often present in UE4 outputs
				AnimResourcePath = string.StripExtension(string.GetFileFromFilename(rawAnimPath))
			end

			-- ==========================================
			-- 3. ANIMATION PLAYBACK LOGIC
			-- ==========================================
			local GESTURE_SLOT = GESTURE_SLOT_ATTACK_AND_RELOAD 
			if CustomAnim and CustomAnim == "ESBCharacterCustomAnim::ESBCharacterCustomAnim_HitStandLight1Back" then 
				GESTURE_SLOT = GESTURE_SLOT_VCD 
			end 

			if AnimResourcePath then 
				if Target == "ESBShowActorTarget::ShowActorTarget_MainActor" then 
					Target = self 
				elseif Target == "ESBShowActorTarget::ShowActorTarget_OtherActor" then 
					Target = StellarBlade.PickTarget(self) 
				end 
				
				if IsValid(Target) then 
					if Target:IsPlayer() then 
						Target:AddVCDSequenceToGestureSlot(GESTURE_SLOT, Target:LookupSequence(AnimResourcePath), 0, true) 
						if CustomAnim then 
							Target:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, 0, 0, true) 
						end 
						BroadcastLua("if IsValid(Entity("..Target:EntIndex()..")) then Entity("..Target:EntIndex().."):AddVCDSequenceToGestureSlot("..GESTURE_SLOT..","..Target:LookupSequence(AnimResourcePath)..",0,true) end") 
					else 
						local animSequence = Target:LookupSequence(AnimResourcePath) 
						print("AnimResourcePath",AnimResourcePath) 
						if !animSequence then break end 
						if animSequence != ACT_INVALID then 
							if scripted_ents.Get("cycler_actor2").NPC_IsSequenceLayered(Target,animSequence) then 
								Target:SetLayerPlaybackRate(Target:AddGestureSequence(animSequence,true),0.5) 
							else 
								scripted_ents.Get("npc_sb_raven").NPC_StartScriptedActivity(Target, AnimResourcePath, true) 
							end 
						end 
					end 
				end 
			end 

			-- ==========================================
			-- 4. LEGACY HL2 NPC FLINCH/REACTION SUPPORT
			-- ==========================================
			if bCheckHitLevel then -- heuristic to distinguish "flinches" from active "attacks"
				if self.SetCondition then 
					self:SetCondition(COND.HEAR_DANGER) 
				end 
				if self.SBAI_SkillStep and self.SBAI_SkillStep.Type == "ESBSkillActiveStepType::SkillActiveStepType_Hit" then 
					-- force NextStepAliasWhenJustParry 
				
				-- custom parry result data 
				-- for Stellar Blade Actor --> HL2 NPC Interaction 
				elseif StellarBlade.IsRaven(self) then continue 
				elseif self:GetClass() == "npc_antlion" then 
					self:SetSchedule(ai.GetScheduleID("SCHED_ANTLION_FLIP")) 
				elseif self:GetClass() == "npc_antlionguard" then 
					self:SetSaveValue("m_nFlinchActivity",util.GetActivityIDByName("ACT_ANTLIONGUARD_CHARGE_CRASH")) 
					self:SetSchedule(ai.GetScheduleID("SCHED_ANTLIONGUARD_PHYSICS_DAMAGE_HEAVY")) 
				elseif self:GetClass() == "npc_hunter" then 
					self:SetCondition(self:ConditionID("COND_HUNTER_STAGGERED")) 
				elseif isbool(self:GetInternalVariable("m_fIsTorso")) then 
					self:SetSchedule(ai.GetScheduleID("SCHED_FLINCH_PHYSICS")) 
				elseif self.SetSchedule and (isnumber(self:SelectWeightedSequence(ACT_SMALL_FLINCH)) and (self:SelectWeightedSequence(ACT_SMALL_FLINCH) > 1 or self:SelectWeightedSequence(ACT_BIG_FLINCH) > 1)) then 
					-- self:SetSchedule(SCHED_BIG_FLINCH) 
				elseif self.TaskFail then 
					self:TaskFail(tostring(Target).. " parried attack") 
					local thinkDelayed = self:SetSaveValue("m_flNextDecisionTime", 3) 
				else 
					local thinkDelayed = self:SetSaveValue("m_flNextAttack", 3) 
				end 
			end 
		elseif data.Type == "SBShowActorKey" then 
			local bUseActorHidden = props.bUseActorHidden 
			if isstring(bUseActorHidden) then 
				bUseActorHidden = tobool(bUseActorHidden) 
			-- Apply immediately (no timer here; revert is scheduled via ScheduledEndKeys above)
				-- print("hidden is:",bUseActorHidden) 
				ApplyRenderState(self, bUseActorHidden)

			-- (previous timer.Simple revert removed because we now schedule end above)
			-- The ScheduledEndKeys / HandleShowKeyEnd will revert when duration/endTime is reached. 
			end 


		elseif data.Type == "SBShowSoundKey" or data.Type == "SBShowCharSESoundKey" then 
			local Channel = data.Type == "SBShowSoundKey" and nil or nil 
			local cachedState = SBAI_ActiveShow.TriggeredKeys[data.Name]
			if istable(cachedState) and cachedState.SoundScript then
				-- We have a cached script. Only check the time.
				if SBAI_ActiveShow.Elapsed >= cachedState.TriggerTime then
					local SoundScript = cachedState.SoundScript
					local Target = cachedState.Target

					if IsValid(Target) then 
						print("SoundScript.SoundPath:",SoundScript.SoundPath) 
						Target:EmitSound(SoundScript.SoundPath, 100, SoundScript.Pitch, SoundScript.Volume, Channel)
					end 
					-- print("EMITTING SOUND") 
					
					-- Mark as fully complete (boolean true) so the main loop skips this key next time
					SBAI_ActiveShow.TriggeredKeys[data.Name] = true
				end
			-- If time isn't reached yet, we do nothing and return.
			-- This skips all the intense string manipulation below.

			else
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
					if !StellarBlade.IsRaven(self) then 
						-- print("not raven",self) 
						continue 
					end 
					local key = props.CharacterReactKey or props.CharacterVoiceKey or props.CharacterHitKey 
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
					CuePath = "data_static/SB/Content" .. CuePath
					CuePath = string.StripExtension(CuePath) .. ".json"

					local SoundScript = StellarBlade.BuildSoundScript(self,CuePath) 
					if SoundScript then 
						local Delay = SoundScript.Delay or 0
						local TriggerTime = StartTime + Delay

						-- Logic: If there is a delay and we haven't reached it, CACHE everything.
						if Delay > 0 and SBAI_ActiveShow.Elapsed < TriggerTime then
							SBAI_ActiveShow.TriggeredKeys[data.Name] = {
								SoundScript = SoundScript,   -- Cache the heavy table
								TriggerTime = TriggerTime,   -- Cache the calculated time
								Target      = TargetForCharacterVoice -- Cache the target (optional, but saves IsValid checks)
							}
							-- Note: We leave TriggeredKeys as a TABLE. 
							-- The main loop check `istable(...)` must allow this to continue processing next frame.
						else 
							print("SoundScript.SoundPath:",SoundScript.SoundPath) 
							TargetForCharacterVoice:EmitSound(SoundScript.SoundPath, 100, SoundScript.Pitch, SoundScript.Volume, Channel) 
							-- print("EMITTING SOUND") 
						end
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
				Duration = duration,
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
				if !IsValid(ent) then return end
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
					if animData.RecoverValue != nil then
						timer.Simple(animData.RecoverWaitTime or 0, function()
							if not IsValid(self) or not IsValid(targetEnt) then return end
							if SBAI_ActiveShow != currentShow then return end

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
			if data.Properties and data.Properties.NiagaraSystem and data.Properties.NiagaraSystem.NiagaraSystemPath then 
				AssetName = string.GetExtensionFromFilename(data.Properties.NiagaraSystem.NiagaraSystemPath.AssetPathName) 
			end 
			if AssetName then 
				local CustomTimeDilation = data.Properties.CustomTimeDilation 
				local SocketName = data.Properties.SocketName -- attachment 
				local bAttach = data.Properties.bAttach -- parent status, add flags 1 
				local ParticleScale = data.Properties.ParticleScale 
				local bUseTargetEquipment = data.Properties.bUseTargetEquipment 
				local RelativeLocation = data.Properties.RelativeLocation 
				local RelativeRotation = data.Properties.RelativeRotation 
				local bPosOnly = data.Properties.bPosOnly 
				
				ParticleScale = ParticleScale and ParticleScale * 10 or 10 
				if RelativeLocation then -- convert to proper Vector table 
					RelativeLocation = Vector(RelativeLocation.X,RelativeLocation.Y,RelativeLocation.Z) * flRescale 
				end 
				local relAng = angle_zero
				if RelativeRotation then -- convert to proper Angle table 
					relAng = Angle(RelativeRotation.Pitch or 0, RelativeRotation.Yaw or 0, RelativeRotation.Roll or 0)
				end 
				if bPosOnly then 
					-- relAng = Angle(relAng.x,relAng.y-90,relAng.z) 
				end 
				
				local ef = EffectData() 
				local EffectEntity = bUseTargetEquipment and self.GetActiveWeapon and IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon() or self 
				
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
				
				if !foundBoneID or foundBoneID == 0 then
					local fallbackBoneName = "RootSocket"
					local boneID, boneEntity = nil, nil

					-- try the effect entity (weapon) first
					if EffectEntity.LookupBone then
						local bid = EffectEntity:LookupBone(fallbackBoneName)
						if bid and bid != -1 then
							boneID = bid
							boneEntity = EffectEntity
						end
					end

					-- then try the actor/player (self)
					if (not boneID or boneID == -1) and IsValid(self) and self.LookupBone then
						local bid = self:LookupBone(fallbackBoneName)
						if bid and bid != -1 then
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
				-- print("found bone ID:",foundBoneID,SocketName,EffectEntity) 
					
				if RelativeLocation then 
					-- LocalToWorld(localPos, localAng, originPos, originAng) 
					local finalPos, finalAng = LocalToWorld(RelativeLocation, angle_zero, worldPos, worldAng) 
					worldPos, worldAng = finalPos, finalAng 
				end 
				ef:SetAngles(relAng) 
				ef:SetEntity(EffectEntity) 
				ef:SetMagnitude(data.Properties.Duration or 0) -- use as effect timer 
				ef:SetOrigin(worldPos) -- contains finalized position 
				ef:SetScale(ParticleScale) -- scale 
				ef:SetStart(RelativeLocation and RelativeLocation or vector_origin) 
				util.Effect(AssetName,ef) 
				Entity(1):ChatPrint(SBAI_ActiveShow.Name.. " "..AssetName.. " "..SBAI_ActiveShow.Elapsed.." "..tostring(CurTime()).. " "..tostring(relAng)) 
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
				-- print("object path is:",ObjectPath) 
				ObjectPath = string.sub(ObjectPath,7) 
				ObjectPath = "data_static/SB/Content/"..ObjectPath..".json" 
				-- print("updated object path is:",ObjectPath) 
				StellarBlade.SetShow(self,ObjectPath) 
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
			if !props.bFireImpulse then continue end

			-- Compute blast origin
			local rel = props.RelativeLocation or { X = 0, Y = 0, Z = 0 }
			local origin = self:GetPos() + self:GetForward() * (rel.X or 0)
			origin = origin + self:GetRight() * (rel.Y or 0)
			origin = origin + self:GetUp() * (rel.Z or 0)

			local radius = props.Radius or 300
			local impulse = props.ImpulseStrength or 500
			local velChange = props.bImpulseVelChange or false
			local destructDmg = props.DestructibleDamage or 0
			local dmgRadius = props.DestructibleCheckRadius or radius
			local ignoreOwner = props.bIgnoreOwningActor or false

			local dir = Vector(0, 0, 1) 

			-- Debug
			Entity(1):ChatPrint(string.format("[SBAI-ShowData] RadialForce blast at %s (R=%.0f, Impulse=%.0f)", tostring(origin), radius, impulse))

			-- Find nearby entities
			local affected = ents.FindInSphere(origin, radius)
			for _, ent in ipairs(affected) do
				if not IsValid(ent) then continue end
				if ignoreOwner and ent == self then continue end

				-- Compute direction and strength falloff
				local dirVec = (ent:GetPos() + ent:OBBCenter() - origin)
				local dist = dirVec:Length()
				dirVec = dirVec:GetNormalized()
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
					dmginfo:SetAttacker(IsValid(self) and self or ent) 
					dmginfo:SetInflictor(IsValid(self) and self or self) 
					dmginfo:SetDamageType(DMG_BLAST) 
					dmginfo:SetDamageForce(dirVec * strength * 30) 

					-- Simulated trace
					local tr = util.TraceLine({
						start = origin,
						endpos = ent:GetPos() + ent:OBBCenter(),
						filter = self
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
			SBAI_ActiveShow = SBAI_ActiveShow.Name or showName
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
					if SBAI_ActiveShow != showName then
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
		if SBAI_ActiveShow.Remove then SBAI_ActiveShow:Remove() end 
		-- Optional: cleanup or callback here 
		-- self:SetNoDraw(false) 
		return
	end
end 

StellarBlade.ProcessActiveSkill = function(self,tbl) 
	-- if !tbl then print(self,"ProcessActiveSkill was called without tbl, skill may have removed during execution") return debug.Trace() end 
	if !tbl then return false end 
    local Name = tbl.Name 
    if !Name then return end 
    local SkillStepTable = tbl.Data 
    if !SkillStepTable then return end 
	local Time = tbl.Time -- start time 
	local Duration = SkillStepTable.Duration 
	local EndTime = Time + Duration 
	local Type = SkillStepTable.Type -- get skill step type 
    -- Determine the current target. Prioritize the locked target if it exists and is valid. 
    local currentTarget, CheckTarget, Hit, Parry, JustParry = nil 
	currentTarget = StellarBlade.PickTarget(self) 
    -- [NEW] Handle persistent "bLookAtTarget": Keep looking at the target during the step 
	local bLookAtTarget = SkillStepTable.bLookAtTarget 
	-- override bLookAtTarget to always look at target when performing a hit 
	-- otherwise, use bLookAtTarget value 
	-- for some reason, bLookAtTarget is mostly false even in SkillActiveStepType_Hit 
	-- something else may be controlling the boolean 
	-- bLookAtTarget = (Type == "ESBSkillActiveStepType::SkillActiveStepType_Hit" or Type == "ESBSkillActiveStepType::SkillActiveStepType_Parry") and true or bLookAtTarget 
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
		CheckTarget, Hit, Parry, JustParry = StellarBlade.CheckSkillHit(self,SkillStepTable,bEveryFrameHitCheck) 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Hold" then -- unused 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_SuperParry" then -- unused 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Item" then -- eve only: use item 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Guard" then -- eve only: put sword / wings in front to parry 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_None" then -- default action 
	
	end 
	if Parry then Hit = false end -- quick fix, fix inside function to either Hit or Parry. Hit should be set only if something takes damage 
	-- print("CheckTarget, Hit, Parry, JustParry:,",CheckTarget, Hit, Parry, JustParry) 
	
	local NextStepCheckEffectArray = StellarBlade.ParseTableStrings(SkillStepTable.NextStepCheckEffectArray) 
	-- "NextStepCheckEffectArray": "[{\"Effect\":\"M_Raven_QTECheck\", \"NextStepAlias\":\"M_Raven_ChaseComboQTE_Cast1\", \"bCheckTarget\":0, \"bHit\":0, \"bParry\":1, \"bJustParry\":1}]", 
	-- "NextStepCheckEffectArray": "[{\"Effect\":\"M_Raven_BetaCounterReady\", \"NextStepAlias\":\"P_Eve_ShieldBreakerCounterRaven1_Cast1\", \"bCheckTarget\":1, \"bHit\":1, \"bParry\":1, \"bJustParry\":1}, {\"Effect\":\"M_Raven_BetaCounterCheckNoCoolTime\", \"NextStepAlias\":\"P_Eve_ShieldBreakerCounterRaven1_Cast1\", \"bCheckTarget\":1, \"bHit\":1, \"bParry\":1, \"bJustParry\":1}]", 
	
	if istable(NextStepCheckEffectArray) then 
		for k,v in ipairs(NextStepCheckEffectArray) do 
			local hCheckTarget, bHit, bParry, bJustParry = tobool(v.bCheckTarget) and currentTarget or self, tobool(v.bHit), tobool(v.bParry), tobool(v.bJustParry) 
			if hCheckTarget.SB_EffectAlias and hCheckTarget.SB_EffectAlias[v.Effect] and !table.IsEmpty(hCheckTarget.SB_EffectAlias[v.Effect]) then 
				if v.bCheckTarget and !IsValid(hCheckTarget) then break end 
				-- print("bHit, bParry, bJustParry:",bHit, bParry, bJustParry) 
				if bHit == Hit and bParry == Parry and bJustParry == JustParry then 
					-- print("calling effect next step") 
					StellarBlade.SetSkillStep(self,v.NextStepAlias) 
					break 
				end 
			end 
		end 
	end 

	-- Check if the duration for the current step has elapsed

	if CurTime() >= EndTime then 
		StellarBlade.RemoveEffectLifeTypes(self,"ESBEffectLifeType::EffectLifeType_StepDependent") 
		-- step finished: advance to next step or clear
		local NextStepAlias = SkillStepTable.NextStepAlias 
		local NextStepAliasWhenNoTarget = SkillStepTable.NextStepAliasWhenNoTarget 
		
		local Step = NextStepAlias 
		if !IsValid(currentTarget) and NextStepAliasWhenNoTarget != "None" then 
			Step = NextStepAliasWhenNoTarget 
		end 
		if NextStepAlias and NextStepAlias != "None" then
			-- Transition to the next skill step
			StellarBlade.SetSkillStep(self,NextStepAlias) 
			StellarBlade.ProcessActiveSkill(self,self.SBAI_SkillStep) 
		else 
			-- No next step, so the skill is finished 
			StellarBlade.RemoveEffectLifeTypes(self,"ESBEffectLifeType::EffectLifeType_SkillDependent") 
			tbl:Remove() 
		end 

	else 
		if SkillStepTable.bStopWhenMoving then 
			local bIsMoving = !self:GetVelocity():IsZero() 
			bIsMoving = bIsMoving or self.GetMoveVelocity and !self:GetMoveVelocity():IsZero() 
			if bIsMoving then 
				tbl:Remove() 
			end 
		end 
	end 
end 

StellarBlade.CompleteTableOptional = function(self,tableOptional) 
	if !tableOptional.Constructor then 
		if tableOptional.DamageInfo and IsValid(tableOptional.DamageInfo:GetAttacker()) then tableOptional.Constructor = tableOptional.DamageInfo:GetAttacker() end 
	end 
    -- 1. If both exist, skip.
    if tableOptional.DamageInfo and tableOptional.TraceResult then return end

    -- 2. If DamageInfo exists but TraceResult does NOT
    if tableOptional.DamageInfo and not tableOptional.TraceResult then
        local dmg = tableOptional.DamageInfo
        local att = dmg:GetAttacker()
        
        -- Determine positions
        -- We assume the damage position is the hit position.
        local hitPos = dmg:GetDamagePosition()
        
        -- We assume the start position is the attacker's shoot position (melee logic).
        -- Fallback to ReportedPosition if attacker is invalid.
        local StartPos = (IsValid(att) and (att.GetShootPos and att:GetShootPos() or att:WorldSpaceCenter())) or dmg:GetReportedPosition()
        
        -- Calculate Normal (Direction)
        local normal = (hitPos - StartPos):GetNormalized()
        
        -- Generate TraceResult table
        local tr = {}
        
        tr.Entity = self -- The entity hit by the trace (self)
        tr.Fraction = 0.99 -- Assumed end of swing
        tr.FractionLeftSolid = 0
        tr.Hit = true -- Damage implies a hit
        tr.HitBox = 0 -- Default generic hitbox
        tr.HitGroup = HITGROUP_GENERIC 
        tr.HitNoDraw = false
        tr.HitNonWorld = true -- Hit 'self', which is an entity
        tr.HitNormal = -normal -- Approximation: Surface normal opposes attack direction
        tr.HitPos = hitPos
        tr.HitSky = false
        tr.HitTexture = "**studio**" -- Assuming self is a prop/entity
        tr.HitWorld = false
        tr.MatType = MAT_FLESH -- Cannot determine exact material without actual trace
        tr.Normal = normal
        tr.PhysicsBone = 0
        tr.StartPos = StartPos
        tr.SurfaceProps = 0
        tr.StartSolid = false
        tr.AllSolid = false
        tr.HitBoxBone = 0 -- Default
        
        -- Save to table
        tableOptional.TraceResult = tr
        
    -- 3. If TraceResult exists but DamageInfo does NOT
    elseif tableOptional.TraceResult and not tableOptional.DamageInfo then
        local tr = tableOptional.TraceResult
        local Constructor = tableOptional.Constructor
        
        -- Create new DamageInfo object 
        local dmginfo = DamageInfo() 
        
        -- Fill Data from TraceResult and Constructor
        dmginfo:SetDamagePosition(tr.HitPos)
        
        -- If Constructor exists, use it as Attacker
        if IsValid(Constructor) then
            dmginfo:SetAttacker(Constructor)
            dmginfo:SetReportedPosition(Constructor:GetShootPos()) -- "From Constructor's GetShootPos"
            
            -- Try to find the active weapon for Inflictor/Weapon fields
            if (Constructor.GetActiveWeapon) then
                local wep = Constructor:GetActiveWeapon()
                if IsValid(wep) then
                    dmginfo:SetInflictor(wep)
                    dmginfo:SetWeapon(wep)
					dmginfo:SetAmmoType(wep:GetPrimaryAmmoType())
                else
                    dmginfo:SetInflictor(Constructor)
                end
            else
                dmginfo:SetInflictor(Constructor)
            end
        else
            -- Fallback if Constructor is missing/invalid
            dmginfo:SetReportedPosition(tr.StartPos)
        end
        
        -- Calculate and Set Force
        -- Standard physics push: Direction * Force Multiplier
        -- We use the Trace Normal for direction.
        local forceDir = tr.Normal
        if forceDir == vector_origin then forceDir = (tr.HitPos - tr.StartPos):GetNormalized() end
        
        -- Apply a reasonable force scalar (approx 100 units per damage point is standard HL2 balance)
        dmginfo:SetDamageForce(forceDir * 10 * 100)
		-- Set Fixed Requirements
        dmginfo:SetDamage(dmginfo:GetAttacker().PhysicAttackPower or 15) 
        dmginfo:SetDamageType(DMG_SLASH)
        
        -- Save to table
        tableOptional.DamageInfo = dmginfo
    end 
end 

StellarBlade.CheckSkillHit = function(self,SkillStepTable,bEveryFrameHitCheck) 
	local ID = SkillStepTable.ID 
	-- trace attack from weapon / radius / sphere / whatever is AttackDirection and call necessary effects 
	-- moved damage event in ActorStat 
	if !bEveryFrameHitCheck then 
		if self.SBAI_SkillStep.HitChecked then 
			return true 
		end 
	end 
	local event,etime,cycle,types,options = util.GetAnimEventIDByName("EVENT_WEAPON_MELEE_HIT"), CurTime(), SkillStepTable.Cycle, 0, self.PhysicAttackPower or 1100 
	-- adjust melee damage depending on step options 
	options = options * SkillStepTable.SkillAttackDamageRate 
	local bParry = false 
	local enemy = StellarBlade.PickTarget(self) 
	local AvailableParry, AvailableSuperParry, AvailableGuard, AvailableJustParry, AvailableJustAction, AvailableJustGuard = SkillStepTable.AvailableParry, SkillStepTable.AvailableSuperParry, SkillStepTable.AvailableGuard, SkillStepTable.AvailableJustParry, SkillStepTable.AvailableJustAction, SkillStepTable.AvailableJustGuard 
	-- print(enemy) 
	if self.GetEnemy and !IsValid(self:GetEnemy()) then -- pick random enemy 
		if #self:GetKnownEnemies() > 0 then 
			enemy = self:GetKnownEnemies()[1] 
		end 
	end 
	
	local function IsSimpleTarget(ent) -- those that you shouldn't apply targetresult 
		if ent:GetCollisionGroup() < COLLISION_GROUP_PLAYER or ent:GetCollisionGroup() > COLLISION_GROUP_NPC then return true end 
		if ent:GetSolid() == 0 then return true end 
		if ent:IsFlagSet(FL_DONTTOUCH) then return true end 
		if bit.band(ent:GetSolidFlags(),FSOLID_NOT_SOLID) == FSOLID_NOT_SOLID then print(ent,"not solid")  return true end 
		if !ent:Alive() then return true end 
		if ent:GetModel() == "models/error.mdl" then return true end 
		return false 
	end 
	local tableofhittargets = { } 

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
		tableofhittargets = StellarBlade.TargetFilter(self,TargetFilterAlias,self.SBAI_SkillStep.Cycle) 
	end 
	
	if string.find(HitDetectionType,"ActiveCollision") then 
		if table.IsEmpty(tableofhittargets) then tableofhittargets = ents.FindInPVS and ents.FindInPVS(self) or ents.FindInSphere(self:GetPos(),100) end 
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
	
	-- print("tableofhittargets size is:",#tableofhittargets) 
	
	if !self.SBAI_SkillStep.Hit then 
		self.SBAI_SkillStep.Hit = false 
	end 
	if self.SBAI_SkillTable then 
		if self.SBAI_SkillTable.Hit == nil then 
			self.SBAI_SkillTable.Hit = false 
		end 
	end 
	
	for k,v in pairs(tableofhittargets) do 
		if !self.SBAI_SkillStep.HitEntities then self.SBAI_SkillStep.HitEntities = { } end 
		if self.SBAI_SkillStep.HitEntities and self.SBAI_SkillStep.HitEntities[v] then continue end -- prevent hitting same entity multiple frames 
		self.SBAI_SkillStep.HitEntities[v] = { ["CurTime"] = CurTime()} 
		local dmgtype = DMG_SLASH+DMG_ALWAYSGIB 
		if v:IsVehicle() then -- make vehicle driver npcs vulnerable to this slash 
			local driver = v:GetDriver() 
			if IsValid(driver) then 
				table.insert(tableofhittargets,driver) 
				if driver:IsNPC() then 
					driver:SetSaveValue("m_takedamage",2) 
				end 
			end 
		elseif v:GetClass() == "npc_combinegunship" or v:GetClass() == "npc_strider" or v:GetClass() == "proto_sniper" then 
			dmgtype = DMG_BLAST 
		elseif v:GetClass() == "prop_dropship_container" or v:GetClass() == "npc_helicopter" then 
			dmgtype = DMG_AIRBOAT + DMG_BLAST 
		elseif v.IsKratos then 
			dmgtype = DMG_BLAST 
			if SkillStepTable.bCritical then 
				v.InBlockMode = false 
			end 
		end 
		local tr = { } 
		local dmg = DamageInfo() 
		v:ForcePlayerDrop() 
		-- print(v:IsPlayerHolding()) 
		if v != self and (!v:IsFlagSet(FL_GODMODE) or IsValid(enemy) and enemy == v) then 
			if IsValid(v:GetOwner()) and v:GetOwner() == self then continue end 
			if IsValid(v:GetParent()) and v:GetParent() == self then continue end 
			-- print(v) 
			local NearestPoint = scripted_ents.Get("cycler_actor2").NearestPoint2(v,self:GetShootPos()) 
			dmg = DamageInfo() 
			dmg:SetAttacker(self) 
			dmg:SetWeapon(IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon() or self) 
			dmg:SetInflictor(IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon() or self) 
			dmg:SetDamage(options) 
			dmg:SetReportedPosition(self:GetShootPos()) 
			dmg:SetDamageType(dmgtype) 
			dmg:SetDamagePosition(NearestPoint) 
			scripted_ents.Get("npc_sb_raven").NPC_CalculateMeleeDamageForce(self,dmg,self:GetAimVector(),v:GetPos(),1) 
			tr = { -- even though we generate a table of a traceRes, this function uses only hitpos and hitnormal 
			Entity = v, 
			Hit = true, 
			-- HitPos = v:NearestPoint(self:IsWeapon() and self:GetOwner():EyePos() or self:EyePos()),
			HitPos = scripted_ents.Get("cycler_actor2").NearestPoint2(v,self:IsWeapon() and self:GetOwner():EyePos() or self:EyePos()), 
			HitNormal = self:GetAimVector(), 
			HitWorld = false, 
			HitMaterial = v:GetMaterial(), 
			
			-- Normal = (self:NearestPoint(v:EyePos()) - v:GetPos()):GetNormalized(), 
			Normal = (scripted_ents.Get("cycler_actor2").NearestPoint2(self,v:EyePos()) - v:GetPos()):GetNormalized(), 
			StartPos = NearestPoint 
			} 
			if v.SetPhysicsAttacker then 
				v:SetPhysicsAttacker(self,SkillStepTable.Duration*10) 
			end 
			
			-- activate TargetMoveAliasArray on target 
			
			local tableOptional = { } 
			tableOptional.DamageInfo = dmg 
			tableOptional.TraceResult = tr 
			tableOptional.Constructor = self 
			tableOptional.Target = v 
			
			for _, TargetMoveAliasArray in ipairs(SkillStepTable.TargetMoveAliasArray) do 
				StellarBlade.AddMoveStep(v,TargetMoveAliasArray,tableOptional) 
			end 

			-- activate TargetShowPath "TargetShowPath": "CH_M_NA_53_Raven/Skill/M_Raven_Slash", 
			-- print("ShowPath is:",SkillStepTable.TargetShowPath) 
			if SkillStepTable.TargetShowPath != "None" then 
				local showpath = "adata_static/SB/Content/Art/Show/" 
				showpath = showpath..SkillStepTable.TargetShowPath..".json" 
				StellarBlade.SetShow(v,showpath,tableOptional) 
			end 
			
			-- "SkillResultAlias": "M_Raven_ChaseCombo_Hit2",
			-- "SkillResultAliasWhenParry": "M_Raven_ChaseCombo_Parry2",
			-- "SkillResultAliasWhenJustParry": "M_Common_ParryJustEffect",
			-- "SkillResultAliasWhenPerfectParry": "None",
			-- "SkillResultAliasWhenSuperParry": "None", -- unused 
			-- "SkillResultAliasWhenGuard": "M_Raven_ChaseCombo_Guard2",
			-- "SkillResultAliasWhenBreakGuard": "None",
			-- "SkillResultElementType": "ESBElementType::Element_None",
			-- "SkillResultElementAmount": 0.0, 
			
			local SkillResultAlias = SkillStepTable.SkillResultAlias 
			local SkillResultAliasWhenParry = SkillStepTable.SkillResultAliasWhenParry 
			local SkillResultAliasWhenJustParry = SkillStepTable.SkillResultAliasWhenJustParry 
			local bDamageBlocked = StellarBlade.JustParryAnticipation(self,v) 
			if !AvailableParry and !AvailableJustParry then bDamageBlocked = false end 
			-- print("bDamageBlocked:",v,bDamageBlocked) 
			
			-- prioritize SkillResultAliasWhenParry, JustParry, PerfectParry, Guard, BreakGuard, Default 
			-- SKILL RESULT BETWEEN ACTORS 
			if IsSimpleTarget(v) then 
				print(v,"simple target") 
				v:DispatchTraceAttack(dmg,tr) 
			else 
			
				if bDamageBlocked then 
					bParry = true 
					if SkillResultAliasWhenJustParry != "None" then 
						StellarBlade.StartSkillSelfResult(self,SkillResultAliasWhenJustParry,false,SkillStepTable.bCritical,tableOptional) 
						StellarBlade.StartSkillTargetResult(v,SkillResultAliasWhenJustParry,false,SkillStepTable.bCritical,tableOptional) 
						-- StellarBlade.SetSkillStep(self,SkillStepTable.NextStepAliasWhenJustParry) 
						self.SBAI_SkillStep.HitChecked = true 
						-- return IsValid(enemy), self.SBAI_SkillStep.Hit, bParry, bParry -- bCheckTarget, bHit, bParry, bJustParry 
						-- print("target result:",v,SkillResultAliasWhenParry) 
					end 
				else 
				
					if SkillResultAlias != "None" then -- applied on self and target 
						-- StellarBlade.StartSkillResult(self,v,SkillResultAlias) 
						StellarBlade.StartSkillSelfResult(self,SkillResultAlias,false,SkillStepTable.bCritical,tableOptional) 
						StellarBlade.StartSkillTargetResult(v,SkillResultAlias,false,SkillStepTable.bCritical,tableOptional) 
						self.SBAI_SkillStep.Hit = true 
						if self.SBAI_SkillTable then 
							self.SBAI_SkillTable.Hit = true 
						end 
						-- print("target result:",v,SkillResultAlias) 
					end 
				end 
			
			end 
			-- NEXT SKILL TRIGGER 
			-- print("NextStepAliasWhenParry:",SkillStepTable.NextStepAliasWhenParry) 
			if SkillStepTable.NextStepAliasWhenParry != "None" then -- player blocked your attack. 
				-- this will be reinterpreted as: trace attack to GetEnemy hit something else 
				-- raven doesn't use this 
				-- StellarBlade.SetSkillStep(self,SkillStepTable.NextStepAliasWhenParry) 
				-- break 
			end 
			
			if SkillStepTable.NextStepAliasWhenJustParry != "None" then -- interpret as: getenemy is invincible or total damage is lesser than %10 
				if bDamageBlocked then 
					StellarBlade.SetSkillStep(self,SkillStepTable.NextStepAliasWhenJustParry) 
					-- Entity(1):ChatPrint("Enemy in JustParry, calling "..SkillStepTable.NextStepAliasWhenJustParry) 
				end 
			end 
			
			if SkillStepTable.NextStepAliasWhenPerfectParry != "None" then -- player performed parry right at HitTime 
			-- this will be reinterpreted as: GetEnemy damaged us right at hit event 
			-- implemented in ON_LIGHT_DAMAGE 
			end 
			
			if SkillStepTable.NextStepAliasWhenSuperParry != "None" then -- unused by anything 
			
			end 
			
			if SkillStepTable.NextStepAliasWhenGuard != "None" then 
				-- raven doesn't use this 
			end 
			
			if SkillStepTable.NextStepAliasWhenBreakGuard != "None" then -- starts QTE 
			
			end 
			
			if SkillStepTable.NextStepAliasWhenCancel != "None" then -- when player wins the interaction 
			
			end 
			
			if SkillStepTable.NextStepAliasWhenPerfectHit != "None" then 
				-- P_Eve_Sword_Normal_Guard2_1_Parry1_ActivatingSkill	P_Eve_Sword_Normal_Guard2_1_ComboParry1
				-- P_Eve_Sword_Normal_Guard1_1_Parry1_ActivatingSkill	P_Eve_Sword_Normal_Guard1_1_ComboParry1
				-- P_Eve_Sword_Normal_Guard1_1_Parry1	P_Eve_Sword_Normal_Guard1_1_ComboParry1
				-- P_Eve_Sword_Normal_Guard2_1_Parry1	P_Eve_Sword_Normal_Guard2_1_ComboParry1
			end 
			
			if SkillStepTable.NextStepAliasWhenHoldRelease != "None" then 
				-- only eve uses this 
			end 
			
			if SkillStepTable.NextStepAliasWhenHoldAndDualSenseTriggerEffectWeaponFired != "None" then 
				-- unused by anything 
			end 
			
			if SkillStepTable.NextStepAliasWhenAttacked != "None" then -- when the target is hit during skill, implemented in ON_LIGHT_DAMAGE 
				-- raven doesn't use this 
			end 
			
			if SkillStepTable.NextStepAliasWhenNoTarget != "None" then 
				-- P_Eve_Gun_ShootMissile1_1_Hit1 P_Eve_Gun_ShootMissile1_1_Finish2	
			end 
			
			if SkillStepTable.NextStepAliasWhenLinkBreak != "None" then -- same as NextStepAliasWhenCancel 
				-- raven uses this 
			end 
			
			if SkillStepTable.NextStepAliasWhenInvalidItemConsume != "None" then 
				-- unused by anything 
			end 
			
			if SkillStepTable.NextStepAliasWhenHit != "None" then 
				local Enemy = StellarBlade.PickTarget(self) 
				if v == Enemy then 
					StellarBlade.SetSkillStep(self,SkillStepTable.NextStepAliasWhenHit) 
				end 
			end 
		end 
	end 
	self.SBAI_SkillStep.HitChecked = true 
	return IsValid(enemy), self.SBAI_SkillStep.Hit, bParry, bParry -- bCheckTarget, bHit, bParry, bJustParry 
end 

StellarBlade.TargetFilter = function(ent, filter, Cycle) 
	if CLIENT then return { } end 
	local flRescale = 1 
	local debugging = true 
    local TargetFilterTable = _G["SB_TargetFilterTable"][1].Rows[filter] 
	if !IsValid(ent) then error("Expected Entity, got NULL Entity!") return end 
	if !filter then print("input a filter") end 
	if filter == "None" then return {} end 
	-- shortcuts to simple checks 
	if filter == "Self" then return {ent} end 
	if filter == "Enemy" then return ent.GetEnemy and IsValid(ent:GetEnemy()) and ent:GetEnemy() or StellarBlade.PickTarget(ent) end 
    if !TargetFilterTable then return {ent:GetEnemy()} end 
	
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
	
	-- Apply dynamic scaling based on Cycle (0..1) if requested.
	-- We scale distances/sizes but intentionally DO NOT scale angles (yaw/width/cone-angle).
	-- Cycle may be nil; default to 0.
	if tobool(bDynamicShapeScale) then
		local c = tonumber(Cycle) or 0
		if c < 0 then c = 0 elseif c > 1 then c = 1 end
		local minS = tonumber(MinShapeScale) or 1
		local maxS = tonumber(MaxShapeScale) or 1
		-- linear interpolate between min and max
		local scale = minS + (maxS - minS) * c

		-- scale global distances used in many shapes
		ShapeForwardDistance = (ShapeForwardDistance or 0) * scale
		ShapeRightDistance   = (ShapeRightDistance or 0) * scale
		ShapeUpDistance      = (ShapeUpDistance or 0) * scale
		-- Near/Far distance will be scaled after they're read below (we reassign them there)

		-- Now do shape-aware scaling for TargetCheckValues:
		-- We'll avoid scaling angle-like values (used as degrees) depending on shape.
		-- Because TargetCheckShape isn't read yet in original flow, we do a best-effort:
		-- scale numeric values that are clearly distances/heights/radii, but do not touch
		-- those that will later be treated as angles in arc/cone checks.
		-- To keep it safe we only scale these here; shape-specific branches below
		-- will expect these possibly-scaled variables.
		TargetCheckValue1 = TargetCheckValue1 * scale
		TargetCheckValue2 = TargetCheckValue2 * scale
		TargetCheckValue3 = TargetCheckValue3 * scale

		-- Edge note: some shapes interpret TargetCheckValue1 as an angle (e.g. 2DArc/3DArc).
		-- To handle that, the shape branches below explicitly override/interpret these
		-- values in a safe way (see comments there). If you prefer stricter semantics,
		-- we will defer scaling of those specific fields until after we read the shape.
	end 
	
	local FarDistance = TargetFilterTable.FarDistance * flRescale 
	local NearDistance = TargetFilterTable.NearDistance * flRescale 
	
	-- If dynamic scaling was enabled we have already scaled TargetCheckValueX and Shape* distances,
	-- but we still need to scale Near/Far now (so they follow the same scale).
	if tobool(bDynamicShapeScale) then
		local minS = tonumber(MinShapeScale) or 1
		local maxS = tonumber(MaxShapeScale) or 1
		local c = tonumber(Cycle) or 0
		if c < 0 then c = 0 elseif c > 1 then c = 1 end
		local scale = minS + (maxS - minS) * c

		FarDistance = (FarDistance or 0) * scale
		NearDistance = (NearDistance or 0) * scale
	end

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
        candidates = ents.FindInPVS and ents.FindInPVS(ent) or ents.GetAll() 
    end 
	
	-- PrintTable(candidates) 

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
		local enemy = ent.GetKnownEnemies 
		if !enemy then 
			for _,target in ipairs(candidates) do 
				if target.Disposition and target:Disposition(ent) == D_HT then 
					table.insert(filtered,target) 
				end 
			end 
		else 
			for _,target in ipairs(ent:GetKnownEnemies()) do 
				table.insert(filtered,target) 
			end 
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
	
	-- PrintTable(filtered) 

    -- Step 3: Distance check
    local nearDist = NearDistance or 0
    local farDist  = FarDistance or math.huge 
    local distFiltered = {}
    for _, target in ipairs(filtered) do
        local distSqr = offsetOrigin:DistToSqr(target:GetPos())
        if distSqr >= nearDist * nearDist and distSqr <= farDist * farDist then 
			-- print("distFiltered: ", target) 
            table.insert(distFiltered, target)
        end
    end
	-- print("past dist check") 

    -- Step 4: Shape checks (2D circle / 3D cylinder)
    local val1  = TargetCheckValue1 or 0
    local val2  = TargetCheckValue2 or 0
    local tmp = {}
	
	-- print("shape check is:",shape,filter) 
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
		-- Visualization: draw vertical cylinder (top/bottom rings + vertical lines + axis + label)
        if debugging then
            local lifetime = FrameTime()*2
            local segs = 100
            local top = offsetOrigin + up * height
            local bottom = offsetOrigin - up * height

            local lastTop = nil
            local lastBottom = nil
            for i = 0, segs do
                local a = (i / segs) * math.pi * 2
                local dir = Vector(math.cos(a), math.sin(a), 0)
                local pTop = top + dir * radius
                local pBottom = bottom + dir * radius

                if lastTop then debugoverlay.Line(lastTop, pTop, lifetime, Color(200,200,50,255)) end
                if lastBottom then debugoverlay.Line(lastBottom, pBottom, lifetime, Color(180,180,255,255)) end
                -- connect top and bottom with a vertical line for clarity (every segment)
                debugoverlay.Line(pTop, pBottom, lifetime, Color(120,220,120,255))

                lastTop = pTop
                lastBottom = pBottom
            end

            -- Axis and label
            debugoverlay.Axis(offsetOrigin, up:Angle(), 12, lifetime)
            debugoverlay.Text(offsetOrigin + up * (height + math_min(16, height * 0.25)), string.format("3DCylinder R=%.0f H=%.0f", radius, height), lifetime)
        end
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
-- Helper function to determine active states for an entity
-- Returns a table where keys are state names and values are booleans
local function GetEntityStates(entity)
	local physobj = entity:GetPhysicsObject()
	
	-- 1. Calculate Moving
	local bMoving = (entity.IsMoving and entity:IsMoving()) or (!entity:GetVelocity():IsZero())
	
	-- 2. Calculate Air
	local bAir = not entity:IsOnGround()
	if physobj and physobj:IsValid() then
		-- Use friction snapshot for physics objects if applicable
		if (entity.GetMoveType and entity:GetMoveType() == MOVETYPE_VPHYSICS) or not entity.GetMoveType then
			bAir = table.IsEmpty(physobj:GetFrictionSnapshot())
		end
	end

	-- 3. Calculate Airborne (Fly)
	local bAirborne = (entity:GetMoveType() == MOVETYPE_FLY) 
		or (entity.GetNavType and entity:GetNavType() == NAV_FLY) 
		or (entity:IsFlagSet(FL_FLY))

	-- 4. Calculate Swimming
	local bSwimming = (entity:WaterLevel() > 0)

	-- Return state map matching JSON key segments
	return {
		Groggy = false, -- Logic for Groggy detection goes here if automated, currently passed via flags usually
		Down = false,   -- Logic for Down detection goes here
		Swimming = bSwimming,
		Airborne = bAirborne,
		Air = bAir,
		EventMoving = bMoving, -- JSON uses "EventMoving", logical check is "Moving"
		Common = true -- Common is always true
	}
end

-- Shared function to resolve keys and apply actions
local function ApplyCascadingActions(entity, SkillResult, activeStates, isTarget, HitLevel, tableOptional)
	-- The Priority Order: High to Low
	local priorityOrder = { "Groggy", "Down", "Swimming", "Airborne", "Air", "EventMoving", "Common" }

	-- The "Slots" we need to fill
	local selectedActions = {
		Effect = nil,
		ShowPath = nil,
		MoveStep = nil
	}

	-- Iterate through priority list
	for _, stateName in ipairs(priorityOrder) do
		-- Only check if this state is actually active on the entity
		-- Note: Groggy/Down/Weakpoint are usually passed in, but here we assume the boolean flags 
		-- from the original script logic (bDown/bGroggy) would be set. 
		-- Since the original script set bGroggy/bDown inside the function based on external flags not shown,
		-- we will assume the state map is updated before this loop or defaults to false.
		
		if activeStates[stateName] then
			
			-- Construct JSON Key Prefixes
			-- Target keys example: "HitLevelResultTargetCommonEffect" vs "ResultTargetCommonEffect"
			-- Self keys example: "ResultSelfCommonEffect" (Self usually ignores HitLevel prefix based on your JSON)
			
			local prefix = "Result" .. (isTarget and "Target" or "Self") .. stateName
			local hitLevelPrefix = "HitLevelResult" .. (isTarget and "Target" or "Self") .. stateName
			
			-- 1. Resolve EFFECT
			if selectedActions.Effect == nil then
				local val = ""
				if isTarget and HitLevel then
					val = SkillResult[hitLevelPrefix .. "Effect"]
				else
					val = SkillResult[prefix .. "Effect"]
				end
				
				if val and val != "" then selectedActions.Effect = val end
			end

			-- 2. Resolve SHOWPATH
			if selectedActions.ShowPath == nil then
				-- ShowPath usually doesn't have a HitLevel prefix in the provided JSON, but we check just in case or default to standard
				local val = SkillResult[prefix .. "ShowPath"]
				if val and val != "" then selectedActions.ShowPath = val end
			end

			-- 3. Resolve MOVESTEP (Targets only)
			if isTarget and selectedActions.MoveStep == nil then
				local val = ""
				if HitLevel then
					val = SkillResult[hitLevelPrefix .. "MoveAlias"]
				else
					val = SkillResult[prefix .. "MoveAlias"]
				end
				
				-- "None" is treated as a valid value in JSON, but we usually want to treat it as 'not set' 
				-- if we want to fall back. However, if "None" is an explicit instruction to Stop, 
				-- keep it. Assuming empty string or missing key is the fallback trigger.
				if val and val != "" and val != "None" then selectedActions.MoveStep = val end
			end
		end
		
		-- Optimization: Break if all slots are filled
		if selectedActions.Effect and selectedActions.ShowPath and (!isTarget or selectedActions.MoveStep) then
			break
		end
	end

	-- EXECUTE SELECTED ACTIONS
	
	-- Apply Effect
	if selectedActions.Effect and selectedActions.Effect != "" then
		local strEffect = StellarBlade.ParseTableStrings(selectedActions.Effect)
		StellarBlade.AddEffectFromTable(entity, strEffect, tableOptional)
	end

	-- Apply ShowPath
	if selectedActions.ShowPath and selectedActions.ShowPath != "" then
		StellarBlade.SetShow(entity, selectedActions.ShowPath, tableOptional)
	end

	-- Apply MoveStep (Target Only)
	if isTarget and selectedActions.MoveStep and selectedActions.MoveStep != "" and selectedActions.MoveStep != "None" then
		StellarBlade.AddMoveStep(entity, selectedActions.MoveStep, tableOptional)
	end
end

StellarBlade.StartSkillSelfResult = function(self, SkillResultAlias, HitLevel, bCritical, tableOptional) 
	-- print("StartSkillSelfResult") 
	local SkillResult = SB_SkillResultTable[1].Rows[SkillResultAlias] 
	
	-- 1. Additive: Critical (Always runs if true)
	if bCritical then 
		local critEffect = SkillResult.ResultSelfCriticalEffect
		if critEffect and critEffect != "" then 
			local table_ResultSelfCriticalEffect = StellarBlade.ParseTableStrings(critEffect) 
			StellarBlade.AddEffectFromTable(self, table_ResultSelfCriticalEffect, tableOptional) 
		end 
		StellarBlade.SetShow(self, SkillResult.ResultSelfCriticalShowPath, tableOptional) 
	end 

	-- 2. Additive: Weakpoint (Always runs if true)
	local bWeakpoint = false -- Define your weakpoint logic here
	if bWeakpoint then 
		local weakEffect = SkillResult.ResultSelfWeakpointHitEffect
		if weakEffect and weakEffect != "" then 
			local table_ResultSelfWeakpointHitEffect = StellarBlade.ParseTableStrings(weakEffect) 
			StellarBlade.AddEffectFromTable(self, table_ResultSelfWeakpointHitEffect, tableOptional) 
		end 
	end 

	-- 3. Calculate States
	local activeStates = GetEntityStates(self)
	-- Inject manual states that depend on external flags if necessary
	activeStates.Groggy = false -- (Set your Groggy logic)
	activeStates.Down = false   -- (Set your Down logic)
	
	-- 4. Process Waterfall Logic
	ApplyCascadingActions(self, SkillResult, activeStates, false, HitLevel, tableOptional)

	return true
end 

StellarBlade.StartSkillTargetResult = function(target, SkillResultAlias, HitLevel, bCritical, tableOptional) 
	-- HitLevel = false 	
	local SkillResult = SB_SkillResultTable[1].Rows[SkillResultAlias] 
	
	-- 1. Additive: Critical
	if bCritical then 
		local critEffect = SkillResult.ResultTargetCriticalEffect
		if critEffect and critEffect != "" then 
			local table_ResultTargetCriticalEffect = StellarBlade.ParseTableStrings(critEffect) 
			StellarBlade.AddEffectFromTable(target, table_ResultTargetCriticalEffect, tableOptional) 
		end 
		StellarBlade.SetShow(target, SkillResult.ResultTargetCriticalShowPath, tableOptional) 
	end 
	
	-- 2. Additive: Weakpoint
	local bWeakpoint = false 
	if bWeakpoint then 
		local weakEffect = SkillResult.ResultTargetWeakpointHitEffect
		if weakEffect and weakEffect != "" then 
			local table_ResultTargetWeakpointHitEffect = StellarBlade.ParseTableStrings(weakEffect) 
			StellarBlade.AddEffectFromTable(target, table_ResultTargetWeakpointHitEffect, tableOptional) 
		end 
	end 
	
	-- 3. Calculate States
	local activeStates = GetEntityStates(target)
	-- Inject manual states
	activeStates.Groggy = false 
	activeStates.Down = false   
	
	-- 4. Process Waterfall Logic
	ApplyCascadingActions(target, SkillResult, activeStates, true, HitLevel, tableOptional)
	
	return true 
end

StellarBlade.JustParryAnticipation = function(self, target)
    local bDamageBlocked = false -- Initialize the variable to false.

    -- Condition 1: The ent is a player and the GM:PlayerShouldTakeDamage hook returns false.
    local playerHookBlocked = target:IsPlayer() and hook.Run("PlayerShouldTakeDamage", target, self) == false

    -- Condition 2: Damage is blocked for AI (if target is NPC and ai_block_damage cvar is true)
    local ai_block_damage = target:IsNPC() and cvars.Bool("ai_block_damage")

    -- Condition 3: The ent has God Mode enabled.
    local isGodMode = target:IsFlagSet(FL_GODMODE)

    -- Condition 4: The target's internal takedamage variable is set to 0 (DAMAGE_NO) or less.
    local takeDamageDisabled = (target:GetInternalVariable("m_takedamage") or 1) < 1

    if playerHookBlocked or ai_block_damage or isGodMode or takeDamageDisabled then
        bDamageBlocked = true
    end
    return bDamageBlocked
end


StellarBlade.SetSkillStep = function(self,strSkill) 
	local SkillStepTable = SB_SkillActiveStepTable[1].Rows[strSkill]
    if !SkillStepTable then
        if self.SBAI_SkillStep then self.SBAI_SkillStep:Remove() end 
        return false 
    end 
	local curTime = CurTime() 

    -- Store the previous skill step's data 
	local Hit = nil 
	local SBAI_SkillStep = self.SBAI_SkillStep 
	if SBAI_SkillStep then 
		-- correct place to transfer stats from old skillstep to new skillstep 
		Hit = SBAI_SkillStep.Hit -- copy skill hit status to next skillstep (move this to self.SBAI_SkillTable) 
		if Hit then 
			-- add on skill step end stat 
		end 
		self.SBAI_SkillStep:Remove(false) 
	else 
		StellarBlade.RemoveEffectLifeTypes(self,"ESBEffectLifeType::EffectLifeType_BeforeNextSkill") 
	end 
	
	-- construct new SkillStep object 
	self.SBAI_SkillStep = { } 
	local SBAI_SkillStep = self.SBAI_SkillStep 
	SBAI_SkillStep.Name = strSkill 
	SBAI_SkillStep.Data = SkillStepTable 
	SBAI_SkillStep.Time = curTime 
	SBAI_SkillStep.Duration = curTime + SkillStepTable.Duration 
	SBAI_SkillStep.Outer = self 
	SBAI_SkillStep.Hit = nil 
	-- SBAI_SkillStep.Cycle = 0 
	setmetatable(SBAI_SkillStep,{ __index = function(self,key) 
		if key == "Cycle" then 
			return math.Clamp((CurTime() - self.Time) / self.Data.Duration, 0, 1) 
		end 
	end } ) 
	
	for k,v in pairs(StellarBlade.SBAI_SkillStep) do 
		SBAI_SkillStep[k] = v 
	end 
	
	hook.Add( "Think", SBAI_SkillStep, function() 
		-- print(self, self.Outer) -- NPC [120][npc_sb_raven]	nil 
		StellarBlade.ProcessActiveSkill(self,SBAI_SkillStep) 
	end ) 
	
	hook.Add("PostEntityTakeDamage",SBAI_SkillStep,SBAI_SkillStep.PostEntityTakeDamage) 
	
	local StartSelfEffect = SkillStepTable.StartSelfEffect 
	local StartTargetEffect = SkillStepTable.StartTargetEffect 
	local CreateEffectSelfPosition = SkillStepTable.CreateEffectSelfPosition 
	local CreateEffectTargetPosition = SkillStepTable.CreateEffectTargetPosition 

    -- [NEW] Handle `bRetargeting`: Lock onto the current target if false 
	local enemy = StellarBlade.PickTarget(self) 
	
	-- [NEW] Handle `StopSelfMove`: Stop the NPC from moving if true 
    if SkillStepTable.StopSelfMove then 
        if self.StopMoving then 
			self:StopMoving(true) 
			self:ClearGoal() 
		end 
		-- clear move steps 
		if self.SBAI_MoveTable then 
			local ok, err = pcall(self.SBAI_MoveTable.Remove,self.SBAI_MoveTable) 
			if !ok then print(self,"move table removal error:",err) end 
		end 
    end  
	
	-- add self effects 
	
	local tableOptional = { } 
	local dmginfo = DamageInfo() 
	dmginfo:SetAttacker(self) 
	dmginfo:SetInflictor(IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon() or self) 
	dmginfo:SetDamagePosition(self:GetPos()) 
	dmginfo:SetReportedPosition(self:GetPos()) 
	dmginfo:SetDamageForce(self:GetAimVector()) 
	dmginfo:SetDamageType(DMG_SLASH) 
	tableOptional.DamageInfo = dmginfo  
	tableOptional.Constructor = self 
	tableOptional.Target = enemy 
	StellarBlade.CompleteTableOptional(enemy,tableOptional) 
	if StartSelfEffect != "" then 
		StartSelfEffect = StellarBlade.ParseTableStrings(StartSelfEffect) 
		StellarBlade.AddEffectFromTable(self,StartSelfEffect,tableOptional) 
	end 
	
	-- add target effects 
	if IsValid(enemy) then 
		if StartTargetEffect != "" then 
			StartTargetEffect = StellarBlade.ParseTableStrings(StartTargetEffect) 
			StellarBlade.AddEffectFromTable(enemy,StartTargetEffect,tableOptional) 
		end 
	end 
	
	if CreateEffectSelfPosition != "" then 
		CreateEffectSelfPosition = StellarBlade.ParseTableStrings(CreateEffectSelfPosition) 
		StellarBlade.AddEffectFromTable(self,CreateEffectSelfPosition,tableOptional) 
	end 
	
	-- add target effects 
	if IsValid(enemy) then 
		if CreateEffectTargetPosition != "" then 
			CreateEffectTargetPosition = StellarBlade.ParseTableStrings(CreateEffectTargetPosition) 
			StellarBlade.AddEffectFromTable(enemy,CreateEffectTargetPosition,tableOptional) 
		end 
	end 
	local ShowPath = SkillStepTable.ShowPath 
	if ShowPath != "None" then 
		local showpath = "data_static/SB/Content/Art/Show/" 
		showpath = showpath..ShowPath..".json" 
		StellarBlade.SetShow(self,showpath) 
	end 

    -- Apply the animation/movement for this step
    local SelfMoveAliasArray = SkillStepTable.SelfMoveAliasArray
    for _, SelfMoveAlias in pairs(SelfMoveAliasArray) do
        StellarBlade.AddMoveStep(self,SelfMoveAlias)
    end 
	
	-- custom way to reward or penalize Player for successfully damaging targets 
	if SkillStepTable.NextStepAlias == "None" then -- no more skills 
		if self.SBAI_SkillTable.Hit == false then -- was in a Hit event but failed to hit targets until the last skillstep 
			-- print(self, " did not hit anything during attack skill, penalizing with decrease in Stamina") 
			StellarBlade.AddEffect(self, "JustParryStaminaDamage", {Constructor = self, Target = enemy, DamageInfo = dmginfo}) 
		elseif self.SBAI_SkillTable.Hit == true then 
			if self:IsPlayer() then 
				-- print("rewarding player with hp",self) 
				-- "CalculationValue": 10.0, -- you can override calcvalue for custom health 
				StellarBlade.AddEffect(self, "HPRecoverRate10", {Constructor = self, Target = enemy, DamageInfo = dmginfo},"bDrainHpByAttack",true) 
			end 
		else -- nil return, most likely Evade or Parry Preview skill used 
		
		end 
	end 

	if #SkillStepTable.UsableTargetProjectileAliasArray > 0 then 
		for i = 1,#SkillStepTable.UsableTargetProjectileAliasArray do 
			local event,etime,cycle,types,options 
			if self.NPC_RangedAttack then 
				self.NPC_RangedProjectile = "raven_projectile" 
				self:NPC_RangedAttack(event,etime,cycle,types,options) 
			elseif self:IsNPC() then 
				self.NPC_RangedProjectile = "raven_projectile" 
				scripted_ents.Get("npc_unreali_female").NPC_RangedAttack(self,event,etime,cycle,types,options) 
			else 
				local proj = ents.Create("raven_projectile") 
				proj:SetOwner(self) 
				proj:SetPos(self:GetShootPos()) 
				proj:SetAngles(self:GetAimVector():Angle()) 
				proj:Spawn() 
				proj:Activate() 
			end 
		end 
	end 
	
	if self:IsPlayer() then
		local hViewModel = self:GetViewModel()
		local hWeapon = self:GetActiveWeapon()
		if IsValid(hViewModel) and IsValid(hWeapon) then
			if SkillStepTable.Type == "ESBSkillActiveStepType::SkillActiveStepType_Hit" then 
				local NextDuration = 0 
				
				local NextStepAlias = SkillStepTable.NextStepAlias 
				NextStepAlias = SB_SkillActiveStepTable[1].Rows[NextStepAlias] 
				if NextStepAlias then NextDuration = NextStepAlias.Duration end 
				-- print(SkillStepTable.Duration,NextDuration) 
		-- local NextStepAliasWhenNoTarget = SkillStepTable.NextStepAliasWhenNoTarget 
		
		-- local Step = NextStepAlias 
		-- if !IsValid(currentTarget) and NextStepAliasWhenNoTarget != "None" then 
			-- Step = NextStepAliasWhenNoTarget 
		-- end 
		-- if NextStepAlias and NextStepAlias != "None" then
				
				
				
				hWeapon:SendWeaponAnim(math.random() > 0.5 and ACT_VM_PRIMARYATTACK or ACT_VM_SECONDARYATTACK)
				local vmDuration = hViewModel:SequenceDuration(hViewModel:GetSequence()) 
				-- Calculate playback rate to match SkillStepTable.Duration
				local PlaybackRate = vmDuration / (SkillStepTable.Duration + NextDuration) 
				hViewModel:SetPlaybackRate(PlaybackRate) 
				-- print(PlaybackRate,vmDuration) 
				if hWeapon.SetIdleDelay then hWeapon:SetIdleDelay(CurTime() + SkillStepTable.Duration+NextDuration) end 
			end 
		end 
	end 

	StellarBlade.ProcessActiveSkill(self,self.SBAI_SkillStep) 
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
    if !curveDataPath or curveDataPath == "None" then return end 

    -- Extract the path between the single quotes, e.g., /Game/GameDesign/...
    local extractedPath = string.match(curveDataPath, "'(.-)'") 
    if !extractedPath then return end 

    -- Strip the duplicate object name at the end, which acts like an extension.
	extractedPath = string.sub(extractedPath,6)  
    extractedPath = string.StripExtension(extractedPath) 

    -- Construct the final file path.
    local finalPath = "data_static/SB/Content" .. extractedPath .. ".json" 

    -- This external function is expected to load the JSON into a global table.
    SB_ImportJSON(finalPath) 
end 

StellarBlade.LookupCharacterSound = function(self, key, specifickeys) 
	specifickeys = specifickeys or false 
    key = string.upper(key) 
    local CharacterSoundSet = string.GetFileFromFilename(string.StripExtension(self.CharacterSoundSetPath or "data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_53_Raven.json")) 
    CharacterSoundSet = _G["SB_"..CharacterSoundSet] -- the CharacterSoundSet imported from JSON is now a Lua table 
    
    if !CharacterSoundSet or !CharacterSoundSet[1].Properties then return nil end

    -- Determine which categories to search based on the specifickeys boolean
    local categories = {}
    if specifickeys then
        categories = { "HitSounds", "ReactSounds", "EnvHitSounds", "VoiceSounds" }
    else
        -- Collect all available category keys from the Properties table
        for categoryName, _ in pairs(CharacterSoundSet[1].Properties) do
            table.insert(categories, categoryName)
        end
    end

    -- search through the determined sound categories
    for _, category in ipairs(categories) do
        local sounds = CharacterSoundSet[1].Properties[category]
        -- Ensure the category exists and is a table before iterating
        if type(sounds) == "table" then
            for _, entry in ipairs(sounds) do
                -- Check if the entry has a Key to prevent indexing nil
                if entry.Key then
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
    end

    return nil
end

StellarBlade.AddMoveStep = function(self,strEffect) 
    if !SB_CharacterMoveTable or !SB_CharacterMoveTable[1] or !SB_CharacterMoveTable[1].Rows then 
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
	
	-- BroadcastLua("if IsValid(Entity("..self:EntIndex()..")) then StellarBlade.AddMoveStep(Entity("..self:EntIndex().."),'"..strEffect.."') end" 

    if !self.SBAI_MoveTable then 
        self.SBAI_MoveTable = {["Outer"] = self} 
    end 
	
	local SBAI_MoveTable = self.SBAI_MoveTable 
	local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[strEffect] -- get precached movetable 
	if CharacterMoveTable.RootMotionDataPath and CharacterMoveTable.RootMotionDataPath != "None" then 
		local RootMotionDataPath = string.sub(CharacterMoveTable.RootMotionDataPath, 6) 
		RootMotionDataPath = "data_static/SB/Content" .. RootMotionDataPath .. ".json" 
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

	local newMoveStep = { 
		["CharacterMoveTable"] = CharacterMoveTable, 
		["LastVelocity"] = vector_origin, 
		["MoveArrayName"] = strEffect, 
		["MoveStatus"] = true, 
		["MoveTable"] = SBAI_MoveTable, 
		["Outer"] = self, 
		["RunTime"] = CurTime(), 
		["StartTime"] = CurTime() + (CharacterMoveTable.StartDelayTime or 0) 
	} 
	
	function newMoveStep:IsValid() 
		return self.Outer:IsValid() and self.Outer:Alive() 
	end 
	
	function SBAI_MoveTable:IsValid() 
		if #self < 1 then return false end 
		if self.IsMarkedForDeletion then return false end 
		-- print("calling movestep for:",self.Outer) 
		return self.Outer:IsValid() and self.Outer:Alive() 
	end 
	
	function newMoveStep:IsActive() 
		if CurTime() < self.StartTime then return false end 
		if CurTime() >= self.StartTime + self.CharacterMoveTable.Time then return false end 
		return true 
	end 
	
	function newMoveStep:Evaluate() 
	
	end 
	
	function newMoveStep:Remove() 
		if !self.IsMarkedForDeletion then 
			self.IsMarkedForDeletion = true 
			hook.Remove("Think",self) 
			hook.Remove("SetupMove",self) 
			hook.Remove("Move",self) 
			hook.Remove("FinishMove",self) 
			for i = 1,#self.Outer.SBAI_MoveTable do 
				local iMoveStep = self.Outer.SBAI_MoveTable[i] 
				if iMoveStep == self then 
					table.remove(self.Outer.SBAI_MoveTable,i) 
				end 
			end 
		end 
	end 
	
	function SBAI_MoveTable:Remove() 
		if !self.IsMarkedForDeletion then 
			self.IsMarkedForDeletion = true 
			hook.Remove("Think",self) 
			hook.Remove("SetupMove",self) 
			hook.Remove("Move",self) 
			hook.Remove("FinishMove",self) 
			if IsValid(self.Outer) then 
				if self.Outer.SBAI_MoveTable == self then 
					self.Outer.SBAI_MoveTable = nil 
				end 
			end 
		end 
	end 
	
	function SBAI_MoveTable:Think() -- npc and other things 
		-- print(self,#self,self.Outer) 
		
		local ply = self.Outer 
		self:Move(ply) 
		-- print("move is:",ply) 
		
		local movePosDelta = Vector(0,0,0) 
		local finalPos, finalAng = ply:GetLocalPos() + self.movePosDelta, self.moveAngDelta 

		if self.movePosDelta != vector_origin then 
			local moveResult = IterativeHybridMoveLimit(ply, ply:GetLocalPos(), finalPos) 
			if ply:IsVehicle() then 
				ply:GetPhysicsObject():SetPos(moveResult.vEndPosition) 
			else 
				ply:SetLocalPos(moveResult.vEndPosition) 
			end 
		end 
		ply:SetAbsVelocity(self.movePosDelta / FrameTime() + ply:GetVelocity()) 
		
		--[[ 
		ply:SetSaveValue("basevelocity",self.movePosDelta / FrameTime()) 
		ply:AddFlags(FL_BASEVELOCITY) 
		--]] 
		
		if finalAng != angle_zero then 
			if ply.SetIdealYawAndUpdate then 
				ply:SetIdealYawAndUpdate(finalAng.y, -1) 
			else 
				ply:SetAngles(Angle(ply:EyeAngles().p,finalAng.y,ply:EyeAngles().z)) 
			end 
		end 
		
		
		for i,moveStep in ipairs(self) do 
			local name = moveStep.MoveArrayName 
			local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name] -- get precached movetable 
			local Time = CharacterMoveTable.Time 
			local CurEndTime = moveStep.StartTime + Time 
			if CurTime() > CurEndTime then 
				if tobool(CharacterMoveTable.bZeroVelocityWhenEnd) then
					-- remove only this step's contribution
					local currentAbsVel = ply:GetVelocity()
					local correctedVel = currentAbsVel - (moveStep.LastVelocity or vector_origin)
					-- self:SetLocalVelocity(vector_origin) 
					ply:SetSaveValue("basevelocity",vector_origin) 
					ply:SetAbsVelocity(vector_origin) 
					moveStep.LastVelocity = vector_origin
				else 
					-- ply:SetVelocity(self.movePosDelta / FrameTime()) 
				end 
				moveStep:Remove() 
			else 
				-- check for movestep validity 
			end 
		end 
		
		if #self < 1 then self:Remove() end 
	end 
	
	function SBAI_MoveTable:Move(ply,mv) -- player only 
		if self.Outer != ply then return end 
		-- print("calling self.Move",CurTime(),ply) 
		self.movePosDelta = vector_origin 
		self.moveAngDelta = angle_zero 
		if #self > 0 then
			for i = 1, #self do
				local moveStep = self[i] 
				local flInterval = CurTime() - moveStep.RunTime 
				moveStep.RunTime = CurTime() 
				if !moveStep:IsActive() then continue end 
				-- print("pre EvaluateMoveStep",SysTime()) 
				local ok, movePosDelta, moveAngDelta = StellarBlade.EvaluateMoveStep(ply, moveStep, flInterval) 
				-- print("post EvaluateMoveStep",SysTime()) 
				moveStep.movePosDelta = movePosDelta 
				moveStep.moveAngDelta = moveAngDelta 
				self.movePosDelta = self.movePosDelta + movePosDelta 
				self.moveAngDelta = self.moveAngDelta + moveAngDelta 
				-- print("called self.Move",CurTime()) 
				-- print("moveAngDelta",self.moveAngDelta) 
			end 
		end 
		-- print("post Move:",SysTime()) 
	end 
	
	function SBAI_MoveTable:FinishMove(ply,mv) -- player only 
		if self.Outer != ply then return end 
		-- print(ply) -- ensure whether the move is called for skill player 
		-- if ply.GetVehicle and IsValid(ply:GetVehicle()) and ply:GetVehicle() then 
			-- self.Outer = ply:GetVehicle() 
			-- self:Think() 
			-- return 
		-- end 
		-- local ply = ply.GetVehicle and IsValid(ply:GetVehicle()) and ply:GetVehicle() or ply 
		-- print("in FinishMove",ply,mv) 
		-- print(mv.Data) 
		-- print(ply:IsFlagSet(FL_FROZEN),self.movePosDelta) 
		if ply:IsPlayer() and ply:IsFlagSet(FL_FROZEN) then -- Move doesn't call during ply:Freeze(true) 
			self:Move(ply,mv) 
			-- print("ended self.Move",CurTime()) 
		end 
		local finalPos, finalAng = mv:GetOrigin() + self.movePosDelta, self.moveAngDelta 
		-- print("pre FinishMove:	",SysTime()) 
		-- also apply root movement on gestures as well 
		--[[ 
		for layerID = 0, 15 do 
			if ply:IsValidLayer(layerID) then 
				-- print(layerID) 
				-- print("pre GetIntervalMovement:",SysTime()) 
				local bMoved, newPosition, newAngles, bMoveSeqFinished = GetIntervalMovement(ply,FrameTime(),layerID) -- true, newPosition, newAngles, bMoveSeqFinished 
				-- print(bMoved, newPosition, newAngles, bMoveSeqFinished) 
				-- print("post GetIntervalMovement:",SysTime()) 
				-- print(layerID,bMoved) 
				if bMoved then 
					-- local moveResult = IterativeHybridMoveLimit(ply, ply:GetPos(), newPosition) 
					-- ply:SetLocalPos(moveResult.vEndPosition) 
					local angles = ply:GetLocalAngles() 
					ply:SetLocalAngles(Angle(angles.x,newAngles.y,angles.z)) 
					newPosition = newPosition - ply:GetPos() 
					self.movePosDelta = self.movePosDelta + newPosition 
					break 
				end 
			end 
		end 
		--]] 
		
		if self.movePosDelta != vector_origin then 
			-- print("pre IterativeHybridMoveLimit:",SysTime()) 
			local moveResult = IterativeHybridMoveLimit(ply, mv:GetOrigin(), finalPos) 
			-- print("post IterativeHybridMoveLimit:",SysTime()) 
			-- ply:SetLocalPos(moveResult.vEndPosition) 
			-- print("calling moveResult",CurTime()) 
			mv:SetOrigin(moveResult.vEndPosition) 
			-- ply:SetSaveValue("basevelocity",self.movePosDelta / (FrameTime())) 
			-- ply:AddFlags(FL_BASEVELOCITY) 
		end 
		-- ply:SetSaveValue("basevelocity",self.movePosDelta / FrameTime() + mv:GetVelocity()) 
		-- local newPosition2 = (newPosition/FrameTime()) - ENT:GetInternalVariable("basevelocity") 
		-- self.LastVelocity = newPosition2 
		
		if finalAng != angle_zero then 
			ply:SetEyeAngles(Angle(ply:EyeAngles().x,self.moveAngDelta.y,ply:EyeAngles().z)) 
		end 
		
		for i,moveStep in ipairs(self) do 
			local name = moveStep.MoveArrayName 
			local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name] -- get precached movetable 
			local Time = CharacterMoveTable.Time 
			local CurEndTime = moveStep.StartTime + Time 
			if CurTime() > CurEndTime then 
				if tobool(CharacterMoveTable.bZeroVelocityWhenEnd) then 
					-- remove only this step's contribution 
					-- local currentAbsVel = ply:GetVelocity() 
					-- local correctedVel = currentAbsVel - (moveStep.LastVelocity or vector_origin) 
					-- self:SetLocalVelocity(vector_origin)
					-- ply:SetAbsVelocity(vector_origin) 
					-- moveStep.LastVelocity = vector_origin 
					ply:SetSaveValue("basevelocity",vector_origin) 
				else 
					-- mv:SetVelocity(self.movePosDelta / FrameTime()) 
				end 
				moveStep:Remove() 
			else 
				-- check for movestep validity 
			end 
		end 
		
		if #self < 1 then self:Remove() end 
		-- print("post FinishMove:	",SysTime()) 
	end 
	
	-- define hooks only if they are not present 
	if !self:IsPlayer() then 
		hook.Add("Think",SBAI_MoveTable,SBAI_MoveTable.Think) 
	else 
		-- hook.Add("SetupMove",SBAI_MoveTable,SBAI_MoveTable.SetupMove) 
		hook.Add("Move",SBAI_MoveTable,SBAI_MoveTable.Move) 
		hook.Add("FinishMove",SBAI_MoveTable,SBAI_MoveTable.FinishMove) 
	end 
	return table.insert(SBAI_MoveTable, newMoveStep) 
end 

StellarBlade.ShouldCancelMoveTable = function(self,moveStep) 
    if !moveStep then return false end
    local name = moveStep.MoveArrayName 
    local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name] 
	if self.GetEnemy then 
		if CharacterMoveTable.bStopWhenInvalidTarget and !IsValid(self:GetEnemy()) then 
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
	-- print("in EvaluateMoveStep:",SysTime(),self,moveStepOrName,flInterval,probeElapsed) 
    if !moveStepOrName then return false, Vector(0,0,0), Angle(0,0,0) end 

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
    if !name or !SB_CharacterMoveTable or !SB_CharacterMoveTable[1] or !SB_CharacterMoveTable[1].Rows[name] then
        return false, Vector(0,0,0), Angle(0,0,0)
    end
	
    local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name]

    local Time = CharacterMoveTable.Time or 0
    local moveStartTimeCfg = CharacterMoveTable.MoveStartTime or 0
    local moveEndTimeCfg = CharacterMoveTable.MoveEndTime or Time
    local moveDuration = math.max(0, moveEndTimeCfg - moveStartTimeCfg)

    -- If caller provided explicit probeElapsed, set StartTime so sampler sees that elapsed
    if probeElapsed != nil and isTempStep then
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
	elapsedTime = nil 
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
        if probeElapsed != nil then
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
	-- print("pre GetEasedFraction:",SysTime()) 
    local easedNow = StellarBlade.GetEasedFraction(interpType, normalizedTime) 
    local easedPrev = StellarBlade.GetEasedFraction(interpType, prevNormalizedTime) 
	-- print("post GetEasedFraction:",SysTime()) 

    local movePosDelta = Vector(0,0,0)
    local moveAngDelta = Angle(0,0,0)
    local flRescale = 1

    -- Determine direction basis (safe fallbacks) 
	-- print("pre StellarBlade.PickTarget:",SysTime()) 
	
	local PositionType = CharacterMoveTable.PositionType 
	
    local enemy = StellarBlade.PickTarget(self) 
    if !IsValid(enemy) then enemy = Entity(0) end 
	-- print("post StellarBlade.PickTarget:",SysTime()) 

    local directionAxis = CharacterMoveTable.PositionDirectionAxis 
    local vecMoveDirection = Vector(1,0,0) 
    if self.GetAimVector then vecMoveDirection = self:GetAimVector() or vecMoveDirection 
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
	-- print("pre Move Offset Calc:",SysTime()) 

    -- Root motion: now uses moveStep.StartTime (which we adjusted above in probe mode)
    if MoveType == "ESBMoveTransformType::MoveTransformType_RootMotion" then
        local RootMotionDataPath = string.StripExtension(string.GetFileFromFilename(CharacterMoveTable.RootMotionDataPath or ""))
        local RootMotion = _G["SB_" .. RootMotionDataPath]
        if RootMotion then
			-- print("pre GetRootMotionTransform:",SysTime(),RootMotion) 
            local posOffset, angOffset = StellarBlade.GetRootMotionTransform(RootMotion, moveStep.StartTime) 
			-- print("post GetRootMotionTransform:",SysTime(),RootMotion) 
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
        local rightDir = vecMoveDirection:Cross(Vector(0,0,1)):GetNormalized()
        local forwardMove = CharacterMoveTable.ForwardValue or 0
        local rightMove = CharacterMoveTable.RightValue or 0
        local upMove = CharacterMoveTable.UpValue or 0
        local posCurvePath = CharacterMoveTable.PositionInterpCurveDataPath
        local zCurvePath = CharacterMoveTable.StaticMoveZVAlueCurveDataPath

        -- Determine anchor position for PositionType::Target vs default (self)
        local anchorPos = nil
        if PositionType == "ESBMovePositionType::MovePositionType_Target" then
            if IsValid(enemy) then
                anchorPos = enemy:GetPos()
            else
                -- fallback to "when no enemy" values
                forwardMove = CharacterMoveTable.ForwardValueWhenNoTarget or forwardMove
                rightMove = CharacterMoveTable.RightValueWhenNoTarget or rightMove
                upMove = CharacterMoveTable.UpValueWhenNoTarget or upMove
            end
        end

        -- Ensure we have an initial position cache when behavior requires it:
        -- For STATIC + TARGET we cache the actor's initial position so interpolation goes from that initial -> desired.
        if PositionType == "ESBMovePositionType::MovePositionType_Target" then
            moveStep.InitialPos = moveStep.InitialPos or self:GetPos()
        end

        -- Helper: compute desired absolute position for given multipliers
        local function computeDesiredAbs(posMultiplier, zMultiplier)
            local totalOffset = (vecMoveDirection * forwardMove) + (rightDir * rightMove)
            return (anchorPos or self:GetPos()) + totalOffset * posMultiplier + Vector(0,0, upMove * zMultiplier)
        end

        if (posCurvePath and posCurvePath ~= "None") or (zCurvePath and zCurvePath ~= "None") then
            local posMultiplier, prevPosMultiplier, zMultiplier, prevZMultiplier = 1,1,1,1
            if posCurvePath and posCurvePath != "None" then
                local curveName = string.StripExtension(string.GetFileFromFilename(string.match(posCurvePath, "'(.-)'") or ""))
                posMultiplier = StellarBlade.ApplyCurveFloat(curveName, normalizedTime)
                prevPosMultiplier = StellarBlade.ApplyCurveFloat(curveName, prevNormalizedTime)
            end
            if zCurvePath and zCurvePath != "None" then
                local curveName = string.StripExtension(string.GetFileFromFilename(string.match(zCurvePath, "'(.-)'") or ""))
                zMultiplier = StellarBlade.ApplyCurveFloat(curveName, normalizedTime)
                prevZMultiplier = StellarBlade.ApplyCurveFloat(curveName, prevNormalizedTime)
            end

            local absNow = computeDesiredAbs(posMultiplier, zMultiplier) 
            local absPrev = computeDesiredAbs(prevPosMultiplier, prevZMultiplier) 

            if PositionType == "ESBMovePositionType::MovePositionType_Target" then
                -- STATIC: interpolate from cached initial pos → desired (InitialPos is fixed)
                if moveStep.InitialPos then
                    -- desired displacement from initial: desiredAbs - InitialPos
                    local relNow = absNow - moveStep.InitialPos
                    local relPrev = absPrev - moveStep.InitialPos
                    movePosDelta = relNow - relPrev
                else
                    -- fallback: incremental between desired absolutes
                    movePosDelta = absNow - absPrev
                end
            else
                -- non-target (self anchored): preserve previous incremental behaviour
                movePosDelta = absNow - absPrev
            end

        else
            -- No curves: simple linear values
            local totalDisplacement = (vecMoveDirection * forwardMove) + (rightDir * rightMove) + (Vector(0,0,1) * upMove)

            if PositionType == "ESBMovePositionType::MovePositionType_Target" and anchorPos then
                local desiredAbs = anchorPos + totalDisplacement
                if moveStep.InitialPos then
                    -- STATIC semantics: interpolate from InitialPos to desiredAbs using eased differences:
                    -- incremental delta = (desiredAbs - InitialPos) * (easedNow - easedPrev)
                    local relNow = desiredAbs - moveStep.InitialPos
                    local relPrev = desiredAbs - moveStep.InitialPos -- same desiredAbs for non-curved case but keep form
                    movePosDelta = relNow * ( (easedNow) ) - relPrev * ( (easedPrev) )
                    -- simplified => relNow * (easedNow - easedPrev)
                    movePosDelta = relNow * (easedNow - easedPrev)
                else
                    -- Non-cached fallback (shouldn't happen for STATIC+TARGET since we set InitialPos), but keep safety:
                    movePosDelta = totalDisplacement * (easedNow - easedPrev)
                end
            else
                -- default (self-anchored) behaviour
                movePosDelta = totalDisplacement * (easedNow - easedPrev)
            end
        end

    -- LocalAxis moves
    elseif MoveType == "ESBMoveTransformType::MoveTransformType_LocalAxis" then
        local forwardMove = CharacterMoveTable.ForwardValue or 0
        local rightMove = CharacterMoveTable.RightValue or 0
        local upMove = CharacterMoveTable.UpValue or 0
        local localDisplacementDelta = Vector(forwardMove, rightMove, upMove) -- this is the *total* local displacement
        local rightVec = vecMoveDirection:Cross(Vector(0,0,1))
        local upVec = vecMoveDirection:Cross(Vector(0,1,0))
        local totalDisplacement = vecMoveDirection * localDisplacementDelta.x + rightVec * localDisplacementDelta.y + upVec * localDisplacementDelta.z

        if PositionType == "ESBMovePositionType::MovePositionType_Target" then
            if IsValid(enemy) then
                local anchorPos = enemy:GetPos()
                -- desired absolute position is anchor + totalDisplacement
                local desiredAbsNow = anchorPos + totalDisplacement * (easedNow)    -- use easedNow as progress toward the local displacement
                local desiredAbsPrev = anchorPos + totalDisplacement * (easedPrev)

                -- LOCALAXIS semantics: do NOT cache initial — always interpolate from actor's current live position toward desired absolute
                -- We'll compute per-frame delta as fraction of the remaining vector for this tick:
                -- delta = (desiredAbsNow - currentPos) - (desiredAbsPrev - currentPosPrev) would be noisy.
                -- Simpler, stable approach: move a proportional portion of the remaining distance this frame:
                --   delta = (desiredAbsNow - self:GetPos()) * (easedNow - easedPrev)
                -- This makes the entity progress toward desiredAbs even if it has external motion.
                local curPos = self:GetPos()
                movePosDelta = (desiredAbsNow - curPos) * (easedNow - easedPrev)
            else
                -- No target -> fallback to original LocalAxis incremental delta based on eased difference
                movePosDelta = totalDisplacement * (easedNow - easedPrev)
            end
        else
            -- Original LocalAxis behaviour (self-anchored)
            movePosDelta = totalDisplacement * (easedNow - easedPrev)
        end

    elseif MoveType == "ESBMoveTransformType::MoveTransformType_WorldLocation" then
        local targetPos = Vector(CharacterMoveTable.ForwardValue or 0, CharacterMoveTable.RightValue or 0, CharacterMoveTable.UpValue or 0)
        movePosDelta = targetPos
    end 
	
	if PositionType == "ESBMovePositionType::MovePositionType_Target" then 
		if IsValid(enemy) then 
			-- movePosDelta = self:WorldToLocal(enemy:GetPos()) + movePosDelta 
		end 
	elseif PositionType == "ESBMovePositionType::MovePositionType_Saved" then 
	elseif PositionType == "ESBMovePositionType::MovePositionType_InsideTargetOrSelf" then 
	elseif PositionType == "ESBMovePositionType::MovePositionType_TargetSocket" then 
	elseif PositionType == "ESBMovePositionType::MovePositionType_WorldPosition" then 
	end 
	
	local RotationType = CharacterMoveTable.RotationType 
	
	if RotationType == "ESBMoveRotationType::MoveRotationType_Target" then 
		if IsValid(enemy) then 
			local dir = (enemy:GetPos() - self:GetPos()):GetNormalized() 
			-- dir = self:GetForward() - dir 
			dir = dir:Angle() 
			-- print("moveAngDelta:",moveAngDelta) 
			-- print("dir:",dir) 
			moveAngDelta = moveAngDelta + dir 
		end 
	end 
	-- print("post Move Offset Calc:",SysTime()) 
	
	-- print(self,elapsedTime) 

    movePosDelta = movePosDelta * flRescale 
    return true, movePosDelta, moveAngDelta 
end 

StellarBlade.MaintainMoveTable = function(self) 
    if self.SBAI_MoveTable and #self.SBAI_MoveTable > 0 then
        local currentAng = self:GetLocalAngles() 
        local totalAngDelta = Angle(0, 0, 0) 
		local enemy = StellarBlade.PickTarget(self) 
		local enemyDir 

        -- Iterate backwards for safe removal
        for i = #self.SBAI_MoveTable, 1, -1 do
			
            local moveStep = self.SBAI_MoveTable[i]
			
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
                    table.remove(self.SBAI_MoveTable, i)
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
					table.remove(self.SBAI_MoveTable, i)
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

-- returns all show key tags a character has been attributed via effects 
StellarBlade.ShowKeyTagMap = function(self) 
	local ShowKeyTag, _ShowKeyTag = { }, { } 
	if self.SB_EffectAlias then 
		for k,v in pairs(self.SB_EffectAlias) do 
			for k2,v2 in ipairs(v) do 
				if v2.ShowKeyTag != "None" then 
					if !_ShowKeyTag[v2.ShowKeyTag] then -- avoid adding same value 
						table.insert(ShowKeyTag,v2.ShowKeyTag) 
						_ShowKeyTag[v2.ShowKeyTag] = true 
					end 
				end 
			end 
		end 
	end 
	return ShowKeyTag 
end 

StellarBlade.ESBAIActorType = function(self,ESBAIActorType) 
	if ESBAIActorType == "ESBAIActorType::ActorType_None" then return 
	elseif ESBAIActorType == "ESBAIActorType::ActorType_Self" then return self 
	elseif ESBAIActorType == "ESBAIActorType::ActorType_Target" then return self:GetEnemy() 
	elseif ESBAIActorType == "ESBAIActorType::ActorType_Owner" then return self:GetOwner() 
	elseif ESBAIActorType == "ESBAIActorType::ActorType_SubTarget" then 
	end 
end 

StellarBlade.ESBCompare = function(val1,val2,operator) 
	local result = false 
	if operator == "ESBCompare::Equal" then 
		result = val1 == val2 
	elseif operator == "ESBCompare::LessOrEqual" then 
		result = val1 <= val2 
	elseif operator == "ESBCompare::Greater" then 
		result = val1 > val2 
	elseif operator == "ESBCompare::GreaterOrEqual" then 
		result = val1 >= val2 
	elseif operator == "ESBCompare::Less" then 
		result = val1 < val2 
	elseif operator == "ESBCompare::NotEqual" then 
		result = val1 != val2 
	end 
	return result 
end 

StellarBlade.PickTarget = function(self) 
	local Time = CurTime() 
	local GetEnemy = self.GetEnemy and self:GetEnemy() or nil 
	if GetEnemy then 
		if IsValid(GetEnemy) and !GetEnemy:Alive() then self:SetEnemy(NULL) end 
	end 
	-- print("PickTarget",Time) 
	
	-- return cached PickTarget if exists within skill step 
	-- return nil if PickTarget is NULL 
	if !self:Alive() then return end 
	if self.GetEnemy and IsValid(self:GetEnemy()) then return self:GetEnemy() end 
	local SBAI_SkillStep = self.SBAI_SkillStep 
	if SBAI_SkillStep then 
		if SBAI_SkillStep.PickTarget then 
			-- print("cached SBAI_SkillStep.PickTarget is:",SBAI_SkillStep.PickTarget) 
			if !IsValid(SBAI_SkillStep.PickTarget) then return end 
			if SBAI_SkillStep.PickTarget:Alive() then 
				-- print("returning cached Entity within skill step:",SBAI_SkillStep.PickTarget) 
				return SBAI_SkillStep.PickTarget 
			end 
		end 
	end 
	
	-- return cached PickTarget if called again for same CurTime 
	-- cache NULL if the entity is nil or NULL 
	-- cache Entity if the Entity selected to self table, and also skill step table if exists 
	if !self.SB_PickTargetTime or self.SB_PickTargetTime and Time > self.SB_PickTargetTime then 
		local bestAim, bestDist, FireDir, projStart = -1, 2500 
		local PickTarget = scripted_ents.Get("proj_unreali_skaarjprojectile").PickTarget(self,-1,bestDist) 
		-- print("calling actual PickTarget:",PickTarget,CurTime(),SBAI_SkillStep) 
		self.SB_PickTarget = IsValid(PickTarget) and PickTarget or NULL  
		self.SB_PickTargetTime = Time + FrameTime() 
		if SBAI_SkillStep then 
			SBAI_SkillStep.PickTarget = IsValid(PickTarget) and PickTarget or NULL 
		end 
		return PickTarget 
	else 
		return self.SB_PickTarget 
	end 
end 

local tableofpassiveweapons = {["weapon_physgun"] = true, ["gmod_camera"] = true, ["gmod_tool"] = true, ["weapon_cubemap"] = true} 

StellarBlade.IsBattle = function(self) 
	if self:IsPlayer() then 
		if IsValid(self:GetActiveWeapon()) then 
			if tableofpassiveweapons[self:GetActiveWeapon():GetClass()] then return false end 
			local GetHoldType = self:GetActiveWeapon():GetHoldType() 
			if GetHoldType == "camera" or GetHoldType == "normal" or GetHoldType == "passive" then return false end 
			return true 
		else 
			return false 
		end 
		
		return IsValid(self:GetActiveWeapon()) 
	end 
	if self.GetNPCState then 
		if self:GetNPCState() == NPC_STATE_DEAD then return false end 
		if self:GetNPCState() > NPC_STATE_IDLE then return true end 
	elseif self.GetEnemy then 
		if IsValid(self:GetEnemy()) then return true end 
	end 
	return false -- add nextbot support 
end 

hook.Add("Restored","SB_SaveRestore",function() 
	for _,ent in pairs(ents.GetAll()) do 
		ent.SB_PickTarget = nil 
		ent.SB_PickTargetTime = nil 
		ent.SBAI_SkillTimers = nil 
		for k,v in pairs(ent:GetTable()) do 
			-- restore SBAI_ActiveShow 
			if k == "SBAI_ActiveShows" then 
				for SBAI_ActiveShowID,SBAI_ActiveShow in pairs(v) do 
					for originaltable,originalvalue in pairs(StellarBlade.SBAI_ActiveShow) do 
						SBAI_ActiveShow[originaltable] = originalvalue 
					end 
					setmetatable(SBAI_ActiveShow,{ __index = function(self,key) 
						if key == "Cycle" then 
							-- PrintTable(showdata) 

							local props = self.SBShowData.Properties 
							local EndTime = props.EndTime or 0 
							
							return math.Clamp((CurTime() - self.Time) / EndTime, 0, 1) 
						end 
					end, 
					__tostring = function(t) return tostring(t.Name).." "..t.Cycle end  

					} ) 
					hook.Add("Tick",SBAI_ActiveShow,SBAI_ActiveShow.Tick) 
				end 
			-- restore SBAI_SkillStep 
			elseif k == "SBAI_SkillStep" then 
			
			setmetatable(v,{ __index = function(v,key) 
				if key == "Cycle" then 
					return math.Clamp((CurTime() - v.Time) / v.Data.Duration, 0, 1) 
				end 
			end } ) 
			for originaltable,originalvalue in pairs(StellarBlade.SBAI_SkillStep) do 
				v[originaltable] = originalvalue 
			end 
			hook.Add( "Think", v, function() 
				-- print(self, self.Outer) -- NPC [120][npc_sb_raven]	nil 
				StellarBlade.ProcessActiveSkill(v.Outer,v) 
			end ) 
			
			hook.Add("PostEntityTakeDamage",v,v.PostEntityTakeDamage) 
			
			-- restore SBAI_SkillTable 
			elseif k == "SBAI_SkillTable" then 
				StellarBlade.SBAI_SkillTable.Initialize(v) 
			-- restore SB_EffectAlias 
			elseif k == "SB_EffectAlias" then 
				for EffectInstance, EffectTable in pairs(v) do 
					for _,EffectAlias in pairs(EffectTable) do 
						print("calling Initialize on:",EffectAlias,EffectAlias.Name) 
						StellarBlade.SB_EffectAlias.Initialize(EffectAlias) 
					end 
					-- PrintTable(EffectAlias) 
				end 
			-- restore SBAI_MoveTable 
			elseif k == "SBAI_MoveTable" then 
			-- restore SBAI_MoveStep 
			elseif k == "SBAI_MoveStep" then 
			-- restore each ESBActorState 
			elseif string.find(k,"ESBActorState") then 
				if istable(v) then 
					for originaltable,originalvalue in pairs(StellarBlade.ActorState) do 
						v[originaltable] = originalvalue 
					end 
					hook.Add("Think",v,v.Think) 
					hook.Add("EntityTakeDamage",v,v.EntityTakeDamage) 
					hook.Add("PostEntityTakeDamage",v,v.PostEntityTakeDamage) 
					hook.Add("SetupMove",v,v.SetupMove) -- player only 
					hook.Add("Move",v,v.Move) -- player only 
					hook.Add("FinishMove",v,v.FinishMove) -- player only 
					hook.Add("CalcMainActivity",v,v.CalcMainActivity) -- player only 
					hook.Add("CalcView",v,v.CalcView) -- clientside player only 
					hook.Add("CalcViewModelView",v,v.CalcViewModelView) -- clientside player only 
				end 
			end 
		end 
	end 
end) 

StellarBlade.IsGroggy = function(self) return self["ESBActorState::ActorState_Groggy"] end 
StellarBlade.ClearMoveTable = function(self) self.SBAI_MoveTable = { } end 
