local QuestBase = require("Common/XQuestBase")
---@class XQuestScript5002 : XQuestBase
local XQuestScript5002 = XDlcScriptManager.RegQuestScript(5002, "XQuestScript5002", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript5002:Ctor(proxy)
end

function XQuestScript5002:Init()

end

function XQuestScript5002:Terminate()
end

---@class Quest5002Objective
local Quest5002Objective = XClass(nil, "Quest5002Objective")

---@param quest XQuestScript5002
function Quest5002Objective:Ctor(quest)
    self.quest = quest
end

local ObjectiveDefines = {}
--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf
--================================================

--region =========================================Step1 - 关卡等待开始
---@class QuestObjective50020101 : Quest5002Objective
ObjectiveDefines.Obj50020101 = {
    Id = 50020101,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4009,
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [400001] = 0, --开始游戏库洛洛
            },
        },
    },
    ---@param obj QuestObjective50020101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective50020101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        --加载游戏库洛洛
        proxy:LoadLevelNpc(400001)
        proxy:LoadSceneObject(400072)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50020101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs) end,
    ---@param obj QuestObjective50020101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        -- 接取任务
        proxy:UnderTakeSelfQuest()
        -- 卸载起点库洛洛
        proxy:UnloadLevelNpc(400001)
        -- 卸载起点空气墙
        proxy:UnloadSceneObject(400072)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step2 - 分数目标
---@class QuestObjective50020201 : Quest5002Objective
ObjectiveDefines.Obj50020201 = {
    Id = 50020201,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4009,
        Key = EJumperLevelVarKey.Score,
        Value = 300,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50020203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载初级级宝箱
        obj.TreasureChestsPlaceId1 = 400073
    end,
    ---@param obj QuestObjective50020101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50020203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId1)
        proxy:AddUnloadSceneObjWhiteList(4009, {obj.TreasureChestsPlaceId1})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50020202 : Quest5002Objective
ObjectiveDefines.Obj50020202 = {
    Id = 50020202,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4009,
        Key = EJumperLevelVarKey.Score,
        Value = 500,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50020203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)--加载中级宝箱
        obj.TreasureChestsPlaceId2 = 400074
    end,
    ---@param obj QuestObjective50020101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50020203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId2)
        proxy:AddUnloadSceneObjWhiteList(4009, {obj.TreasureChestsPlaceId2})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50020203 : Quest5002Objective
ObjectiveDefines.Obj50020203 = {
    Id = 50020203,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4009,
        Key = EJumperLevelVarKey.Score,
        Value = 1000,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50020203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载高级宝箱
        obj.TreasureChestsPlaceId3 = 400075
    end,
    ---@param obj QuestObjective50020101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50020203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId3)
        proxy:AddUnloadSceneObjWhiteList(4009, {obj.TreasureChestsPlaceId3})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step3 - 结算时刻
---@type table 金币分数字典 key: SceneObjPlaceId, value: Score
local GoldSceneObjScoreDict = {
    [400036]  = 20,
    [400037]  = 20,
    [400038]  = 20,
    [400039]  = 20,
    [400040]  = 20,
    [400041]  = 20,
    [400042]  = 20,
    [400043]  = 20,
    [400044]  = 20,
    [400045]  = 20,
    [400046]  = 20,
    [400047]  = 20,
    [400048]  = 20,
    [400049]  = 20,
    [400050]  = 20,
    [400051]  = 20,
    [400052]  = 20,
    [400053]  = 20,
    [400054]  = 20,
    [400055]  = 20,
    [400056]  = 20,
    [400057]  = 20,
    [400058]  = 20,
    [400059]  = 20,
    [400060]  = 20,
    [400061]  = 20,
    [400062]  = 20,
    [400063]  = 20,
    [400064]  = 20,
    [400094]  = 100,
    [400096]  = 100,
}

---@type table 保底路线
local BaseSceneObjHide = {
    400083,
    400084,
    400085,
    400086,
    400087,
    400088,
    400089,
    400090,
    400091,
    400092,
    400093,
    400095,
}

---到达终点(完成)
---@class QuestObjective50020301 : Quest5002Objective
---@field TransformBoxPlaceId number 死区Trigger
---@field StartPos UnityEngine.Vector3 重生点
ObjectiveDefines.Obj50020301 = {
    Id = 50020301,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4009,
        TargetPosition = { x = 258.31, y = 38.37, z =336.58 },
        ReachDistance = 5,
    },
    ---@param obj QuestObjective50020301
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.StartPos = { x = 254.81, y = 43.37, z = 348.58 }
        obj.TransformBoxPlaceId = 400099
        obj.SaveBoxPlaceId = 400070
    end,
    ---@param obj QuestObjective50020101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TransformBoxPlaceId)
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
    ---@param obj QuestObjective50020301
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
                    proxy:UnloadSceneObject(obj.TransformBoxPlaceId)
                    for _, baseSceneObjHide in pairs(BaseSceneObjHide) do
                        proxy:LoadSceneObject(baseSceneObjHide)
                    end 
                end
            end
        end
    end,
    ---@param obj QuestObjective50020301
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local TimeNum = 1800
        -- 卸载全部金币
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, TimeNum, 5002, {50020201, 50020202, 50020203}, true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---倒计时结束(失败)
---@class QuestObjective50020302 : Quest5002Objective
ObjectiveDefines.Obj50020302 = {
    Id = 50020302,
    Type = EQuestObjectiveType.OnLevelTimeOut,
    Args = {
        LevelId = 4009,
        AutoStart = true,
        IsCountDown = true,
        Time = 90,
    },
    ---@param obj QuestObjective50020101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        XLog.Debug("跳跳乐：倒计时开始")
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50020302
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)     --结算卸载金币
        XLog.Debug("跳跳乐：倒计时结束")
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, 0, 5002, {50020201, 50020202, 50020203}, false)
        proxy:SetNpcPosAndRot( proxy:GetLocalPlayerNpcId(),  { x = 258.31, y = 38.37, z =336.58 },  {x = 0, y = -84.625, z = 0}, true )--失败去终点
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

local StepDefines = {}
StepDefines.Step500201 = {
    Id = 500201,
    ExecMode = EQuestStepExecMode.Serial,
}

StepDefines.Step500202 = {
    Id = 500202,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 3,
}

StepDefines.Step500203 = {
    Id = 500203,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(Quest5002Objective, ObjectiveDefines)