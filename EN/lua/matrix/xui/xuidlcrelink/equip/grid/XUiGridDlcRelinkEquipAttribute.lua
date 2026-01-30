---@class XUiGridDlcRelinkEquipAttribute : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkEquipAttribute = XClass(XUiNode, "XUiGridDlcRelinkEquipAttribute")

---@param attribute XDlcRelinkEquipAttribute
function XUiGridDlcRelinkEquipAttribute:Refresh(attribute, isSkillAttribute)
    self:SetBg(isSkillAttribute)
    self:SetLevelText(attribute.Level)
    self:SetName(attribute.FactorId)
    if isSkillAttribute then
        self:SetSkill(attribute.FactorId)
    else
        local isMaxLevel = self._Control:CheckEquipAttributeIsMaxLevel(attribute)
        self:SetNormal(attribute.FactorId, attribute.Level, isMaxLevel)
    end
end

---@param data { FactorId: number, IsSkill:boolean, CurLevel:number }
function XUiGridDlcRelinkEquipAttribute:CustomRefresh(data)
    self:SetBg(data.IsSkill)
    self:SetLevelText(data.CurLevel)
    self:SetName(data.FactorId)
    if data.IsSkill then
        self:SetSkill(data.FactorId)
    else
        local maxLevel = self._Control:GetFactorDescMaxLevel(data.FactorId)
        local isMaxLevel = data.CurLevel >= maxLevel
        self:SetNormal(data.FactorId, data.CurLevel, isMaxLevel)
    end
end

---@param data { FactorId: number, IsSkill:boolean, IsCur:boolean, Level:number }
function XUiGridDlcRelinkEquipAttribute:RefreshAttributeDetails(data)
    self.PanelCur.gameObject:SetActiveEx(data.IsCur)
    self:SetLevelText(data.Level)
    if data.IsSkill then
        local maxLevel = self._Control:GetFactorDescMaxLevel(data.FactorId)
        local isMaxLevel = data.Level >= maxLevel
        self.Normal.gameObject:SetActiveEx(not isMaxLevel)
        self.Max.gameObject:SetActiveEx(isMaxLevel)
        self.TxtNum.text = self._Control:GetFactorDesc(data.FactorId, data.Level)
    else
        local maxLevel = self._Control:GetFactorDescMaxLevel(data.FactorId)
        local isMaxLevel = data.Level >= maxLevel
        self:SetNormal(data.FactorId, data.Level, isMaxLevel)
    end
end

function XUiGridDlcRelinkEquipAttribute:SetBg(isSkill)
    self.ImgBg01.gameObject:SetActiveEx(isSkill)
    self.ImgBg02.gameObject:SetActiveEx(not isSkill)
end

function XUiGridDlcRelinkEquipAttribute:SetLevelText(level)
    self.NormalTxt.text = level
    self.MaxTxt.text = level
end

function XUiGridDlcRelinkEquipAttribute:SetName(factorId)
    self.TxtName.text = self._Control:GetFactorDescName(factorId)
end

function XUiGridDlcRelinkEquipAttribute:SetSkill(factorId)
    self.Normal.gameObject:SetActiveEx(false)
    self.Max.gameObject:SetActiveEx(true)
    self.TxtNum.text = self._Control:GetEquipSkillFactorName(factorId)
end

function XUiGridDlcRelinkEquipAttribute:SetNormal(factorId, level, isMaxLevel)
    self.Normal.gameObject:SetActiveEx(not isMaxLevel)
    self.Max.gameObject:SetActiveEx(isMaxLevel)

    if self.TxtNum then
        local isPercent = self._Control:GetFactorDescIsPercent(factorId)
        local params = self._Control:GetFactorParams(factorId, level)
        local num = params[1] or 0
        self.TxtNum.text = self:Format(num, isPercent)
    end
end

function XUiGridDlcRelinkEquipAttribute:Format(v, isPercent)
    v = v or 0
    if isPercent then
        return string.format("%s%%", math.floor(v / 100))
    end
    return string.format("+%s", v)
end

return XUiGridDlcRelinkEquipAttribute
