local QuestBase = require("Common/XQuestBase")
---@class XQuestScript2003
local Quest_2003 = XDlcScriptManager.RegQuestScript(2003, "XQuestScript2003", QuestBase)

function Quest_2003:Ctor()
end

function Quest_2003:Init()
end

function Quest_2003:Terminate()
end

-------------------任务目标的基类定义，为了方便访问quest，用任务ID替换这块内容里的9999
---@class Quest2003Objective
local ObjectiveBase = XClass(nil, "Quest2003Objective")

---@param quest XQuestScript2003
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end
-------------------------------------

local ObjectiveDefines = {} --本任务包含的所有任务目标的定义，包含参数和逻辑（不要删除！）
--================================================
--步骤1
--与罗斯交互
---@class QuestObjective20030101 : Quest2003Objective
ObjectiveDefines.Obj20030101 = {
    Id = 20030101,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500003, --罗斯
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500003] = 0,--罗斯
            },
        },
    },
    ---@param obj QuestObjective20030101
    ---@param proxy XDlcCSharpFuncs

    InitFunc = function(obj, proxy)
        obj.SO200301PID = 500001---加载垃圾桶
        obj.NPC200301PID = 500003----加载罗斯
        obj.NPC200302PID = 500001----加载店员A
        obj.NPC200303PID = 500002----加载店员B
    end,

    EnterFunc = function(obj, proxy)
        proxy:UnderTakeSelfQuest()
        proxy:LoadLevelNpc(obj.NPC200301PID)
        proxy:LoadLevelNpc(obj.NPC200302PID)
        proxy:LoadLevelNpc(obj.NPC200303PID)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500002),false)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500001),false)
        proxy:PlayDramaCaption("Caption200301")
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective20030101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤2
--播放罗斯与指挥官的聊天剧情
---@class QuestObjective20030102 : Quest2003Objective
ObjectiveDefines.Obj20030102 = {
    Id = 20030102,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200302",
    },
    ---@param obj QuestObjective20030102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500003),false)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500001),true)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤3
--与艾德交互
---@class QuestObjective20030103 : Quest2003Objective
ObjectiveDefines.Obj20030103 = {
    Id = 20030103,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500001, --店员A
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500001] = 0,--店员A
            },
        },
    },
    ---@param obj QuestObjective20030103
    ---@param proxy XDlcCSharpFuncs

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030103
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective20030103
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤4
--播放艾德与指挥官的聊天剧情
---@class QuestObjective20030104 : Quest2003Objective
ObjectiveDefines.Obj20030104 = {
    Id = 20030104,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200303",
    },
    ---@param obj QuestObjective20030104
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500001),false)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500002),true)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤5
--与海莉交互
---@class QuestObjective20030105 : Quest2003Objective
ObjectiveDefines.Obj20030105 = {
    Id = 20030105,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500002, --店员A
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500002] = 0, --店员A
            },
        },
    },
    ---@param obj QuestObjective20030105
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030105
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤6
--播放海莉与指挥官的聊天剧情
---@class QuestObjective20030106 : Quest2003Objective
ObjectiveDefines.Obj20030106 = {
    Id = 20030106,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200304",
    },
    ---@param obj QuestObjective20030106
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter(20030106)
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500002),false)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500003),true)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤7
--与罗斯交互
---@class QuestObjective20030107 : Quest2003Objective
ObjectiveDefines.Obj20030107 = {
    Id = 20030107,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500003, --罗斯
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500003] = 0,--罗斯
            },
        },
    },
    ---@param obj QuestObjective20030107
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030107
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤8
--播放罗斯与指挥官的聊天剧情
---@class QuestObjective20030108 : Quest2003Objective
ObjectiveDefines.Obj20030108 = {
    Id = 20030108,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200305",
    },
    ---@param obj QuestObjective20030108
    ---@param proxy XDlcCSharpFuncs

    InitFunc = function(obj, proxy)
        obj.NPC200304PID = 500004----加载贾森
        obj.NPC200303PID = 500002
        obj.NPC200302PID = 500001
    end,

    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC200304PID)--生成贾森
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500003),false)
        proxy:UnloadLevelNpc(500002)--销毁店员A
        proxy:UnloadLevelNpc(500001)--销毁店员B
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤10
--寻找贾森
---@class QuestObjective20030110 : Quest2003Objective
ObjectiveDefines.Obj20030110 = {
    Id = 20030110,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500004, --贾森
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 569.2134, y = 168.56, z = 1193.687},
        ReachDistance = 6,
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤11
--播放贾森与指挥官的聊天剧情
---@class QuestObjective20030111 : Quest2003Objective
ObjectiveDefines.Obj20030111 = {
    Id = 20030111,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200306",
        Combinkey = 1,
    },
    ---@param obj QuestObjective20030111
    ---@param proxy XDlcCSharpFuncs
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC200301PID = 500003----加载罗斯
    end,

    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030111
    ---@param proxy XDlcCSharpFuncs

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500004),false)
        proxy:UnloadLevelNpc(500003)--销毁罗斯
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤12
--播放反派登场剧情
---@class QuestObjective20030112 : Quest2003Objective
ObjectiveDefines.Obj20030112 = {
    Id = 20030112,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200307",
    },
    ---@param obj QuestObjective20030112
    ---@param proxy XDlcCSharpFuncs


    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤12_1
--完成咖啡厅关卡2
---@class QuestObjective200301121 : Quest2003Objective
ObjectiveDefines.Obj200301121 = {
    Id = 200301121,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100093, --咖啡厅引导员
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        ConditionIds = {50000102},
    },
    ---@param obj QuestObjective200301121
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective200301121
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(500004)--销毁贾森
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤122
--空花检测
---@class QuestObjective200301122 : Quest2003Objective
ObjectiveDefines.Obj200301122 = {
    Id = 200301122,
    Type = EQuestObjectiveType.EnterLevel,
    Args = {
        LevelId = 4001,
        TargetLevelId = 4001,
    },
}
--步骤123
--播放黑屏白字
---@class QuestObjective200301123 : Quest2003Objective
ObjectiveDefines.Obj200301123 = {
    Id = 200301123,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_2003081",
    },

    InitFunc = function(obj, proxy)
        obj.NPC200305PID = 500005--加载新罗斯
    end,

    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC200305PID)--加载新罗斯
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤13
--阅读罗斯发来的短信
---@class QuestObjective20030113 : Quest2003Objective
ObjectiveDefines.Obj20030113 = {
    Id = 20030113,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200301,
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective20030113
    ---@param proxy XDlcCSharpFuncs

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200302")
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤14
--区域触发
---@class QuestObjective20030114 : Quest2003Objective
ObjectiveDefines.Obj20030114 = {
    Id = 20030114,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500005, --罗斯
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 542.21, y = 168.65, z = 1137.01},
        ReachDistance = 8,
    },
    -----到达区域
    ---@param obj QuestObjective20030114
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)

    end,
    ---@param obj QuestObjective20030114
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤15
--播放与罗斯对话
---@class QuestObjective20030115 : Quest2003Objective
ObjectiveDefines.Obj20030115 = {
    Id = 20030115,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200308",
    },
    ---@param obj QuestObjective20030115
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤16
--与罗斯交互
---@class QuestObjective20030116 : Quest2003Objective
ObjectiveDefines.Obj20030116 = {
    Id = 20030116,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500005, --新罗斯
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500005] = 0,--新罗斯
            },
        },
    },
    ---@param obj QuestObjective20030116
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030116
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}


--步骤18
--打开UI
---@class QuestObjective20030118 : Quest2003Objective
ObjectiveDefines.obj20030118 = {
    Id = 20030118,
    Type = EQuestObjectiveType.UiClosed,
    Args = {
        LevelId = 4001,
        IntParams = { 25 },
        UiName = "UiBigWorldNarrative"
    },
    ---@param obj QuestObjective20030118
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)

   end,
    ---@param obj QuestObjective20030118
    ---@param proxy XDlcCSharpFuncs
   EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030118
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective20030118
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
   end,
}

--步骤181
--播放信件后续剧情
---@class QuestObjective200301181 : Quest2003Objective
ObjectiveDefines.Obj200301181 = {
    Id = 200301181,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200309",
    },
    ---@param obj QuestObjective200301181
    ---@param proxy XDlcCSharpFuncs

    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500005),false)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}


--步骤20
--阅读反派发的短信
---@class QuestObjective20030120 : Quest2003Objective
ObjectiveDefines.Obj20030120 = {
    Id = 20030120,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200302,
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective20030120
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption200303")
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤24
--区域触发
---@class QuestObjective20030124 : Quest2003Objective
ObjectiveDefines.Obj20030124 = {
    Id = 20030124,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 559.39, y = 169.4448, z = 1178.78},
                DisplayOffset = {x = 0, y = 1.5, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 559.39, y = 169.4448, z = 1178.78},
        ReachDistance = 4,
    },
    InitFunc = function(obj, proxy)
        obj.NPC200306PID = 500006----加载氛围NPC
        obj.NPC200307PID = 500007----加载氛围NPC
        obj.NPC200308PID = 500008----加载氛围NPC
        obj.NPC200309PID = 500009----加载氛围NPC
        obj.NPC200310PID = 500010----加载氛围NPC
    end,
    -----到达区域
    ---@param obj QuestObjective20030124
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC200306PID)
        proxy:LoadLevelNpc(obj.NPC200307PID)
        proxy:LoadLevelNpc(obj.NPC200308PID)
        proxy:LoadLevelNpc(obj.NPC200309PID)
        proxy:LoadLevelNpc(obj.NPC200310PID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030124
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective20030124
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤25
--播放与人群对话剧情
---@class QuestObjective20030125 : Quest2003Objective
ObjectiveDefines.Obj20030125 = {
    Id = 20030125,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200310",
    },
    ---@param obj QuestObjective20030125
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC200322PID = 500022----新贾森
    end,
    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC200322PID)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(500005)
        proxy:UnloadLevelNpc(500006)
        proxy:UnloadLevelNpc(500007)
        proxy:UnloadLevelNpc(500008)
        proxy:UnloadLevelNpc(500009)
        proxy:UnloadLevelNpc(500010)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤26
--寻找贾森
---@class QuestObjective20030126 : Quest2003Objective
ObjectiveDefines.Obj20030126 = {
    Id = 20030126,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 538.6931, y = 168.5649, z = 1157.635},
                DisplayOffset = {x = 0, y = 1.5, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 538.6931, y = 168.5649, z = 1157.635},
        ReachDistance = 4,
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤28
--播放贾森登场的剧情
---@class QuestObjective20030128 : Quest2003Objective
ObjectiveDefines.Obj20030128 = {
    Id = 20030128,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200311",
    },
    ---@param obj QuestObjective20030128
    ---@param proxy XDlcCSharpFuncs

    InitFunc = function(obj, proxy)
        obj.NPC200312PID = 500012---加载丸丸熊
        obj.NPC200313PID = 500013---加载约会男
        obj.NPC200314PID = 500014---加载约会女
    end,

    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC200312PID)
        proxy:LoadLevelNpc(obj.NPC200313PID)
        proxy:LoadLevelNpc(obj.NPC200314PID)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030128
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
        if eventType == EWorldEvent.DramaFinish then
            if eventArgs.DramaName == "Drama_200311" then--播放完CG
                proxy:FinishQuestObjectiveScriptEnter()
                XLog.Debug("任务目标20030128，结束enter")
            end
        end
    end,
    ---@param obj QuestObjective20030128
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500022),false)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤29
--寻找丸丸熊（区域）
---@class QuestObjective20030129 : Quest2003Objective
ObjectiveDefines.Obj20030129 = {
    Id = 20030129,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500012, --丸丸熊
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 556.093, y = 181.8306, z = 1182.484},
        ReachDistance = 3,
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤30
--播放丸丸熊剧情
---@class QuestObjective20030130 : Quest2003Objective
ObjectiveDefines.Obj20030130 = {
    Id = 20030130,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200312",
    },
    ---@param obj QuestObjective20030130
    ---@param proxy XDlcCSharpFuncs

    InitFunc = function(obj, proxy)
        obj.NPC200312PID = 500012---加载丸丸熊
        obj.NPC200315PID = 500015---加载新丸丸熊
        obj.SO200302PID = 500003---加载垃圾桶
    end,

    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.SO200302PID)
        proxy:LoadLevelNpc(obj.NPC200315PID)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(500022)--删除新贾森
        proxy:UnloadLevelNpc(500012)--删除丸丸熊
        ----proxy:NpcNavigateTo(proxy:GetNpcUUID(500012), { x =551.5403, y = 168.5649, z = 1187.083 }, ENpcMoveType.Walk)
        proxy:UnloadLevelNpc(500013)--删除可疑NPC
        proxy:UnloadLevelNpc(500014)--删除可疑NPC
        proxy:PlayDramaCaption("Caption200304")
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤301
--寻找丸丸熊
---@class QuestObjective200301301 : Quest2003Objective
ObjectiveDefines.Obj200301301 = {
    Id = 200301301,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500015, --新丸丸熊
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500015] = 0,--新丸丸熊
            },
        },
    },
    ---@param obj QuestObjective200301301
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective200301301
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤302
--播放丸丸熊对话的剧情
---@class QuestObjective200301302 : Quest2003Objective
ObjectiveDefines.Obj200301302 = {
    Id = 200301302,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200313",
    },
    ---@param obj QuestObjective200301302
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500015),false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤31
--完成咖啡厅关卡4
---@class QuestObjective20030131: Quest2003Objective
ObjectiveDefines.Obj20030131 = {
    Id = 20030131,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100093, --咖啡厅引导员
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        ConditionIds = {50000104},
    },
    ---@param obj QuestObjective20030131
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030131
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤311
--空花检测
---@class QuestObjective200301311 : Quest2003Objective
ObjectiveDefines.Obj200301311 = {
    Id = 200301311,
    Type = EQuestObjectiveType.EnterLevel,
    Args = {
        LevelId = 4001,
        TargetLevelId = 4001,
    },
}

--步骤312
--播放黑屏白字
---@class QuestObjective200301312 : Quest2003Objective
ObjectiveDefines.Obj200301312 = {
    Id = 200301312,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_2003131",
    },
    ---@param obj QuestObjective200301312
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500015),true)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤32
--与丸丸熊对话（交互）
---@class QuestObjective20030132 : Quest2003Objective
ObjectiveDefines.Obj20030132 = {
    Id = 20030132,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500015, --新丸丸熊
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500015] = 0,--新丸丸熊
            },
        },
    },
    ---@param obj QuestObjective20030132
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030132
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤33
--播放丸丸熊对话剧情
---@class QuestObjective20030133 : Quest2003Objective
ObjectiveDefines.Obj20030133 = {
    Id = 20030133,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200314",

    },
    ---@param obj QuestObjective20030133
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(500020)
        proxy:UnloadLevelNpc(500015)
        proxy:PlayDramaCaption("Caption200305")
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤34
--找寻垃圾桶
---@class QuestObjective20030134 : Quest2003Objective
ObjectiveDefines.Obj20030134 = {
    Id = 20030134,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 500020, --垃圾桶
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [500020] = 0,--垃圾桶
            },
        },
    },
    ---@param obj QuestObjective20030134
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030134
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(500020)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤35
--打开UI
---@class QuestObjective20030135 : Quest2003Objective
ObjectiveDefines.obj20030135 = {
    Id = 20030135,
    Type = EQuestObjectiveType.UiClosed,
    Args = {
        LevelId = 4001,
        IntParams = { 26 },
        UiName = "UiBigWorldNarrative"
    },
    ---@param obj QuestObjective20030135
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)

    end,
    ---@param obj QuestObjective20030135
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030135
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective20030135
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤37
--播放与丸丸熊的对话
---@class QuestObjective20030137 : Quest2003Objective
ObjectiveDefines.Obj20030137 = {
    Id = 20030137,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200315",
    },
    ---@param obj QuestObjective20030137
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤38
--阅读罗斯发来的短信
---@class QuestObjective20030138 : Quest2003Objective
ObjectiveDefines.Obj20030138 = {
    Id = 20030138,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200303,
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective20030113
    ---@param proxy XDlcCSharpFuncs

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤381
--阅读皮特发来的短信
---@class QuestObjective200301381 : Quest2003Objective
ObjectiveDefines.Obj200301381 = {
    Id = 200301381,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 200304,
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective200301381
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤39
--完成咖啡厅关卡6
---@class QuestObjective20030139 : Quest2003Objective
ObjectiveDefines.Obj20030139 = {
    Id = 20030139,
    Type = EQuestObjectiveType.CheckRimSystemCondition,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100093, --咖啡厅引导员
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        ConditionIds = {50000106},
    },
    ---@param obj QuestObjective20030139
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030139
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤391
--空花检测
---@class QuestObjective200301391 : Quest2003Objective
ObjectiveDefines.Obj200301391 = {
    Id = 200301391,
    Type = EQuestObjectiveType.EnterLevel,
    Args = {
        LevelId = 4001,
        TargetLevelId = 4001,
    },
}

--步骤392
--播放黑屏白字
---@class QuestObjective200301392 : Quest2003Objective
ObjectiveDefines.Obj200301392 = {
    Id = 200301392,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_2003151",
    },
    ---@param obj QuestObjective200301392
    ---@param proxy XDlcCSharpFuncs

    InitFunc = function(obj, proxy)
        obj.NPC200316PID = 500016---加载罗斯
        obj.NPC200317PID = 500017---加载丸丸熊
        obj.NPC200318PID = 500018---加载贾森
        obj.NPC200319PID = 500019---加载机器人
        obj.NPC200320PID = 500027---加载机器人
        obj.NPC200321PID = 500030---加载机器人

    end,

    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC200316PID)
        proxy:LoadLevelNpc(obj.NPC200317PID)
        proxy:LoadLevelNpc(obj.NPC200318PID)
        proxy:LoadLevelNpc(obj.NPC200319PID)
        proxy:LoadLevelNpc(obj.NPC200320PID)
        proxy:LoadLevelNpc(obj.NPC200321PID)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500018),false)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤40
--丸丸熊对话（交互）
---@class QuestObjective20030140 : Quest2003Objective
ObjectiveDefines.Obj20030140 = {
    Id = 20030140,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500017, --丸丸熊
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500017] = 0,--丸丸熊
            },
        },
    },
    ---@param obj QuestObjective20030140
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective20030140
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤41
--播放与丸丸熊的对话
---@class QuestObjective20030141 : Quest2003Objective
ObjectiveDefines.Obj20030141 = {
    Id = 20030141,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200316",
    },
    ---@param obj QuestObjective20030141
    ---@param proxy XDlcCSharpFuncs

    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500017),false)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500018),true)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤42
--跟贾森对话（交互）
---@class QuestObjective20030142 : Quest2003Objective
ObjectiveDefines.Obj20030142 = {
    Id = 20030142,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500018, --丸丸熊
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500018] = 0,--丸丸熊
            },
        },
    },
    ---@param obj QuestObjective20030142
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter(20030142)
    end,
    ---@param obj QuestObjective20030142
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit(20030142)
    end,
}
--步骤43
--播放与贾森的对话
---@class QuestObjective20030143 : Quest2003Objective
ObjectiveDefines.Obj20030143 = {
    Id = 20030143,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_200317",
    },
    ---@param obj QuestObjective20030143
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter(20030143)
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(500016)
        proxy:UnloadLevelNpc(500017)
        proxy:UnloadLevelNpc(500018)
        proxy:UnloadLevelNpc(500019)
        proxy:FinishQuestObjectiveScriptExit(20030143)
    end,
}

local StepDefines = {} --本任务包含的所有任务步骤的参数配置（不要删除！）

--Step的参数配置，至少要有一个，可按需增加
StepDefines.Step200301 = {
    Id = 200301,
    ExecMode = EQuestStepExecMode.Serial,
}

QuestBase.InitSteps(StepDefines) --固定的任务步骤数据初始化调用（不要删除！）
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines) --固定的任务目标数据初始化调用（不要删除！）

return Quest_2003