local QuestBase = require("Common/XQuestBase")
---@class XQuestScript5006 : XQuestBase
local XQuestScript5006 = XDlcScriptManager.RegQuestScript(5006, "XQuestScript5006", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript5006:Ctor(proxy)
end


function XQuestScript5006:Init()

end

function XQuestScript5006:Terminate()
end

---@class Quest5006Objective
local Quest5006Objective = XClass(nil, "Quest5006Objective")

---@param quest XQuestScript5006
function Quest5006Objective:Ctor(quest)
    self.quest = quest
end

local ObjectiveDefines = {}
--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf
--================================================

--region =========================================Step1 - 关卡等待开始
---@class QuestObjective50060101 : Quest5006Objective
ObjectiveDefines.Obj50060101 = {
    Id = 50060101,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4020,
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [800001] = 0, --开始游戏库洛洛
            },
        },
    },
    ---@param obj QuestObjective50060101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective50060101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        --加载游戏库洛洛
        proxy:LoadLevelNpc(800001)
        proxy:LoadSceneObject(800066)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50060101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs) end,
    ---@param obj QuestObjective50060101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        -- 接取任务
        proxy:UnderTakeSelfQuest()
        -- 卸载起点库洛洛
        proxy:UnloadLevelNpc(800001)
        -- 卸载起点空气墙
        proxy:UnloadSceneObject(800066)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step2 - 分数目标
---@class QuestObjective50060201 : Quest5006Objective
ObjectiveDefines.Obj50060201 = {
    Id = 50060201,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4020,
        Key = EJumperLevelVarKey.Score,
        Value = 500,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50060203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载初级级宝箱
        obj.TreasureChestsPlaceId1 = 800111
    end,
    ---@param obj QuestObjective50060101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50060203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId1)
        proxy:AddUnloadSceneObjWhiteList(4020, {obj.TreasureChestsPlaceId1})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50060202 : Quest5006Objective
ObjectiveDefines.Obj50060202 = {
    Id = 50060202,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4020,
        Key = EJumperLevelVarKey.Score,
        Value = 700,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50060203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)--加载中级宝箱
        obj.TreasureChestsPlaceId2 = 800112
    end,
    ---@param obj QuestObjective50060101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50060203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId2)
        proxy:AddUnloadSceneObjWhiteList(4020, {obj.TreasureChestsPlaceId2})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50060203 : Quest5006Objective
ObjectiveDefines.Obj50060203 = {
    Id = 50060203,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4020,
        Key = EJumperLevelVarKey.Score,
        Value = 1200,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50060203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载高级宝箱
        obj.TreasureChestsPlaceId3 = 800113
    end,
    ---@param obj QuestObjective50060101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50060203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId3)
        proxy:AddUnloadSceneObjWhiteList(4020, {obj.TreasureChestsPlaceId3})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step3 - 结算时刻

---@type table 金币分数字典 key: SceneObjPlaceId, value: Score
local GoldSceneObjScoreDict = {
    [800059] = 20,
    [800060] = 20,
    [800061] = 20,
    [800062] = 20,
    [800063] = 20,
    [800064] = 20,
    [800065] = 20,
    [800067] = 20,
    [800068] = 20,
    [800069] = 20,
    [800070] = 20,
    [800071] = 20,
    [800072] = 20,
    [800073] = 100,
    [800074] = 20,
    [800075] = 20,
    [800076] = 20,
    [800077] = 20,
    [800078] = 20,
    [800079] = 20,
    [800080] = 20,
    [800081] = 20,
    [800082] = 20,
    [800083] = 20,
    [800084] = 20,
    [800085] = 20,
    [800086] = 20,
    [800087] = 20,
    [800088] = 20,
    [800089] = 20,
    [800090] = 20,
    [800091] = 20,
    [800092] = 20,
    [800093] = 20,
    [800094] = 20,
    [800095] = 20,
    [800096] = 20,
    [800097] = 20,
    [800098] = 20,
    [800099] = 20,
    [800100] = 20,
    [800101] = 20,
    [800102] = 20,
    [800103] = 20,
    [800104] = 20,
    [800105] = 20,
    [800106] = 20,
    [800125] = 100,
}

---@type table 保底路线
local BaseSceneObjHide = {
    800135,
    800136,
    800137,
    800138,
    800139,
    800140,
    800034,
    800035,
    800036,
    800037,
    800141,
    800142,
}

---到达终点(完成)
---@class QuestObjective50060301 : Quest5006Objective
---@field TransformBoxPlaceId number 死区Trigger
---@field StartPos UnityEngine.Vector3 重生点
ObjectiveDefines.Obj50060301 = {
    Id = 50060301,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4020,
        TargetPosition = { x = 269.76, y = 54.11, z = 317.63},
        ReachDistance = 5,
    },
    ---@param obj QuestObjective50060301
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.TransformBoxPlaceId = 800107
        obj.SaveBoxPlaceId = 800152
    end,
    ---@param obj QuestObjective50060101
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
    ---@param obj QuestObjective50060301
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
            end
        end
    end,
    ---@param obj QuestObjective50060301
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local TimeNum = 1500
        -- 卸载全部金币
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, TimeNum, 5006, {50060201, 50060202, 50060203}, true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---倒计时结束(失败)
---@class QuestObjective50060302 : Quest5006Objective
ObjectiveDefines.Obj50060302 = {
    Id = 50060302,
    Type = EQuestObjectiveType.OnLevelTimeOut,
    Args = {
        LevelId = 4020,
        AutoStart = true,
        IsCountDown = true,
        Time = 100,
    },
    ---@param obj QuestObjective50060101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        XLog.Debug("跳跳乐：倒计时开始")
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50060302
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)     --结算卸载金币
        XLog.Debug("跳跳乐：倒计时结束")
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, 0, 5006, {50060201, 50060202, 50060203}, false)
        proxy:SetNpcPosAndRot( proxy:GetLocalPlayerNpcId(),  { x = 269.76, y = 54.11, z = 317.63},  {x = 0, y = -84.625, z = 0}, true )--失败去终点
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

local StepDefines = {}
StepDefines.Step500601 = {
    Id = 500601,
    ExecMode = EQuestStepExecMode.Serial,
}

StepDefines.Step500602 = {
    Id = 500602,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 3,
}

StepDefines.Step500603 = {
    Id = 500603,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(Quest5006Objective, ObjectiveDefines)