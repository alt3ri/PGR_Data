---@class XUiPurchaseDialog: XLuaUi
local XUiPurchaseDialog = XLuaUiManager.Register(XLuaUi, 'UiPurchaseDialog')


function XUiPurchaseDialog:OnAwake()
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnTanchuangClose:AddEventListener(handler(self, self._DoClose))
end

function XUiPurchaseDialog:OnStart(sureCb, otherCb, closeCb, customInfo)
    self.SureCb = sureCb
    self.OtherCb = otherCb
    self.CloseCb = closeCb

    if not string.IsNilOrEmpty(customInfo) then
        self.TxtInfo.text = customInfo
    end
end

--- 点击继续当前行为的逻辑
function XUiPurchaseDialog:OnBtnConfirmClick()
    if self.SureCb then
        self.SureCb()
    end
    
    self:_DoClose()
end


--- 点击其他行为的逻辑
function XUiPurchaseDialog:OnBtnCloseClick()
    if self.OtherCb then
        self.OtherCb()
    end

    self:_DoClose()
end

function XUiPurchaseDialog:_DoClose()
    if self.CloseCb then
        self.CloseCb()
    end
    
    self:Close()
end

return XUiPurchaseDialog