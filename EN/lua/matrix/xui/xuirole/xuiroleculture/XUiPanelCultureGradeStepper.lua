---@class XUiPanelCultureGradeStepper : XUiNode
local XUiPanelCultureGradeStepper = XClass(XUiNode, "XUiPanelCultureGradeStepper")
local XUiCultureStarGroup = require("XUi/XUiRole/XUiRoleCulture/XUiCultureStarGroup")
local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")

local LONG_CLICK_INTERVAL = 100
local LONG_CLICK_PER_PRESS = 1 / 150

function XUiPanelCultureGradeStepper:OnStart(characterId)
    self.CharacterId = characterId
    self.StarGroup = XUiCultureStarGroup.New(self.Parent, self)

    self.BtnSub:AddEventListener(handler(self, self.OnBtnSubClick))
    self.BtnAdd:AddEventListener(handler(self, self.OnBtnAddClick))
    self.BtnMax:AddEventListener(handler(self, self.OnBtnMaxClick))

    self.Value = 0
    self.LongPressChangeCnt = 0
    XUiButtonLongClick.New(self.BtnSub, LONG_CLICK_INTERVAL, self, nil, self.OnLongClickSub, nil, true)
    XUiButtonLongClick.New(self.BtnAdd, LONG_CLICK_INTERVAL, self, nil, self.OnLongClickAdd, nil, true)
end

function XUiPanelCultureGradeStepper:OnLongClickAdd(pressingTime)
    local cfg = self.Cfg
    if self.Value >= cfg.Max or self.Value >= cfg.GetMaxAffordable() then
        return true
    end
    local changeCnt = math.floor(pressingTime * LONG_CLICK_PER_PRESS)
    if self.LongPressChangeCnt > changeCnt then
        self.LongPressChangeCnt = 0
    elseif self.LongPressChangeCnt < changeCnt then
        self:OnBtnAddClick()
        self.LongPressChangeCnt = self.LongPressChangeCnt + 1
    end
end

function XUiPanelCultureGradeStepper:OnLongClickSub(pressingTime)
    local cfg = self.Cfg
    if self.Value <= cfg.Min then
        return true
    end
    local changeCnt = math.floor(pressingTime * LONG_CLICK_PER_PRESS)
    if self.LongPressChangeCnt > changeCnt then
        self.LongPressChangeCnt = 0
    elseif self.LongPressChangeCnt < changeCnt then
        self:OnBtnSubClick()
        self.LongPressChangeCnt = self.LongPressChangeCnt + 1
    end
end

--- cfg = { Min, Max, GetMaxAffordable = fun():number, OnValueChanged = fun(v) }
function XUiPanelCultureGradeStepper:Init(cfg)
    self.Cfg = cfg
end

function XUiPanelCultureGradeStepper:OnBtnSubClick()
    self:SetValue(self.Value - 1, true)
end

function XUiPanelCultureGradeStepper:OnBtnAddClick()
    self:SetValue(self.Value + 1, true)
end

function XUiPanelCultureGradeStepper:OnBtnMaxClick()
    if self.Cfg.OnMaxClick then
        if self.Cfg.OnMaxClick() == false then
            return
        end
    end
    self:SetValue(self.Cfg.GetMaxAffordable(), true)
end

function XUiPanelCultureGradeStepper:SetValue(value, notify)
    local cfg = self.Cfg
    value = math.min(math.max(value, cfg.Min), cfg.Max)
    local changed = value ~= self.Value
    self.Value = value
    self:RefreshState()
    if notify and changed then
        cfg.OnValueChanged(value)
    end
end

function XUiPanelCultureGradeStepper:SetLocked(isLocked)
    self.IsLocked = isLocked
    self.BtnSub.gameObject:SetActiveEx(not isLocked)
    self.BtnAdd.gameObject:SetActiveEx(not isLocked)
    self.BtnMax.gameObject:SetActiveEx(not isLocked)
    self.Light.gameObject:SetActiveEx(isLocked)
    -- 解锁时按钮 disable 态在锁定期间被跳过刷新，需补刷一次（避免停留在锁定前的旧态）
    if not isLocked then
        self:RefreshState()
    end
end

function XUiPanelCultureGradeStepper:RefreshState()
    local cfg = self.Cfg
    local maxAffordable = cfg.GetMaxAffordable()
    local isMaterialLack = cfg.IsMaterialLack and cfg.IsMaterialLack() or false
    self.StarGroup:Refresh(self.CharacterId, self.Value, isMaterialLack)
    if self.IsLocked then
        return
    end
    local subDisable = self.Value <= cfg.Min
    local addDisable = self.Value >= cfg.Max or self.Value >= maxAffordable
    self.BtnSub:SetDisable(subDisable, not subDisable)
    self.BtnAdd:SetDisable(addDisable, not addDisable)
    local maxDisable = subDisable and addDisable
    self.BtnMax:SetDisable(maxDisable, not maxDisable)
    self.Light.gameObject:SetActiveEx(false)
end

function XUiPanelCultureGradeStepper:Refresh(value, min, max)
    local cfg = self.Cfg
    if min then
        cfg.Min = min
    end
    if max then
        cfg.Max = max
    end
    self:SetValue(value, false)
end

return XUiPanelCultureGradeStepper
