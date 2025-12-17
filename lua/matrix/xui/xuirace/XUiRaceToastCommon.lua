---@class XUiRaceToastCommon : XLuaUi 飘字
---@field _Control XRaceControl
local XUiRaceToastCommon = XLuaUiManager.Register(XLuaUi, "UiRaceToastCommon")

function XUiRaceToastCommon:OnStart(str)
    self.TxtTitle.text = str
    local timerId = XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, self._Control:GetIntClientConfig("ToastKeepTime"))
    self:_AddTimerId(timerId)
end

return XUiRaceToastCommon