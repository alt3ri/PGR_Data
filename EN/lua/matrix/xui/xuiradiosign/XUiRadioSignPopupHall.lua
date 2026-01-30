---@class XUiRadioSignPopupHall : XLuaUi
local XUiRadioSignPopupHall = XLuaUiManager.Register(XLuaUi, "UiRadioSignPopupHall")

function XUiRadioSignPopupHall:OnAwake()
    self:BindExitBtns(self.BtnClose)
end

---@param content XTableRadioSignContent
function XUiRadioSignPopupHall:OnStart(content)
    self.TxtInfo.text = content.Text
    XUiHelper.RegisterClickEvent(self, self.BtnGo, function()
        XLuaUiManager.Open("UiRadioSignMain", content)
        XLuaUiManager.Remove(self.Name)
    end)
end

return XUiRadioSignPopupHall