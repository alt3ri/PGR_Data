local XDlcWorldFight = require("XModule/XDlcRoom/XDlcWorldFight/XDlcWorldFight")
---@class XDlcRelinkWorldFight : XDlcWorldFight
local XDlcRelinkWorldFight = XClass(XDlcWorldFight, "XDlcRelinkWorldFight")

---@param settleData XDlcFightSettleData
function XDlcRelinkWorldFight:OnFightFinishSettle(worldType, settleData, isWin, isCheat)
    XMVCA.XDlcRelink:DisposeWorld()
    if settleData.ResultData.SettleState == XEnumConst.DlcWorld.SettleState.LoadingFail then
        -- loading失败，直接返回房间界面
        XEventManager.DispatchEvent(XEventId.EVENT_DLC_RELINK_MATE_LOAD_FAIL)
    else
        XLuaUiManager.Open("UiDlcRelinkSettlementNew", settleData)
    end
end

function XDlcRelinkWorldFight:OnFightForceExit(worldType)
    XMVCA.XDlcRelink:DisposeWorld()
    -- 结算数据为空的时候直接返回主界面
    XLuaUiManager.RunMain()
    XUiManager.TipText("DlcRelinkMateForceExit")
end

return XDlcRelinkWorldFight
