AddCSLuaFile() 

-- Define the path to your JSON file relative to the "garrysmod" folder.
IterativeHybridMoveLimit = include("includes/custommoveprobe.lua") 
include("includes/raven_soundscripts.lua") 
include("includes/curframe.lua") 
local tblWeapons = { "raven_blade" } 
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

local filePath = "addons/sbraven/data_static/SB/Content/Local/Data/SkillCommandTable.json"

--[[
    SB_ImportJSON(path) - V2 (Flexible Pathing)
    By Gemini

    Description:
    Imports a single .json file or all .json files in a directory into global Lua tables.
    Now correctly handles both absolute paths (e.g., C:\...) AND GMod-relative paths (e.g., addons/...).
--]] 

function SB_ImportJSON(path)
    -- Helper function to process a single JSON file (unchanged).
    local function ProcessJSONFile(relativePath)
        local fileName = string.match(relativePath, "([^/]+)%.json$")
        if !fileName then
            MsgC(Color(255, 100, 100), "[SB Importer] Invalid file name or not a .json file: ", relativePath, "\n")
            return
        end
        local globalTableName = "SB_" .. fileName

        if _G[globalTableName] then
            MsgC(Color(100, 255, 100), "[SB Importer] Table '", globalTableName, "' already exists. Skipping file read.\n")
            return _G[globalTableName] 
        end

        local jsonString = file.Read(relativePath, "GAME")
        if !jsonString then
            ErrorNoHalt(string.format("[SB Importer] Failed to read file for '%s'! Check path: %s\n", globalTableName, relativePath))
            return
        end

        local tempTable = util.JSONToTable(jsonString,false)
        if !tempTable then
            ErrorNoHalt(string.format("[SB Importer] Failed to parse JSON for '%s'! File may be malformed: %s\n", globalTableName, relativePath))
            return
        end
		
		-- setmetatable(tempTable,{ __newindex = function(t,k,v) error("Tried to write "..k.." to a read-only global table "..globalTableName) end}) 
		function Initialize(tbl) 
			-- setmetatable(tbl,{ __newindex = function(t,k,v) error("Tried to write "..k.." to a read-only global table "..tostring(tbl)) end}) 
			for k,v in pairs(tbl) do if istable(v) then Initialize(v) end end 
		end 
		Initialize(tempTable) 

        _G[globalTableName] = tempTable
        MsgC(Color(100, 255, 100), "[SB Importer] Successfully loaded '", relativePath, "' into global table '", globalTableName, "'.\n")
		return tempTable 
    end

    -- Main function logic starts here.
    -- First, normalize the path separators from Windows-style '\' to '/'
    local normalizedPath = string.gsub(path, "\\", "/")
    local relativePath

    -- NEW, SMARTER PATH HANDLING:
    -- Try to strip the path as if it's absolute.
    local strippedPath = string.match(normalizedPath, "/garrysmod/(.+)")
    if strippedPath then
        -- If it succeeded, it was an absolute path. Use the stripped version.
        relativePath = strippedPath
    else
        -- If it failed, it's already a relative path. Use it as-is.
        relativePath = normalizedPath
    end

    -- The rest of the function proceeds with the correctly determined relativePath.
    if file.IsDir(relativePath, "GAME") then
        local filesInDir = file.Find(relativePath .. "/*.json", "GAME")
        MsgC(Color(255, 255, 100), "[SB Importer] Starting batch import for directory: ", relativePath, "\n")

        if #filesInDir == 0 then
            MsgC(Color(255, 150, 0), "[SB Importer] No .json files found in ", relativePath, "\n")
            return
        end

        for _, fileName in ipairs(filesInDir) do
            -- Make sure the path has a trailing slash before appending the filename
            local dirPath = string.sub(relativePath, -1) == "/" and relativePath or (relativePath .. "/")
            ProcessJSONFile(dirPath .. fileName)
        end
    else
        return ProcessJSONFile(relativePath)
    end
end

SB_ImportJSON("data_static/SB/Content/Local/Data/SkillTable.json")
SB_ImportJSON("data_static/SB/Content/Local/Data/SkillCommandTable.json")
SB_ImportJSON("data_static/SB/Content/Local/Data/SkillActiveStepTable.json")
SB_ImportJSON("data_static/SB/Content/Local/Data/SkillResultTable.json")
SB_ImportJSON("data_static/SB/Content/Local/Data/EffectTable.json")
SB_ImportJSON("data_static/SB/Content/Local/Data/TargetFilterTable.json")
SB_ImportJSON("data_static/SB/Content/Local/Data/CharacterAnimSetTable.json")
SB_ImportJSON("data_static/SB/Content/Local/Data/CharacterMoveTable.json")
SB_ImportJSON("data_static/SB/Content/Local/Data/CharacterTable.json")
local CharacterStanceTable = "data_static/SB/Content/Local/Data/CharacterStanceTable.json" 
SB_ImportJSON(CharacterStanceTable) 
local M_Raven_Default = SB_CharacterStanceTable[1].Rows.M_Raven_Default  
local M_Raven_Phase2 = SB_CharacterStanceTable[1].Rows.M_Raven_Phase2  
table.Merge(ENT,M_Raven_Phase2) 
-- table.Merge(ENT,SB_CharacterTable[1].Rows["M_Raven"]) 
table.Merge(ENT,SB_CharacterTable[1].Rows["M_Raven"]) 
print(SysTime()) 

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

ENT.NPC_AlertSound	= "" 
ENT.NPC_IdleSound 	= "" 
ENT.NPC_GroupIdleSound 	= "" 
ENT.NPC_MeleeHitSound = "Unreali_Nali.MeleeHit" 
ENT.NPC_PainSound 	= "NPC_Raven.PainSound" 
ENT.NPC_PainSoundWater 	= "Unreali_Female.HurtUnderWater" 
ENT.npc_health 		= ENT.MaxHP -- "MaxHP": 248304, "MaxShield": 4805, 
ENT.npc_model		= "models/alvaroports/sbravenpm.mdl" 
-- ENT.PhysicAttackPower = 1600 
ENT.bHasInnateMelee1 = true 
ENT.m_fMaxYawSpeed = 360 -- "RotateAnglePerSecond": 360.0, 
ENT.SBAI_BlackBoard = { } 
ENT.SBAI_bInBackgroundTask = false 
ENT.SB_EffectAlias = { } 
ENT.SBAI_ActiveShow = { } 
ENT.SBAI_SkillTimers = { } 
ENT.CharacterSoundSetPath = "addons/sbraven/data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_53_Raven.json" 
ENT.EVE_CharacterSoundSetPath = "addons/sbraven/data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_PC_EVE.json" 
SB_ImportJSON(ENT.CharacterSoundSetPath) 
-- local M_Raven_AI = SB_ImportJSON("data_static/SB/Content/GameDesign/Combat/BehaviorTree/Monster/M_Raven_AI.json") 
local BehaviorTreeRes = ENT.BehaviorTreeRes 
BehaviorTreeRes = string.sub(BehaviorTreeRes,6) 
BehaviorTreeRes = "data_static/SB/Content"..BehaviorTreeRes..".json" 
SB_ImportJSON(BehaviorTreeRes) 
-- print(BehaviorTreeRes)  
-- "BehaviorTreeRes": "/Game/GameDesign/Combat/BehaviorTree/Monster/M_Raven_AI", 

function ENT:Initialize() 
	scripted_ents.Get("npc_unreali_female").Initialize(self) 
	-- start effects in CharacterStanceTable 
	StellarBlade.ActorStats(self) -- initialize stats if we haven't 
	if SERVER and self.StartEffect then 
		local StartEffect = StellarBlade.ParseTableStrings(self.StartEffect) 
		StellarBlade.AddEffectFromTable(self,StartEffect) 
	end 
	-- start effects in CharacterTable 
end 

function ENT:SBAI_GetEffectTable(strEffect) 
	local EffectTable = SB_EffectTable[1].Rows[strEffect] 
	return EffectTable 
end 

function ENT:SBAI_GetSkillAnimData(name) 
	local data = _G["SB_"..name] 
	if data then return data else MsgC(Color(0,255,0),"SBAI_GetSkillAnimData: "..name.." not precached\n") end 
end 

-- Tick the runtime tree: create/resume the coroutine that runs SBAI_SelectTask
function ENT:SBAI_RunBehavior() 
    -- Create coroutine if missing or dead
    if !self._sbaico or coroutine.status(self._sbaico) == "dead" then 
        -- Ensure tree is indexed and state is reset
        if !self.SBAI_RuntimeState then self:SBAI_InitTree() end

        -- Safety check for the Root ID
        if !self.SBAI_TreeRootID then
            print("[SBAI] Error: Cannot run behavior, TreeRootID is missing!") return 
        end

        print("constructing coroutine starting at:", self.SBAI_TreeRootID) 
        self._sbaico = coroutine.create(function()
            -- CHANGED: Pass the Root ID string, not a table
            return self:SBAI_SelectTask(self.SBAI_TreeRootID)
        end)
    end

    -- Resume coroutine safely
    if coroutine.status(self._sbaico) == "suspended" then
		self:SBAI_CheckObservers() 
        local ok, ret = coroutine.resume(self._sbaico)
        if !ok then
            print("[SBAI] behavior coroutine error:", ret)
            self._sbaico = nil
            self.SBAI_RuntimeState = {} -- Reset state on crash
            self.SBAI_ExecutionStack = {}
            return false
        else
            if coroutine.status(self._sbaico) == "dead" then
                self._sbaico = nil
                print("[SBAI] Tree finished with result:", ret)
                return ret
            else
                return nil
            end
        end
    end
    return false
end

-- Phase 1: The One-Time Indexer
-- Call this in Initialize or OnEntityCreated, before trying to run the AI.
function ENT:SBAI_IndexTree()
    -- Ensure the global raw table exists (imported via "BehaviorTreeRes = SB_ImportJSON(...)")
	local AITable = "SB_"..string.StripExtension(string.GetFileFromFilename(BehaviorTreeRes)) 
    local rawTable = _G[AITable] 
    if !rawTable then
        ErrorNoHalt("[SBAI] BehaviorTreeRes global table not found! Cannot index Behavior Tree.\n")
        return false
    end

    -- 1. Create the Global Lookup Table
    self.SBAI_NodeLookup = {}
    self.SBAI_TreeRootID = nil

    print("[SBAI] Indexing Behavior Tree Nodes...")

    for _, node in ipairs(rawTable) do
        -- 2. Map Keys to Nodes
        -- We must reconstruct the unique string ID that Unreal uses in its references.
        -- Format: Type'Outer:Name'
        -- Example: BTComposite_Selector'M_Raven_AI:BTComposite_Selector_38'
        
        local t = node.Type
        local name = node.Name
        local outer = node.Outer

        -- Only index nodes that are relevant parts of the tree (have an Outer package)
        if t and name and outer then
            local fullID = string.format("%s'%s:%s'", t, outer, name)
            
            -- Store reference to the raw node data
            self.SBAI_NodeLookup[fullID] = node
        end

        -- 3. Find the Root
        -- The entry with t "BehaviorTree" holds the pointer to the start of the logic.
        if t == "BehaviorTree" and node.Properties and node.Properties.RootNode then
            self.SBAI_TreeRootID = node.Properties.RootNode.ObjectName
            print("[SBAI] Found Root Node ID:", self.SBAI_TreeRootID)
        end
    end

    -- Validation
    if !self.SBAI_TreeRootID then
        ErrorNoHalt("[SBAI] Error: Could not find 'BehaviorTree' entry or RootNode property in JSON.\n")
        return false
    end
    
    if table.Count(self.SBAI_NodeLookup) == 0 then
         ErrorNoHalt("[SBAI] Error: Lookup table is empty. Check JSON format (Type/Name/Outer fields).\n")
         return false
    end

    print("[SBAI] Successfully indexed " .. table.Count(self.SBAI_NodeLookup) .. " nodes.")
    return true 
end 

-- Phase 2: State Segregation
-- Call this to reset the AI state (e.g., on spawn or when the tree resets)
function ENT:SBAI_InitTree()
    -- 1. Create the Runtime Registry
    -- Key = NodeID (string), Value = Table { _running=bool, _result=var, _startTime=float, _currentChild=int }
    self.SBAI_RuntimeState = {}

    -- 2. Reset the Execution Stack
    -- This will replace the recursive coroutine stack. It holds the path of NodeIDs currently being traversed.
    self.SBAI_ExecutionStack = {}

    -- 3. Standard Reset
    self.SBAI_bInBackgroundTask = false
    self.CurrentBranch = nil
    self._sbaico = nil
    
    -- Safety check: Ensure the static indexer has run
    if !self.SBAI_NodeLookup then
        self:SBAI_IndexTree()
    end
end

-- Helper: safely set a state value for a node
function ENT:SBAI_SetNodeState(nodeID, key, value)
    if !self.SBAI_RuntimeState[nodeID] then
        self.SBAI_RuntimeState[nodeID] = {}
    end
    self.SBAI_RuntimeState[nodeID][key] = value
end

-- Helper: safely get a state value (returns nil if state doesn't exist)
function ENT:SBAI_GetNodeState(nodeID, key)
    local state = self.SBAI_RuntimeState[nodeID]
    if state then return state[key] end
    return nil
end

-- Helper: Evaluate all decorators on a specific child link (Edge)
-- Returns: boolean (True = Allowed, False = Blocked)
function ENT:SBAI_EvaluateEdge(childEntry)
    if !childEntry.Decorators then return true end

    for _, decoRef in ipairs(childEntry.Decorators) do
        local decoID = decoRef.ObjectName
        local decoNode = self.SBAI_NodeLookup[decoID]

        if decoNode then
            local rawName = decoNode.Type or decoNode.Name
            local funcName = string.gsub(rawName, "^SBBTDecorator_", "")
			
			print("Decorator is:",funcName) 
            if self[funcName] then
                -- Check condition
                local success = self[funcName](self, decoNode.Properties, decoID) 
				print("Decorator result is:", success) 
				if success == nil then Entity(1):ChatPrint("Decorator returned nil: ".. funcName) end 
                if !success then return false end
            end
        end
    end
    return true
end

-- Runs every tick to check for interrupts (Flow Abort)
-- Returns: Boolean (Did we abort something?)
function ENT:SBAI_CheckObservers()
    if #self.SBAI_ExecutionStack == 0 then return false end

    -- Iterate down the stack (from Root -> Current Leaf)
    -- We use a numeric loop because we might modify the stack during the loop
    for stackIdx, frame in ipairs(self.SBAI_ExecutionStack) do
        local nodeID = frame.NodeID
        local nodeData = self.SBAI_NodeLookup[nodeID]
        local currentChildIdx = frame.Index
        
        if not nodeData or not nodeData.Properties.Children then goto next_frame end
        local children = nodeData.Properties.Children

        -- === 1. Check "LowerPriority" & "Both" (Higher Priority Siblings) ===
        -- Look at all siblings to the LEFT of the current running child
        for i = 1, currentChildIdx - 1 do
            local sibling = children[i]
            local abortMode = nil
            
            -- Scan decorators for Abort Mode
            if sibling.Decorators then
                for _, d in ipairs(sibling.Decorators) do
                    local dNode = self.SBAI_NodeLookup[d.ObjectName]
                    if dNode and dNode.Properties.FlowAbortMode then
                        local mode = dNode.Properties.FlowAbortMode
                        if string.find(mode, "LowerPriority") or string.find(mode, "Both") then
                            abortMode = true 
                            break 
                        end
                    end
                end
            end

            -- If this sibling is set to Abort Lower Priority, we check its condition
            if abortMode then
                if self:SBAI_EvaluateEdge(sibling) then
                    -- CRITICAL INTERRUPT: A higher priority node is now valid!
                    -- 1. Clear running state of the *previous* path (the one we are executing now)
                    local runningChildEntry = children[currentChildIdx]
                    local runningID = runningChildEntry.ChildComposite and runningChildEntry.ChildComposite.ObjectName or runningChildEntry.ChildTask and runningChildEntry.ChildTask.ObjectName
                    if runningID then self:SBAI_ClearRunning(runningID) end

                    -- 2. Prune the stack back to this level
                    while #self.SBAI_ExecutionStack > stackIdx do
                        table.remove(self.SBAI_ExecutionStack)
                    end

                    -- 3. Set the index to this sibling (Restart execution here)
                    frame.Index = i
                    
                    -- print("[SBAI] Observer Abort: LowerPriority interrupt at index " .. i)
                    return true -- We interrupted, stop checking
                end
            end
        end

        -- === 2. Check "Self" & "Both" (Current Active Branch) ===
        -- Look at the CURRENT running child
        local currentEntry = children[currentChildIdx]
        local checkSelf = false

        if currentEntry.Decorators then
            for _, d in ipairs(currentEntry.Decorators) do
                local dNode = self.SBAI_NodeLookup[d.ObjectName]
                if dNode and dNode.Properties.FlowAbortMode then
                    local mode = dNode.Properties.FlowAbortMode
                    if string.find(mode, "Self") or string.find(mode, "Both") then
                        checkSelf = true
                        break
                    end
                end
            end
        end

        if checkSelf then
            -- Re-evaluate the current condition
            if !self:SBAI_EvaluateEdge(currentEntry) then
                -- CRITICAL FAILURE: The node we are inside is no longer allowed!
                
                -- 1. Clear running state of the subtree we are killing
                local runningID = currentEntry.ChildComposite and currentEntry.ChildComposite.ObjectName or currentEntry.ChildTask and currentEntry.ChildTask.ObjectName
                if runningID then self:SBAI_ClearRunning(runningID) end

                -- 2. Prune stack back to this level
                while #self.SBAI_ExecutionStack > stackIdx do
                    table.remove(self.SBAI_ExecutionStack)
                end

                -- 3. Handle Failure Logic
                local isSelector = string.find(nodeData.Type, "Selector")
                if isSelector then
                    -- If Selector, try next sibling
                    frame.Index = frame.Index + 1
                else
                    -- If Sequence, the whole sequence fails immediately
                    -- We force the result to fail and pop this frame too
                    frame.ForceResult = false
                    frame.Index = #children + 1 -- This ensures SelectTask pops it
                end

                -- print("[SBAI] Observer Abort: Self condition failed")
                return true
            end
        end

        ::next_frame::
    end

    return false
end

-- Recursive State Clearer
-- 1. Looks up the STATIC structure to find children relationships.
-- 2. Deletes the DYNAMIC state in the registry for those children.
function ENT:SBAI_ClearRunning(nodeID)
    if !nodeID then return end

    -- 1. Clear the runtime state for this specific node
    if self.SBAI_RuntimeState[nodeID] then
        -- We explicitly nil these out to reset the node completely
        self.SBAI_RuntimeState[nodeID]._running = false
        self.SBAI_RuntimeState[nodeID]._result = nil
        self.SBAI_RuntimeState[nodeID]._startTime = nil
        self.SBAI_RuntimeState[nodeID]._currentChild = nil
        
        -- Optional: Remove the entry entirely to save memory, 
        -- though keeping the table can reduce garbage collection churn.
        -- self.SBAI_RuntimeState[nodeID] = nil 
    end

    -- 2. Find children using the STATIC Lookup Table
    local staticNode = self.SBAI_NodeLookup[nodeID]
    
    -- Use the static definition to find what *could* be running below this node
    if staticNode and staticNode.Properties and staticNode.Properties.Children then
        for _, childEntry in ipairs(staticNode.Properties.Children) do
            local childID = nil
            
            -- Resolve child ID based on type
            if childEntry.ChildComposite then
                childID = childEntry.ChildComposite.ObjectName
            elseif childEntry.ChildTask then
                childID = childEntry.ChildTask.ObjectName
            end

            -- Recursively clear state for the child
            if childID then
                self:SBAI_ClearRunning(childID)
            end
        end
    end

    -- 3. Coroutine Safety
    -- If we are clearing the root or the currently running branch, the existing coroutine 
    -- is now invalid because its local variables refer to states we just wiped.
    if self._sbaico and nodeID == self.SBAI_TreeRootID then
        self._sbaico = nil
    end
end 

-- Phase 3: The Runner Logic (FIXED)
function ENT:SBAI_SelectTask(startNodeID)
    -- Initialize stack if empty
    if #self.SBAI_ExecutionStack == 0 then
        table.insert(self.SBAI_ExecutionStack, { NodeID = startNodeID, Index = 1 })
    end

    -- SAFETY: Prevent infinite loops if the tree resolves instantly
    local ops = 0
    local max_ops = 500 

    while #self.SBAI_ExecutionStack > 0 do
        ops = ops + 1
        if ops > max_ops then
            print("[SBAI] Infinite Loop Detected! Tree resolved too many nodes without yielding.")
            return nil -- Force a yield/break
        end

        -- 1. Get the current Stack Frame
        local frame = self.SBAI_ExecutionStack[#self.SBAI_ExecutionStack]
        local nodeID = frame.NodeID
        local nodeData = self.SBAI_NodeLookup[nodeID] 
        
        -- Safety Check
        if !nodeData or !nodeData.Properties.Children then
            table.remove(self.SBAI_ExecutionStack)
            goto continue_loop
        end

        local children = nodeData.Properties.Children
        local idx = frame.Index
        
        -- Helper to identify composite type
        local isSelector = string.find(nodeData.Type, "Selector")

        -- 2. Check if we have processed all children (Pop Logic)
        if idx > #children then
            table.remove(self.SBAI_ExecutionStack)
            
            -- Default Results: Selector=False (Fail), Sequence=True (Success)
            local compositeResult = !isSelector 
            
            -- OVERRIDE: Did we force a result? (Used when decorators fail in a sequence)
            if frame.ForceResult != nil then
                compositeResult = frame.ForceResult
            end
            
            -- Propagate result to parent
            if #self.SBAI_ExecutionStack > 0 then
                local parentFrame = self.SBAI_ExecutionStack[#self.SBAI_ExecutionStack]
                local parentNode = self.SBAI_NodeLookup[parentFrame.NodeID]
                local parentIsSelector = string.find(parentNode.Type, "Selector")
                
                -- Standard Propagation:
                -- Parent Selector + Child Success = Parent Success (Stop)
                -- Parent Sequence + Child Fail    = Parent Fail (Stop)
                if (parentIsSelector and compositeResult == true) or (!parentIsSelector and compositeResult == false) then
                    -- Force Parent to finish early
                    parentFrame.ForceResult = compositeResult
                    parentFrame.Index = #parentNode.Properties.Children + 1 -- Move index to end to trigger pop next loop
                else
                    -- Parent continues to next sibling
                    parentFrame.Index = parentFrame.Index + 1
                end
            end
            
            if #self.SBAI_ExecutionStack == 0 then return compositeResult end
            goto continue_loop
        end

        -- 3. Look at the Child
        local childEntry = children[idx]
        local canExecute = true

		
		-- 4. Edge Decorators
		-- We use the same helper, but here we check ALL decorators (blocking logic)
		local canExecute = self:SBAI_EvaluateEdge(childEntry)

        -- 5. Decorator Handling (THE FIX)
        if !canExecute then
			if backgroundtask then 
			-- [NEW] Safety Check: If we are aborting a node that was ALREADY running, we must clear its state!
				local childID = nil
				if childEntry.ChildComposite then 
					childID = childEntry.ChildComposite.ObjectName
				elseif childEntry.ChildTask then 
					childID = childEntry.ChildTask.ObjectName 
				end
            
				if childID and self:SBAI_GetNodeState(childID, "_running") then
					 -- print("[SBAI] Aborting running node due to decorator failure:", childID)
					 self:SBAI_ClearRunning(childID)
				end
			end 
            -- [END NEW]
		
            if isSelector then
                -- Selector: Child blocked? Just try the next one.
                frame.Index = frame.Index + 1
            else
                -- Sequence: Child blocked? THE SEQUENCE FAILS.
                frame.ForceResult = false
                frame.Index = #children + 1 -- Force pop
            end
            goto continue_loop
        end

        -- 6. Execute Child
        if childEntry.ChildComposite then
            local nextID = childEntry.ChildComposite.ObjectName
            table.insert(self.SBAI_ExecutionStack, { NodeID = nextID, Index = 1 })
            goto continue_loop

        elseif childEntry.ChildTask then
            local taskID = childEntry.ChildTask.ObjectName
            local taskNode = self.SBAI_NodeLookup[taskID]
            local taskName = string.gsub(taskNode.Type, "^SBBTTask_", "")
            
            -- Manage Running State
            local isRunning = self:SBAI_GetNodeState(taskID, "_running")
            if !isRunning then
                self:SBAI_SetNodeState(taskID, "_running", true)
                self:SBAI_SetNodeState(taskID, "_startTime", CurTime())
            end

            -- Run Task
            if self[taskName] then 
				print("Task is:",taskName) 
                local result = self[taskName](self, taskNode.Properties, taskID) 
				print("Task result is:",result) 
                
                if result == nil then
                    coroutine.yield() -- Running
					if self:IsFlagSet(FL_KILLME) then return false end -- called during OnRemove, closes variables 
                else
                    self:SBAI_SetNodeState(taskID, "_running", false)
                    
                    -- Handle Result
                    if isSelector then
                        if result == true then
                            frame.ForceResult = true
                            frame.Index = #children + 1 -- Selector Succeeded, Stop
                        else
                            frame.Index = frame.Index + 1 -- Selector Failed, Try Next
                        end
                    else -- Sequence
                        if result == true then
                            frame.Index = frame.Index + 1 -- Sequence Succeeded, Next
                        else
                            frame.ForceResult = false
                            frame.Index = #children + 1 -- Sequence Failed, Stop
                        end
                    end
                end
            else
                print("[SBAI] Missing Task: " .. taskName)
                frame.Index = frame.Index + 1
            end
        end

        ::continue_loop::
    end
    
    return false
end

function ENT:NPC_GetRunActivity( act ) 
	act = act or ACT_MP_WALK_MELEE 
	return act 
end 

function ENT:NPC_GetWalkActivity( act ) 
	act = act or ACT_MP_WALK_MELEE 
	return act 
end 

function ENT:NPC_TranslateActivity(act) 
	if act == ACT_IDLE_ANGRY then 
		if IsValid(self:GetActiveWeapon()) then 
			if self:GetActiveWeapon():GetClass() == "raven_blade" 
			or self:GetActiveWeapon():GetHoldType() == "melee" 
			or self:GetActiveWeapon():GetHoldType() == "knife" then 
				return ACT_HL2MP_IDLE_MELEE_ANGRY 
			end 
		end 
	end 
	if IsValid(self:GetActiveWeapon()) then 
		if self:GetActiveWeapon():GetHoldType() == "melee" or self:GetActiveWeapon():GetHoldType() == "knife" and act == ACT_WALK then 
			return ACT_MP_WALK_MELEE 
		end 
	end 
	return scripted_ents.Get("npc_unreali_female").NPC_TranslateActivity(self,act) 
end 

function ENT:NPC_TranslateLuaSchedule(oldsched) 
	local retVal = scripted_ents.Get("npc_unreali_female").NPC_TranslateLuaSchedule(self,oldsched) 
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
	if pos.z < -800 or pos.z > 800 then return false end 
	-- has raven melee weapon 
	if IsValid(self:GetActiveWeapon()) then 
		if self:GetActiveWeapon():GetClass() != "raven_blade" then return false end 
	else 
		return false 
	end 
	-- definitely not a CBaseCombatCharacter in a vehicle, or a CBaseHelicopter 
	if self:GetNPCState() == NPC_STATE_DEAD then return false end 
	if self:NPC_HasCondition(COND.ENEMY_OCCLUDED) then return false end 
	return true 
end 

ENT.ShotRegulator = { } 
-- auto update burst settings and rest times each time we attempt to conduct a shot 
function ENT.ShotRegulator:UpdateRestTimes() 
	local Outer = self.Outer 
	scripted_ents.Get("cycler_actor2").ShotRegulator.UpdateRestTimes(self) 
	Outer.ShotRegulator.flMinRestInterval = 0.1 
	Outer.ShotRegulator.flMaxRestInterval = 0.1  
end 

function ENT:NPC_ShouldBlockRunAI() -- whether to call lua schedules or not
	-- when blocked (true), it calls Lua schedules 
	-- when not blocked (false), it calls Engine schedules 
	if self.CurrentSchedule and self.CurrentSchedule.DebugName == "LUASCHED_RAVEN_RAPIDEVADE" then return true end 
	if self:NPC_ShouldConductBehaviorTree() then return true end 
	return scripted_ents.Get("npc_unreali_female").NPC_ShouldBlockRunAI(self) 
end 

function ENT:CustomRunAI() 
	-- self:SBAI_ProcessActiveSkill(self.SBAI_SkillStep) 
	local NPC_ShouldConductBehaviorTree = self:NPC_ShouldConductBehaviorTree() 
	if NPC_ShouldConductBehaviorTree then 
		return self:SBAI_RunBehavior(), self:NPC_MaintainActivity() 
	end 
	local retVal = scripted_ents.Get("npc_unreali_female").CustomRunAI(self) 
end 

function ENT:OnKilled(dmginfo) 
	local attacker = dmginfo:GetAttacker() 
	if self.AttackerEffectWhenDead then 
		local AttackerEffectWhenDead = StellarBlade.ParseTableStrings(self.AttackerEffectWhenDead) 
		StellarBlade.AddEffectFromTable(attacker,AttackerEffectWhenDead) 
	end 
	return scripted_ents.Get("npc_unreali_female").OnKilled(self,dmginfo) -- baseclass 
end 

function ENT:OnRemove(fullUpdate) 
	if self._sbaico and coroutine.status(self._sbaico) == "suspended" then
		self:SBAI_CheckObservers() 
		local ok, ret = coroutine.resume(self._sbaico)
	end 
	scripted_ents.Get("npc_unreali_female").OnRemove(self) 
end 

-- conditions 
function ENT:SbAggroLevel(tbl)
    local CompareAggroLevelArray = tbl.CompareAggroLevelArray
    if !CompareAggroLevelArray then return false end

    -- Defensive: ensure we can iterate
    if type(CompareAggroLevelArray) != "table" then
        CompareAggroLevelArray = { CompareAggroLevelArray }
    end

    for _, level in ipairs(CompareAggroLevelArray) do

        -- if level == "AIAggroLevel_Peaceful" and self:GetNPCState() < 2 then
        if level == "AIAggroLevel_Peaceful" then
            return true
        elseif level == "AIAggroLevel_Battle" and self:GetNPCState() == NPC_STATE_COMBAT then
            return true
        end
        -- add more elseif branches here if you support other aggro levels
    end

    return false
end

function ENT:SbAimMe(tbl) -- doesn't have any additional properties 
	return self:NPC_HasCondition(COND.ENEMY_FACING) and self:NPC_IsEnemyAttacking(self:GetEnemy()) 
end 

function ENT:SbBlackboard(tbl) 
	-- PrintTable(tbl) 
	-- 1. Default IntValue should be 0 
    local testvalue = tbl.IntValue or 0 
    local CompareOP = tbl.CompareOP or "ESBCompare::Equal" 
    
    -- 2. Retrieve value, treating nil as 0 (for integer checks)
    local lookup = self.SBAI_BlackBoard[tbl.KeyName]
    local val = lookup 
    if val == nil then val = 0 end -- Treat uninitialized keys as 0
    
    -- If we are in "Task" mode (writing), this field bReturnSucceeded exists
    if tbl.bReturnSucceeded != nil then 
        -- Task: Write to Blackboard 
        -- print("[SBAI] Writing BB:", tbl.KeyName, tbl.IntValue) 
		Entity(1):ChatPrint("saving to SBAI_BlackBoard: "..tbl.KeyName..tostring(tbl.IntValue).." ") 
        self.SBAI_BlackBoard[tbl.KeyName] = tbl.IntValue 
        return tbl.bReturnSucceeded 
    end 
    
    -- Decorator: Compare
    -- print("Checking BB:", tbl.KeyName, "Val:", val, "Op:", CompareOP, "Target:", testvalue) 
    return StellarBlade.ESBCompare(val,testvalue,CompareOP) 
end 

function ENT:SbCheckActorEffect(tbl) 
	-- PrintTable(tbl) 
    local ActorType          = tbl.ActorType or "ESBAIActorType::Self" 
    local EffectAlias        = tbl.EffectAlias 
    local OrCheckArray       = tbl.OrCheck_EffectAliasArray or {} 
    local bActive            = tbl.bActive or true 
    local bInverseCondition  = tbl.bInverseCondition or false 

    -- if decorator disabled, always allow
    if bActive == false then return false end

    -- resolve actor
    local ent = self 
    if ActorType == "ESBAIActorType::Target" then
        ent = self:GetEnemy()
    elseif ActorType == "ESBAIActorType::Self" then
        ent = self
    elseif ActorType == "ESBAIActorType::Owner" then
        ent = self:GetOwner()
    elseif ActorType == "ESBAIActorType::SubTarget" then
        for _, subent in pairs(self:GetKnownEnemies() or {}) do
            if IsValid(subent) and subent != self:GetEnemy() then
                ent = subent
                break
            end
        end
    end
    if !IsValid(ent) then return bInverseCondition end 
	-- debug 
	-- if math.random() > 0.5 then return true else return false end 

    -- gather effects to check
    local effectsToCheck = {}
    if EffectAlias then
        table.insert(effectsToCheck, EffectAlias)
    end
	
    for _, v in ipairs(OrCheckArray) do
        table.insert(effectsToCheck, v)
    end

    -- check actor effects
    local hasEffect = false
    for _, Effect in ipairs(effectsToCheck) do
        -- normal alias checks
        if ent.SB_EffectAlias and ent.SB_EffectAlias[Effect] then 
			if !table.IsEmpty(ent.SB_EffectAlias[Effect]) then 
			-- for EffectIndex, EffectTable in ipairs(ent.SB_EffectAlias[Effect]) do 
				hasEffect = true
			end 
        end

        -- post check wrapper: if ENT has a function named after the effect alias, call it 
        local fn = self[Effect]
        if type(fn) == "function" then
            local ok, override = pcall(fn, self, ent)
            if ok and override != nil then
                hasEffect = override and true or false
            end
        end

        if hasEffect then break end
    end

    -- apply inverse flag
    if bInverseCondition then
        return !hasEffect
    else
        return hasEffect
    end
end

function ENT:SbCheckActorStat(tbl) 
	-- PrintTable(tbl) 
	local CheckStat = tbl.CheckStat -- ActorStatType_AttackSpeed       ActorStatType_StaminaAttackPower        ActorStatType_CriticalPercentage        ActorStatType_HitDefenseLevel   ActorStatType_ShieldIgnorePercentage    ActorStatType_CriticalValueRate ActorStatType_ShieldRegenPerSecond      ActorStatType_AdditiveSkillDamageRate   ActorStatType_ShieldRegenPerSecondRate  ActorStatType_ShieldRegenPerSecondValue ActorStatType_ShieldRegenPerSecondWhenBattleValue       ActorStatType_ShieldRegenPerSecondWhenBattle    ActorStatType_StaminaRegenPerSecond     ActorStatType_ShieldRegenPerSecondWhenBattleRate        ActorStatType_HPRegenPerSecondValue     ActorStatType_HPRegenPerSecond  ActorStatType_SmallWeightTypeDamageAdditiveRate ActorStatType_HPRegenPerSecondRate      ActorStatType_RangeAttackDamageAdditiveRate     ActorStatType_LargeWeightTypeDamageAdditiveRate ActorStatType_RangeAttackDamageReductionRate    ActorStatType_MeleeAttackDamageReductionRate    ActorStatType_GroggyStateDamageAdditiveRate     ActorStatType_DownStateDamageAdditiveRate       ActorStatType_FireAttributeDamageReductionRate  ActorStatType_AirborneStateDamageAdditiveRate   ActorStatType_LightningAttributeDamageReductionRate     ActorStatType_IceAttributeDamageReductionRate   ActorStatType_BetaGaugeAdditiveRate     ActorStatType_PoisonAttributeDamageReductionRate        ActorStatType_LowHpDamageAdditiveRate   ActorStatType_AdditiveFixedDamage       ActorStatType_DOTDamageAdditiveRate     ActorStatType_HighHpDamageAdditiveRate  ActorStatType_TachyGaugeReduceConsumeRate       ActorStatType_TachyGaugeAdditiveGainRate        ActorStatType_FinalShieldDamageReduceRate       ActorStatType_FinalHPDamageReduceRate   ActorStatType_AdditiveSkillDamageGroup1 ActorStatType_Luck      ActorStatType_AdditiveSkillDamageGroup3 ActorStatType_AdditiveSkillDamageGroup2 ActorStatType_AdditiveSkillDamageGroup5 ActorStatType_AdditiveSkillDamageGroup4 ActorStatType_AdditiveSkillDamageGroup7 ActorStatType_AdditiveSkillDamageGroup6 ActorStatType_AdditiveSkillDamageGroup9 ActorStatType_AdditiveSkillDamageGroup8 ActorStatType_DrainHpByAttackPowerRate  ActorStatType_AdditiveSkillDamageGroup10        ActorStatType_SprintableStaminaValue    ActorStatType_DrainHpFixedValue ActorStatType_ItemStackBullet1  ActorStatType_ItemStackRecoveryPotion   ActorStatType_ItemStackBullet3  ActorStatType_ItemStackBullet2  ActorStatType_ItemStackBullet5  ActorStatType_ItemStackBullet4  ActorStatType_ItemStackConsumable1      ActorStatType_ItemStackBullet6  ActorStatType_ItemStackConsumable3      ActorStatType_ItemStackConsumable2      ActorStatType_ItemStackConsumable5      ActorStatType_ItemStackConsumable4      
	local CheckValue = tbl.CheckValue -- 60.0, 
	local CompareOP = tbl.CompareOP or "ESBCompare::Equal" -- Greater 
	local bRateValue = tbl.bRateValue or false -- true 
	local NodeName = tbl.NodeName -- SB_CheckActorStat(HP>60) 
	-- handle only ActorStatType_HP for now, Raven only looks for this 
	local testvalue, result 
	if CheckStat == "ESBActorStatType::ActorStatType_HP" then 
		testvalue = self:Health() 
		testvalue = (testvalue / self:GetMaxHealth()) * 100 
	else 
		testvalue = 0 
	end 
	-- Entity(1):ChatPrint("CheckStat: "..CheckStat.." CheckValue: "..tostring(CheckValue).. "..CompareOP:"..CompareOP.." "..tostring(result)) 
	-- print("ActorStat check", CheckStat, testvalue, CompareOP, CheckValue, "=>", result) 
	return StellarBlade.ESBCompare(testvalue,CheckValue,CompareOP) 
end 

function ENT:SbCheckStance(tbl) -- M_Raven_Phase2, M_Raven_Default 
	return true -- stance switcing doesn't exist yet, default to true 
	-- if true then 
		-- return "M_Raven_Default" == tbl.StanceName 
	-- end 
	-- return self.StanceName == tbl.StanceName 
end 

function ENT:SbDetectResult(tbl) 
	-- ESBAIDetectResultType::AIDetectResult_NotDetect ESBAIDetectResultType::AIDetectResult_Observe AIDetectResult_Doubt	AIDetectResult_Detect 
	local CompareDetectResult = tbl.CompareDetectResult -- e.g., "AIDetectResult_Detect"
    local hasEnemy = IsValid(self:GetEnemy()) 

    if CompareDetectResult == "ESBAIDetectResultType::AIDetectResult_Detect" then 
        return hasEnemy 
    elseif CompareDetectResult == "ESBAIDetectResultType::AIDetectResult_NotDetect" then 
        return !hasEnemy 
    end 

    -- Default fallback 
    return hasEnemy 
end 

function ENT:SbDistanceToTarget(tbl) -- distance to enemy 
	if !self.enemyDist then return false end 
	local dist = tbl.Distance 
	local operator = tbl.CompareOP -- LessOrEqual, Greater, GreaterOrEqual, Equal, Less, NotEqual 
	local FlowAbortMode = tbl.FlowAbortMode or "None" 
	-- print("DistanceToTarget:",dist,operator,FlowAbortMode) 
	return StellarBlade.ESBCompare(self.enemyDist,dist,operator) 
end 

function ENT:SbIsAlive(tbl) 
	-- PrintTable(tbl) 
	local ActorType = tbl.ActorType or "ESBAIActorType::Target" -- Target, Self, SubTarget, Owner. Default: Self 
	local CheckType = tbl.CheckType or "ESBBTDecoratorAliveCheckType::Alive" -- Coma, Dead, Alive. Default: Alive 
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

function ENT:SbRandom(tbl) 
	local RandomRange = math.random(0,tbl.RandomRange) 
	local CheckValue = tbl.CheckValue 
	local CompareOP = tbl.CompareOP or "ESBCompare::Equal" -- LessOrEqual, Greater, GreaterOrEqual, Equal, Less, NotEqual 
	return StellarBlade.ESBCompare(RandomRange,CheckValue,CompareOP) 
end 

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

-- SbCautionToTarget: property-driven adaptation (no spawn hacks)
function ENT:SbCautionToTarget(tbl, nodeID) 
    -- small helpers
    local function SafeGet(key, def) return (tbl[key] ~= nil) and tbl[key] or def end
    local function randFloat(a,b) return a + math.random() * (b - a) end
    local function isValidEnt(e) return e ~= nil and e ~= NULL and IsValid(e) end

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
		print("chosen",chosen) 
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
            local minPathLen = math.Clamp(tbl.sideDist * 0.5, 100, 2000)
            self:NavSetRandomGoal(minPathLen, (tgtPos - myPos):GetNormalized()) 
        else
			self:NavSetGoalPos(goalPos) 
		end 
		self:SBAI_SetNodeState(nodeID,"navSet",true) 
		self:SetMovementActivity(ACT_MP_WALK_MELEE) 
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
		self:SBAI_SetNodeState(nodeID, "waitEnd",CurTime() + (self:SBAI_GetNodeState(nodeID, "waitEnd" or 0)))
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


function ENT:SbDetectTarget(tbl) 
	local bEnemy, bComa = tbl.bEnemy, tbl.bComa 
	local EffectAliasArray = tbl.EffectAliasArray 
	-- right now just return true instead of searching for enemy 
	-- print("in sbdetecttarget. this will directly return true") 
	
	-- "EffectAliasArray": [
        -- "Check_AttackTachyNPC",
        -- "Check_Detect"
      -- ],
	
	return !IsValid(self:GetEnemy()) 
end 

function ENT:SbMoveToTarget(tbl) 
	print("in SbMoveToTarget") 
	local MoveState = tbl.MoveState
	local DistanceOfApproach = tbl.DistanceOfApproach or 250 -- i think this means walk until distancetoenemy < 250 
	local enemyDist = self.enemyDist or 9999 
	if enemyDist < DistanceOfApproach then 
		return true 
	else 
		local bBackgroundTask = tbl.bBackgroundTask 
		local NodeName = tbl.NodeName 
		local navSet = self:IsGoalActive() 
		if !navSet then 
			if IsValid(self:GetEnemy()) then 
				navSet = self:NavSetGoalTarget(self:GetEnemy()) 
			else 
				navSet = self:NavSetGoalPos(self:GetPos() + (self:GetForward()*300)) 
			end 
		end 
		self:SetMovementActivity(ACT_MP_WALK_MELEE) 
		if !navSet then return false end 
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
			StellarBlade.AddEffect(target,EffectTable) 
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

function ENT:SbUseSkill(tbl, nodeID) 
    -- This function is now simplified, as setup logic has moved to SetSkillStep. 
	-- PrintTable(tbl) 
	local Started = self:SBAI_GetNodeState(nodeID, "hasStarted") 
	-- print("Started:",nodeID,Started) 
    if !Started then 
        for k, v in RandomPairs(tbl.SkillName) do 
            if isnumber(k) then -- do not accidentally start variables 
				if bUseSkillCommand then 
					if StellarBlade.StartSkillCommand(self,v) then 
						self:SBAI_SetNodeState(nodeID, "hasStarted", true) 
						break 
					end  
					-- return true 
				else 
					if StellarBlade.StartSkill(self,v) then 
						self:SBAI_SetNodeState(nodeID, "hasStarted", true) 
						break 
					end 
					-- return true 
				end 
			end 
		end 
	end 
	local Started = self:SBAI_GetNodeState(nodeID, "hasStarted") 

    if Started then 
        -- If the active skill was cleared (e.g., skill finished or target died), the task is complete 
        if !self.SBAI_SkillStep or self.SBAI_SkillStep and !self.SBAI_SkillStep:IsActive() then 
             -- Entity(1):ChatPrint("task complete") 
             self:NPC_StopScriptedActivity() 
			 self:ResetIdealActivity(ACT_IDLE) 
			 -- self.SBAI_SkillTable = nil 
			 self:SBAI_SetNodeState(nodeID, "hasStarted", false ) 
             return true 
        else 
			return nil -- Task is still running 
		end 
    else 
		if !self.SBAI_SkillTable then 
			self:SBAI_SetNodeState(nodeID, "hasStarted", false ) 
			return false 
		end 
		return nil -- not started, maybe all tasks are in delay? 
	end 
	
	self:SBAI_SetNodeState(nodeID, "hasStarted", false ) 
    return false -- no task selected  
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

    -- Use Runtime Registry instead of writing to JSON 'data'
    local startTime = self:SBAI_GetNodeState(nodeID, "startTime") 
    
    if !startTime then
        startTime = CurTime()
        self:SBAI_SetNodeState(nodeID, "startTime", startTime)
    end

    local elapsed = CurTime() - startTime
    print("in SbWait", elapsed, WaitTime)

    if elapsed < WaitTime then
        return nil -- still running
    else
        if returnSucceeded then
            return true  -- wait succeeded
        else
            return false -- wait failed
        end
    end
end 

function ENT:SbMetaAI(data) end -- base AI 
function ENT:SbMoveToHome(data) 
	local bUseSpawnPath = data.bUseSpawnPath 
	local bDetectTarget = data.bDetectTarget 
	local DetectTargetDelayTime = data.DetectTargetDelayTime 
	local bEnemy = data.bEnemy 
end 

function ENT:SB_LookAtTarget(data) end 
function ENT:SbWaitTimeRandom(data, nodeID) -- only in tachy ai 
	local MinTime = data.MinTime 
	local MaxTime = data.MaxTime 
	local bReturnSucceeded = data.bReturnSucceeded 
	if !self:SBAI_GetNodeState(nodeID, "SbWaitTimeRandom") then 
		return CurTime() > self:SBAI_GetNodeState(nodeID, "SbWaitTimeRandom") and true or nil 
	else 
		self:SBAI_SetNodeState(nodeID, "SbWaitTimeRandom",math.Rand(MinTime,MaxTime))
	end 
end 

-- function ENT:Item_Resurrection_Ground(ent) return false end 
-- function ENT:M_Raven_BetaCounterGrab_HitE(ent) return false end 
-- function ENT:LV_FinishQTE_FailDown(ent) return false end 
function ENT:P_Eve_Beta_SwordAura(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:P_Eve_Beta_SwordAura2(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:P_Eve_Beta_SwordAura3(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:M_Common_HitProjectileResult(ent) return self:NPC_IsNPCAttacking(ent) end 

function ENT:ON_LIGHT_DAMAGE() 
	-- get current skill step if available and see whether NextStepAliasWhenAttacked is set 
	local SkillStepTable = self.SBAI_SkillStep 
	if !SkillStepTable then return scripted_ents.Get("npc_unreali_female").ON_LIGHT_DAMAGE(self) end 
	if !SkillStepTable.Name then return scripted_ents.Get("npc_unreali_female").ON_LIGHT_DAMAGE(self) end 
	SkillStepTable = SB_SkillActiveStepTable[1].Rows[SkillStepTable] 
	if !SkillStepTable then return scripted_ents.Get("npc_unreali_female").ON_LIGHT_DAMAGE(self) end 
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
	return scripted_ents.Get("npc_unreali_female").ON_LIGHT_DAMAGE(self) 
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
		self:SetNoDraw(true)
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
        if self.SetNoDraw then
            self:SetNoDraw(false)
        else
            pcall(function() self:RemoveEffects(EF_NODRAW) end)
        end
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
        if self.SetNoDraw then self:SetNoDraw(false) end 
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

function ENT:Draw(flags) 
	scripted_ents.Get("npc_unreali_female").Draw(self,flags) 
	local attachment = { ["FX_Core_01"] = 8, ["FX_Core_02"] = 4, ["FX_Core_03"] = 2, ["FX_Core_04"] = 2} 
	for attachmentname, scale in pairs(attachment) do 
		local attachmentid = self:LookupAttachment(attachmentname) 
		if attachmentid > 0 then 
			local Pos = self:GetAttachment(attachmentid).Pos -- Pos will be used 
			render.SetMaterial(t_a_shineflare_02) 
			for i = 1,math.random(1,3) do 
				render.DrawSprite(Pos,scale,scale,Color(0,255,255)) 
			end 
		end 
	end 
end 