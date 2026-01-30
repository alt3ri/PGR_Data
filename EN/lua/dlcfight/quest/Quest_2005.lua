local QuestBase = require("Common/XQuestBase")
---@class XQuestScript2005
local Quest_2005 = XDlcScriptManager.RegQuestScript(2005, "XQuestScript2005", QuestBase)

function Quest_2005:Ctor()
end

function Quest_2005:Init()
end

function Quest_2005:Terminate()
end

-------------------任务目标的基类定义，为了方便访问quest，用任务ID替换这块内容里的2005
---@class Quest2005Objective
local ObjectiveBase = XClass(nil, "Quest2005Objective")

---@param quest XQuestScript2005
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end
-------------------------------------

local ObjectiveDefines = {} --本任务包含的所有任务目标的定义，包含参数和逻辑（不要删除！）

---@class QuestObjective20050101 : Quest2005Objective
ObjectiveDefines.Obj20050101 = {
    Id = 20050101, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.InteractComplete, --该任务目标的类型，只能使用枚举EQuestObjectiveType来填（必填！）
    Args = {
        LevelId = 4001, --该任务目标所属关卡（必填！）
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 600020, --薇拉
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,

            }
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [600020] = 0,--薇拉
            },
        },
    },
    ---@param obj QuestObjective20050101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC600020PID = 600020----加载薇拉
    end,
    ---@param obj QuestObjective20050101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:UnderTakeSelfQuest()
        proxy:LoadLevelNpc(obj.NPC600020PID)--生成薇拉
        proxy:FinishQuestObjectiveScriptEnter(20050101)
    end,
    ---@param obj QuestObjective20050101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective20050101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local pos = { x = 605.746094, y = 189.338181, z = 1146.83838 }

        proxy:FinishQuestObjectiveScriptExit(20050101)
    end,
}
---@class QuestObjective200501011 : Quest2005Objective
ObjectiveDefines.Obj200501011= {
    Id = 200501011, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.DramaPlayFinish, --该任务目标的类型，只能使用枚举EQuestObjectiveType来填（必填！）
    Args = {
        LevelId = 4001,
        DramaName = "Drama200501",
    },
    ---@param obj QuestObjective200501011
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC600020PID = 600020----加载薇拉
    end,
    ---@param obj QuestObjective200501011
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter(200501011)
    end,
    ---@param obj QuestObjective200501011
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective200501011
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local pos = { x = 605.746094, y = 189.338181, z = 1146.83838 }
        proxy:RequestEnterInstLevel(4022, pos)
        proxy:UnloadLevelNpc(obj.NPC600020PID)--销毁薇拉
        proxy:FinishQuestObjectiveScriptExit(200501011)
    end,
}

---@class QuestObjective20050102 : Quest2005Objective
ObjectiveDefines.Obj20050102= {
    Id = 20050102, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.InstanceComplete,
    Args = {
        LevelId = 4001,
        --DramaName = "CE_Dialog01",
        InstLevelId = 4022,
        Count = 1,
    },
    ---@param obj QuestObjective20050102
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)

    end,
    ---@param obj QuestObjective20050102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(600022)---创建再次进入副本的入口
        proxy:FinishQuestObjectiveScriptEnter(20050102)
    end,
    ---@param obj QuestObjective20050102
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective20050102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit(20050102)
    end,
}

local StepDefines = {} --本任务包含的所有任务步骤的参数配置（不要删除！）

--Step的参数配置，至少要有一个，可按需增加
StepDefines.Step200501 = {
    Id = 200501,
    ExecMode = EQuestStepExecMode.Serial,
}

QuestBase.InitSteps(StepDefines) --固定的任务步骤数据初始化调用（不要删除！）
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines) --固定的任务目标数据初始化调用（不要删除！）

return Quest_2005