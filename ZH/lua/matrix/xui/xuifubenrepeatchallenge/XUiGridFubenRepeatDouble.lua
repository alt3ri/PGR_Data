--- 双倍显示标签 —— 拉人回流回归玩家
---@class XUiGridFubenRepeatDouble: XUiNode
---@field protected _Control XReCallActivityControl
---@field Parent
local XUiGridFubenRepeatDouble = XClass(XUiNode, "XUiGridFubenRepeatDouble")

function XUiGridFubenRepeatDouble:OnStart(stageId)
    self.StageId = stageId
end

function XUiGridFubenRepeatDouble:OnEnable()
    self:RefreshShow()
end

function XUiGridFubenRepeatDouble:RefreshShow(stageId)
    if stageId then
        self.StageId = stageId
    end
    
    local curTimes = self._Control:GetCurRegressionPlayerMultiRewardCount(self.StageId) or 0
    local maxTimes = self._Control:GetMaxRegressionPlayerMultiRewardCount() or 0


    if self.TxtATNums then
        self.TxtATNums.text = XUiHelper.GetText("FubenRepeatChallengeDoubleRewardTimes", curTimes, maxTimes)
    end
end

return XUiGridFubenRepeatDouble