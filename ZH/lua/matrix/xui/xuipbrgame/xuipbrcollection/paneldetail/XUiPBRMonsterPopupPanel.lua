local XUiCommonPopupPanel = require('XUi/XUiPBRGame/CommonUiTemplate/ItemDetailPopupPanel/XUiCommonPopupPanel')

--- 怪物波次成长描述飘窗
---@class XUiPBRMonsterPopupPanel: XUiCommonPopupPanel
---@field protected _Control XPBRGameControl
---@field Parent XUiPBRCollectionPanelDesc
local XUiPBRMonsterPopupPanel = XClass(XUiCommonPopupPanel, "XUiPBRMonsterPopupPanel")

function XUiPBRMonsterPopupPanel:OnStart()
    self.BtnCloseTips:AddEventListener(handler(self, self.Close))
    
    local viewWidth, viewHeight = self.Transform:GetUIRectWidthHeight()
    self:SetViewArea(viewWidth, viewHeight)
    self:SetPopupPanelRectTrans(self.ImgTips.transform)
end

function XUiPBRMonsterPopupPanel:RefreshShow(worldPos, pivot, desc)
    self.TxtMonsterDetail.text = desc
    
    self:SetPosition(worldPos, pivot)
end


return XUiPBRMonsterPopupPanel