local QuestBase = require("Common/XQuestBase")
---@class XQuestScript4021 : XQuestBase
local XQuestScript4021 = XDlcScriptManager.RegQuestScript(4021, "XQuestScript4021", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript4021:Ctor(proxy)
end

function XQuestScript4021:Init()

end

function XQuestScript4021:Terminate()
end

---@class Quest4021Objective
local ObjectiveBase = XClass(nil, "Quest4021Objective")

---@param quest XQuestScript4021
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }
local ObjectiveDefines = {}

---@class QuestObjective40210100 : Quest4021Objective
ObjectiveDefines.Obj40210100 = {
    Id = 40210100, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4021,
        TracePosArgs = {
            {
                Position={x = 602.479919, y = 189.338165, z = 1148.56311},------------一会儿来改参数
                DisplayOffset = {x = 0, y = 2.2, z = 0},
                ShowEffect = true,
                ForceMapPinActive = false,
            },
        },
        TargetPosition={x = 602.479919, y = 189.338165, z = 1148.56311},------------一会儿来改参数
        ReachDistance = 3,
    },
    ---@param obj QuestObjective40210100
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,

    ---@param obj QuestObjective40210100
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40210100
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}


---@class QuestObjective40210101 : Quest4021Objective
ObjectiveDefines.Obj40210101 = {
    Id = 40210101, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.DramaPlayFinish, --该任务目标的类型，只能使用枚举EQuestObjectiveType来填（必填！）
    Args = {
        LevelId = 4021,
        DramaName = "Drama200402",
    },
    ---@param obj QuestObjective40210101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)

    end,

    ---@param obj QuestObjective40210101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(100108)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40210101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(100108)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective40210102 : Quest4021Objective
ObjectiveDefines.Obj40210102 = {
    Id = 40210102, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.TakePhotoComplete, --该任务目标的类型，只能使用枚举EQuestObjectiveType来填（必填！）
    Args = {
        LevelId = 4021, --该任务目标所属关卡（必填！）
        CamParamId = 8,
        DetectionNpcPlaceIdList ={100003},
        DetectionSceneObjectPlaceIdList = {},
    },

    ---@param obj QuestObjective40210102
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC402101PID = 100003----加载露西亚
    end,

    ---@param obj QuestObjective40210102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC402101PID)--生成露西亚
        local uuid1=proxy:GetLocalPlayerNpcId()
        proxy:SetNpcPosAndRot(uuid1,{x = 603.908, y = 189.338, z = 1147.39},{x = 0, y = 120, z =0},false)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40210102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective40210103 : Quest4021Objective
ObjectiveDefines.Obj40210103 = {
    Id = 40210103, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4021,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100001, ----赛利卡
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [100008] = 0,----赛利卡
            },
        },
    },
    ---@param obj QuestObjective40210103
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,

    ---@param obj QuestObjective40210103
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(100008)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40210103
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishInstLevel()
        proxy:RequestLeaveInstanceLevel(true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

local StepDefines = {}

StepDefines.Step402101 = {
    Id = 402101,
    ExecMode = EQuestStepExecMode.Serial,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines)