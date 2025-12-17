---@class XUiRacePopupMap : XLuaUi 赛道预览
local XUiRacePopupMap = XLuaUiManager.Register(XLuaUi, "UiRacePopupMap")

function XUiRacePopupMap:OnStart()
    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)
end

return XUiRacePopupMap