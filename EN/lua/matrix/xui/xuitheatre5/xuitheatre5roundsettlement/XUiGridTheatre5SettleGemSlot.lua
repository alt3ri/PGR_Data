local XUiGridTheatre5Container = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Container')

--- 回合结算的宝珠容器
---@class XUiGridTheatre5SettleGemSlot: XUiGridTheatre5Container
local XUiGridTheatre5SettleGemSlot = XClass(XUiGridTheatre5Container, 'XUiGridTheatre5SettleGemSlot')


function XUiGridTheatre5SettleGemSlot:SetTriggerTimes(times)
    self.TxtTriggerNum.text = XUiHelper.FormatText(self._Control:GetClientConfigGemTriggerTimesLabel(), times)
end

function XUiGridTheatre5SettleGemSlot:SetPassiveShow()
    self.TxtTriggerNum.text = self._Control:GetClientConfigRoundSettlePassiveGemLabel()
end

return XUiGridTheatre5SettleGemSlot