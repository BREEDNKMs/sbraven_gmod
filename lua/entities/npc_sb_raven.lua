AddCSLuaFile() 

-- Define the path to your JSON file relative to the "garrysmod" folder.
print(SysTime()) 
IterativeHybridMoveLimit = include("includes/custommoveprobe.lua") 
include("includes/raven_soundscripts.lua") 
include("includes/curframe.lua") 
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
            return _G[globalTableName] 
        end

        local jsonString = file.Read(relativePath, "GAME")
        if not jsonString then
            ErrorNoHalt(string.format("[SB Importer] Failed to read file for '%s'! Check path: %s\n", globalTableName, relativePath))
            return
        end

        local tempTable = util.JSONToTable(jsonString,false)
        if not tempTable then
            ErrorNoHalt(string.format("[SB Importer] Failed to parse JSON for '%s'! File may be malformed: %s\n", globalTableName, relativePath))
            return
        end

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

SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/SkillTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/SkillCommandTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/SkillActiveStepTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/SkillResultTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/EffectTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/TargetFilterTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/CharacterAnimSetTable.json")
SB_ImportJSON("addons/sbraven/data_static/SB/Content/Local/Data/CharacterMoveTable.json")

print(SysTime()) 

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
ENT.NPC_PainSound 	= "NPC_Raven.PainSound" 
ENT.NPC_PainSoundWater 	= "Unreali_Female.HurtUnderWater" 
ENT.npc_health 		= 248304 -- "MaxHP": 248304, "MaxShield": 4805, 
ENT.npc_model		= "models/alvaroports/sbraven2.mdl" 
ENT.PhysicAttackPower = 1600  
ENT.bHasInnateMelee1 = false 
ENT.m_fMaxYawSpeed = 360 -- "RotateAnglePerSecond": 360.0, 
ENT.SBAI_BlackBoard = { } 
ENT.SBAI_bInBackgroundTask = false 
ENT.SbEffectAlias = { } 
ENT.SBAI_ActiveSkill = { } 
ENT.SBAI_ActiveShow = { } 
ENT.SBAI_SkillTimers = { } 
ENT.CharacterSoundSetPath = "addons/sbraven/data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_53_Raven.json" 
SB_ImportJSON(ENT.CharacterSoundSetPath) 

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

function ENT:SBAI_SetSkillStep(strSkill) 
	local SkillStepTable = SB_SkillActiveStepTable[1].Rows[strSkill]
    if not SkillStepTable then
        self.SBAI_ActiveSkill = {} -- Clear active skill if the next step is invalid
        return
    end

    -- Store the current skill step's data
    self.SBAI_ActiveSkill = { Name = strSkill, Time = CurTime(), Data = SkillStepTable }

    -- [NEW] Handle `bRetargeting`: Lock onto the current target if false
    if SkillStepTable.bRetargeting == false then
        self.SBAI_ActiveSkill.LockedTarget = self:GetEnemy()
    else
        -- If retargeting is allowed, ensure no previous target is locked
        self.SBAI_ActiveSkill.LockedTarget = nil
    end

    -- [NEW] Handle `StopSelfMove`: Stop the NPC from moving if true
    if SkillStepTable.StopSelfMove then
        self:StopMoving(true)
        self:ClearGoal()
    end

    -- [NEW] Handle initial `bLookAtTarget`: Turn to face the target at the start of the step
    if SkillStepTable.bLookAtTarget then
        local target = self.SBAI_ActiveSkill.LockedTarget or self:GetEnemy()
        if IsValid(target) then
            local angleToTarget = (target:GetPos() - self:GetPos()):Angle().y
            self:SetIdealYawAndUpdate(angleToTarget, -1) -- -1 for automatic turn speed
        end
    end

    -- Apply the animation/movement for this step
    local SelfMoveAliasArray = SkillStepTable.SelfMoveAliasArray
    for _, SelfMoveAlias in pairs(SelfMoveAliasArray) do
        self:SBAI_SetMoveTable(SelfMoveAlias)
    end
	-- activate TargetMoveAliasArray on target 
	
	-- activate ShowPath "ShowPath": "CH_M_NA_53_Raven/Skill/M_Raven_Slash", 
	if SkillStepTable.ShowPath != "None" then 
		local showpath = "addons/sbraven/data_static/SB/Content/Art/Show/" 
		showpath = showpath..SkillStepTable.ShowPath..".json" 
		-- SB_ImportJSON(showpath) 
		-- local showname = string.GetFileFromFilename( showpath ) 
		-- showname = string.StripExtension(showname) 
		-- showname = "SB_"..showname 
		-- for _,animpaths in pairs(_G[showname]) do 
			-- if animpaths.Type == "SBShowAnimKey" then 
				-- local Target = animpaths.Properties.Target 
				-- if !Target then -- may not preexist 
					-- Target = "ESBShowActorTarget::ShowActorTarget_MainActor" 
				-- end 
				-- if Target == "ESBShowActorTarget::ShowActorTarget_MainActor" then 
					-- print(animpaths) 
					-- local anim = animpaths.Properties.AnimResourcePath 
					-- anim = string.GetFileFromFilename(anim) 
					-- self:NPC_StartScriptedActivity(anim,true) 
				-- elseif Target == "ESBShowActorTarget::ShowActorTarget_OtherActor" then 
					-- -- play interaction, not handled yet 
					-- -- because target entity most likely doesn't have any of those anims 
				-- end 
			-- end 
		-- end 
		-- print("showname:",showname) 
		self:SBAI_SetShow(showpath) 
	end 
	if #SkillStepTable.UsableTargetProjectileAliasArray > 0 then 
		for i = 1,#SkillStepTable.UsableTargetProjectileAliasArray do 
			local event,etime,cycle,types,options 
			self:NPC_RangedAttack(event,etime,cycle,types,options) 
		end 
	end 
	-- play animations stored as SBShowAnimKey_0 
	
end 

function ENT:SBAI_SetShow(showpath) 
	print("showpath:",showpath) 
	SB_ImportJSON(showpath) 
	self.SBAI_ActiveShow = {["Time"] = CurTime()} 
	self.SBAI_ActiveShow = {["RunTime"] = CurTime()} 
	self.SBAI_ActiveShow.Dir = showpath 
	local showname = string.GetFileFromFilename( showpath ) 
	showname = string.StripExtension(showname) 
	self.SBAI_ActiveShow.Name = showname 
	self.SBAI_ActiveShow.Frame = 0 
	self.SBAI_ActiveShow.Stopped = false 
	showname = "SB_"..showname 
	self:SBAI_MaintainShow2() 
	-- for _,animpaths in pairs(_G[showname]) do 
		-- if animpaths.Type == "SBShowAnimKey" then 
			-- local Target = animpaths.Properties.Target 
			-- if !Target then -- may not preexist 
				-- Target = "ESBShowActorTarget::ShowActorTarget_MainActor" 
			-- end 
			-- if Target == "ESBShowActorTarget::ShowActorTarget_MainActor" then 
				-- print(animpaths) 
				-- local anim = animpaths.Properties.AnimResourcePath 
				-- anim = string.GetFileFromFilename(anim) 
				-- self:NPC_StartScriptedActivity(anim,true) 
			-- elseif Target == "ESBShowActorTarget::ShowActorTarget_OtherActor" then 
				-- -- play interaction, not handled yet 
				-- -- because target entity most likely doesn't have any of those anims 
			-- end 
		-- end 
	-- end 
	return showname -- return true on animation play, false on not play 
end 

function ENT:SBAI_MaintainShow2()
	if !self.SBAI_ActiveShow or self.SBAI_ActiveShow.Stopped then return end
	if !self.SBAI_ActiveShow.Name then return end -- table not ready 
	local showname = "SB_" .. self.SBAI_ActiveShow.Name
	local showdata = _G[showname]
	if not showdata then return end

	-- Find SBShowData entry
	local showEntry
	for _, data in pairs(showdata) do
		if data.Type == "SBShowData" then
			showEntry = data
			break
		end
	end
	if not showEntry then return end

	local props = showEntry.Properties
	local endTime = props.EndTime or 0
	if endTime <= 0 then return end

	-- Find max key (defines last frame index)
	local maxKey = 0
	for _, container in ipairs(props.KeyContanerMap or {}) do
		local k = tonumber(container.Key) or 0
		if k > maxKey then
			maxKey = k
		end
	end
	if maxKey <= 0 then return end

	-- Progress time by interval 
	local Elapsed = CurTime() - self.SBAI_ActiveShow.RunTime 
	self.SBAI_ActiveShow.Elapsed = (self.SBAI_ActiveShow.Elapsed or 0) + Elapsed -- or self:GetAnimTimeInterval() once efficiency issues are solved  
	self.SBAI_ActiveShow.RunTime = CurTime() 

	-- Normalize to cycle [0..1]
	local cycle = math.Clamp(self.SBAI_ActiveShow.Elapsed / endTime, 0, 1)

	-- Convert cycle to frame index (0..maxKey)
	local currentFrame = math.max(1, math.floor(cycle * maxKey + 0.5))

	-- Get previous frame
	local prevFrame = self.SBAI_ActiveShow.Frame or -1
	-- If frame didn’t advance, do nothing
	if currentFrame <= prevFrame then 
		if maxKey != 1 then 
			return 
		end 
	end 

	-- Update to current frame
	self.SBAI_ActiveShow.Frame = currentFrame

	-- Iterate through skipped frames (inclusive)
	for f = prevFrame + 1, currentFrame do
		for _, container in ipairs(props.KeyContanerMap or {}) do
			local keyIndex = tonumber(container.Key)
			if keyIndex and keyIndex == f then
				local val = container.Value
				if val and val.Keys then
					for _, k in ipairs(val.Keys) do
						if k.ObjectName then
							local short = k.ObjectName:match(":(.-)'?$") or k.ObjectName
							Entity(1):ChatPrint("[SBAI-ShowData] Triggered Key: " .. short .. " at frame " .. f)

							-- resolve this ObjectName to its actual data table from showdata
							local targetKey
							for _, data in ipairs(showdata) do
								if data.Name == short then
									targetKey = data
									break
								end
							end

							-- if found, act based on its Type
							if targetKey and targetKey.Type == "SBShowAnimKey" then
								local Target = targetKey.Properties.Target 
								if not Target then 
									Target = "ESBShowActorTarget::ShowActorTarget_MainActor"
								end

								if Target == "ESBShowActorTarget::ShowActorTarget_MainActor" then
									local anim = targetKey.Properties.AnimResourcePath 
									anim = string.GetFileFromFilename(anim)
									self:NPC_StartScriptedActivity(anim, true)
								elseif Target == "ESBShowActorTarget::ShowActorTarget_OtherActor" then
									-- handle interaction case
									print("[SBAI-ShowData] OtherActor anim:", targetKey.Properties.AnimResourcePath)
									-- leave for you to implement
								end
							elseif targetKey and (targetKey.Type == "SBShowSoundKey" or targetKey.Type == "SBShowCharSESoundKey") then 
								-- initialize template soundscript 
								local CuePath 
								
								if targetKey.Type == "SBShowCharSESoundKey" then 
									print("looking up:",targetKey.Properties.CharacterReactKey) 
									local key = targetKey.Properties.CharacterReactKey or targetKey.Properties.CharacterVoiceKey 
									PrintTable(targetKey) 
									CuePath = self:SBAI_LookupCharacterSound(key) 
									print(CuePath) 
									CuePath = CuePath.ObjectPath 
									CuePath = string.gsub(CuePath,"/L10N/[^/]+", "")
								else 
									CuePath = targetKey.Properties.SoundSoftObject 
									if CuePath then 
										CuePath = CuePath.AssetPathName 
									else -- property may be named "Sound" 
										CuePath = targetKey.Properties.Sound 
										CuePath = CuePath.ObjectPath 
									end 
								end 
								print("CuePath:",CuePath,"TargetKey:",targetKey.Type) 
								CuePath = string.sub(CuePath,6) 
								CuePath = "addons/sbraven/data_static/SB/Content"..CuePath 
								CuePath = string.StripExtension(CuePath) 
								CuePath = CuePath..".json" 
								local SoundScript = self:SBAI_BuildSoundScript(CuePath) 
								-- print("got soundscript") 
								PrintTable(SoundScript) 
								if SoundScript.Delay and SoundScript.Delay != 0 then 
									timer.Simple(SoundScript.Delay,function() self:EmitSound(SoundScript.SoundPath,100,SoundScript.Pitch,SoundScript.Volume) end) 
								else 
									self:EmitSound(SoundScript.SoundPath,100,SoundScript.Pitch,SoundScript.Volume) 
								end 
								-- targetKey.Properties.SoundSoftObject.AssetPathName = "/Game/Sound/Skill/Monster/Raven/M_Raven_Cloth_XL3_Cue.M_Raven_Cloth_XL3_Cue"
								-- send to cue file handler 
								-- handler will navigate through items and fill a table formed like soundscript 
								-- and return the filled table here 
							end 
						end
					end
				end
			end
		end
	end
	-- Auto-stop if exceeded duration
	if self.SBAI_ActiveShow.Elapsed >= endTime then
		self.SBAI_ActiveShow.Stopped = true
		return
	end
end 

function ENT:SBAI_LookupCharacterSound(key) 
	key = string.upper(key) 
	local CharacterSoundSet = string.GetFileFromFilename(string.StripExtension(self.CharacterSoundSetPath)) 
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

function ENT:SBAI_BuildSoundScript(parsedjson)
	if not istable(parsedjson) then
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
		pcall(function() SoundScript.SoundPath = result.SoundPath end)
	end

	return SoundScript
end



function ENT:Think() 
	self:SBAI_MaintainShow2() 
	return scripted_ents.Get("npc_unreali_female").Think(self) 
end 

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

function ENT:SBAI_CheckSkillHit(SkillStepTable,bEveryFrameHitCheck) 
	local ID = SkillStepTable.ID 
	-- trace attack from weapon / radius / sphere / whatever is AttackDirection and deal damage 
	-- for now, do default damage action 
	local event,etime,cycle,types,options = util.GetAnimEventIDByName("EVENT_WEAPON_MELEE_HIT"), CurTime(), self:GetCycle(), 0, self.PhysicAttackPower 
	-- adjust melee damage depending on step options 
	options = options * SkillStepTable.SkillAttackDamageRate
	local enemy = self:GetEnemy() 
	if !IsValid(self:GetEnemy()) then -- pick random enemy 
		if #self:GetKnownEnemies() > 0 then 
			enemy = self:GetKnownEnemies()[1] 
		end 
	end 
	local tableofhittargets 
	if IsValid(enemy) then 
		local curHealth = enemy:Health()
		tableofhittargets = self:NPC_MeleeAttack(event,etime,cycle,types,options)
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
			local ai_block_damage = enemy:IsNPC() and cvars.Bool("ai_block_damage") 

			-- Condition 2: The enemy has God Mode enabled.
			local isGodMode = enemy:IsFlagSet(FL_GODMODE)

			-- Condition 3: The enemy's internal takedamage variable is set to 0 (D_HT_NO) or less.
			-- (or 1) is a safeguard in case the variable is missing, defaulting to a state that takes damage.
			local takeDamageDisabled = (enemy:GetInternalVariable("m_takedamage") or 1) < 1

			-- Condition 4: The actual damage applied was less than 10% of what was intended.
			local lowDamage = damagePercentage < 0.1

			if playerHookBlocked or isGodMode or takeDamageDisabled or lowDamage or ai_block_damage then
				bDamageBlocked = true
			end
		end
	else 
		tableofhittargets = self:NPC_MeleeAttack(event,etime,cycle,types,options) 
	end 
    --- END: Added Damage Check Logic ---

	for k,v in pairs(tableofhittargets) do 
		if IsValid(v) and v != self then 
			local Disposition = self:Disposition(v) 
			if Disposition == D_HT or Disposition == D_FR then 
				if SkillStepTable.SkillResultAlias then -- applied on self and target 
					-- self:SBAI_SetSkillStep() 
				end 
				
				if SkillStepTable.NextStepAliasWhenParry != "None" then -- player blocked your attack. 
				-- this will be reinterpreted as: trace attack to GetEnemy hit something else 
				end 
				
				if SkillStepTable.NextStepAliasWhenParryJust != "None" then -- interpret as: getenemy is invincible or total damage is lesser than %10 
					if bDamageBlocked then 
						self:SBAI_SetSkillStep(SkillStepTable.NextStepAliasWhenParryJust) 
					end 
				end 
				
				if SkillStepTable.NextStepAliasWhenPerfectParry != "None" then -- player performed parry right at HitTime 
				-- this will be reinterpreted as: GetEnemy damaged us right at hit event 
				-- implemented in ON_LIGHT_DAMAGE 
				end 
				
				if SkillStepTable.NextStepAliasWhenSuperParry != "None" then 
				
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
					self:SBAI_SetSkillStep(SkillStepTable.NextStepAliasWhenHit)
				end 
			end 
		end 
	end 
	if bEveryFrameHitCheck then 
		timer.Simple(0.01,function() 
			if IsValid(self) then 
				local NextStepTable = self.SBAI_ActiveSkill.Name -- check to see whether Name has changed 
				print("next step is:",NextStepTable) 
				if !NextStepTable or NextStepTable == "None" then return end 
				NextStepTable = SB_SkillActiveStepTable[1].Rows[NextStepTable] 
				if ID == NextStepTable.ID then -- maintain loop as long as ID is same 
					self:SBAI_CheckSkillHit(SkillStepTable,true) 
				end 
			end 
		end) 
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

--==============================================================================
-- HELPER: Curve Loading and Evaluation
--==============================================================================
--[[
    Loads a CurveFloat JSON file by parsing the specific path format from the move tables.
    @param curveDataPath The raw path string from the CharacterMoveTable.
]]
function ENT:SBAI_LoadCurveData(curveDataPath)
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

--[[
    Calculates a value from a loaded CurveFloat table based on a normalized time.
    Handles both Linear and Cubic interpolation between keys.
    @param curveName The name of the curve, e.g., "M_Sawshark_DoubleSwingSaw_Curve".
    @param normalizedTime A value between 0.0 and 1.0 representing the progress.
    @returns The calculated float value from the curve.
]]
function ENT:SB_ApplyCurveFloat(curveName, normalizedTime)
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

--[[
    Converts a linear fraction (0-1) into an eased fraction based on the interp type.
    @param interpType The string identifier from the move table.
    @param fraction The linear progress, typically normalizedTime.
    @returns The eased progress.
]]
function ENT:SBAI_GetEasedFraction(interpType, fraction)
    if not interpType then return fraction end
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
]]
function ENT:SBAI_GetRootMotionTransform(rootMotionTable, startTime)
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

function ENT:SBAI_SetMoveTable(strEffect)
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
        ["StartTime"] = CurTime() + (CharacterMoveTable.StartDelayTime or 0)
    }
    table.insert(self.SBAI_MoveStep, newMoveStep)

    if CharacterMoveTable.RootMotionDataPath and CharacterMoveTable.RootMotionDataPath ~= "None" then
        local RootMotionDataPath = string.sub(CharacterMoveTable.RootMotionDataPath, 6)
        RootMotionDataPath = "addons/sbraven/data_static/SB/Content" .. RootMotionDataPath .. ".json"
        SB_ImportJSON(RootMotionDataPath)
    end
    if CharacterMoveTable.PositionInterpCurveDataPath and CharacterMoveTable.PositionInterpCurveDataPath != "None" then
        self:SBAI_LoadCurveData(CharacterMoveTable.PositionInterpCurveDataPath)
    end
    if CharacterMoveTable.StaticMoveZVAlueCurveDataPath and CharacterMoveTable.StaticMoveZVAlueCurveDataPath != "None" then
        self:SBAI_LoadCurveData(CharacterMoveTable.StaticMoveZVAlueCurveDataPath)
    end
    if CharacterMoveTable.MoveOffsetCurveDataPath and CharacterMoveTable.MoveOffsetCurveDataPath != "None" then
        self:SBAI_LoadCurveData(CharacterMoveTable.MoveOffsetCurveDataPath)
    end
    if CharacterMoveTable.RotationInterpCurveDataPath and CharacterMoveTable.RotationInterpCurveDataPath != "None" then
        self:SBAI_LoadCurveData(CharacterMoveTable.RotationInterpCurveDataPath)
    end

    return true
end

--[[
    Checks if the current move should be cancelled based on conditions in the move data.
]]
function ENT:SBAI_ShouldCancelMoveTable(moveStep) 
    if not moveStep then return false end
    local name = moveStep.MoveArrayName 
    local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name] 
    if CharacterMoveTable.bStopWhenInvalidTarget and not IsValid(self:GetEnemy()) then 
        return true 
    end
    if CharacterMoveTable.bStopWhenInvalidNavigation and not self:IsGoalActive() then 
        return true 
    end
    return false 
end 

function ENT:SBAI_GetSkillAnimData(name) 
	local data = _G["SB_"..name] 
	if data then return data else MsgC(Color(0,255,0),"SBAI_GetSkillAnimData: "..name.." not precached\n") end 
end 

function ENT:OverrideMove(flInterval) 
    if self.SBAI_MoveStep and #self.SBAI_MoveStep > 0 then
        local currentAng = self:GetLocalAngles()
        local totalAngDelta = Angle(0, 0, 0)

        -- Iterate backwards for safe removal
        for i = #self.SBAI_MoveStep, 1, -1 do
            local moveStep = self.SBAI_MoveStep[i]

            if CurTime() < moveStep.StartTime then continue end

            local name = moveStep.MoveArrayName
            local CharacterMoveTable = SB_CharacterMoveTable[1].Rows[name]
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
            local easedNow = self:SBAI_GetEasedFraction(interpType, normalizedTime)
            local easedPrev = self:SBAI_GetEasedFraction(interpType, prevNormalizedTime)

            local movePosDelta = Vector(0, 0, 0)
            local moveAngDelta = Angle(0, 0, 0)
            local MoveType = CharacterMoveTable.MoveType

            if MoveType == "ESBMoveTransformType::MoveTransformType_RootMotion" then
                local RootMotionDataPath = string.StripExtension(string.GetFileFromFilename(CharacterMoveTable.RootMotionDataPath))
                local RootMotion = _G["SB_" .. RootMotionDataPath]
                if RootMotion then
                    local posOffset, angOffset = self:SBAI_GetRootMotionTransform(RootMotion, moveStep.StartTime)
                    if posOffset and angOffset then
                        if not moveStep.PrevPosOffset then
                            moveStep.PrevPosOffset = Vector(0, 0, 0)
                            moveStep.PrevAngOffset = Angle(0, 0, 0)
                        end
                        local posDelta = posOffset - moveStep.PrevPosOffset
                        moveAngDelta = angOffset - moveStep.PrevAngOffset
                        movePosDelta = currentAng:Forward() * posDelta.x + currentAng:Right() * posDelta.y + currentAng:Up() * posDelta.z
                        moveStep.PrevPosOffset = posOffset
                        moveStep.PrevAngOffset = angOffset
                    end
                end
            elseif MoveType == "ESBMoveTransformType::MoveTransformType_Static" then
                 if CharacterMoveTable.PositionType == "ESBMovePositionType::MovePositionType_TargetSocket" then 
                    local target = IsValid(self:GetEnemy()) and self:GetEnemy() or Entity(1) 
                    movePosDelta = target:WorldSpaceCenter() - self:GetPos()
                else
                    if not moveStep.MoveDir then
                        local directionAxis = CharacterMoveTable.PositionDirectionAxis
                        if directionAxis == "ESBMoveDirectionAxis::MoveDirectionAxis_SelfToTarget" then
                            local enemy = IsValid(self:GetEnemy()) and self:GetEnemy() or Entity(1)
                            moveStep.MoveDir = (enemy:GetPos() - self:GetPos()):GetNormalized()
                        else
                            moveStep.MoveDir = self:GetAngles():Forward()
                        end
                    end
                    local rightDir = moveStep.MoveDir:Cross(Vector(0, 0, 1)):GetNormalized()
                    local forwardMove = CharacterMoveTable.ForwardValue or 0
                    local rightMove = CharacterMoveTable.RightValue or 0
                    local upMove = CharacterMoveTable.UpValue or 0
                    local posCurvePath = CharacterMoveTable.PositionInterpCurveDataPath
                    local zCurvePath = CharacterMoveTable.StaticMoveZVAlueCurveDataPath
                    if (posCurvePath and posCurvePath ~= "None") or (zCurvePath and zCurvePath ~= "None") then
                        local posMultiplier, prevPosMultiplier, zMultiplier, prevZMultiplier = 1, 1, 1, 1
                        if posCurvePath and posCurvePath ~= "None" then
                            local curveName = string.StripExtension(string.GetFileFromFilename(string.match(posCurvePath, "'(.-)'")))
                            posMultiplier = self:SB_ApplyCurveFloat(curveName, normalizedTime)
                            prevPosMultiplier = self:SB_ApplyCurveFloat(curveName, prevNormalizedTime)
                        end
                        if zCurvePath and zCurvePath ~= "None" then
                           local curveName = string.StripExtension(string.GetFileFromFilename(string.match(zCurvePath, "'(.-)'")))
                            zMultiplier = self:SB_ApplyCurveFloat(curveName, normalizedTime)
                            prevZMultiplier = self:SB_ApplyCurveFloat(curveName, prevNormalizedTime)
                        end
                        local totalOffset = (moveStep.MoveDir * forwardMove + rightDir * rightMove)
                        local curvePosDelta = totalOffset * (posMultiplier - prevPosMultiplier)
                        local zDelta = Vector(0, 0, upMove * (zMultiplier - prevZMultiplier))
                        movePosDelta = curvePosDelta + zDelta
                    else
                        local totalDisplacement = (moveStep.MoveDir * forwardMove) + (rightDir * rightMove) + (Vector(0,0,1) * upMove)
                        movePosDelta = totalDisplacement * (easedNow - easedPrev)
                    end
                end
            elseif MoveType == "ESBMoveTransformType::MoveTransformType_LocalAxis" then
                local forwardMove = CharacterMoveTable.ForwardValue or 0
                local rightMove = CharacterMoveTable.RightValue or 0
                local upMove = CharacterMoveTable.UpValue or 0
                local totalLocalDisplacement = Vector(forwardMove, rightMove, upMove)
                local localDisplacementDelta = totalLocalDisplacement * (easedNow - easedPrev)
                movePosDelta = self:GetAngles():Forward() * localDisplacementDelta.x + self:GetAngles():Right() * localDisplacementDelta.y + self:GetAngles():Up() * localDisplacementDelta.z
            end

            -- Apply this move's delta and check for collision failure
            local collisionFailed = false
            if movePosDelta:LengthSqr() > 0.001 then
                local moveSuccess = true
                local targetPosForThisMove = self:GetPos() + movePosDelta

                if CharacterMoveTable.bOnGround then 
                    if self:MoveGroundStep(targetPosForThisMove) == 0 then moveSuccess = false end 
                else 
                    local moveResult = IterativeHybridMoveLimit(self, self:GetPos(), targetPosForThisMove)
                    self:SetLocalPos(moveResult.vEndPosition)
                    if moveResult.fStatus ~= "OK" then moveSuccess = false end
                end

                if not moveSuccess and CharacterMoveTable.bStopWhenCollision then
                    print("removing motion due to collision for", name)
                    table.remove(self.SBAI_MoveStep, i)
                    collisionFailed = true
                end
            end

            -- Only process expiration and add angle delta if the move wasn't removed for collision
            if not collisionFailed then
                totalAngDelta = totalAngDelta + moveAngDelta
                
                if CurTime() > CurEndTime or self:SBAI_ShouldCancelMoveTable(moveStep) then
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
    -- print("***in selecttask", taskTable, currentIndex)
    currentIndex = currentIndex or 1

    for subTaskNum, subTaskTable in ipairs(taskTable) do 
        local objectName = subTaskTable.ObjectName
        local isSelector = objectName and objectName:find("BTComposite_Selector")
        local isSequence = objectName and objectName:find("BTComposite_Sequence")
		local skiptasks = true 
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
    -- print("RunBehavior start: SysTime:", SysTime()) 

    -- Ensure we have a runtime tree copy
    if !self.SBAI_CurBehaviorStack then
        -- print("Cloning behavior tree...")
        self.SBAI_CurBehaviorStack = table.Copy(self.SBAI_BehaviorTree)
    end

    -- Run tick on runtime tree
    local result = self:SBAI_SelectTask(self.SBAI_CurBehaviorStack) 
    -- print("BehaviorTree tick finished with result:", result, self.CurrentSBTask)

    -- If resolved (true/false), discard runtime so next tick restarts fresh
    if result != nil then
        -- print("Clearing runtime behavior stack")
        self.SBAI_CurBehaviorStack = nil
    end 

    -- print("RunBehavior end: SysTime:", SysTime()) 
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
	if self:NPC_HasCondition(COND.ENEMY_OCCLUDED) then return false end 
	return true 
end 

function ENT:NPC_ShouldBlockRunAI() 
	if self:NPC_ShouldConductBehaviorTree() then return true end 
	return scripted_ents.Get("npc_unreali_female").NPC_ShouldBlockRunAI(self) 
end 

function ENT:CustomRunAI() 
	self:SBAI_ProcessActiveSkill(self.SBAI_ActiveSkill) 
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
		-- Entity(1):ChatPrint("saving to SBBlackBoard: "..tbl.KeyName..tostring(tbl.IntValue)..tbl.CompareOP) 
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
    if !IsValid(ent) then return bInverseCondition end 
	-- debug 
	if math.random() > 0.5 then return true else return false end 

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
	-- Entity(1):ChatPrint("CheckStat: "..CheckStat.." CheckValue: "..tostring(CheckValue).. "..CompareOP:"..CompareOP.." "..tostring(result)) 
	-- print("ActorStat check", CheckStat, testvalue, CompareOP, CheckValue, "=>", result) 
	return result 
end 

function ENT:SbCheckStance(tbl) -- M_Raven_Phase2, M_Raven_Default 
	if true then return true end 
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
	local enemyDist = self.enemyDist or 9999 
	if enemyDist < 250 then return true end -- moved away from task start pos by 250 units 
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
    -- This function is now simplified, as setup logic has moved to SetSkillStep. 
	
    if !tbl.Started then
        Entity(1):ChatPrint("starting skill")
        for k, v in RandomPairs(tbl) do
            if isnumber(k) then -- do not accidentally start variables
				local CheckCooldown = self.SBAI_SkillTimers[v] -- returns Time, ["M_Raven_SlashChain"] = 216 
				local SkillCommandTable = SB_SkillCommandTable[1].Rows[v]
				local SkillNameFromSkillCommandTable = SkillCommandTable.SkillAlias
				local SkillTable = SB_SkillTable[1].Rows[SkillNameFromSkillCommandTable]
				if !CheckCooldown or CheckCooldown and CurTime() >= CheckCooldown then 
					-- This logic correctly finds the *first* skill step to execute
					if SkillCommandTable then
						local FirstSkillActiveAlias = SkillTable.FirstSkillActiveAlias
						-- This now correctly handles all the data-driven setup for the first step
						self:SBAI_SetSkillStep(FirstSkillActiveAlias)
						self.SBAI_SkillTimers[v] = CurTime() + SkillTable.CoolTime 
						-- Entity(1):ChatPrint("added cooldown to: "..v.." "..tostring(SkillTable.CoolTime)) 
						tbl.Started = true
						break -- Start with the first valid skill found 
					else -- do not use SkillCommandTable, directly refer to SkillTable 
					
					end 
				else 
					-- Entity(1):ChatPrint(v.." is in cooldown. "..tostring(CurTime()).." "..tostring(CheckCooldown)) 
				end 
			end 
		end 
	end 

    if tbl.Started then
        -- Process the currently active skill step
        self:SBAI_ProcessActiveSkill(self.SBAI_ActiveSkill)

        -- If the active skill was cleared (e.g., skill finished or target died), the task is complete
        if not self.SBAI_ActiveSkill or not self.SBAI_ActiveSkill.Name then
             Entity(1):ChatPrint("task complete")
             self:NPC_StopScriptedActivity() 
			 self:ResetIdealActivity(ACT_RESET) 
             return true
        end

        -- Check if the animation sequence itself has finished
        if self:IsSequenceFinished() then
            -- This condition might be too simple, as some skills might end based on
            -- duration rather than the animation finishing. We rely on the duration check for now.
        end
    else -- no skill activated, maybe all of them are in cooldown 
		return true -- to continue the procedure 
	end 

    return nil -- Task is still running
end

-- This function is called every tick to process the active skill step.
-- It handles timed events, continuous actions, and transitioning to the next step.
function ENT:SBAI_ProcessActiveSkill(tbl)
    local Name = tbl.Name
    if not Name then return end

    local SkillStepTable = tbl.Data
    if not SkillStepTable then return end
	local Duration = SkillStepTable.Duration 
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
        currentTarget = self:GetEnemy()
    end

    -- [NEW] Handle persistent "bLookAtTarget": Keep looking at the target during the step
	local bLookAtTarget = true 
	-- local bLookAtTarget = SkillStepTable.bLookAtTarget 
    if bLookAtTarget and IsValid(currentTarget) then
        local angleToTarget = (currentTarget:GetPos() - self:GetPos()):Angle().y
        self:SetIdealYawAndUpdate(angleToTarget, -1)
    end 
	
	local Type = SkillStepTable.Type 
	-- get skill step type 
	
	if Type == "ESBSkillActiveStepType::SkillActiveStepType_Parry" then -- parries incoming attack, used by eve, raven and some other npcs 
	-- to be filled 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Hit" then 
		local bEveryFrameHitCheck = SkillStepTable.bEveryFrameHitCheck 
		if bEveryFrameHitCheck then 
			if !self.SBAI_ActiveSkill.bEveryFrameHitCheck then 
				self.SBAI_ActiveSkill.bEveryFrameHitCheck = true 
				timer.Simple(0.01,function() 
					if IsValid(self) then 
						self:SBAI_CheckSkillHit(SkillStepTable,true) 
					end 
				end) 
			end 
		else 
			self:SBAI_CheckSkillHit(SkillStepTable) 
		end 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Hold" then -- unused 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_SuperParry" then -- unused 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Item" then -- eve only: use item 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_Guard" then -- eve only: put sword / wings in front to parry 
	elseif Type == "ESBSkillActiveStepType::SkillActiveStepType_None" then -- default action 
	
	end 

    -- Check if the duration for the current step has elapsed
    local Time = tbl.Time 
    if CurTime() > Time + Duration then
        local NextStepAlias = SkillStepTable.NextStepAlias
        if NextStepAlias and NextStepAlias != "None" then
            -- Transition to the next skill step
            self:SBAI_SetSkillStep(NextStepAlias)
        else
            -- No next step, so the skill is finished
            self.SBAI_ActiveSkill = {}
        end
    else 
		local GetAnimTimeInterval = self:GetAnimTimeInterval() 
		GetAnimTimeInterval = GetAnimTimeInterval > 0.1 and GetAnimTimeInterval or 0.1 -- by default it can't be lesser than 0.1 so we will assume 0.1 is original think rate 
		if Duration < self:GetAnimTimeInterval() then 
			self:NextThink(CurTime()+Duration) -- run activities in lesser gaps with high frequency 
		end 
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

function ENT:ON_LIGHT_DAMAGE() 
	-- get current skill step if available and see whether NextStepAliasWhenAttacked is set 
	local SkillStepTable = self.SBAI_ActiveSkill 
	if !SkillStepTable then return scripted_ents.Get("npc_unreali_female").ON_LIGHT_DAMAGE(self) end 
	if !SkillStepTable.Name then return scripted_ents.Get("npc_unreali_female").ON_LIGHT_DAMAGE(self) end 
	SkillStepTable = SB_SkillActiveStepTable[1].Rows[SkillStepTable] 
	if !SkillStepTable then return scripted_ents.Get("npc_unreali_female").ON_LIGHT_DAMAGE(self) end 
	if SkillStepTable.NextStepAliasWhenAttacked and SkillStepTable.NextStepAliasWhenAttacked != "None" then 
		self:SBAI_SetSkillStep(SkillStepTable.NextStepAliasWhenAttacked) 
	elseif SkillStepTable.NextStepAliasWhenPerfectParry != "None" then 
		local enemy = self:GetEnemy() 
		if IsValid(self:GetEnemy()) then 
			local DamageTime = self:GetLastTimeTookDamageFromEnemy() 
			if DamageTime + 0.02 > CurTime() then 
				self:SBAI_SetSkillStep(SkillStepTable.NextStepAliasWhenPerfectParry) 
			end 
		end 
	end 
	return scripted_ents.Get("npc_unreali_female").ON_LIGHT_DAMAGE(self) 
end 
