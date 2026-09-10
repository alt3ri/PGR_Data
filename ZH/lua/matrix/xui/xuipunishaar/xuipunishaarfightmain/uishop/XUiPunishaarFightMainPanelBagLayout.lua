local XUiPunishaarPanelBagLayoutBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarPanelBagLayoutBase")
local XUiPanelPunishaarDragBuyTips = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Panel/XUiPanelPunishaarDragBuyTips")

--- 商店态·背包暂存区容器（当前与战前态零差异，继承基类；分离时按需覆写基类 _Get* 系列）。
---@class XUiPunishaarFightMainPanelBagLayout : XUiPunishaarPanelBagLayoutBase
local XUiPunishaarFightMainPanelBagLayout = XClass(XUiPunishaarPanelBagLayoutBase, "XUiPunishaarFightMainPanelBagLayout")

--- 商店态启用拖拽购买提示（覆写基类 nil 默认，实例化 XUiPanelPunishaarDragBuyTips）#PanelDragBuyTips
function XUiPunishaarFightMainPanelBagLayout:_GetDragBuyTipsClass()
    return XUiPanelPunishaarDragBuyTips
end

return XUiPunishaarFightMainPanelBagLayout
