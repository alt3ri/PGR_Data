local XDynamicDailyTask = require("XUi/XUiTask/XDynamicDailyTask")

---@class XUiDynamicDailyTask:XDynamicDailyTask
local XUiDynamicDailyTask = XClass(XDynamicDailyTask, "XUiDynamicDailyTask")

--重写点击方法
function XUiDynamicDailyTask:OnBtnSkipClick()
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end
    self.Super.OnBtnSkipClick(self)
end

---显示/隐藏双倍奖励标签
function XUiDynamicDailyTask:UpdateMultiReward()
    if self:IsMultiRewardTagShow() then
        local multiRewardCfg = XDataCenter.FubenRepeatChallengeManager.GetMultiRewardActivityCfg()
        local countStr = XTool.ConvertChineseNumberString(multiRewardCfg.Multiple)
        self.BtnSkip:ShowTag(true)
        self.BtnSkip:SetNameByGroup(1, XUiHelper.GetText("ActivityRepeatChallengeMultiRewardTag2", countStr))
    else
        self.BtnSkip:ShowTag(false)
    end
end

function XUiDynamicDailyTask:IsMultiRewardTagShow()
    local isMultiRewardOpen = XDataCenter.FubenRepeatChallengeManager.IsMultiRewardOpen()
    if not isMultiRewardOpen then
        return false --多倍奖励活动未开启
    end

    local multiRewardCfg = XDataCenter.FubenRepeatChallengeManager.GetMultiRewardActivityCfg()
    if multiRewardCfg.TaskId ~= self.Data.Id then
        return false --不是目标任务
    end

    local isBtnSkipShow = self.BtnSkip.gameObject.activeSelf and self.BtnSkip.ButtonState ~= CS.UiButtonState.Disable
    if not isBtnSkipShow then
        return false --跳转按钮未显示/未激活
    end

    return true
end

return XUiDynamicDailyTask