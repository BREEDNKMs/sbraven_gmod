AddCSLuaFile() 

-- Define the path to your JSON file relative to the "garrysmod" folder.
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
ENT.npc_health 		= 248304 -- "MaxHP": 248304, "MaxShield": 4805, 
ENT.npc_model		= "models/alvaroports/sbraven2.mdl" 
ENT.PhysicAttackPower = 1600  
ENT.bHasInnateMelee1 = true 
ENT.m_fMaxYawSpeed = 360 -- "RotateAnglePerSecond": 360.0, 
ENT.SBAI_BlackBoard = { } 
ENT.SBAI_bInBackgroundTask = false 
ENT.SB_EffectAlias = { } 
ENT.SBAI_ActiveSkill = { } -- SkillStepTable 
ENT.SBAI_ActiveShow = { } 
ENT.SBAI_SkillTimers = { } 
ENT.CharacterSoundSetPath = "addons/sbraven/data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_MON_53_Raven.json" 
ENT.EVE_CharacterSoundSetPath = "addons/sbraven/data_static/SB/Content/Sound/SoundAsset/CharacterSoundset/CSS_PC_EVE.json" 
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

function ENT:SBAI_BuildSoundScript(parsedjson) 
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
		pcall(function() SoundScript.SoundPath = result.SoundPath end)
	end

	return SoundScript
end 

function ENT:SBAI_GetEffectTable(strEffect) 
	local EffectTable = SB_EffectTable[1].Rows[strEffect] 
	return EffectTable 
end 

function ENT:SBAI_GetSkillAnimData(name) 
	local data = _G["SB_"..name] 
	if data then return data else MsgC(Color(0,255,0),"SBAI_GetSkillAnimData: "..name.." not precached\n") end 
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

-- Initialize a working copy of the master tree and reset coroutine state
function ENT:SBAI_InitTree()
    self.SBAI_CurBehaviorStack = table.Copy(self.SBAI_BehaviorTree)
    self.CurrentBranch = nil
    self.SBAI_bInBackgroundTask = false
    -- reset running coroutine (so we start fresh)
    self._sbaico = nil
end

-- Recursively clear running state in a subtree (used by flow-abort)
function ENT:SBAI_ClearRunning(node)
    if not node then return end
    node._running = false
    node._result = nil
    node._startTime = nil
    node._currentChild = nil
    if node.NextTask then
        for _, child in ipairs(node.NextTask) do
            self:SBAI_ClearRunning(child)
        end
    end

    -- If we cleared running nodes mid-coroutine, drop the coroutine so a fresh traversal will be created next tick.
    -- This prevents stale coroutine-local control flow from continuing on a pruned subtree.
    self._sbaico = nil
end


-- Coroutine-friendly, stack-based Behavior Tree selector/sequence executor.
-- Call this function *inside* a coroutine (NextBot coroutine think).
-- It yields whenever a running task returns nil so the coroutine can be resumed later.
function ENT:SBAI_SelectTask(taskTable, startIndex)
    startIndex = startIndex or 1
    if not taskTable or #taskTable == 0 then return false end

    -- Frame represents a composite frame we are iterating:
    -- { tasks = <table>, idx = <current index>, parentSub = <sub table on parent>, parentIsSelector, parentIsSequence }
    local stack = {}
    local function pushFrame(tasks, idx, parentSub)
        stack[#stack + 1] = {
            tasks = tasks,
            idx = idx or 1,
            parentSub = parentSub,
        }
    end
    local function popFrame()
        stack[#stack] = nil
    end
    -- Start with root
    pushFrame(taskTable, startIndex, nil)

    -- Helper: evaluate decorators (conditions). Returns allowEntry, flowAbortMode
    local function evalConditions(sub)
        local allowEntry = true
        local flowAbortMode = nil

        if sub.Condition then
            for subConditionName, subConditionValues in pairs(sub.Condition) do
                -- cached previous result optimization:
                local prev = subConditionValues._result
                local passed

                if sub._running and not (sub.bBackgroundTask or false) and prev ~= nil then
                    -- If node is running (and not background), reuse previous decorator result when available
                    passed = prev
                else
                    -- record flow abort mode if present (prefer first seen)
                    if not flowAbortMode and subConditionValues.FlowAbortMode then
                        flowAbortMode = subConditionValues.FlowAbortMode
                    end

                    local decoName = subConditionName:gsub("^SBBTDecorator_", ""):gsub("_%d+$", "")
                    local decoHandler = self[decoName]
                    if decoHandler then
                        passed = decoHandler(self, subConditionValues)
                    else
                        passed = true
                        print("SBAI_SelectTask_Co: unknown decorator handler", decoName, "-> assuming true")
                    end

                    -- cache result for reuse while running
                    subConditionValues._result = passed
                end

                if not passed then
                    allowEntry = false
                    break
                end
            end
        end

        return allowEntry, flowAbortMode
    end

    -- Helper: run a leaf StartTask until non-nil result (yielding between nil results).
    local function runLeafTask(sub)
        for taskKey, taskData in pairs(sub.StartTask) do
            local cleanTaskKey = taskKey:gsub("^SBBTTask_", ""):gsub("_%d+$", "")
            local handler = self[cleanTaskKey]

            if not handler then
                print("SBAI_SelectTask_Co: missing task handler", cleanTaskKey)
                sub._running = false
                sub._result = false
                return false
            end

            -- Ensure running flag and start time
            if not sub._running then
                sub._running = true
                sub._startTime = CurTime()
            end

            -- Loop calling handler until it returns non-nil; yield on nil
            local result = handler(self, taskData, sub)
            while result == nil do
                if taskData.bBackgroundTask then
                    self.SBAI_bInBackgroundTask = true
                end
                coroutine.yield() -- pause the coroutine; caller should resume next tick
                -- resume here
                result = handler(self, taskData, sub)
            end

            -- Handler finished (non-nil)
            sub._running = false
            sub._result = result
            self.SBAI_bInBackgroundTask = false

            -- Return the result for caller to apply selector/sequence logic
            return result
        end

        -- No StartTask entries (shouldn't happen)
        return false
    end

    -- Main iterative traversal loop
    while #stack > 0 do
        local frame = stack[#stack]
        local tasks = frame.tasks
        local i = frame.idx

        -- If we've exhausted this composite's children, finish this frame and propagate result to its parent
        if i > #tasks then
            -- No child returned success/running in this composite -> default false for sequences/selectors
            -- Propagate false to parent if any
            local parentSub = frame.parentSub
            popFrame()
            if not parentSub then
                -- root finished with no running children -> final false
                return false
            else
                -- mark parentSub as finished with result = false
                parentSub._running = false
                parentSub._result = false
                parentSub._currentChild = nil
                -- continue loop and let parent frame handle its selector/sequence logic
                -- NOTE: do NOT automatically return here; parent frame will check parentSub._result when continuing
                -- increment parent's idx so parent will continue to next sibling after processing
                local parentFrame = stack[#stack]
                if parentFrame then
                    parentFrame.idx = parentFrame.idx + 1
                end
                -- next iteration will handle parent
                goto continue_outer_loop
            end
        end

        local sub = tasks[i]
        local objectName = sub.ObjectName or ""
        local isSelector = objectName:find("BTComposite_Selector")
        local isSequence = objectName:find("BTComposite_Sequence")

        -- If this node was already running: resume it without re-evaluating decorators (original behaviour)
        if sub._running then
            if sub.StartTask then
                local result = runLeafTask(sub) -- this yields internally if still running
                -- runLeafTask returns only when handler returns non-nil
                if result == true then
                    if isSelector then return true end
                    -- if sequence, continue to next sibling
                elseif result == false then
                    if isSequence then return false end
                    -- if selector, continue
                end
                -- move to next sibling
                frame.idx = frame.idx + 1
                goto continue_outer_loop
            elseif sub.NextTask then
                -- composite: resume its children
                local childStart = sub._currentChild or 1
                -- push a child frame and continue loop (we'll resume the child in subsequent iterations)
                pushFrame(sub.NextTask, childStart, sub)
                goto continue_outer_loop
            else
                -- nothing to run; mark finished
                sub._running = false
                sub._result = false
                frame.idx = frame.idx + 1
                goto continue_outer_loop
            end
        end

        -- Evaluate decorators (unless we resumed above)
        local allowEntry, flowAbortMode = evalConditions(sub)

        -- Flow-abort handling (mirrors your original logic)
        -- Self: abort current node and clear running subtree
        if flowAbortMode == "Self" and not allowEntry and self.CurrentBranch == i then
            self.CurrentBranch = nil
            self:SBAI_ClearRunning(sub)
            return false
        end

        -- LowerPriority: a higher-priority node became valid -> preempt lower-priority
        if flowAbortMode == "LowerPriority" and allowEntry and startIndex and i < startIndex then
            self.CurrentBranch = i
            -- restart selection at this higher priority (push root to stack starting at i)
            popFrame() -- remove current frame and push the taskTable starting from i
            pushFrame(tasks, i, frame.parentSub)
            goto continue_outer_loop
        end

        if flowAbortMode == "Both" then
            if not allowEntry and self.CurrentBranch == i then
                self.CurrentBranch = nil
                self:SBAI_ClearRunning(sub)
                return false
            elseif allowEntry and startIndex and i < startIndex then
                self.CurrentBranch = i
                popFrame()
                pushFrame(tasks, i, frame.parentSub)
                goto continue_outer_loop
            end
        end

        -- If decorators allow entry, execute this node
        if allowEntry then
            if not self.CurrentBranch then
                self.CurrentBranch = i
            end

            if sub.StartTask then
                -- Run the leaf task and yield if still running (runLeafTask yields internally).
                local result = runLeafTask(sub)
                if result == true then
                    if isSelector then return true end
                    -- if sequence, continue to next sibling
                elseif result == false then
                    if isSequence then return false end
                    -- if selector, continue to next sibling
                end
                -- proceed to next sibling
                frame.idx = frame.idx + 1
                goto continue_outer_loop

            elseif sub.NextTask then
                -- Composite: descend into children
                local childStart = sub._currentChild or 1
                -- mark parent running and remember current child start
                sub._running = true
                sub._currentChild = childStart
                pushFrame(sub.NextTask, childStart, sub)
                goto continue_outer_loop
            else
                -- Unknown node type - skip
                frame.idx = frame.idx + 1
                goto continue_outer_loop
            end
        else
            -- decorator prevented entry -> continue to next sibling
            frame.idx = frame.idx + 1
            goto continue_outer_loop
        end

        ::continue_outer_loop::
    end

    -- If stack emptied and nothing returned true/running, return false
    return false
end


--[[ 
-- Tick the runtime tree
function ENT:SBAI_RunBehavior() 
    if not self.SBAI_CurBehaviorStack then
        self.SBAI_CurBehaviorStack = table.Copy(self.SBAI_BehaviorTree)
    end

    local result = self:SBAI_SelectTask(self.SBAI_CurBehaviorStack)

    if result ~= nil then
        -- resolved this tick; clear runtime copy so next tick starts fresh
        self.SBAI_CurBehaviorStack = nil
        self.CurrentBranch = nil
    end

    return result
end
--]] 

-- Tick the runtime tree: create/resume the coroutine that runs SBAI_SelectTask
function ENT:SBAI_RunBehavior() 
    -- Create coroutine if missing or dead
    if !self._sbaico or coroutine.status(self._sbaico) == "dead" then 
		self:SBAI_InitTree() 
		print("constructing coroutine") 
        self._sbaico = coroutine.create(function()
            return self:SBAI_SelectTask(self.SBAI_CurBehaviorStack)
        end)
    end

    -- Resume coroutine safely
    if coroutine.status(self._sbaico) == "suspended" then
        local ok, ret = coroutine.resume(self._sbaico)
        if !ok then
            -- coroutine errored: print and reset so next tick can recreate
            print("[SBAI] behavior coroutine error:", ret)
            self._sbaico = nil
            -- clear runtime copy to avoid half-baked state
            self.SBAI_CurBehaviorStack = nil
            self.CurrentBranch = nil
            return false
        else
            -- If coroutine finished (dead), ret contains final boolean result
            if self._sbaico and coroutine.status(self._sbaico) == "dead" then
                -- resolved this tick; clear runtime copy so next tick starts fresh
                self.SBAI_CurBehaviorStack = nil
                self.CurrentBranch = nil
                -- clear coroutine so next tick a new one is created
                self._sbaico = nil
                return ret
            else
                -- coroutine yielded (task still running) -> return nil to indicate running
                return nil
            end
        end
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
end 

function ENT:NPC_TranslateLuaSchedule(oldsched) 
	local retVal = scripted_ents.Get("npc_unreali_female").NPC_TranslateLuaSchedule(self,oldsched) 
	if retVal and retVal.DebugName == "LUASCHED_FLEE_FROM_BEST_SOUND" then 
		return LUASCHED_RAVEN_BLINK_FROM_BESTSOUND 
	elseif retVal and retVal.DebugName == "LUASCHED_TAKE_COVER_FROM_BEST_SOUND" then 
		return LUASCHED_RAVEN_BLINK_FROM_BESTSOUND 
	end 
	return retVal 
end 

function ENT:NPC_ShouldConductBehaviorTree() 
	-- likely performing a skill 
	if self:GetCurrentSchedule() == SCHED_SCENE_GENERIC then -- may be in a skill task 
		if self.SBAI_ActiveSkill and self.SBAI_ActiveSkill.Name then 
			if !self.SBAI_ActiveSkill.Stopped then 
				-- print("self.SBAI_ActiveSkill.Name:",self.SBAI_ActiveSkill.Name) 
				return true 
			end 
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
	if IsValid(self:GetActiveWeapon()) then 
		if self:GetActiveWeapon():GetClass() != "raven_blade" then return false end 
	end 
	-- has raven melee weapon 
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
	if self.CurrentSchedule and self.CurrentSchedule.DebugName == "LUASCHED_RAVEN_BLINK" then return true end 
	if self:NPC_ShouldConductBehaviorTree() then return true end 
	return scripted_ents.Get("npc_unreali_female").NPC_ShouldBlockRunAI(self) 
end 

function ENT:CustomRunAI() 
	-- self:SBAI_ProcessActiveSkill(self.SBAI_ActiveSkill) 
	local NPC_ShouldConductBehaviorTree = self:NPC_ShouldConductBehaviorTree() 
	if NPC_ShouldConductBehaviorTree then 
		return self:SBAI_RunBehavior(), self:NPC_MaintainActivity() 
	end 
	local retVal = scripted_ents.Get("npc_unreali_female").CustomRunAI(self) 
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
    local ent = self 
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
	local CheckStat = tbl.CheckStat -- ActorStatType_AttackSpeed       ActorStatType_StaminaAttackPower        ActorStatType_CriticalPercentage        ActorStatType_HitDefenseLevel   ActorStatType_ShieldIgnorePercentage    ActorStatType_CriticalValueRate ActorStatType_ShieldRegenPerSecond      ActorStatType_AdditiveSkillDamageRate   ActorStatType_ShieldRegenPerSecondRate  ActorStatType_ShieldRegenPerSecondValue ActorStatType_ShieldRegenPerSecondWhenBattleValue       ActorStatType_ShieldRegenPerSecondWhenBattle    ActorStatType_StaminaRegenPerSecond     ActorStatType_ShieldRegenPerSecondWhenBattleRate        ActorStatType_HPRegenPerSecondValue     ActorStatType_HPRegenPerSecond  ActorStatType_SmallWeightTypeDamageAdditiveRate ActorStatType_HPRegenPerSecondRate      ActorStatType_RangeAttackDamageAdditiveRate     ActorStatType_LargeWeightTypeDamageAdditiveRate ActorStatType_RangeAttackDamageReductionRate    ActorStatType_MeleeAttackDamageReductionRate    ActorStatType_GroggyStateDamageAdditiveRate     ActorStatType_DownStateDamageAdditiveRate       ActorStatType_FireAttributeDamageReductionRate  ActorStatType_AirborneStateDamageAdditiveRate   ActorStatType_LightningAttributeDamageReductionRate     ActorStatType_IceAttributeDamageReductionRate   ActorStatType_BetaGaugeAdditiveRate     ActorStatType_PoisonAttributeDamageReductionRate        ActorStatType_LowHpDamageAdditiveRate   ActorStatType_AdditiveFixedDamage       ActorStatType_DOTDamageAdditiveRate     ActorStatType_HighHpDamageAdditiveRate  ActorStatType_TachyGaugeReduceConsumeRate       ActorStatType_TachyGaugeAdditiveGainRate        ActorStatType_FinalShieldDamageReduceRate       ActorStatType_FinalHPDamageReduceRate   ActorStatType_AdditiveSkillDamageGroup1 ActorStatType_Luck      ActorStatType_AdditiveSkillDamageGroup3 ActorStatType_AdditiveSkillDamageGroup2 ActorStatType_AdditiveSkillDamageGroup5 ActorStatType_AdditiveSkillDamageGroup4 ActorStatType_AdditiveSkillDamageGroup7 ActorStatType_AdditiveSkillDamageGroup6 ActorStatType_AdditiveSkillDamageGroup9 ActorStatType_AdditiveSkillDamageGroup8 ActorStatType_DrainHpByAttackPowerRate  ActorStatType_AdditiveSkillDamageGroup10        ActorStatType_SprintableStaminaValue    ActorStatType_DrainHpFixedValue ActorStatType_ItemStackBullet1  ActorStatType_ItemStackRecoveryPotion   ActorStatType_ItemStackBullet3  ActorStatType_ItemStackBullet2  ActorStatType_ItemStackBullet5  ActorStatType_ItemStackBullet4  ActorStatType_ItemStackConsumable1      ActorStatType_ItemStackBullet6  ActorStatType_ItemStackConsumable3      ActorStatType_ItemStackConsumable2      ActorStatType_ItemStackConsumable5      ActorStatType_ItemStackConsumable4      
	local CheckValue = tbl.CheckValue -- 60.0, 
	local CompareOP = tbl.CompareOP -- Greater 
	local bRateValue = tbl.bRateValue or false -- true 
	local NodeName = tbl.NodeName -- SB_CheckActorStat(HP>60) 
	-- handle only ActorStatType_HP for now, Raven only looks for this 
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
	-- print("DistanceToTarget:",dist,operator,FlowAbortMode) 
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

-- SbCautionToTarget: property-driven adaptation (no spawn hacks)
function ENT:SbCautionToTarget(tbl)
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
    if not tbl._started then
        tbl._started = true
        tbl.startTime = CurTime()
        tbl.attempts = 0
        tbl.navSet = false
        tbl.waitEnd = nil
        tbl.returnSucceeded = false

        -- compute wait time (possibly randomized)
        if WaitCheckTime > 0 then
            if bWaitRandom then
                tbl.waitTime = randFloat(WaitRandMin, WaitRandMax)
            else
                tbl.waitTime = WaitCheckTime
            end
        else
            tbl.waitTime = 0
        end

        -- group repetition counter
        tbl.waitGroupRemaining = WaitCountByGroup

        -- side repeat counter
        tbl.sideRepeatRemaining = SideRepeat

        -- preserved random choices if bIgnoreRestartSelf; re-roll only if absent or not preserving
        if not (bIgnoreRestartSelf and tbl.chosenMoveChoice) then
            tbl.chosenMoveChoice = nil -- will choose below
        end
        if not (bIgnoreRestartSelf and tbl.sideSign) then
            tbl.sideSign = (math.random() < 0.5) and -1 or 1
        end
        if not (bIgnoreRestartSelf and tbl.sideDist) then
            tbl.sideDist = math.Rand(SideMin, SideMax)
        end
        if not (bIgnoreRestartSelf and tbl.forwardDist) then
            tbl.forwardDist = math.Rand(MinDistance, math.max(MinDistance, MaxDistance))
        end

        -- yaw lock
        if bLockOn then
            self:SetMoveYawLocked(false) -- disabled  
        end

        -- choose movement style now (set tbl.chosenMoveChoice if not set)
        if not tbl.chosenMoveChoice then
            if SetMoveType == "ESBCautionToTargetMoveType::Side" then
                tbl.chosenMoveChoice = "side"
            elseif SetMoveType == "ESBCautionToTargetMoveType::ForwardAndSide" then
                tbl.chosenMoveChoice = "forwardandside"
            else -- All or unknown: decide probabilistically by declared ranges
                local forwardRange = math.max(0, (MaxDistance or 0) - (MinDistance or 0))
                local sideRange = math.max(0, (SideMax or 0) - (SideMin or 0))
                -- if RunDistance present, bias toward forward
                if RunDistance and RunDistance > 0 then forwardRange = forwardRange + RunDistance end
                -- avoid zero division
                if forwardRange + sideRange <= 0 then
                    -- fallback: choose forward if MinDistance small, else side
                    tbl.chosenMoveChoice = (MinDistance <= SideMin) and "forward" or "side"
                else
                    local pForward = forwardRange / (forwardRange + sideRange)
                    if math.random() < pForward then tbl.chosenMoveChoice = "forward" else tbl.chosenMoveChoice = "side" end
                end
            end
        end

        -- increment attempts
        tbl.attempts = tbl.attempts + 1
    end -- init done

    -- if nav not set, create nav goal according to chosenMoveChoice
    if not tbl.navSet then
        local myPos = self:GetPos()
        local tgtPos = target:GetPos()
        local dir = (tgtPos - myPos)
        local dir2D = Vector(dir.x, dir.y, 0)
        if dir2D:Length() > 0.001 then dir2D:Normalize() else dir2D = Vector(1,0,0) end
        local rightVec = dir2D:Angle():Right()

        local chosen = tbl.chosenMoveChoice

        local goalPos = tgtPos
		print("chosen",chosen) 
        if chosen == "side" then
            goalPos = tgtPos + rightVec * (tbl.sideDist * tbl.sideSign)
        elseif chosen == "forward" then
            goalPos = tgtPos - dir2D * tbl.forwardDist
        elseif chosen == "forwardandside" then
            goalPos = tgtPos - dir2D * tbl.forwardDist + rightVec * (tbl.sideDist * tbl.sideSign)
        else
            -- defensive fallback to forward
            goalPos = tgtPos - dir2D * tbl.forwardDist
        end

        -- Prefer NavSetRandomGoal for side moves to create natural paths; otherwise NavSetGoalPos.
        if chosen == "side" and self.NavSetRandomGoal then
            local minPathLen = math.Clamp(tbl.sideDist * 0.5, 100, 2000)
            self:NavSetRandomGoal(minPathLen, (tgtPos - myPos):GetNormalized()) 
        else
            if self.NavSetGoalPos then
                self:NavSetGoalPos(goalPos) 
            elseif self.NavSetGoalTarget then
                -- fallback: offset from target
                local offset = goalPos - tgtPos
                self:NavSetGoalTarget(target, offset) 
            end
        end
        tbl.navSet = true
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
        if tbl.chosenMoveChoice == "side" or tbl.chosenMoveChoice == "forwardandside" then
            if tbl.sideRepeatRemaining and tbl.sideRepeatRemaining <= 1 then
                success = true
            end
        end
    end

    -- if we did side movement and have repeats remaining, decrement and prepare another side move
    if not tbl.waitEnd and (tbl.chosenMoveChoice == "side" or tbl.chosenMoveChoice == "forwardandside") and tbl.sideRepeatRemaining and tbl.sideRepeatRemaining > 1 then
        tbl.sideRepeatRemaining = tbl.sideRepeatRemaining - 1
        -- pick new lateral sign unless preserving with bIgnoreRestartSelf
        if not bIgnoreRestartSelf then tbl.sideSign = (math.random() < 0.5) and -1 or 1 end
        tbl.navSet = false
        tbl.attempts = tbl.attempts + 1
        return nil
    end

    -- Start wait phase when movement finished (or attempts exhausted)
    if not tbl.waitEnd then
        tbl.returnSucceeded = success
        tbl.waitEnd = CurTime() + (tbl.waitTime or 0)
        -- maybe play a show/gesture with PlayShowRateWhenWait probability
        if PlayShowRateWhenWait and PlayShowRateWhenWait > 0 and math.random() * 100 <= PlayShowRateWhenWait then
            -- safe-call a generic "gesture" if present (you can replace with your own)
            pcall(function() if self.PlayGesture then self:PlayGesture(ACT_GESTURE_TURN_RIGHT) end end)
        end
    end

    -- during wait: keep looking at target if requested
    if tbl.waitEnd and CurTime() < tbl.waitEnd then
        if bStayTargetView then
            -- if NPC API offers SetEyeTarget / look functions, use them safely
            pcall(function()
                if self.SetEyeTarget then self:SetEyeTarget(target:GetPos()) end
            end)
        end
        return nil -- still waiting
    end

    -- wait finished: decrement group counter and either finish or iterate another cycle
    if tbl.waitEnd and CurTime() >= tbl.waitEnd then
        tbl.waitEnd = nil
        tbl.waitGroupRemaining = math.max(0, (tbl.waitGroupRemaining or 1) - 1)

        -- if group cycles remain, prepare for another caution move
        if tbl.waitGroupRemaining > 0 then
            tbl.navSet = false
            tbl.sideRepeatRemaining = SideRepeat
            -- if not preserving, re-roll movement choices to create variety
            if not bIgnoreRestartSelf then
                tbl.chosenMoveChoice = nil
                tbl.sideSign = (math.random() < 0.5) and -1 or 1
                tbl.sideDist = math.Rand(SideMin, SideMax)
                tbl.forwardDist = math.Rand(MinDistance, math.max(MinDistance, MaxDistance))
            end
            return nil
        end

        -- final decision: succeed if movement reported success, else fail
        -- clear move locks and stop
        self:StopMoving(true) 
        self:ClearGoal() 
        if bLockOn then self:SetMoveYawLocked(false) end

        if tbl.returnSucceeded then
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
	
	return IsValid(self:GetEnemy()) 
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
		print(self:GetCurWaypointPos()) 
		if !navSet then return false end 
		self:SetMovementActivity(ACT_MP_WALK_MELEE) 
	end 
end 

function ENT:SbUseEffect(tbl) -- add effect 
	local bSelfActor = tbl.bSelfActor 
	local EffectAlias = tbl.EffectAlias 
	local bSubTarget = tbl.bSubTarget or false 
	local target = self:GetEnemy() 
	if bSelfActor then target = self end 
	if IsValid(target) then 
		StellarBlade.AddEffect(target,EffectAlias) 
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

function ENT:SbUseSkill(tbl)
    -- This function is now simplified, as setup logic has moved to SetSkillStep. 
	
    if !tbl.Started then
        for k, v in RandomPairs(tbl) do
            if isnumber(k) then -- do not accidentally start variables
				local CheckCooldown = self.SBAI_SkillTimers[v] -- returns Time, ["M_Raven_SlashChain"] = 216 
				local SkillCommandTable = SB_SkillCommandTable[1].Rows[v]
				local SkillNameFromSkillCommandTable = SkillCommandTable.SkillAlias
				local SkillTable = SB_SkillTable[1].Rows[SkillNameFromSkillCommandTable]
				if !CheckCooldown or CheckCooldown and CurTime() >= CheckCooldown then 
					-- This logic correctly finds the *first* skill step to execute 
					-- clear out old skill effects 
					
					StellarBlade.RemoveEffectLifeTypes(self,"ESBEffectLifeType::EffectLifeType_SkillDependent") 
					StellarBlade.RemoveEffectLifeTypes(self,"ESBEffectLifeType::EffectLifeType_StepDependent") 
					
					-- add effects from SkillTable 
					self.SBAI_SkillTable = SkillTable 
					-- StellarBlade.AddEffect(self,effect,name) 
					if SkillCommandTable then 
						local FirstSkillActiveAlias = SkillTable.FirstSkillActiveAlias 
						-- This now correctly handles all the data-driven setup for the first step 
						-- self:SBAI_SetSkillStep(FirstSkillActiveAlias) 
						StellarBlade.SetSkillStep(self,FirstSkillActiveAlias) 
						self.SBAI_SkillTimers[v] = CurTime() + SkillTable.CoolTime 
						Entity(1):ChatPrint("starting "..v.." at CurTime:"..tostring(CurTime())) 
						-- Entity(1):ChatPrint("added cooldown to: "..v.." "..tostring(SkillTable.CoolTime)) 
						tbl.Started = true 
						break -- Start with the first valid skill found 
					else -- does not use SkillCommandTable, directly refer to SkillTable 
					
					end 
				else 
					-- Entity(1):ChatPrint(v.." is in cooldown. "..tostring(CurTime()).." "..tostring(CheckCooldown)) 
				end 
			end 
		end 
	end 

    if tbl.Started then
        -- Process the currently active skill step
        -- self:SBAI_ProcessActiveSkill(self.SBAI_ActiveSkill) 

        -- If the active skill was cleared (e.g., skill finished or target died), the task is complete
        if !self.SBAI_ActiveSkill or !self.SBAI_ActiveSkill.Name then
             -- Entity(1):ChatPrint("task complete")
             self:NPC_StopScriptedActivity() 
			 self:ResetIdealActivity(ACT_IDLE) 
			 self.SBAI_SkillTable = nil  
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


function ENT:SbWait(data)
    local waitTime = data.WaitTime or 0
    local returnSucceeded = data.bReturnSucceeded or false

    if !data.startTime then
        data.startTime = CurTime()
    end

    local elapsed = CurTime() - data.startTime
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

-- function ENT:Item_Resurrection_Ground(ent) return false end 
-- function ENT:M_Raven_BetaCounterGrab_HitE(ent) return false end 
-- function ENT:LV_FinishQTE_FailDown(ent) return false end 
function ENT:P_Eve_Beta_SwordAura(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:P_Eve_Beta_SwordAura2(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:P_Eve_Beta_SwordAura3(ent) return self:NPC_IsNPCAttacking(ent) end 
function ENT:M_Common_HitProjectileResult(ent) return self:NPC_IsNPCAttacking(ent) end 

function ENT:ON_LIGHT_DAMAGE() 
	-- get current skill step if available and see whether NextStepAliasWhenAttacked is set 
	local SkillStepTable = self.SBAI_ActiveSkill 
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
    LUASCHED_RAVEN_BLINK = ai_schedule.New("LUASCHED_RAVEN_BLINK")
    -- single master task; ensures the whole 1.4s timeline is controlled here
    LUASCHED_RAVEN_BLINK:AddTaskEx("TASK_BLINK", "TASK_BLINK", 0)
	
	LUASCHED_RAVEN_BLINK_FROM_BESTSOUND = ai_schedule.New("LUASCHED_RAVEN_BLINK_FROM_BESTSOUND")
	LUASCHED_RAVEN_BLINK_FROM_BESTSOUND:EngTask("TASK_STOP_MOVING",0) 
    LUASCHED_RAVEN_BLINK_FROM_BESTSOUND:EngTask("TASK_SET_FAIL_SCHEDULE",SCHED_COWER) 
    LUASCHED_RAVEN_BLINK_FROM_BESTSOUND:EngTask("TASK_STORE_BESTSOUND_REACTORIGIN_IN_SAVEPOSITION",0) 
    LUASCHED_RAVEN_BLINK_FROM_BESTSOUND:EngTask("TASK_GET_PATH_AWAY_FROM_BEST_SOUND",3000) 
    LUASCHED_RAVEN_BLINK_FROM_BESTSOUND:AddTaskEx("TASK_BLINK", "TASK_BLINK", 1)
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
