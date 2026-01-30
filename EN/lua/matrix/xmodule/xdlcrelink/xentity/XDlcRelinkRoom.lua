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

function XDlcRelinkRoom:OnEnterWorld()
    XLuaUiManager.SafeClose("UiDlcRelinkPopupPlayerInvite")
    XLuaUiManager.SafeClose("UiDlcRelinkCharacter")
    XLuaUiManager.SafeClose("UiDlcRelinkCharacterOther")
    XLuaUiManager.SafeClose("UiDlcRelinkEquipBag")
    XLuaUiManager.SafeClose("UiDlcRelinkEquipReform")
    XLuaUiManager.SafeClose("UiDlcRelinkEquipDecompose")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupFilter")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupEquipCompose")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupEquipAttributeDetail")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupEquipPresets")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupCharacterAttributeDetail")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupRename")
    XLuaUiManager.SafeClose("UiDlcRelinkBubbleEquipDetail")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupCommon")
    XLuaUiManager.SafeClose("UiDlcRelinkToastCommon")
    XLuaUiManager.SafeClose("UiDlcRelinkToastCommonSmall")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupItemDetail")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupInvitation")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupResearch")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupSwitchCareer")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupExchangeWheel")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupSkillDetail")
    XLuaUiManager.SafeClose("UiDlcRelinkLvReward")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupGetReward")
    XLuaUiManager.SafeClose("UiDlcRelinkShopItem")
    XLuaUiManager.SafeClose("UiDlcRelinkEncyclopedia")
    XLuaUiManager.SafeClose("UiDlcRelinkPopupChooseAttribute")
end

return XDlcRelinkRoom
