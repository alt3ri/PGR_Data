local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XPokerGuessing2Agency : XAgency
---@field private _Model XPokerGuessing2Model
local XPokerGuessing2Agency = XClass(XFubenActivityAgency, "XPokerGuessing2Agency")

function XPokerGuessing2Agency:OnInit()
    self._CurrentStageId = nil
    self._CurrentRound = nil
    --初始化一些变量
    self:RegisterActivityAgency()
end

function XPokerGuessing2Agency:InitRpc()
    --实现服务器事件注册
    XRpc.NotifyPokerGuessing2Data = Handler(self, self.NotifyPokerGuessing2Data)
end

function XPokerGuessing2Agency:InitEvent()
    --实现跨Agency事件注册
end

function XPokerGuessing2Agency:NotifyPokerGuessing2Data(serverData)
    self._Model:SetServerData(serverData)
end

-- 开始游戏
function XPokerGuessing2Agency:StartNewPokerGuessing2Request(stageId, callback)
    XNetwork.Call("StartNewPokerGuessing2Request", {
        Stage = stageId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if callback then
                callback(false)
            end
            return
        end
        XSaveTool.SaveData("XPokerGuessing2StageCanChallenge" .. XPlayer.Id .. stageId, true)
        if callback then
            callback(res)
        end
    end)
end

-- 出牌
---@param card XPokerGuessing2Card
function XPokerGuessing2Agency:ActionPokerGuessing2Request(card, callback)
    XNetwork.Call("ActionPokerGuessing2Request", {
        PlayerCard = card:GetId(),
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback(res)
        end
    end)
end

-- 使用帮助提示
function XPokerGuessing2Agency:UseTips2Request(callback)
    XNetwork.Call("UseTipsPokerGuessing2Request", {
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback(res)
        end
    end)
end

-- 解锁角色剧情
function XPokerGuessing2Agency:UnlockStoryPokerGuessing2Request(storyId, callback)
    XNetwork.Call("UnlockStoryPokerGuessing2Request", {
        StoryId = storyId,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if callback then
            callback(res)
        end
    end)
end

function XPokerGuessing2Agency:OpenMain()
    if self._Model:IsActivityOpen() then
        XLuaUiManager.Open("UiPokerGuessing2Main")
        return true
    else
        XUiManager.TipText("ActivityBranchNotOpen")
        return false
    end
end

function XPokerGuessing2Agency:ExCheckInTime()
    return true
end

function XPokerGuessing2Agency:HasTaskCanReceive()
    local activityId = self._Model:GetActivityId()
    if not activityId or activityId <= 0 then
        return false
    end
    local activityConfig = self._Model:GetPokerGuessing2ActivityConfigById(activityId)
    if not activityConfig then
        return false
    end
    local taskGroupId = activityConfig.TaskGroupId
    for i = 1, #taskGroupId do
        if XDataCenter.TaskManager.IsAnyTaskCanReceiveByTaskGroupId(taskGroupId[i]) then
            return true
        end
    end
    return false
end

function XPokerGuessing2Agency:IsShowRedDot()
    if not self._Model:IsActivityOpen() then
        return false
    end
    
    if self:HasTaskCanReceive() then
        return true
    end
    if self:HasStageCanChallenge() then
        return true
    end
    return false
end

function XPokerGuessing2Agency:HasStageCanChallenge()
    local curActivityId = self._Model:GetActivityId()

    if not XTool.IsNumberValid(curActivityId) then
        return false
    end
    
    local curActivityCfg = self._Model:GetPokerGuessing2ActivityConfigById(curActivityId)

    if not curActivityCfg or XTool.IsTableEmpty(curActivityCfg.StageIds) then
        return false
    end
    
    for i, stageId in pairs(curActivityCfg.StageIds) do
        if self._Model:IsStageCanChallenge(stageId) and not self._Model:IsStagePassed(stageId) then
            if XSaveTool.GetData("XPokerGuessing2StageCanChallenge" .. XPlayer.Id .. stageId) == nil then
                return true
            end
        end
    end
    return false
end

function XPokerGuessing2Agency:ExGetProgressTip()
    local progress, max = 0, 0
    local curActivityId = self._Model:GetActivityId()

    if not XTool.IsNumberValid(curActivityId) then
        -- 没开活动不显示进度
        return ''
    end
    
    local activityCfg = self._Model:GetPokerGuessing2ActivityConfigById(curActivityId)

    if activityCfg and not XTool.IsTableEmpty(activityCfg.StageIds) then
        max = #activityCfg.StageIds
        
        for i, stageId in pairs(activityCfg.StageIds) do
            if self._Model:IsStagePassed(stageId) then
                progress = progress + 1
            end
        end
    end
    
    return XUiHelper.GetText("BossSingleProgress", progress, max)
end

function XPokerGuessing2Agency:SetCurrentStageId(stageId)
    self._CurrentStageId = stageId
end

function XPokerGuessing2Agency:SetCurrentRound(round)
    self._CurrentRound = round
end

function XPokerGuessing2Agency:CheckIsInStageAndRound(stageId, round)
    if not self._CurrentStageId then
        return false
    end
    if not self._CurrentRound then
        return false
    end
    if self._CurrentStageId == stageId and self._CurrentRound == round then
        return true
    end
    return false
end

function XPokerGuessing2Agency:IsAvgPlayed()
    --[[if XSaveTool.GetData("XPokerGuessing2FirstTimeStory" .. XPlayer.Id) == true then
        return true
    end--]]

    if self._Model:CheckIsFirstTimeStory() then
        return true
    end
    
    return false
end

return XPokerGuessing2Agency