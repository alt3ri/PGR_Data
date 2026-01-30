local QuestBase = require("Common/XQuestBase")
---@class XQuestScript3005
local Quest_3005 = XDlcScriptManager.RegQuestScript(3005, "XQuestScript3005", QuestBase)

function Quest_3005:Ctor()
end

function Quest_3005:Init()
end

function Quest_3005:Terminate()
end

-------------------任务目标的基类定义，为了方便访问quest，用任务ID替换这块内容里的9999
---@class Quest3005Objective
local ObjectiveBase = XClass(nil, "Quest3005Objective")

---@param quest XQuestScript3005
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end
-------------------------------------

local ObjectiveDefines = {} --本任务包含的所有任务目标的定义，包含参数和逻辑（不要删除！）
--================================================
--步骤1
--与奇怪的库洛洛交互
---@class QuestObjective30050101 : Quest3005Objective
ObjectiveDefines.Obj30050101 = {
    Id = 30050101,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500024, ----奇怪的库洛洛
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500024] = 0,----奇怪的库洛洛
            },
        },
    },

    InitFunc = function(obj, proxy)
        obj.NPC300501PID = 500024----注册奇怪的库洛洛
    end,

    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC300501PID)
        proxy:SetNpcQuestTipIconActive(500024,3005,true)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnderTakeSelfQuest()
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤2
--播放奇怪库洛洛的登场剧情
---@class QuestObjective30050102 : Quest3005Objective
ObjectiveDefines.Obj30050102 = {
    Id = 30050102,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3005_001",
    },

    EnterFunc = function(obj, proxy)
        proxy:SetNpcQuestTipIconActive(500024,3005,false)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(500024)----删除库洛洛
        proxy:PlayDramaCaption("Caption300501",true) --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤3
--阅读工作人员发来的短信
---@class QuestObjective30050103 : Quest3005Objective
ObjectiveDefines.Obj30050103 = {
    Id = 30050103,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 300501,
        AutoSend = true, --enter时，自动发送短信
    },

    InitFunc = function(obj, proxy)
        obj.NPC300502PID = 500025----注册自恋的库洛洛
    end,

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC300502PID)----生成自恋的库洛洛
        proxy:PlayDramaCaption("Caption300502") --播放简易字幕
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤4
--区域触发
---@class QuestObjective30050104 : Quest3005Objective
ObjectiveDefines.Obj30050104 = {
    Id = 30050104,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 682.3409, y = 156.176, z = 1215.49},----到达银河时尚旁边
                DisplayOffset = {x = 0, y = 0, z = 0},
                ShowEffect = true,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 682.3409, y = 156.176, z = 1215.49},
        ReachDistance = 8,
    },
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤5
--播放自恋的库洛洛与指挥官的聊天剧情
---@class QuestObjective30050105 : Quest3005Objective
ObjectiveDefines.Obj30050105  = {
    Id = 30050105 ,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3005_002",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(500025)----删除自恋的库洛洛
        proxy:LoadLevelNpc(500016)----生成新自恋的库洛洛
        proxy:LoadSceneObject(500018)
        proxy:SetNpcPosAndRot( proxy:GetLocalPlayerNpcId(), {x = 680.4954, y = 156.2298, z = 1218.132},  {x = 0, y = -84.625, z = 0}, true )
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--步骤6
--为库洛洛拍照
---@class QuestObjective30050106 : Quest3005Objective
ObjectiveDefines.Obj30050106 = {
    Id = 30050106,
    Type = EQuestObjectiveType.TakePhotoComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500016, ----自恋的库洛洛
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        CamParamId=7,
        DetectionNpcPlaceIdList = {  },-----新自恋库洛洛的PID
        DetectionSceneObjectPlaceIdList = { 500018 },-----场景物品的PID
    },

    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(500010)
        proxy:LoadSceneObject(500011)
        proxy:LoadSceneObject(500012)
        proxy:LoadSceneObject(500013)
        proxy:LoadSceneObject(500014)
        proxy:LoadSceneObject(500015)
        proxy:LoadSceneObject(500016)
        proxy:LoadSceneObject(500017)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤7
--将照片交给自恋的库洛洛
---@class QuestObjective30050107 : Quest3005Objective
ObjectiveDefines.Obj30050107 = {
    Id = 30050107,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500016, ----新自恋的库洛洛
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500016] = 0,----新自恋的库洛洛
            },
        },
    },

    InitFunc = function(obj, proxy)
    end,

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤8
--播放自恋的库洛洛与指挥官的聊天剧情
---@class QuestObjective30050108 : Quest3005Objective
ObjectiveDefines.Obj30050108  = {
    Id = 30050108 ,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3005_003",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(500016)----删除新自恋的库洛洛
        proxy:UnloadSceneObject(500010)
        proxy:UnloadSceneObject(500011)
        proxy:UnloadSceneObject(500012)
        proxy:UnloadSceneObject(500013)
        proxy:UnloadSceneObject(500014)
        proxy:UnloadSceneObject(500015)
        proxy:UnloadSceneObject(500016)
        proxy:UnloadSceneObject(500017)
        proxy:AddTimerTask(1,function()
            proxy:PlayDramaCaption("Caption300503") --播放简易字幕
        end)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤9
--区域触发
---@class QuestObjective30050109 : Quest3005Objective
ObjectiveDefines.Obj30050109 = {
    Id = 30050109,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4001,
        TracePosArgs = {
            {
                Position={x = 568.697, y = 145.2953, z = 1385.01},----到达宿舍旁边
                DisplayOffset = {x = 0, y = 0, z = 0},
                ShowEffect = true,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 568.697, y = 145.2953, z = 1385.01},
        ReachDistance = 8,
    },
    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(500029)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤10
--播放激动的库洛洛与指挥官的聊天剧情
---@class QuestObjective30050110 : Quest3005Objective
ObjectiveDefines.Obj30050110  = {
    Id = 30050110 ,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3005_004",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:UnloadLevelNpc(500029)
        proxy:AddTimerTask(2,function()
            proxy:PlayDramaCaption("Caption300504") --播放简易字幕
        end)
        proxy:LoadLevelNpc(500028)----加载好胜的库洛洛
        proxy:LoadLevelNpc(500026)----加载工作人员
        proxy:LoadSceneObject(500009)----加载跳跳乐装置
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤11
--与工作人员交互
---@class QuestObjective30050111 : Quest3005Objective
ObjectiveDefines.Obj30050111 = {
    Id = 30050111,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500028, ----工作人员
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500028] = 0,----工作人员
            },
        },
    },

    InitFunc = function(obj, proxy)
    end,

    EnterFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500026),false)----关闭工作人员的交互
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤12
--播放好胜的库洛洛与指挥官的聊天剧情
---@class QuestObjective30050112 : Quest3005Objective
ObjectiveDefines.Obj30050112  = {
    Id = 30050112 ,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3005_005",
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        local pos = { x = 243.7, y = 36.6, z = 322.7 }
        proxy:RequestEnterInstLevel(4025, pos)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500028),false)----关闭库洛洛的交互
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500026),true)----开启工作人员的交互，作为关卡入口
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤121
--检测跳跳乐完成
---@class QuestObjective300501121 : Quest3005Objective
ObjectiveDefines.Obj300501121= {
    Id = 300501121, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.InstanceComplete,
    Args = {
        LevelId = 4001,
        InstLevelId = 4025,
        Count = 1,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 500009, ----工作人员
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
    },

    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter(300501121)
    end,

    ExitFunc = function(obj, proxy)
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500026),false)----关闭工作人员的交互
        proxy:SetActorInteractableComponentEnable(proxy:GetNpcUUID(500028),true)----关闭库洛洛的交互
        proxy:FinishQuestObjectiveScriptExit(300501121)
    end,
}

--步骤13
--与好胜的库洛洛交互
---@class QuestObjective30050113 : Quest3005Objective
ObjectiveDefines.Obj30050113 = {
    Id = 30050113,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 500028, ----好胜的库洛洛
                DisplayOffset = { x = 0, y = 1.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500028] = 0,----好胜的库洛洛
            },
        },
    },
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,

    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--步骤14
--播放工作人员与指挥官的聊天剧情
---@class QuestObjective30050114 : Quest3005Objective
ObjectiveDefines.Obj30050114  = {
    Id = 30050114 ,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4001,
        DramaName = "Drama_3005_006",
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
StepDefines.Step300501 = {
    Id = 300501,
    ExecMode = EQuestStepExecMode.Serial,
}

QuestBase.InitSteps(StepDefines) --固定的任务步骤数据初始化调用（不要删除！）
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines) --固定的任务目标数据初始化调用（不要删除！）

return Quest_3005