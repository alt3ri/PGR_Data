---@class XUiGridDlcRelinkCharacterProperty : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkCharacterProperty = XClass(XUiNode, "XUiGridDlcRelinkCharacterProperty")

function XUiGridDlcRelinkCharacterProperty:Refresh(attrStr, attrValue)
    local icon = self._Control:GetCharacterAttribIcon(attrStr)
    if not string.IsNilOrEmpty(icon) then
        self.Icon.gameObject:SetActiveEx(true)
        self.Icon:SetSprite(icon)
    else
        self.Icon.gameObject:SetActiveEx(false)
    end
    if self.TxtName then
        self.TxtName.text = self._Control:GetCharacterAttribName(attrStr)
    end
    local isPercent = self._Control:GetCharacterAttribIsPercent(attrStr)
    if self.TxtAttack then
        self.TxtAttack.text = self:Format(attrValue, isPercent)
    end
end

function XUiGridDlcRelinkCharacterProperty:SetBg(isActive)
    if self.RawImage then
        self.RawImage.gameObject:SetActiveEx(isActive)
    end
end

function XUiGridDlcRelinkCharacterProperty:Format(v, isPercent)
    v = v or 0
    if isPercent then
        return string.format("%s%%", math.floor(v / 100))
    end
    return tostring(v)
end

return XUiGridDlcRelinkCharacterProperty
