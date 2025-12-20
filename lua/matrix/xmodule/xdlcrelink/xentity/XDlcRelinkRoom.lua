local XDlcRoom = require("XModule/XDlcRoom/XEntity/XDlcRoom")
---@class XDlcRelinkRoom : XDlcRoom
local XDlcRelinkRoom = XClass(XDlcRoom, "XDlcRelinkRoom")

function XDlcRelinkRoom:OpenMultiplayerRoom()
end

function XDlcRelinkRoom:PopThenOpenMultiplayerRoom()
end

function XDlcRelinkRoom:OpenFightUiLoading()
    XLuaUiManager.Open("UiDlcRelinkLoadingNew")
end

function XDlcRelinkRoom:CloseFightUiLoading()
    XLuaUiManager.Close("UiDlcRelinkLoadingNew")
end

function XDlcRelinkRoom:OnDisconnect()
    local uiName = "UiDlcRelinkRoom"
    if XLuaUiManager.IsStackUiOpen(uiName) then
        XLuaUiManager.CloseAllUpperUi(uiName)
    else
        XLuaUiManager.Open(uiName)
    end
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
        -- TODO 被踢出房间后的处理
    end
end

return XDlcRelinkRoom
