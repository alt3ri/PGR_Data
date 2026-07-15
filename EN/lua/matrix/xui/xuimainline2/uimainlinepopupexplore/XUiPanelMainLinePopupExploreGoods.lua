--- 弹窗中的物品展示面板
---@class XUiPanelMainLinePopupExploreGoods: XUiNode
---@field protected _Control
---@field Parent
local XUiPanelMainLinePopupExploreGoods = XClass(XUiNode, "XUiPanelMainLinePopupExploreGoods")

---@param contentCfg XTableMainLine2MessageContents
function XUiPanelMainLinePopupExploreGoods:Refresh(contentCfg)
    self.UiTxtItemName.text = contentCfg.Name or ''
    self.UiTxtItemDesc.text = XUiHelper.ConvertLineBreakSymbol(contentCfg.Desc)

    if not string.IsNilOrEmpty(contentCfg.ShowIcon) then
        self.PanelItemIcon.gameObject:SetActiveEx(true)
        self.RImgItemIcon:SetRawImage(contentCfg.ShowIcon)
    else
        self.PanelItemIcon.gameObject:SetActiveEx(false)
    end
end

return XUiPanelMainLinePopupExploreGoods