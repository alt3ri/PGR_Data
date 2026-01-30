local QuestBase = require("Common/XQuestBase")
---@class XQuestScript4011 : XQuestBase
local XQuestScript4011 = XDlcScriptManager.RegQuestScript(4011, "XQuestScript4011", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript4011:Ctor(proxy)
end

function XQuestScript4011:Init()

end

function XQuestScript4011:Terminate()
end

---@class Quest4011Objective
local ObjectiveBase = XClass(nil, "Quest4011Objective")

---@param quest XQuestScript4011
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}


--01.播放B1级动画：展示阿呆蛙场景
---@class QuestObjective40110101 : Quest4011Objective
ObjectiveDefines.Obj40110101 = {
    Id = 40110101,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4011,
        DramaName = "Drama_1001_033",
    },
    ---@param obj QuestObjective40110101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40110101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--02.到达指定地点查看阿呆蛙
---@class QuestObjective40110102 : Quest4011Objective
ObjectiveDefines.Obj40110102 = {
    Id = 40110102,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4011,
        TracePosArgs = {
            {
                Position = { x = 29.13, y = 56.59, z = 16.97 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 29.13, y = 56.59, z = 16.97 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40110102
    InitFunc = function(obj)
    end,
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--03.播放B1级动画：阿呆蛙让指挥官去找东西
---@class QuestObjective40110103 : Quest4011Objective
ObjectiveDefines.Obj40110103 = {
    Id = 40110103,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4011,
        DramaName = "Drama_1001_034",
    },
    ---@param obj QuestObjective40110103
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110103
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40110103
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--04.找礼物盒1
---@class QuestObjective40110104 : Quest4012Objective
ObjectiveDefines.Obj40110104 = {
    Id = 40110104,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4011,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 4,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [4] = 0,--礼物盒1
            },
        },
    },
    ---@param obj QuestObjective40110104
    InitFunc = function(obj)
        obj.soRabbitCakeP1ID = 4
    end,
    ---@param obj QuestObjective40110104
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP1ID)
        proxy:AddTimerTask(0.5, function()
            proxy:PlayDramaCaption("Caption100108") --播放简易字幕
        end)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110104
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--05.找礼物盒2
---@class QuestObjective40110105 : Quest4012Objective
ObjectiveDefines.Obj40110105 = {
    Id = 40110105,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4011,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 5,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [5] = 0,--礼物盒2
            },
        },
    },
    ---@param obj QuestObjective40110105
    InitFunc = function(obj)
        obj.soRabbitCakeP1ID = 5
        obj.soRabbitCakeP2ID = 3
    end,
    ---@param obj QuestObjective40110105
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP1ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP2ID)
        proxy:PlayDramaCaption("Caption100109") --播放简易字幕
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110105
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--06.到达指定地点查看阿呆蛙
---@class QuestObjective40110106 : Quest4011Objective
ObjectiveDefines.Obj40110106 = {
    Id = 40110106,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4011,
        TracePosArgs = {
            {
                Position = { x = 29.13, y = 56.59, z = 16.97 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 29.13, y = 56.59, z = 16.97 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40110106
    InitFunc = function(obj)
        obj.soRabbitCakeP2ID = 3
    end,
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:PlayDramaCaption("Caption100111") --播放简易字幕
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110106
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP2ID)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--07.播放B1级动画：回复阿呆蛙
---@class QuestObjective40110107 : Quest4011Objective
ObjectiveDefines.Obj40110107 = {
    Id = 40110107,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4011,
        DramaName = "Drama_1001_035",
    },
    ---@param obj QuestObjective40110107
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110107
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40110107
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--08.找金色萤火虫
---@class QuestObjective40110108 : Quest4012Objective
ObjectiveDefines.Obj40110108 = {
    Id = 40110108,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4011,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 6,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [6] = 0,--礼物盒2
            },
        },
    },
    ---@param obj QuestObjective40110108
    InitFunc = function(obj)
        obj.soRabbitCakeP1ID = 6
        obj.soRabbitCakeP2ID = 7
        obj.soRabbitCakeP3ID = 8
        obj.soRabbitCakeP4ID = 9
        obj.soRabbitCakeP5ID = 10
        obj.soRabbitCakeP6ID = 11
        obj.soRabbitCakeP7ID = 12
        obj.soRabbitCakeP8ID = 13
        obj.soRabbitCakeP9ID = 14
        obj.soRabbitCakeP10ID = 15
        obj.soRabbitCakeP11ID = 16
    end,
    ---@param obj QuestObjective40110108
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP1ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP2ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP3ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP4ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP5ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP6ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP7ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP8ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP9ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP10ID)
        proxy:LoadSceneObject(obj.soRabbitCakeP11ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110108
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--09.播放B1级动画：发现萤火虫
---@class QuestObjective40110109 : Quest4011Objective
ObjectiveDefines.Obj40110109 = {
    Id = 40110109,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4011,
        DramaName = "Drama_1001_036",
    },
    ---@param obj QuestObjective40110109
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110109
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40110109
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--10.播放B1级动画：讲信息告诉鼹鼠妈妈
---@class QuestObjective40110110 : Quest4011Objective
ObjectiveDefines.Obj40110110 = {
    Id = 40110110,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4011,
        DramaName = "Drama_1001_037",
    },
    ---@param obj QuestObjective40110110
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110107
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40110110
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--11.和传送门交互离开副本
---@class QuestObjective40110111 : Quest4012Objective
ObjectiveDefines.Obj40110111 = {
    Id = 40110111,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4011,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 1,
                DisplayOffset = { x = 0, y = 1, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [1] = 0,-- 传送门
            },
        },
    },
    ---@param obj QuestObjective40110111
    InitFunc = function(obj)
        obj.soRabbitCakeP1ID = 1
        obj.soRabbitCakeP2ID = 6
    end,
    ---@param obj QuestObjective40110111
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakeP2ID)
        proxy:PlayDramaCaption("Caption100110") --播放简易字幕
        proxy:LoadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40110111
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:PlayStayScreenEffectById(1001001)
        proxy:UnloadSceneObject(obj.soRabbitCakeP1ID)
        proxy:AddTimerTask(1.1, function()
            proxy:FinishInstLevel() --标记当前副本关卡完成
            proxy:RequestLeaveInstanceLevel(false)
            proxy:FinishQuestObjectiveScriptExit()
        end)
    end,
}

local StepDefines = {}

StepDefines.Step401101 = {
    Id = 401101,
    ExecMode = EQuestStepExecMode.Serial,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines)