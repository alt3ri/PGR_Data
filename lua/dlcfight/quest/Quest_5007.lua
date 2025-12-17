local QuestBase = require("Common/XQuestBase")
---@class XQuestScript5007 : XQuestBase
local XQuestScript5007 = XDlcScriptManager.RegQuestScript(5007, "XQuestScript5007", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript5007:Ctor(proxy)
end

function XQuestScript5007:Init()

end

function XQuestScript5007:Terminate()
end

---@class Quest5007Objective
local Quest5007Objective = XClass(nil, "Quest5007Objective")

---@param quest XQuestScript5007
function Quest5007Objective:Ctor(quest)
    self.quest = quest
end

local ObjectiveDefines = {}
--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf
--================================================

--region =========================================Step1 - 关卡等待开始
---@class QuestObjective50070101 : Quest5007Objective
ObjectiveDefines.Obj50070101 = {
    Id = 50070101,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4025,
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [900001] = 0, --开始游戏库洛洛
            },
        },
    },
    ---@param obj QuestObjective50070101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective50070101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        --加载游戏库洛洛
        proxy:LoadLevelNpc(900001)
        proxy:LoadSceneObject(900028)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50070101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs) end,
    ---@param obj QuestObjective50070101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        -- 接取任务
        proxy:UnderTakeSelfQuest()
        -- 卸载起点库洛洛
        proxy:UnloadLevelNpc(900001)
        -- 卸载起点空气墙
        proxy:UnloadSceneObject(900028)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step2 - 分数目标
---@class QuestObjective50070201 : Quest5007Objective
ObjectiveDefines.Obj50070201 = {
    Id = 50070201,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4025,
        Key = EJumperLevelVarKey.Score,
        Value = 300,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50070201
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50070201
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50070202 : Quest5007Objective
ObjectiveDefines.Obj50070202 = {
    Id = 50070202,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4025,
        Key = EJumperLevelVarKey.Score,
        Value = 500,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50070202
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50070203 : Quest5007Objective
ObjectiveDefines.Obj50070203 = {
    Id = 50070203,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4025,
        Key = EJumperLevelVarKey.Score,
        Value = 1000,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step3 - 结算时刻
local GoldSceneObjScoreDict = {
    [900012] = 20,
    [900013] = 20,
    [900014] = 20,
    [900015] = 20,
    [900016] = 20,
    [900017] = 20,
    [900018] = 20,
    [900019] = 20,
    [900020] = 20,
    [900021] = 20,
    [900022] = 20,
    [900023] = 20,
    [900024] = 100,
}
---到达终点(完成)
---@class QuestObjective50070301 : Quest5007Objective
---@field TransformBoxPlaceId number 死区Trigger
---@field StartPos UnityEngine.Vector3 重生点
---@field GoldSceneObjScoreDict table<number, number> 金币分数字典 key: SceneObjPlaceId, value: Score
ObjectiveDefines.Obj50070301 = {
    Id = 50070301,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4025,
        TargetPosition={x = 306.65, y = 37.29846, z = 323.8},
        ReachDistance = 5,
    },
    ---@param obj QuestObjective50070301
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.TransformBoxPlaceId = 900030
        obj.StartPos =  { x = 243.7, y = 37, z = 322.7 }
    end,
    ---@param obj QuestObjective50070101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        -- 加载金币
        for goldSceneObjPlaceId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:LoadSceneObject(goldSceneObjPlaceId)
        end
        -- 初始化跳跳乐参数
        XScriptTool.InitJumperVarBlock(proxy)
        proxy:RegisterEvent(EWorldEvent.SceneObjectBeCollected)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50070301
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
        -- 收集金币后获得金币分数
        if eventType == EWorldEvent.SceneObjectBeCollected then
            local addScore = GoldSceneObjScoreDict[eventArgs.PlaceId]
            if addScore ~= nil then
                XScriptTool.AddQuestIntValue(proxy, EJumperLevelVarKey.GoldCount, 1)
                local score = XScriptTool.AddQuestIntValue(proxy, EJumperLevelVarKey.Score, addScore)
                XLog.Debug("跳跳乐：吃金币，加"..addScore.. " 当前分:"..score)
            end
        end
    end,
    ---@param obj QuestObjective50070301
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local TimeNum = 1200
        -- 卸载全部金币
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        -- 5007的跳跳乐不算入跳跳乐的关卡成就记录里
        XScriptTool.JumperLevelSettle(proxy, TimeNum, 5007, {50070201, 50070202, 50070203}, true, true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---倒计时结束(失败)
---@class QuestObjective50070302 : Quest5007Objective
ObjectiveDefines.Obj50070302 = {
    Id = 50070302,
    Type = EQuestObjectiveType.OnLevelTimeOut,
    Args = {
        LevelId = 4025,
        AutoStart = true,
        IsCountDown = true,
        Time = 60,
    },
    ---@param obj QuestObjective50070302
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        XLog.Debug("跳跳乐：倒计时开始")
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50070302
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        XLog.Debug("跳跳乐：倒计时结束")
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, 0, 5007, {50070201, 50070202, 50070203}, false, true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

local StepDefines = {}
StepDefines.Step500701 = {
    Id = 500701,
    ExecMode = EQuestStepExecMode.Serial,
}

StepDefines.Step500702 = {
    Id = 500702,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 3,
}

StepDefines.Step500703 = {
    Id = 500703,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(Quest5007Objective, ObjectiveDefines)