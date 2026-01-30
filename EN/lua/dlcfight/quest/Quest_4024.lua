local QuestBase = require("Common/XQuestBase")
---@class XQuestScript4024 : XQuestBase
local XQuestScript4024 = XDlcScriptManager.RegQuestScript(4024, "XQuestScript4024", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript4024:Ctor(proxy)
end

function XQuestScript4024:Init()

end

function XQuestScript4024:Terminate()
end

---@class Quest4024Objective
local ObjectiveBase = XClass(nil, "Quest4024Objective")

---@param quest XQuestScript4024
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}

--01.播放A1级动画：回到筑梦之境
---@class QuestObjective40240101 : Quest4024Objective
ObjectiveDefines.Obj40240101 = {
    Id = 40240101,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4024,
        DramaName = "Drama_1001_046",
    },
    ---@param obj QuestObjective40240101
    InitFunc = function(obj)
        obj.soRabbitCakeP1ID = 100001
    end,
    ---@param obj QuestObjective40240101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakeP1ID)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40240101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40240101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--02.和传送门交互离开副本
---@class QuestObjective40240102 : Quest4012Objective
ObjectiveDefines.Obj40240102 = {
    Id = 40240102,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4024,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 100001,
                DisplayOffset = { x = 0, y = 1, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [100001] = 0,-- 传送门
            },
        },
    },
    ---@param obj QuestObjective40240102
    InitFunc = function(obj)
    end,
    ---@param obj QuestObjective40240102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40240102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishInstLevel() --标记当前副本关卡完成
        proxy:RequestLeaveInstanceLevel(false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

local StepDefines = {}

StepDefines.Step402401 = {
    Id = 402401,
    ExecMode = EQuestStepExecMode.Serial,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines)