---@class XUiGridTheatre5CharaterAttribute: XUiNode
---@field private _Control XTheatre5Control
local XUiGridTheatre5CharaterAttribute = XClass(XUiNode, 'XUiGridTheatre5CharaterAttribute')

---@param cfg XTableTheatre5AttrShow
function XUiGridTheatre5CharaterAttribute:Refresh(cfg, originVal)
    self.TxtName.text = cfg.AttrName
    self.TxtNumNow.text = self:_GetNumberContent(originVal, cfg.ShowType)
    
    local adds = self._Control:GetCharacterAttrAddsByAttrType(cfg.AttrType)

    if XTool.IsNumberValid(adds) then
        self.TxtNumAdd.gameObject:SetActiveEx(true)

        self.TxtNumAdd.text = XUiHelper.FormatText(self._Control:GetClientConfigCharacterAttribAddsShow(), self:_GetNumberContent(adds, cfg.ShowType))
    else
        self.TxtNumAdd.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5CharaterAttribute:_GetNumberContent(num, attrType)
    if attrType == XMVCA.XTheatre5.EnumConst.AttribShowType.Normal then
        return num
    else
        return string.format("%.1f%%", num / 100)
    end
end

return XUiGridTheatre5CharaterAttribute