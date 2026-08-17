---@class XUiEnvelopeGuessingReward : XLuaUi
local XUiEnvelopeGuessingReward = XLuaUiManager.Register(XLuaUi, "UiEnvelopeGuessingReward")

function XUiEnvelopeGuessingReward:OnStart(rewardGoodsList, taskRewardGoodsList)
    self.BtnClose:AddEventListener(handler(self, self.Close))

    local hasLeft = not XTool.IsTableEmpty(rewardGoodsList)
    local hasRight = not XTool.IsTableEmpty(taskRewardGoodsList)

    self.ImgLine.gameObject:SetActiveEx(hasLeft and hasRight)
    self.PanelLeft.gameObject:SetActiveEx(hasLeft)
    self.PanelRight.gameObject:SetActiveEx(hasRight)

    if hasLeft then
        -- 默认取第一个奖励的数量除以3，当累积天数（向下取整）
        local dayCount = math.floor(rewardGoodsList[1].Count / 3)
        local text
        if dayCount <= 1 then
            text = CS.XTextManager.GetText("EnvelopeGuessingRewardPanelLeftTitle")
        else
            text = CS.XTextManager.GetText("EnvelopeGuessingRewardPanelLeftTitleWithDays", dayCount)
        end
        self:_SetPanel(self.PanelLeft, text, rewardGoodsList)
    end

    if hasRight then
        self:_SetPanel(self.PanelRight, CS.XTextManager.GetText("EnvelopeGuessingRewardPanelRightTitle"), taskRewardGoodsList)
    end
end

function XUiEnvelopeGuessingReward:_SetPanel(panel, title, data)
    data = XRewardManager.MergeAndSortRewardGoodsList(data)
    if XTool.IsTableEmpty(data) then
        XLog.Error("XUiEnvelopeGuessingReward：奖励数据为空。")
        return
    end
    panel:GetObject("TxtTitle").text = title
    panel:GetObject("ToolNum").text = CS.XTextManager.GetText("EnvelopeGuessingRewardPanelItemCount", data[1].Count)
    if #data > 1 then
        XLog.Error("XUiEnvelopeGuessingReward：当前UI不支持显示超过多于1种物品。")
    end
end

return XUiEnvelopeGuessingReward
