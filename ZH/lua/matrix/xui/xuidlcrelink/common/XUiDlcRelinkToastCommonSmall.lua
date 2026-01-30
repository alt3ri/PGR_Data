---@class XUiDlcRelinkToastCommonSmall : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkToastCommonSmall = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkToastCommonSmall")
local TIP_MSG_SHOW_TIME = 2000

function XUiDlcRelinkToastCommonSmall:Refresh(content)
    self.TxtDesc.text = XUiHelper.ConvertLineBreakSymbol(content)
    self:PlayAnimation("AnimShow")
    self:StopTimer()
    self.Timer = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:Close()
    end, TIP_MSG_SHOW_TIME)
end

function XUiDlcRelinkToastCommonSmall:OnDisable()
    self:StopTimer()
end

function XUiDlcRelinkToastCommonSmall:StopTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

return XUiDlcRelinkToastCommonSmall
