--- 结算 UI 基类
--- 所有结算页面（胜利/失败/自定义结算）统一继承此类
--- 在 OnDestroyUi 中，先执行子类 OnDestroy 再自动 Dispatch EVENT_FIGHT_FINISH_SETTLE
--- 子类无需手动发送该事件
---
--- 【新增结算页面须知】
--- 注册时先 require 再传入 Register：
--- local XLuaUiSettle = require("XUi/XUiBase/XLuaUiSettle")
--- local XUiMySettle = XLuaUiManager.Register(XLuaUiSettle, "UiMySettle")
--- 否则空花（大世界）回流逻辑收不到"结算已关闭"通知，会导致无法回到 DLC 战斗
---
--- 监听方：XBigWorldGamePlayProcess.lua → OnExitFubenFightAndEnterDlcFight
local XLuaUiSettle = XClass(XLuaUi, "XLuaUiSettle")

function XLuaUiSettle:OnDestroyUi()
    XLuaUi.OnDestroyUi(self)
    XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_FINISH_SETTLE)
end

return XLuaUiSettle
