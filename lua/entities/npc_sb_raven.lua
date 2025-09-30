AddCSLuaFile() 

-- Define the path to your JSON file relative to the "garrysmod" folder.
print(SysTime()) 
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
        if not fileName then
            MsgC(Color(255, 100, 100), "[SB Importer] Invalid file name or not a .json file: ", relativePath, "\n")
            return
        end
        local globalTableName = "SB_" .. fileName

        if _G[globalTableName] then
            MsgC(Color(100, 255, 100), "[SB Importer] Table '", globalTableName, "' already exists. Skipping file read.\n")
            return
        end

        local jsonString = file.Read(relativePath, "GAME")
        if not jsonString then
            ErrorNoHalt(string.format("[SB Importer] Failed to read file for '%s'! Check path: %s\n", globalTableName, relativePath))
            return
        end

        local tempTable = util.JSONToTable(jsonString)
        if not tempTable then
            ErrorNoHalt(string.format("[SB Importer] Failed to parse JSON for '%s'! File may be malformed: %s\n", globalTableName, relativePath))
            return
        end

        _G[globalTableName] = tempTable
        MsgC(Color(100, 255, 100), "[SB Importer] Successfully loaded '", relativePath, "' into global table '", globalTableName, "'.\n")
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
        ProcessJSONFile(relativePath)
    end
end

SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/SkillTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/SkillCommandTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/SkillActiveStepTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/SkillResultTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/EffectTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/TargetFilterTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/CharacterAnimSetTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/CharacterMoveTable.json")

print(SysTime()) 

sound.Add( 
{ 
    name = "M_Raven_vo_Cast_S_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Dialogue/ActionVoice/Raven/vo_Raven_cast_s1_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_cast_s2_VO.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_Cloth_XL_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_Cloth_L_1.wav","Character/SE/SE_Cloth_whoosh_03.wav","Character/SE/SE_Cloth_whoosh_04.wav","Skill/Monster/Raven/M_Raven_Cloth_L_2.wav","Skill/Monster/Raven/M_Raven_Cloth_L_3.wav","Character/SE/SE_Cloth_whoosh_01.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_vo_ATK_S_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Dialogue/ActionVoice/Raven/vo_Raven_atk_s1_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_atk_s2_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_atk_s4_VO.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_SwordSwish_XL_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_SwordSwish_XL_layer.wav","Skill/Monster/Raven/M_Raven_SwordSwish_XL_C_1.wav","Skill/Monster/Raven/M_Raven_SwordSwish_XL_C_2.wav","Skill/Monster/Raven/M_Raven_SwordSwish_XL_C_3.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_SwordSwish_XL_C_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_SwordSwish_XL_C_1.wav","Skill/Monster/Raven/M_Raven_SwordSwish_XL_C_2.wav","Skill/Monster/Raven/M_Raven_SwordSwish_XL_layer.wav","Skill/Monster/Raven/M_Raven_SwordSwish_XL_C_3.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_Cloth_M_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_Cloth_L_1.wav","Skill/Monster/Raven/M_Raven_Cloth_L_2.wav","Skill/Monster/Raven/M_Raven_Cloth_L_3.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_Cloth_XL3_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/PC/Evade/PC_Evade_Jump_2.wav","Skill/Monster/Raven/M_Raven_Cloth_XL2_1.wav","Skill/Monster/Raven/M_Raven_Cloth_XL2_2.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_Bodyfall_L_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Character/SE/KnockDown/NEW/PC_SE_KnockDown_Bodyfall_Dirt_1.wav","MON/Statue/SE_Move_Rock_Debris_bodyfall_01.wav","FootSteps/monster/Raven/M_Raven_Bodyfall_L_1.wav","FootSteps/monster/Raven/M_Raven_Bodyfall_L_2.wav","MON/Statue/SE_Move_Rock_Debris_bodyfall_02.wav","FootSteps/monster/Mon_Bodyfall_M_Default_1.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_Cloth_L_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_Cloth_L_1.wav","Skill/Monster/Raven/M_Raven_Cloth_L_2.wav","Skill/Monster/Raven/M_Raven_Cloth_L_3.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_Bodyfall_S_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"FootSteps/monster/Raven/M_Raven_Bodyfall_S_1.wav","FootSteps/monster/Raven/M_Raven_Bodyfall_S_2.wav","MON/Statue/SE_Move_Rock_Debris_bodyfall_01.wav","MON/Statue/SE_Move_Rock_Debris_bodyfall_02.wav","FootSteps/monster/Mon_Bodyfall_M_Default_1.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_vo_P_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Dialogue/ActionVoice/Raven/vo_Raven_dmg_l3_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_dmg_l4_VO.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_vo_ATK_L_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Dialogue/ActionVoice/Raven/vo_Raven_atk_l1_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_atk_l2_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_atk_l3_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_atk_l4_VO.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_SwordSwish_S_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_SwordSwish_M_1.wav","Skill/Monster/Raven/M_Raven_SwordSwish_M_2.wav","Skill/Monster/Raven/M_Raven_SwordSwish_M_3.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_SwordSwish_L_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_SwordSwish_L_1.wav","Skill/Monster/Raven/M_Raven_SwordSwish_L_2.wav","Skill/Monster/Raven/M_Raven_SwordSwish_L_3.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_vo_Cast_M_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Dialogue/ActionVoice/Raven/vo_Raven_cast_m1_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_cast_m2_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_cast_m3_VO.wav"}
}) 
sound.Add( 
{ 
    name = "mon_swish_m_cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Character/Skill/Swing_sword_Short_06.wav","Character/Skill/Swing_sword_Short_07.wav","Character/Skill/Swing_sword_Short_08.wav","Character/Skill/Swing_sword_Short_09.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_SwordSwish_XS_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_SwordSwish_XS_1.wav","Skill/Monster/Raven/M_Raven_SwordSwish_XS_2.wav","Skill/Monster/Raven/M_Raven_SwordSwish_XS_3.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_Cloth_XL2_Ce", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_Cloth_XL2_1.wav","Skill/Monster/Raven/M_Raven_Cloth_XL2_2.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_Skill_Stab_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Character/Hit/PCHitSound/CSS_Hit_Hammer_Critical_1.wav","Skill/Monster/Raven/M_Raven_Skill_Stab_1.wav","Character/Hit/PCHitSound/CSS_Hit_Hammer_Critical_3.wav","Skill/Monster/Raven/M_Raven_Skill_Stab_3.wav","Character/Hit/Hit_Sword_Defualt_10.wav","Character/Hit/Hit_Sword_Defualt_11.wav","Character/Hit/Hit_Sword_Defualt_08.wav","Character/Hit/Hit_Sword_Defualt_09.wav","Character/Hit/Hit_Sword_Defualt_07.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_vo_Dmg_S_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Dialogue/ActionVoice/Raven/vo_Raven_dmg_s1_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_dmg_s2_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_dmg_s3_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_dmg_s4_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_dmg_s5_VO.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_SwordSwish_M_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Skill/Monster/Raven/M_Raven_SwordSwish_M_1.wav","Skill/Monster/Raven/M_Raven_SwordSwish_M_2.wav","Skill/Monster/Raven/M_Raven_SwordSwish_M_3.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_vo_Cast_L_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Dialogue/ActionVoice/Raven/vo_Raven_cast_l1_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_cast_l2_VO.wav"}
}) 
sound.Add( 
{ 
    name = "M_Raven_vo_Dmg_L_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Dialogue/ActionVoice/Raven/vo_Raven_dmg_l1_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_dmg_l2_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_dmg_l3_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_dmg_l4_VO.wav"}
}) 

sound.Add( 
{ 
    name = "M_Raven_vo_SkillLaugh_Cue", 
    channel = CHAN_AUTO, 
    volume = 1, 
    soundlevel = 100, 
    sound = {"Dialogue/ActionVoice/Raven/vo_Raven_laugh_01_VO.wav","Dialogue/ActionVoice/Raven/vo_Raven_laugh_02_VO.wav"}
}) 


-- stuff related to health, shield is in CharacterTable.json 
-- skilltable has skill information and the skill tree it starts from SkillActiveStepTable 
-- SelectSchedule accesses M_Raven_AI.json and starting from root node "ObjectName": "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_38'" 
-- checking whether the target & self is alive 
-- then proceeds to child nodes 
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
ENT.NPC_PainSound 	= "M_Raven_vo_Dmg_L_Cue" 
ENT.NPC_PainSoundWater 	= "Unreali_Female.HurtUnderWater" 
ENT.npc_health 		= 248304 -- "MaxHP": 248304, "MaxShield": 4805, 
ENT.npc_model		= "models/alvaroports/sbraven2.mdl" 
ENT.bHasInnateMelee1 = false 
ENT.m_fMaxYawSpeed = 360 -- "RotateAnglePerSecond": 360.0, 
ENT.SBAI_BlackBoard = { } 
ENT.SBAI_bInBackgroundTask = false 
ENT.SbEffectAlias = { } 

-- childcomposite = nexttask 
-- childtask = starttask 
-- decorators = condition 
ENT.SBAI_BehaviorTree = {
  {
    Condition = {
      SBBTDecorator_SbIsAlive_0 = {
        ActorType = "Target",
        CheckType = "Alive",
        FlowAbortMode = "Both"
      }
    },
    NextTask = {
      {
        Condition = {
          SBBTDecorator_SbDetectResult_1 = {
            CompareDetectResult = "AIDetectResult_Detect"
          }
        },
        ObjectName = "SBBTTask_SbDetectTarget'M_Raven_AI:SBBTTask_SbDetectTarget_1'",
        StartTask = {
          SBBTTask_SbDetectTarget_1 = {
            bComa = true,
            bEnemy = true
          }
        }
      },
      {
        Condition = {
          SBBTDecorator_SbIsAlive_1 = {
            ActorType = "Target",
            CheckType = "Coma",
            FlowAbortMode = "Both"
          }
        },
        NextTask = {
          {
            Condition = {},
            ObjectName = "SBBTTask_SbWait'M_Raven_AI:SBBTTask_SbWait_0'",
            StartTask = {
              SBBTTask_SbWait_0 = {
                WaitTime = 1
              }
            }
          }
        },
        ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_34'"
      },
      {
        Condition = {
          SBBTDecorator_SbIsAlive_2 = {
            ActorType = "Target",
            CheckType = "Alive",
            FlowAbortMode = "Both"
          }
        },
        NextTask = {
          {
            Condition = {
              SBBTDecorator_SbCheckActorEffect_21 = {
                ActorType = "Target",
                EffectAlias = "Item_Resurrection_Ground",
                bActive = true,
                bInverseCondition = false
              }
            },
            ObjectName = "SBBTTask_SbWait'M_Raven_AI:SBBTTask_SbWait_1'",
            StartTask = {
              SBBTTask_SbWait_1 = {
                WaitTime = 2
              }
            }
          },
          {
            Condition = {
              SBBTDecorator_SbCheckActorEffect_1 = {
                ActorType = "Target",
                FlowAbortMode = "Self",
                OrCheck_EffectAliasArray = {
                  "Item_Resurrection_Ground",
                  "Getup",
                  "FastGetup",
                  "KnockDownForward",
                  "KnockDownBackward",
                  "Down",
                  "DownFaceUp",
                  "DownFaceUp_E",
                  "DownFaceDown",
                  "DownFaceDown_E",
                  "KnockDownBackward_Eve",
                  "KnockDownForward_Eve",
                  "KnockDownBackwardTumbling_Eve",
                  "KnockDownForwardTumbling_Eve",
                  "LV_FinishQTE_FailDown",
                  "M_Raven_BetaGrab_HitL",
                  "M_Raven_BetaGrab_HitE",
                  "M_Raven_BetaGrabChain_HitL",
                  "M_Raven_BetaGrabChain_HitE",
                  "M_Raven_BetaCounterGrab_HitL",
                  "M_Raven_BetaCounterGrab_HitE"
                },
                bActive = true,
                bInverseCondition = false
              }
            },
            NextTask = {
              {
                Condition = {
                  SBBTDecorator_SbTimeLimit_2 = {
                    LimitTime = 3.6000000000000001,
                    TimerName = "AbnormalTimer"
                  }
                },
                ObjectName = "SBBTTask_SbCautionToTarget'M_Raven_AI:SBBTTask_SbCautionToTarget_2'",
                StartTask = {
                  SBBTTask_SbCautionToTarget_2 = {
                    MaxDistance = 1200,
                    SetMoveType = "ESBCautionToTargetMoveType::Side",
                    SideMoveMaxDistance = 2000,
                    SideMoveMinDistance = 2000,
                    WaitCheckTime = 5,
                    WaitCountByGroup = 1,
                    bIgnoreRestartSelf = true,
                    bLockOn = true
                  }
                }
              }
            },
            ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_9'"
          },
          {
            Condition = {
              SBBTDecorator_SbAggroLevel_1 = {
                CompareAggroLevelArray = {
                  "AIAggroLevel_Peaceful"
                }
              }
            },
            NextTask = {
              {
                Condition = {
                  SBBTDecorator_SbBlackboard_1 = {
                    CompareOP = "Equal",
                    KeyName = "SwordBuffFX"
                  }
                },
                NextTask = {
                  {
                    Condition = {},
                    ObjectName = "SBBTTask_SbBlackboard'M_Raven_AI:SBBTTask_SbBlackboard_0'",
                    StartTask = {
                      SBBTTask_SbBlackboard_0 = {
                        IntValue = 1,
                        KeyName = "SwordBuffFX",
                        bReturnSucceeded = true
                      }
                    }
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_29 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_BuffFX",
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    ObjectName = "SBBTTask_SbUseEffect'M_Raven_AI:SBBTTask_SbUseEffect_1'",
                    StartTask = {
                      SBBTTask_SbUseEffect_1 = {
                        EffectAlias = {
                          "M_Raven_BuffFX"
                        },
                        bSelfActor = true
                      }
                    }
                  }
                },
                ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_13'"
              },
              {
                Condition = {
                  SBBTDecorator_SbCheckActorStat_2 = {
                    CheckStat = "ActorStatType_HP",
                    CheckValue = 60,
                    CompareOP = "Greater",
                    NodeName = "SB_CheckActorStat(HP>60)",
                    bRateValue = true
                  },
                  SBBTDecorator_SbCheckStance_2 = {
                    StanceName = "M_Raven_Default"
                  }
                },
                NextTask = {
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_6 = {
                        CompareOP = "Equal",
                        KeyName = "BB1"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_5'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_5 = {
                            KeyName = "Timer_Approach",
                            NodeName = "SB_UseableTimeReset(Timer_Approach)",
                            SetCycleTimeValue = -1,
                            SetInitialTimeValue = 5
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_4'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_4 = {
                            KeyName = "Timer_8Seconds",
                            NodeName = "SB_UseableTimeReset(Timer_8Seconds)",
                            SetCycleTimeValue = -1,
                            SetInitialTimeValue = 8
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_0'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_0 = {
                            KeyName = "Timer_NoGuard",
                            NodeName = "SB_UseableTimeReset(Timer_NoGuard)",
                            SetCycleTimeValue = -1,
                            SetInitialTimeValue = 15
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_1'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_1 = {
                            KeyName = "Timer_20Seconds",
                            NodeName = "SB_UseableTimeReset(Timer_20Seconds)",
                            SetCycleTimeValue = -1,
                            SetInitialTimeValue = 20
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_7'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_7 = {
                            KeyName = "Timer_MoveBack",
                            NodeName = "SB_UseableTimeReset(Timer_MoveBack)",
                            SetCycleTimeValue = -1,
                            SetInitialTimeValue = 30
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_6'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_6 = {
                            KeyName = "Timer_EvasionSkill",
                            NodeName = "SB_UseableTimeReset(Timer_EvasionSkill)",
                            SetCycleTimeValue = 1.5,
                            SetInitialTimeValue = 1
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseEffect'M_Raven_AI:SBBTTask_SbUseEffect_0'",
                        StartTask = {
                          SBBTTask_SbUseEffect_0 = {
                            EffectAlias = {
                              "M_Raven_QTETimer"
                            },
                            bSelfActor = true
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbBlackboard'M_Raven_AI:SBBTTask_SbBlackboard_12'",
                        StartTask = {
                          SBBTTask_SbBlackboard_12 = {
                            IntValue = 1,
                            KeyName = "BB1",
                            bReturnSucceeded = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_45'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbAimMe_2 = {},
                      SBBTDecorator_SbBlackboard_7 = {
                        CompareOP = "Equal",
                        KeyName = "FirstShot"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbBlackboard'M_Raven_AI:SBBTTask_SbBlackboard_25'",
                        StartTask = {
                          SBBTTask_SbBlackboard_25 = {
                            IntValue = 1,
                            KeyName = "FirstShot",
                            bReturnSucceeded = true
                          }
                        }
                      },
                      {
                        Condition = {
                          SBBTDecorator_SbRandom_3 = {
                            CheckValue = 50,
                            CompareOP = "LessOrEqual",
                            RandomRange = 100
                          }
                        },
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_12'",
                        StartTask = {
                          SBBTTask_SbUseSkill_12 = {
                            "M_Raven_EvadeLeft",
                            "M_Raven_EvadeRight",
                            SkillComboType = "ESBAISkillComboType::TableCommand",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_41'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_35 = {
                        ActorType = "Target",
                        EffectAlias = "M_Common_HitProjectileResult",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbRandom_1 = {
                        CheckValue = 50,
                        CompareOP = "LessOrEqual",
                        RandomRange = 100
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_11'",
                        StartTask = {
                          SBBTTask_SbUseSkill_11 = {
                            "M_Raven_EvadeLeft",
                            "M_Raven_EvadeRight",
                            SkillComboType = "ESBAISkillComboType::TableCommand",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_35'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_49 = {
                        ActorType = "Target",
                        EffectAlias = "P_Eve_Beta_SwordAura",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbDistanceToTarget_23 = {
                        CompareOP = "GreaterOrEqual",
                        Distance = 300
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_14'",
                        StartTask = {
                          SBBTTask_SbUseSkill_14 = {
                            "M_Raven_BetaEvadeLeft",
                            "M_Raven_BetaEvadeRight",
                            SkillComboType = "ESBAISkillComboType::TableCommand",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_24'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_53 = {
                        ActorType = "Target",
                        EffectAlias = "P_Eve_Beta_SwordAura2",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbDistanceToTarget_24 = {
                        CompareOP = "GreaterOrEqual",
                        Distance = 300
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_0'",
                        StartTask = {
                          SBBTTask_SbUseSkill_0 = {
                            "M_Raven_BetaEvadeLeft",
                            "M_Raven_BetaEvadeRight",
                            SkillComboType = "ESBAISkillComboType::TableCommand",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_23'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_54 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_RushWaitTime",
                        FlowAbortMode = "Self",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbCheckActorEffect_55 = {
                        ActorType = "Target",
                        EffectAlias = "P_Eve_Beta_SwordAura2",
                        FlowAbortMode = "Self",
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbTimeLimit_10 = {
                            LimitTime = 1.8,
                            TimerName = "RushWaitTimer1"
                          }
                        },
                        ObjectName = "SBBTTask_SbCautionToTarget'M_Raven_AI:SBBTTask_SbCautionToTarget_6'",
                        StartTask = {
                          SBBTTask_SbCautionToTarget_6 = {
                            MaxDistance = 1200,
                            SetMoveType = "ESBCautionToTargetMoveType::Side",
                            SideMoveMaxDistance = 2000,
                            SideMoveMinDistance = 1000,
                            WaitCheckTime = 4,
                            WaitCountByGroup = 1,
                            bIgnoreRestartSelf = true,
                            bLockOn = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_8'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_5 = {
                        CompareOP = "GreaterOrEqual",
                        IntValue = 1,
                        KeyName = "FirstTime"
                      },
                      SBBTDecorator_SbCheckActorEffect_60 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_NoGuardCheck",
                          "M_Raven_NoGuardCheck2",
                          "M_Raven_NoGuardShortCheck",
                          "M_Raven_EvadeParryCheck",
                          "M_Raven_ParryChain",
                          "M_Raven_GrabChain"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbUseableTime_14 = {
                        KeyName = "Timer_20Seconds"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_66'",
                        StartTask = {
                          SBBTTask_SbUseSkill_66 = {
                            "M_Raven_ParryPreview1",
                            bUsePostStep = true,
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_37'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_73 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryPreviewChain1",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbCheckActorEffect_74 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryPreviewChain2",
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_24'",
                        StartTask = {
                          SBBTTask_SbUseSkill_24 = {
                            "M_Raven_Parry",
                            bUsePostStep = true,
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_14'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_61 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryChain",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbCheckActorEffect_62 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryPreviewChain2",
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_65 = {
                            ActorType = "Target",
                            EffectAlias = "M_Raven_BetaGrabCheck",
                            bActive = true,
                            bInverseCondition = true
                          }
                        },
                        NextTask = {
                          {
                            Condition = {},
                            NextTask = {
                              {
                                Condition = {},
                                ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_43'",
                                StartTask = {
                                  SBBTTask_SbUseSkill_43 = {
                                    "M_Raven_BetaGrabChain",
                                    bUseSkillCommand = true
                                  }
                                }
                              },
                              {
                                Condition = {
                                  SBBTDecorator_SbCheckActorEffect_15 = {
                                    ActorType = "Target",
                                    EffectAlias = "M_Raven_GrabChain",
                                    bActive = true,
                                    bInverseCondition = false
                                  }
                                },
                                ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_35'",
                                StartTask = {
                                  SBBTTask_SbUseSkill_35 = {
                                    "M_Raven_BetaCounterGrab",
                                    bUseSkillCommand = true
                                  }
                                }
                              }
                            },
                            ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_7'"
                          },
                          {
                            Condition = {
                              SBBTDecorator_SbCheckActorEffect_64 = {
                                ActorType = "Target",
                                OrCheck_EffectAliasArray = {
                                  "M_Raven_GrabChain",
                                  "M_Raven_NoGuardCheck2"
                                },
                                bActive = true,
                                bInverseCondition = true
                              }
                            },
                            ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_36'",
                            StartTask = {
                              SBBTTask_SbUseSkill_36 = {
                                "M_Raven_BetaGrab",
                                bUseSkillCommand = true
                              }
                            }
                          }
                        },
                        ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_31'"
                      },
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_63 = {
                            ActorType = "Target",
                            OrCheck_EffectAliasArray = {
                              "M_Raven_GrabChain",
                              "M_Raven_NoGuardCheck2"
                            },
                            bActive = true,
                            bInverseCondition = true
                          }
                        },
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_54'",
                        StartTask = {
                          SBBTTask_SbUseSkill_54 = {
                            "M_Raven_BetaRapidCombo",
                            "M_Raven_BetaChargeCombo",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_33'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_39 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_EvadeParryCheck",
                          "M_Raven_ParryChain",
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbUseableTime_9 = {
                        KeyName = "Timer_20Seconds"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_64'",
                        StartTask = {
                          SBBTTask_SbUseSkill_64 = {
                            "M_Raven_EvadeBackRush",
                            "M_Raven_ParryPreview2",
                            bUsePostStep = true,
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_42'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_76 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryPreviewChain2",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbCheckActorEffect_77 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryPreviewChain1",
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_25'",
                        StartTask = {
                          SBBTTask_SbUseSkill_25 = {
                            "M_Raven_ParryCounterCombo",
                            bUsePostStep = true,
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_17'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_25 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_ParryChain",
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2",
                          "M_Raven_RushWaitTime"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbDistanceToTarget_15 = {
                        CompareOP = "GreaterOrEqual",
                        Distance = 400
                      },
                      SBBTDecorator_SbUseableTime_3 = {
                        KeyName = "Timer_Approach"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_38 = {
                            ActorType = "Target",
                            OrCheck_EffectAliasArray = {
                              "M_Raven_NoGuardCheck",
                              "M_Raven_NoGuardShortCheck"
                            },
                            bActive = true,
                            bInverseCondition = true
                          },
                          SBBTDecorator_SbUseableTime_8 = {
                            KeyName = "Timer_NoGuard"
                          }
                        },
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_56'",
                        StartTask = {
                          SBBTTask_SbUseSkill_56 = {
                            "M_Raven_ChaseGrab",
                            bUseSkillCommand = true
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_62'",
                        StartTask = {
                          SBBTTask_SbUseSkill_62 = {
                            "M_Raven_ChaseCombo",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_40'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_9 = {
                        CompareOP = "Equal",
                        KeyName = "FirstTime"
                      },
                      SBBTDecorator_SbCheckActorEffect_13 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_EvadeParryCheck",
                          "M_Raven_ParryChain",
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbUseableTime_11 = {
                        KeyName = "Timer_NoGuard"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_58'",
                        StartTask = {
                          SBBTTask_SbUseSkill_58 = {
                            "M_Raven_BetaRapidCombo",
                            "M_Raven_BetaChargeCombo",
                            "M_Raven_BetaGrab",
                            bUseSkillCommand = true
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbBlackboard'M_Raven_AI:SBBTTask_SbBlackboard_3'",
                        StartTask = {
                          SBBTTask_SbBlackboard_3 = {
                            IntValue = 1,
                            KeyName = "FirstTime",
                            bReturnSucceeded = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_19'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_3 = {
                        CompareOP = "GreaterOrEqual",
                        IntValue = 1,
                        KeyName = "FirstTime"
                      },
                      SBBTDecorator_SbCheckActorEffect_7 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_NoGuardCheck",
                          "M_Raven_NoGuardShortCheck",
                          "M_Raven_EvadeParryCheck",
                          "M_Raven_ParryChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbUseableTime_0 = {
                        KeyName = "Timer_NoGuard"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_40 = {
                            ActorType = "Target",
                            EffectAlias = "M_Raven_BetaGrabCheck",
                            bActive = true,
                            bInverseCondition = true
                          }
                        },
                        NextTask = {
                          {
                            Condition = {},
                            NextTask = {
                              {
                                Condition = {},
                                ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_65'",
                                StartTask = {
                                  SBBTTask_SbUseSkill_65 = {
                                    "M_Raven_BetaGrabChain",
                                    bUseSkillCommand = true
                                  }
                                }
                              },
                              {
                                Condition = {
                                  SBBTDecorator_SbCheckActorEffect_42 = {
                                    ActorType = "Target",
                                    EffectAlias = "M_Raven_GrabChain",
                                    bActive = true,
                                    bInverseCondition = false
                                  }
                                },
                                ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_55'",
                                StartTask = {
                                  SBBTTask_SbUseSkill_55 = {
                                    "M_Raven_BetaCounterGrab",
                                    bUseSkillCommand = true
                                  }
                                }
                              }
                            },
                            ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_8'"
                          },
                          {
                            Condition = {
                              SBBTDecorator_SbCheckActorEffect_36 = {
                                ActorType = "Target",
                                OrCheck_EffectAliasArray = {
                                  "M_Raven_GrabChain",
                                  "M_Raven_NoGuardCheck2"
                                },
                                bActive = true,
                                bInverseCondition = true
                              }
                            },
                            ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_59'",
                            StartTask = {
                              SBBTTask_SbUseSkill_59 = {
                                "M_Raven_BetaGrab",
                                bUseSkillCommand = true
                              }
                            }
                          }
                        },
                        ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_36'"
                      },
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_5 = {
                            ActorType = "Target",
                            OrCheck_EffectAliasArray = {
                              "M_Raven_GrabChain",
                              "M_Raven_NoGuardCheck2"
                            },
                            bActive = true,
                            bInverseCondition = true
                          }
                        },
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_67'",
                        StartTask = {
                          SBBTTask_SbUseSkill_67 = {
                            "M_Raven_BetaRapidCombo",
                            "M_Raven_BetaChargeCombo",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_43'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_47 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_ParryChain",
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbUseableTime_10 = {
                        KeyName = "Timer_MoveBack"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_60'",
                        StartTask = {
                          SBBTTask_SbUseSkill_60 = {
                            "M_Raven_RapidMoveBack",
                            bUseSkillCommand = true
                          }
                        }
                      },
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_14 = {
                            ActorType = "Target",
                            FlowAbortMode = "Self",
                            OrCheck_EffectAliasArray = {
                              "P_Eve_Beta_SwordAura",
                              "P_Eve_Beta_SwordAura2"
                            },
                            bActive = true,
                            bInverseCondition = true
                          },
                          SBBTDecorator_SbCheckActorEffect_16 = {
                            ActorType = "Target",
                            FlowAbortMode = "Self",
                            OrCheck_EffectAliasArray = {
                              "M_Raven_ParryPreviewChain1",
                              "M_Raven_ParryPreviewChain2",
                              "M_Raven_RushWaitTime",
                              "M_Raven_ParryChain"
                            },
                            bActive = true,
                            bInverseCondition = true
                          },
                          SBBTDecorator_SbDistanceToTarget_20 = {
                            CompareOP = "LessOrEqual",
                            Distance = 1400
                          },
                          SBBTDecorator_SbDistanceToTarget_21 = {
                            CompareOP = "GreaterOrEqual",
                            Distance = 250,
                            FlowAbortMode = "Self"
                          },
                          SBBTDecorator_SbTimeLimit_7 = {
                            LimitTime = 1.8,
                            ReactInterval = 35,
                            TimerName = "CautionTimer1"
                          }
                        },
                        ObjectName = "SBBTTask_SbCautionToTarget'M_Raven_AI:SBBTTask_SbCautionToTarget_5'",
                        StartTask = {
                          SBBTTask_SbCautionToTarget_5 = {
                            MaxDistance = 1200,
                            SetMoveType = "ESBCautionToTargetMoveType::Side",
                            SideMoveMaxDistance = 1000,
                            SideMoveMinDistance = 600,
                            WaitCheckTime = 4,
                            WaitCountByGroup = 1,
                            bIgnoreRestartSelf = true,
                            bLockOn = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_5'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_24 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_ParryChain",
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2",
                          "M_Raven_MoveComboCheck"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbUseableTime_2 = {
                        KeyName = "Timer_8Seconds"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_63'",
                        StartTask = {
                          SBBTTask_SbUseSkill_63 = {
                            "M_Raven_MoveCombo",
                            "M_Raven_MoveChainCombo",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_41'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_4 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_ParryChain",
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_68'",
                        StartTask = {
                          SBBTTask_SbUseSkill_68 = {
                            "M_Raven_Slash",
                            "M_Raven_SlashChain",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_20'"
                  },
                  {
                    Condition = {},
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_20 = {
                            ActorType = "Target",
                            FlowAbortMode = "Self",
                            OrCheck_EffectAliasArray = {
                              "P_Eve_Beta_SwordAura",
                              "P_Eve_Beta_SwordAura2"
                            },
                            bActive = true,
                            bInverseCondition = true
                          },
                          SBBTDecorator_SbCheckActorEffect_28 = {
                            ActorType = "Target",
                            FlowAbortMode = "Self",
                            OrCheck_EffectAliasArray = {
                              "M_Raven_ParryPreviewChain1",
                              "M_Raven_ParryPreviewChain2",
                              "M_Raven_RushWaitTime",
                              "M_Raven_ParryChain"
                            },
                            bActive = true,
                            bInverseCondition = true
                          },
                          SBBTDecorator_SbDistanceToTarget_14 = {
                            CompareOP = "LessOrEqual",
                            Distance = 1400
                          },
                          SBBTDecorator_SbDistanceToTarget_22 = {
                            CompareOP = "GreaterOrEqual",
                            Distance = 250,
                            FlowAbortMode = "Self"
                          },
                          SBBTDecorator_SbTimeLimit_4 = {
                            LimitTime = 1.8,
                            ReactInterval = 35,
                            TimerName = "CautionTimer1"
                          },
                          SBBTDecorator_SbUseableTime_4 = {
                            KeyName = "Timer_8Seconds"
                          }
                        },
                        ObjectName = "SBBTTask_SbCautionToTarget'M_Raven_AI:SBBTTask_SbCautionToTarget_3'",
                        StartTask = {
                          SBBTTask_SbCautionToTarget_3 = {
                            MaxDistance = 1200,
                            SetMoveType = "ESBCautionToTargetMoveType::Side",
                            SideMoveMaxDistance = 1000,
                            SideMoveMinDistance = 600,
                            WaitCheckTime = 4,
                            WaitCountByGroup = 1,
                            bIgnoreRestartSelf = true,
                            bLockOn = true
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbMoveToTarget'M_Raven_AI:SBBTTask_SbMoveToTarget_2'",
                        StartTask = {
                          SBBTTask_SbMoveToTarget_2 = {
                            DistanceOfApproach = 250,
                            MoveState = "ESBMoveState::MoveState_Run",
                            NodeName = "SB_MoveToTarget_Run",
                            bBackgroundTask = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_44'"
                  }
                },
                ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_6'"
              },
              {
                Condition = {
                  SBBTDecorator_SbCheckActorStat_1 = {
                    CheckStat = "ActorStatType_HP",
                    CheckValue = 60,
                    CompareOP = "LessOrEqual",
                    NodeName = "SB_CheckActorStat(HP<=60)",
                    bRateValue = true
                  },
                  SBBTDecorator_SbCheckStance_1 = {
                    StanceName = "M_Raven_Phase2"
                  }
                },
                NextTask = {
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_0 = {
                        CompareOP = "Equal",
                        KeyName = "BB2"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_9'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_9 = {
                            KeyName = "Timer_7Seconds",
                            NodeName = "SB_UseableTimeReset(Timer_7Seconds)",
                            SetCycleTimeValue = -1,
                            SetInitialTimeValue = 7
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_2'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_2 = {
                            KeyName = "Timer_10Seconds",
                            NodeName = "SB_UseableTimeReset(Timer_10Seconds)",
                            SetCycleTimeValue = -1,
                            SetInitialTimeValue = 10
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_8'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_8 = {
                            KeyName = "Timer_15Seconds",
                            NodeName = "SB_UseableTimeReset(Timer_15Seconds)",
                            SetCycleTimeValue = -1,
                            SetInitialTimeValue = 15
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseableTimeReset'M_Raven_AI:SBBTTask_SbUseableTimeReset_3'",
                        StartTask = {
                          SBBTTask_SbUseableTimeReset_3 = {
                            KeyName = "Timer_EvasionSkill",
                            NodeName = "SB_UseableTimeReset(Timer_EvasionSkill)",
                            SetCycleTimeValue = 1.5,
                            SetInitialTimeValue = 1
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbBlackboard'M_Raven_AI:SBBTTask_SbBlackboard_1'",
                        StartTask = {
                          SBBTTask_SbBlackboard_1 = {
                            IntValue = 1,
                            KeyName = "BB2",
                            bReturnSucceeded = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_14'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbAimMe_7 = {},
                      SBBTDecorator_SbBlackboard_14 = {
                        CompareOP = "Equal",
                        KeyName = "FirstShot"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbBlackboard'M_Raven_AI:SBBTTask_SbBlackboard_4'",
                        StartTask = {
                          SBBTTask_SbBlackboard_4 = {
                            IntValue = 1,
                            KeyName = "FirstShot",
                            bReturnSucceeded = true
                          }
                        }
                      },
                      {
                        Condition = {
                          SBBTDecorator_SbRandom_8 = {
                            CheckValue = 50,
                            CompareOP = "LessOrEqual",
                            RandomRange = 100
                          }
                        },
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_20'",
                        StartTask = {
                          SBBTTask_SbUseSkill_20 = {
                            "M_Raven_EvadeLeft",
                            "M_Raven_EvadeRight",
                            SkillComboType = "ESBAISkillComboType::TableCommand",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_12'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_30 = {
                        ActorType = "Target",
                        EffectAlias = "M_Common_HitProjectileResult",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbRandom_0 = {
                        CheckValue = 50,
                        CompareOP = "LessOrEqual",
                        RandomRange = 100
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_18'",
                        StartTask = {
                          SBBTTask_SbUseSkill_18 = {
                            "M_Raven_EvadeLeft",
                            "M_Raven_EvadeRight",
                            SkillComboType = "ESBAISkillComboType::TableCommand",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_11'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbAimMe_6 = {},
                      SBBTDecorator_SbCheckActorStat_6 = {
                        CheckStat = "ActorStatType_HP",
                        CheckValue = 20,
                        CompareOP = "LessOrEqual",
                        bRateValue = true
                      },
                      SBBTDecorator_SbRandom_7 = {
                        CheckValue = 50,
                        CompareOP = "LessOrEqual",
                        RandomRange = 100
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_19'",
                        StartTask = {
                          SBBTTask_SbUseSkill_19 = {
                            "M_Raven_EvadeLeft",
                            "M_Raven_EvadeRight",
                            SkillComboType = "ESBAISkillComboType::TableCommand",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_10'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_79 = {
                        ActorType = "Target",
                        EffectAlias = "P_Eve_Beta_SwordAura",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbDistanceToTarget_10 = {
                        CompareOP = "GreaterOrEqual",
                        Distance = 300
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_2'",
                        StartTask = {
                          SBBTTask_SbUseSkill_2 = {
                            "M_Raven_BetaEvadeLeft",
                            "M_Raven_BetaEvadeRight",
                            SkillComboType = "ESBAISkillComboType::TableCommand",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_6'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_80 = {
                        ActorType = "Target",
                        EffectAlias = "P_Eve_Beta_SwordAura2",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbDistanceToTarget_18 = {
                        CompareOP = "GreaterOrEqual",
                        Distance = 300
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_8'",
                        StartTask = {
                          SBBTTask_SbUseSkill_8 = {
                            "M_Raven_BetaEvadeLeft",
                            "M_Raven_BetaEvadeRight",
                            SkillComboType = "ESBAISkillComboType::TableCommand",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_9'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_43 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_RushWaitTime",
                        FlowAbortMode = "Self",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbCheckActorEffect_44 = {
                        ActorType = "Target",
                        EffectAlias = "P_Eve_Beta_SwordAura2",
                        FlowAbortMode = "Self",
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbTimeLimit_8 = {
                            LimitTime = 1.8,
                            TimerName = "RushWaitTimer1"
                          }
                        },
                        ObjectName = "SBBTTask_SbCautionToTarget'M_Raven_AI:SBBTTask_SbCautionToTarget_7'",
                        StartTask = {
                          SBBTTask_SbCautionToTarget_7 = {
                            MaxDistance = 1200,
                            SetMoveType = "ESBCautionToTargetMoveType::Side",
                            SideMoveMaxDistance = 2000,
                            SideMoveMinDistance = 1000,
                            WaitCheckTime = 4,
                            WaitCountByGroup = 1,
                            bIgnoreRestartSelf = true,
                            bLockOn = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_10'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_8 = {
                        CompareOP = "GreaterOrEqual",
                        IntValue = 1,
                        KeyName = "SecondTime"
                      },
                      SBBTDecorator_SbCheckActorEffect_19 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_EvadeParryCheck",
                          "M_Raven_GrabChain"
                        },
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_37'",
                        StartTask = {
                          SBBTTask_SbUseSkill_37 = {
                            "M_Raven_ParryPreview1",
                            bUsePostStep = true,
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_1'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_67 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryPreviewChain1",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbCheckActorEffect_68 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryPreviewChain2",
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_34'",
                        StartTask = {
                          SBBTTask_SbUseSkill_34 = {
                            "M_Raven_ParryCounterSlash",
                            bUsePostStep = true,
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_26'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_2 = {
                        CompareOP = "GreaterOrEqual",
                        IntValue = 1,
                        KeyName = "SecondTime"
                      },
                      SBBTDecorator_SbCheckActorEffect_81 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_EvadeParryCheck",
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbUseableTime_1 = {
                        KeyName = "Timer_10Seconds"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_91'",
                        StartTask = {
                          SBBTTask_SbUseSkill_91 = {
                            "M_Raven_EvadeBackSwordAura",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_57'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_18 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_EvadeParryCheck",
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbUseableTime_16 = {
                        KeyName = "Timer_10Seconds"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_39'",
                        StartTask = {
                          SBBTTask_SbUseSkill_39 = {
                            "M_Raven_EvadeBackRush",
                            "M_Raven_ParryPreview2",
                            bUsePostStep = true,
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_5'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_69 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryPreviewChain2",
                        bActive = true,
                        bInverseCondition = false
                      },
                      SBBTDecorator_SbCheckActorEffect_70 = {
                        ActorType = "Target",
                        EffectAlias = "M_Raven_ParryPreviewChain1",
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_38'",
                        StartTask = {
                          SBBTTask_SbUseSkill_38 = {
                            "M_Raven_ParryCounterCombo",
                            bUsePostStep = true,
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_27'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_129 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbCheckActorStat_0 = {
                        CheckStat = "ActorStatType_HP",
                        CheckValue = 30,
                        CompareOP = "LessOrEqual",
                        NodeName = "SB_CheckActorStat(HP<=30)",
                        bRateValue = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_4'",
                        StartTask = {
                          SBBTTask_SbUseSkill_4 = {
                            "M_Raven_SlashChainCombo",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_2'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_6 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2",
                          "M_Raven_RushWaitTime",
                          "M_Raven_SwordAuraCheck"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbDistanceToTarget_13 = {
                        CompareOP = "GreaterOrEqual",
                        Distance = 1000
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_16'",
                        StartTask = {
                          SBBTTask_SbUseSkill_16 = {
                            "M_Raven_SwordAuraCombo",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_12'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_2 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_GrabChain",
                          "M_Raven_ChaseCheck",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2",
                          "M_Raven_RushWaitTime"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbDistanceToTarget_17 = {
                        CompareOP = "GreaterOrEqual",
                        Distance = 400
                      }
                    },
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_17 = {
                            ActorType = "Target",
                            OrCheck_EffectAliasArray = {
                              "M_Raven_NoGuardCheck",
                              "M_Raven_NoGuardShortCheck"
                            },
                            bActive = true,
                            bInverseCondition = true
                          }
                        },
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_93'",
                        StartTask = {
                          SBBTTask_SbUseSkill_93 = {
                            "M_Raven_ChaseGrab",
                            bUseSkillCommand = true
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_40'",
                        StartTask = {
                          SBBTTask_SbUseSkill_40 = {
                            "M_Raven_ChaseCombo",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_13'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_4 = {
                        CompareOP = "Equal",
                        KeyName = "SecondTime"
                      },
                      SBBTDecorator_SbCheckActorEffect_37 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      },
                      SBBTDecorator_SbUseableTime_12 = {
                        KeyName = "Timer_7Seconds"
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_15'",
                        StartTask = {
                          SBBTTask_SbUseSkill_15 = {
                            "M_Raven_BurstAreaSlash",
                            bUseSkillCommand = true
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbBlackboard'M_Raven_AI:SBBTTask_SbBlackboard_2'",
                        StartTask = {
                          SBBTTask_SbBlackboard_2 = {
                            IntValue = 1,
                            KeyName = "SecondTime",
                            bReturnSucceeded = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_16'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_10 = {
                        CompareOP = "GreaterOrEqual",
                        IntValue = 1,
                        KeyName = "SecondTime"
                      },
                      SBBTDecorator_SbCheckActorEffect_11 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_1'",
                        StartTask = {
                          SBBTTask_SbUseSkill_1 = {
                            "M_Raven_BurstSpinCombo",
                            "M_Raven_BurstAreaSlash",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_2'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbBlackboard_11 = {
                        CompareOP = "GreaterOrEqual",
                        IntValue = 1,
                        KeyName = "SecondTime"
                      },
                      SBBTDecorator_SbCheckActorEffect_23 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_NoGuardCheck",
                          "M_Raven_EvadeParryCheck",
                          "M_Raven_NoGuardShortCheck",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_33 = {
                            ActorType = "Target",
                            EffectAlias = "M_Raven_BetaGrabCheck",
                            bActive = true,
                            bInverseCondition = true
                          }
                        },
                        NextTask = {
                          {
                            Condition = {},
                            NextTask = {
                              {
                                Condition = {},
                                ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_3'",
                                StartTask = {
                                  SBBTTask_SbUseSkill_3 = {
                                    "M_Raven_BetaGrabChain",
                                    bUseSkillCommand = true
                                  }
                                }
                              },
                              {
                                Condition = {
                                  SBBTDecorator_SbCheckActorEffect_34 = {
                                    ActorType = "Target",
                                    EffectAlias = "M_Raven_GrabChain",
                                    bActive = true,
                                    bInverseCondition = false
                                  }
                                },
                                ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_10'",
                                StartTask = {
                                  SBBTTask_SbUseSkill_10 = {
                                    "M_Raven_BetaCounterGrab",
                                    bUseSkillCommand = true
                                  }
                                }
                              }
                            },
                            ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_0'"
                          },
                          {
                            Condition = {
                              SBBTDecorator_SbCheckActorEffect_32 = {
                                ActorType = "Target",
                                OrCheck_EffectAliasArray = {
                                  "M_Raven_GrabChain",
                                  "M_Raven_NoGuardCheck2"
                                },
                                bActive = true,
                                bInverseCondition = true
                              }
                            },
                            ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_21'",
                            StartTask = {
                              SBBTTask_SbUseSkill_21 = {
                                "M_Raven_BetaGrab",
                                bUseSkillCommand = true
                              }
                            }
                          }
                        },
                        ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_7'"
                      },
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_31 = {
                            ActorType = "Target",
                            OrCheck_EffectAliasArray = {
                              "M_Raven_GrabChain",
                              "M_Raven_NoGuardCheck2"
                            },
                            bActive = true,
                            bInverseCondition = true
                          }
                        },
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_44'",
                        StartTask = {
                          SBBTTask_SbUseSkill_44 = {
                            "M_Raven_BetaRapidCombo",
                            "M_Raven_BetaChargeCombo",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_3'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_10 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_GrabChain",
                          "M_Raven_BackMoveCheck",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        NextTask = {
                          {
                            Condition = {
                              SBBTDecorator_SbCheckActorEffect_9 = {
                                ActorType = "Target",
                                EffectAlias = "M_Raven_SwordAuraCheck",
                                bActive = true,
                                bInverseCondition = true
                              },
                              SBBTDecorator_SbUseableTime_48 = {
                                KeyName = "Timer_15Seconds"
                              }
                            },
                            ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_17'",
                            StartTask = {
                              SBBTTask_SbUseSkill_17 = {
                                "M_Raven_BackJumpCombo",
                                bUseSkillCommand = true
                              }
                            }
                          },
                          {
                            Condition = {
                              SBBTDecorator_SbCheckActorEffect_26 = {
                                ActorType = "Target",
                                FlowAbortMode = "Self",
                                OrCheck_EffectAliasArray = {
                                  "P_Eve_Beta_SwordAura",
                                  "P_Eve_Beta_SwordAura2"
                                },
                                bActive = true,
                                bInverseCondition = true
                              },
                              SBBTDecorator_SbDistanceToTarget_2 = {
                                CompareOP = "LessOrEqual",
                                Distance = 1400
                              },
                              SBBTDecorator_SbDistanceToTarget_3 = {
                                CompareOP = "GreaterOrEqual",
                                Distance = 250,
                                FlowAbortMode = "Self"
                              },
                              SBBTDecorator_SbTimeLimit_3 = {
                                LimitTime = 1.8,
                                ReactInterval = 55,
                                TimerName = "CautionTimer2"
                              }
                            },
                            ObjectName = "SBBTTask_SbCautionToTarget'M_Raven_AI:SBBTTask_SbCautionToTarget_1'",
                            StartTask = {
                              SBBTTask_SbCautionToTarget_1 = {
                                MaxDistance = 1200,
                                SetMoveType = "ESBCautionToTargetMoveType::Side",
                                SideMoveMaxDistance = 1000,
                                SideMoveMinDistance = 600,
                                WaitCheckTime = 4,
                                WaitCountByGroup = 1,
                                bIgnoreRestartSelf = true,
                                bLockOn = true
                              }
                            }
                          }
                        },
                        ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_3'"
                      },
                      {
                        Condition = {},
                        NextTask = {
                          {
                            Condition = {},
                            ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_94'",
                            StartTask = {
                              SBBTTask_SbUseSkill_94 = {
                                "M_Raven_RapidMoveBack",
                                bUseSkillCommand = true
                              }
                            }
                          },
                          {
                            Condition = {
                              SBBTDecorator_SbCheckActorEffect_27 = {
                                ActorType = "Target",
                                FlowAbortMode = "Self",
                                OrCheck_EffectAliasArray = {
                                  "P_Eve_Beta_SwordAura",
                                  "P_Eve_Beta_SwordAura2"
                                },
                                bActive = true,
                                bInverseCondition = true
                              },
                              SBBTDecorator_SbDistanceToTarget_4 = {
                                CompareOP = "LessOrEqual",
                                Distance = 1400
                              },
                              SBBTDecorator_SbDistanceToTarget_5 = {
                                CompareOP = "GreaterOrEqual",
                                Distance = 250,
                                FlowAbortMode = "Self"
                              },
                              SBBTDecorator_SbTimeLimit_5 = {
                                LimitTime = 1.8,
                                ReactInterval = 55,
                                TimerName = "CautionTimer2"
                              }
                            },
                            ObjectName = "SBBTTask_SbCautionToTarget'M_Raven_AI:SBBTTask_SbCautionToTarget_0'",
                            StartTask = {
                              SBBTTask_SbCautionToTarget_0 = {
                                MaxDistance = 1200,
                                SetMoveType = "ESBCautionToTargetMoveType::Side",
                                SideMoveMaxDistance = 1000,
                                SideMoveMinDistance = 600,
                                WaitCheckTime = 4,
                                WaitCountByGroup = 1,
                                bIgnoreRestartSelf = true,
                                bLockOn = true
                              }
                            }
                          }
                        },
                        ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_4'"
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_4'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_12 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_0 = {
                            ActorType = "Target",
                            EffectAlias = "M_Raven_ComboCheck",
                            bActive = true,
                            bInverseCondition = true
                          }
                        },
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_13'",
                        StartTask = {
                          SBBTTask_SbUseSkill_13 = {
                            "M_Raven_SlashCombo",
                            bUseSkillCommand = true
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_41'",
                        StartTask = {
                          SBBTTask_SbUseSkill_41 = {
                            "M_Raven_BurstSpinCombo",
                            bUseSkillCommand = true
                          }
                        }
                      },
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_3 = {
                            ActorType = "Target",
                            EffectAlias = "M_Raven_MoveComboCheck",
                            bActive = true,
                            bInverseCondition = true
                          }
                        },
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_9'",
                        StartTask = {
                          SBBTTask_SbUseSkill_9 = {
                            "M_Raven_MoveCombo",
                            "M_Raven_MoveChainCombo",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_11'"
                  },
                  {
                    Condition = {
                      SBBTDecorator_SbCheckActorEffect_22 = {
                        ActorType = "Target",
                        OrCheck_EffectAliasArray = {
                          "M_Raven_GrabChain",
                          "M_Raven_ParryPreviewChain1",
                          "M_Raven_ParryPreviewChain2"
                        },
                        bActive = true,
                        bInverseCondition = true
                      }
                    },
                    NextTask = {
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbUseSkill'M_Raven_AI:SBBTTask_SbUseSkill_57'",
                        StartTask = {
                          SBBTTask_SbUseSkill_57 = {
                            "M_Raven_Slash",
                            "M_Raven_SlashChain",
                            bUseSkillCommand = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Sequence'M_Raven_AI:BTComposite_Sequence_36'"
                  },
                  {
                    Condition = {},
                    NextTask = {
                      {
                        Condition = {
                          SBBTDecorator_SbCheckActorEffect_52 = {
                            ActorType = "Target",
                            EffectAlias = "P_Eve_Beta_SwordAura",
                            FlowAbortMode = "Self",
                            bActive = true,
                            bInverseCondition = true
                          },
                          SBBTDecorator_SbCheckActorEffect_78 = {
                            ActorType = "Target",
                            FlowAbortMode = "Self",
                            OrCheck_EffectAliasArray = {
                              "M_Raven_ParryPreviewChain1",
                              "M_Raven_ParryPreviewChain2"
                            },
                            bActive = true,
                            bInverseCondition = true
                          },
                          SBBTDecorator_SbDistanceToTarget_0 = {
                            CompareOP = "LessOrEqual",
                            Distance = 1400
                          },
                          SBBTDecorator_SbDistanceToTarget_1 = {
                            CompareOP = "GreaterOrEqual",
                            Distance = 250,
                            FlowAbortMode = "Self"
                          },
                          SBBTDecorator_SbTimeLimit_0 = {
                            LimitTime = 1.8,
                            ReactInterval = 55,
                            TimerName = "CautionTimer2"
                          }
                        },
                        ObjectName = "SBBTTask_SbCautionToTarget'M_Raven_AI:SBBTTask_SbCautionToTarget_4'",
                        StartTask = {
                          SBBTTask_SbCautionToTarget_4 = {
                            MaxDistance = 1200,
                            SetMoveType = "ESBCautionToTargetMoveType::Side",
                            SideMoveMaxDistance = 1000,
                            SideMoveMinDistance = 600,
                            WaitCheckTime = 4,
                            WaitCountByGroup = 1,
                            bIgnoreRestartSelf = true,
                            bLockOn = true
                          }
                        }
                      },
                      {
                        Condition = {},
                        ObjectName = "SBBTTask_SbMoveToTarget'M_Raven_AI:SBBTTask_SbMoveToTarget_4'",
                        StartTask = {
                          SBBTTask_SbMoveToTarget_4 = {
                            DistanceOfApproach = 250,
                            MoveState = "ESBMoveState::MoveState_Run",
                            NodeName = "SB_MoveToTarget_Run",
                            bBackgroundTask = true
                          }
                        }
                      }
                    },
                    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_23'"
                  }
                },
                ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_0'"
              }
            },
            ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_35'"
          }
        },
        ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_52'"
      }
    },
    ObjectName = "BTComposite_Selector'M_Raven_AI:BTComposite_Selector_32'"
  }
} 

-- when effects get added, they also apply effects called ShowPath like 
	-- "ActiveShowPath": "CH_M_NA_53_Raven/Basic/M_Raven_BuffFX",
        -- "LoopShowPath": "",
        -- "DeactiveShowPath": "",
		-- "ActiveTargetFilterAlias": "Self",
        -- "ActiveTargetEffectAliasArray": [],
        -- "ActiveTargetResultShowPath": "",
        -- "bActiveTargetApplyConditionHitMe": false,
        -- "LoopTargetFilterAlias": "None",
        -- "LoopTargetEffectAliasArray": [],
        -- "LoopTargetResultShowPath": "",
        -- "bLoopTargetApplyConditionHitMe": false,
        -- "FixedTargetFilterAlias": "None",
        -- "DeactiveTargetFilterAlias": "None",
        -- "DeactiveTargetEffectAliasArray": [],
        -- "DeactiveTargetResultShowPath": "",
-- they can either be visual fx, and actual animations 
-- "M_Raven_BetaGrab_HitL": {"ActiveShowPath": "CH_M_NA_53_Raven/LinkSkill/M_Raven_BetaGrabSuccessHitL"} 
-- M_Raven_BetaGrabSuccessHitL: "AnimResourcePath": "/Game/Art/Character/PC/CH_P_EVE_01/Animation/Hit_Raven_BetaCounterGrabL" 

function ENT:SBAI_AddEffect(strEffect) 
	local EffectTable = scripted_ents.Get("npc_sb_raven").SBAI_GetEffectTable(self,strEffect) 
	local curEffects = self.SbEffectAlias -- {["EffectName"] = CurTime() + EffectDuration} 
	if !curEffects then self.SbEffectAlias = { } curEffects = self.SbEffectAlias end 
	if EffectTable.LifeType == "ESBEffectLifeType::EffectLifeType_Infinite" then 
		curEffects[strEffect] = true 
	else 
		curEffects[strEffect] = CurTime() + EffectTable.LifeTime 
	end 
end 

function ENT:SBAI_GetEffectTable(strEffect) 
	local EffectTable = SB_EffectTable[1].Rows[strEffect] 
	return EffectTable 
end 

function ENT:SBAI_CheckEffect(strEffect) -- check existence of effect, return time available 
	local EffectTable = scripted_ents.Get("npc_sb_raven").SBAI_GetEffectTable(self,strEffect) 
	local curEffects = self.SbEffectAlias -- {["EffectName"] = CurTime() + EffectDuration} 
	-- pre checks before checking for existence of effect 
	-- EffectLifeType_StanceDependent: check whether npc StanceName equals to EffectTable.StanceAlias 
	-- EffectLifeType_StepDependent: check whether effect ran out of steps 
	-- EffectLifeType_BeforeNextSkill 
	-- EffectLifeType_CharacterGetupTime 
	-- EffectLifeType_CharacterGroggyEndTime
	-- EffectLifeType_EquipmentDependent
	-- EffectLifeType_IndependentTime -- countdown from LifeTime 
	-- EffectLifeType_Infinite -- once set, it can only be manually worn off 
	-- EffectLifeType_LevelSequenceDependent
	-- EffectLifeType_LevelSequenceDependentWithoutPlayable
	-- EffectLifeType_NextSkillDependent
	-- EffectLifeType_ProjectileDependent
	-- EffectLifeType_SkillDependent
	if EffectTable.LifeType == "ESBEffectLifeType::EffectLifeType_Infinite" then 
		return curEffects[strEffect] -- check whether we have specific effect 
	elseif EffectTable.LifeType == "ESBEffectLifeType::EffectLifeType_StanceDependent" then 
		return self.StanceName == EffectTable.StanceAlias 
	-- elseif EffectTable.LifeType == "ESBEffectLifeType::EffectLifeType_Infinite" then 
	end 
end 

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
]]
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
-- CORE: Get Interpolated Root Motion Transform
--==============================================================================
--[[
    Parses the root motion data to get the interpolated transform at a specific time.
    It calculates the current frame based on elapsed time and interpolates between
    the two nearest keyframes to ensure smooth movement.

    @param rootMotionTable The imported JSON table for the animation.
    @param startTime The CurTime() when the animation started.
    @returns Vector positionOffset, Angle angleOffset, or nil if data is invalid.
]]
function ENT:SBAI_GetRootMotionTransform(rootMotionTable, startTime)
    -- Ensure the root motion table is valid.
    if not rootMotionTable or not rootMotionTable[1] or not rootMotionTable[1].Properties then
        return nil, nil
    end

    -- The JSON does not seem to contain FrameRate. We'll assume a standard of 30 FPS.
    -- You may need to adjust this value if the animations look too fast or slow.
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

    -- Extract, convert, and interpolate rotation.
    local ang1 = QuaternionToAngle(transform1.Rotation)
    local ang2 = QuaternionToAngle(transform2.Rotation)
    -- LerpAngle provides smooth rotation and is a global function.
    local interpolatedAngle = LerpAngle(alpha, ang1, ang2)

    return interpolatedPos, interpolatedAngle
end

function ENT:SBAI_SetMoveTable(strEffect) -- M_Raven_SlashCombo_Move_RM 
	local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[strEffect] 
	if !CharacterMoveTable then print("no move table",strEffect) return false end 
	-- initialize new move step 
	self.SBAI_MoveStep = { ["MoveArrayName"] = strEffect, ["StartTime"] = CurTime() } 
	-- cache move array 
	local RootMotionDataPath = CharacterMoveTable.RootMotionDataPath 
	-- "addons/sbraven/data_static/SB/Content/Local/Data/SkillTable.json"
	RootMotionDataPath = string.sub(RootMotionDataPath,6) -- strip out /Game 
	-- addons/sbraven/data_static/SB/Art/Character/Monster/CH_M_NA_53/Animation/RootMotionData/M_Raven_SlashCombo_RM.json
	RootMotionDataPath = "addons/sbraven/data_static/SB/Content"..RootMotionDataPath..".json" 
	SB_ImportJSON(RootMotionDataPath) -- imports as _G.SB_M_Raven_SlashCombo_RM 
	-- "RootMotionDataPath": "/Game/Art/Character/Monster/CH_M_NA_53/Animation/RootMotionData/M_Raven_SlashCombo_RM",
	    -- "Properties": {
      -- "RootMotionDataArray": [
        -- {
          -- "CharacterMoveAlias": "M_Raven_SlashCombo_Move_RM",
          -- "TransformArray": [
            -- {
              -- "Rotation": {
                -- "X": 0.0,
                -- "Y": 0.0,
                -- "Z": 0.0,
                -- "W": 1.0,
                -- "IsNormalized": true,
                -- "Size": 1.0,
                -- "SizeSquared": 1.0
              -- },
              -- "Translation": {
                -- "X": 0.0,
                -- "Y": 0.0,
                -- "Z": 0.0
              -- },
              -- "Scale3D": {
                -- "X": 1.0,
                -- "Y": 1.0,
                -- "Z": 1.0
              -- }
            -- },
            -- {
              -- "Rotation": {
                -- "X": 0.0,
end 

function ENT:OverrideMove(flInterval)
    if self.SBAI_MoveStep then
        local name = self.SBAI_MoveStep.MoveArrayName
        local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name]
        local EndTime = CharacterMoveTable.Time
        local CurEndTime = self.SBAI_MoveStep.StartTime + EndTime

        local RootMotionDataPath = CharacterMoveTable.RootMotionDataPath
        RootMotionDataPath = string.GetFileFromFilename(RootMotionDataPath)
        RootMotionDataPath = string.StripExtension(RootMotionDataPath)

        local RootMotion = _G["SB_" .. RootMotionDataPath]

        if RootMotion then
            -- Get the interpolated transform for the current time
            local posOffset, angOffset = self:SBAI_GetRootMotionTransform(RootMotion, self.SBAI_MoveStep.StartTime)

            if posOffset and angOffset then
                -- Initialize previous offsets on the first frame of movement.
                if not self.SBAI_MoveStep.PrevPosOffset then
                    self.SBAI_MoveStep.PrevPosOffset = Vector(0, 0, 0)
                    self.SBAI_MoveStep.PrevAngOffset = Angle(0, 0, 0)
                end

                -- Calculate the change (delta) from the last frame's offsets.
                local posDelta = posOffset - self.SBAI_MoveStep.PrevPosOffset
                local angDelta = angOffset - self.SBAI_MoveStep.PrevAngOffset

                -- Get the entity's current transform, allowing for external changes (e.g., physgun, re-aiming).
                local currentAng = self:GetLocalAngles()
                local currentPos = self:GetPos()

                -- Transform the position delta from local animation space to world space based on the entity's current angle.
                local worldPosDelta = currentAng:Forward() * posDelta.x +
                                       currentAng:Right() * posDelta.y +
                                       currentAng:Up() * posDelta.z

                -- Apply the deltas to the current transform.
                local targetPos = currentPos + worldPosDelta
                local targetAng = currentAng + angDelta

                self:MoveGroundStep(targetPos)
                self:SetAngles(targetAng)

                -- Store the current total offsets for the next frame's calculation.
                self.SBAI_MoveStep.PrevPosOffset = posOffset
                self.SBAI_MoveStep.PrevAngOffset = angOffset
            end
        end

        -- Clear out motion data after it has finished.
        if CurTime() > CurEndTime then
            self.SBAI_MoveStep = nil
        end
    end
end

-- function ENT:CustomRunAI() 
	-- pre check to decide whether to consult Raven's unique BehaviorTree 
	-- local retval = self:SBAI_RunBehavior() 
	-- call scripted_ents.Get("npc_unreali_female").CustomRunAI(self) when appropriate to run Lua schedules 
	-- post check to whether to run base LUASCHED_* tree or Raven's BehaviorTree 
-- end 
-- "AISightSenseVerticalDistance": 500.0, -- this means fallback to LUA Behavior if enemy z distance is this high up or down 
-- "AIDetectCheckDistance": 5000.0, 

-- walkspeed = 150 
-- default weapon: Raven_Blade 
-- attack power: 1600 
-- skill min / max distances and activate cases are in TargetFilterTable.json 

function ENT:SBAI_InitTree()
    -- Deep clone the master tree into a working stack
    self.SBAI_CurBehaviorStack = table.Copy(self.SBAI_BehaviorTree)
end

function ENT:SBAI_SelectTask(taskTable, currentIndex)
    print("***in selecttask", taskTable, currentIndex)
    currentIndex = currentIndex or 1

    for subTaskNum, subTaskTable in ipairs(taskTable) do 
        local objectName = subTaskTable.ObjectName
        local isSelector = objectName and objectName:find("BTComposite_Selector")
        local isSequence = objectName and objectName:find("BTComposite_Sequence")
		
		if skiptasks and subTaskTable._running then
			-- Resume the same child without reevaluating decorators or siblings
			if subTaskTable.StartTask then
				local taskKey, taskData = next(subTaskTable.StartTask)
				local cleanTaskKey = taskKey:gsub("^SBBTTask_", ""):gsub("_%d+$", "")
				local result = self[cleanTaskKey](self, taskData, subTaskTable)
				if result == nil then
					return nil -- still running
				else
					subTaskTable._running = false
					subTaskTable._result = result
					if result == true and isSelector then return true end
					if result == false and isSequence then return false end
				end
			elseif subTaskTable.NextTask then
				local result = self:SBAI_SelectTask(subTaskTable.NextTask, subTaskTable._currentChild or 1)
				if result == nil then return nil end
				subTaskTable._running = false
				subTaskTable._result = result
				if result == true and isSelector then return true end
				if result == false and isSequence then return false end
			end
		end

        print("objectName:", objectName)
		
        -- evaluate decorators
        local allowEntry = true
        local flowAbortMode = nil
        if subTaskTable.Condition then
            for subConditionName, subConditionValues in pairs(subTaskTable.Condition) do
				local bPrevReturn = subConditionValues._result
				
				if subTaskTable._running and !(subTaskTable.bBackgroundTask or false) and bPrevReturn != nil then 
					allowEntry = bPrevReturn 
				else 
				
					local flowMode = subConditionValues.FlowAbortMode
					if flowMode then flowAbortMode = flowMode end

					subConditionName = subConditionName:gsub("^SBBTDecorator_", ""):gsub("_%d+$", "")
					local passed = self[subConditionName](self, subConditionValues)
					subConditionValues._result = passed 
					print("Decorator", subConditionName, "returned", passed)
					if !passed then
						allowEntry = false
						break
					end
				end 
            end
        end
		::postdecorators:: 
        print("allowEntry", allowEntry, flowAbortMode)

        -- flow abort handling (simplified to stateful version)
        if flowAbortMode == "Self" and not allowEntry and self.CurrentBranch == subTaskNum then
            self.CurrentBranch = nil
            return false -- nil 
        elseif flowAbortMode == "LowerPriority" and allowEntry and currentIndex and subTaskNum < currentIndex then
            self.CurrentBranch = subTaskNum
            return self:SBAI_SelectTask({subTaskTable}, subTaskNum)
        elseif flowAbortMode == "Both" then
            if not allowEntry and self.CurrentBranch == subTaskNum then
                self.CurrentBranch = nil
                return false -- nil 
            elseif allowEntry and currentIndex and subTaskNum < currentIndex then
                self.CurrentBranch = subTaskNum
                return self:SBAI_SelectTask({subTaskTable}, subTaskNum)
            end
        end

        if allowEntry then
            if not self.CurrentBranch then self.CurrentBranch = subTaskNum end

            -- LEAF TASK
            if subTaskTable.StartTask then
                for taskKey, taskData in pairs(subTaskTable.StartTask) do
                    local cleanTaskKey = taskKey:gsub("^SBBTTask_", ""):gsub("_%d+$", "")

                    -- run/resume logic
                    if not subTaskTable._running then
                        subTaskTable._running = true
                        subTaskTable._startTime = SysTime()
                    end

                    local result = self[cleanTaskKey](self, taskData, subTaskTable)
                    print(objectName, "returned", result)

                    if result == nil then
                        -- still running, just return nil (state stays in node)
						if taskData.bBackgroundTask then -- is task interruptable by decorators while task is still performing. true to mark as interruptable. false to keep. 
							self.SBAI_bInBackgroundTask = taskData.bBackgroundTask 
						end 
                        return nil
                    else
                        -- finished, clear runtime
                        subTaskTable._running = false
                        subTaskTable._result = result
						self.SBAI_bInBackgroundTask = false 

                        if result == true then
                            if isSelector then return true end -- selector succeeds immediately
                            -- sequence → continue
                        elseif result == false then
                            if isSequence then return false end -- sequence fails immediately
                            -- selector → continue
                        end
                    end
                end

            -- COMPOSITE TASK
            elseif subTaskTable.NextTask then
                local result = self:SBAI_SelectTask(subTaskTable.NextTask, 1)

                if result == nil then
                    -- child branch is running, mark parent running
                    subTaskTable._running = true
                    return nil
                else
                    subTaskTable._running = false
                    subTaskTable._result = result -- true means pass me 

                    if isSelector and result == true then
                        return true
                    elseif isSequence and result == false then
                        return false
                    end
                    -- otherwise continue to next sibling
                end
            end
        end
    end

    print("If no child returned success/running, return false") 
    return false
end

function ENT:SBAI_RunBehavior()
    print("RunBehavior start: SysTime:", SysTime()) 

    -- Ensure we have a runtime tree copy
    if !self.SBAI_CurBehaviorStack then
        print("Cloning behavior tree...")
        self.SBAI_CurBehaviorStack = table.Copy(self.SBAI_BehaviorTree)
    end

    -- Run tick on runtime tree
    local result = self:SBAI_SelectTask(self.SBAI_CurBehaviorStack) 
    print("BehaviorTree tick finished with result:", result, self.CurrentSBTask)

    -- If resolved (true/false), discard runtime so next tick restarts fresh
    if result != nil then
        print("Clearing runtime behavior stack")
        self.SBAI_CurBehaviorStack = nil
    end 

    print("RunBehavior end: SysTime:", SysTime()) 
	return result 
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
	if act == ACT_IDLE then return ACT_HL2MP_IDLE_MELEE_ANGRY end 
	if act == ACT_IDLE_ANGRY then return ACT_HL2MP_IDLE_MELEE_ANGRY end 
	if act == ACT_WALK then return ACT_MP_WALK_MELEE end 
	if IsValid(self:GetActiveWeapon()) then 
		if self:GetActiveWeapon():GetHoldType() == "melee" and act == ACT_WALK then 
			return ACT_MP_WALK_MELEE 
		end 
	end 
end 

function ENT:NPC_ShouldConductBehaviorTree() 
	-- likely performing a skill 
	if self:GetCurrentSchedule() == SCHED_SCENE_GENERIC then -- may be in a skill task 
		if self.scriptActivity then 
			return true 
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
	-- definitely not a CBaseCombatCharacter in a vehicle, or a CBaseHelicopter 
	if self:GetNPCState() == NPC_STATE_DEAD then return false end 
	return true 
end 

function ENT:NPC_ShouldBlockRunAI() 
	if self:NPC_ShouldConductBehaviorTree() then return true end 
	return scripted_ents.Get("npc_unreali_female").NPC_ShouldBlockRunAI(self) 
end 

function ENT:CustomRunAI() 
	if self:NPC_ShouldConductBehaviorTree() then 
		return self:SBAI_RunBehavior(), self:NPC_MaintainActivity() 
	end 
	local retVal = scripted_ents.Get("npc_unreali_female").CustomRunAI(self) 
	-- self:DoSchedule( self.CurrentSchedule ) 
end 

-- FlowAbortMode: 
-- LowerPriority: If the condition becomes true, the Behavior Tree will abort any currently running tasks in lower-priority branches. It does not abort the current branch where the decorator lives.
-- Self: interrupt current task when decorator meets criteria. proceeds to next tasks   
-- Both: LowerPriority + Self: abort current task and nexttasks whenever this meets true. isalive check 
-- None: do not interrupt task structure, leaving Condition useless 

-- conditions 
function ENT:SbAggroLevel(tbl)
    local arr = tbl.CompareAggroLevelArray
    if not arr then return false end

    -- Defensive: ensure we can iterate
    if type(arr) != "table" then
        arr = { arr }
    end

    for _, level in ipairs(arr) do

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
	if !isbool(tbl.bReturnSucceeded) then -- decorators don't have bReturnSucceeded, attempt to retrieve from blackboard 
		local CheckValue = tbl.KeyName 
		local testvalue = tbl.IntValue or 1 -- 1 means true 
		local CompareOP = tbl.CompareOP or "Equal" 
		Entity(1):ChatPrint("retrieving from SBBlackBoard: "..CheckValue.." "..tostring(testvalue).." "..CompareOP) 
		local lookup = self.SBAI_BlackBoard[CheckValue] or 0 -- do not compare nil 
		
		if CompareOP == "Equal" then 
			result = testvalue == lookup 
		elseif CompareOP == "LessOrEqual" then 
			result = testvalue <= lookup 
		elseif CompareOP == "Greater" then 
			result = testvalue > lookup 
		elseif CompareOP == "GreaterOrEqual" then 
			result = testvalue >= lookup 
		elseif CompareOP == "Less" then 
			result = testvalue < lookup 
		elseif CompareOP == "NotEqual" then 
			result = testvalue != lookup 
		end 
	return result 
	
	else -- task, save KeyName 
		Entity(1):ChatPrint("saving to SBBlackBoard: "..tbl.KeyName..tostring(tbl.IntValue)..tbl.CompareOP) 
		self.SBAI_BlackBoard[tbl.KeyName] = tbl.IntValue 
		return tbl.bReturnSucceeded 
	end 
	
end -- key - value retriever 

function ENT:SbCheckActorEffect(tbl)
    local ActorType          = tbl.ActorType or "Self"
    local EffectAlias        = tbl.EffectAlias
    local OrCheckArray       = tbl.OrCheck_EffectAliasArray or {}
    local bActive            = tbl.bActive 
    local bInverseCondition  = tbl.bInverseCondition or false

    -- if decorator disabled, always allow
    if bActive == false then return false end

    -- resolve actor
    local ent
    if ActorType == "Target" then
        ent = self:GetEnemy()
    elseif ActorType == "Self" then
        ent = self
    elseif ActorType == "Owner" then
        ent = self:GetOwner()
    elseif ActorType == "SubTarget" then
        for _, subent in pairs(self:GetKnownEnemies() or {}) do
            if IsValid(subent) and subent != self:GetEnemy() then
                ent = subent
                break
            end
        end
    end
    if !IsValid(ent) then return false end

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
    for _, eff in ipairs(effectsToCheck) do
        -- normal alias checks
        if ent.SbEffectAlias and ent.SbEffectAlias[eff] then
            hasEffect = true
        elseif ent.EffectAliasArray then
            for _, eff2 in ipairs(ent.EffectAliasArray) do
                if eff2 == eff then
                    hasEffect = true
                    break
                end
            end
        end

        -- post check wrapper: if ENT has a function named after the effect alias, call it 
        local fn = self[eff]
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
	local CheckStat = tbl.CheckStat -- ActorStatType_AttackSpeed       ActorStatType_StaminaAttackPower        ActorStatType_CriticalPercentage        ActorStatType_HitDefenseLevel   ActorStatType_ShieldIgnorePercentage    ActorStatType_CriticalValueRate ActorStatType_ShieldRegenPerSecond      ActorStatType_AdditiveSkillDamageRate   ActorStatType_ShieldRegenPerSecondRate  ActorStatType_ShieldRegenPerSecondValue ActorStatType_ShieldRegenPerSecondWhenBattleValue       ActorStatType_ShieldRegenPerSecondWhenBattle    ActorStatType_StaminaRegenPerSecond     ActorStatType_ShieldRegenPerSecondWhenBattleRate        ActorStatType_HPRegenPerSecondValue     ActorStatType_HPRegenPerSecond  ActorStatType_SmallWeightTypeDamageAdditiveRate ActorStatType_HPRegenPerSecondRate      ActorStatType_RangeAttackDamageAdditiveRate     ActorStatType_LargeWeightTypeDamageAdditiveRate ActorStatType_RangeAttackDamageReductionRate    ActorStatType_MeleeAttackDamageReductionRate    ActorStatType_GroggyStateDamageAdditiveRate     ActorStatType_DownStateDamageAdditiveRate       ActorStatType_FireAttributeDamageReductionRate  ActorStatType_AirborneStateDamageAdditiveRate   ActorStatType_LightningAttributeDamageReductionRate     ActorStatType_IceAttributeDamageReductionRate   ActorStatType_BetaGaugeAdditiveRate     ActorStatType_PoisonAttributeDamageReductionRate        ActorStatType_LowHpDamageAdditiveRate   ActorStatType_AdditiveFixedDamage       ActorStatType_DOTDamageAdditiveRate     ActorStatType_HighHpDamageAdditiveRate  ActorStatType_TachyGaugeReduceConsumeRate       ActorStatType_TachyGaugeAdditiveGainRate        ActorStatType_FinalShieldDamageReduceRate       ActorStatType_FinalHPDamageReduceRate   ActorStatType_AdditiveSkillDamageGroup1 ActorStatType_Luck      ActorStatType_AdditiveSkillDamageGroup3 ActorStatType_AdditiveSkillDamageGroup2 ActorStatType_AdditiveSkillDamageGroup5 ActorStatType_AdditiveSkillDamageGroup4 ActorStatType_AdditiveSkillDamageGroup7 ActorStatType_AdditiveSkillDamageGroup6 ActorStatType_AdditiveSkillDamageGroup9 ActorStatType_AdditiveSkillDamageGroup8 ActorStatType_DrainHpByAttackPowerRate  ActorStatType_AdditiveSkillDamageGroup10        ActorStatType_SprintableStaminaValue    ActorStatType_DrainHpFixedValue ActorStatType_ItemStackBullet1  ActorStatType_ItemStackRecoveryPotion   ActorStatType_ItemStackBullet3  ActorStatType_ItemStackBullet2  ActorStatType_ItemStackBullet5  ActorStatType_ItemStackBullet4  ActorStatType_ItemStackConsumable1      ActorStatType_ItemStackBullet6  ActorStatType_ItemStackConsumable3      ActorStatType_ItemStackConsumable2      ActorStatType_ItemStackConsumable5      ActorStatType_ItemStackConsumable4      
	local CheckValue = tbl.CheckValue -- 60.0, 
	local CompareOP = tbl.CompareOP -- Greater 
	local bRateValue = tbl.bRateValue or false -- true 
	local NodeName = tbl.NodeName -- SB_CheckActorStat(HP>60) 
	-- handle only ActorStatType_HP for now 
	local testvalue, result 
	if CheckStat == "ActorStatType_HP" then 
		testvalue = self:Health() 
		testvalue = (testvalue / self:GetMaxHealth()) * 100 
	else 
		testvalue = 0 
	end 
	if CompareOP == "Equal" then 
		result = testvalue == CheckValue 
	elseif CompareOP == "LessOrEqual" then 
		result = testvalue <= CheckValue 
	elseif CompareOP == "Greater" then 
		result = testvalue > CheckValue 
	elseif CompareOP == "GreaterOrEqual" then 
		result = testvalue >= CheckValue 
	elseif CompareOP == "Less" then 
		result = testvalue < CheckValue 
	elseif CompareOP == "NotEqual" then 
		result = testvalue != CheckValue 
	end 
	-- print("ActorStat check", CheckStat, testvalue, CompareOP, CheckValue, "=>", result) 
	return result 
end 

function ENT:SbCheckStance(tbl) -- M_Raven_Phase2, M_Raven_Default 
	if true then 
		return "M_Raven_Default" == tbl.StanceName 
	end 
	return self.StanceName == tbl.StanceName 
end 

function ENT:SbDetectResult(tbl) 
	-- AIDetectResult_NotDetect AIDetectResult_Observe AIDetectResult_Doubt	AIDetectResult_Detect 
	local CompareDetectResult = tbl.CompareDetectResult 
	-- right now, check whether there is an enemy (AIDetectResult_Detect) 
	-- print("SbDetectResult will directly return true") 
	return IsValid(self:GetEnemy()) 
end 

function ENT:SbDistanceToTarget(tbl) -- distance to enemy 
	if !self.enemyDist then return false end 
	local dist = tbl.Distance 
	local operator = tbl.CompareOP -- LessOrEqual, Greater, GreaterOrEqual, Equal, Less, NotEqual 
	local FlowAbortMode = tbl.FlowAbortMode or "None" 
	local result 
	if operator == "Equal" then 
		result = self.enemyDist == dist 
	elseif operator == "LessOrEqual" then 
		result = self.enemyDist <= dist 
	elseif operator == "Greater" then 
		result = self.enemyDist > dist 
	elseif operator == "GreaterOrEqual" then 
		result = self.enemyDist >= dist 
	elseif operator == "Less" then 
		result = self.enemyDist < dist 
	elseif operator == "NotEqual" then 
		result = self.enemyDist != dist 
	end 
	print("DistanceToTarget:",dist,operator,FlowAbortMode) 
	return result 
end 

function ENT:SbIsAlive(tbl) 
	local ActorType = tbl.ActorType -- Target, Self, SubTarget, Owner. Default: Self 
	local CheckType = tbl.CheckType -- Coma, Dead, Alive. Default: Alive 
	-- print("ActorType",ActorType) 
	local ent = self 
	if ActorType == "Target" then 
		ent = self:GetEnemy() 
	elseif ActorType == "Self" then 
		ent = self 
	elseif ActorType == "Owner" then 
		ent = self:GetOwner() 
	-- print(self, "checking ent:",ent) 
	elseif ActorType == "SubTarget" then 
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
	
    if CheckType == "Coma" then
        return IsValid(ent) and ent:GetInternalVariable("m_lifeState") == 1
    elseif CheckType == "Dead" then
        return IsValid(ent) and not ent:Alive()
    elseif CheckType == "Alive" then
        return IsValid(ent) and ent:Alive()
    end

    return false
end 

function ENT:SbRandom(tbl) 
	local RandomRange = math.random(0,tbl.RandomRange) 
	local CheckValue = tbl.CheckValue 
	local operator = tbl.CompareOP -- LessOrEqual, Greater, GreaterOrEqual, Equal, Less, NotEqual 
	local result 
	if operator == "Equal" then 
		result = RandomRange == CheckValue 
	elseif operator == "LessOrEqual" then 
		result = RandomRange <= CheckValue 
	elseif operator == "Greater" then 
		result = RandomRange > CheckValue 
	elseif operator == "GreaterOrEqual" then 
		result = RandomRange >= CheckValue 
	elseif operator == "Less" then 
		result = RandomRange < CheckValue 
	elseif operator == "NotEqual" then 
		result = RandomRange != CheckValue 
	end 
	return result 
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
    local cycle      = self.SBAI_Timers[KeyName.."_Cycle"]

    if expireTime then
        if CurTime() < expireTime then
            -- Timer still active → block this branch
            return false
        else
            -- Timer expired
            if cycle and cycle > 0 then
                -- Auto - rearm: push expiry forward by cycle time
                self.SBAI_Timers[KeyName] = CurTime() + cycle
                return false  -- still blocked this tick, will open next time
            end
        end
    end

    -- No timer or expired with no cycle → allow entry
    return true
end


-- skills 

function ENT:SbCautionToTarget(tbl) 
	local MaxDistance = tbl.MaxDistance 
	local SetMoveType = tbl.SetMoveType 
	local SideMoveMaxDistance = tbl.SideMoveMaxDistance 
	local SideMoveMinDistance = tbl.SideMoveMinDistance 
	local WaitCheckTime = tbl.WaitCheckTime 
	local WaitCountByGroup = tbl.WaitCountByGroup 
	local bIgnoreRestartSelf = tbl.bIgnoreRestartSelf 
	local bLockOn = tbl.bLockOn 
	-- create random route 
	-- set walk type 
	-- now delay 
	local waitTime = tbl.WaitCheckTime or 0
    local returnSucceeded = tbl.bReturnSucceeded or false
	-- if tbl.finished then return true end 

    if !tbl.startTime then -- TASKSTATUS_NEW 
        tbl.startTime = CurTime() 
		-- self:StartSchedule(LUASCHED_RANDOM_NONAV_GO) 
		-- self.flMaxTasksRun = 10 
		-- self:DoSchedule(self.CurrentSchedule) 
		self.bTaskComplete = false 
		self:TASK_FIND_RANDOM_PATH(500) 
		self:ChainStartTask("TASK_SET_TOLERANCE_DISTANCE",48) 
		self:ChainStartTask("TASK_SET_ROUTE_SEARCH_TIME",3) 
		self:ChainStartTask("TASK_GET_PATH_TO_LASTPOSITION",1) 
		self:ChainStartTask("TASK_WALK_PATH",48) 
		self:ResetIdealActivity(ACT_MP_WALK_MELEE) 
    end
	self:SetMovementActivity(ACT_MP_WALK_MELEE) -- do the cautious move 
    local elapsed = CurTime() - tbl.startTime
    -- print("in SbCautionToTarget", elapsed, waitTime)

    if elapsed < waitTime then
        return nil -- still running
    else
		tbl.finished = true 
		-- Entity(1):ChatPrint("SbCautionToTarget: finishing "..tbl.startTime) 
		-- tbl.startTime = nil
		-- if true then return true end -- temporary: remove this when branch selection issues are solved 
        if returnSucceeded then
            return true  -- wait succeeded
        else
            return false -- wait failed
        end
    end
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
	
	return IsValid(self:GetEnemy()) 
end 

function ENT:SbMoveToTarget(tbl) 
	local MoveState = tbl.MoveState
	local DistanceOfApproach = tbl.DistanceOfApproach -- i think this means walk until distancetoenemy < 250 
	local bBackgroundTask = tbl.bBackgroundTask
	local NodeName = tbl.NodeName 
	if self.CurrentSchedule then 
		if IsValid(self:GetEnemy()) then 
			if self.CurrentSchedule.DebugName != "LUASCHED_CHASE_ENEMY" then 
				self:StartSchedule(LUASCHED_CHASE_ENEMY) 
			end 
		else 
			if self.CurrentSchedule.DebugName != "LUASCHED_PATROL_WALK" then 
				self:StartSchedule(LUASCHED_PATROL_WALK) 
			end 
		end 
	end 
	-- tbl.StartPos = tbl.StartPos or self:GetEnemyLastKnownPos() 
	if self.enemyDist < 250 then return true end -- moved away from task start pos by 250 units 
end 

function ENT:SbUseEffect(tbl) -- add effect 
	local bSelfActor = tbl.bSelfActor 
	local EffectAlias = tbl.EffectAlias 
	local target = self:GetEnemy() 
	if bSelfActor then target = self end 
	if IsValid(target) then 
		target.SbEffectAlias[target] = CurTime() 
	end 
end 

-- SbUseSkill 
-- indices in tbl contain skill names, [1]	=	M_Raven_ParryPreview1 
-- skill names are looked up from SkillCommandTable.json, "M_Raven_ParryPreview1": {"SkillAlias": "M_Raven_ParryPreview1"} 
-- looked up skill's SkillAlias is called from SkillTable.json, "M_Raven_ParryPreview1": {
-- TargetFilterAlias is activated in TargetFilterTable, "TargetFilterAlias": "M_Raven_ParryPreview1_Target", 
-- FirstSkillActiveAlias is activated in SkillActiveStepTable, "FirstSkillActiveAlias": "M_Raven_ParryPreview1_Cast1"} 
-- FirstSkillActiveAlias contains dir to animation data in FirstSkillActiveAlias, "ShowPath": "CH_M_NA_53_Raven/Skill/M_Raven_ParryPreview" 
-- inside anim metadata, actual animation exists in SBShowAnimKey's Properties["AnimResourcePath"] = "/Game/Art/Character/Monster/CH_M_NA_53/Animation/M_Raven_BurstAreaSlashEnd" 
function ENT:SbUseSkill(tbl) 
	-- PrintTable(tbl) 
	-- [1]	=	M_Raven_ParryPreview1
	-- ["bUsePostStep"]	=	true
	-- ["bUseSkillCommand"]	=	true
	
	-- temp build to play 
	self:StopMoving(true) 
	self:ClearGoal() 
	if !tbl.Started then 
		Entity(1):ChatPrint("starting skill") 
		for k,v in RandomPairs(tbl) do 
			if isnumber(k) then -- do not accidentally start variables 
				-- local bHasActivity = self:LookupSequence(v) 
				-- if bHasActivity then 
				-- end 
				if v == "M_Raven_ParryPreview1" then 
					-- self:ResetIdealActivity(ACT_SPECIAL_ATTACK1) 
					self:NPC_StartScriptedActivity("M_Raven_Parry",true) 
				end 
				local SkillCommandTable = SB_SkillCommandTable[1].Rows[v] 
				local SkillNameFromSkillCommandTable = SkillCommandTable.SkillAlias 
				local SkillTable = SB_SkillTable[1].Rows[SkillNameFromSkillCommandTable] 
				local SkillNameFromSkillTable = SkillTable.FirstSkillActiveAlias 
				local FirstSkillActiveAlias = SB_SkillActiveStepTable[1].Rows[SkillNameFromSkillTable] 
				-- look up skill from SkillCommandTable 
				tbl.Started = true 
			end 
		end 
	end 
	if tbl.Started then 
		if self:IsSequenceFinished() then 
			Entity(1):ChatPrint("task complete") 
			self:NPC_StopScriptedActivity() 
			return true 
		end 
	end 
	return nil 
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

    return "Success"
end


function ENT:SbWait(data)
    local waitTime = data.WaitTime or 0
    local returnSucceeded = data.bReturnSucceeded or false

    if !data.startTime then
        data.startTime = SysTime()
    end

    local elapsed = SysTime() - data.startTime
    print("in SbWait", elapsed, waitTime)

    if elapsed < waitTime then
        return nil -- still running
    else
		if true then return true end -- temporary: remove this when branch selection issues are solved 
        data.startTime = nil
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
function ENT:SbWaitTimeRandom(data) -- only in tachy ai 
	local MinTime = data.MinTime 
	local MaxTime = data.MaxTime 
	local bReturnSucceeded = data.bReturnSucceeded 
end 

function ENT:Item_Resurrection_Ground(ent) return false end 
function ENT:M_Raven_BetaCounterGrab_HitE(ent) return false end 
function ENT:LV_FinishQTE_FailDown(ent) return false end 

