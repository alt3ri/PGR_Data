local QuestBase = require("Common/XQuestBase")
---@class XQuestScript4023 : XQuestBase
local XQuestScript4023 = XDlcScriptManager.RegQuestScript(4023, "XQuestScript4023", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript4023:Ctor(proxy)
end

function XQuestScript4023:Init()

end

function XQuestScript4023:Terminate()
end

---@class Quest4023Objective
local ObjectiveBase = XClass(nil, "Quest4023Objective")

---@param quest XQuestScript4023
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}

--01.到达指定地点查看阿呆蛙
---@class QuestObjective40230101 : Quest4023Objective
ObjectiveDefines.Obj40230101 = {
    Id = 40230101,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4023,
        TracePosArgs = {
            {
                Position = { x = 28.33, y = 56.59, z = 21.39 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 28.33, y = 56.59, z = 21.39 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40230101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40230101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--02.播放B1级动画：阿呆蛙出场
---@class QuestObjective40230102 : Quest4023Objective
ObjectiveDefines.Obj40230102 = {
    Id = 40230102,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4023,
        DramaName = "Drama_1001_041",
    },
    ---@param obj QuestObjective40230102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40230102
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40230102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
---@class QuestObjective40230103 : Quest4023Objective
ObjectiveDefines.Obj40230103 = {
    Id = 40230103,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4023,
        DramaName = "Drama_1001_042",
    },
    ---@param obj QuestObjective40230103
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40230103
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40230103
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishInstLevel() --标记当前副本关卡完成
        proxy:RequestLeaveInstanceLevel(false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

local StepDefines = {}

StepDefines.Step402301 = {
    Id = 402301,
    ExecMode = EQuestStepExecMode.Serial,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines)