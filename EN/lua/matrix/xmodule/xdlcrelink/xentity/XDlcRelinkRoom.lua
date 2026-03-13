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
    -- 断线后，打开界面没有意义，所以覆盖父类方法
    --XMVCA.XDlcRelink:CommonRunRelinkRoomUiHandle()
end

function XDlcRelinkRoom:OnRoomLeaderTimeOut()
    -- 房主超时后的处理
end

function XDlcRelinkRoom:OnKickOut(code)
    if code == XCode.DlcMultiplayerClose then
        XLuaUiManager.RunMain(true)
    else
        -- 被踢出房间后的处理
    end
end

function XDlcRelinkRoom:OnCustomEnterTargetRoom()
    XMVCA.XDlcRelink:CommonRunRelinkRoomUiHandle()
end

return XDlcRelinkRoom
