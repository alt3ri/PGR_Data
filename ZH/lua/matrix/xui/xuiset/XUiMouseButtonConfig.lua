local XUiMouseButtonConfig = XLuaUiManager.Register(XLuaUi, "UiMouseButtonConfig")
local XInputManager = CS.XInputManager

local MouseMode = {
    AttackLeft = 1,
    AttackRight = 2,
}

local CurrMode -- 1左键攻击 2右键攻击

function XUiMouseButtonConfig:OnStart(mouseButtonKeyItem)
    self.InputMapId = mouseButtonKeyItem.CurInputMapId
    self.OperationType = mouseButtonKeyItem.CurOperationType
    self.DataId = mouseButtonKeyItem:GetDataId()
    XInputManager.StartEditKey(CS.InputDeviceType.Keyboard, 0, 0, nil, self.InputMapId, self.OperationType, self.DataId)
    self:Init()
end

function XUiMouseButtonConfig:OnDestroy()
    XInputManager.EndEdit()
end

function XUiMouseButtonConfig:Init()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnConfirm.CallBack = function()
        local currMode = XInputManager.IsModifyMouse(self.InputMapId) and MouseMode.AttackLeft or MouseMode.AttackRight
        if CurrMode ~= currMode then
            XInputManager.SwitchKeyboardMouseFunc(self.InputMapId)
            CS.XGameEventManager.Instance:Notify(XEventId.EVENT_SETTING_KEYBOARD_KEY_CHANGED, CS.InputDeviceType.Keyboard)
        end
        self:Close()
    end

    local ButtonSetGroup = { self.MouseButton1, self.MouseButton2 }
    self.ToggleGroup:Init(ButtonSetGroup, handler(self, self.OnMouseClickModeChanged))
    self.ToggleGroup:SelectIndex(XInputManager.IsModifyMouse(self.InputMapId) and MouseMode.AttackLeft or MouseMode.AttackRight)
end

function XUiMouseButtonConfig:OnMouseClickModeChanged(index)
    CurrMode = index
    self:UpdateText()
end

function XUiMouseButtonConfig:UpdateText()
    self.MouseLeftText.text = CurrMode == MouseMode.AttackLeft and CS.XTextManager.GetText("PcMouseButtonAttack") or CS.XTextManager.GetText("PcMouseButtonDodge")
    self.MouseRightText.text = CurrMode == MouseMode.AttackRight and CS.XTextManager.GetText("PcMouseButtonAttack") or CS.XTextManager.GetText("PcMouseButtonDodge")
end
