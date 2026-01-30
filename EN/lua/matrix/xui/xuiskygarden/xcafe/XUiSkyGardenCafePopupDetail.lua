
local XUiBigWorldPopupConfirm = require("XUi/XUiBigWorld/XCommon/XUiBigWorldPopupConfirm")

---@class XUiSkyGardenCafePopupDetail : XUiBigWorldPopupConfirm
local XUiSkyGardenCafePopupDetail = XMVCA.XBigWorldUI:Register(XUiBigWorldPopupConfirm, "UiSkyGardenCafePopupDetail")

function XUiSkyGardenCafePopupDetail:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick, true)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick, true)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick, true)
end

function XUiSkyGardenCafePopupDetail:_RefreshTitle()
    local data = self._Data

    self.TxtInfoNormal.text = data.Tips or ""
end

function XUiSkyGardenCafePopupDetail:_RefreshClick()
    local data = self._Data
    local cancelText = data:GetCancelClickText()
    local sureText = data:GetSureClickText()
    local toggleText = data:GetToggleText()

    if not string.IsNilOrEmpty(cancelText) then
        self.BtnClose:SetNameByGroup(0, cancelText)
    end
    if not string.IsNilOrEmpty(sureText) then
        self.BtnConfirm:SetNameByGroup(0, sureText)
    end
    if not string.IsNilOrEmpty(toggleText) and self.TxtTips then
        self.TxtTips.text = toggleText
    end
    self.BtnConfirm.gameObject:SetActiveEx(data.SureClickData.IsActive)
    self.BtnClose.gameObject:SetActiveEx(data.CancelClickData.IsActive)
    self.BtnTanchuangClose.gameObject:SetActiveEx(data.CloseClickData.IsActive)
end