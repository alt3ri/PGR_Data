---@class XUiGridDlcRelinkSwitchStyle : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkPopupSwitchCareer
local XUiGridDlcRelinkSwitchStyle = XClass(XUiNode, "XUiGridDlcRelinkSwitchStyle")

function XUiGridDlcRelinkSwitchStyle:OnStart(isNotSelf)
    self.IsNotSelf = isNotSelf
    self.BtnSelect:AddEventListener(handler(self, self.OnBtnSelectClick))
end

function XUiGridDlcRelinkSwitchStyle:OnDisable()
    if self.IsNotSelf then
        return
    end
    -- 记录红点状态
    local isUnlock, _ = self:IsCharacterStyleUnlock(self.Config.Condition)
    if isUnlock then
        self._Control:RecordCharacterStyleViewed(self.Config.CharacterId, self.Config.StyleType)
    end
    -- 清空配置
    self.Config = nil
end

---@param config XTableDlcRelinkCharacter 配置
---@param isSelect boolean 是否选中
function XUiGridDlcRelinkSwitchStyle:Refresh(config, isSelect)
    self.Config = config
    -- 选中状态
    self.Normal.gameObject:SetActiveEx(not isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)

    ---@type UiObject
    local panel = isSelect and self.Select or self.Normal
    local styleIcon = config.StyleIcon or ""
    local styleName = config.StyleName or ""
    local styleDesc = config.StyleDesc or ""

    -- 风格图标、名称、描述
    if not string.IsNilOrEmpty(styleIcon) then
        panel:GetObject("RImgIcon"):SetRawImage(styleIcon)
    end
    panel:GetObject("TxtName").text = styleName
    panel:GetObject("TxtContent").text = XUiHelper.ConvertLineBreakSymbol(styleDesc)

    -- 是否解锁
    local isUnlock, desc = self:IsCharacterStyleUnlock(config.Condition)
    self.Lock.gameObject:SetActiveEx(not isUnlock)
    self.BtnSelect.gameObject:SetActiveEx(isUnlock)
    if not isUnlock then
        self.Lock:GetObject("TxtUnlock").text = desc
    end

    -- 记录已查看过的风格类型
    if isSelect and isUnlock then
        self._Control:RecordCharacterStyleViewed(config.CharacterId, config.StyleType)
    end
    -- 红点
    local isShowRedPoint = self._Control:CheckCharacterStyleHasNewUnlock(config.CharacterId, config.StyleType)
    self.Red.gameObject:SetActiveEx(isShowRedPoint)
end

function XUiGridDlcRelinkSwitchStyle:IsCharacterStyleUnlock(conditionIds)
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

function XUiGridDlcRelinkSwitchStyle:OnBtnSelectClick()
    if not self.Config or self.IsNotSelf then
        return
    end

    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end

    self._Control:RequestSwitchStyleType(self.Config.CharacterId, self.Config.StyleType, function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end

        local desc = self._Control:GetClientConfig("SwitchStyleSuccessDesc") or ""
        local styleName = self.Config.StyleName or ""
        self._Control:OpenCommonLeftTipDialog(string.format(desc, styleName))
        if self.Parent and self.Parent.OnBtnCloseClick then
            self.Parent:OnBtnCloseClick()
        end
    end)
end

function XUiGridDlcRelinkSwitchStyle:RefreshOther(characterId, styleType)
    self.Normal.gameObject:SetActiveEx(true)
    self.Select.gameObject:SetActiveEx(false)
    self.Lock.gameObject:SetActiveEx(false)
    self.BtnSelect.gameObject:SetActiveEx(false)
    self.Red.gameObject:SetActiveEx(false)

    -- 风格图标、名称、描述
    local styleIcon = self._Control:GetCharacterStyleIcon(characterId, styleType)
    local styleName = self._Control:GetCharacterStyleName(characterId, styleType)
    local styleDesc = self._Control:GetCharacterStyleDesc(characterId, styleType)
    self.Normal:GetObject("RImgIcon"):SetRawImageEx(styleIcon)
    self.Normal:GetObject("TxtName").text = styleName
    self.Normal:GetObject("TxtContent").text = XUiHelper.ConvertLineBreakSymbol(styleDesc)
end

return XUiGridDlcRelinkSwitchStyle
