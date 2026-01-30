local QuestBase = require("Common/XQuestBase")
---@class XQuestScript2004
local Quest_2004 = XDlcScriptManager.RegQuestScript(2004, "XQuestScript2004", QuestBase)

function Quest_2004:Ctor()
end

function Quest_2004:Init()
end

function Quest_2004:Terminate()
end

-------------------任务目标的基类定义，为了方便访问quest，用任务ID替换这块内容里的2004
---@class Quest2004Objective
local ObjectiveBase = XClass(nil, "Quest2004Objective")

---@param quest XQuestScript2004
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end
-------------------------------------

local ObjectiveDefines = {} --本任务包含的所有任务目标的定义，包含参数和逻辑（不要删除！）

---@class QuestObjective20040101 : Quest2004Objective
ObjectiveDefines.Obj20040101 = {
    Id = 20040101, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.InteractComplete, --该任务目标的类型，只能使用枚举EQuestObjectiveType来填（必填！）
    Args = {
        LevelId = 4001, --该任务目标所属关卡（必填！）
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 600018, --露西亚
                DisplayOffset = { x = 0, y = 2.0, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            }
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [600018] = 0,--露西亚
            },
        },
    },
    ---@param obj QuestObjective20040101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC600018PID = 600018----加载露西亚
    end,
    ---@param obj QuestObjective20040101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:UnderTakeSelfQuest()
        proxy:LoadLevelNpc(obj.NPC600018PID)--生成露西亚
        proxy:FinishQuestObjectiveScriptEnter(20040101)
    end,
    ---@param obj QuestObjective20040101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective20040101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit(20040101)
    end,
}

---@class QuestObjective200401011 : Quest2004Objective
ObjectiveDefines.Obj200401011= {
    Id = 200401011, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.DramaPlayFinish, --该任务目标的类型，只能使用枚举EQuestObjectiveType来填（必填！）
    Args = {
        LevelId = 4001,
        DramaName = "Drama200401",
    },
    ---@param obj QuestObjective200401011
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.NPC600018PID = 600018----加载露西亚
    end,
    ---@param obj QuestObjective200401011
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter(200401011)
    end,
    ---@param obj QuestObjective200401011
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective200401011
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local pos = { x = 605.746094, y = 189.338181, z = 1146.83838 }
        proxy:RequestEnterInstLevel(4021, pos)
        proxy:UnloadLevelNpc(obj.NPC600018PID)--销毁露西亚
        proxy:FinishQuestObjectiveScriptExit(200401011)
    end,
}


---@class QuestObjective20040102 : Quest2004Objective
ObjectiveDefines.Obj20040102= {
    Id = 20040102, --该任务目标的ID，和配表里的保持一致（必填！）
    Type = EQuestObjectiveType.InstanceComplete,
    Args = {
        LevelId = 4001,
        InstLevelId = 4021,
        Count = 1,
    },
    ---@param obj QuestObjective20040102
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)

    end,
    ---@param obj QuestObjective20040102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadLevelNpc(600021)---创建再次进入副本的入口
        proxy:FinishQuestObjectiveScriptEnter(20040102)
    end,
    ---@param obj QuestObjective20040102
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)

    end,
    ---@param obj QuestObjective20040102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit(20040102)
    end,
}


local StepDefines = {} --本任务包含的所有任务步骤的参数配置（不要删除！）

--Step的参数配置，至少要有一个，可按需增加
StepDefines.Step200401 = {
    Id = 200401,
    ExecMode = EQuestStepExecMode.Serial,
}

QuestBase.InitSteps(StepDefines) --固定的任务步骤数据初始化调用（不要删除！）
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines) --固定的任务目标数据初始化调用（不要删除！）

return Quest_2004