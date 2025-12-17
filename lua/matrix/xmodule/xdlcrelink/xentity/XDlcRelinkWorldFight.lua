local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")
---@class XDlcRelinkWorldFight : XDlcWorldFight
local XDlcRelinkWorldFight = XClass(XDlcWorldFight, "XDlcRelinkWorldFight")

function XDlcRelinkWorldFight:OnFightFinishSettle(worldType, settleData, isWin, isCheat)
    if isWin then
        XLuaUiManager.Open("UiRelinkSettlement", settleData.ResultData)
    else
        XLuaUiManager.Open("UiDlcSettleLose")
    end
end

function XDlcRelinkWorldFight:OnFightForceExit(worldType)
    XLuaUiManager.Open("UiDlcSettleLose")
    XLuaUiManager.SafeClose("UiDlcRelinkRoom")
end

return XDlcRelinkWorldFight
