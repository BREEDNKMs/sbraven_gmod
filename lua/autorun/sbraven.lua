local tblWeapons = { "raven_blade" } 

player_manager.AddValidModel( "Raven", "models/alvaroports/SBRavenPM.mdl" ) 
player_manager.AddValidHands( "Raven", "models/alvaroports/SBRavenVM.mdl", 0, "0000000" ) 

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

local co -- worker coroutine

local function EffectCheckerPass()
    -- one full pass over all ents' SB_EffectAlias; when this function returns the coroutine dies
    for _, ENT in ents.Iterator() do
        if not ENT.SB_EffectAlias then
            ENT.SB_EffectAlias = {}
        end

        -- if there are no effects for this ENT, yield once so we don't stall
        if not next(ENT.SB_EffectAlias) then
            coroutine.yield()
        else
            -- iterate effects; yield before each expensive lookup
            for Effect, EffectData in pairs(ENT.SB_EffectAlias) do
                coroutine.yield() -- yield BEFORE doing the expensive SBAI_GetEffectTable lookup

                -- safe lookup; pass ENT as the first argument
                local EffectTable = scripted_ents.Get("npc_sb_raven").SBAI_GetEffectTable(ENT, Effect)
                if not EffectTable then
                    -- table missing for this effect; remove it to keep things clean
                    StellarBlade.RemoveEffect(ENT, Effect)
                else
                    local LifeType = EffectTable.LifeType

                    if LifeType == "ESBEffectLifeType::EffectLifeType_Infinite" then
                        -- do nothing (infinite)
                    elseif LifeType == "ESBEffectLifeType::EffectLifeType_SkillDependent" then
                        if not ENT.SBAI_SkillTable then
                            StellarBlade.RemoveEffect(ENT, Effect)
                        end
                    elseif LifeType == "ESBEffectLifeType::EffectLifeType_StepDependent" then
                        if not ENT.SBAI_ActiveSkill then
                            StellarBlade.RemoveEffect(ENT, Effect)
                        end
                    elseif LifeType == "ESBEffectLifeType::EffectLifeType_IndependentTime" then
                        if EffectData and EffectTable.LifeTime and CurTime() > (EffectData.Time or 0) + EffectTable.LifeTime then
                            StellarBlade.RemoveEffect(ENT, Effect)
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
                end
            end
        end
    end

    -- completed a full pass; coroutine returns and becomes dead so it will be reconstructed next Think
end

hook.Add("Think", "StellarBlade_CheckEffects", function()
    local systime = SysTime()
    local bDisabled = false
	
	for _, self in ents.Iterator() do 
		if self.SB_EffectAlias then 
			for Effect, EffectTable in pairs(self.SB_EffectAlias) do 
				if !EffectTable then
                    -- table missing for this effect; remove it to keep things clean
                    StellarBlade.RemoveEffect(self, Effect)
                else
                    local LifeType = EffectTable.LifeType

                    if LifeType == "ESBEffectLifeType::EffectLifeType_Infinite" then
                        -- do nothing (infinite)
                    elseif LifeType == "ESBEffectLifeType::EffectLifeType_SkillDependent" then
                        if !self.SBAI_SkillTable then
                            StellarBlade.RemoveEffect(self, Effect)
                        end
                    elseif LifeType == "ESBEffectLifeType::EffectLifeType_StepDependent" then
                        if !self.SBAI_ActiveSkill then
                            StellarBlade.RemoveEffect(self, Effect)
                        end
                    elseif LifeType == "ESBEffectLifeType::EffectLifeType_IndependentTime" then
                        if EffectData and EffectTable.LifeTime and CurTime() > (EffectData.Time or 0) + EffectTable.LifeTime then
                            StellarBlade.RemoveEffect(self, Effect)
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
				end 
			end 
		end 
	end 

    -- if SERVER and not bDisabled then
        -- -- try to resume existing coroutine; if none exists or resume fails (coroutine finished / errored),
        -- -- create a fresh one and resume it once so it starts working immediately
        -- if not co or not coroutine.resume(co) then
            -- co = coroutine.create(EffectCheckerPass)
            -- coroutine.resume(co)
        -- end
    -- end

    -- print("time difference for this think interval:", SysTime() - systime, bDisabled)
end) 

-- flIntervalUsed: time interval (float)
-- Returns: moved, newPosition (Vector), newAngles (Angle), bMoveSeqFinished (bool)
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
			if ENT.SBAI_ActiveSkill and ENT.SBAI_ActiveSkill.Name then 
				StellarBlade.ProcessActiveSkill(ENT,ENT.SBAI_ActiveSkill) 
			end 
			if ENT.SBAI_ActiveShow then
				-- scripted_ents.Get("npc_sb_raven").SBAI_MaintainShow(ENT) 
				StellarBlade.MaintainShow(ENT) 
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

hook.Add("Think","StellarBlade_MaintainMoveTable", function() 
	for _,ent in ents.Iterator() do 
		StellarBlade.MaintainMoveTable(ent) 
	end 
	-- StellarBlade.CheckWeaponCollision(Entity(34),{Entity(1)}) 
end) 

hook.Add("EntityTakeDamage", "StellarBlade_DamageEffects", function(target, dmginfo)
	if target.SB_EffectAlias then
		for Effect, EffectTable in pairs(target.SB_EffectAlias) do
			local Damage = dmginfo:GetDamage()
			local CalculationValue = EffectTable.CalculationValue
			local ActorState1, ActorState2, ActorState3, ActorState4, ActorState5, ActorState6, ActorState7, ActorState8, ActorState9, ActorState10 = EffectTable.ActorState1, EffectTable.ActorState2, EffectTable.ActorState3, EffectTable.ActorState4, EffectTable.ActorState5, EffectTable.ActorState6, EffectTable.ActorState7, EffectTable.ActorState8, EffectTable.ActorState9, EffectTable.ActorState10 
			
			if EffectTable.StatType == "ESBActorStatType::ActorStatType_MinimumHP" and CalculationValue then
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
			elseif EffectTable.StatType == "ESBActorStatType::ActorStatType_HitDefenseLevel" then 
				dmginfo:ScaleDamage(CalculationValue) 
			end 
			
			if ActorState1 == "ESBActorState::ActorState_NoDamageNoHit" or ActorState2 == "ESBActorState::ActorState_NoDamageNoHit" or ActorState3 == "ESBActorState::ActorState_NoDamageNoHit" or ActorState4 == "ESBActorState::ActorState_NoDamageNoHit" or ActorState5 == "ESBActorState::ActorState_NoDamageNoHit" or ActorState6 == "ESBActorState::ActorState_NoDamageNoHit" or ActorState7 == "ESBActorState::ActorState_NoDamageNoHit" or ActorState8 == "ESBActorState::ActorState_NoDamageNoHit" or ActorState9 == "ESBActorState::ActorState_NoDamageNoHit" or ActorState10 == "ESBActorState::ActorState_NoDamageNoHit" then 
				return true 
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

StellarBlade.AddEffect = function(self,strEffect, ...) 
	local EffectTable = scripted_ents.Get("npc_sb_raven").SBAI_GetEffectTable(self, strEffect) 
	local curEffects = self.SB_EffectAlias

	if !curEffects then
		self.SB_EffectAlias = {}
		curEffects = self.SB_EffectAlias
	end

	-- initialize/overwrite effect entry
	-- print(strEffect) 
	curEffects[strEffect] = table.Copy(SB_EffectTable[1].Rows[strEffect]) 
	-- Entity(1):ChatPrint("effect added: "..strEffect.." to: "..tostring(self)) 
	-- print("effect added: "..strEffect.." to: "..tostring(self)) 
	-- print(curEffects) 
	-- PrintTable(curEffects) 
	curEffects[strEffect].Time = CurTime() 
	local curEffect = curEffects[strEffect] 

	-- process vararg key/value pairs
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
	local LifeType = EffectTable.LifeType 
	if LifeType == "ESBEffectLifeType::EffectLifeType_Infinite" then 
		-- curEffects[strEffect] = true 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_SkillDependent" then -- active during entirety of skill 
		-- curEffects[strEffect] = self.SBAI_SkillTable.SkillName 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_StepDependent" then 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_IndependentTime" then 
		-- curEffects[strEffect] = CurTime() + EffectTable.LifeTime 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_StanceDependent" then 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_CharacterGetupTime" then 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_ProjectileDependent" then 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_BeforeNextSkill" then 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_CharacterGroggyEndTime" then 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_NextSkillDependent" then 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_LevelSequenceDependent" then 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_EquipmentDependent" then 
	elseif LifeType == "ESBEffectLifeType::EffectLifeType_LevelSequenceDependentWithoutPlayable" then 
	end 
	
	local DispelFlagsArray = curEffect.DispelFlagsArray
	if type(DispelFlagsArray) == "table" and next(DispelFlagsArray) then
		local toRemove = {}
		for _, dispFlag in ipairs(DispelFlagsArray) do
			if dispFlag then
				for existName, existData in pairs(curEffects) do
					if existName != strEffect then -- don't remove the effect we just added
						local existFlag = existData and existData.Flag
						if existFlag == dispFlag or existName == dispFlag then
							toRemove[#toRemove + 1] = existName
						end
					end
				end
			end
		end 

		for _, name in ipairs(toRemove) do 
			StellarBlade.RemoveEffect(self, name) 
		end 
	end 
	
	StellarBlade.SetMoveTable(self,curEffect.MoveAlias) 
	
	local Action1, ActionValue1 = curEffect.Action1, curEffect.ActionValue1 
	StellarBlade.ApplyEffectAction(self,curEffect,Action1,ActionValue1) 
	local Action2, ActionValue2 = curEffect.Action2, curEffect.ActionValue2 
	StellarBlade.ApplyEffectAction(self,curEffect,Action2,ActionValue2) 
	local Action3, ActionValue3 = curEffect.Action3, curEffect.ActionValue3 
	StellarBlade.ApplyEffectAction(self,curEffect,Action3,ActionValue3) 
	local Action4, ActionValue4 = curEffect.Action4, curEffect.ActionValue4 
	StellarBlade.ApplyEffectAction(self,curEffect,Action4,ActionValue4) 
	local Action5, ActionValue5 = curEffect.Action5, curEffect.ActionValue5 
	StellarBlade.ApplyEffectAction(self,curEffect,Action5,ActionValue5) 
	
	local StatType = curEffect.StatType 
	
end 

StellarBlade.ApplyEffectAction = function(self,EffectTable,Action,ActionValue) 
	ParsedActionValue = StellarBlade.ParseTableStrings(ActionValue) 
	if Action == "ESBEffectAction::EffectAction_None" then 
	
	elseif Action == "ESBEffectAction::EffectAction_SkillCancel" then 
		-- print("calling EffectAction_SkillCancel") 
		self.SBAI_ActiveSkill = { } 
		self.SBAI_SkillTable = { } 
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

-- Updated AddEffectFromTable to accept the plain array table produced by ParseTableStrings
StellarBlade.AddEffectFromTable = function(self, tblEffect)
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

StellarBlade.RemoveEffect = function(self,strEffect) 
	self.SB_EffectAlias[strEffect] = nil 
end 

StellarBlade.RemoveEffectLifeTypes = function(self,strLifeType) 
	if !self.SB_EffectAlias then return end 
	for EffectName,EffectData in pairs(self.SB_EffectAlias) do 
		local EffectTable = scripted_ents.Get("npc_sb_raven").SBAI_GetEffectTable(self,EffectName) 
		if strLifeType == EffectTable.LifeType then 
			self.SB_EffectAlias[EffectName] = nil 
		end 
	end 
end 

StellarBlade.StartSkill = function(self,SkillName) 
	local CheckCooldown = self.SBAI_SkillTimers and self.SBAI_SkillTimers[SkillName] -- returns Time, ["M_Raven_SlashChain"] = 216 
	local SkillTable = SB_SkillTable[1].Rows[SkillName] 
	if !CheckCooldown or CheckCooldown and CurTime() >= CheckCooldown then 
		self.SBAI_SkillTable = SkillTable 
		local FirstSkillActiveAlias = SkillTable.FirstSkillActiveAlias 
		-- This now correctly handles all the data-driven setup for the first step 
		StellarBlade.SetSkillStep(self,FirstSkillActiveAlias) 
		if !self.SBAI_SkillTimers then self.SBAI_SkillTimers = { } end 
		self.SBAI_SkillTimers[SkillName] = CurTime() + SkillTable.CoolTime 
		Entity(1):ChatPrint("starting "..SkillName.." at CurTime:"..tostring(CurTime())) 
		return true 
	end 
	return false 
end 

StellarBlade.StartSkillCommand = function(self,SkillName) 
	local CheckCooldown = self.SBAI_SkillTimers[SkillName] -- returns Time, ["M_Raven_SlashChain"] = 216 
	local SkillCommandTable = SB_SkillCommandTable[1].Rows[SkillName]
	local SkillNameFromSkillCommandTable = SkillCommandTable.SkillAlias
	local SkillTable = SB_SkillTable[1].Rows[SkillNameFromSkillCommandTable] 
	if !CheckCooldown or CheckCooldown and CurTime() >= CheckCooldown then 
		self.SBAI_SkillTable = SkillTable 
		local FirstSkillActiveAlias = SkillTable.FirstSkillActiveAlias 
		-- This now correctly handles all the data-driven setup for the first step 
		self:SBAI_SetSkillStep(FirstSkillActiveAlias) 
		if !self.SBAI_SkillTimers then self.SBAI_SkillTimers = { } end 
		self.SBAI_SkillTimers[SkillName] = CurTime() + SkillTable.CoolTime 
		Entity(1):ChatPrint("starting "..SkillName.." at CurTime:"..tostring(CurTime())) 
		return true 
	end 
	return false 
end 

StellarBlade.SetShow = function(self,showpath) 
	-- scripted_ents.Get("npc_sb_raven").SBAI_SetShow(self,showPath) 
	SB_ImportJSON(showpath) 
	self.SBAI_ActiveShow = {["Time"] = CurTime(),["RunTime"] = CurTime()} 
	self.SBAI_ActiveShow.Dir = showpath 
	local showname = string.GetFileFromFilename( showpath ) 
	showname = string.StripExtension(showname) 
	self.SBAI_ActiveShow.Name = showname 
	self.SBAI_ActiveShow.Frame = 0 
	self.SBAI_ActiveShow.Stopped = false 
	showname = "SB_"..showname 
	-- self:SBAI_MaintainShow() 
	-- scripted_ents.Get("npc_sb_raven").SBAI_MaintainShow(self) 
	StellarBlade.MaintainShow(self) 
	return showname -- return true on animation play, false on not play 
end 

StellarBlade.MaintainShow = function(self) 
	local flRescale = 0.42 
	if !self.SBAI_ActiveShow or self.SBAI_ActiveShow.Stopped then return end
	if !self.SBAI_ActiveShow.Name then return end

	local showname = "SB_" .. self.SBAI_ActiveShow.Name
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
	local Elapsed = CurTime() - (self.SBAI_ActiveShow.RunTime or CurTime())
	self.SBAI_ActiveShow.Elapsed = (self.SBAI_ActiveShow.Elapsed or 0) + Elapsed
	self.SBAI_ActiveShow.RunTime = CurTime()

	-- Create triggered list if not yet present
	self.SBAI_ActiveShow.TriggeredKeys = self.SBAI_ActiveShow.TriggeredKeys or {}

	-- Iterate all entries (SBShowAnimKey, SBShowActorKey, SBShowSoundKey, etc.)
	for _, data in ipairs(showdata) do
		local props = data.Properties or {}
		local StartTime = props.StartTime or 0

		-- Skip if not reached yet or already triggered
		if self.SBAI_ActiveShow.Elapsed < StartTime then
			continue
		end
		if self.SBAI_ActiveShow.TriggeredKeys[data.Name] then
			continue
		end

		-- Mark as triggered
		self.SBAI_ActiveShow.TriggeredKeys[data.Name] = true
		-- Entity(1):ChatPrint("SBShowAnimKey: Triggered "..data.Name.." at time: "..(CurTime() - self.SBAI_ActiveShow.Time)) 
		
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
						self:NPC_StartScriptedActivity(anim, true) 
					end 
				elseif Target == "ESBShowActorTarget::ShowActorTarget_OtherActor" then 
					-- Optional: handle other actor animations 
				end 
			end 

		elseif data.Type == "SBShowActorKey" then
			local hidden = props.bUseActorHidden or false

			-- Helper: apply render state recursively
			local function ApplyRenderState(ent, hide)
				if not IsValid(ent) then return end

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

			-- Apply immediately
			ApplyRenderState(self, hidden)

			-- Auto-revert after Duration
			if props.Duration and props.Duration > 0 then
				timer.Simple(props.Duration, function()
					if IsValid(self) then
						ApplyRenderState(self, not hidden)
					end
				end)
			end

		elseif data.Type == "SBShowSoundKey" or data.Type == "SBShowCharSESoundKey" then
			local CuePath
			if data.Type == "SBShowCharSESoundKey" then
				local key = props.CharacterReactKey or props.CharacterVoiceKey
				local lookup = StellarBlade.LookupCharacterSound(self,key)
				CuePath = lookup and lookup.ObjectPath
				if CuePath then
					CuePath = string.gsub(CuePath, "/L10N/[^/]+", "")
				end
			else
				CuePath = props.SoundSoftObject and props.SoundSoftObject.AssetPathName
				if not CuePath and props.Sound then
					CuePath = props.Sound.ObjectPath
				end
			end

			if CuePath then
				CuePath = string.sub(CuePath, 6)
				CuePath = "addons/sbraven/data_static/SB/Content" .. CuePath
				CuePath = string.StripExtension(CuePath) .. ".json"

				local SoundScript = StellarBlade.BuildSoundScript(self,CuePath)
				if SoundScript then
					if SoundScript.Delay and SoundScript.Delay ~= 0 then
						timer.Simple(SoundScript.Delay, function()
							if IsValid(self) then
								self:EmitSound(SoundScript.SoundPath, 100, SoundScript.Pitch, SoundScript.Volume)
							end
						end)
					else
						self:EmitSound(SoundScript.SoundPath, 100, SoundScript.Pitch, SoundScript.Volume)
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
			if animData.Target == "ESBShowActorTarget::ShowActorTarget_OtherActor" and IsValid(self.SBAI_ActiveShow.OtherActor) then
				targetEnt = self.SBAI_ActiveShow.OtherActor
			end

			-- Interpolation logic
			local function AdvanceAnimBP()
				if not IsValid(self) or not IsValid(targetEnt) then return end
				if self.SBAI_ActiveShow ~= currentShow then
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
							if self.SBAI_ActiveShow ~= currentShow then return end

							local startVal = value
							local endVal = animData.RecoverValue
							local StartTime = CurTime()

							local function RecoverStep()
								if not IsValid(self) or not IsValid(targetEnt) then return end
								local rElapsed = CurTime() - StartTime
								local rNorm = math.Clamp(rElapsed / (animData.RecoverTime or 0.5), 0, 1)
								local v = Lerp(rNorm, startVal, endVal)
								ApplyValue(targetEnt, animData.Name, v)
								if rNorm < 1 and self.SBAI_ActiveShow == currentShow then
									timer.Simple(0.01, RecoverStep)
								end
							end

							RecoverStep()
						end)
					end
				end
			end

			-- Start interpolation
			local currentShow = self.SBAI_ActiveShow
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
			if not props then continue end

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

				if SocketName and EffectEntity:LookupAttachment(SocketName) and EffectEntity:LookupAttachment(SocketName) ~= 0 then
					local att = EffectEntity:GetAttachment(EffectEntity:LookupAttachment(SocketName))
					if att and att.Pos and att.Ang then
						worldPos = att.Pos
						worldAng = att.Ang
						-- Let effect know we used an attachment index (so engine can parent)
						ef:SetAttachment(EffectEntity:LookupAttachment(SocketName))
					end
				end
				if RelativeLocation then
					-- LocalToWorld(localPos, localAng, originPos, originAng)
					local finalPos, finalAng = LocalToWorld(RelativeLocation, relAng, worldPos, worldAng)
					worldPos, worldAng = finalPos, finalAng
				end
				
				-- RelativeLocation is now global 
				-- "RelativeRotation": {
				-- "Pitch": 110.0,
				-- "Yaw": -30.0,
				-- "Roll": 0.0
			  -- }, 
			  -- print("networking Ang:",Ang, "for:",AssetName) 
				ef:SetAngles(worldAng) 
				ef:SetEntity(EffectEntity) 
				ef:SetMagnitude(data.Properties.Duration or 0) -- use as effect timer 
				ef:SetOrigin(worldPos) -- contains finalized position 
				ef:SetScale(ParticleScale) -- scale 
				util.Effect(AssetName,ef) 
				debugoverlay.Cross(worldPos,10,2) 
				-- debugoverlay.Cross(Pos,10,5) 
			elseif data.Properties.bUsePhysParticle then 
				local PhysParticleSet = data.Properties.PhysParticleSet 
				local bPlayPhysParticleOnHitLocation = data.Properties.bPlayPhysParticleOnHitLocation 
				PhysParticleSet = PhysParticleSet.ObjectName 
			else 
				print("AssetName not found for "..data.Type) 
			end 
		elseif data.Type == "SBShowPlayShowKey" then -- play effect at given path 
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
			self.SBAI_ActiveShow = self.SBAI_ActiveShow or showName
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
					if self.SBAI_ActiveShow ~= showName then
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
				if self.SBAI_ActiveShow ~= showName then return end

				-- Blend in
				BlendToTarget(targetScale, blendIn)

				-- Stay at target for (duration - blend in - blend out)
				local holdTime = math.max(0, duration - (blendIn + blendOut))
				local totalActiveTime = blendIn + holdTime

				-- Blend out (back to 1x)
				timer.Simple(totalActiveTime, function()
					if not IsValid(self) then return end
					if not keyState.Active then return end
					if self.SBAI_ActiveShow ~= showName then return end
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

	-- Auto-stop at end
	if self.SBAI_ActiveShow.Elapsed >= endTime then
		self.SBAI_ActiveShow.Stopped = true
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
	local Type = SkillStepTable.Type -- get skill step type 
	local Duration = SkillStepTable.Duration 
	local bLookAtTarget = true 
    -- Determine the current target. Prioritize the locked target if it exists and is valid.
    local currentTarget = nil
    if IsValid(tbl.LockedTarget) then
        if tbl.LockedTarget:Alive() then
            currentTarget = tbl.LockedTarget
        else
            -- [NEW] Failsafe: If the locked target is dead, end the skill immediately.
            -- Entity(1):ChatPrint("Locked target died. Ending skill.")
            self.SBAI_ActiveSkill = {}
            return
        end
    else
        -- If there's no locked target, use the NPC's current enemy.
        currentTarget = self:IsNPC() and self:GetEnemy() or StellarBlade.PickTarget(self) 
    end

    -- [NEW] Handle persistent "bLookAtTarget": Keep looking at the target during the step
	-- local bLookAtTarget = SkillStepTable.bLookAtTarget 
    if bLookAtTarget and IsValid(currentTarget) then
        local angleToTarget = (currentTarget:GetPos() - self:GetPos()):Angle().y
        if self.SetIdealYawAndUpdate then self:SetIdealYawAndUpdate(angleToTarget, -1) end 
		if !self.SetIdealYawAndUpdate then self:SetEyeAngles(Angle(self:EyeAngles().x,angleToTarget,self:EyeAngles().z)) end 
    end 
	if Type == "ESBSkillActiveStepType::SkillActiveStepType_Parry" then -- parries incoming attack, used by eve, raven and some other npcs 
	-- to be filled 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Hit" then 
		local bEveryFrameHitCheck = SkillStepTable.bEveryFrameHitCheck 
		if bEveryFrameHitCheck then 
			-- if !self.SBAI_ActiveSkill.bEveryFrameHitCheck then 
				-- self.SBAI_ActiveSkill.bEveryFrameHitCheck = true 
				-- timer.Simple(0.01,function() 
					-- if IsValid(self) then 
						-- self:SBAI_CheckSkillHit(SkillStepTable,true) 
					-- end 
				-- end) 
			-- end 
			StellarBlade.CheckSkillHit(self,SkillStepTable) 
		else 
			StellarBlade.CheckSkillHit(self,SkillStepTable) 
		end 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Hold" then -- unused 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_SuperParry" then -- unused 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Item" then -- eve only: use item 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Guard" then -- eve only: put sword / wings in front to parry 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_None" then -- default action 
	
	end 

	-- Check if the duration for the current step has elapsed
	local Time = tbl.Time
	local EndTime = Time + Duration
	local now = CurTime()

	if now >= EndTime then
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
			self.SBAI_ActiveSkill = {}
		end

	else
		-- still inside step: decide whether to force a closer NextThink
		local GetAnimTimeInterval = self:GetAnimTimeInterval() or 0
		-- keep the minimum think interval (your original minimum was 0.1)
		GetAnimTimeInterval = (GetAnimTimeInterval > 0.1) and GetAnimTimeInterval or 0.1

		local remaining = EndTime - now -- seconds until we must advance

		-- If the remaining time is shorter than our usual animation/think interval,
		-- schedule a NextThink to wake us right when the step ends (or slightly before).
		if remaining < GetAnimTimeInterval then
			-- clamp to a small positive value to avoid 0 or negative NextThink
			local delta = math.max(0.01, remaining)
			-- self:NextThink(now + delta)
			-- DEBUG
			-- print(string.format("scheduling NextThink in %.6f (remaining %.6f, animInterval %.6f) at CurTime: %.6f",delta, remaining, GetAnimTimeInterval, now))
		end

		-- optional: debug print showing why we didn't reschedule
		-- print(string.format("Duration is:\t%.3f\t%.6f\t%.3f (remaining %.6f) -- no NextThink change",Duration, GetAnimTimeInterval, Time, remaining, Name)) 
		-- print(Name) 
	end 
end 

StellarBlade.CheckSkillHit = function(self,SkillStepTable,bEveryFrameHitCheck) 
	local ID = SkillStepTable.ID 
	-- trace attack from weapon / radius / sphere / whatever is AttackDirection and deal damage 
	-- for now, do default damage action 
	local event,etime,cycle,types,options = util.GetAnimEventIDByName("EVENT_WEAPON_MELEE_HIT"), CurTime(), self:GetCycle(), 0, self.PhysicAttackPower or 100 
	-- adjust melee damage depending on step options 
	options = options * SkillStepTable.SkillAttackDamageRate
	local enemy = self.GetEnemy and self:GetEnemy() or StellarBlade.PickTarget(self) 
	-- print(enemy) 
	if self.GetEnemy and !IsValid(self:GetEnemy()) then -- pick random enemy 
		if #self:GetKnownEnemies() > 0 then 
			enemy = self:GetKnownEnemies()[1] 
		end 
	end 
	local tableofhittargets 
	-- to do: update: use Parry for %10 damage 
	-- use %0 damage for JustParry 
	-- print("in CheckSkillHit") 
	if IsValid(enemy) then 
		local curHealth = enemy:Health()
		-- tableofhittargets = self:NPC_MeleeAttack(event,etime,cycle,types,options) 
		-- print("invoking TargetFilter with filtername:",SkillStepTable.OverrideTargetFilterAlias) 
		local TargetFilterAlias = SkillStepTable.OverrideTargetFilterAlias 
		if !TargetFilterAlias or TargetFilterAlias == "None" then 
			if self.SBAI_SkillTable then TargetFilterAlias = self.SBAI_SkillTable.TargetFilterAlias end -- default to SkillTable 
		end 
		tableofhittargets = StellarBlade.TargetFilter(self,TargetFilterAlias) 
		-- originally, characters have a SBCollisionGroupComponent 
		-- they lead to character's collision group data asset such as CH_M_NA_53_Raven_Collision 
		-- those assets have names, bones used, pos and ang data such as AttackCollisionGroupArray[1].GroupName = "Collision_Weapon"
		print("SkillStepTable.AttackCollisionGroupArray",SkillStepTable.AttackCollisionGroupArray) 
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
		for k,v in pairs(tableofhittargets) do 
			local NearestPoint = scripted_ents.Get("cycler_actor2").NearestPoint2(v,self:GetShootPos()) 
			local dmg = DamageInfo() 
			dmg:SetAttacker(self) 
			dmg:SetWeapon(IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon() or self) 
			dmg:SetInflictor(IsValid(self:GetActiveWeapon()) and self:GetActiveWeapon() or self) 
			dmg:SetDamage(options) 
			dmg:SetReportedPosition(self:GetShootPos()) 
			dmg:SetDamageType(DMG_SLASH+DMG_ALWAYSGIB) 
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
		tableofhittargets = scripted_ents.Get("npc_sb_raven").NPC_MeleeAttack(self,event,etime,cycle,types,options) 
	end 
    --- END: Added Damage Check Logic --

	for k,v in pairs(tableofhittargets) do 
		if IsValid(v) and v != self then 
			local Disposition = self.Disposition and self:Disposition(v) or v.Disposition and v:Disposition(self) or D_NU 
			if Disposition == D_HT or Disposition == D_FR then 
				if SkillStepTable.SkillResultAlias then -- applied on self and target 
					-- self:SBAI_SetSkillStep() 
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

StellarBlade.TargetFilter = function(ent, filter) 
	local flRescale = 1 
    local TargetFilterTable = _G["SB_TargetFilterTable"][1].Rows[filter] 
	if !IsValid(ent) then error("Expected Entity, got NULL Entity!") return end 
	if !filter then print("input a filter") end 
    if !TargetFilterTable then return {ent:GetEnemy()} end 
	
	local tableInsert = table.insert
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
    local forward = ent:GetAimVector() 
	local right = ent:GetRight() 
	local up = ent:GetUp() 
	
	local ShapeForwardDistance = TargetFilterTable.ShapeForwardDistance * flRescale 
	local ShapeRightDistance = TargetFilterTable.ShapeRightDistance * flRescale 
	local ShapeUpDistance = TargetFilterTable.ShapeUpDistance * flRescale 
	
	local TargetCheckValue1 = TargetFilterTable.TargetCheckValue1 * flRescale 
	local TargetCheckValue2 = TargetFilterTable.TargetCheckValue2 * flRescale 
	local TargetCheckValue3 = TargetFilterTable.TargetCheckValue3 * flRescale 
	
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
    if shape == "ESBCheckShape::CheckShape_3DArc" then
        local range = FarDistance or 0
        local angle = math.max(0, math.min(TargetFilterTable.TargetCheckValue1 or 0, 180))
        local angle_cos = math.cos(math.rad(angle))
        candidates = ents.FindInCone(offsetOrigin, forward, range, angle_cos)
    elseif shape == "ESBCheckShape::CheckShape_3DCircle" then
        local radius = TargetCheckValue1 or (FarDistance or 0)
        candidates = ents.FindInSphere(offsetOrigin, radius)
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
	Target_SpecifiedTargetes                 = 2,
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
]]
StellarBlade.CheckWeaponCollision = function(self, entityList) 
	-- print(owner) 
	if !SERVER then return end 
 	local debugColor = Color(255,0,0,5) 
    local wep = self:GetActiveWeapon() 
	if !IsValid(wep) then return entityList end 
    local mins, maxs = wep:GetCollisionBounds() 
	if wep:GetClass() == "raven_blade" then 
		mins = mins * -1 
		maxs = maxs * -1 
	end 

    -- Get the right-hand bone transform
    local boneIndex = self:LookupBone("ValveBiped.Bip01_R_Hand")

    local bonePos, boneAng = self:GetBonePosition(boneIndex)

    -- Base direction vectors
    local forward = boneAng:Forward()
    local right   = boneAng:Right()
    local up      = boneAng:Up()

    -- Extend ray roughly along the weapon’s forward axis
    local reach = maxs:Length() * 0 -- 0 because reach scalar is disabled 
    local startPos = bonePos 
	-- debugoverlay.Cross(startPos, 32, 0.1) 
    local endPos = bonePos + up * -reach 
	-- debugoverlay.Cross(endPos, 32, 0.1) 

    -- Convert mins/maxs into world-space oriented bounding box corners
    -- by applying the bone’s rotation
    local worldMins, worldMaxs = LocalToWorld(mins, Angle(), vector_origin, boneAng)
    local worldMins2, worldMaxs2 = LocalToWorld(maxs, Angle(), vector_origin, boneAng)

    -- Because LocalToWorld rotates each vector around origin, we must find the
    -- actual numeric min/max bounds after rotation.
    local orientedMins = Vector(
        math.min(worldMins.x, worldMaxs.x, worldMins2.x, worldMaxs2.x),
        math.min(worldMins.y, worldMaxs.y, worldMins2.y, worldMaxs2.y),
        math.min(worldMins.z, worldMaxs.z, worldMins2.z, worldMaxs2.z)
    )
    local orientedMaxs = Vector(
        math.max(worldMins.x, worldMaxs.x, worldMins2.x, worldMaxs2.x),
        math.max(worldMins.y, worldMaxs.y, worldMins2.y, worldMaxs2.y),
        math.max(worldMins.z, worldMaxs.z, worldMins2.z, worldMaxs2.z)
    )

    -- Perform the oriented trace
    local hitEnts = ents.FindAlongRay(startPos, endPos, orientedMins, orientedMaxs) 
	-- print("ents in blade range") 
	-- PrintTable(entityList) 
    -- Filter to include only given entity list members
    local filtered = {} 
    for _, ent in ipairs(hitEnts) do
        if IsValid(ent) and table.HasValue(entityList, ent) then
			debugColor = Color(0,255,0,5) 
            table.insert(filtered, ent)
        end
    end

    -- Optional debug visualization 
	-- debugoverlay.BoxAngles(startPos, mins, maxs, boneAng, 0.1, debugColor) 
	-- debugoverlay.Line(startPos, endPos, 0.1, Color(255, 255, 0), false) 

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
    if not IsValid(owner) or not istable(entityList) then return {} end
    hitboxSet = hitboxSet or 0

    -- Convert bone name → hitbox ID if string was given
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

    if not isnumber(hitboxID) then return {} end

    -- Fetch hitbox bounds in world space
    local mins, maxs = owner:GetHitBoxBounds(hitboxID, hitboxSet)
    if not mins or not maxs then return {} end

    -- Fetch hitbox orientation
    local boneIndex = owner:GetHitBoxBone(hitboxID, hitboxSet)
    if not boneIndex then return {} end

    local bonePos, boneAng = owner:GetBonePosition(boneIndex)
    if not bonePos or not boneAng then return {} end

    -- Optionally visualize the hitbox for debugging
    -- debugoverlay.BoxAngles(bonePos, mins, maxs, boneAng, 0.1, Color(0, 255, 0, 8))

    -- Build a list of entities intersecting this hitbox
    local collided = {}
    for _, target in ipairs(entityList) do
        if IsValid(target) and target ~= owner then
            -- Check a few sample points around the target’s bounding box
            local tmins, tmaxs = target:OBBMins(), target:OBBMaxs()
            local corners = {
                target:LocalToWorld(tmins),
                target:LocalToWorld(tmaxs),
                target:LocalToWorld(Vector(tmins.x, tmaxs.y, tmins.z)),
                target:LocalToWorld(Vector(tmaxs.x, tmins.y, tmaxs.z)),
                target:LocalToWorld(Vector(tmaxs.x, tmaxs.y, tmins.z)),
                target:LocalToWorld(Vector(tmins.x, tmins.y, tmaxs.z)),
                target:LocalToWorld(Vector(tmins.x, tmaxs.y, tmaxs.z)),
                target:LocalToWorld(Vector(tmaxs.x, tmins.y, tmins.z)),
            }

            -- If any corner is inside this hitbox’s OBB, we count it as a hit
            for _, point in ipairs(corners) do
                -- Fast built-in Garry's Mod OBB test
                if owner:IsPointInBounds(point) then
                    table.insert(collided, target)
                    break
                end
            end
        end
    end

    return collided
end


StellarBlade.IsInJustParry = function(ent) 
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
        self.SBAI_ActiveSkill = {} -- Clear active skill if the next step is invalid
        return
    end

    -- Store the current skill step's data
    self.SBAI_ActiveSkill = { Name = strSkill, Time = CurTime(), Data = SkillStepTable }

    -- [NEW] Handle `bRetargeting`: Lock onto the current target if false
    if SkillStepTable.bRetargeting == false and self.GetEnemy then
        self.SBAI_ActiveSkill.LockedTarget = self:GetEnemy()
    else
        -- If retargeting is allowed, ensure no previous target is locked
        self.SBAI_ActiveSkill.LockedTarget = nil
    end

    -- [NEW] Handle `StopSelfMove`: Stop the NPC from moving if true 
    if SkillStepTable.StopSelfMove and self.StopMoving then 
        self:StopMoving(true) 
        self:ClearGoal() 
    end 

    -- [NEW] Handle initial `bLookAtTarget`: Turn to face the target at the start of the step
    if SkillStepTable.bLookAtTarget and self.SetIdealYawAndUpdate then
        local target = self.SBAI_ActiveSkill.LockedTarget or self:GetEnemy()
        if IsValid(target) then
            local angleToTarget = (target:GetPos() - self:GetPos()):Angle().y
            self:SetIdealYawAndUpdate(angleToTarget, -1) -- -1 for automatic turn speed
        end
    end

    -- Apply the animation/movement for this step
    local SelfMoveAliasArray = SkillStepTable.SelfMoveAliasArray
    for _, SelfMoveAlias in pairs(SelfMoveAliasArray) do
        StellarBlade.SetMoveTable(self,SelfMoveAlias)
    end
	-- activate TargetMoveAliasArray on target 
	
	-- activate ShowPath "ShowPath": "CH_M_NA_53_Raven/Skill/M_Raven_Slash", 
	if SkillStepTable.ShowPath != "None" then 
		local showpath = "addons/sbraven/data_static/SB/Content/Art/Show/" 
		showpath = showpath..SkillStepTable.ShowPath..".json" 
		StellarBlade.SetShow(self,showpath) 
	end 
	if #SkillStepTable.UsableTargetProjectileAliasArray > 0 then 
		for i = 1,#SkillStepTable.UsableTargetProjectileAliasArray do 
			local event,etime,cycle,types,options 
			if self.NPC_RangedAttack then 
				self:NPC_RangedAttack(event,etime,cycle,types,options) 
			else 
				self.NPC_RangedProjectile = "proj_unreali_dispersionammo" 
				scripted_ents.Get("npc_unreali_female").NPC_RangedAttack(self,event,etime,cycle,types,options) 
			end 
		end 
	end 
end 

--==============================================================================
-- HELPER: Curve Loading and Evaluation
--==============================================================================
--[[
    Loads a CurveFloat JSON file by parsing the specific path format from the move tables.
    @param curveDataPath The raw path string from the CharacterMoveTable.
]]
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
    if not SB_CharacterMoveTable or not SB_CharacterMoveTable[1] or not SB_CharacterMoveTable[1].Rows then
        print("ERROR: SB_CharacterMoveTable is not available.")
        return false
    end

    local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[strEffect]
    if not CharacterMoveTable then
        print("no move table", strEffect)
        return false
    end

    if not self.SBAI_MoveStep then
        self.SBAI_MoveStep = {}
    end

    local newMoveStep = {
        ["MoveArrayName"] = strEffect,
        ["StartTime"] = CurTime() + (CharacterMoveTable.StartDelayTime or 0), 
        ["RunTime"] = CurTime() 
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
		if CharacterMoveTable.bStopWhenInvalidNavigation and not self:IsGoalActive() then 
			return true 
		end 
	end 
    return false 
end 

StellarBlade.MaintainMoveTable = function(self) -- adapt this to work between all entities, including players and npcs 
    if self.SBAI_MoveStep and #self.SBAI_MoveStep > 0 then
        local currentAng = self:GetLocalAngles()
        local totalAngDelta = Angle(0, 0, 0)

        -- Iterate backwards for safe removal
        for i = #self.SBAI_MoveStep, 1, -1 do
            local moveStep = self.SBAI_MoveStep[i]
			
			local flInterval = CurTime() - moveStep.RunTime 
			moveStep.RunTime = CurTime() 
			
            if CurTime() < moveStep.StartTime then continue end

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
			local enemy = self.GetEnemy and self:GetEnemy() 
			if !self.GetEnemy then 
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

            if MoveType == "ESBMoveTransformType::MoveTransformType_RootMotion" then
				-- print("root motion") 
                local RootMotionDataPath = string.StripExtension(string.GetFileFromFilename(CharacterMoveTable.RootMotionDataPath))
                local RootMotion = _G["SB_" .. RootMotionDataPath]
                if RootMotion then
                    local posOffset, angOffset = StellarBlade.GetRootMotionTransform(RootMotion, moveStep.StartTime)
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
						movePosDelta = vecMoveDirection * posDelta.x + vecMoveDirection:Cross(Vector(0,0,-1)) * posDelta.y + vecMoveDirection:Cross(Vector(0,1,0)) * posDelta.z 
						-- movePosDelta = vecMoveDirection * posDelta 
                        moveStep.PrevPosOffset = posOffset 
                        moveStep.PrevAngOffset = angOffset 
                    end 
                end 
				-- movePosDelta = movePosDelta * (easedNow - easedPrev) -- is the RootMotion influenced from interptype? 
            elseif MoveType == "ESBMoveTransformType::MoveTransformType_Static" then
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
                local forwardMove = CharacterMoveTable.ForwardValue or 0
                local rightMove = CharacterMoveTable.RightValue or 0
                local upMove = CharacterMoveTable.UpValue or 0
                local totalLocalDisplacement = Vector(forwardMove, rightMove, upMove)
                local localDisplacementDelta = totalLocalDisplacement * (easedNow - easedPrev) 
                movePosDelta = vecMoveDirection * localDisplacementDelta.x + vecMoveDirection:Cross(Vector(0,0,-1)) * localDisplacementDelta.y + vecMoveDirection:Cross(Vector(0,1,0)) * localDisplacementDelta.z
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
			-- movePosDelta = movePosDelta * (easedNow - easedPrev)
			-- print(easedNow,easedPrev) 
			movePosDelta = movePosDelta * flRescale 
			-- print(movePosDelta) 

            -- Apply this move's delta and check for collision failure
            local collisionFailed = false
            if movePosDelta:LengthSqr() > 0.001 then
                local moveSuccess = true
                local targetPosForThisMove = self:GetPos() + movePosDelta

                if CharacterMoveTable.bOnGround and self.MoveGroundStep then 
                    if self:MoveGroundStep(targetPosForThisMove) == 0 then moveSuccess = false end 
                else 
                    local moveResult = IterativeHybridMoveLimit(self, self:GetPos(), targetPosForThisMove)
                    self:SetLocalPos(moveResult.vEndPosition)
                    if moveResult.fStatus != "OK" then moveSuccess = false end
                end

                if !moveSuccess and CharacterMoveTable.bStopWhenCollision then
                    -- print("removing motion due to collision for", name) 
                    table.remove(self.SBAI_MoveStep, i)
                    collisionFailed = true
                end
            end

            -- Only process expiration and add angle delta if the move wasn't removed for collision
            if !collisionFailed then
                totalAngDelta = totalAngDelta + moveAngDelta
                
                if CurTime() > CurEndTime or StellarBlade.ShouldCancelMoveTable(self,moveStep) then
                    if CharacterMoveTable.bZeroVelocityWhenEnd then
                        self:SetLocalVelocity(Vector(0,0,0))
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
]]
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
	if !self.SB_PickTargetTime or self.SB_PickTargetTime and Time > self.SB_PickTargetTime then 
		local bestAim, bestDist, FireDir, projStart = -1, 2500 
		local PickTarget = scripted_ents.Get("proj_unreali_skaarjprojectile").PickTarget(self,-1) 
		self.SB_PickTarget = PickTarget 
		return PickTarget 
	else 
		return self.SB_PickTarget 
	end 
end 


StellarBlade.ClearMoveTable = function(self) self.SBAI_MoveStep = { } end 
