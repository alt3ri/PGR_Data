local QuestBase = require("Common/XQuestBase")
---@class XQuestScript4022 : XQuestBase
local XQuestScript4022 = XDlcScriptManager.RegQuestScript(4022, "XQuestScript4022", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript4022:Ctor(proxy)
end

function XQuestScript4022:Init()

end

function XQuestScript4022:Terminate()
end

---@class Quest4022Objective
local ObjectiveBase = XClass(nil, "Quest4022Objective")

---@param quest XQuestScript4022
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }
local ObjectiveDefines = {}

---@class QuestObjective40220100 : Quest4022Objective
ObjectiveDefines.Obj40220100 = {
    Id = 40220100, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4022,
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
    ---@param obj QuestObjective40220100
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,

    ---@param obj QuestObjective40220100
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)

        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40220100
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective40220101 : Quest4022Objective
ObjectiveDefines.Obj40220101 = {
    Id = 40220101, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.DramaPlayFinish, --该任务目标的类型，只能使用枚举EQuestObjectiveType来填（必填！）
    Args = {
        LevelId = 4022,
        DramaName = "Drama200502",
    },
}

---@class QuestObjective40220102 : Quest4022Objective
ObjectiveDefines.Obj40220102 = {
    Id = 40220102, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.TakePhotoComplete, --该任务目标的类型，只能使用枚举EQuestObjectiveType来填（必填！）
    Args = {
        LevelId = 4022, --该任务目标所属关卡（必填！）
        CamParamId = 8,
        DetectionNpcPlaceIdList ={100002},
        DetectionSceneObjectPlaceIdList = {},
    },

    ---@param obj QuestObjective40220102
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC402201PID = 100002----加载薇拉
    end,

    ---@param obj QuestObjective40220102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(obj.NPC402201PID)--生成薇拉
        local uuid1=proxy:GetLocalPlayerNpcId()
        proxy:SetNpcPosAndRot(uuid1,{x = 603.908, y = 189.338, z = 1147.39},{x = 0, y = 120, z =0},false)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40220102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective40220103 : Quest4022Objective
ObjectiveDefines.Obj40220103 = {
    Id = 40220103, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4022,
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
    ---@param obj QuestObjective40220103
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,

    ---@param obj QuestObjective40220103
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(100008)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40220103
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishInstLevel()
        proxy:RequestLeaveInstanceLevel(true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

local StepDefines = {}

StepDefines.Step402201 = {
    Id = 402201,
    ExecMode = EQuestStepExecMode.Serial,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines)