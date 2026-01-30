---@class XUiGridJourneyReward : XUiNode
local XUiGridJourneyReward = XClass(XUiNode, "XUiGridJourneyReward")

function XUiGridJourneyReward:OnStart()
    self.Btn.CallBack = function() self:OnBtnClick()  end
end

function XUiGridJourneyReward:GetCurDrawId()
    local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(self.Parent.Data:GetId())
    local drawId = drawInfo.Id
    return drawId
end

function XUiGridJourneyReward:Refresh(rewardId, index)
    self.RewardId = rewardId
    self.Index = index

    local rewardDatas = XRewardManager.GetRewardList(rewardId) or {}
    ---@type XUiGridCommon
    local grid = XUiHelper.XUiGridCommon(self.Parent.Parent, self.Grid256New)
    grid:Refresh(rewardDatas[1])

    local num = self.Parent.CurCanLiverRewardCfg.Schedules[index]
    self.Btn:SetNameByGroup(0, num)

    -- 当总Count大于等于当前num且 服务端侧的Schedules数据里的已领取的奖励下标RewardIndex不存在当前下标，则为可领取状态需要红点
    local isCanReceive = XDataCenter.DrawManager.IsCanJourneyRewardGet(index)
    self.Btn:ShowReddot(isCanReceive)
    grid:SetBtnActive(not isCanReceive)

    local isReceived = XDataCenter.DrawManager.IsJourneyRewardReceived(index)
    self.Btn:ShowTag(isReceived)
end

function XUiGridJourneyReward:OnBtnClick()
    local isCanReceive = XDataCenter.DrawManager.IsCanJourneyRewardGet(self.Index)
    if not isCanReceive then
        return
    end

    -- index偏移量csharp
    XDataCenter.DrawManager.DrawCanLiverRewardRequest(function(rewardGoodsList)
        local horizontalNormalizedPosition = 0
        XUiManager.OpenUiObtain(rewardGoodsList, nil, nil, nil, horizontalNormalizedPosition)
        self.Parent:RefreshJourneyRewardDynamicTable()
    end)
end

return XUiGridJourneyReward