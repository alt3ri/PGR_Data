local QuestBase = require("Common/XQuestBase")
---@class XQuestScript5005 : XQuestBase
local XQuestScript5005 = XDlcScriptManager.RegQuestScript(5005, "XQuestScript5005", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript5005:Ctor(proxy)
end


function XQuestScript5005:Init()

end

function XQuestScript5005:Terminate()
end

---@class Quest5005Objective
local Quest5005Objective = XClass(nil, "Quest5005Objective")

---@param quest XQuestScript5005
function Quest5005Objective:Ctor(quest)
    self.quest = quest
end

local ObjectiveDefines = {}
--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf
--================================================

--region =========================================Step1 - 关卡等待开始
---@class QuestObjective50050101 : Quest5005Objective
ObjectiveDefines.Obj50050101 = {
    Id = 50050101,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4019,
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [700001] = 0, --开始游戏库洛洛
            },
        },
    },
    ---@param obj QuestObjective50050101
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
    end,
    ---@param obj QuestObjective50050101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        --加载游戏库洛洛
        proxy:LoadLevelNpc(700001)
        proxy:LoadSceneObject(700044)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50050101
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs) end,
    ---@param obj QuestObjective50050101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        -- 接取任务
        proxy:UnderTakeSelfQuest()
        -- 卸载起点库洛洛
        proxy:UnloadLevelNpc(700001)
        -- 卸载起点空气墙
        proxy:UnloadSceneObject(700044)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step2 - 分数目标
---@class QuestObjective50050201 : Quest5005Objective
ObjectiveDefines.Obj50050201 = {
    Id = 50050201,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4019,
        Key = EJumperLevelVarKey.Score,
        Value = 500,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50050203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载初级级宝箱
        obj.TreasureChestsPlaceId1 = 700094
    end,
    ---@param obj QuestObjective50050101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50050203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId1)
        proxy:AddUnloadSceneObjWhiteList(4019, {obj.TreasureChestsPlaceId1})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50050202 : Quest5005Objective
ObjectiveDefines.Obj50050202 = {
    Id = 50050202,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4019,
        Key = EJumperLevelVarKey.Score,
        Value = 700,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50050203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)--加载中级宝箱
        obj.TreasureChestsPlaceId2 = 700095
    end,
    ---@param obj QuestObjective50050101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50050203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId2)
        proxy:AddUnloadSceneObjWhiteList(4019, {obj.TreasureChestsPlaceId2})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---@class QuestObjective50050203 : Quest5005Objective
ObjectiveDefines.Obj50050203 = {
    Id = 50050203,
    Type = EQuestObjectiveType.CheckIntVar,
    Args = {
        LevelId = 4019,
        Key = EJumperLevelVarKey.Score,
        Value = 1200,
        CheckType = EIntCheckType.GreaterThanAndEquals,
    },
    ---@param obj QuestObjective50050203
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy) --加载高级宝箱
        obj.TreasureChestsPlaceId3 = 700096
    end,
    ---@param obj QuestObjective50050101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50050203
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.TreasureChestsPlaceId3)
        proxy:AddUnloadSceneObjWhiteList(4019, {obj.TreasureChestsPlaceId3})
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

--region =========================================Step3 - 结算时刻

---@type table 金币分数字典 key: SceneObjPlaceId, value: Score
local GoldSceneObjScoreDict = {
    [700059]= 20,
    [700060]= 20,
    [700061]= 20,
    [700062]= 20,
    [700063]= 20,
    [700064]= 20,
    [700065]= 20,
    [700066]= 20,
    [700067]= 20,
    [700068]= 20,
    [700069]= 20,
    [700070]= 20,
    [700071]= 20,
    [700072]= 20,
    [700073]= 20,
    [700074]= 20,
    [700075]= 20,
    [700076]= 20,
    [700077]= 20,
    [700078]= 20,
    [700079]= 20,
    [700080]= 20,
    [700081]= 20,
    [700082]= 20,
    [700083]= 20,
    [700084]= 20,
    [700085]= 20,
    [700086]= 20,
    [700087]= 20,
    [700088]= 20,
    [700089]= 20,
    [700090]= 20,
    [700091]= 20,
    [700092]= 20,
    [700093]= 20,
    [700097]= 20,
    [700098]= 20,
}
---@type table 保底路线
local BaseSceneObjHide = {
    700129,
    700130,
    700131,
    700132,
    700133,
    700134,
    700135,
    700136,
    700137,
    700138,
    700139,
    700140,
    700141,
}

---到达终点(完成)
---@class QuestObjective50050301 : Quest5005Objective
---@field TransformBoxPlaceId number 死区Trigger
---@field StartPos UnityEngine.Vector3 重生点
ObjectiveDefines.Obj50050301 = {
    Id = 50050301,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4019,
        TargetPosition = { x = 254.21, y = 52.37, z = 284.59 },
        ReachDistance = 5,
    },
    ---@param obj QuestObjective50050301
    ---@param proxy XDlcCSharpFuncs
    InitFunc = function(obj, proxy)
        obj.TransformBoxPlaceId = 700106
        obj.SaveBoxPlaceId = 700101
    end,
    ---@param obj QuestObjective50050101
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
    ---@param obj QuestObjective50050301
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
    ---@param obj QuestObjective50050301
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        local TimeNum = 1400
        -- 卸载全部金币
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, TimeNum, 5005, {50050201, 50050202, 50050203}, true)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

---倒计时结束(失败)
---@class QuestObjective50050302 : Quest5005Objective
ObjectiveDefines.Obj50050302 = {
    Id = 50050302,
    Type = EQuestObjectiveType.OnLevelTimeOut,
    Args = {
        LevelId = 4019,
        AutoStart = true,
        IsCountDown = true,
        Time = 100,
    },
    ---@param obj QuestObjective50050101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        XLog.Debug("跳跳乐：倒计时开始")
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective50050302
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)     --结算卸载金币
        XLog.Debug("跳跳乐：倒计时结束")
        for placeId, _ in pairs(GoldSceneObjScoreDict) do
            proxy:UnloadSceneObject(placeId)
        end
        XScriptTool.JumperLevelSettle(proxy, 0, 5005, {50050201, 50050202, 50050203}, false)
        proxy:SetNpcPosAndRot( proxy:GetLocalPlayerNpcId(),  { x = 254.21, y = 52.37, z = 284.59 },  {x = 0, y = -84.625, z = 0}, true )
        proxy:FinishQuestObjectiveScriptExit()
    end,
}
--endregion

local StepDefines = {}
StepDefines.Step500501 = {
    Id = 500501,
    ExecMode = EQuestStepExecMode.Serial,
}

StepDefines.Step500502 = {
    Id = 500502,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 3,
}

StepDefines.Step500503 = {
    Id = 500503,
    ExecMode = EQuestStepExecMode.Parallel,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(Quest5005Objective, ObjectiveDefines)