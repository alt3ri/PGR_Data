local QuestBase = require("Common/XQuestBase")
---@class XQuestScript5004 : XQuestBase
local XQuestScript5004 = XDlcScriptManager.RegQuestScript(5004, "XQuestScript5004", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript5004:Ctor(proxy)
end


function XQuestScript5004:Init()

end

function XQuestScript5004:Terminate()
end

---@class Quest5004Objective
local Quest5004Objective = XClass(nil, "Quest5004Objective")

---@param quest XQuestScript5004
function Quest5004Objective:Ctor(quest)
    self.quest = quest
end

local ObjectiveDefines = {}
--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf
--================================================

--region =========================================Step1 - 关卡等待开始
---@class QuestObjective50040101 : Quest5004Objective
ObjectiveDefines.Obj50040101 = {
    Id = 50040101,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4018,
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [600001] = 0, --开始游戏库洛洛
            },
        },
    },
    ---@param obj QuestObjective50040101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        --加载游戏库洛洛
        proxy:LoadLevelNpc(600001)
        proxy:LoadSceneObject(600113)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50040101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        -- 接取任务
        proxy:UnderTakeSelfQuest()
        -- 卸载起点库洛洛
        proxy:UnloadLevelNpc(600001)
        -- 卸载起点空气墙
        proxy:UnloadSceneObject(600113)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step2 - 分数目标
---@class QuestObjective50040201 : Quest5004Objective
ObjectiveDefines.Obj50040201 = {
    Id = 50040201,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4018,
        Key = EJumperLevelVarKey.Score,
        Value = 500,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50040203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载初级级宝箱
        obj.TreasureChestsPlaceId1 = 600108
    end,
    ---@param obj QuestObjective50040101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50040203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId1)
        proxy:AddUnloadSceneObjWhiteList(4018, {obj.TreasureChestsPlaceId1})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50040202 : Quest5004Objective
ObjectiveDefines.Obj50040202 = {
    Id = 50040202,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4018,
        Key = EJumperLevelVarKey.Score,
        Value = 700,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50040203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)--加载中级宝箱
        obj.TreasureChestsPlaceId2 = 600109
    end,
    ---@param obj QuestObjective50040101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50040203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId2)
        proxy:AddUnloadSceneObjWhiteList(4018, {obj.TreasureChestsPlaceId2})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50040203 : Quest5004Objective
ObjectiveDefines.Obj50040203 = {
    Id = 50040203,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4018,
        Key = EJumperLevelVarKey.Score,
        Value = 1200,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50040203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载高级宝箱
        obj.TreasureChestsPlaceId3 = 600110
    end,
    ---@param obj QuestObjective50040101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50040203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId3)
        proxy:AddUnloadSceneObjWhiteList(4018, {obj.TreasureChestsPlaceId3})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step3 - 结算时刻

---@type table 金币分数字典 key: SceneObjPlaceId, value: Score
local GoldSceneObjScoreDict = {
    [600037] = 20,
    [600038] = 20,
    [600039] = 20,
    [600040] = 20,
    [600041] = 20,
    [600042] = 20,
    [600043] = 20,
    [600044] = 20,
    [600045] = 20,
    [600046] = 20,
    [600047] = 20,
    [600048] = 20,
    [600049] = 20,
    [600050] = 20,
    [600051] = 20,
    [600052] = 20,
    [600053] = 20,
    [600054] = 20,
    [600055] = 20,
    [600056] = 20,
    [600057] = 20,
    [600058] = 20,
    [600059] = 20,
    [600060] = 20,
    [600061] = 20,
    [600062] = 20,
    [600063] = 20,
    [600064] = 20,
    [600065] = 20,
    [600066] = 20,
    [600067] = 20,
    [600068] = 20,
    [600069] = 20,
    [600070] = 20,
    [600071] = 20,
    [600071] = 20,
    [600130] = 100,
    [600036] = 100,
    [600076] = -40,
    [600077] = -40,
    [600078] = -40,
    [600079] = -40,
    [600080] = -40,
    [600081] = -40,
    [600082] = -40,

}
local BaseSceneObjHide = {
    600133,
    600134,
    600135,
    600136,
    600137,
    600138,
    600139,
    600140,
    600141,
    600032,
    600033,
    600034,
    600035,
}
local RewardSceneObjId = {
    600032,
    600033,
    600034,
    600035,
}
---到达终点(完成)
---@class QuestObjective50040301 : Quest5004Objective
---@field TransformBoxPlaceId number 死区Trigger
---@field StartPos UnityEngine.Vector3 重生点
ObjectiveDefines.Obj50040301 = {
    Id = 50040301,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4018,
        TargetPosition = { x = 319.63, y = 54.43, z = 340.59 },
        ReachDistance = 5,
    },
    ---@param obj QuestObjective50040301
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.SaveBoxPlaceId = 600101
        obj.RewardSceneObjId = 600132
        obj.TransformBoxPlaceId =  600112
    end,
    ---@param obj QuestObjective50040101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        -- 加载金币
        for goldSceneObjPlaceId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:LoadSceneObject(goldSceneObjPlaceId)
        end
        -- 初始化跳跳乐参数
        XScriptTool.InitJumperVarBlock(proxy)
        proxy:RegisterEvent(EWorldEvent.ActorTrigger)
        proxy:RegisterEvent(EWorldEvent.SceneObjectBeCollected)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50040301
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
        if eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerState == ETriggerState.Enter then
            if eventArgs.HostSceneObjectPlaceId == obj.TransformBoxPlaceId then
                local count = XScriptTool.AddQuestIntValue(proxy, EJumperLevelVarKey.DeathCount, 1)
                if count == 5 and proxy:GetLevelPlayTimerCurTime() > 0 then    --死区保底路线
                    proxy:SetVarBool(EJumperLevelVarKey.IsTriggerJudge, true)
                    for _, baseSceneObjHide in pairs(BaseSceneObjHide) do
                        proxy:LoadSceneObject(baseSceneObjHide)
                    end
                end
            elseif eventArgs.HostSceneObjectPlaceId == obj.RewardSceneObjId then    --奖励路线
                proxy:SetVarBool(EJumperLevelVarKey.IsTriggerHideRoad, true)
                proxy:UnloadSceneObject(obj.RewardSceneObjId)
                for rewardSceneObjHide, _ in pairs(RewardSceneObjId) do
                    proxy:LoadSceneObject(rewardSceneObjHide)
                end
            end
        end
    end,
    ---@param obj QuestObjective50040301
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local TimeNum = 1600
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        for _, placeId in pairs(BaseSceneObjHide) do
            proxy:LoadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, TimeNum, 5004, {50040201, 50040202, 50040203}, true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---倒计时结束(失败)
---@class QuestObjective50040302 : Quest5004Objective
ObjectiveDefines.Obj50040302 = {
    Id = 50040302,
    Type = EQuestObjectiveType.OnLevelTimeOut,
    Args = {
        LevelId = 4018,
        AutoStart = true,
        IsCountDown = true,
        Time = 100,
    },
    ---@param obj QuestObjective50040101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        XLog.Debug("跳跳乐：倒计时开始")
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50040302
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)     --结算卸载金币
        XLog.Debug("跳跳乐：倒计时结束")
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        for _, placeId in pairs(BaseSceneObjHide) do
            proxy:LoadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, 0, 5004, {50040201, 50040202, 50040203}, false)
        proxy:SetNpcPosAndRot( proxy:GetLocalPlayerNpcId(),  { x = 319.63, y = 54.43, z = 340.59 },  {x = 0, y = -84.625, z = 0}, true )--失败去终点
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

local StepDefines = {}
StepDefines.Step500401 = {
    Id = 500401,
    ExecMode = EQuestStepExecMode.Serial,
}

StepDefines.Step500402 = {
    Id = 500402,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 3,
}

StepDefines.Step500403 = {
    Id = 500403,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(Quest5004Objective, ObjectiveDefines)