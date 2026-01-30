---@class XUiPanelDlcRelinkEquipChooseAttribute : XUiNode
---@field Parent XUiDlcRelinkPopupEquipCompose
---@field _Control XDlcRelinkControl
local XUiPanelDlcRelinkEquipChooseAttribute = XClass(XUiNode, "XUiPanelDlcRelinkEquipChooseAttribute")

function XUiPanelDlcRelinkEquipChooseAttribute:OnStart()
    self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClick))
    self.BtnClear:AddEventListener(handler(self, self.OnBtnClearClick))
    ---@type XUiGridDlcRelinkEquipment
    self._Equip = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment").New(self.GridRelinkEquipment, self)
    self:CheckFuncUnlock()
end

function XUiPanelDlcRelinkEquipChooseAttribute:OnEnable()
    self._CurAttrId = nil
    self:UpdateAttribute()
end

function XUiPanelDlcRelinkEquipChooseAttribute:GetAttrId()
    return self._CurAttrId
end

function XUiPanelDlcRelinkEquipChooseAttribute:IsChooseAttr()
    return XTool.IsNumberValid(self._CurAttrId)
end

function XUiPanelDlcRelinkEquipChooseAttribute:CheckFuncUnlock()
    self._IsUnlock = true
    self._LockDesc = ""
    local conditionIds = self._Control:GetTargetingComposeConsumeConditionIds()
    if not XTool.IsTableEmpty(conditionIds) then
        for _, conditionId in ipairs(conditionIds) do
            self._IsUnlock, self._LockDesc = XConditionManager.CheckCondition(tonumber(conditionId))
            if not self._IsUnlock then
                return
            end
        end
    end
end

function XUiPanelDlcRelinkEquipChooseAttribute:UpdateAttribute()
    if self._CurAttrId then
        self.PanelRandom.gameObject:SetActiveEx(false)
        self.ImgNone.gameObject:SetActiveEx(false)
        self.PanelNormal.gameObject:SetActiveEx(true)
        self.TxtData.text = self._Control:GetFactorDescName(self._CurAttrId)
        self.BtnChoose.gameObject:SetActiveEx(false)
        self.BtnClear.gameObject:SetActiveEx(true)
        self._Equip:Open()
        self._Equip:RefreshByEquipId(self._Control:GetMaxQualityEquipByFactor(self._CurAttrId).Id)
    else
        self.PanelRandom.gameObject:SetActiveEx(true)
        self.ImgNone.gameObject:SetActiveEx(true)
        self.PanelNormal.gameObject:SetActiveEx(false)
        self.BtnChoose.gameObject:SetActiveEx(true)
        self.BtnChoose:SetButtonState(self._IsUnlock and XUiButtonState.Normal or XUiButtonState.Disable)
        self.BtnClear.gameObject:SetActiveEx(false)
        self._Equip:Close()
    end
end

function XUiPanelDlcRelinkEquipChooseAttribute:OnBtnChooseClick()
    if XTool.IsNumberValid(self._CurAttrId) then
        return
    end
    if not self._IsUnlock then
        self._Control:OpenCommonTipMsg(self._LockDesc)
        return
    end

    local param = {}
    XLuaUiManager.OpenWithCloseCallback("UiDlcRelinkPopupChooseAttribute", function()
        self._CurAttrId = param.AttrId
        self:UpdateAttribute()
        self.Parent:OnChooseAttrChange()
    end, param)
end

function XUiPanelDlcRelinkEquipChooseAttribute:OnBtnClearClick()
    self._CurAttrId = nil
    self:UpdateAttribute()
    self.Parent:OnChooseAttrChange()
end

return XUiPanelDlcRelinkEquipChooseAttribute
