--- 肉鸽6内部使用的通用确认弹窗
---@class XUiTheatre6PopupCommon: XLuaUi
local XUiTheatre6PopupCommon = XLuaUiManager.Register(XLuaUi, 'UiTheatre6PopupCommon')

function XUiTheatre6PopupCommon:OnAwake()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnSure:AddEventListener(handler(self, self.OnBtnSureClickEvent))
    self.BtnCancel:AddEventListener(handler(self, self.OnBtnCancelClickEvent))
    self.TxtTips = self.TxtTips or XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/Inner/Content/TxtTips", "Text")
end

function XUiTheatre6PopupCommon:OnStart(title, content, closeCb, sureCb, cancelCb, dailyIgnoreKey, hideFullClose, hideCancel, showTxtTips, hideSure)
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
    
    if hideSure then
        self.BtnSure.gameObject:SetActiveEx(false)
    end

    self.BtnCheck.gameObject:SetActiveEx(self.DailyIgnoreKey ~= nil)

    if showTxtTips then
        self.TxtTips.gameObject:SetActiveEx(true)
    else
        self.TxtTips.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre6PopupCommon:OnBtnSureClickEvent()
    if self.SureCb then
        self.SureCb()
    end

    self:Close()
end

function XUiTheatre6PopupCommon:OnBtnCancelClickEvent()
    if self.CancelCb then
        self.CancelCb()
    end

    self:Close()
end

function XUiTheatre6PopupCommon:Close()
    if self.CloseCb then
        self.CloseCb()
    end

    self.Super.Close(self)
end

return XUiTheatre6PopupCommon