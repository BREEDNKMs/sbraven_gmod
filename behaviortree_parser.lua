-- Requires rxi/json.lua (https://github.com/rxi/json.lua)
local json = require "json" 

local filedir = "E:/Stellar Blade/Output/Exports/SB/Content/GameDesign/Combat/BehaviorTree/Monster/M_Raven_AI.json"

-- load JSON file into Lua table
local function load_json(path)
  local f = assert(io.open(path, "r")) -- windir.open crashes 
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
                        if decoNode.Properties.FlowAbortMode then
                            entry.Condition[decoName].FlowAbortMode = string.sub(normalize_name(decoNode.Properties.FlowAbortMode), 2) -- FlowAbortMode
                        end
                        -- special handling: Distance decorator
                        if decoName:match("^SBBTDecorator_SbDistanceToTarget_%d+$") then
                            entry.Condition[decoName].Distance = decoNode.Properties.Distance -- 1400
                            if decoNode.Properties.CompareOP then
                                entry.Condition[decoName].CompareOP = string.sub(normalize_name(decoNode.Properties.CompareOP), 2) -- LessOrEqual
                            end

                        elseif decoName:match("^SBBTDecorator_SbAggroLevel_%d+$") then
                            entry.Condition[decoName].CompareAggroLevelArray = decoNode.Properties.CompareAggroLevelArray -- "AIAggroLevel_Peaceful"
                        elseif decoName:match("^SBBTDecorator_SbAimMe_%d+$") then -- is the enemy facing us
                            -- SbAimMe has no properties
                        elseif decoName:match("^SBBTDecorator_SbBlackboard_%d+$") then -- special operator i guess
                            if decoNode.Properties.CompareOP then
                                entry.Condition[decoName].CompareOP = string.sub(normalize_name(decoNode.Properties.CompareOP), 2) -- LessOrEqual
                            else
                                entry.Condition[decoName].CompareOP = "Equal"
                            end
                            entry.Condition[decoName].KeyName = decoNode.Properties.KeyName -- BBT2, SwordBuffFX
                            entry.Condition[decoName].IntValue = decoNode.Properties.IntValue -- 1
                        elseif decoName:match("^SBBTDecorator_SbCheckActorEffect_%d+$") then -- check for actor states, either on self or target
                            if decoNode.Properties.ActorType then
                                entry.Condition[decoName].ActorType = string.sub(normalize_name(decoNode.Properties.ActorType), 2) -- Target
                            else
                                entry.Condition[decoName].ActorType = "Target"
                            end
                            entry.Condition[decoName].EffectAlias = decoNode.Properties.EffectAlias -- M_Raven_ComboCheck
                            entry.Condition[decoName].OrCheck_EffectAliasArray = decoNode.Properties.OrCheck_EffectAliasArray -- table of effects
                            entry.Condition[decoName].bActive = decoNode.Properties.bActive or false
                            entry.Condition[decoName].bInverseCondition = decoNode.Properties.bInverseCondition or false
                        elseif decoName:match("^SBBTDecorator_SbCheckStance_%d+$") then -- check for self status. i.e. raven normal or raven phase 2
                            entry.Condition[decoName].StanceName = decoNode.Properties.StanceName -- M_Raven_Default
                        elseif decoName:match("^SBBTDecorator_SbCheckActorStat_%d+$") then -- check for self status, generally self health
                            entry.Condition[decoName].CheckStat = string.sub(normalize_name(decoNode.Properties.CheckStat), 2) -- ActorStatType_HP
                            entry.Condition[decoName].CheckValue = decoNode.Properties.CheckValue -- 60.0,
                            if decoNode.Properties.CompareOP then
                                entry.Condition[decoName].CompareOP = string.sub(normalize_name(decoNode.Properties.CompareOP), 2) -- LessOrEqual
                            else
                                entry.Condition[decoName].CompareOP = "Equal"
                            end
                            entry.Condition[decoName].bRateValue = decoNode.Properties.bRateValue or false -- true
                            entry.Condition[decoName].NodeName = decoNode.Properties.NodeName -- SB_CheckActorStat(HP>60)
                        elseif decoName:match("^SBBTDecorator_SbDetectResult_%d+$") then -- idk, there is only one example
                            entry.Condition[decoName].CompareDetectResult = string.sub(normalize_name(decoNode.Properties.CompareDetectResult), 2) -- AIDetectResult_Detect
                        elseif decoName:match("^SBBTDecorator_SbIsAlive_%d+$") then -- enemy or us
                            if decoNode.Properties.ActorType then
                                entry.Condition[decoName].ActorType = string.sub(normalize_name(decoNode.Properties.ActorType), 2) -- Target
                            else
                                entry.Condition[decoName].ActorType = "Target"
                            end
                            if decoNode.Properties.CheckType then
                                entry.Condition[decoName].CheckType = string.sub(normalize_name(decoNode.Properties.CheckType), 2) -- Alive, Coma, Dead
                            else
                                entry.Condition[decoName].CheckType = "Alive"
                            end
                        elseif decoName:match("^SBBTDecorator_SbTimeLimit_%d+$") then -- either self or enemy is alive
                            entry.Condition[decoName].TimerName = decoNode.Properties.TimerName -- CautionTimer2
                            entry.Condition[decoName].LimitTime = decoNode.Properties.LimitTime -- 1.8
                            entry.Condition[decoName].ReactInterval = decoNode.Properties.ReactInterval -- 55.0
                        elseif decoName:match("^SBBTDecorator_SbUseableTime_%d+$") then -- either self or enemy is alive
                            entry.Condition[decoName].KeyName = decoNode.Properties.KeyName -- Timer_NoGuard
                        elseif decoName:match("^SBBTDecorator_SbRandom_%d+$") then -- either self or enemy is alive
                            entry.Condition[decoName].RandomRange = decoNode.Properties.RandomRange -- 100
                            entry.Condition[decoName].CheckValue = decoNode.Properties.CheckValue -- 50
                            if decoNode.Properties.CompareOP then
                                entry.Condition[decoName].CompareOP = string.sub(normalize_name(decoNode.Properties.CompareOP), 2) -- LessOrEqual
                            else
                                entry.Condition[decoName].CompareOP = "Equal"
                            end
                        else
                            entry.Condition[decoName].UNHANDLED = true -- if you get this in output, update your parser to handle decoName
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
                        if not entry.StartTask[taskName] then entry.StartTask[taskName] = {} end
                        entry.StartTask[taskName].bEnemy = taskNode.Properties.bEnemy or false
                        entry.StartTask[taskName].bComa = taskNode.Properties.bComa or false
                    end

                elseif taskName:match("^SBBTTask_SbCautionToTarget_%d+$") then
                    if taskNode and taskNode.Properties then
                        if not entry.StartTask[taskName] then entry.StartTask[taskName] = {} end
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
                        if not entry.StartTask[taskName] then entry.StartTask[taskName] = {} end
                        entry.StartTask[taskName].MoveState = taskNode.Properties.MoveState
                        entry.StartTask[taskName].DistanceOfApproach = taskNode.Properties.DistanceOfApproach
                        entry.StartTask[taskName].bBackgroundTask = taskNode.Properties.bBackgroundTask
                        entry.StartTask[taskName].NodeName = taskNode.Properties.NodeName
                    end

                elseif taskName:match("^SBBTTask_SbUseableTimeReset_%d+$") then
                    if taskNode and taskNode.Properties then
                        if not entry.StartTask[taskName] then entry.StartTask[taskName] = {} end
                        entry.StartTask[taskName].KeyName = taskNode.Properties.KeyName
                        entry.StartTask[taskName].SetInitialTimeValue = taskNode.Properties.SetInitialTimeValue
                        entry.StartTask[taskName].SetCycleTimeValue = taskNode.Properties.SetCycleTimeValue
                        entry.StartTask[taskName].NodeName = taskNode.Properties.NodeName
                    end

                elseif taskName:match("^SBBTTask_SbUseEffect_%d+$") then
                    if taskNode and taskNode.Properties then
                        if not entry.StartTask[taskName] then entry.StartTask[taskName] = {} end
                        entry.StartTask[taskName].bSelfActor = taskNode.Properties.bSelfActor
                        entry.StartTask[taskName].EffectAlias = taskNode.Properties.EffectAlias
                    end

                elseif taskName:match("^SBBTTask_SbBlackboard_%d+$") then
                    if taskNode and taskNode.Properties then
                        if not entry.StartTask[taskName] then entry.StartTask[taskName] = {} end
                        entry.StartTask[taskName].bReturnSucceeded = taskNode.Properties.bReturnSucceeded -- true
                        entry.StartTask[taskName].KeyName = taskNode.Properties.KeyName -- SwordBuffFX,BB2
                        entry.StartTask[taskName].IntValue = taskNode.Properties.IntValue -- 1
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

            -- MODIFICATION: Instead of a numeric index, use the child node's type as the key in a wrapper table.
            local child_object_name
            if child.ChildComposite then
                child_object_name = child.ChildComposite.ObjectName
            elseif child.ChildTask then
                child_object_name = child.ChildTask.ObjectName
            end

            if child_object_name then
                -- Extract the base type from the name (e.g., "BTComposite_Selector_1" -> "BTComposite_Selector")
                -- local child_base_type = string.match(normalize_name(child_object_name), "^(.+)_%d+$") or normalize_name(child_object_name) -- do not do this 
                local child_base_type = child_object_name 

                -- Create a new table where the key is the child's type
                -- local wrapped_entry = { [child_base_type] = entry } -- do not do this 
				-- result[child_object_name] = entry 
                -- table.insert(result, wrapped_entry)
				entry.ObjectName = child_object_name 
                table.insert(result, entry)
            else
                -- Fallback for any edge cases where a child might not have a composite or task object
				-- result[child_object_name] = entry 
                table.insert(result, entry)
            end
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
