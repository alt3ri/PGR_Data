---@class XUiGridDlcRelinkSwitchOccupation : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkPopupSwitchCareer
local XUiGridDlcRelinkSwitchOccupation = XClass(XUiNode, "XUiGridDlcRelinkSwitchOccupation")

function XUiGridDlcRelinkSwitchOccupation:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnSelectClick, true, true)
end

function XUiGridDlcRelinkSwitchOccupation:OnDisable()
    -- 记录红点状态
    local isUnlock, _ = self:IsCharacterOccupationUnlock(self.Config.Condition)
    if isUnlock then
        self._Control:RecordCharacterOccupationViewed(self.Config.CharacterId, self.Config.OccupationType)
    end
    -- 清空配置
    self.Config = nil
end

---@param config XTableDlcRelinkCharacter 配置
---@param isSelect boolean 是否选中
function XUiGridDlcRelinkSwitchOccupation:Refresh(config, isSelect)
    self.Config = config
    -- 选中状态
    self.Normal.gameObject:SetActiveEx(not isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)

    ---@type UiObject
    local panel = isSelect and self.Select or self.Normal
    local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIcon", config.OccupationType) or ""
    local occupationName = self._Control:GetClientConfig("CharacterOccupationName", config.OccupationType) or ""
    local occupationDesc = config.OccupationDesc or ""

    -- 职业图标、名称、描述
    if not string.IsNilOrEmpty(occupationIcon) then
        panel:GetObject("RImgIcon"):SetRawImage(occupationIcon)
    end
    panel:GetObject("TxtName").text = occupationName
    panel:GetObject("TxtContent").text = occupationDesc

    -- 是否解锁
    local isUnlock, desc = self:IsCharacterOccupationUnlock(config.Condition)
    self.Lock.gameObject:SetActiveEx(not isUnlock)
    self.BtnSelect.gameObject:SetActiveEx(isUnlock)
    if not isUnlock then
        self.Lock:GetObject("TxtUnlock").text = desc
    end

    -- 记录已查看过的职业类型
    if isSelect and isUnlock then
        self._Control:RecordCharacterOccupationViewed(config.CharacterId, config.OccupationType)
    end
    -- 红点
    local isShowRedPoint = self._Control:CheckCharacterOccupationHasNewUnlock(config.CharacterId, config.OccupationType)
    self.Red.gameObject:SetActiveEx(isShowRedPoint)
end

function XUiGridDlcRelinkSwitchOccupation:IsCharacterOccupationUnlock(conditionIds)
    if XTool.IsTableEmpty(conditionIds) then
        return true, ""
    end

    for _, conditionId in pairs(conditionIds) do
        local isUnlock, desc = XConditionManager.CheckCondition(conditionId)
        if not isUnlock then
            return false, desc
        end
    end
    return true, ""
end

function XUiGridDlcRelinkSwitchOccupation:OnBtnSelectClick()
    if not self.Config then
        return
    end

    self._Control:RequestSwitchOccupationType(self.Config.CharacterId, self.Config.OccupationType, function()
        local desc = self._Control:GetClientConfig("SwitchOccupationSuccessDesc") or ""
        local occupationName = self._Control:GetClientConfig("CharacterOccupationName", self.Config.OccupationType) or ""
        self._Control:OpenCommonLeftTipDialog(string.format(desc, occupationName))
        if self.Parent and self.Parent.OnBtnCloseClick then
            self.Parent:OnBtnCloseClick()
        end
    end)
end

return XUiGridDlcRelinkSwitchOccupation
