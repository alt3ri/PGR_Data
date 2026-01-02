---@class XUiGridDlcRelinkCharacterAttribute : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkCharacterAttribute = XClass(XUiNode, "XUiGridDlcRelinkCharacterAttribute")

---@param data { AttrStr: string, CurValue:number, EquipValue:number }
function XUiGridDlcRelinkCharacterAttribute:RefreshAttributeDetail(data)
    local attrStr = data.AttrStr
    -- 图标
    local icon = self._Control:GetCharacterAttribIcon(attrStr)
    if not string.IsNilOrEmpty(icon) then
        self.Icon.gameObject:SetActiveEx(true)
        self.Icon:SetSprite(icon)
    else
        self.Icon.gameObject:SetActiveEx(false)
    end
    -- 名称
    self.TxtName.text = self._Control:GetCharacterAttribName(attrStr)
    -- 描述
    self.TxtDesc.text = self._Control:GetCharacterAttribDesc(attrStr)
    local isPercent = self._Control:GetCharacterAttribIsPercent(attrStr)

    -- 普通属性值
    local curValueValid = XTool.IsNumberValid(data.CurValue)
    self.TxtNum.gameObject:SetActiveEx(curValueValid)
    if curValueValid then
        self.TxtNum.text = self:Format(data.CurValue, isPercent)
    end

    -- 装备属性值
    local equipValueValid = XTool.IsNumberValid(data.EquipValue)
    self.TxtNumNew.gameObject:SetActiveEx(equipValueValid)
    if equipValueValid then
        self.TxtNumNew.text = self:Format2(data.EquipValue, isPercent)
    end
end

function XUiGridDlcRelinkCharacterAttribute:SetBg(isActive)
    if self.ImaBg1 then
        self.ImaBg1.gameObject:SetActiveEx(isActive)
    end
    if self.ImaBg2 then
        self.ImaBg2.gameObject:SetActiveEx(not isActive)
    end
end

function XUiGridDlcRelinkCharacterAttribute:Format(v, isPercent)
    if not XTool.IsNumberValid(v) then
        return ""
    end
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

function XUiGridDlcRelinkCharacterAttribute:Format2(v, isPercent)
    if not XTool.IsNumberValid(v) then
        return ""
    end
    if isPercent then
        local value = v / 100
        local intPart, fracPart = math.modf(value)
        if fracPart == 0 then
            value = intPart
        end
        if value >= 0 then
            return string.format("+%s%%", value)
        else
            return string.format("%s%%", value)
        end
    end
    if v >= 0 then
        return string.format("+%s", v)
    else
        return tostring(v)
    end
end

return XUiGridDlcRelinkCharacterAttribute
