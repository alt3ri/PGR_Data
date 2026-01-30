---@class XUiSkyGardenShoppingStreetVideoRecording : XLuaUi
---@field TxtDetail UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetVideoRecording = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetVideoRecording")
local TIP_MSG_SHOW_TIME = 2400

--region 生命周期
function XUiSkyGardenShoppingStreetVideoRecording:OnStart()
    self.Timer = XScheduleManager.ScheduleOnce(function()
        self:Close()
    end, TIP_MSG_SHOW_TIME)
end

function XUiSkyGardenShoppingStreetVideoRecording:OnDestroy()
    XScheduleManager.UnSchedule(self.Timer)
end
--endregion

return XUiSkyGardenShoppingStreetVideoRecording
