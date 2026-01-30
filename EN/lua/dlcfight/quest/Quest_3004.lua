local QuestBase = require("Common/XQuestBase")
---@class XQuestScript3004
local Quest_3004 = XDlcScriptManager.RegQuestScript(3004, "XQuestScript3004", QuestBase)

function Quest_3004:Ctor()
end

function Quest_3004:Init()
end

function Quest_3004:Terminate()
end

-------------------任务目标的基类定义，为了方便访问quest，用任务ID替换这块内容里的9999
---@class Quest3004Objective
local ObjectiveBase = XClass(nil, "Quest3004Objective")

---@param quest XQuestScript3004
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end
-------------------------------------

local ObjectiveDefines = {} --本任务包含的所有任务目标的定义，包含参数和逻辑（不要删除！）
--================================================
--步骤1
--阅读罗斯发来的短信
---@class QuestObjective30040101 : Quest3004Objective
ObjectiveDefines.Obj30040101 = {
    Id = 30040101,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 300401,
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective30040101
    ---@param proxy StatusSyncFight.XFightScriptProxy
    InitFunc = function(obj, proxy)
        obj.NPC300401PID = 500021----注册心理医生
    end,

    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC300401PID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnderTakeSelfQuest()
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤2
--与医生交互
---@class QuestObjective30040102 : Quest3004Objective
ObjectiveDefines.Obj30040102 = {
    Id = 30040102,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500021, ----心理医生
                DisplayOffset = { x = 0, y = 2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500021] = 0,----心理医生
            },
        },
    },
    ---@param obj QuestObjective30040102
    ---@param proxy StatusSyncFight.XFightScriptProxy
    EnterFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption300401",true) --播放简易字幕
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤3
--播放医生与指挥官的聊天剧情
---@class QuestObjective30040103 : Quest3004Objective
ObjectiveDefines.Obj30040103 = {
    Id = 30040103,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3004_001",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:LoadLevelNpc(500020)----生成瑞娅
        proxy:PlayDramaCaption("Caption300402") --播放简易字幕
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500021),false)----关闭医生交互
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤4
--前往瑞亚的地方
---@class QuestObjective30040104 : Quest3004Objective
ObjectiveDefines.Obj30040104 = {
    Id = 30040104,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 626.082, y = 157.4056, z = 1286.848},
                DisplayOffset = {x = 0, y = 1.5, z = 0},
                ShowEffect = true,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 626.082, y = 157.4056, z = 1286.848},
        ReachDistance = 3,
    },
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption300403") --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤5
--前往瑞亚的地方
---@class QuestObjective30040105 : Quest3004Objective
ObjectiveDefines.Obj30040105 = {
    Id = 30040105,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500020, ----心理医生
                DisplayOffset = { x = 0, y = 2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 616.15, y = 157.422, z = 1293.44},
        ReachDistance = 7,
    },
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤6
--播放瑞娅与指挥官的聊天剧情
---@class QuestObjective30040106 : Quest3004Objective
ObjectiveDefines.Obj30040106 = {
    Id = 30040106,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3004_002",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500020),false)----关闭瑞娅交互
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500021),true)----开启医生交互
        proxy:PlayDramaCaption("Caption300404") --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤7
--与医生交互
---@class QuestObjective30040107 : Quest3004Objective
ObjectiveDefines.Obj30040107 = {
    Id = 30040107,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500021, ----心理医生
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500021] = 0,----心理医生
            },
        },
    },
    ---@param obj QuestObjective30040107
    ---@param proxy StatusSyncFight.XFightScriptProxy
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤8
--播放医生与指挥官的聊天剧情
---@class QuestObjective30040108 : Quest3004Objective
ObjectiveDefines.Obj30040108 = {
    Id = 30040108,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3004_003",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption300405") --播放简易字幕
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500021),false)----关闭医生交互
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤9
--区域触发
---@class QuestObjective30040109: Quest3004Objective
ObjectiveDefines.Obj30040109 = {
    Id = 30040109,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 551.5, y = 145.5, z = 1355.45},
                DisplayOffset = {x = 0, y = 1.5, z = 0},
                ShowEffect = true,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 551.5, y = 145.5, z = 1355.45},
        ReachDistance = 13,
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(500006)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤10
--拍摄星幕树
---@class QuestObjective30040110 : Quest3004Objective
ObjectiveDefines.Obj30040110  = {
    Id = 30040110 ,
    Type = EQuestObjectiveType.TakePhotoComplete,
    Args = {
        LevelId = 4001,
        CamParamId=1,
        DetectionNpcPlaceIdList = {  },
        DetectionSceneObjectPlaceIdList = { 500006 },
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:LoadLevelNpc(500023)
        proxy:LoadSceneObject(500019)
        proxy:UnloadSceneObject(500006)
        proxy:PlayDramaCaption("Caption300406") --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤11
--与罗斯交互
---@class QuestObjective30040111 : Quest3004Objective
ObjectiveDefines.Obj30040111 = {
    Id = 30040111,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500023, ----罗斯
                DisplayOffset = { x = 0, y = 2, z = 0 },
                ShowEffect = true,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 561.5, y = 169.5, z = 1170.45},
        ReachDistance = 6,
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤12
--播放罗斯与指挥官的聊天剧情
---@class QuestObjective30040112 : Quest3004Objective
ObjectiveDefines.Obj30040112 = {
    Id = 30040112,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3004_004",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(500019)
        proxy:LoadSceneObject(500002)
        proxy:LoadSceneObject(500008)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500023),false)----关闭罗斯交互
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤121
--接过咖啡杯
---@class QuestObjective300401121 : Quest3004Objective
ObjectiveDefines.Obj300401121 = {
    Id = 300401121,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 500002, ----咖啡杯
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [500008] = 0,----咖啡杯
            },
        },
    },
    ---@param obj QuestObjective300401121
    ---@param proxy StatusSyncFight.XFightScriptProxy
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500021),true)----开启医生交互
        proxy:UnloadSceneObject(500002)
        proxy:UnloadSceneObject(500008)
        proxy:PlayDramaCaption("Caption300407") --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤13
--与医生交互
---@class QuestObjective30040113 : Quest3004Objective
ObjectiveDefines.Obj30040113 = {
    Id = 30040113,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500021, ----医生
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500021] = 0,----医生
            },
        },
    },
    ---@param obj QuestObjective30040113
    ---@param proxy StatusSyncFight.XFightScriptProxy

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤14
--播放医生与指挥官的聊天剧情
---@class QuestObjective30040114 : Quest3004Objective
ObjectiveDefines.Obj30040114 = {
    Id = 30040114 ,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3004_005",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption300408") --播放简易字幕
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500021),false)----关闭医生交互
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500020),true)----开启瑞娅交互
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤15
--与瑞娅交互
---@class QuestObjective30040115 : Quest3004Objective
ObjectiveDefines.Obj30040115 = {
    Id = 30040115,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500020, ----瑞娅
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500020] = 0,----瑞娅
            },
        },
    },
    ---@param obj QuestObjective30040115
    ---@param proxy StatusSyncFight.XFightScriptProxy

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤16
--播放瑞娅与指挥官的聊天剧情
---@class QuestObjective30040116 : Quest3004Objective
ObjectiveDefines.Obj30040116 = {
    Id = 30040116 ,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3004_006",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}


local StepDefines = {} --本任务包含的所有任务步骤的参数配置（不要删除！）

--Step的参数配置，至少要有一个，可按需增加
StepDefines.Step300401 = {
    Id = 300401,
    ExecMode = EQuestStepExecMode.Serial,
}

QuestBase.InitSteps(StepDefines) --固定的任务步骤数据初始化调用（不要删除！）
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines) --固定的任务目标数据初始化调用（不要删除！）

return Quest_3004