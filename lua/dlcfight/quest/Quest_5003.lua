local QuestBase = require("Common/XQuestBase")
---@class XQuestScript5003 : XQuestBase
local XQuestScript5003 = XDlcScriptManager.RegQuestScript(5003, "XQuestScript5003", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript5003:Ctor(proxy)
end

function XQuestScript5003:Init()

end

function XQuestScript5003:Terminate()
end

---@class Quest5003Objective
local Quest5003Objective = XClass(nil, "Quest5003Objective")

---@param quest XQuestScript5003
function Quest5003Objective:Ctor(quest)
    self.quest = quest
end

local ObjectiveDefines = {}
--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf
--================================================

--region =========================================Step1 - 关卡等待开始
---@class QuestObjective50030101 : Quest5003Objective
ObjectiveDefines.Obj50030101 = {
    Id = 50030101,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4010,
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [500002] = 0, --开始游戏库洛洛
            },
        },
    },
    ---@param obj QuestObjective50030101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective50030101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        --加载游戏库洛洛
        proxy:LoadLevelNpc(500002)
        proxy:LoadSceneObject(500091)
        -- 临时传送至起点
        -- proxy:SetNpcPosition(proxy:GetLocalPlayerNpcId(), {x=324, y=46, z=319})
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50030101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs) end,
    ---@param obj QuestObjective50030101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        -- 接取任务
        proxy:UnderTakeSelfQuest()
        -- 卸载起点库洛洛
        proxy:UnloadLevelNpc(500002)
        -- 卸载起点空气墙
        proxy:UnloadSceneObject(500091)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step2 - 分数目标
---@class QuestObjective50030201 : Quest5003Objective
ObjectiveDefines.Obj50030201 = {
    Id = 50030201,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4010,
        Key = EJumperLevelVarKey.Score,
        Value = 500,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50030203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载初级级宝箱
        obj.TreasureChestsPlaceId1 = 500094
    end,
    ---@param obj QuestObjective50030101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50030203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId1)
        proxy:AddUnloadSceneObjWhiteList(4010, {obj.TreasureChestsPlaceId1})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50030202 : Quest5003Objective
ObjectiveDefines.Obj50030202 = {
    Id = 50030202,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4010,
        Key = EJumperLevelVarKey.Score,
        Value = 700,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50030203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)--加载中级宝箱
        obj.TreasureChestsPlaceId2 = 500095
    end,
    ---@param obj QuestObjective50030101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50030203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId2)
        proxy:AddUnloadSceneObjWhiteList(4010, {obj.TreasureChestsPlaceId2})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50030203 : Quest5003Objective
ObjectiveDefines.Obj50030203 = {
    Id = 50030203,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4010,
        Key = EJumperLevelVarKey.Score,
        Value = 1200,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50030203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载高级宝箱
        obj.TreasureChestsPlaceId3 = 500096
    end,
    ---@param obj QuestObjective50030101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50030203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId3)
        proxy:AddUnloadSceneObjWhiteList(4010, {obj.TreasureChestsPlaceId3})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step3 - 结算时刻
---@type table
local GoldSceneObjScoreDict = {
    [500023] = 20,
    [500024] = 20,
    [500025] = 20,
    [500026] = 20,
    [500049] = 20,
    [500050] = 20,
    [500052] = 20,
    [500053] = 20,
    [500054] = 20,
    [500055] = 20,
    [500056] = 20,
    [500057] = 20,
    [500058] = 20,
    [500059] = 20,
    [500060] = 20,
    [500062] = 20,
    [500063] = 20,
    [500064] = 20,
    [500065] = 20,
    [500066] = 20,
    [500068] = 20,
    [500069] = 20,
    [500070] = 20,
    [500071] = 20,
    [500072] = 20,
    [500073] = 20,
    [500074] = 20,
    [500075] = 20,
    [500076] = 20,
    [500156] = 20,
    [500157] = 20,
    [500158] = 20,
    [500159] = 20,
    [500160] = 20,
    [500039] = -40,
    [500040] = -40,
    [500041] = -40,
    [500042] = -40,
    [500043] = -40,
    [500044] = -40,
    [500045] = -40,
    [500046] = -40,
    [500047] = -40,
    [500048] = -40,
    [500051] = -40,
    [500080] = 100,
}
---@type table
local BaseSceneObjHide = { 
    500097,
    500098,
    500099,
    500100,
    500101,
    500102,
    500103,
    500104,
    500105,
    500106,
    500107,
    500081,
    500089,
    500088,
}
local RewardGoldObjHide = {
    [500082]= 20,
    [500083]= 20,
    [500084]= 20,
    [500085]= 20,
    [500061] = 100,
    [500067] = 100,
}
local RewardObjHide = {
    500032,
    500033,
    500034,
    500035,
    500037,
    500038,
    500155,
    500010,
    500152
}
---到达终点(完成)
---@class QuestObjective50030301 : Quest5003Objective
---@field TransformBoxPlaceId number 死区Trigger
---@field StartPos UnityEngine.Vector3 重生点
---@field GoldSceneObjScoreDict table<number, number> 金币分数字典 key: SceneObjPlaceId, value: Score
ObjectiveDefines.Obj50030301 = {
    Id = 50030301,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4010,
        TargetPosition = { x = 380.68, y = 52.73, z =275.59 },
        ReachDistance = 5,
    },
    ---@param obj QuestObjective50030301
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.TransformBoxPlaceId = 500090
        obj.StartPos = { x = 251.42, y = 41, z = 269.59 }
        obj.RewardSceneObjId = 500036   --奖励隐藏道路
        obj.SaveBoxPlaceId = 500092
    end,
    ---@param obj QuestObjective50030101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        -- 加载金币
        for goldSceneObjPlaceId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:LoadSceneObject(goldSceneObjPlaceId)
        end
        -- 加载隐藏关碰撞盒
        proxy:LoadSceneObject(obj.RewardSceneObjId)
        -- 初始化跳跳乐参数
        XScriptTool.InitJumperVarBlock(proxy)
        proxy:RegisterEvent(EWorldEvent.ActorTrigger)
        proxy:RegisterEvent(EWorldEvent.SceneObjectBeCollected)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50030301
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
        -- 收集金币后获得金币分数
        if eventType == EWorldEvent.SceneObjectBeCollected then
            local addGoldScore = GoldSceneObjScoreDict[eventArgs.PlaceId]
            local addHideScore = RewardGoldObjHide[eventArgs.PlaceId]
            local addScore
            if addGoldScore ~= nil then
                addScore = addGoldScore
            end
            if addHideScore ~= nil then
                addScore = addHideScore
            end
            if addScore ~= nil then
                XScriptTool.AddQuestIntValue(proxy, EJumperLevelVarKey.GoldCount, 1)
                local score = XScriptTool.AddQuestIntValue(proxy, EJumperLevelVarKey.Score, addScore)
                XLog.Debug("跳跳乐：吃金币，加"..addScore.. " 当前分:"..score)
            end
        end
        if eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerState == ETriggerState.Enter then
            if eventArgs.HostSceneObjectPlaceId == obj.TransformBoxPlaceId then
                local count = XScriptTool.AddQuestIntValue(proxy, EJumperLevelVarKey.DeathCount, 1)
                if count == 5 then    --死区保底路线
                    proxy:SetVarBool(EJumperLevelVarKey.IsTriggerJudge, true)
                    for _, baseSceneObjHide in pairs(BaseSceneObjHide) do
                        proxy:LoadSceneObject(baseSceneObjHide)
                    end 
                end
            elseif eventArgs.HostSceneObjectPlaceId == obj.RewardSceneObjId then    --奖励路线
                proxy:SetVarBool(EJumperLevelVarKey.IsTriggerHideRoad, true)
                proxy:UnloadSceneObject(obj.RewardSceneObjId)
                for _, rewardSceneObjHide in pairs(RewardObjHide) do
                    proxy:LoadSceneObject(rewardSceneObjHide)
                end
                for goldPlaceId, _ in pairs(RewardGoldObjHide) do
                    proxy:LoadSceneObject(goldPlaceId)
                end
            end
        end
    end,
    ---@param obj QuestObjective50030301
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local TimeNum = 1800
        -- 卸载全部金币
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, TimeNum, 5003, {50030201, 50030202, 50030203}, true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---倒计时结束(失败)
---@class QuestObjective50030302 : Quest5003Objective
ObjectiveDefines.Obj50030302 = {
    Id = 50030302,
    Type = EQuestObjectiveType.OnLevelTimeOut,
    Args = {
        LevelId = 4010,
        AutoStart = true,
        IsCountDown = true,
        Time = 100,
    },
    ---@param obj QuestObjective50030101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        XLog.Debug("跳跳乐：倒计时开始")
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50030302
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)     --结算卸载金币
        XLog.Debug("跳跳乐：倒计时结束")
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, 0, 5003, {50030201, 50030202, 50030203}, false)
        proxy:SetNpcPosAndRot( proxy:GetLocalPlayerNpcId(),  { x = 380.68, y = 52.73, z =275.59 },  {x = 0, y = -84.625, z = 0}, true )--失败去终点
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

local StepDefines = {}
StepDefines.Step500301 = {
    Id = 500301,
    ExecMode = EQuestStepExecMode.Serial,
}

StepDefines.Step500302 = {
    Id = 500302,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 3,
}

StepDefines.Step500303 = {
    Id = 500303,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(Quest5003Objective, ObjectiveDefines)