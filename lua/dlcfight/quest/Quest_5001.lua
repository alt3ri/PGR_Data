local QuestBase = require("Common/XQuestBase")
---@class XQuestScript5001 : XQuestBase
local XQuestScript5001 = XDlcScriptManager.RegQuestScript(5001, "XQuestScript5001", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript5001:Ctor(proxy)
end

function XQuestScript5001:Init()

end

function XQuestScript5001:Terminate()
end

---@class Quest5001Objective
local Quest5001Objective = XClass(nil, "Quest5001Objective")

---@param quest XQuestScript5001
function Quest5001Objective:Ctor(quest)
    self.quest = quest
end

local ObjectiveDefines = {}
--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf
--================================================

--region =========================================Step1 - 关卡等待开始
---@class QuestObjective50010101 : Quest5001Objective
ObjectiveDefines.Obj50010101 = {
    Id = 50010101,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4008,
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [300001] = 0, --开始游戏库洛洛
            },
        },
    },
    ---@param obj QuestObjective50010101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective50010101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        --加载游戏库洛洛
        proxy:LoadLevelNpc(300001)
        proxy:LoadSceneObject(300031)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50010101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs) end,
    ---@param obj QuestObjective50010101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        -- 接取任务
        proxy:UnderTakeSelfQuest()
        -- 卸载起点库洛洛
        proxy:UnloadLevelNpc(300001)
        -- 卸载起点空气墙
        proxy:UnloadSceneObject(300031)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step2 - 分数目标
---@class QuestObjective50010201 : Quest5001Objective
ObjectiveDefines.Obj50010201 = {
    Id = 50010201,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4008,
        Key = EJumperLevelVarKey.Score,
        Value = 300,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50010201
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载初级级宝箱
        obj.TreasureChestsPlaceId1 = 300032
    end,
    ---@param obj QuestObjective50010201
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50010201
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId1)
        proxy:AddUnloadSceneObjWhiteList(4008, {obj.TreasureChestsPlaceId1})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50010202 : Quest5001Objective
ObjectiveDefines.Obj50010202 = {
    Id = 50010202,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4008,
        Key = EJumperLevelVarKey.Score,
        Value = 500,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50010202
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)--加载中级宝箱
        obj.TreasureChestsPlaceId2 = 300033
    end,
    ---@param obj QuestObjective50010202
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50010202
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId2)
        proxy:AddUnloadSceneObjWhiteList(4008, {obj.TreasureChestsPlaceId2})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50010203 : Quest5001Objective
ObjectiveDefines.Obj50010203 = {
    Id = 50010203,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4008,
        Key = EJumperLevelVarKey.Score,
        Value = 1000,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50010203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载高级宝箱
        obj.TreasureChestsPlaceId3 = 300034
    end,
    ---@param obj QuestObjective50010203
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50010203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId3)
        proxy:AddUnloadSceneObjWhiteList(4008, {obj.TreasureChestsPlaceId3})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step3 - 结算时刻
local GoldSceneObjScoreDict = {
    [300012] = 20,
    [300013] = 20,
    [300014] = 20,
    [300015] = 20,
    [300016] = 20,
    [300017] = 20,
    [300018] = 20,
    [300019] = 20,
    [300020] = 20,
    [300021] = 20,
    [300022] = 20,
    [300023] = 20,
    [300024] = 20,
    [300025] = 20,
    [300037] = 100,
}
---到达终点(完成)
---@class QuestObjective50010301 : Quest5001Objective
---@field TransformBoxPlaceId number 死区Trigger
---@field StartPos UnityEngine.Vector3 重生点
---@field GoldSceneObjScoreDict table<number, number> 金币分数字典 key: SceneObjPlaceId, value: Score
ObjectiveDefines.Obj50010301 = {
    Id = 50010301,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4008,
        TargetPosition={x = 306.65, y = 37.29846, z = 323.8},
        ReachDistance = 5,
    },
    ---@param obj QuestObjective50010301
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.TransformBoxPlaceId = 300036
        obj.StartPos =  { x = 243.7, y = 37, z = 322.7 }
    end,
    ---@param obj QuestObjective50010101
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
    ---@param obj QuestObjective50010301
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
    ---@param obj QuestObjective50010301
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local TimeNum = 1800
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, TimeNum, 5001, {50010201, 50010202, 50010203}, true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---倒计时结束(失败)
---@class QuestObjective50010302 : Quest5001Objective
ObjectiveDefines.Obj50010302 = {
    Id = 50010302,
    Type = EQuestObjectiveType.OnLevelTimeOut,
    Args = {
        LevelId = 4008,
        AutoStart = true,
        IsCountDown = true,
        Time = 90,
    },
    ---@param obj QuestObjective50010302
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        XLog.Debug("跳跳乐：倒计时开始")
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50010302
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        XLog.Debug("跳跳乐：倒计时结束")
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, 0, 5001, {50010201, 50010202, 50010203}, false)
        proxy:SetNpcPosAndRot( proxy:GetLocalPlayerNpcId(),  {x = 306.65, y = 37.29846, z = 323.8},  {x = 0, y = -84.625, z = 0}, true )--失败去终点
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

local StepDefines = {}
StepDefines.Step500101 = {
    Id = 500101,
    ExecMode = EQuestStepExecMode.Serial,
}

StepDefines.Step500102 = {
    Id = 500102,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 3,
}

StepDefines.Step500103 = {
    Id = 500103,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(Quest5001Objective, ObjectiveDefines)