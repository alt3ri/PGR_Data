
---@class XUiPanelBigWorldNarrative : XUiNode
---@field Parent XUiBigWorldNarrative
local XUiPanelBigWorldNarrative = XClass(XUiNode, "XUiPanelBigWorldNarrative")

function XUiPanelBigWorldNarrative:OnStart()
    self:InitUi()
    self:InitCb()
end

function XUiPanelBigWorldNarrative:InitUi()
    self:OnInitUi()
end

function XUiPanelBigWorldNarrative:OnInitUi()
end

function XUiPanelBigWorldNarrative:InitCb()
    self.BtnTanchuangClose:AddEventListener(function()
        self.Parent:OnBtnCloseClick()
    end)
    self:OnInitCb()
end

function XUiPanelBigWorldNarrative:OnInitCb()
end

function XUiPanelBigWorldNarrative:Refresh(narrativeId)
end

return XUiPanelBigWorldNarrative