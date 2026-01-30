--- 回合结算界面显示的奖杯
---@class XUiGridTheatre5SettleCup: XUiNode
local XUiGridTheatre5SettleCup = XClass(XUiNode, 'XUiGridTheatre5SettleCup')

function XUiGridTheatre5SettleCup:SetCupIsOn(isOn)
    if self.ImgOn then
        self.ImgOn.gameObject:SetActiveEx(isOn)
    end
end

return XUiGridTheatre5SettleCup