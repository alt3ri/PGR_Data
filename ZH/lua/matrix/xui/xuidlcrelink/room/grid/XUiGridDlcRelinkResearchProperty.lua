---@class XUiGridDlcRelinkResearchProperty : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkResearchProperty = XClass(XUiNode, "XUiGridDlcRelinkResearchProperty")

function XUiGridDlcRelinkResearchProperty:Refresh(attrStr, curValue, nextValue, isMaxLevel)
    local icon = self._Control:GetCharacterAttribIcon(attrStr)
    if icon and self.Icon then
        self.Icon:SetSprite(icon)
    end
    if self.TxtName then
        self.TxtName.text = self._Control:GetCharacterAttribName(attrStr)
    end
    local isPercent = self._Control:GetCharacterAttribIsPercent(attrStr)
    if self.TxtCurValue then
        self.TxtCurValue.text = self:Format(curValue, isPercent)
    end
    if self.Image then
        self.Image.gameObject:SetActiveEx(not isMaxLevel)
    end
    if self.TxtNextValue then
        self.TxtNextValue.gameObject:SetActiveEx(not isMaxLevel)
        if not isMaxLevel then
            self.TxtNextValue.text = self:Format(nextValue, isPercent)
        end
    end
end

function XUiGridDlcRelinkResearchProperty:Format(v, isPercent)
    v = v or 0
    if isPercent then
        local value = v / 100
        local intPart, fracPart = math.modf(value)
        if fracPart == 0 then
            value = intPart
        end
        return string.format("%s%%", value)
    end
    return tostring(v)
end

return XUiGridDlcRelinkResearchProperty
