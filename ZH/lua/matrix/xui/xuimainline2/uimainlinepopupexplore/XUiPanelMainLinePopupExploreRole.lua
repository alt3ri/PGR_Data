--- 弹窗中的纯人物对话面板
---@class XUiPanelMainLinePopupExploreRole: XUiNode
---@field protected _Control
---@field Parent
local XUiPanelMainLinePopupExploreRole = XClass(XUiNode, "XUiPanelMainLinePopupExploreRole")

---@param contentCfg XTableMainLine2MessageContents
function XUiPanelMainLinePopupExploreRole:Refresh(contentCfg)
    self.UiTxtItemName.text = contentCfg.Name or ''
    self.UiTxtItemDesc.text = XUiHelper.ConvertLineBreakSymbol(contentCfg.Desc)

    if not string.IsNilOrEmpty(contentCfg.RoleIcon) then
        self.PanelItemCharacter.gameObject:SetActiveEx(true)
        self.RImgItemNpc:SetRawImage(contentCfg.RoleIcon)
    else
        self.PanelItemCharacter.gameObject:SetActiveEx(false)
    end
end

return XUiPanelMainLinePopupExploreRole