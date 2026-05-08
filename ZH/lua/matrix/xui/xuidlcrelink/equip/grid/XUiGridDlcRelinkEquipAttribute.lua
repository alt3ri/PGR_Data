---@class XUiGridDlcRelinkEquipAttribute : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkEquipAttribute = XClass(XUiNode, "XUiGridDlcRelinkEquipAttribute")

function XUiGridDlcRelinkEquipAttribute:OnStart(detailGo)
    self.DetailGo = detailGo
    if self.DetailGo then
        self.DetailGo.gameObject:SetActiveEx(false)
        ---@type UiObject
        self.DetailGoUiObject = self.DetailGo.gameObject:GetComponent(typeof(CS.UiObject))
    end
end

function XUiGridDlcRelinkEquipAttribute:OnDisable()
    if self.DetailGo then
        self.DetailGo.gameObject:SetActiveEx(false)
    end
end

function XUiGridDlcRelinkEquipAttribute:MoveToParentLatest()
    self.Transform:SetAsLastSibling()
    if self.DetailGo then
        self.DetailGo.transform:SetAsLastSibling()
    end
end

---@param attribute XDlcRelinkEquipAttribute
function XUiGridDlcRelinkEquipAttribute:Refresh(attribute)
    self.NormalTxt.text = attribute.Level
    self:SetName(attribute.FactorId)
    self.Normal.gameObject:SetActiveEx(true)
    self:SetNum(attribute.FactorId, attribute.Level)
    -- 背景
    if self.ImgBg then
        local levelTypeIcon = self._Control:GetAttributeLevelTypeIcon(attribute)
        self.ImgBg:SetRawImageEx(levelTypeIcon)
    end
    if self.Dark and self.Parent.CheckEquipFactorIsUnlock then
        -- 刷新是否解锁
        local factorIsUnLock, desc = self.Parent:CheckEquipFactorIsUnlock(attribute)
        self.Dark.gameObject:SetActiveEx(not factorIsUnLock)
        self.BtnNoEffective.gameObject:SetActiveEx(not factorIsUnLock)
        if not factorIsUnLock then
            self.BtnNoEffective:AddEventListener(function()
                if self.Parent and self.Parent.OnShowPanelDetail then
                    self.Parent:OnShowPanelDetail(self.Transform, desc)
                end
            end)
        end
    end
end

---@param attribute XDlcRelinkEquipAttribute
function XUiGridDlcRelinkEquipAttribute:Refresh2(attribute)
    self.NormalTxt.text = attribute.Level
    self.MaxTxt.text = attribute.Level
    self:SetName(attribute.FactorId)
    local isMaxLevel = self._Control:CheckEquipAttributeIsMaxLevel(attribute)
    self.Normal.gameObject:SetActiveEx(not isMaxLevel)
    self.Max.gameObject:SetActiveEx(isMaxLevel)
    self:SetNum(attribute.FactorId, attribute.Level)
end

---@param attribute XDlcRelinkEquipAttribute
function XUiGridDlcRelinkEquipAttribute:RefreshDetailShow(isShow, attribute, forceRefresh)
    if not self:IsNodeShow() then
        return
    end

    if not isShow then
        if self.DetailGo then
            self.DetailGo.gameObject:SetActiveEx(false)
        end
        return
    end

    local validShow = false
    if self.DetailGoUiObject then
        local factorDesc = self._Control:GetFactorDescDesc(attribute.FactorId)
        if not string.IsNilOrEmpty(factorDesc) then
            local txt = self.DetailGoUiObject:GetObject("DetailTxt")
            if txt then
                txt.text = factorDesc
                validShow = true
            end
            local txtDark = self.DetailGoUiObject:GetObject("DetailTxtDark", false)
            if txtDark and self.Parent.CheckEquipFactorIsUnlock then
                local factorIsUnLock = self.Parent:CheckEquipFactorIsUnlock(attribute)
                txtDark.text = factorDesc
                txtDark.gameObject:SetActiveEx(not factorIsUnLock)
                txt.gameObject:SetActiveEx(factorIsUnLock)
                validShow = true
            end
        end
    end

    if self.DetailGo then
        self.DetailGo.gameObject:SetActiveEx(validShow)
        if validShow and forceRefresh then
            CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.DetailGo)
        end
    end
end

---@param data { FactorId: number, IsSkill:boolean, CurLevel:number }
function XUiGridDlcRelinkEquipAttribute:CustomRefresh(data)
    self.NormalTxt.text = data.CurLevel
    self.MaxTxt.text = data.CurLevel
    self:SetName(data.FactorId)
    local maxLevel = self._Control:GetFactorDescMaxLevel(data.FactorId)
    self.TxtMaxLevel.text = maxLevel
    local isOverMaxLevel = data.CurLevel > maxLevel
    self.Normal.gameObject:SetActiveEx(not isOverMaxLevel)
    self.Max.gameObject:SetActiveEx(isOverMaxLevel)
    self:SetNum(data.FactorId, data.CurLevel)
end

---@param data { FactorId: number, IsSkill:boolean, IsCur:boolean, Level:number, IsShowSkillDesc: boolean }
function XUiGridDlcRelinkEquipAttribute:RefreshAttributeDetails(data)
    self.PanelCur.gameObject:SetActiveEx(data.IsCur)
    self.NormalTxt.text = data.Level
    self.MaxTxt.text = data.Level

    local maxLevel = self._Control:GetFactorDescMaxLevel(data.FactorId)
    local isMaxLevel = data.Level >= maxLevel
    self.Normal.gameObject:SetActiveEx(not isMaxLevel)
    self.Max.gameObject:SetActiveEx(isMaxLevel)

    if data.IsSkill then
        if data.IsShowSkillDesc then
            self.TxtNum.text = self._Control:GetFactorSkillDesc(data.FactorId, data.Level)
        else
            self.TxtNum.text = self._Control:GetFactorDesc(data.FactorId, data.Level)
        end
    else
        self:SetNum(data.FactorId, data.Level)
    end

    -- 设置背景交替显示
    local isShowBg1 = data.Level % 2 ~= 0
    if self.Image1 then
        self.Image1.gameObject:SetActiveEx(isShowBg1)
    end
    if self.Image2 then
        self.Image2.gameObject:SetActiveEx(not isShowBg1)
    end
end

function XUiGridDlcRelinkEquipAttribute:SetBg(isSkill)
    self.ImgBg01.gameObject:SetActiveEx(isSkill)
    self.ImgBg02.gameObject:SetActiveEx(not isSkill)
end

function XUiGridDlcRelinkEquipAttribute:ShowBg1()
    self.ImgBg01.gameObject:SetActiveEx(true)
    self.ImgBg02.gameObject:SetActiveEx(false)
end

function XUiGridDlcRelinkEquipAttribute:ShowBg2()
    self.ImgBg01.gameObject:SetActiveEx(false)
    self.ImgBg02.gameObject:SetActiveEx(true)
end

function XUiGridDlcRelinkEquipAttribute:SetName(factorId)
    self.TxtName.text = self._Control:GetFactorDescName(factorId)
end

function XUiGridDlcRelinkEquipAttribute:SetNum(factorId, level)
    if not self.TxtNum then
        return
    end
    local factorType = self._Control:GetFactorType(factorId, level)
    if factorType == XEnumConst.DlcRelink.FactorType.MainSkill then
        self.TxtNum.text = self._Control:GetFactorDesc(factorId, level)
    else
        local isPercent = self._Control:GetFactorDescIsPercent(factorId)
        local params = self._Control:GetFactorParams(factorId, level)
        local num = params[1] or 0
        self.TxtNum.text = self:Format(num, isPercent)
    end
end

function XUiGridDlcRelinkEquipAttribute:Format(v, isPercent)
    v = v or 0
    if isPercent then
        local value = v / 100
        local intPart, fracPart = math.modf(value)
        if fracPart == 0 then
            value = intPart
        end
        return string.format("%s%%", value)
    end
    if v >= 0 then
        return string.format("+%s", v)
    else
        return tostring(v)
    end
end

return XUiGridDlcRelinkEquipAttribute
