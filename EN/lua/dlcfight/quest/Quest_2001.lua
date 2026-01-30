local QuestBase = require("Common/XQuestBase")
---@class XQuestScript2001
local Quest_2001 = XDlcScriptManager.RegQuestScript(2001, "XQuestScript2001", QuestBase)

function Quest_2001:Ctor()
end

function Quest_2001:Init()
end

function Quest_2001:Terminate()
end

--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf

---@class Quest2001Objective
local Quest2001Objective = XClass(nil, "Quest2001Objective")

---@param quest XQuestScript2001
function Quest2001Objective:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}
--不用数字key，是为了能在IDEA的structure视图中识别这里的table结构，方便快速跳转


---@class QuestObjective20010102 : Quest2001Objective
ObjectiveDefines.Obj20010102 = {
    Id = 20010102,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200101,-------短信id
        AutoSend = true, --enter时，自动发送短信
    },-------在exit的时候播caption200101
    ---@param obj QuestObjective20010102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:UnderTakeSelfQuest()
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200102",true) --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective20010104 : Quest2001Objective
ObjectiveDefines.Obj20010104 = {
    Id = 20010104,
    Type = EQuestObjectiveType.NarrativeComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 600005,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        NarrativeIds = {4}
    },
    ---@param obj QuestObjective20010104
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.SO200101PID = 600005
        obj.NPC200101PID = 600001----在这一步就要把偷听的NPC加载出来
        obj.NPC200102PID = 600002----在这一步就要把偷听的NPC加载出来
    end,
    ---@param obj QuestObjective20010104
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.SO200101PID)
        proxy:LoadLevelNpc(obj.NPC200101PID)
        proxy:LoadLevelNpc(obj.NPC200102PID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010104
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(600005)

        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective20010105 : Quest2001Objective
ObjectiveDefines.Obj20010105 = {
    Id = 20010105,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200102,-------短信id
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective20010105
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200103",true) --播放简易字幕
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010105
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010106 : Quest2001Objective
ObjectiveDefines.Obj20010106 = {
    Id = 20010106,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 608.29, y = 189.3382, z = 1145.44},------赛利卡参考点
        ReachDistance = 7,
    },
    ---@param obj QuestObjective20010106
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200104",true)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010106
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010107 : Quest2001Objective
ObjectiveDefines.Obj20010107 = {
    Id = 20010107,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200101",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective20010107
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010107
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective20010108 : Quest2001Objective
ObjectiveDefines.Obj20010108 = {
    Id = 20010108,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 598.76, y = 189.2768, z = 1121},
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 598.76, y = 189.2768, z = 1121},
        ReachDistance = 10,
    },
    -----偷听可疑的人员
    ---@param obj QuestObjective20010108
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010108
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010109 : Quest2001Objective
ObjectiveDefines.Obj20010109 = {
    Id = 20010109,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200102",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective20010109
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC200101PID = 600001
        obj.NPC200102PID = 600002
    end,
    ---@param obj QuestObjective20010109
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010109
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(obj.NPC200101PID)-----在这里销毁两个可疑人员
        proxy:UnloadLevelNpc(obj.NPC200102PID)-----在这里销毁两个可疑人员
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010110 : Quest2001Objective
ObjectiveDefines.Obj20010110 = {
    Id = 20010110,
    Type = EQuestObjectiveType.NarrativeComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 600001,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        NarrativeIds = {5}
    },
    ---@param obj QuestObjective20010110
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.SO200102PID = 600001
    end,
    ---@param obj QuestObjective20010110
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.SO200102PID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010110
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.SO200102PID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010111 : Quest2001Objective
ObjectiveDefines.Obj20010111 = {
    Id = 20010111,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 608.29, y = 189.3382, z = 1145.44},------赛利卡参考点
        ReachDistance = 7,
    },
    ---@param obj QuestObjective20010111
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200105",true)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010111
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective200101120: Quest2001Objective
ObjectiveDefines.Obj200101120 = {
    Id = 200101120,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200103",
    },
    ---@param obj QuestObjective200101120
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective200101120
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010112 : Quest2001Objective
ObjectiveDefines.Obj20010112 = {
    Id = 20010112,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200104",--------Drama命名 别忘了 暂时放01 后面改04
    },
    ---@param obj QuestObjective20010112
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.SO200102PID = 600001
    end,
    ---@param obj QuestObjective20010112
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010112
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective200101121 : Quest2001Objective
ObjectiveDefines.Obj200101121 = {
    Id = 200101121,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200105",
    },
    ---@param obj QuestObjective200101121
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective200101121
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010113 : Quest2001Objective
ObjectiveDefines.Obj20010113 = {
    Id = 20010113,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        ConditionIds={50000001},
    },
    ---@param obj QuestObjective20010113
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010113
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010114 : Quest2001Objective
ObjectiveDefines.Obj20010114 = {
    Id = 20010114,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        ConditionIds={50000002},
    },
    ---@param obj QuestObjective20010114
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010114
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective200101141 : Quest2001Objective
ObjectiveDefines.Obj200101141 = {
    Id = 200101141,
    Type = EQuestObjectiveType.EnterLevel,
    Args = {
        LevelId = 4001,
        TargetLevelId = 4001,
    },
    ---@param obj QuestObjective200101141
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective200101141
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010115 : Quest2001Objective
ObjectiveDefines.Obj20010115 = {
    Id = 20010115,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200106",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective20010115
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.SO200105PID = 600007
        obj.SO200106PID = 600008
        obj.SO200107PID = 600009
        obj.NPC200103PID = 600016
        obj.NPC200104PID = 600017
    end,
    ---@param obj QuestObjective20010115
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.SO200105PID)
        proxy:LoadSceneObject(obj.SO200106PID)
        proxy:LoadSceneObject(obj.SO200107PID)
        proxy:LoadLevelNpc(obj.NPC200103PID)
        proxy:LoadLevelNpc(obj.NPC200104PID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010115
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010116 : Quest2001Objective
ObjectiveDefines.Obj20010116 = {
    Id = 20010116,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 532.7736, y = 189.3382, z = 1159.523},------------一会儿来改参数
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 532.7736, y = 189.3382, z = 1159.523},------------一会儿来改参数
        ReachDistance = 6,
    },
    ---@param obj QuestObjective20010116
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010116
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective20010118 : Quest2001Objective
ObjectiveDefines.Obj20010118 = {
    Id = 20010118,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 600017, ----露西亚
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [600017] = 0,--NPC2
            },
        },
    },
    ---@param obj QuestObjective20010118
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200106",true)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010118
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(600017),false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010119 : Quest2001Objective
ObjectiveDefines.Obj20010119= {
    Id = 20010119,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200107",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective20010119
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010119
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010120 : Quest2001Objective
ObjectiveDefines.Obj20010120= {
    Id = 20010120,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200103,-------短信id
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective20010120
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010120
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200107",true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective20010122 : Quest2001Objective
ObjectiveDefines.Obj20010122 = {
    Id = 20010122,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 614.01, y = 189.9987, z = 1184.46},------------一会儿来改参数
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 614.01, y = 189.9987, z = 1184.46},------------一会儿来改参数
        ReachDistance = 5,
    },
    ---@param obj QuestObjective20010122
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC200104PID = 600017--------摧毁掉商品铺的露西亚
        obj.NPC200106PID = 600004
        obj.NPC200107PID = 600005
        obj.NPC200108PID = 600010
    end,
    ---@param obj QuestObjective20010122
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:LoadLevelNpc(obj.NPC200106PID)
        proxy:LoadLevelNpc(obj.NPC200107PID)
        proxy:LoadLevelNpc(obj.NPC200108PID)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(600010),false)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010122
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(obj.NPC200104PID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010123 : Quest2001Objective
ObjectiveDefines.Obj20010123= {
    Id = 20010123,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200108",--------Drama命名 别忘了

    },
    ---@param obj QuestObjective20010123
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010123
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010124 : Quest2001Objective
ObjectiveDefines.Obj20010124= {
    Id = 20010124,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 600002, ----阿迪莱仓库
                DisplayOffset = { x = 0, y = 0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [600002] = 0,----阿迪莱仓库
            },
        },
    },
    ---@param obj QuestObjective20010124
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(600002)--------调查物件
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010124
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010125 : Quest2001Objective
ObjectiveDefines.Obj20010125= {
    Id = 20010125,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200109",--------Drama命名 别忘了

    },
    ---@param obj QuestObjective20010125
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010125
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(600002)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010126 : Quest2001Objective
ObjectiveDefines.Obj20010126= {
    Id = 20010126,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 600010, ----露西亚
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [600010] = 0,----露西亚
            },
        },
    },
    ---@param obj QuestObjective20010126
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(600010),true)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010126
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(600010),false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010127 : Quest2001Objective
ObjectiveDefines.Obj20010127= {
    Id = 20010127,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200110",--------Drama命名 别忘了

    },
    ---@param obj QuestObjective20010127
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC200109PID = 600007---在这个目标里加载露西亚和嫌疑人
        obj.NPC200110PID = 600008
        obj.NPC200111PID = 600009
    end,
    ---@param obj QuestObjective20010127
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010127
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC200109PID)
        proxy:LoadLevelNpc(obj.NPC200110PID)
        proxy:LoadLevelNpc(obj.NPC200111PID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010128 : Quest2001Objective
ObjectiveDefines.Obj20010128= {
    Id = 20010128,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 600008, ----嫌疑人二号
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [600008] = 0,----嫌疑人二号
            },
        },
    },
    ---@param obj QuestObjective20010128
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010128
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010129 : Quest2001Objective
ObjectiveDefines.Obj20010129= {
    Id = 20010129,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200112",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective20010129
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        ---在这个目标里摧毁露西亚和嫌疑人 在下一个目标完成时摧毁剩下两个 记得摧毁 记得摧毁
        obj.NPC200110PID = 600008
        obj.NPC200112PID = 600010---露西亚
    end,
    ---@param obj QuestObjective20010129
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010129
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(obj.NPC200110PID)
        proxy:UnloadLevelNpc(obj.NPC200112PID)----摧毁两个角色
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010130 : Quest2001Objective
ObjectiveDefines.Obj20010130 = {
    Id = 20010130,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 624.1719, y = 189.2768, z = 1166.565},------------触发点1
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = true,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 624.1719, y = 189.2768, z = 1166.565},------------触发点1
        ReachDistance = 8.3,
    },
    ---@param obj QuestObjective20010130
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC200109PID = 600007-------销毁这俩NPC
        obj.NPC200111PID = 600009
    end,
    ---@param obj QuestObjective20010130
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200109",true)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010130
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(obj.NPC200109PID)
        proxy:UnloadLevelNpc(obj.NPC200111PID)----摧毁两个角色
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010131 : Quest2001Objective
ObjectiveDefines.Obj20010131 = {
    Id = 20010131,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 642.61, y = 190.9095, z = 1219.88},------------触发点1
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = true,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 642.61, y = 190.9095, z = 1219.88},------------触发点1
        ReachDistance = 6,
    },
    ---@param obj QuestObjective20010131
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010131
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010132 : Quest2001Objective
ObjectiveDefines.Obj20010132 = {
    Id = 20010132,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 652.57, y = 193.8959, z = 1290.34},------------触发点1
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = true,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 652.57, y = 193.8959, z = 1290.34},------------触发点1
        ReachDistance = 6,
    },
    ---@param obj QuestObjective20010132
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC200113PID = 600011------------------在这一步把真凶创建出来
    end,
    ---@param obj QuestObjective20010132
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC200113PID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010132
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010133 : Quest2001Objective
ObjectiveDefines.Obj20010133= {
    Id = 20010133,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200113",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective20010133
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010133
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010134 : Quest2001Objective
ObjectiveDefines.Obj20010134= {
    Id = 20010134,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 614.01, y = 189.9987, z = 1184.46},------------触发点1
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 614.01, y = 189.9987, z = 1184.46},------------触发点1
        ReachDistance = 5,
    },
    ---@param obj QuestObjective20010134
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        local uuid11=proxy:GetLocalPlayerNpcId()
        proxy:SetNpcPosition(uuid11,{x = 614.01, y = 189.9987, z = 1184.46},false)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010134
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010135 : Quest2001Objective
ObjectiveDefines.Obj20010135= {
    Id = 20010135,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200114",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective20010135
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010135
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective200101360 : Quest2001Objective
ObjectiveDefines.Obj200101360= {
    Id = 200101360,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 608.29, y = 189.3382, z = 1145.44},------赛利卡参考点
        ReachDistance = 7,
    },
    ---@param obj QuestObjective200101360
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective200101360
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective200101361 : Quest2001Objective
ObjectiveDefines.Obj200101361= {
    Id = 200101361,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200116",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective200101361
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective200101361
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010136 : Quest2001Objective
ObjectiveDefines.Obj20010136 = {
    Id = 20010136,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        ConditionIds={50000003},
    },
    ---@param obj QuestObjective20010136
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010136
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010137 : Quest2001Objective
ObjectiveDefines.Obj20010137 = {
    Id = 20010137,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        ConditionIds={50000004},
    },
    ---@param obj QuestObjective20010137
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010137
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective200101371 : Quest2001Objective
ObjectiveDefines.Obj200101371 = {
    Id = 200101371,
    Type = EQuestObjectiveType.EnterLevel,
    Args = {
        LevelId = 4001,
        TargetLevelId = 4001,
    },
    ---@param obj QuestObjective200101371
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective200101371
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010138 : Quest2001Objective
ObjectiveDefines.Obj20010138= {
    Id = 20010138,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200117",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective20010138
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010138
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010139 : Quest2001Objective
ObjectiveDefines.Obj20010139= {
    Id = 20010139,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 567.3, y = 196.94, z = 1168.38},------------触发点1
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 567.3, y = 196.94, z = 1168.38},------------触发点1
        ReachDistance = 10,
    },
    ---@param obj QuestObjective20010139
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010139
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010140 : Quest2001Objective
ObjectiveDefines.Obj20010140= {
    Id = 20010140,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200118",--------Drama命名 别忘了
    },
    ---@param obj QuestObjective20010140
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010140
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010141 : Quest2001Objective
ObjectiveDefines.Obj20010141 = {
    Id = 20010141,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200106,-------短信id
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective20010141
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010141
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010142 : Quest2001Objective
ObjectiveDefines.Obj20010142= {
    Id = 20010142,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200119",--------Drama命名 别忘了

    },
    ---@param obj QuestObjective20010142
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010142
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010143 : Quest2001Objective
ObjectiveDefines.Obj20010143= {
    Id = 20010143,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 585.8243, y = 189.9987, z = 1211.554},------------触发点1
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 585.8243, y = 189.9987, z = 1211.554},------------触发点1
        ReachDistance = 3,
    },
    ---@param obj QuestObjective20010143
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010143
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010144 : Quest2001Objective
ObjectiveDefines.Obj20010144= {
    Id = 20010144,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200120",--------Drama命名 别忘了待会儿改成20
    },
    ---@param obj QuestObjective20010144
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC200114PID = 600014-----加载陀螺商会员工
    end,
    ---@param obj QuestObjective20010144
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010144
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid11=proxy:GetLocalPlayerNpcId()
        proxy:SetNpcPosition(uuid11,{x = 604.7062, y = 189.3382, z = 1148.34},false)
        proxy:LoadLevelNpc(obj.NPC200114PID)
        proxy:AddTrialNpcToTeam({113100401},ETrialNpcAddMode.Cover,0)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010145 : Quest2001Objective
ObjectiveDefines.Obj20010145= {
    Id = 20010145,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 600014, ----陀螺商会员工
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [600014] = 0,----陀螺商会员工
            },
        },
    },
    ---@param obj QuestObjective20010145
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010145
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(600014),false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010146 : Quest2001Objective
ObjectiveDefines.Obj20010146= {
    Id = 20010146,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200122",--------Drama命名 别忘了待会儿改成22
    },
    ---@param obj QuestObjective20010146
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective20010146
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010146
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:RemoveTrialNpcFromTeam()---切换回指挥官
        proxy:LoadLevelNpc(600003)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(600003),false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective20010153 : Quest2001Objective
ObjectiveDefines.Obj20010153= {
    Id = 20010153,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 667.98, y = 192.28, z = 1194.82},------------触发点14
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 667.98, y = 192.28, z = 1194.82},------------触发点14
        ReachDistance = 5,
    },
    ---@param obj QuestObjective20010153
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective20010153
    ---@param proxy StatusSyncFight.XFightScriptProxy
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010153
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010154 : Quest2001Objective
ObjectiveDefines.Obj20010154= {
    Id = 20010154,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200125",--------Drama命名 别忘了 待会儿改成25
    },
    ---@param obj QuestObjective20010154
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010154
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(600003),true)
        local pos = { x = 76.383, y = 7.865, z = 55.2803 }
        proxy:RequestEnterInstLevel(4013, pos)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010155 : Quest2001Objective
ObjectiveDefines.Obj20010155= {
    Id = 20010155,
    Type = EQuestObjectiveType.InstanceComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 600003, ----入口
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        InstLevelId = 4013,
        Count = 1,
    },
}

---@class QuestObjective20010156 : Quest2001Objective
ObjectiveDefines.Obj20010156= {
    Id = 20010156,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200130",--------Drama命名 别忘了 改成30

    },
    ---@param obj QuestObjective20010156
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC200117PID = 600003
    end,
    ---@param obj QuestObjective20010156
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(600003),false)
        proxy:UnloadLevelNpc(600014)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010156
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010158 : Quest2001Objective
ObjectiveDefines.Obj20010158= {
    Id = 20010158,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200131",--------Drama命名 别忘了改成32

    },
    ---@param obj QuestObjective20010158
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010158
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010157 : Quest2001Objective
ObjectiveDefines.Obj20010157= {
    Id = 20010157,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 608.29, y = 189.3382, z = 1145.44},------赛利卡参考点
        ReachDistance = 7,
    },
    ---@param obj QuestObjective20010157
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010157
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective20010159 : Quest2001Objective
ObjectiveDefines.Obj20010159 = {
    Id = 20010159,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        ConditionIds={50000005},
    },
    ---@param obj QuestObjective20010159
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010159
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010160 : Quest2001Objective
ObjectiveDefines.Obj20010160 = {
    Id = 20010160,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100020, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        ConditionIds={50000006},
    },
    ---@param obj QuestObjective20010160
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010160
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective200101601 : Quest2001Objective
ObjectiveDefines.Obj200101601 = {
    Id = 200101601,
    Type = EQuestObjectiveType.EnterLevel,
    Args = {
        LevelId = 4001,
        TargetLevelId = 4001,
    },
    ---@param obj QuestObjective200101601
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective200101601
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective20010161 : Quest2001Objective
ObjectiveDefines.Obj20010161= {
    Id = 20010161,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama200132",--------Drama命名 别忘了

    },
    ---@param obj QuestObjective20010161
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20010161
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
local StepDefines = {} --本任务包含的所有任务步骤的参数配置（不要删除！）

--Step的参数配置，至少要有一个，可按需增加
StepDefines.Step200101 = {
    Id = 200101,
    ExecMode = EQuestStepExecMode.Serial,
}

QuestBase.InitSteps(StepDefines) --固定的任务步骤数据初始化调用（不要删除！）
QuestBase.InitQuestObjectives(Quest2001Objective, ObjectiveDefines) --固定的任务目标数据初始化调用（不要删除！）

return Quest_2001