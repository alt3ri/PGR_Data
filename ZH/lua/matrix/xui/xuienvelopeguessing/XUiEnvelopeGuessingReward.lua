local XUiEnvelopeGuessingSubUi =
    require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingSubUi")

---@class XUiEnvelopeGuessingReward : XLuaUi

local XUiEnvelopeGuessingReward = XLuaUiManager.Register(
    XUiEnvelopeGuessingSubUi, "UiEnvelopeGuessingReward")

function XUiEnvelopeGuessingReward:OnStart(data, activityConf, cb)
    self.BtnClose.CallBack = handler(self, self.Close)
    self._CloseCallback = cb

    local hasLeft = not XTool.IsTableEmpty(data.RewardGoodsList)
    local hasRight = not XTool.IsTableEmpty(data.TaskRewardGoodsList)

    self.ImgLine.gameObject:SetActiveEx(hasLeft and hasRight)
    self.PanelLeft.gameObject:SetActiveEx(hasLeft)
    self.PanelRight.gameObject:SetActiveEx(hasRight)

    if hasLeft then
        local activityTimeId = activityConf.TimeId
        local startTime = XFunctionManager.GetStartTimeByTimeId(activityTimeId)
        local startAlarm = XTime.GetDayCountUntilTime(startTime, true)
        local registerAlarm = XTime.GetDayCountUntilTime(XPlayer.CreateTime, true)
        local alarm = math.min(startAlarm, registerAlarm)
        alarm = alarm - 1 -- 计算累积天数，活动开始当天不算在内
        local text
        if alarm <= 1 then 
            text = CS.XTextManager.GetText("EnvelopeGuessingRewardPanelLeftTitle")
        else
            text = CS.XTextManager.GetText("EnvelopeGuessingRewardPanelLeftTitleWithDays", alarm)
        end
        self:_SetPanel(self.PanelLeft, text, data.RewardGoodsList)
    end

    if hasRight then
        self:_SetPanel(
            self.PanelRight,
            CS.XTextManager.GetText("EnvelopeGuessingRewardPanelRightTitle"),
            data.TaskRewardGoodsList)
    end
end

function XUiEnvelopeGuessingReward:OnDestroy()
    if self._CloseCallback then
        self._CloseCallback()
    end
end

function XUiEnvelopeGuessingReward:_SetPanel(panel, title, data)
    data = XRewardManager.MergeAndSortRewardGoodsList(data)
    assert(data[1])

    panel:GetObject("TxtTitle").text = title

    panel:GetObject("ToolNum").text = CS
        .XTextManager
        .GetText("EnvelopeGuessingRewardPanelItemCount", data[1].Count)

    if #data > 1 then
        XLog.Error("XUiEnvelopeGuessingReward：当前UI不支持显示超过多于1种物品。")
    end
end

return XUiEnvelopeGuessingReward
