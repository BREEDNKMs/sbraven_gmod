-- Requires rxi/json.lua (https://github.com/rxi/json.lua)
local json = require "json" 

local filedir = "E:/Stellar Blade/Output/Exports/SB/Content/GameDesign/Combat/BehaviorTree/Monster/M_Raven_AI.json"

-- load JSON file into Lua table
local function load_json(path)
  local f = assert(io.open(path, "r"))
  local content = f:read("*a")
  f:close()
  return json.decode(content)
end

local function normalize_name(name)
  -- strip Unreal-style prefixes, keep only last identifier
  -- Example: "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_38'"
  -- Result: "BTComposite_Selector_38"
  local cleaned = name:match(":(.-)'?$")
  return cleaned or name
end

-- recursive function to parse BehaviorTree node
local function parse_node(node_map, node_name) -- todo: add normalize_name(str) to references to other actors 
  local key = normalize_name(node_name)
  local node = node_map[key]
  if not node then return nil end

  local result = {}

  if node.Properties and node.Properties.Children then
    for _, child in ipairs(node.Properties.Children) do
      local entry = {}

      -- Decorators → Condition
      if child.Decorators then
        entry.Condition = {}
        for _, deco in ipairs(child.Decorators) do
          local decoName = normalize_name(deco.ObjectName)
          entry.Condition[decoName] = {}

          local decoNode = node_map[decoName]
          if decoNode and decoNode.Properties then
            -- special handling: Distance decorator
            if decoName:match("^SBBTDecorator_SbDistanceToTarget_%d+$") then
              entry.Condition[decoName].Distance     = decoNode.Properties.Distance
              entry.Condition[decoName].CompareOP   = decoNode.Properties.CompareOP
              entry.Condition[decoName].FlowAbortMode = decoNode.Properties.FlowAbortMode
            elseif decoName:match("^SBBTDecorator_SbAggroLevel_%d+$") then
				entry.Condition[decoName].FlowAbortMode = decoNode.Properties.FlowAbortMode
            elseif decoName:match("^SBBTDecorator_SbAimMe_%d+$") then -- is the enemy facing us 
				-- SbAimMe has no properties 
			elseif decoName:match("^SBBTDecorator_SbBlackboard_%d+$") then -- special operator i guess 
				entry.Condition[decoName].CompareOP = decoNode.Properties.CompareOP -- comparison to process 
				entry.Condition[decoName].KeyName = decoNode.Properties.KeyName
				entry.Condition[decoName].IntValue = decoNode.Properties.IntValue
			elseif decoName:match("^SBBTDecorator_SbCheckActorEffect_%d+$") then -- check for actor states, either on self or target 
				entry.Condition[decoName].ActorType = decoNode.Properties.ActorType 
				entry.Condition[decoName].EffectAlias = decoNode.Properties.EffectAlias 
				entry.Condition[decoName].OrCheck_EffectAliasArray = decoNode.Properties.OrCheck_EffectAliasArray -- table of effects 
				entry.Condition[decoName].FlowAbortMode = decoNode.Properties.FlowAbortMode 
				entry.Condition[decoName].bActive = decoNode.Properties.bActive 
				entry.Condition[decoName].bInverseCondition = decoNode.Properties.bInverseCondition 
			elseif decoName:match("^SBBTDecorator_SbCheckStance_%d+$") then -- check for self status. i.e. raven normal or raven phase 2 
				entry.Condition[decoName].StanceName = decoNode.Properties.StanceName -- M_Raven_Default 
			elseif decoName:match("^SBBTDecorator_SbDetectResult_%d+$") then -- idk, there is only one example 
				entry.Condition[decoName].CompareDetectResult = normalize_name(decoNode.Properties.CompareDetectResult) -- AIDetectResult_Detect 
			elseif decoName:match("^SBBTDecorator_SbIsAlive_%d+$") then -- idk, there is only one example 
				entry.Condition[decoName].ActorType = decoNode.Properties.ActorType 
				entry.Condition[decoName].CheckType = decoNode.Properties.CheckType 
				entry.Condition[decoName].FlowAbortMode = decoNode.Properties.FlowAbortMode 
			elseif decoName:match("^SBBTDecorator_SbIsAlive_%d+$") then -- either self or enemy is alive  
				entry.Condition[decoName].CheckValue = decoNode.Properties.CheckValue 
				entry.Condition[decoName].CompareOP = decoNode.Properties.CompareOP 
				entry.Condition[decoName].RandomRange = decoNode.Properties.RandomRange 
			else 
				entry.Condition[decoName].UNHANDLED = true 
			end 
          end
        end
      end

      -- ChildTask → StartTask
      if child.ChildTask then
        local taskName = normalize_name(child.ChildTask.ObjectName)
		local taskNode = node_map[taskName] 
        entry.StartTask = {} 

        -- handle SbUseSkill
        if taskName:match("^SBBTTask_SbUseSkill_%d+$") then
          local skillTable = {}
          if taskNode and taskNode.Properties and taskNode.Properties.SkillName then
            for _, skill in ipairs(taskNode.Properties.SkillName) do
              table.insert(skillTable, skill)
            end
          end
          entry.StartTask[taskName] = skillTable
		  entry.StartTask[taskName].SkillComboType = taskNode.Properties.SkillComboType 
		  entry.StartTask[taskName].bUseSkillCommand = taskNode.Properties.bUseSkillCommand 
		  entry.StartTask[taskName].bUsePostStep = taskNode.Properties.bUsePostStep 

        -- handle SbWait
        elseif taskName:match("^SBBTTask_SbWait_%d+$") then
          local waitData = {}
          if taskNode and taskNode.Properties then
            waitData.WaitTime = taskNode.Properties.WaitTime
            waitData.bReturnSucceeded = taskNode.Properties.bReturnSucceeded or false 
          end
          entry.StartTask[taskName] = waitData
		elseif taskName:match("^SBBTTask_SbDetectTarget_%d+$") then
			if taskNode and taskNode.Properties then
				if not entry.StartTask[taskName] then entry.StartTask[taskName] = { } end 
				entry.StartTask[taskName].bEnemy = taskNode.Properties.bEnemy or false 
				entry.StartTask[taskName].bComa = taskNode.Properties.bComa or false 
			end 
		
		elseif taskName:match("^SBBTTask_SbCautionToTarget_%d+$") then
			if taskNode and taskNode.Properties then
				if not entry.StartTask[taskName] then entry.StartTask[taskName] = { } end 
				entry.StartTask[taskName].SetMoveType = taskNode.Properties.SetMoveType 
				entry.StartTask[taskName].MaxDistance = taskNode.Properties.MaxDistance 
				entry.StartTask[taskName].bLockOn = taskNode.Properties.bLockOn 
				entry.StartTask[taskName].WaitCheckTime = taskNode.Properties.WaitCheckTime 
				entry.StartTask[taskName].WaitCountByGroup = taskNode.Properties.WaitCountByGroup 
				entry.StartTask[taskName].SideMoveMinDistance = taskNode.Properties.SideMoveMinDistance 
				entry.StartTask[taskName].SideMoveMaxDistance = taskNode.Properties.SideMoveMaxDistance 
				entry.StartTask[taskName].bIgnoreRestartSelf = taskNode.Properties.bIgnoreRestartSelf 
			end 
			
		elseif taskName:match("^SBBTTask_SbMoveToTarget_%d+$") then
			if taskNode and taskNode.Properties then
				if not entry.StartTask[taskName] then entry.StartTask[taskName] = { } end 
				entry.StartTask[taskName].MoveState = taskNode.Properties.MoveState 
				entry.StartTask[taskName].DistanceOfApproach = taskNode.Properties.DistanceOfApproach 
				entry.StartTask[taskName].bBackgroundTask = taskNode.Properties.bBackgroundTask 
				entry.StartTask[taskName].NodeName = taskNode.Properties.NodeName 
			end 
			
		elseif taskName:match("^SBBTTask_SbUseableTimeReset_%d+$") then
			if taskNode and taskNode.Properties then
				if not entry.StartTask[taskName] then entry.StartTask[taskName] = { } end 
				entry.StartTask[taskName].KeyName = taskNode.Properties.KeyName 
				entry.StartTask[taskName].SetInitialTimeValue = taskNode.Properties.SetInitialTimeValue 
				entry.StartTask[taskName].SetCycleTimeValue = taskNode.Properties.SetCycleTimeValue 
				entry.StartTask[taskName].NodeName = taskNode.Properties.NodeName 
			end 
			
		elseif taskName:match("^SBBTTask_SbUseEffect_%d+$") then
			if taskNode and taskNode.Properties then
				if not entry.StartTask[taskName] then entry.StartTask[taskName] = { } end 
				entry.StartTask[taskName].bSelfActor = taskNode.Properties.bSelfActor 
				entry.StartTask[taskName].EffectAlias = taskNode.Properties.EffectAlias 
			end 
		
        else
          -- other tasks (placeholder)
          entry.StartTask[taskName] = {"UNHANDLED"} 
        end
      end

      -- ChildComposite → NextTask (and recurse)
      if child.ChildComposite then
        entry.NextTask = parse_node(node_map, child.ChildComposite.ObjectName)
      end

      table.insert(result, entry)
    end
  end

  return result
end

-- build a lookup table of nodes by short name
local function build_node_map(json_data)
  local map = {}
  for _, entry in ipairs(json_data) do
    map[entry.Name] = entry
  end
  return map
end

-- main
local function build_behavior_tree(path)
  local f = assert(io.open(path, "r"))
  local content = f:read("*a")
  f:close()
  local data = json.decode(content)

  local node_map = build_node_map(data)

  -- find RootNode
  local root = nil
  for _, entry in ipairs(data) do
    if entry.Type == "BehaviorTree" then
      root = entry.Properties.RootNode.ObjectName
      break
    end
  end

  if not root then
    error("RootNode not found in JSON")
  end

  return parse_node(node_map, root)
end

-- Example usage
local tree = build_behavior_tree(filedir)
ENT = {}
ENT.SBAI_BehaviorTree = tree

-- debug print
-- for k,v in pairs(tree) do print(k,v) end 
local serpent = require "serpent" -- optional pretty printer
print(serpent.block(ENT.SBAI_BehaviorTree, {comment=false}))