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
        XLuaUiManager.SafeClose(self.Name)
    end)

    -- 检查引导，因为在连续弹窗的过程中，不会触发指引，所以这里只能手动触发
    XDataCenter.GuideManager.CheckGuideOpen()
end

function XUiRadioSignPopupHall:OnDisable()
    XDataCenter.FunctionEventManager.OnFunctionEventCompleted()
end

return XUiRadioSignPopupHall