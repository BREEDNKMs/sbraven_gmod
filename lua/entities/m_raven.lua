AddCSLuaFile() 

-- Define the path to your JSON file relative to the "garrysmod" folder.
IterativeHybridMoveLimit = include("includes/custommoveprobe.lua") 
include("includes/raven_soundscripts.lua") 
include("includes/curframe.lua") 

local className = string.GetFileFromFilename(ENT.Folder)
local charData = SB_CharacterTable[1].Rows[className]

local tblWeapons = { "raven_blade" } 
local NPC = { 
	Name = "Raven (Friend)", 
	Class = "m_raven", 
	Category = "Other", 
	Weapons = tblWeapons, 
	Model = "models/alvaroports/sbravenpm.mdl", 
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PLAYER } 
} 

list.Set( "NPC", "CH_M_NA_53", NPC ) 

NPC = { 
	Name = "Raven (Enemy)", 
	Class = "m_raven", 
	Category = "Other", 
	Weapons = tblWeapons, 
	Model = "models/alvaroports/sbravenpm.mdl", 
	KeyValues = { citizentype = 4, Numgrenades = 5, npcclass = CLASS_PORTAL_TURRET } 
} 

list.Set( "NPC", "CH_M_NA_53_enemy", NPC ) 

local strRealm = SERVER and "SERVER" or "CLIENT" 

-- stuff related to health, shield is in CharacterTable.json 
-- skilltable has skill information and the skill tree it starts from SkillActiveStepTable 
-- SelectSchedule accesses M_Raven_AI.json and starting from root node "ObjectName": "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_38'" 
-- checking whether the target & self is alive 
-- then proceeds to child nodes 
local flRescale = 0.42 
ENT.Base = "npc_unreali_female" 
ENT.Type 			= "ai" 
ENT.Spawnable = false 
ENT.AdminOnly = false 
ENT.PrintName		= "Raven" 
ENT.Author			= "DevilHawk" 

-- Merge CharacterTable properties while protecting GMod engine fields
for k, v in pairs(charData) do
	if k ~= "Type" and k ~= "Base" then
		ENT[k] = v
	end
end
ENT.CharacterType = charData.Type
ENT.NPC_AlertSound	= "" 
ENT.NPC_IdleSound 	= "" 
ENT.NPC_GroupIdleSound 	= "" 
ENT.NPC_MeleeHitSound = "Unreali_Nali.MeleeHit" 
ENT.NPC_PainSound 	= "NPC_Raven.PainSound" 
ENT.NPC_PainSoundWater 	= "Unreali_Female.HurtUnderWater" 
ENT.npc_health 		= ENT.MaxHP -- "MaxHP": 248304, "MaxShield": 4805, 
ENT.npc_model		= "models/alvaroports/sbravenpm.mdl" 
ENT.bHasInnateMelee1 = true 
ENT.m_fMaxYawSpeed = 360 -- "RotateAnglePerSecond": 360.0, 
ENT.SBAI_BlackBoard = { } 
ENT.SBAI_bInBackgroundTask = false 
ENT.SB_EffectAlias = { } 
ENT.SBAI_ActiveShow = { } 
ENT.SBAI_SkillTimers = { } 
-- State & Behavior Registries
ENT.bUseFuncTankBehavior = false 
ENT.flScheduleStrategyType = 1 

-- 4. Dynamic Asset Imports (Soundset & BehaviorTree)
if charData.OverrideCharacterSoundSet and charData.OverrideCharacterSoundSet ~= "" then
	local css = string.match(charData.OverrideCharacterSoundSet, "'(.-)'") or charData.OverrideCharacterSoundSet
	ENT.CharacterSoundSetPath = "data_static/SB/Content" .. string.StripExtension(string.sub(css, 6)) .. ".json"
else
	ENT.CharacterSoundSetPath = "data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_53_Raven.json"
end
SB_ImportJSON(ENT.CharacterSoundSetPath) 

ENT.EVE_CharacterSoundSetPath = "data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_PC_EVE.json" 

local BehaviorTreeRes = "data_static/SB/Content" .. string.sub(charData.BehaviorTreeRes, 6) .. ".json"
ENT.BehaviorTreeRes = BehaviorTreeRes
SB_ImportJSON(BehaviorTreeRes) 

function ENT:Initialize() 
	scripted_ents.Get("cycler_actor2").Initialize(self) 
	-- start effects in CharacterStanceTable 
	StellarBlade.ActorStats(self) -- initialize stats if we haven't 
	-- if SERVER and self.StartEffect then 
		-- local StartEffect = StellarBlade.ParseTableStrings(self.StartEffect) 
		-- StellarBlade.AddEffectFromTable(self,StartEffect) 
	-- end 
	
	-- start effects in CharacterTable 
end 

function ENT:SBAI_GetEffectTable(strEffect) 
	local EffectTable = SB_EffectTable[1].Rows[strEffect] 
	return EffectTable 
end 

-- ============================================================================
-- STELLAR BLADE AI: UNREAL ENGINE 4 BEHAVIOR TREE RUNTIME REPLICATION
-- ============================================================================

-- Tick the runtime tree: manages coroutine lifecycle and clean tree cycling
function ENT:SBAI_RunBehavior()
    -- 1. Create coroutine if missing or dead (restarts clean cycle from root)
    if not self._sbaico or coroutine.status(self._sbaico) == "dead" then
        self:SBAI_InitTree()

        if not self.SBAI_TreeRootID then
            ErrorNoHalt("[SBAI] Error: Cannot run behavior, TreeRootID is missing!\n")
            return false
        end

        self._sbaico = coroutine.create(function()
            return self:SBAI_SelectTask(self.SBAI_TreeRootID)
        end)
    end

    -- 2. Resume coroutine safely
    if coroutine.status(self._sbaico) == "suspended" then
        -- Observer checks run every tick prior to resumption to evaluate FlowAbort modes
        self:SBAI_CheckObservers()

        local ok, ret = coroutine.resume(self._sbaico)
        if not ok then
            ErrorNoHalt("[SBAI] Behavior coroutine error: " .. tostring(ret) .. "\n")
            self._sbaico = nil
            self.SBAI_RuntimeState = {}
            self.SBAI_ExecutionStack = {}
            return false
        else
            if coroutine.status(self._sbaico) == "dead" then
                self._sbaico = nil
                return ret
            else
                return nil -- Latent task still in-progress
            end
        end
    end

    return false
end

-- Phase 1: Indexing behavior tree JSON structures
function ENT:SBAI_IndexTree()
    local AITable = "SB_" .. string.StripExtension(string.GetFileFromFilename(self.BehaviorTreeRes))
    local rawTable = _G[AITable]
    if not rawTable then
        ErrorNoHalt("[SBAI] BehaviorTreeRes global table not found! Cannot index Behavior Tree.\n")
        return false
    end

    self.SBAI_NodeLookup = {}
    self.SBAI_TreeRootID = nil

    for _, node in ipairs(rawTable) do
        local t = node.Type
        local name = node.Name
        local outer = node.Outer

        if t and name and outer then
            local fullID = string.format("%s'%s:%s'", t, outer, name)
            self.SBAI_NodeLookup[fullID] = node
        end

        if t == "BehaviorTree" and node.Properties and node.Properties.RootNode then
            self.SBAI_TreeRootID = node.Properties.RootNode.ObjectName
        end
    end

    if not self.SBAI_TreeRootID then
        ErrorNoHalt("[SBAI] Error: Could not find 'BehaviorTree' entry or RootNode property.\n")
        return false
    end

    return true
end

-- Phase 2: State Initialization
function ENT:SBAI_InitTree()
    self.SBAI_RuntimeState = {}
    self.SBAI_ExecutionStack = {}
    self.SBAI_bInBackgroundTask = false
    self.CurrentBranch = nil
    self._sbaico = nil

    if not self.SBAI_NodeLookup then
        self:SBAI_IndexTree()
    end
end

-- Helper: safely set a runtime state value for a node
function ENT:SBAI_SetNodeState(nodeID, key, value)
    if not self.SBAI_RuntimeState[nodeID] then
        self.SBAI_RuntimeState[nodeID] = {}
    end
    self.SBAI_RuntimeState[nodeID][key] = value
end

-- Helper: safely get a runtime state value
function ENT:SBAI_GetNodeState(nodeID, key)
    local state = self.SBAI_RuntimeState[nodeID]
    if state then return state[key] end
    return nil
end

-- Evaluates a single decorator node (supporting built-in and composite decorators)
function ENT:SBAI_EvaluateSingleDecorator(decoNode, decoID)
    local rawName = decoNode.Type or decoNode.Name

    -- Support for Composite Decorators (AND, OR, NOT graphs)
    if rawName == "BTDecorator_Composite" or rawName == "SBBTDecorator_Composite" then
        local props = decoNode.Properties or {}
        local logicType = props.LogicType or "AND" -- "AND", "OR", "NOT"
        local subDecorators = props.SubDecorators or {}

        if logicType == "AND" then
            for _, subRef in ipairs(subDecorators) do
                local subNode = self.SBAI_NodeLookup[subRef.ObjectName]
                if subNode and not self:SBAI_EvaluateSingleDecorator(subNode, subRef.ObjectName) then
                    return false
                end
            end
            return true
        elseif logicType == "OR" then
            for _, subRef in ipairs(subDecorators) do
                local subNode = self.SBAI_NodeLookup[subRef.ObjectName]
                if subNode and self:SBAI_EvaluateSingleDecorator(subNode, subRef.ObjectName) then
                    return true
                end
            end
            return false
        elseif logicType == "NOT" then
            if subDecorators[1] then
                local subNode = self.SBAI_NodeLookup[subDecorators[1].ObjectName]
                if subNode then
                    return not self:SBAI_EvaluateSingleDecorator(subNode, subDecorators[1].ObjectName)
                end
            end
            return true
        end
    end

    -- Standard single decorator evaluation
    local funcName = string.gsub(rawName, "^SBBTDecorator_", "")
    funcName = string.gsub(funcName, "^BTDecorator_", "")

    if self[funcName] then
        local success = self[funcName](self, decoNode.Properties or {}, decoID)
        if decoNode.Properties and decoNode.Properties.bInverseCondition then
            success = not success
        end
		-- print(self,decoID,"returned:",success,"bInverseCondition is:",decoNode.Properties.bInverseCondition,CurTime()) 
        return success == true
    else
        ErrorNoHalt("[SBAI] Missing Decorator: " .. funcName .. " on " .. self:GetClass() .. "\n")
        return false
    end
end

-- Decorator evaluation for edge links
-- All decorators of a link must pass (AND, stops at the first failure like UE). Used when a link is ENTERED.
function ENT:SBAI_EvaluateEdge(childEntry)
	if !childEntry.Decorators then return true end
	for _, decoRef in ipairs(childEntry.Decorators) do
		if !self:SBAI_EvaluateDecorator(decoRef) then return false end
	end
	return true
end

function ENT:SBAI_GetAbortMode(decoRef)
	local decoNode = self.SBAI_NodeLookup[decoRef.ObjectName]
	if !decoNode then return "None" end

	local funcName = string.gsub(decoNode.Type or decoNode.Name, "^SBBTDecorator_", "")
	if self.SBAI_NonObservableDecorators[funcName] then return "None" end

	local mode = decoNode.Properties.FlowAbortMode
	if isstring(mode) then
		if string.find(mode, "Both") then return "Both" end
		if string.find(mode, "LowerPriority") then return "LowerPriority" end
		if string.find(mode, "Self") then return "Self" end
	end
	if self.SBAI_TickingDecorators[funcName] then return "Self" end
	return "None"
end

-- UE OnNodeActivation: runs ENT:<DecoratorName>_Activate(props, decoID) for every decorator of an entered link
function ENT:SBAI_NotifyActivation(childEntry)
	if !childEntry.Decorators then return end
	for _, decoRef in ipairs(childEntry.Decorators) do
		local decoNode = self.SBAI_NodeLookup[decoRef.ObjectName]
		if decoNode then
			local fn = self[string.gsub(decoNode.Type or decoNode.Name, "^SBBTDecorator_", "") .. "_Activate"]
			if fn then fn(self, decoNode.Properties, decoRef.ObjectName) end
		end
	end
end

-- Applies Additive Blackboard decorators when entering a child composite branch
function ENT:SBAI_ApplyDecoratorSets(childEntry)
    if not childEntry.Decorators then return end
    for _, decoRef in ipairs(childEntry.Decorators) do
        local decoNode = self.SBAI_NodeLookup[decoRef.ObjectName]
        if decoNode and (decoNode.Type == "SBBTDecorator_SbBlackboard" or decoNode.Name == "SBBTDecorator_SbBlackboard") then
            if decoNode.Properties then
                self:SbBlackboard_ApplySet(decoNode.Properties)
            end
        end
    end
end

-- Aborts a node and cleans up active resources (animations, movement, timers)
function ENT:SBAI_AbortNode(nodeID)
    if not nodeID then return end
    local nodeData = self.SBAI_NodeLookup[nodeID]
    if not nodeData then return end

    -- Clean up running tasks
    if nodeData.Type and string.find(nodeData.Type, "Task") then
        local rawName = nodeData.Type or nodeData.Name
        local taskName = string.gsub(rawName, "^SBBTTask_", "")

        -- 1. Skill cancellation
        if taskName == "SbUseSkill" then
            if self.SBAI_SkillStep then
                StellarBlade.SBAI_SkillStep.Remove(self.SBAI_SkillStep) 
            end
            -- if self.StopSkill then pcall(self.StopSkill, self) end
            if self.NPC_StopScriptedActivity then self:NPC_StopScriptedActivity() end
            -- if self.ResetIdealActivity then self:ResetIdealActivity(ACT_IDLE) end

        -- 2. Show cancellation
        elseif taskName == "SbPlayShow" then
            local showObj = self:SBAI_GetNodeState(nodeID, "hasStarted")
            if istable(showObj) and showObj.Remove then
                pcall(showObj.Remove, showObj)
            end

        -- 3. Navigation cancellation
        elseif taskName == "SbCautionToTarget" or taskName == "SbMoveToTarget" or taskName == "SbMoveToHome" then
            if self.StopMoving then self:StopMoving(true) end
            if self.ClearGoal then self:ClearGoal() end
            if self.ResetIdealActivity then self:ResetIdealActivity(ACT_IDLE) end
        end

        -- Wipe node memory completely
        self.SBAI_RuntimeState[nodeID] = nil
    end

    -- Recursively abort composite children
    if nodeData.Properties and nodeData.Properties.Children then
        for _, childEntry in ipairs(nodeData.Properties.Children) do
            local childID = childEntry.ChildComposite and childEntry.ChildComposite.ObjectName
                         or childEntry.ChildTask and childEntry.ChildTask.ObjectName
            if childID then
                self:SBAI_AbortNode(childID)
            end
        end
    end

    self.SBAI_RuntimeState[nodeID] = nil
end

-- Runs every tick before the coroutine resumes. Emulates UE's observer events by polling:
--   Self / Both      : an observer of the ACTIVE link turned false      -> abort that branch, parent goes on as if it failed
--   LowerPriority/Both: an observer of a link LEFT of the active one turned true (false -> true) and the whole
--                       link now allows execution                      -> abort the active branch, restart at that link
-- Returns true when something was aborted.
function ENT:SBAI_CheckObservers()
	local stack = self.SBAI_ExecutionStack
	if #stack == 0 then return false end
	self.SBAI_DecoLast = self.SBAI_DecoLast or {}

	for stackIdx = 1, #stack do
		local frame = stack[stackIdx]
		local nodeData = self.SBAI_NodeLookup[frame.NodeID]
		local children = nodeData and nodeData.Properties and nodeData.Properties.Children
		local activeIdx = frame.Index

		if !children or !children[activeIdx] then goto next_frame end

		-- 1. LowerPriority / Both on the links to the LEFT of the active child
		for i = 1, activeIdx - 1 do
			local sibling = children[i]
			local bBecameTrue = false

			if sibling.Decorators then
				for _, decoRef in ipairs(sibling.Decorators) do
					local mode = self:SBAI_GetAbortMode(decoRef)
					if mode == "LowerPriority" or mode == "Both" then
						local previous = self.SBAI_DecoLast[decoRef.ObjectName]
						local current = self:SBAI_EvaluateDecorator(decoRef)
						if current and previous != true then bBecameTrue = true end
					end
				end
			end

			if bBecameTrue and self:SBAI_EvaluateEdge(sibling) then
				local runningEntry = children[activeIdx]
				local runningID = runningEntry.ChildComposite and runningEntry.ChildComposite.ObjectName or runningEntry.ChildTask and runningEntry.ChildTask.ObjectName
				if runningID then self:SBAI_ClearRunning(runningID) end

				while #self.SBAI_ExecutionStack > stackIdx do
					table.remove(self.SBAI_ExecutionStack)
				end

				frame.Index = i
				frame.EnteredIdx = i -- its decorators were just evaluated, do not roll them a second time on entry
				self:SBAI_NotifyActivation(sibling)
				return true
			end
		end

		-- 2. Self / Both on the link of the ACTIVE child
		local currentEntry = children[activeIdx]
		if currentEntry.Decorators then
			local bAbortSelf = false
			for _, decoRef in ipairs(currentEntry.Decorators) do
				local mode = self:SBAI_GetAbortMode(decoRef)
				if mode == "Self" or mode == "Both" then
					if !self:SBAI_EvaluateDecorator(decoRef) then
						bAbortSelf = true
						break
					end
				end
			end

			if bAbortSelf then
				local runningID = currentEntry.ChildComposite and currentEntry.ChildComposite.ObjectName or currentEntry.ChildTask and currentEntry.ChildTask.ObjectName
				if runningID then self:SBAI_ClearRunning(runningID) end

				while #self.SBAI_ExecutionStack > stackIdx do
					table.remove(self.SBAI_ExecutionStack)
				end

				if string.find(nodeData.Type, "Selector") then
					frame.Index = frame.Index + 1 -- Selector: next sibling
				else
					frame.ForceResult = false -- Sequence: the whole sequence fails
					frame.Index = #children + 1
				end
				return true
			end
		end

		::next_frame::
	end

	return false
end

-- Recursive state clearer for an ABORTED subtree (all call sites are aborts).
-- Running tasks get ENT:<TaskName>_Abort(props, nodeID) first, so they can drop their own state.
function ENT:SBAI_ClearRunning(nodeID)
	if !nodeID then return end

	local state = self.SBAI_RuntimeState[nodeID]
	local staticNode = self.SBAI_NodeLookup[nodeID]

	if state and state._running and staticNode and staticNode.Type and string.find(staticNode.Type, "^SBBTTask_") then
		local abortFn = self[string.gsub(staticNode.Type, "^SBBTTask_", "") .. "_Abort"]
		if abortFn then abortFn(self, staticNode.Properties, nodeID) end
	end

	if state then
		state._running = false
		state._result = nil
		state._startTime = nil
		state._currentChild = nil
	end

	if staticNode and staticNode.Properties and staticNode.Properties.Children then
		for _, childEntry in ipairs(staticNode.Properties.Children) do
			local childID = nil
			if childEntry.ChildComposite then
				childID = childEntry.ChildComposite.ObjectName
			elseif childEntry.ChildTask then
				childID = childEntry.ChildTask.ObjectName
			end
			if childID then self:SBAI_ClearRunning(childID) end
		end
	end

	-- the coroutine's locals refer to what we just wiped
	if self._sbaico and nodeID == self.SBAI_TreeRootID then
		self._sbaico = nil
	end
end

-- Phase 3: The Runner Logic
-- The runner. Selector: first child that succeeds wins, a failed or blocked child falls through to the next.
-- Sequence: every child must succeed, a failed or blocked child fails the whole sequence (the parent then
-- applies its own rule). Nothing restarts the tree except the root finishing.
function ENT:SBAI_SelectTask(startNodeID)
	if #self.SBAI_ExecutionStack == 0 then
		table.insert(self.SBAI_ExecutionStack, { NodeID = startNodeID, Index = 1 })
	end

	local ops = 0
	local max_ops = 500

	while #self.SBAI_ExecutionStack > 0 do
		ops = ops + 1
		if ops > max_ops then
			print("[SBAI] Infinite Loop Detected in Behavior Tree! Breaking out.")
			return nil
		end

		local frame = self.SBAI_ExecutionStack[#self.SBAI_ExecutionStack]
		local nodeID = frame.NodeID
		local nodeData = self.SBAI_NodeLookup[nodeID]
		local children = nodeData and nodeData.Properties and nodeData.Properties.Children or {}
		local isSelector = !nodeData or string.find(nodeData.Type, "Selector") != nil
		local idx = frame.Index

		-- 1. Composite finished: pop and report to the parent
		if idx > #children then
			local compositeResult = frame.ForceResult
			if compositeResult == nil then
				compositeResult = !isSelector -- Selector exhausted = failed, Sequence exhausted = succeeded
			end

			table.remove(self.SBAI_ExecutionStack)
			if #self.SBAI_ExecutionStack == 0 then return compositeResult end

			local parentFrame = self.SBAI_ExecutionStack[#self.SBAI_ExecutionStack]
			local parentData = self.SBAI_NodeLookup[parentFrame.NodeID]
			local parentChildren = parentData and parentData.Properties and parentData.Properties.Children or {}
			local parentIsSelector = !parentData or string.find(parentData.Type, "Selector") != nil

			if (parentIsSelector and compositeResult == true) or (!parentIsSelector and compositeResult == false) then
				parentFrame.ForceResult = compositeResult
				parentFrame.Index = #parentChildren + 1
			else
				parentFrame.Index = parentFrame.Index + 1
			end
			goto continue_loop
		end

		do
			local childEntry = children[idx]

			-- 2. Decorators: evaluated ONCE, when the link is entered. A running task is not re-checked here;
			--    only observers (SBAI_CheckObservers) can end it.
			local canExecute = true
			if frame.EnteredIdx != idx then
				canExecute = self:SBAI_EvaluateEdge(childEntry)
				if canExecute then
					frame.EnteredIdx = idx
					self:SBAI_NotifyActivation(childEntry)
				end
			end

			if !canExecute then
				-- a link that was never entered has nothing running; blocked = failed child
				local childID = childEntry.ChildComposite and childEntry.ChildComposite.ObjectName or childEntry.ChildTask and childEntry.ChildTask.ObjectName
				if childID and self:SBAI_GetNodeState(childID, "_running") then self:SBAI_ClearRunning(childID) end

				if isSelector then
					frame.Index = frame.Index + 1
				else
					frame.ForceResult = false
					frame.Index = #children + 1
				end
				goto continue_loop
			end

			-- 3. Execute the child
			if childEntry.ChildComposite then
				self:SBAI_ApplyDecoratorSets(childEntry)
				table.insert(self.SBAI_ExecutionStack, { NodeID = childEntry.ChildComposite.ObjectName, Index = 1 })
				goto continue_loop
			end

			if childEntry.ChildTask then
				local taskID = childEntry.ChildTask.ObjectName
				local taskNode = self.SBAI_NodeLookup[taskID]
				local taskName = taskNode and string.gsub(taskNode.Type, "^SBBTTask_", "")

				if !self:SBAI_GetNodeState(taskID, "_running") then
					self:SBAI_SetNodeState(taskID, "_running", true)
					self:SBAI_SetNodeState(taskID, "_startTime", CurTime())
				end

				local result = false -- a task that does not exist fails
				if taskName and self[taskName] then
					result = self[taskName](self, taskNode.Properties, taskID)
					if self.SBAI_Debug then print("Task", taskID, " result is:", result) end
				else
					print("[SBAI] Missing Task: " .. tostring(taskName))
				end

				if result == nil then
					coroutine.yield() -- InProgress: polled again next tick, decorators are NOT re-evaluated
					if self:IsFlagSet(FL_KILLME) then return false end -- called during OnRemove, closes variables
				else
					self:SBAI_SetNodeState(taskID, "_running", false)
					if isSelector then
						if result == true then
							frame.ForceResult = true
							frame.Index = #children + 1 -- Selector succeeded
						else
							frame.Index = frame.Index + 1 -- Selector: try the next child
						end
					else
						if result == true then
							frame.Index = frame.Index + 1 -- Sequence: next child
						else
							frame.ForceResult = false
							frame.Index = #children + 1 -- Sequence failed
						end
					end
				end
			else
				frame.Index = frame.Index + 1 -- empty link entry
			end
		end

		::continue_loop::
	end

	return false
end

-- function ENT:NPC_GetWalkActivity( act ) 
	-- act = act or ACT_MP_WALK_MELEE 
	-- return act 
-- end 

function ENT:NPC_TranslateLuaSchedule(oldsched) 
	local retVal = scripted_ents.GetStored("cycler_actor2").t.NPC_TranslateLuaSchedule(self,oldsched) 
	if retVal and retVal.DebugName == "LUASCHED_FLEE_FROM_BEST_SOUND" then 
		return LUASCHED_RAVEN_RAPIDEVADE_FROM_BESTSOUND 
	elseif retVal and retVal.DebugName == "LUASCHED_TAKE_COVER_FROM_BEST_SOUND" then 
		return LUASCHED_RAVEN_RAPIDEVADE_FROM_BESTSOUND 
	end 
	return retVal 
end 

function ENT:NPC_ShouldConductBehaviorTree() 
	-- likely performing a skill 
	if self["ESBActorState::ActorState_BlockingBehavior"] then return false end 
	if self:GetCurrentSchedule() == SCHED_SCENE_GENERIC then -- may be in a skill task 
		if self.SBAI_SkillStep and self.SBAI_SkillStep.Name then 
			if !self.SBAI_SkillStep:IsActive() then return true end 
		end 
	end 
	-- if true then return false end 
	-- has enemy 
	if !IsValid(self:GetEnemy()) then return false end 
	-- horizontal distance not higher than 5000 
	if !self.enemyDist then return false end 
	if self.enemyDist > 5000 then return false end 
	-- vertical distance between 800 
	local pos = self:WorldToLocal(self:GetEnemy():WorldSpaceCenter()) 
	if pos.z < -800 or pos.z > 800 then 
		if (CurTime() - self:GetLastTimeTookDamageFromEnemy(self:GetEnemy())) > 5 then 
			return false 
		end 
	end 
	-- has raven melee weapon 
	-- FIX: Check if we possess the raven_blade in our inventory, rather than if it's currently active.
    -- This allows us to transition back to the blade when switching away from a secondary weapon.
    local hasRavenBlade = false
    for _, wep in ipairs(self:GetWeapons()) do
        if wep:GetClass() == "raven_blade" then
            hasRavenBlade = true
            break
        end
    end
    if not hasRavenBlade then return false end
	-- definitely not a CBaseCombatCharacter in a vehicle, or a CBaseHelicopter 
	if self:GetNPCState() == NPC_STATE_DEAD then return false end 
	if self:NPC_HasCondition(COND.ENEMY_OCCLUDED) then return false end 
	if self:NPC_HasCondition(COND.WEAPON_SIGHT_OCCLUDED) then return false end 
	-- if self:GetEnemy().GetHullType and (self:GetEnemy():GetHullType() == HULL_SMALL_CENTERED or self:GetEnemy():GetHullType() == HULL_TINY or self:GetEnemy():GetHullType() == HULL_TINY_CENTERED) or self:GetEnemy():BoundingRadius() < 21 then return false end -- if raven lock on to a npc_cscanner, she only stares at scanner 
	return true 
end 

ENT.ShotRegulator = { } 
-- auto update burst settings and rest times each time we attempt to conduct a shot 
function ENT.ShotRegulator:UpdateRestTimes() 
	local Outer = self.Outer 
	scripted_ents.GetStored("cycler_actor2").t.ShotRegulator.UpdateRestTimes(self) 
	Outer.ShotRegulator.flMinRestInterval = 0.1 
	Outer.ShotRegulator.flMaxRestInterval = 0.1 
end 

function ENT:NPC_ShouldBlockRunAI() -- whether to call lua schedules or not
	-- when blocked (true), it calls Lua schedules 
	-- when not blocked (false), it calls Engine schedules 
	if self.CurrentSchedule and self.CurrentSchedule.DebugName == "LUASCHED_RAVEN_RAPIDEVADE" then return true end 
	if self:NPC_ShouldConductBehaviorTree() then return true end 
	return scripted_ents.GetStored("cycler_actor2").t.NPC_ShouldBlockRunAI(self) 
end 

function ENT:CustomRunAI(sTable) 
	local enemy = self:GetEnemy()
    local NPC_ShouldConductBehaviorTree = self:NPC_ShouldConductBehaviorTree() 
    local skipBehaviorTree = false
	
	if self:GetCurrentSchedule() == SCHED_SCENE_GENERIC then -- may be in a skill task 
		if self.SBAI_SkillStep and self.SBAI_SkillStep.Name then 
			if self.SBAI_SkillStep:IsValid() then goto inskill end 
		end 
	end 

    -- 1. INTERSECTION CHECK: Waypoint segment intersection with enemy position
    if not NPC_ShouldConductBehaviorTree and self.enemyDist and self.enemyDist < 100 and IsValid(enemy) then
        local lineStart = self:GetPos()
        local lineEnd = self:GetCurWaypointPos()
        local pointPos = enemy:GetPos()
		if lineEnd == vector_origin then skipBehaviorTree = true end 

        if lineEnd and lineEnd != vector_origin then
            local distToLine, nearestPoint, distAlongLine = util.DistanceToLine(lineStart, lineEnd, pointPos)
            -- Tolerance uses the enemy's bounding radius (fallback to standard 32 units)
            local tolerance = enemy:BoundingRadius() or 32
            if distToLine <= tolerance then
                skipBehaviorTree = true
            end
        end
    end

    -- 2. DYNAMIC WEAPON HANDLING (Combat/Alert States)
    if IsValid(enemy) and self:GetNPCState() != NPC_STATE_DEAD then
        if (NPC_ShouldConductBehaviorTree and not skipBehaviorTree) or skipBehaviorTree then
            -- High priority targets OR Interception condition met -> Force raven_blade
            local ravenBlade = NULL
            for _, wep in ipairs(self:GetWeapons()) do
                if wep:GetClass() == "raven_blade" then ravenBlade = wep; break end
            end
            if IsValid(ravenBlade) and self:GetActiveWeapon() != ravenBlade then
                self:SelectWeapon(ravenBlade)
                ravenBlade:RemoveEffects(EF_NODRAW)
				-- Entity(1):ChatPrint("selecting blade") 
                if ravenBlade.DeploySound then
                    ravenBlade:EmitSound(ravenBlade.DeploySound)
                end
            end
        else
            -- Behavior tree should not be accessed -> Draw secondary weapon (ranged, etc.)
            local secondaryWep = NULL
            for _, wep in ipairs(self:GetWeapons()) do
                if wep:GetClass() != "raven_blade" then secondaryWep = wep; break end
            end
            if IsValid(secondaryWep) then
                if self:GetActiveWeapon() != secondaryWep then
                    self:SelectWeapon(secondaryWep)
                    secondaryWep:RemoveEffects(EF_NODRAW)
					Entity(1):ChatPrint("selecting secondary weapon") 
                end
            end
        end
    end
	
	::inskill:: 

    -- 3. BEHAVIOR TREE RUN EXECUTION
    if NPC_ShouldConductBehaviorTree and not skipBehaviorTree then 
        return self:SBAI_RunBehavior(), self:NPC_MaintainActivity() 
    end
	local layer = self:FindGestureLayer(ACT_GESTURE_MELEE_ATTACK1) 
	if layer and layer >= 0 then 
		if self:GetLayerCycle(layer) > 0.25 then 
			if self:NPC_HasCondition(COND.CAN_MELEE_ATTACK1) then -- still able to melee attack 
				self:RemoveLayer(layer) 
			end 
		end 
	elseif self:GetCurrentSchedule() == SCHED_MELEE_ATTACK1 then 
		if self:NPC_HasCondition(COND.CAN_MELEE_ATTACK1) and self:TaskTime() > 0.25 then 
		self:TaskComplete()
		-- print("raven clearing schedule") 
			-- self.CurrentSchedule = nil 
		end 
	end 
	local retVal = scripted_ents.GetStored("cycler_actor2").t.CustomRunAI(self,sTable) 
end 

function ENT:OnKilled(dmginfo) 
	local attacker = dmginfo:GetAttacker() 
	if self.AttackerEffectWhenDead then 
		local AttackerEffectWhenDead = StellarBlade.ParseTableStrings(self.AttackerEffectWhenDead) 
		StellarBlade.AddEffectFromTable(attacker,AttackerEffectWhenDead) 
	end 
	return scripted_ents.GetStored("cycler_actor2").t.OnKilled(self,dmginfo) -- baseclass 
end 

function ENT:OnRemove(fullUpdate) 
	if self._sbaico and coroutine.status(self._sbaico) == "suspended" then
		self:SBAI_CheckObservers() 
		local ok, ret = coroutine.resume(self._sbaico)
	end 
	scripted_ents.GetStored("cycler_actor2").t.OnRemove(self) 
end 

function ENT:OnStateChange(oldState, newState) 
    local ravenBlade, otherWeapon = NULL, NULL 
    local weapons = self:GetWeapons() 

    for _, wep in ipairs(weapons) do 
        if wep:GetClass() == "raven_blade" then 
            ravenBlade = wep 
        else 
            otherWeapon = wep 
        end 
        if IsValid(ravenBlade) and IsValid(otherWeapon) then break end 
    end 

    if IsValid(ravenBlade) then 
        -- HOLSTER (Alert/Combat -> Idle)
        -- Triggers when there are absolutely no targets left and entering IDLE.
        if (oldState >= NPC_STATE_ALERT or oldState <= NPC_STATE_NONE) and newState == NPC_STATE_IDLE and self:GetKnownEnemyCount() < 1 then 
            
            local seqID = self:LookupSequence("layer_Eve_Weapon_End_BS") 
            if seqID != -1 then 
                local layer = self:FindGestureSequenceLayer(seqID) 
                layer = layer >= 0 and layer or self:AddGestureSequence(seqID) 
                self:SetLayerPlaybackRate(layer,0.5) 
            end 

            ravenBlade:AddEffects(EF_NODRAW) 
            if IsValid(otherWeapon) then 
                self:SelectWeapon(otherWeapon) 
            else 
				SafeRemoveEntity(self:Give("basehl2mpcombatweapon")) -- sets active weapon to something and removes it, effectively sets active weapon to nil 
            end 
			Entity(1):ChatPrint("OnStateChange no targets: Selecting OtherWeapon"..tostring(otherWeapon).." "..tostring(oldState).." "..tostring(newState)) 
            ravenBlade:EmitSound("character/se/pc_foldsword_close.wav") 

        -- DRAW (Idle -> Alert/Combat)
        elseif oldState == NPC_STATE_IDLE and (newState >= NPC_STATE_ALERT and newState <= NPC_STATE_COMBAT) then 
            
            if self:NPC_ShouldConductBehaviorTree() then
                -- Target requires Behavior Tree -> Setup Raven Blade gestures
                local seqID = self:LookupSequence("layer_Eve_Weapon_Start_Anim")
                if seqID != -1 then 
                    local layer = self:FindGestureSequenceLayer(seqID) 
                    layer = layer >= 0 and layer or self:AddGestureSequence(seqID) 
                    self:SetLayerPlaybackRate(layer,0.5) 
                end 

                self:SelectWeapon(ravenBlade) 
				Entity(1):ChatPrint("OnStateChange high priority: Selecting ravenBlade"..tostring(ravenBlade).." "..tostring(oldState).." "..tostring(newState)) 
                if ravenBlade.DeploySound then
                    ravenBlade:EmitSound(ravenBlade.DeploySound) 
                end
                self:ResetIdealActivity(ACT_IDLE) 
            else
                -- Target is low priority -> Instantly select secondary weapon without sword gestures
                if IsValid(otherWeapon) then 
                    self:SelectWeapon(otherWeapon) 
                    otherWeapon:RemoveEffects(EF_NODRAW)
					Entity(1):ChatPrint("OnStateChange low priority: Selecting otherWeapon"..tostring(otherWeapon).." "..tostring(oldState).." "..tostring(newState)) 
                else
                    self:SelectWeapon(ravenBlade) 
					Entity(1):ChatPrint("OnStateChange low priority: Selecting ravenBlade"..tostring(ravenBlade).." "..tostring(oldState).." "..tostring(newState)) 
                end
            end
        end 
    end 
end 

function ENT:NPC_AllowGestureMelee() return !self:NPC_ShouldConductBehaviorTree() end 
function ENT:NPC_EvaluateIncomingAttackRisk() return 0 end 

-- Decorators that must not be polled while their branch runs (no change events in UE, evaluated on entry only)
ENT.SBAI_NonObservableDecorators = { SbRandom = true }
-- Decorators observed every tick even when FlowAbortMode is omitted (UE's TimeLimit forces FlowAbortMode = Self)
ENT.SBAI_TickingDecorators = { SbTimeLimit = true }

-- Evaluates ONE decorator, bInverseCondition included. Returns boolean.
function ENT:SBAI_EvaluateDecorator(decoRef)
	local decoID = decoRef.ObjectName
	local decoNode = self.SBAI_NodeLookup[decoID]
	if !decoNode then return true end

	local funcName = string.gsub(decoNode.Type or decoNode.Name, "^SBBTDecorator_", "")
	local fn = self[funcName]
	if !fn then
		error("Decorator '" .. funcName .. "' is missing from " .. self:GetClass() .. ", go fill it!")
	end

	local raw = fn(self, decoNode.Properties, decoID)
	if raw == nil then
		Entity(1):ChatPrint("Decorator returned nil: " .. funcName)
		return false
	end

	local result = raw and true or false
	if decoNode.Properties.bInverseCondition then result = !result end
	if self.SBAI_Debug then print(decoID, "Decorator result is:", result) end

	self.SBAI_DecoLast = self.SBAI_DecoLast or {}
	self.SBAI_DecoLast[decoID] = result
	return result
end

-- In Stellar Blade Behavior Trees, bEqual defaults to false (inequality / exclusion check)
local DEFAULT_B_EQUAL = false
ENT.SBAI_AggroLevel = nil
function ENT:SbAggroLevel(tbl)
    local CompareAggroLevelArray = tbl.CompareAggroLevelArray
    if not CompareAggroLevelArray then return false end

    if type(CompareAggroLevelArray) ~= "table" then
        CompareAggroLevelArray = { CompareAggroLevelArray }
    end

    local bEqual = (tbl.bEqual ~= nil) and tbl.bEqual or DEFAULT_B_EQUAL

    -- Resolve active AggroLevel
	local currentAggro = self:GetTable()["ESBActorState::ActorState_BattleMode"] and "AIAggroLevel_Battle" or "AIAggroLevel_Peaceful" -- AggroLevel must be being updated before this decorator is called, just checking for BattleMode here prevents BattleMode effect from being added in further calls because it isn't set yet 
	local currentAggro = self.SBAI_AggroLevel -- this can act as an override 
	if not currentAggro then
		local enemy = self:GetEnemy()
		if IsValid(enemy) and enemy:Alive() then
			currentAggro = "AIAggroLevel_Battle"
		else
			currentAggro = "AIAggroLevel_Peaceful"
		end
	end 
	
	-- local hasEnemy = self:GetKnownEnemyCount() > 0 and "AIAggroLevel_Battle" or "AIAggroLevel_Peaceful" -- an alternative check 
	
	-- if self:GetTable()["ESBActorState::ActorState_BattleMode"] then currentAggro = "AIAggroLevel_Battle" end -- doing this here prevents turret from undeploying 
	-- because BattleMode effect is infinite 

    local found = false
    for _, level in ipairs(CompareAggroLevelArray) do
        if level == currentAggro then
            found = true
            break
        end
    end

    local matches = found
    if not bEqual then
        matches = not matches
    end
    return matches
end

function ENT:SbAimMe(tbl) -- doesn't have any additional properties 
	return self:NPC_HasCondition(COND.ENEMY_FACING) and self:NPC_IsEnemyAttacking(self:GetEnemy()) 
end 

--[[---------------------------------------------------------------------------
	SbBlackboard  (drop-in replacement for ENT:SbBlackboard in m_raven.lua)

	Serves both USBBTDecorator_SbBlackboard and USBBTTask_SbBlackboard.

	Properties actually present in the 118 BehaviorTree dumps (FModel omits defaults):
	  Decorator : KeyName, CompareOP (default Equal), IntValue (default 0),
	              SetValueType (None / Additive)
	  Task      : KeyName, IntValue, bReturnSucceeded (default false), bAdditive

	UNUSED in every dump (0 hits), so deliberately NOT implemented:
	  VarType, FloatValue, VectorValue, BoolValue          -> the blackboard is Int-only
	  SetIntValue, SetFloatValue, SetVectorValue, SetBoolValue
	  bCheckContains, bCheckNoContains
	  ActorType (its hits belong to other nodes; SbBlackboard always uses its own board)
-----------------------------------------------------------------------------]]

-- SetValueType = Additive never comes with a SetIntValue in the dumps, so the amount
-- is not stored in the tree. Assumed to be +1 (an "add 0" decorator would do nothing).
local SBBB_ADDITIVE_AMOUNT = 1

-- Task vs Decorator, from the node ID the executor passes as the 2nd argument
-- ("SBBTTask_SbBlackboard'M_Raven_AI:SBBTTask_SbBlackboard_0'"). bReturnSucceeded alone
-- is not reliable: false is its default, so FModel omits it.
local function SBBB_IsTask(tbl, nodeID)
	if isstring(nodeID) then
		if string.find(nodeID, "^SBBTTask_") then return true end
		if string.find(nodeID, "^SBBTDecorator_") then return false end
	end
	return tbl.bReturnSucceeded ~= nil or tbl.bAdditive ~= nil -- fallback: Task-only fields
end

-- Decorator "SetValueType = Additive": KeyName += 1.
-- Decorators are evaluated every tick, so the compare path never writes. Call this ONCE
-- when the decorated branch is entered (see SBAI_ApplyDecoratorSets below).
function ENT:SbBlackboard_ApplySet(tbl)
	if tbl.KeyName == nil or tbl.SetValueType ~= "ESBDecoratorBlackboardSetValueType::Additive" then return end
	self.SBAI_BlackBoard = self.SBAI_BlackBoard or {}
	self.SBAI_BlackBoard[tbl.KeyName] = (self.SBAI_BlackBoard[tbl.KeyName] or 0) + SBBB_ADDITIVE_AMOUNT
end

function ENT:SbBlackboard(tbl, nodeID)
	local key = tbl.KeyName
	local intValue = tbl.IntValue or 0 -- omitted = 0
	self.SBAI_BlackBoard = self.SBAI_BlackBoard or {}

	-- TASK: write to the blackboard
	if SBBB_IsTask(tbl, nodeID) then
		if key ~= nil then
			if tbl.bAdditive then
				intValue = (self.SBAI_BlackBoard[key] or 0) + intValue
			end
			self.SBAI_BlackBoard[key] = intValue -- explicit 0 too, never nil
		end
		return tbl.bReturnSucceeded == true -- omitted = false
	end

	-- DECORATOR: compare (read-only). Uninitialized keys read as 0.
	if key == nil then return false end
	local val = self.SBAI_BlackBoard[key] or 0
	return StellarBlade.ESBCompare(val, intValue, tbl.CompareOP or "ESBCompare::Equal") and true or false
end

function ENT:SbCheckActorEffect(tbl)
	local expectedActive = (tbl.bActive == true)
	local ActorType = tbl.ActorType or "Self" 
	local ent = StellarBlade.ESBAIActorType(self, ActorType)

	if !IsValid(ent) then
		return false
	end

	-- Collect the effect names to check, and the mode
	local bOrMode = false
	local names = {}
	local source = tbl.AndCheck_EffectAliasArray
	if istable(tbl.OrCheck_EffectAliasArray) and #tbl.OrCheck_EffectAliasArray > 0 then
		bOrMode = true
		source = tbl.OrCheck_EffectAliasArray
	end

	if isstring(tbl.EffectAlias) and tbl.EffectAlias != "" and tbl.EffectAlias != "None" then
		names[#names + 1] = tbl.EffectAlias
	end
	for _, name in ipairs(source or {}) do
		if isstring(name) and name != "" and name != "None" then
			names[#names + 1] = name
		end
	end

	-- AND: starts true, one missing effect makes it false. OR: starts false, one present makes it true.
	local hasEffect = (!bOrMode and #names > 0)
	for _, name in ipairs(names) do
		local present = #StellarBlade.GetActorEffects(ent, name) > 0

		if !present then -- an ENT:<EffectName>(ent) function may stand in for a real effect
			local override = self[name]
			if isfunction(override) then
				local ok, result = pcall(override, self, ent)
				present = (ok and result) and true or false
			end
		end

		if bOrMode and present then
			hasEffect = true
			break
		elseif !bOrMode and !present then
			hasEffect = false
			break
		end
	end

	return hasEffect == expectedActive
end


function ENT:SbCheckActorStat(tbl) 
	-- PrintTable(tbl) 
	-- consider ActorType 
	local CheckStat = tbl.CheckStat -- ActorStatType_AttackSpeed       ActorStatType_StaminaAttackPower        ActorStatType_CriticalPercentage        ActorStatType_HitDefenseLevel   ActorStatType_ShieldIgnorePercentage    ActorStatType_CriticalValueRate ActorStatType_ShieldRegenPerSecond      ActorStatType_AdditiveSkillDamageRate   ActorStatType_ShieldRegenPerSecondRate  ActorStatType_ShieldRegenPerSecondValue ActorStatType_ShieldRegenPerSecondWhenBattleValue       ActorStatType_ShieldRegenPerSecondWhenBattle    ActorStatType_StaminaRegenPerSecond     ActorStatType_ShieldRegenPerSecondWhenBattleRate        ActorStatType_HPRegenPerSecondValue     ActorStatType_HPRegenPerSecond  ActorStatType_SmallWeightTypeDamageAdditiveRate ActorStatType_HPRegenPerSecondRate      ActorStatType_RangeAttackDamageAdditiveRate     ActorStatType_LargeWeightTypeDamageAdditiveRate ActorStatType_RangeAttackDamageReductionRate    ActorStatType_MeleeAttackDamageReductionRate    ActorStatType_GroggyStateDamageAdditiveRate     ActorStatType_DownStateDamageAdditiveRate       ActorStatType_FireAttributeDamageReductionRate  ActorStatType_AirborneStateDamageAdditiveRate   ActorStatType_LightningAttributeDamageReductionRate     ActorStatType_IceAttributeDamageReductionRate   ActorStatType_BetaGaugeAdditiveRate     ActorStatType_PoisonAttributeDamageReductionRate        ActorStatType_LowHpDamageAdditiveRate   ActorStatType_AdditiveFixedDamage       ActorStatType_DOTDamageAdditiveRate     ActorStatType_HighHpDamageAdditiveRate  ActorStatType_TachyGaugeReduceConsumeRate       ActorStatType_TachyGaugeAdditiveGainRate        ActorStatType_FinalShieldDamageReduceRate       ActorStatType_FinalHPDamageReduceRate   ActorStatType_AdditiveSkillDamageGroup1 ActorStatType_Luck      ActorStatType_AdditiveSkillDamageGroup3 ActorStatType_AdditiveSkillDamageGroup2 ActorStatType_AdditiveSkillDamageGroup5 ActorStatType_AdditiveSkillDamageGroup4 ActorStatType_AdditiveSkillDamageGroup7 ActorStatType_AdditiveSkillDamageGroup6 ActorStatType_AdditiveSkillDamageGroup9 ActorStatType_AdditiveSkillDamageGroup8 ActorStatType_DrainHpByAttackPowerRate  ActorStatType_AdditiveSkillDamageGroup10        ActorStatType_SprintableStaminaValue    ActorStatType_DrainHpFixedValue ActorStatType_ItemStackBullet1  ActorStatType_ItemStackRecoveryPotion   ActorStatType_ItemStackBullet3  ActorStatType_ItemStackBullet2  ActorStatType_ItemStackBullet5  ActorStatType_ItemStackBullet4  ActorStatType_ItemStackConsumable1      ActorStatType_ItemStackBullet6  ActorStatType_ItemStackConsumable3      ActorStatType_ItemStackConsumable2      ActorStatType_ItemStackConsumable5      ActorStatType_ItemStackConsumable4      
	local CheckValue = tbl.CheckValue -- 60.0, 
	local CompareOP = tbl.CompareOP or "ESBCompare::Equal" -- Greater 
	local bRateValue = tbl.bRateValue or false -- true 
	local NodeName = tbl.NodeName -- SB_CheckActorStat(HP>60) 
	CheckValue = CheckValue or 0 -- Scarlet checks for 0 shield 
	-- handle only ActorStatType_HP for now, Raven only looks for this 
	local testvalue, result 
	if CheckStat == "ESBActorStatType::ActorStatType_HP" or CheckStat == "ESBActorStatType::ActorStatType_MaxHP" then 
		testvalue = self:Health() 
		-- testvalue = (testvalue / self:GetMaxHealth()) * 100 
		testvalue = (testvalue / StellarBlade.ActorStats(self)["ESBActorStatType::ActorStatType_MaxHP"]) * 100 
	elseif CheckStat == "ESBActorStatType::ActorStatType_MaxShield" then 
		testvalue = self.Armor and self:Armor() 
		testvalue = testvalue and (testvalue / self:GetMaxArmor()) * 100 or 0 -- NPCs don't have Armor yet 
	elseif CheckStat == "ESBActorStatType::ActorStatType_MaxStamina" then 
		testvalue = StellarBlade.ActorStats(self)["ESBActorStatType::ActorStatType_Stamina"] 
		testvalue = (testvalue / StellarBlade.ActorStats(self)[CheckStat]) * 100 
	else -- other uses: ActorStatType_MaxHP
		testvalue = 0 
		Entity(1):ChatPrint(tostring(self).." CheckStat not implemented for:  "..CheckStat) 
	end 
	-- Entity(1):ChatPrint("CheckStat: "..CheckStat.." CheckValue: "..tostring(CheckValue).. "..CompareOP:"..CompareOP.." "..tostring(result)) 
	-- print("ActorStat check", CheckStat, testvalue, CompareOP, CheckValue, "=>", result) 
	return StellarBlade.ESBCompare(testvalue,CheckValue,CompareOP) 
end 

function ENT:SbCheckActorState(tbl)
	Entity(1):ChatPrint(tostring(self).." in CheckActorState, may be bogus") 
	local ActorType = tbl.ActorType or "Self" 
	local ent = StellarBlade.ESBAIActorType(self, ActorType)
	local CheckState = tbl.CheckState
	-- local bInverseCondition = (tbl.bInverseCondition == true)

	local bHasState = false
	if IsValid(ent) and isstring(CheckState) and CheckState != "ESBActorState::ActorState_None" then
		bHasState = (ent[CheckState] != nil)
	end

	return bHasState
end

function ENT:SbCheckStance(tbl) -- M_Raven_Phase2, M_Raven_Default 
	local ActorType = tbl.ActorType or "Self" 
	local ent = StellarBlade.ESBAIActorType(self, ActorType)
	if IsValid(actor) then self = actor end 
    local StanceName = tbl.StanceName
	local StanceNameArray = tbl.StanceNameArray 
    local currentStance = self.CurrentStance
    -- local matches = (currentStance == StanceName)
	local matches = false 
	if StanceNameArray then 
		for k,v in ipairs(StanceNameArray) do if v == currentStance then matches = true end end 
	else 
		matches = (currentStance == StanceName)
	end 
    -- if tbl.bInverseCondition then
        -- matches = !matches
    -- end
	print("stance returning:",matches, "currentStance",currentStance, "checking stance:",tbl.StanceName) 
    return matches
end

function ENT:SbCheckTarget() return IsValid(self:GetEnemy()) end -- Antlion and Skulling. has only "TargetRelation": "ESBTribeRelation::TribeRelation_Enemy",
function ENT:SbCheckActorTag() Entity(1):ChatPrint("possibly M_Opener_AI accessed SbCheckActorTag, returning true, it has only ActorTag:OnActor") return true end 

function ENT:SbCheckLastAttackedTime(tbl) -- used by M_BotAttacker_AI, BotCommon, BotDefense 
	local CheckTime = tbl.CheckTime 
	local ActorType = tbl.ActorType -- unused 
	local bLess = tbl.bLess -- unused 
	local m_flNextAttack = self:GetInternalVariable("m_flNextAttack") 
	return -m_flNextAttack < CheckTime -- double check the return 
end 

function ENT:SbCheckZoneEnvState() end -- unused 
function ENT:SbIsFindPathWay() end -- unused 
function ENT:SbIsFlying() end -- unused 

function ENT:SbIsEmptyEquipment() 
	print("in SbIsEmptyEquipment") 
	print("only BotAttacker, BotCommon or BotDefense use this") 
	print('they all check for "EquipmentType": "ESBEquipmentType::EquipmentType_SecondaryWeapon",') -- and this is the only property 
	print("but whom?") 
	return true 
end 


-- SbCheckSummonedCount users: Marionette and Roadblock 
-- Probably checks how many children it has right now 

-- SbCheckTargetAngleFromCamera has 0 users 
-- SbDistanceToHome has 0 users 
-- SbCheckAnimState has 0 users 
-- SbIsRunPathWay has 0 users 
-- SbIsFindPathWay has 0 users 
-- SbIsRunSpiderNav has 1 user, M_Antlion_AI, tbl.SpiderNavigationPlaceType 
-- SbIsTPS has 0 users 
-- SbLastSkillHitResult has 4 users, checks for ESBSkillHitResult::SkillHitResult - HitResult
-- it consists of SkillHitResult_None, SkillHitResult_Hit, Parry, SkillHitResult_SuperParry, Guard, SkillHitResult_GuardBlock 



function ENT:SbDetectResult(tbl) 
	-- ESBAIDetectResultType::AIDetectResult_NotDetect ESBAIDetectResultType::AIDetectResult_Observe AIDetectResult_Doubt	AIDetectResult_Detect 
    local cmp = tbl.CompareDetectResult 
    local bEqual = (tbl.bEqual ~= false) -- Defaults to true in UE
    local hasEnemy = IsValid(self:GetEnemy()) and self:GetEnemy():Alive()

    local expected = false
    if cmp == "ESBAIDetectResultType::AIDetectResult_Detect" or cmp == 3 then
        expected = true
    elseif cmp == "ESBAIDetectResultType::AIDetectResult_NotDetect" or cmp == 0 or cmp == nil then
        -- Default enum 0 is NotDetect (omitted from JSON)
        expected = false
    else
        expected = false
    end

    local matches = (hasEnemy == expected)
    if not bEqual then
        matches = not matches
    end
    return matches
end

-- ============================================================================
-- DECORATOR: SbDetectResult (USBBTDecorator_SbDetectResult)
-- Evaluates perception sensing, detect gauges, and detect state matching.
-- ============================================================================

local ENUM_DETECT_RESULT = {
    ["ESBAIDetectResultType::AIDetectResult_NotDetect"] = 0,
    ["AIDetectResult_NotDetect"]                         = 0,
    [0]                                                  = 0,
    ["ESBAIDetectResultType::AIDetectResult_Doubt"]     = 1,
    ["AIDetectResult_Doubt"]                             = 1,
    [1]                                                  = 1,
    ["ESBAIDetectResultType::AIDetectResult_Observe"]   = 2,
    ["AIDetectResult_Observe"]                           = 2,
    [2]                                                  = 2,
    ["ESBAIDetectResultType::AIDetectResult_Detect"]    = 3,
    ["AIDetectResult_Detect"]                            = 3,
    [3]                                                  = 3,
}

function ENT:SbDetectResult(tbl)
	-- print("_SBAI_DetectGauge:",self._SBAI_DetectGauge) 
	-- print("_SBAI_DoubtGauge:",self._SBAI_DoubtGauge) 
    -- -------------------------------------------------------------------------
    -- 1. Table Lookup & Safe Fallback
    -- -------------------------------------------------------------------------
    local detectAITable = SB_CharacterDetectAITable[1]
    local detectData = nil

    local alias = self.DefaultDetectAIAlias or self.NarrowDetectAIAlias
    if not alias then
        local sTable = self:GetTable()
        alias = sTable.DefaultDetectAIAlias or sTable.NarrowDetectAIAlias or sTable.CharacterType or self:GetClass()
    end

    if detectAITable and alias then
        if detectAITable.Rows and detectAITable.Rows[alias] then
            detectData = detectAITable.Rows[alias]
        elseif detectAITable[alias] then
            detectData = detectAITable[alias]
        end
    end

    -- Target comparison level (default when omitted is AIDetectResult_NotDetect = 0)
    local targetEnum = ENUM_DETECT_RESULT[tbl.CompareDetectResult] or 0
    local bEqual = (tbl.bEqual == true)

    if not detectData then
        -- Legacy fallback if CharacterDetectAITable or entry is missing
        local hasEnemy = IsValid(self:GetEnemy()) and self:GetEnemy():Alive()
        local currentDetect = hasEnemy and 3 or 0

        if currentDetect == 3 then
            self.SBAI_AggroLevel = "AIAggroLevel_Battle"
        elseif not hasEnemy then
            self.SBAI_AggroLevel = "AIAggroLevel_Peaceful"
        end

        if bEqual then
            return currentDetect == targetEnum
        else
            return currentDetect >= targetEnum
        end
    end

    -- -------------------------------------------------------------------------
    -- 2. Parsing Detection Profile Parameters
    -- -------------------------------------------------------------------------
    local horizAngle             = tonumber(detectData.AISightSenseHorizontalAngle) or 360.0
    local vertAngle              = tonumber(detectData.AISightSenseVerticalAngle) or 90.0
    local nearDist               = tonumber(detectData.AISightSenseNearDistance) or 0.0
    local vertDistMax            = tonumber(detectData.AISightSenseVerticalDistance) or 5000.0
    local detectDistMax          = tonumber(detectData.AIDetectCheckDistance) or 5000.0
    local pursuitDist            = tonumber(detectData.AIPursuitDistance) or detectDistMax
    local pursuitVertDist        = tonumber(detectData.AIPursuitVerticaDistance) or vertDistMax
    local ignoreBlocking         = tobool(detectData.AISightSenseIgnoreBlocking)
    local ignoreBlockingOnDetect = tobool(detectData.AISightSenseIgnoreBlockingWhenDetectTarget)

    -- Interval step amounts (treated discretely per call as requested)
    local incDetect = tonumber(detectData.AIIncreaseAggroGaguePerSecond) or 20.0
    local incDoubt  = tonumber(detectData.AIIncreaseDoubtAggroGaguePerSecond) or 10000.0
    local decLevel0 = tonumber(detectData.AIDecreaseLevel0AggroGaguePerSecond) or 20.0
    local decLevel1 = tonumber(detectData.AIDecreaseLevel1AggroGaguePerSecond) or 20.0
	
	local GetAnimTimeInterval = self:GetAnimTimeInterval() 
	incDetect = incDetect * GetAnimTimeInterval 
	incDoubt = incDoubt * GetAnimTimeInterval 
	decLevel0 = decLevel0 * GetAnimTimeInterval 
	decLevel1 = decLevel1 * GetAnimTimeInterval 

    -- -------------------------------------------------------------------------
    -- 3. Enemy Sensing Loop (ents.FindInPVS)
    -- -------------------------------------------------------------------------
    local myPos    = self:GetPos()
    local myEyePos = (self:EyePos()) 
    local fwd      = self:GetForward()
    fwd.z          = 0
    fwd:Normalize()

    local existingEnemy    = self:GetEnemy()
    local hasExistingEnemy = IsValid(existingEnemy) and existingEnemy:Alive()

    local bestEnemy   = nil
    local bestDistSqr = math.huge

    -- Evaluate currently acquired enemy first (using pursuit ranges)
    if hasExistingEnemy then
        local ePos   = existingEnemy:GetPos()
        local d2d    = myPos:Distance2D(ePos)
        local vDelta = math.abs(myPos.z - ePos.z)

        if d2d <= pursuitDist and vDelta <= pursuitVertDist then
            local blocked = false
            if not ignoreBlocking and not ignoreBlockingOnDetect then
                local tr = util.TraceLine({
                    start  = myEyePos,
                    endpos = existingEnemy:EyePos(),
                    filter = { self, self:GetOwner() },
                    mask   = MASK_SHOT
                })
                if tr.Fraction < 1 and tr.Entity ~= existingEnemy and not (IsValid(tr.Entity) and tr.Entity:GetOwner() == existingEnemy) then
                    blocked = true
                end
            end

            if not blocked then
                bestEnemy   = existingEnemy
                bestDistSqr = myPos:DistToSqr(ePos)
            end
        end
    end

    -- Scan PVS entities for visible hostile targets
    local candidates = (SERVER and ents.FindInPVS) and ents.FindInPVS(self) or ents.FindInSphere(myPos, detectDistMax)
    for _, cand in ipairs(candidates) do
        if not IsValid(cand) or cand == self or not cand:Alive() then continue end
        if cand == existingEnemy then continue end -- Already processed
        -- if cand.GetNoDraw and cand:GetNoDraw() then continue end
		if cand:IsFlagSet(FL_NOTARGET) then continue end 
		if cand:IsPlayer() then 
			if cvars.Bool("ai_ignoreplayers") then continue end 
			if cand:GetObserverMode() > OBS_MODE_NONE then continue end 
		end 

        -- Disposition hostile check
        local isEnemy = false
        if self:Disposition(cand) == D_HT then
            isEnemy = true
        elseif cand:IsPlayer() then
            if not (self:Disposition(cand) == D_LI) then
                isEnemy = true
            end
        elseif cand.Disposition and cand:Disposition(self) == D_HT then
            isEnemy = true
        end

        if not isEnemy then continue end

        local cPos = cand:GetPos()
        local dSqr = myPos:DistToSqr(cPos)
        local d    = math.sqrt(dSqr)

        -- Near & Max detection distance checks
        if nearDist > 0 and d < nearDist then continue end
        if d > detectDistMax then continue end

        -- Vertical height separation check
        if math.abs(myPos.z - cPos.z) > vertDistMax then continue end

        -- Horizontal FOV angle check
        if horizAngle < 360 then
            local dir2D = (cPos - myPos)
            dir2D.z = 0
            if dir2D:LengthSqr() > 0 then
                dir2D:Normalize()
                local dot = math.Clamp(fwd:Dot(dir2D), -1, 1)
                local deg = math.deg(math.acos(dot))
                if deg > (horizAngle * 0.5) then continue end
            end
        end

        -- Vertical pitch angle check
        if vertAngle < 90 then
            local candEye = cand:EyePos()
            local dir3D   = (candEye - myEyePos):GetNormalized()
            local pitch   = math.abs(math.deg(math.asin(math.Clamp(dir3D.z, -1, 1))))
            if pitch > vertAngle then continue end
        end

        -- Raycast line-of-sight check
        if not ignoreBlocking then
            local tr = util.TraceLine({
                start  = myEyePos,
                endpos = cand:EyePos(),
                filter = { self, (self.GetActiveWeapon and self:GetActiveWeapon() or self) },
                mask   = MASK_SHOT
            })
            if tr.Fraction < 1 and tr.Entity ~= cand and not (IsValid(tr.Entity) and tr.Entity:GetOwner() == cand) then
                continue
            end
        end

        -- Retain closest candidate
        if dSqr < bestDistSqr then
            bestDistSqr = dSqr
            bestEnemy   = cand
        end
    end

    -- -------------------------------------------------------------------------
    -- 4. Gauge Accumulation & Detection Level Resolution
    -- -------------------------------------------------------------------------
    self._SBAI_DetectGauge = self._SBAI_DetectGauge or 0
    self._SBAI_DoubtGauge  = self._SBAI_DoubtGauge or 0

    if IsValid(bestEnemy) then
        -- When actively tracking the established enemy, lock gauges at max
        if bestEnemy == existingEnemy then
            self._SBAI_DetectGauge = 100.0
            self._SBAI_DoubtGauge  = 100.0
        else
            self._SBAI_DoubtGauge  = math.Clamp(self._SBAI_DoubtGauge + incDoubt, 0, 100.0)
            self._SBAI_DetectGauge = math.Clamp(self._SBAI_DetectGauge + incDetect, 0, 100.0)
        end
    else
        -- Decay gauges when no hostiles are perceived
        self._SBAI_DetectGauge = math.Clamp(self._SBAI_DetectGauge - decLevel0, 0, 100.0)
        self._SBAI_DoubtGauge  = math.Clamp(self._SBAI_DoubtGauge - decLevel1, 0, 100.0)
    end

    local currentDetect = 0 -- AIDetectResult_NotDetect
    if self._SBAI_DetectGauge >= 100.0 then
        currentDetect = 3 -- AIDetectResult_Detect
    elseif self._SBAI_DetectGauge >= 50.0 or (self._SBAI_DoubtGauge >= 100.0 and IsValid(bestEnemy)) then
        currentDetect = 2 -- AIDetectResult_Observe
    elseif self._SBAI_DoubtGauge > 0 or self._SBAI_DetectGauge > 0 then
        currentDetect = 1 -- AIDetectResult_Doubt
    else
        currentDetect = 0 -- AIDetectResult_NotDetect
    end

    -- -------------------------------------------------------------------------
    -- 5. Synchronize Target & AggroLevel
    -- -------------------------------------------------------------------------
    if currentDetect == 3 and IsValid(bestEnemy) then
        self.SBAI_AggroLevel = "AIAggroLevel_Battle"
        if (not IsValid(self:GetEnemy())) or (not self:GetEnemy():Alive()) then
            self:SetEnemy(bestEnemy) 
        end
    elseif currentDetect == 0 then
        if (not IsValid(self:GetEnemy())) or (not self:GetEnemy():Alive()) then
            self.SBAI_AggroLevel = "AIAggroLevel_Peaceful"
        end
    end

    -- -------------------------------------------------------------------------
    -- 6. Evaluate Decorator Condition
    -- -------------------------------------------------------------------------
    if bEqual then
        return currentDetect == targetEnum
    else
        return currentDetect >= targetEnum
    end
end

function ENT:SbDistanceToTarget(tbl)
    local target = self:GetEnemy()
    if tbl.bSubTarget then
        for _, sub in pairs(self:GetKnownEnemies()) do
            if IsValid(sub) and sub ~= target then
                target = sub
                break
            end
        end
    end

    if not IsValid(target) then return false end

    local dist = self.enemyDist_2d
    if !dist then
        dist = self:GetPos():Distance2D(target:GetPos())
    end
	
	dist = dist * 0.42 -- approximate Hammer units 

    local checkDist = tbl.Distance or 0
    local op = tbl.CompareOP or "ESBCompare::LessOrEqual"
    return StellarBlade.ESBCompare(dist, checkDist, op)
end

function ENT:SbIsActiveSkill(tbl) 
	local actor = tbl.ActorType 
	if actor then 
		actor = StellarBlade.ActorType(actor) 
	end 
	if IsValid(actor) then self = actor end 
	local retVal = self.SBAI_SkillStep 
	if StellarBlade.SBAI_SkillStep.IsActive(retVal) then retVal = true end 
	-- if tbl.bInverseCondition then return !retVal end 
	return retVal 
end 

function ENT:SbIsAlive(tbl) 
	local ActorType = tbl.ActorType or "ESBAIActorType::Self" -- Target, Self, SubTarget, Owner. Default: Self 
	local CheckType = tbl.CheckType or "ESBBTDecoratorAliveCheckType::Alive" -- Alive, Dead, Coma. Default: Alive 
	-- print("ActorType",ActorType) 
	local ent = self 
	if ActorType == "ESBAIActorType::Target" then 
		ent = self:GetEnemy() 
	elseif ActorType == "ESBAIActorType::Self" then 
		ent = self 
	elseif ActorType == "ESBAIActorType::Owner" then 
		ent = self:GetOwner() 
	-- print(self, "checking ent:",ent) 
	elseif ActorType == "ESBAIActorType::SubTarget" then 
		for _,subent in pairs(self:GetKnownEnemies()) do 
			if IsValid(subent) then 
				if IsValid(self:GetEnemy()) then 
					if self:GetEnemy() != subent then 
						ent = subent 
					end 
				end 
			end 
		end 
	end 
	
    if CheckType == "ESBBTDecoratorAliveCheckType::Coma" then
        return IsValid(ent) and ent:GetInternalVariable("m_lifeState") == 1
    elseif CheckType == "ESBBTDecoratorAliveCheckType::Dead" then
        return IsValid(ent) and !ent:Alive()
    elseif CheckType == "ESBBTDecoratorAliveCheckType::Alive" then
        return IsValid(ent) and ent:Alive()
    end
	
    return false
end 

function ENT:SbIsBattleMode(tbl) -- has no users, why here? 
	local ActorType = tbl.ActorType 
	ActorType = StellarBlade.ESBAIActorType(ActorType) 
	if !IsValid(ActorType) then return false end 
	return StellarBlade.IsBattle(ActorType) 
end 

function ENT:SbIsGroupAttacker(tbl) 
	local ActorType = tbl.ActorType 
	ActorType = StellarBlade.ESBAIActorType(ActorType) 
	if !IsValid(ActorType) then return false end 
	return ActorType.bGroupAttacker 
end 

function ENT:SbRandom(tbl) 
	local RandomRange = math.random(0,tbl.RandomRange) 
	local CheckValue = tbl.CheckValue 
	local CompareOP = tbl.CompareOP or "ESBCompare::Equal" -- LessOrEqual, Greater, GreaterOrEqual, Equal, Less, NotEqual 
	return StellarBlade.ESBCompare(RandomRange,CheckValue,CompareOP) 
end 

-- SbSpiderIsArrived is unused 

function ENT:SbTimeLimit(tbl)
    if !self.SBAI_TimeLimit then
        self.SBAI_TimeLimit = {}
    end

    local name         = tbl.TimerName or "DefaultTimer"
    local limit        = tbl.LimitTime or 0
    local react        = tbl.ReactInterval or 0
    local now          = CurTime()
    local timerData    = self.SBAI_TimeLimit[name]

    -- If no timer exists, start one now
    if !timerData then
        self.SBAI_TimeLimit[name] = {
            expire = now + limit,
            cooldown = 0
        }
        return true
    end

    -- If currently within active limit window
    if now <= timerData.expire then
        return true
    end

    -- If cooldown hasn’t been set yet, set it
    if timerData.cooldown == 0 and react > 0 then
        timerData.cooldown = now + react
        self.SBAI_TimeLimit[name] = timerData
    end

    -- If still in cooldown, block entry
    if timerData.cooldown > now then
        return false
    end

    -- Otherwise, reset timer and allow again
    self.SBAI_TimeLimit[name] = {
        expire = now + limit,
        cooldown = 0
    }
    return true
end

function ENT:SbLockOnMe() 
	local enemy = self.GetEnemy and self:GetEnemy() or self:GetEyeTrace().Entity 
	if IsValid(enemy) then 
		if enemy.GetEnemy then 
			if IsValid(enemy:GetEnemy()) and enemy:GetEnemy() == self then 
				return true 
			end 
			elseif IsValid(enemy.GetEyeTrace().Entity) and enemy.GetEyeTrace().Entity == self then return true end 
		end 
	return false 
end 

function ENT:SbUseableTime(tbl) 
    local KeyName = tbl.KeyName
    self.SBAI_Timers = self.SBAI_Timers or {}

    local expireTime = self.SBAI_Timers[KeyName]
    
    -- REMOVE "Cycle" logic from here. The Decorator just asks "Is it ready?".
    -- The Task (Reset) or the Skill execution logic should handle the cycling.

    if expireTime then
        if CurTime() < expireTime then
            return false -- Blocked
        end
    end

    return true -- Allowed
end


-- skills 

-- SbFollowTarget: Used by Drone only 
-- SbLookAtTarget: no users. has property YawRotationTime 
-- SbMountingEquipment: has 2 users, botattacker and botcommon 
-- SbMoveToFlyingPoint: no users 
-- SBResetTimeLimit: no users 
-- SbSpiderMoveStop: used by M_Antlion_AI. no properties, only used once 
-- SbSpiderMoveToCeiling: no users 
-- SbSpiderMoveToRandomLocation: no users 
-- SbSpiderMoveToTarget: used by antlion 
-- SbSpiderRunFall: no users 



-- SbCautionToTarget: property-driven adaptation (no spawn hacks) 
function ENT:SbCautionToTarget(tbl, nodeID) 
    -- small helpers
    local function SafeGet(key, def) return (tbl[key] ~= nil) and tbl[key] or def end
    local function randFloat(a,b) return a + math.random() * (b - a) end

    -- resolve and fail if no valid target
    if not tbl.target then
        tbl.target = tbl.Target or tbl.TargetEntity or self:GetEnemy()
    end
    local target = tbl.target
    if !IsValid(target) then return false end

    -- Map fields with defaults
    local SetMoveType = SafeGet("SetMoveType", "ESBCautionToTargetMoveType::All")
    local MinDistance = SafeGet("MinDistance", 200)
    local MaxDistance = SafeGet("MaxDistance", 1200)
    local RunDistance = SafeGet("RunDistance", 0)
    local SideMin = SafeGet("SideMoveMinDistance", 300)
    local SideMax = SafeGet("SideMoveMaxDistance", 800)
    local SideRepeat = math.max( SafeGet("SideMoveRepeatCount", 1), 1 )
    local WaitCheckTime = SafeGet("WaitCheckTime", 0)
    local bWaitRandom = SafeGet("bWaitCheckRandomTime", false)
    local WaitRandMin = SafeGet("WaitCheckTimeRandomMinTime", math.max(0, WaitCheckTime - 1))
    local WaitRandMax = SafeGet("WaitCheckTimeRandomMaxTime", WaitCheckTime + 1)
    local WaitRate = SafeGet("WaitRate", 100) -- percent (kept for reference)
    local PlayShowRateWhenWait = SafeGet("PlayShowRateWhenWait", 0) -- percent
    local WaitCountByGroup = math.max( SafeGet("WaitCountByGroup", 1), 1 )
    local bLockOn = SafeGet("bLockOn", false)
    local bIgnoreRestartSelf = SafeGet("bIgnoreRestartSelf", false)
    local bStayTargetView = SafeGet("bStayTargetView", false)
    local CheckSkillFlag = SafeGet("CheckSkillFlag", nil) -- not acted on here

    -- initialize per-task cached fields (only once) 
	if !self:SBAI_GetNodeState(nodeID, "hasStarted") then 
		self:SBAI_SetNodeState(nodeID, "hasStarted", true) 
		self:SBAI_SetNodeState(nodeID, "startTime", CurTime()) 
		self:SBAI_SetNodeState(nodeID, "attempts", 0) 
		self:SBAI_SetNodeState(nodeID, "navSet", false) 
		self:SBAI_SetNodeState(nodeID, "waitEnd", nil) 
		self:SBAI_SetNodeState(nodeID, "returnSucceeded", false) 

        -- compute wait time (possibly randomized)
        if WaitCheckTime > 0 then
            if bWaitRandom then
				self:SBAI_SetNodeState(nodeID, "waitTime", randFloat(WaitRandMin, WaitRandMax)) 
            else
				self:SBAI_SetNodeState(nodeID, "waitTime", WaitCheckTime) 
            end
        else
			self:SBAI_SetNodeState(nodeID, "waitTime", 0) 
        end

        -- group repetition counter 
		self:SBAI_SetNodeState(nodeID, "waitGroupRemaining", WaitCheckTime) 

        -- side repeat counter
		self:SBAI_SetNodeState(nodeID, "sideRepeatRemaining", SideRepeat) 

        -- preserved random choices if bIgnoreRestartSelf; re-roll only if absent or not preserving
        if !(bIgnoreRestartSelf and self:SBAI_GetNodeState(nodeID, "chosenMoveChoice")) then
			self:SBAI_SetNodeState(nodeID, "chosenMoveChoice", nil) 
        end
        if !(bIgnoreRestartSelf and self:SBAI_GetNodeState(nodeID, "sideSign")) then
			self:SBAI_SetNodeState(nodeID, "sideSign", (math.random() < 0.5) and -1 or 1) 
        end
        if !(bIgnoreRestartSelf and self:SBAI_GetNodeState(nodeID, "sideDist")) then
			self:SBAI_SetNodeState(nodeID, "sideDist", math.Rand(SideMin, SideMax)) 
        end
        if !(bIgnoreRestartSelf and self:SBAI_GetNodeState(nodeID, "forwardDist")) then
			self:SBAI_SetNodeState(nodeID, "forwardDist", math.Rand(MinDistance, math.max(MinDistance, MaxDistance))) 
        end

        -- yaw lock
        if bLockOn then
            self:SetMoveYawLocked(false) -- disabled  
        end

        -- choose movement style now (set tbl.chosenMoveChoice if not set)
        if !self:SBAI_GetNodeState(nodeID, "chosenMoveChoice") then
            if SetMoveType == "ESBCautionToTargetMoveType::Side" then
				self:SBAI_SetNodeState(nodeID, "chosenMoveChoice", "side")
            elseif SetMoveType == "ESBCautionToTargetMoveType::ForwardAndSide" then
				self:SBAI_SetNodeState(nodeID, "chosenMoveChoice", "forwardandside") 
            else -- All or unknown: decide probabilistically by declared ranges
                local forwardRange = math.max(0, (MaxDistance or 0) - (MinDistance or 0))
                local sideRange = math.max(0, (SideMax or 0) - (SideMin or 0))
                -- if RunDistance present, bias toward forward
                if RunDistance and RunDistance > 0 then forwardRange = forwardRange + RunDistance end
                -- avoid zero division
                if forwardRange + sideRange <= 0 then
                    -- fallback: choose forward if MinDistance small, else side
					self:SBAI_SetNodeState(nodeID, "chosenMoveChoice", (MinDistance <= SideMin) and "forward" or "side" ) 
                else
                    local pForward = forwardRange / (forwardRange + sideRange)
                    if math.random() < pForward then 
						self:SBAI_SetNodeState(nodeID, "chosenMoveChoice", "forward") else self:SBAI_SetNodeState(nodeID, "chosenMoveChoice", "side") 
					end
                end
            end
        end

        -- increment attempts
        -- tbl.attempts = tbl.attempts + 1
		self:SBAI_SetNodeState(nodeID, "attempts", self:SBAI_GetNodeState(nodeID,"attempts") +1) 
    end -- init done

    -- if nav not set, create nav goal according to chosenMoveChoice 
	if !self:SBAI_GetNodeState(nodeID,"navSet") then 
        local myPos = self:GetPos()
        local tgtPos = target:GetPos()
        local dir = (tgtPos - myPos)
        local dir2D = Vector(dir.x, dir.y, 0)
        if dir2D:Length() > 0.001 then dir2D:Normalize() else dir2D = Vector(1,0,0) end
        local rightVec = dir2D:Angle():Right()

        local chosen = self:SBAI_GetNodeState(nodeID, "chosenMoveChoice") 

        local goalPos = tgtPos
        if chosen == "side" then
            goalPos = tgtPos + rightVec * (self:SBAI_GetNodeState(nodeID,"sideDist") * self:SBAI_GetNodeState(nodeID,"sideSign"))
        elseif chosen == "forward" then
            goalPos = tgtPos - dir2D * self:SBAI_GetNodeState(nodeID,"forwardDist") 
        elseif chosen == "forwardandside" then
            goalPos = tgtPos - dir2D * self:SBAI_GetNodeState(nodeID,"forwardDist") + rightVec * (self:SBAI_GetNodeState(nodeID,"sideDist") * self:SBAI_GetNodeState(nodeID,"sideSign"))
        else
            -- defensive fallback to forward
            goalPos = tgtPos - dir2D * self:SBAI_GetNodeState(nodeID,"forwardDist") 
        end

        -- Prefer NavSetRandomGoal for side moves to create natural paths; otherwise NavSetGoalPos.
        if chosen == "side" then
            local minPathLen = math.Clamp(self:SBAI_GetNodeState(nodeID,"sideDist") * 0.5, 100, 2000)
            self:NavSetRandomGoal(minPathLen, (tgtPos - myPos):GetNormalized()) 
        else
			self:NavSetGoalPos(goalPos) 
		end 
		self:SBAI_SetNodeState(nodeID,"navSet",true) 
		self:SetMovementActivity(ACT_WALK) 
        return nil -- running while nav completes
    end 

    -- -- While nav is set, keep running until movement stops; try to detect movement using available API:
    -- if self.IsMoving and type(self.IsMoving) == "function" then
        -- if self:IsMoving() then return nil end
    -- else
        -- -- fallback heuristic: if current distance to goal is still far, consider still moving.
        -- -- We judge "movement finished" by whether navSet is true and we're not moving (or attempts exceeded)
        -- -- We'll compute distance to target and allow finishing if inside MaxDistance.
        -- local curDistToTarget = (self:GetPos() - target:GetPos()):Length()
        -- if curDistToTarget > math.max( (MinDistance or 0), 100 ) and tbl.attempts <= 6 then
            -- -- still likely moving / trying; let it run a few attempts
            -- return nil
        -- end
    -- end
	-- if self:IsMoving() then return nil end 

    -- If we reach here, nav likely finished (success or not). Decide success:
    local curDist = (self:GetPos() - target:GetPos()):Length()
    local success = false
    -- success if within MaxDistance (or at least within a reasonable threshold based on MinDistance)
    if curDist <= math.max( (MaxDistance or 1200), (MinDistance or 200) ) then
        success = true
    else
        -- if we were performing side moves, consider success when side repeats exhausted
        if self:SBAI_GetNodeState(nodeID, "chosenMoveChoice") == "side" or self:SBAI_GetNodeState(nodeID, "chosenMoveChoice") == "forwardandside" then
            if self:SBAI_GetNodeState(nodeID, "sideRepeatRemaining") and self:SBAI_GetNodeState(nodeID, "sideRepeatRemaining") <= 1 then
                success = true
            end
        end
    end

    -- if we did side movement and have repeats remaining, decrement and prepare another side move
    if !self:SBAI_GetNodeState(nodeID, "waitEnd") and (self:SBAI_GetNodeState(nodeID, "chosenMoveChoice") == "side" or self:SBAI_GetNodeState(nodeID, "chosenMoveChoice") == "forwardandside") and self:SBAI_GetNodeState(nodeID, "sideRepeatRemaining") and self:SBAI_GetNodeState(nodeID, "sideRepeatRemaining") > 1 then
        self:SBAI_SetNodeState(nodeID, "sideRepeatRemaining",self:SBAI_GetNodeState(nodeID, "sideRepeatRemaining") - 1) 
        -- pick new lateral sign unless preserving with bIgnoreRestartSelf
        if !bIgnoreRestartSelf then self:SBAI_SetNodeState(nodeID, "sideSign",(math.random() < 0.5) and -1 or 1) end 
		self:SBAI_SetNodeState(nodeID,"navSet",false) 
		self:SBAI_SetNodeState(nodeID,"attempts",self:SBAI_GetNodeState(nodeID,"attempts") +1) 
        return nil
    end

    -- Start wait phase when movement finished (or attempts exhausted) 
    if !self:SBAI_GetNodeState(nodeID, "waitEnd") then 
		self:SBAI_SetNodeState(nodeID,"returnSucceeded",success) 
		self:SBAI_SetNodeState(nodeID, "waitEnd",CurTime() + (self:SBAI_GetNodeState(nodeID, "waitEnd") or 0)) 
        -- maybe play a show/gesture with PlayShowRateWhenWait probability 
        if PlayShowRateWhenWait and PlayShowRateWhenWait > 0 and math.random() * 100 <= PlayShowRateWhenWait then 
            -- safe-call a generic "gesture" if present (you can replace with your own) 
            -- pcall(function() if self.PlayGesture then self:PlayGesture(ACT_GESTURE_TURN_RIGHT) end end) 
        end 
    end 

    -- during wait: keep looking at target if requested 
    if self:SBAI_GetNodeState(nodeID, "waitEnd") and CurTime() < self:SBAI_GetNodeState(nodeID, "waitEnd") then 
        if bStayTargetView then 
            -- if NPC API offers SetEyeTarget / look functions, use them safely 
            -- pcall(function() 
                -- if self.SetEyeTarget then self:SetEyeTarget(target:GetPos()) end 
            -- end) 
        end 
        return nil -- still waiting 
    end 

    -- wait finished: decrement group counter and either finish or iterate another cycle
    if self:SBAI_GetNodeState(nodeID, "waitEnd") and CurTime() >= self:SBAI_GetNodeState(nodeID, "waitEnd") then
        self:SBAI_SetNodeState(nodeID, "waitEnd",nil) 
		self:SBAI_SetNodeState(nodeID, "waitGroupRemaining",math.max(0, (self:SBAI_GetNodeState(nodeID, "waitGroupRemaining") or 1) - 1)) 

        -- if group cycles remain, prepare for another caution move
        if self:SBAI_GetNodeState(nodeID, "waitGroupRemaining") > 0 then
            self:SBAI_SetNodeState(nodeID, "navSet",false) 
			self:SBAI_SetNodeState(nodeID, "sideRepeatRemaining",SideRepeat) 
            -- if not preserving, re-roll movement choices to create variety
            if !bIgnoreRestartSelf then
				self:SBAI_SetNodeState(nodeID, "chosenMoveChoice",nil) 
				self:SBAI_SetNodeState(nodeID, "sideSign",(math.random() < 0.5) and -1 or 1) 
				self:SBAI_SetNodeState(nodeID, "sideDist",math.Rand(SideMin, SideMax)) 
				self:SBAI_SetNodeState(nodeID, "forwardDist",math.Rand(MinDistance, math.max(MinDistance, MaxDistance))) 
            end
            return nil
        end

        -- final decision: succeed if movement reported success, else fail
        -- clear move locks and stop
        self:StopMoving(true) 
        self:ClearGoal() 
        if bLockOn then self:SetMoveYawLocked(false) end

        if self:SBAI_GetNodeState(nodeID, "returnSucceeded") then 
            return true 
        else 
            return false 
        end 
    end 

    -- default: still running
    return nil
end

function ENT:SbIsGroupTarget(tbl)
    local target = self:GetEnemy()
    if not IsValid(target) then return false end

    local isGroup = (self.bGroupAttacker == true)
    -- if tbl.bInverseCondition then
        -- return not isGroup
    -- end
    return isGroup
end

function ENT:SbDetectTarget(tbl, nodeID)
    local enemy = self:GetEnemy()
    if IsValid(enemy) and enemy:Alive() then
        -- Enemy already acquired: fail so parent Selector can advance to combat subtrees
        return false
    end

    local target = StellarBlade.PickTarget(self)
    if IsValid(target) and target:Alive() then
        if self.SetEnemy then self:SetEnemy(target) end
        return true
    end

    return false
end

--==============================================================================
-- TASK: SbMoveToHome (USBBTTask_SbMoveToHome)
-- Moves NPC toward wander goal or spawn position, scanning for targets if requested.
--
-- Unimplemented ESBMoveState enum values:
--   - MoveState_None   (0): No movement state specified
--   - MoveState_Sprint (3): Unimplemented (high-speed burst)
--   - MoveState_Spider (4): Unimplemented (wall-crawl / burrowing crawl)
--   - MoveState_Fly    (5): Unimplemented (airborne nav)
--   - MoveState_Jog    (6): Unimplemented (intermediate jog)
--==============================================================================
function ENT:SbMoveToHome(data, nodeID)
	print("CurTime in SbMoveToHome:",CurTime()) 
	data = data or {}

	-- -------------------------------------------------------------------------
	-- 1. Helper: Target Matching Filter
	-- Evaluates if a given entity satisfies the detection properties
	-- -------------------------------------------------------------------------
	local function IsTargetValid(ent)
		if not IsValid(ent) then return false end

		-- Dead check
		if data.bDead then
			if ent:Alive() then return false end
		else
			if not ent:Alive() then return false end
		end

		-- Enemy check
		if data.bEnemy then
			local isEnemy = (ent == self:GetEnemy()) 
				or (self.Disposition and self:Disposition(ent) == D_HT)
				or (ent:IsPlayer() and not ent:IsFlagSet(FL_NOTARGET))
			if not isEnemy then return false end
		end

		-- Ally check
		if data.bAlly then
			local isAlly = (self.Disposition and self:Disposition(ent) == D_LI)
			if not isAlly then return false end
		end

		-- EffectAliasArray: Target must possess at least one of these effects
		if data.EffectAliasArray and #data.EffectAliasArray > 0 then
			local hasRequired = false
			if ent.SB_EffectAlias then
				for _, effectName in ipairs(data.EffectAliasArray) do
					if ent.SB_EffectAlias[effectName] and not table.IsEmpty(ent.SB_EffectAlias[effectName]) then
						hasRequired = true
						break
					end
				end
			end
			if not hasRequired then return false end
		end

		-- NoneEffectAliasArray: Target must NOT possess any of these effects
		if data.NoneEffectAliasArray and #data.NoneEffectAliasArray > 0 then
			if ent.SB_EffectAlias then
				for _, effectName in ipairs(data.NoneEffectAliasArray) do
					if ent.SB_EffectAlias[effectName] and not table.IsEmpty(ent.SB_EffectAlias[effectName]) then
						return false
					end
				end
			end
		end

		return true
	end

	-- -------------------------------------------------------------------------
	-- 2. Initialization on Task Start
	-- -------------------------------------------------------------------------
	local hasStarted = self:SBAI_GetNodeState(nodeID, "hasStarted")
	if not hasStarted then
		self:SBAI_SetNodeState(nodeID, "hasStarted", true)
		self:SBAI_SetNodeState(nodeID, "startTime", CurTime())

		-- Determine MoveState Activity
		-- MoveState_Walk = 1, MoveState_Run = 2
		local moveState = data.MoveState or 1
		local isRun = (moveState == 2) or (moveState == "ESBMoveState::MoveState_Run") or (isstring(moveState) and string.find(moveState, "Run") ~= nil)
		local isWalk = (moveState == 1) or (moveState == "ESBMoveState::MoveState_Walk") or (isstring(moveState) and string.find(moveState, "Walk") ~= nil)

		if isRun then
			self:SetMovementActivity(ACT_RUN)
		elseif isWalk then
			self:SetMovementActivity(ACT_WALK)
		else
			-- Fallback default for MoveState_None and unsupported MoveStates
			self:SetMovementActivity(ACT_WALK)
		end

		-- Set Navigation Goal
		-- Currently uses NavSetWanderGoal (min: 400, max: 1200) as requested.
		-- (To switch to spawn position later, replace with: self:NavSetGoalPos(self.SpawnPosition))
		local navOk = false
		if self.NavSetWanderGoal then
			navOk = self:NavSetWanderGoal(400, 1200)
		elseif self.NavSetRandomGoal then
			navOk = self:NavSetRandomGoal(600, self:GetForward())
		end

		-- If pathing failed immediately, fail the task
		if not navOk and not self:IsGoalActive() then
			self:SBAI_SetNodeState(nodeID, "hasStarted", false)
			self:SBAI_SetNodeState(nodeID, "startTime", nil)
			return false
		end

		return nil -- Yield while path begins
	end

	-- -------------------------------------------------------------------------
	-- 3. Runtime Target Detection Check (bDetectTarget)
	-- -------------------------------------------------------------------------
	if data.bDetectTarget then
		local foundTarget = nil

		-- Priority 1: Current enemy
		if IsValid(self:GetEnemy()) and IsTargetValid(self:GetEnemy()) then
			foundTarget = self:GetEnemy()
		end

		-- Priority 2: Known enemies in perception
		if not foundTarget and self.GetKnownEnemies then
			for _, enemy in ipairs(self:GetKnownEnemies()) do
				if IsTargetValid(enemy) then
					foundTarget = enemy
					break
				end
			end
		end

		-- Priority 3: Fallback scanner
		if not foundTarget and StellarBlade and StellarBlade.PickTarget then
			local picked = StellarBlade.PickTarget(self)
			if IsTargetValid(picked) then
				foundTarget = picked
			end
		end

		-- Target detected while moving home: succeed to let AI engage
		if IsValid(foundTarget) then
			if self.SetEnemy and self:GetEnemy() ~= foundTarget then
				self:SetEnemy(foundTarget)
			end

			self:StopMoving(true)
			self:ClearGoal()
			self:ResetIdealActivity(ACT_IDLE)
			self:SBAI_SetNodeState(nodeID, "hasStarted", false)
			self:SBAI_SetNodeState(nodeID, "startTime", nil)
			return true
		end
	end

	-- -------------------------------------------------------------------------
	-- 4. Navigation Progress & Completion Checks
	-- -------------------------------------------------------------------------
	-- Goal reached (nav engine cleared goal upon arrival)
	if not self:IsGoalActive() then
		self:StopMoving(true)
		self:ClearGoal()
		self:ResetIdealActivity(ACT_IDLE)
		self:SBAI_SetNodeState(nodeID, "hasStarted", false)
		self:SBAI_SetNodeState(nodeID, "startTime", nil)
		return true
	end

	-- Safety timeout: fail task if pathing gets stuck longer than 10 seconds
	local startTime = self:SBAI_GetNodeState(nodeID, "startTime") or CurTime()
	if CurTime() - startTime > 10.0 then
		self:StopMoving(true)
		self:ClearGoal()
		self:ResetIdealActivity(ACT_IDLE)
		self:SBAI_SetNodeState(nodeID, "hasStarted", false)
		self:SBAI_SetNodeState(nodeID, "startTime", nil)
		return false
	end

	-- Still traveling to goal
	return nil
end
--[[ 
MoveState_None                           = 0,
	MoveState_Walk                           = 1,
	MoveState_Run                            = 2,
	MoveState_Sprint                         = 3,
	MoveState_Spider                         = 4,
	MoveState_Fly                            = 5,
	MoveState_Jog                            = 6,
	MoveState_MAX                            = 7,
--]] 

function ENT:SbMoveToTarget(tbl) 
	-- parameters: MoveState, TargetType, DroneFollowLocationType, SystemTypeKey, LocationHoldingTime, bUseNavMesh, DistanceOfApproach, ExecutableDistanceToTarget, TeleportDistance, LocalRelativeLocation, LookAtRelativeLocation 
	if self["ESBActorState::ActorState_BlockingBehavior"] or self["ESBActorState::ActorState_BlockMove"] then return end 
	local MoveState = tbl.MoveState
	local DistanceOfApproach = tbl.DistanceOfApproach or 250 -- i think this means walk until distancetoenemy < 250 
	local enemyDist = self.enemyDist_2d or self.enemyDist or 9999 
	if enemyDist < DistanceOfApproach then 
		self:ClearGoal(true) 
		return true 
	else 
		local bBackgroundTask = tbl.bBackgroundTask 
		local NodeName = tbl.NodeName 
		local navSet = self:IsGoalActive() 
		-- print(self:IsGoalActive(),self,self:GetCurWaypointPos(),self:GetActivity()) 
		if !navSet then 
			if IsValid(self:GetEnemy()) then 
				-- navSet = self:NavSetGoalTarget(self:GetEnemy()) 
				-- navSet = self:NavSetGoalPos(self:GetPos() + (self:GetForward()*300)) 
				self:ChainStartTask("TASK_GET_PATH_TO_ENEMY_LKP",0) 
				navSet = !self:GetCurWaypointPos():IsZero() 
			else 
				navSet = self:NavSetGoalPos(self:GetPos() + (self:GetForward()*300)) 
			end 
		end 
		self:SetMovementActivity(ACT_WALK) 
		if !navSet then return false end 
	end 
end 

-- SbPlayShow: Manages show playback and clean cleanup
function ENT:SbPlayShow(tbl, nodeID)
    local showPath = tbl.ShowPath
    local bWait = (tbl.bWait ~= false)
    local showObject = self:SBAI_GetNodeState(nodeID, "hasStarted")

    if not showObject then
        local cleanPath = string.StripExtension(showPath)
        local show = StellarBlade.SetShow(self, cleanPath, "Show")
        if not bWait then return true end
        if not show then return false end

        self:SBAI_SetNodeState(nodeID, "hasStarted", show)
        return nil
    else
        local isFinished = true
        if istable(showObject) and not showObject.Stopped and not showObject.IsMarkedForDeletion then
            if self.SBAI_ActiveShows and table.HasValue(self.SBAI_ActiveShows, showObject) then
                isFinished = false
            end
        end

        if isFinished then
            self.SBAI_RuntimeState[nodeID] = nil
            return true
        else
            return nil
        end
    end
end

function ENT:SbUseEffect(tbl) -- add effect 
	local bSelfActor = tbl.bSelfActor 
	local EffectAlias = tbl.EffectAlias 
	local bSubTarget = tbl.bSubTarget or false 
	local target = self:GetEnemy() 
	if bSelfActor then target = self end 
	if IsValid(target) then 
		for _, EffectTable in ipairs(EffectAlias) do 
			StellarBlade.AddEffect(target,EffectTable) -- returns true on effect add, false on effect not added 
		end 
	end 
	return true 
end 

-- SbUseSkill 
-- indices in tbl contain skill names, [1]	=	M_Raven_ParryPreview1 
-- skill names are looked up from SkillCommandTable.json, "M_Raven_ParryPreview1": {"SkillAlias": "M_Raven_ParryPreview1"} 
-- looked up skill's SkillAlias is called from SkillTable.json, "M_Raven_ParryPreview1": {
-- TargetFilterAlias is activated in TargetFilterTable, "TargetFilterAlias": "M_Raven_ParryPreview1_Target", 
-- FirstSkillActiveAlias is activated in SkillActiveStepTable, "FirstSkillActiveAlias": "M_Raven_ParryPreview1_Cast1"} 
-- FirstSkillActiveAlias contains dir to animation data in FirstSkillActiveAlias, "ShowPath": "CH_M_NA_53_Raven/Skill/M_Raven_ParryPreview" 
-- inside anim metadata, actual animation exists in SBShowAnimKey's Properties["AnimResourcePath"] = "/Game/Art/Character/Monster/CH_M_NA_53/Animation/M_Raven_BurstAreaSlashEnd" 

-- SbUseSkill: Starts skill, yields during execution, returns true on completion
function ENT:SbUseSkill(tbl, nodeID)
    if StellarBlade.IsGroggy(self) then return false end
    if StellarBlade.IsDown(self) then return false end

    local started = self:SBAI_GetNodeState(nodeID, "hasStarted")
    if not started then
        local startedAny = false
        for k, v in RandomPairs(tbl.SkillName) do
            if isnumber(k) then
                if tbl.bUseSkillCommand then
                    if StellarBlade.StartSkillCommand(self, v) then
                        self:SBAI_SetNodeState(nodeID, "hasStarted", true)
                        startedAny = true
                        break
                    end
                else
                    if StellarBlade.StartSkill(self, v) then
                        self:SBAI_SetNodeState(nodeID, "hasStarted", true)
                        startedAny = true
                        break
                    end
                end
            end
        end
        if not startedAny then
            self.SBAI_RuntimeState[nodeID] = nil
            return false
        end
        return nil
    end

    if not self.SBAI_SkillStep or not self.SBAI_SkillStep:IsActive() then
        if self.NPC_StopScriptedActivity then self:NPC_StopScriptedActivity() end
        -- if self.ResetIdealActivity then self:ResetIdealActivity(ACT_IDLE) end
        self.SBAI_RuntimeState[nodeID] = nil
        return true
    else
        return nil
    end
end

function ENT:SbUseableTimeReset(tbl)
    local KeyName = tbl.KeyName
    self.SBAI_Timers = self.SBAI_Timers or {}

    local initial = tbl.SetInitialTimeValue or 0
    local cycle   = tbl.SetCycleTimeValue or -1

    -- First activation: set expiry to now + initial
    self.SBAI_Timers[KeyName] = CurTime() + initial

    -- Store cycle info if needed
    if cycle and cycle > 0 then
        self.SBAI_Timers[KeyName.."_Cycle"] = cycle
    else
        self.SBAI_Timers[KeyName.."_Cycle"] = nil
    end

    return true 
end


function ENT:SbWait(tbl, nodeID)
	local WaitTime = tbl.WaitTime or 0
	local bReturnSucceeded = tbl.bReturnSucceeded or false

	local startTime = self:SBAI_GetNodeState(nodeID, "startTime")
	if !startTime then
		startTime = CurTime()
		self:SBAI_SetNodeState(nodeID, "startTime", startTime)
	end

	if CurTime() - startTime < WaitTime then
		return nil -- still waiting
	end

	self:SBAI_SetNodeState(nodeID, "startTime", nil)
	return bReturnSucceeded
end

function ENT:SbWait_Abort(tbl, nodeID)
	self:SBAI_SetNodeState(nodeID, "startTime", nil)
end

function ENT:SbUseSkill_Abort(tbl, nodeID)
	self:SBAI_SetNodeState(nodeID, "hasStarted", false)
	-- UE's AbortTask also cancels the running skill. Uncomment to match (cancels shows, move table, skill step):
	-- StellarBlade.StopSkill(self)
end

-- SbPlayShow (see turret_aggro_fix.lua)
function ENT:SbPlayShow_Abort(tbl, nodeID)
	self:SBAI_SetNodeState(nodeID, "hasStarted", nil)
end

function ENT:SbMetaAI(data) end -- idle AI 
function ENT:SB_LookAtTarget(data) end 
function ENT:SbWaitTimeRandom(data, nodeID) -- only in tachy ai 
    local minTime = data.MinTime or 0.1
    local maxTime = data.MaxTime or 0.3
    local bReturnSucceeded = (data.bReturnSucceeded ~= false)

    local expireTime = self:SBAI_GetNodeState(nodeID, "expireTime")
    if expireTime == nil then
        expireTime = CurTime() + math.Rand(minTime, maxTime)
        self:SBAI_SetNodeState(nodeID, "expireTime", expireTime)
    end

    if CurTime() >= expireTime then
        self.SBAI_RuntimeState[nodeID] = nil
        return bReturnSucceeded
    else
        return nil
    end
end

-- function ENT:Item_Resurrection_Ground(ent) return false end 
-- function ENT:M_Raven_BetaCounterGrab_HitE(ent) return false end 
-- function ENT:LV_FinishQTE_FailDown(ent) return false end 
function ENT:P_Eve_Beta_SwordAura(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:P_Eve_Beta_SwordAura2(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:P_Eve_Beta_SwordAura3(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:M_Common_HitProjectileResult(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:Check_LinkSkillHit_Skill(ent) return true end 

function ENT:ON_LIGHT_DAMAGE() 
	-- get current skill step if available and see whether NextStepAliasWhenAttacked is set 
	local SkillStepTable = self.SBAI_SkillStep 
	if !SkillStepTable then return scripted_ents.GetStored("cycler_actor2").t.ON_LIGHT_DAMAGE(self) end 
	if !SkillStepTable.Name then return scripted_ents.GetStored("cycler_actor2").t.ON_LIGHT_DAMAGE(self) end 
	SkillStepTable = SB_SkillActiveStepTable[1].Rows[SkillStepTable] 
	if !SkillStepTable then return scripted_ents.GetStored("cycler_actor2").t.ON_LIGHT_DAMAGE(self) end 
	if SkillStepTable.NextStepAliasWhenAttacked and SkillStepTable.NextStepAliasWhenAttacked != "None" then 
		StellarBlade.SetSkillStep(self,SkillStepTable.NextStepAliasWhenAttacked) 
	elseif SkillStepTable.NextStepAliasWhenPerfectParry != "None" then 
		local enemy = self:GetEnemy() 
		if IsValid(self:GetEnemy()) then 
			local DamageTime = self:GetLastTimeTookDamageFromEnemy() 
			if DamageTime + 0.02 > CurTime() then 
				StellarBlade.SetSkillStep(self,SkillStepTable.NextStepAliasWhenPerfectParry) 
			end 
		end 
	end 
	return scripted_ents.GetStored("cycler_actor2").t.ON_LIGHT_DAMAGE(self) 
end 

-- Master blink task: single-task orchestration for whole 1.4s blink timeline
-- Put this in your ENT definition (server-side)

function ENT:TASK_BLINK(data) -- 0: towards dynamic GetLastPosition, 1: towards static GetGoalPos which will be cleared after saving 
    -- timeline constants (seconds) derived from the JSON 
	self:ClearCondition(COND.TASK_FAILED) 
    local TOTAL_DURATION = 1.4
    local SOUND_START = 0.03
    local DECAL_START = 0.042
    local PARTICLE1_START = 0.2
    local PARTICLE1_DUR = 0.2735 -- from JSON
    local HIDE_START = 0.3
    local HIDE_DUR = 0.2             -- actorkey duration -> hide from 0.3 to 0.5
    local UNHIDE_AT = HIDE_START + HIDE_DUR -- 0.5
    local PARTICLE2_START = 0.51
    local PARTICLE2_DUR = 0.18714339
    -- movement interpolation window -- move while hidden
    local MOVE_START = HIDE_START
    local MOVE_END = UNHIDE_AT 

	if ( self:GetTaskStatus() == TASKSTATUS_NEW ) then 
		if cvars.Bool("g_debug_cycler_actor2",false) then 
			print("TASK_BLINK: started (ent " .. tostring(self:EntIndex()) .. ")")
		end 
		
		local Pos = data == 1 and self:GetGoalPos() or self:GetLastPosition() 
		if data == 1 then -- limited movement towards GetGoalPos 
			local BestSound = self:GetBestSoundHint()
			if BestSound and BestSound.origin then
				local SoundVolume = tonumber(BestSound.volume) or 0
				SoundVolume = SoundVolume * 1.5 
				local soundOrigin = BestSound.origin

				-- helper: returns true if vec is inside sound sphere
				local function InsideSoundVolume(vec)
					if not vec then return false end
					return vec:DistToSqr(soundOrigin) <= (SoundVolume * SoundVolume)
				end

				-- 1) check current waypoint
				local curWP = self:GetCurWaypointPos() != vector_origin and self:GetCurWaypointPos() or self:GetPos()
				-- debugoverlay.Cross(curWP,50,5) 
				if not InsideSoundVolume(curWP) then
					-- cur waypoint is already outside the sound volume: keep Pos as goal
					-- print("blink curwaypointpos is not volume") 
					Pos = curWP or self:GetGoalPos()
				else
					-- 2) try next waypoint
					local nextWP = self:GetNextWaypointPos() != vector_origin and self:GetNextWaypointPos() or self:GetPos()
					-- debugoverlay.Cross(nextWP,50,5) 
					if nextWP and not InsideSoundVolume(nextWP) then
						-- print("blink nextwaypointpos is not in volume") 
						Pos = nextWP
					else
						-- 3) still inside volume: do a forward trace hull from the sound origin
						local dir = (self:GetPos() - soundOrigin):GetNormalized()
						if dir:IsZero() then dir = Vector(1,0,0) end

						local traceDist = SoundVolume * 1.0
						local trstart = soundOrigin
						local trend = soundOrigin + dir * traceDist
						-- movement code will handle actual blocking
						Pos = trend
					end
				end
			else
				-- no sound hint; leave Pos as-is (GetGoalPos)
				Pos = Pos or self:GetGoalPos()
			end
		end

		self:ClearGoal() -- clear goal after we have stored the GetGoalPos


        -- initialize blink state
        self.CurrentSchedule.blink = self.CurrentSchedule.blink or {}
        self.CurrentSchedule.blink.startpos = self:GetPos()
		self.CurrentSchedule.blink.targetpos = Pos 
        self.CurrentSchedule.blink.triggered = {
            sound = false,
            decal = false,
            particle1 = false,
            hide = false,
            move = false,
            particle2 = false,
            unhide = false,
            finished = false
        }

        -- try to set sequence safely (non-blocking)
		self:SetIdealActivity(ACT_DO_NOT_DISTURB) 
        if self.ResetSequence then
            -- Set the animation sequence name; if this fails it won't break task
            pcall(function() self:ResetSequence("M_Raven_RapidMoveBack") self:SetCycle(0.0) end)
        elseif self.SetSequence then
            pcall(function() self:SetSequence("M_Raven_RapidMoveBack") end)
        end

        -- prepare sound path (use your existing helper; fallback if nil)
        local soundPath = nil 
		soundPath = StellarBlade.BuildSoundScript(self,"addons/sbraven/data_static/SB/Content/Sound/Skill/Monster/Raven/M_Raven_Skill_RapidMove_Cue.json").SoundPath 

        -- store values for runtime use
        self.CurrentSchedule.blink.soundPath = soundPath

        -- mark task as running
        self:SetTaskStatus(TASKSTATUS_RUN_MOVE_AND_TASK)
        return
    end

    -- Running state: update timeline
    -- Use self:TaskTime() where available (time since task started).
    local t = 0
    if self.TaskTime then
        t = self:TaskTime()
    else
        -- fallback if TaskTime is not defined for some NPC variant
        self.CurrentSchedule.blink._sysstart = self.CurrentSchedule.blink._sysstart or CurTime()
        t = CurTime() - self.CurrentSchedule.blink._sysstart
    end
	
	local Pos = data == 1 and self.CurrentSchedule.blink.targetpos or self:GetLastPosition() 
	self:SetIdealActivity(ACT_DO_NOT_DISTURB) 
    local tr = self.CurrentSchedule.blink.triggered

    -- 1) play sound early (SOUND_START)
    if not tr.sound and t >= SOUND_START then
        tr.sound = true
        if self.CurrentSchedule.blink.soundPath then
            self:EmitSound(self.CurrentSchedule.blink.soundPath)
			if cvars.Bool("g_debug_cycler_actor2",false) then 
				print("TASK_BLINK: emitted sound", self.CurrentSchedule.blink.soundPath)
			end 
        else
            -- no sound script found; attempt to play by name if you know it
            -- self:EmitSound("path/to/fallback.wav")
			if cvars.Bool("g_debug_cycler_actor2",false) then 
				print("TASK_BLINK: no sound script available")
			end 
        end
    end

    -- 2) create initial decal (approx start)
	local disabled = true 
	if !disabled then 
		if not tr.decal and t >= DECAL_START then
			tr.decal = true
			-- Use same effect for decal if you prefer; here we create a small effect to hint
			local ef = EffectData()
			ef:SetOrigin(self:WorldSpaceCenter())
			ef:SetEntity(self)
			ef:SetScale(1)
			ef:SetMagnitude(0)
			-- If you have a decal effect name, spawn it; otherwise the effect will be ignored safely by clients that don't have it
			util.Effect("NS_A_Blink", ef) -- this was used before in your code; harmless if missing
			if cvars.Bool("g_debug_cycler_actor2",false) then 
				print("TASK_BLINK: decal/effect spawned (decal start)") 
			end 
		end
	end 

    -- 3) first particle (pre-hide flare) at ~PARTICLE1_START
    if not tr.particle1 and t >= PARTICLE1_START then
        tr.particle1 = true
        local ef = EffectData()
        ef:SetOrigin(self:WorldSpaceCenter())
        ef:SetEntity(self)
        ef:SetMagnitude(0.2735217)
        ef:SetScale(10)
        util.Effect("NS_A_Blink", ef)
		if cvars.Bool("g_debug_cycler_actor2",false) then 
			print("TASK_BLINK: particle1 spawned") 
		end 
    end

    -- 4) hide actor at HIDE_START and begin interpolated movement
    if !tr.hide and t >= HIDE_START then
        tr.hide = true
        -- hide visually:
		-- self:SetNoDraw(true)
        -- capture fresh startpos in case the entity moved slightly after task start
        self.CurrentSchedule.blink.startpos = self:GetPos() 
		if cvars.Bool("g_debug_cycler_actor2",false) then 
			print(("TASK_BLINK: hidden at t=%.3f, startpos=%s targetpos=%s"):format(t, tostring(self.CurrentSchedule.blink.startpos), tostring(Pos))) 
		end 
    end

    -- 5) while hidden, lerp SetPos from startpos -> targetpos between MOVE_START and MOVE_END
    if tr.hide and not tr.move then
		self:NextThink(CurTime()) 
        if t >= MOVE_START and t <= MOVE_END then
            local frac = 0
            if MOVE_END > MOVE_START then frac = math.Clamp((t - MOVE_START) / (MOVE_END - MOVE_START), 0, 1) end
            local newpos = LerpVector(frac, self.CurrentSchedule.blink.startpos, Pos)
            -- keep original z if you want to preserve current height; the JSON moves in local axis, but we assume teleport target is valid
			local moveResult = IterativeHybridMoveLimit(self, self:GetPos(), newpos)
            self:SetLocalPos(moveResult.vEndPosition)
            -- optionally zero velocity to prevent physics interference
            if self.GetVelocity and self.SetLocalVelocity then
                -- no-op: keep it stable if function available
            end
            -- don't set move flag until we actually reach the end
            if frac >= 1.0 then
                tr.move = true
				if cvars.Bool("g_debug_cycler_actor2",false) then 
					print("TASK_BLINK: move finished (arrived at target)") 
				end 
            end
        elseif t > MOVE_END then
            -- if we missed the window for some reason, just snap and mark move done
			local moveResult = IterativeHybridMoveLimit(self, self:GetPos(), Pos)
            self:SetLocalPos(moveResult.vEndPosition)
            tr.move = true
			if cvars.Bool("g_debug_cycler_actor2",false) then 
				print("TASK_BLINK: move forced to target (late)") 
			end 
        end
    end

    -- 6) unhide at UNHIDE_AT
    if tr.hide and not tr.unhide and t >= UNHIDE_AT then
        tr.unhide = true
		self:SetNoDraw(false)
		if cvars.Bool("g_debug_cycler_actor2",false) then 
			print("TASK_BLINK: unhidden at t=" .. tostring(t)) 
		end 
    end

    -- 7) second particle near PARTICLE2_START
    if not tr.particle2 and t >= PARTICLE2_START then
        tr.particle2 = true
        local ef = EffectData()
        ef:SetOrigin(self:WorldSpaceCenter())
        ef:SetEntity(self)
        ef:SetMagnitude(0.18714339)
        ef:SetScale(10)
        util.Effect("NS_A_Blink", ef)
		if cvars.Bool("g_debug_cycler_actor2",false) then 
			print("TASK_BLINK: particle2 spawned") 
		end 
    end

    -- 8) finish at TOTAL_DURATION
    if not tr.finished and t >= TOTAL_DURATION then
        tr.finished = true
        -- final cleanup to be safe
        self:SetNoDraw(false) 
		if cvars.Bool("g_debug_cycler_actor2",false) then 
			print("TASK_BLINK: finished at t=" .. tostring(t)) 
		end 
        self:TaskComplete()
        return
    end
    -- the task is still running; return and will be called again next tick
end

-- create single-task schedule to use the master task
if SERVER then 
    LUASCHED_RAVEN_RAPIDEVADE = ai_schedule.New("LUASCHED_RAVEN_RAPIDEVADE") 
    -- single master task; ensures the whole 1.4s timeline is controlled here 
    LUASCHED_RAVEN_RAPIDEVADE:AddTaskEx("TASK_BLINK", "TASK_BLINK", 0) 
	
	LUASCHED_RAVEN_RAPIDEVADE_FROM_BESTSOUND = ai_schedule.New("LUASCHED_RAVEN_RAPIDEVADE_FROM_BESTSOUND") 
	LUASCHED_RAVEN_RAPIDEVADE_FROM_BESTSOUND:EngTask("TASK_STOP_MOVING",0) 
    LUASCHED_RAVEN_RAPIDEVADE_FROM_BESTSOUND:EngTask("TASK_SET_FAIL_SCHEDULE",SCHED_COWER) 
    LUASCHED_RAVEN_RAPIDEVADE_FROM_BESTSOUND:EngTask("TASK_STORE_BESTSOUND_REACTORIGIN_IN_SAVEPOSITION",0) 
    LUASCHED_RAVEN_RAPIDEVADE_FROM_BESTSOUND:EngTask("TASK_GET_PATH_AWAY_FROM_BEST_SOUND",3000) 
    LUASCHED_RAVEN_RAPIDEVADE_FROM_BESTSOUND:AddTaskEx("TASK_BLINK", "TASK_BLINK", 1) 
end 

local t_a_shineflare_02 = Material("sprites/t_a_shineflare_02") 
local color_cyan = Color(0,255,255) 

function ENT:Draw(flags) 
	scripted_ents.GetStored("cycler_actor2").t.Draw(self,flags) 
	local attachment = { ["FX_Core_01"] = 8, ["FX_Core_02"] = 4, ["FX_Core_03"] = 2, ["FX_Core_04"] = 2} 
	for attachmentname, scale in pairs(attachment) do 
		local attachmentid = self:LookupAttachment(attachmentname) 
		if attachmentid > 0 then 
			local Pos = self:GetAttachment(attachmentid).Pos -- Pos will be used 
			render.SetMaterial(t_a_shineflare_02) 
			for i = 1,math.random(1,3) do 
				render.DrawSprite(Pos,scale,scale,color_cyan) 
			end 
		end 
	end 
end 