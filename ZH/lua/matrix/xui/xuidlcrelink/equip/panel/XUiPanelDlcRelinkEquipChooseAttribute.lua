---@class XUiPanelDlcRelinkEquipChooseAttribute : XUiNode
---@field Parent XUiDlcRelinkPopupEquipCompose
---@field _Control XDlcRelinkControl
local XUiPanelDlcRelinkEquipChooseAttribute = XClass(XUiNode, "XUiPanelDlcRelinkEquipChooseAttribute")

function XUiPanelDlcRelinkEquipChooseAttribute:OnStart()
    self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClick))
    self.BtnClear:AddEventListener(handler(self, self.OnBtnClearClick))
    if self.BtnDetail then
        self.BtnDetail:AddEventListener(handler(self, self.OnBtnDetailClick))
    end
    if self.BtnDetailClose then
        self.BtnDetailClose:AddEventListener(handler(self, self.OnBtnDetailCloseClick))
    end
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
        local characterIcon = self._Control:GetFactorDescCharacterIcon(self._CurAttrId)
        local isShowIcon = not string.IsNilOrEmpty(characterIcon)
        self.ImgAvatar.gameObject:SetActiveEx(isShowIcon)
        if isShowIcon then
            self.ImgAvatar:SetSprite(characterIcon)
        end
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

function XUiPanelDlcRelinkEquipChooseAttribute:OnBtnDetailClick()
    if not XTool.IsNumberValid(self._CurAttrId) then
        return
    end
    self.TxtDesc.text = self._Control:GetFactorDescDesc(self._CurAttrId)
    -- 计算目标格子左上角的世界坐标
    local rect = self.PanelNormal.transform.rect
    local tempVec3 = CS.UnityEngine.Vector3(rect.xMin, rect.yMax, 0)
    local bottomLeftWorld = self.PanelNormal.transform:TransformPoint(tempVec3)
    -- 将世界坐标转换为PanelBubbleDetail的局部坐标
    local localPos = self.PanelBubbleDetail.transform:InverseTransformPoint(bottomLeftWorld)
    self.TxtDesc.transform.parent.anchoredPosition = CS.UnityEngine.Vector2(localPos.x, localPos.y)
    self.PanelBubbleDetail.gameObject:SetActiveEx(true)
end

function XUiPanelDlcRelinkEquipChooseAttribute:OnBtnDetailCloseClick()
    self.PanelBubbleDetail.gameObject:SetActiveEx(false)
end

return XUiPanelDlcRelinkEquipChooseAttribute
