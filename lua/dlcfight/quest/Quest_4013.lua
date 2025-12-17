local QuestBase = require("Common/XQuestBase")
---@class XQuestScript4013 : XQuestBase
local XQuestScript4013 = XDlcScriptManager.RegQuestScript(4013, "XQuestScript4013", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript4013:Ctor(proxy)
end

function XQuestScript4013:Init()

end

function XQuestScript4013:Terminate()
end

---@class Quest4013Objective
local ObjectiveBase = XClass(nil, "Quest4013Objective")

---@param quest XQuestScript4013
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}

---@class QuestObjective40130101 : Quest4013Objective
ObjectiveDefines.Obj40130101 = {
    Id = 40130101,
    Type = EQuestObjectiveType.NarrativeComplete,
    Args = {
        LevelId = 4013,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 1,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        NarrativeIds = {41}
    },
    ---@param obj QuestObjective40130101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective40130101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(1)
        proxy:LoadSceneObject(2)
        proxy:LoadSceneObject(3)
        proxy:LoadSceneObject(4)
        proxy:FinishQuestObjectiveScriptEnter(40130101)
    end,
    ---@param obj QuestObjective40130101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective40130101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptExit(40130101)
    end,
}
---@class QuestObjective40130102 : Quest4013Objective
ObjectiveDefines.Obj40130102 = {
    Id = 40130102,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4013,
        DramaName = "Drama200126",
    },
    ---@param obj QuestObjective40130102
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective40130102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptEnter(40130102)
    end,
    ---@param obj QuestObjective40130102
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40130102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local uuid1 = proxy:GetLocalPlayerNpcId()
        proxy:SetNpcPosition(uuid1,{x = 67.75342, y = 21.046, z = 74.6273},false)

        proxy:FinishQuestObjectiveScriptExit(40130102)
    end,
}
---@class QuestObjective40130103 : Quest4013Objective
ObjectiveDefines.Obj40130103 = {
    Id = 40130103,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4013,
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
                [4] = 0,
            },
        },
    },
    ---@param obj QuestObjective40130103
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective40130103
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:AddTrialNpcToTeam({113100401},ETrialNpcAddMode.Cover,0)
        proxy:FinishQuestObjectiveScriptEnter(40130103)
    end,
    ---@param obj QuestObjective40130103
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40130103
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptExit(40130103)
    end,
}
---@class QuestObjective40130104 : Quest4013Objective
ObjectiveDefines.Obj40130104 = {
    Id = 40130104,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4013,
        DramaName = "Drama200127",
    },
    ---@param obj QuestObjective40130104
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective40130104
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptEnter(40130104)
    end,
    ---@param obj QuestObjective40130104
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40130104
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)


        proxy:RemoveTrialNpcFromTeam()
        local uuid1 = proxy:GetLocalPlayerNpcId()
        proxy:SetNpcPosition(uuid1,{x = 48.09212, y = 16.26238, z = 74.50628},false)
        proxy:FinishQuestObjectiveScriptExit(40130104)
    end,
}
---@class QuestObjective40130105 : Quest4013Objective
ObjectiveDefines.Obj40130105 = {
    Id = 40130105,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4013,
        TracePosArgs = {
            {
                Position={x = 39, y = 14, z =74 },------------触发点14Vector3(39.923069,14.0856047,74.3585129)
            DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 39, y = 14, z = 74},------------触发点14
        ReachDistance = 3,
    },
    ---@param obj QuestObjective40130105
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective40130105
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptEnter(40130105)
    end,
    ---@param obj QuestObjective40130105
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40130105
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(13)
        proxy:FinishQuestObjectiveScriptExit(40130105)
    end,
}
---@class QuestObjective40130106 : Quest4013Objective
ObjectiveDefines.Obj40130106 = {
    Id = 40130106,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4013,
        DramaName = "Drama200128",
    },
    ---@param obj QuestObjective40130106
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective40130106
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptEnter(40130106)
    end,
    ---@param obj QuestObjective40130106
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40130106
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptExit(40130106)
    end,
}
---@class QuestObjective40130107 : Quest4013Objective
ObjectiveDefines.Obj40130107 = {
    Id = 40130107,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4013,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 2,
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [2] = 0,
            },
        },
    },
    ---@param obj QuestObjective40130107
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective40130107
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(13)
        proxy:FinishQuestObjectiveScriptEnter(40130107)
    end,


}
---@class QuestObjective40130108 : Quest4013Objective
ObjectiveDefines.Obj40130108 = {
    Id = 40130108,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4013,
        DramaName = "Drama200129",
    },
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishInstLevel() --标记当前副本关卡完成
        proxy:FinishQuestObjectiveScriptEnter(40130108)
    end,
    ---@param obj QuestObjective40130107
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:RequestLeaveInstanceLevel(true)
        proxy:FinishQuestObjectiveScriptExit(40130108)
    end,
}

local StepDefines = {}

StepDefines.Step401301 = {
    Id = 401301,
    ExecMode = EQuestStepExecMode.Serial,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines)