--- 肉鸽5内部使用的通用确认弹窗
---@class XUiTheatre5PopupCommon: XLuaUi
local XUiTheatre5PopupCommon = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PopupCommon')

function XUiTheatre5PopupCommon:OnAwake()
    self:RegisterClickEvent(self.BtnBack, handler(self, self.Close))
    self:RegisterClickEvent(self.BtnSure, handler(self, self.OnBtnSureClickEvent))
    self:RegisterClickEvent(self.BtnCancel, handler(self, self.OnBtnCancelClickEvent))
    self.TxtTips = self.TxtTips or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Inner/Content/TxtTips", "Text")
end

function XUiTheatre5PopupCommon:OnStart(title, content, closeCb, sureCb, cancelCb, dailyIgnoreKey, hideFullClose, hideCancel, showTxtTips)
    self.TxtName.text = title
    self.TxtDescription.text = content
    self.CloseCb = closeCb
    self.SureCb = sureCb
    self.CancelCb = cancelCb
    self.DailyIgnoreKey = dailyIgnoreKey

    if hideFullClose then
        self.BtnBack.gameObject:SetActiveEx(false)
    end

    if hideCancel then
        self.BtnCancel.gameObject:SetActiveEx(false)
    end

    self.BtnCheck.gameObject:SetActiveEx(self.DailyIgnoreKey ~= nil)

    if showTxtTips then
        self.TxtTips.gameObject:SetActiveEx(true)
    else
        self.TxtTips.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre5PopupCommon:OnBtnSureClickEvent()
    if self.SureCb then
        self.SureCb()
    end

    self:Close()
end

function XUiTheatre5PopupCommon:OnBtnCancelClickEvent()
    if self.CancelCb then
        self.CancelCb()
    end

    self:Close()
end

function XUiTheatre5PopupCommon:Close()
    if self.CloseCb then
        self.CloseCb()
    end

    self.Super.Close(self)
end

return XUiTheatre5PopupCommon