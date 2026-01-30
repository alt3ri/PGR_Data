local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")
---@class XDlcRelinkWorldFight : XDlcWorldFight
local XDlcRelinkWorldFight = XClass(XDlcWorldFight, "XDlcRelinkWorldFight")

---@param settleData XDlcFightSettleData
function XDlcRelinkWorldFight:OnFightFinishSettle(worldType, settleData, isWin, isCheat)
    XLuaUiManager.Open("UiDlcRelinkSettlementNew", settleData)
end

function XDlcRelinkWorldFight:OnFightForceExit(worldType)
    local uiName = "UiDlcRelinkRoom"
    if XLuaUiManager.IsStackUiOpen(uiName) then
        XLuaUiManager.CloseAllUpperUi(uiName)
    else
        XLuaUiManager.Open(uiName)
    end
end

return XDlcRelinkWorldFight
