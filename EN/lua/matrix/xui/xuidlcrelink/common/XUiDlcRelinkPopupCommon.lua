---@class XUiDlcRelinkPopupCommon : XLuaUi
---@field private _Control XDlcRelinkControl
---@field BtnHint XUiComponent.XUiButton
local XUiDlcRelinkPopupCommon = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupCommon")

function XUiDlcRelinkPopupCommon:OnAwake()
    self:RegisterUiEvents()
end

---@param title string 标题
---@param content string 内容
---@param closeCallback function 关闭回调
---@param sureCallback function 确认回调
---@param extraData { ConfirmText:string, CancelText:string, NoRemindText:string, TipsKey:string, DefaultNoRemind:boolean, NoRemindCallback:function }额外数据
function XUiDlcRelinkPopupCommon:OnStart(title, content, closeCallback, sureCallback, extraData)
    self.TxtTitle.text = title or ""
    self.TxtContent.text = content or ""

    self.CloseCallback = closeCallback
    self.SureCallback = sureCallback

    if extraData then
        self.NoRemindCallback = extraData.NoRemindCallback

        if extraData.ConfirmText then
            self.BtnConfirm:SetNameByGroup(0, extraData.ConfirmText)
        end

        if extraData.CancelText then
            self.BtnCancel:SetNameByGroup(0, extraData.CancelText)
        end

        if extraData.NoRemindText then
            self.BtnHint:SetNameByGroup(0, extraData.NoRemindText)
        end

        self.BtnHint.gameObject:SetActiveEx(self.NoRemindCallback and true or false)
        self.BtnHint:SetButtonState(extraData.DefaultNoRemind and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
end

function XUiDlcRelinkPopupCommon:RegisterUiEvents()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnHint:AddEventListener(handler(self, self.OnBtnHintClick))
    self.BtnCancel:AddEventListener(handler(self, self.OnBtnCancelClick))
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
end

function XUiDlcRelinkPopupCommon:OnBtnCloseClick()
    self:Close()
end

function XUiDlcRelinkPopupCommon:OnBtnConfirmClick()
    local isSelect = self.BtnHint:GetToggleState()
    if self.NoRemindCallback then
        self.NoRemindCallback(isSelect)
    end
    self:Close()
    if self.SureCallback then
        self.SureCallback()
    end
end

function XUiDlcRelinkPopupCommon:OnBtnCancelClick()
    self:Close()
    if self.CloseCallback then
        self.CloseCallback()
    end
end

function XUiDlcRelinkPopupCommon:OnBtnHintClick()
    local isSelect = self.BtnHint:GetToggleState()
    if self.NoRemindCallback then
        self.NoRemindCallback(isSelect)
    end
end

return XUiDlcRelinkPopupCommon
