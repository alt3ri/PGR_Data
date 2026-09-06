---@class XUiPanelCultureStepper : XUiNode
local XUiPanelCultureStepper = XClass(XUiNode, "XUiPanelCultureStepper")

local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")
local COLOR_NORMAL = CS.UnityEngine.Color.black
local _, COLOR_OVER = CS.UnityEngine.ColorUtility.TryParseHtmlString("#E43730")
local LONG_CLICK_INTERVAL = 100
local LONG_CLICK_PER_PRESS = 1 / 150

function XUiPanelCultureStepper:OnStart()
    self.TxtValue = self.TxtLevel
    self.InputField = self.TxtLevel

    self.BtnSub:AddEventListener(handler(self, self.OnBtnSubClick))
    self.BtnAdd:AddEventListener(handler(self, self.OnBtnAddClick))
    self.BtnMax:AddEventListener(handler(self, self.OnBtnMaxClick))

    self.InputField.characterLimit = 4
    self.InputField.contentType = CS.UnityEngine.UI.InputField.ContentType.IntegerNumber
    self.InputField.onValueChanged:AddListener(function(value)
        self:OnInputValueChanged(value)
    end)
    self.InputField.onEndEdit:AddListener(function(value)
        self:OnInputEndEdit(value)
    end)

    self.Value = 0
    self.LongPressChangeCnt = 0
    XUiButtonLongClick.New(self.BtnSub, LONG_CLICK_INTERVAL, self, nil, self.OnLongClickSub, nil, true)
    XUiButtonLongClick.New(self.BtnAdd, LONG_CLICK_INTERVAL, self, nil, self.OnLongClickAdd, nil, true)
end

function XUiPanelCultureStepper:Init(cfg)
    self.Cfg = cfg
end

function XUiPanelCultureStepper:OnDestroy()
    self.InputField.onValueChanged:RemoveAllListeners()
    self.InputField.onEndEdit:RemoveAllListeners()
end

function XUiPanelCultureStepper:OnBtnSubClick()
    self:SetValue(self.Value - 1, true)
end

function XUiPanelCultureStepper:OnBtnAddClick()
    self:SetValue(self.Value + 1, true)
end

function XUiPanelCultureStepper:OnBtnMaxClick()
    if self.Cfg.OnMaxClick and self.Cfg.OnMaxClick() == false then
        return
    end
    self:SetValue(self.Cfg.GetMaxAffordable(), true)
end

function XUiPanelCultureStepper:OnLongClickAdd(pressingTime)
    local changeCnt = math.floor(pressingTime * LONG_CLICK_PER_PRESS)
    if self.LongPressChangeCnt > changeCnt then
        self.LongPressChangeCnt = 0
    elseif self.LongPressChangeCnt < changeCnt then
        self:OnBtnAddClick()
        self.LongPressChangeCnt = self.LongPressChangeCnt + 1
    end
end

function XUiPanelCultureStepper:OnLongClickSub(pressingTime)
    local changeCnt = math.floor(pressingTime * LONG_CLICK_PER_PRESS)
    if self.LongPressChangeCnt > changeCnt then
        self.LongPressChangeCnt = 0
    elseif self.LongPressChangeCnt < changeCnt then
        self:OnBtnSubClick()
        self.LongPressChangeCnt = self.LongPressChangeCnt + 1
    end
end

function XUiPanelCultureStepper:OnInputValueChanged(value)
    if self._IsSettingText then
        return
    end
    if value == nil or value == "" then
        return
    end
    local num = tonumber(value)
    if not num then
        return
    end
    local cfg = self.Cfg
    num = math.min(math.max(math.floor(num), cfg.Min), cfg.Max)
    self:SetValue(num, true)
end

function XUiPanelCultureStepper:OnInputEndEdit(value)
    local cfg = self.Cfg
    if value == nil or value == "" then
        self:SetValue(cfg.Min, true)
        return
    end
    local num = tonumber(value)
    if not num then
        self:SetValue(cfg.Min, true)
        return
    end
    num = math.min(math.max(math.floor(num), cfg.Min), cfg.Max)
    self:SetValue(num, true)
end

function XUiPanelCultureStepper:SetValue(value, notify)
    local cfg = self.Cfg
    value = math.min(math.max(value, cfg.Min), cfg.Max)
    local changed = value ~= self.Value
    self.Value = value
    self:RefreshState()
    if notify and changed then
        cfg.OnValueChanged(value)
    end
end

function XUiPanelCultureStepper:SetLocked(isLocked)
    self.IsLocked = isLocked
    self.BtnSub.gameObject:SetActiveEx(not isLocked)
    self.BtnAdd.gameObject:SetActiveEx(not isLocked)
    self.BtnMax.gameObject:SetActiveEx(not isLocked)
    self.Light.gameObject:SetActiveEx(isLocked)
    if not isLocked then
        self:RefreshState()
    end
end

function XUiPanelCultureStepper:RefreshState()
    local cfg = self.Cfg
    self._IsSettingText = true
    self.InputField.text = tostring(self.Value)
    self._IsSettingText = false
    self.TxtLv.color = self.Value > cfg.GetMaxAffordable() and COLOR_OVER or COLOR_NORMAL
    self.Lv.color = self.Value > cfg.GetMaxAffordable() and COLOR_OVER or COLOR_NORMAL
    if self.IsLocked then
        return
    end
    local subDisable = self.Value <= cfg.Min
    local addDisable = self.Value >= cfg.Max
    if not addDisable and cfg.IsMaxNoCost then
        addDisable = cfg.IsMaxNoCost()
    end
    self.BtnSub:SetDisable(subDisable, not subDisable)
    self.BtnAdd:SetDisable(addDisable, not addDisable)
    local maxDisable = subDisable and addDisable
    self.BtnMax:SetDisable(maxDisable, not maxDisable)
    self.Light.gameObject:SetActiveEx(false)
end

function XUiPanelCultureStepper:Refresh(value, min, max)
    local cfg = self.Cfg
    if min then cfg.Min = min end
    if max then cfg.Max = max end
    self:SetValue(value, false)
end

return XUiPanelCultureStepper
