local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")
---@class XDlcRelinkRoom : XDlcRoom
local XDlcRelinkRoom = XClass(XDlcRoom, "XDlcRelinkRoom")

function XDlcRelinkRoom:OpenMultiplayerRoom()
    --XLuaUiManager.Open("UiDlcRelinkRoom")
    --XLuaUiManager.Remove("UiRelinkPopupChooseRoom")
end

function XDlcRelinkRoom:PopThenOpenMultiplayerRoom()
    --XLuaUiManager.PopThenOpen("UiDlcRelinkRoom")
end

function XDlcRelinkRoom:OpenFightUiLoading()
    XLuaUiManager.Open("UiRelinkLoading")
end

function XDlcRelinkRoom:CloseFightUiLoading()
    XLuaUiManager.Close("UiRelinkLoading")
end

function XDlcRelinkRoom:OnDisconnect()
    XLuaUiManager.Open("UiDlcSettleLose")
    XLuaUiManager.SafeClose("UiDlcRelinkRoom")
end

function XDlcRelinkRoom:OnRoomLeaderTimeOut()
    if not XUiManager.CheckTopUi(CsXUiType.Normal, "UiDlcRelinkRoom") then
        XLuaUiManager.Remove("UiDlcRelinkRoom")
    end
end

function XDlcRelinkRoom:OnKickOut(code)
    if code == XCode.DlcMultiplayerClose then
        XLuaUiManager.RunMain(true)
    else
        --XLuaUiManager.SafeClose("UiRelinkPopupChooseRoom")
        --if not XUiManager.CheckTopUi(CsXUiType.Normal, "UiDlcRelinkRoom") then
        --    XLuaUiManager.Remove("UiDlcRelinkRoom")
        --end
    end
end

function XDlcRelinkRoom:OnCreateRoom()
    --XLuaUiManager.SafeClose("UiDialog")
end

function XDlcRelinkRoom:OnEnterWorld()
    --XLuaUiManager.SafeClose("UiDlcRelinkRoom")
end

return XDlcRelinkRoom
