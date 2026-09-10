local XUiPunishaarComBottomBagBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarComBottomBagBase")
local XUiPunishaarFightMainPanelBagLayout = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiPunishaarFightMainPanelBagLayout")
local XUiPanelPunishaarDragBuyTips = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Panel/XUiPanelPunishaarDragBuyTips")

--- 商店态·对战区+背包暂存容器（当前与战前态零差异，继承基类；分离时按需覆写基类 _Get* 系列）。
---@class XUiPunishaarFightMainComBottomBag : XUiPunishaarComBottomBagBase
local XUiPunishaarFightMainComBottomBag = XClass(XUiPunishaarComBottomBagBase, "XUiPunishaarFightMainComBottomBag")

--- 商店态持有商店态的 BagLayout 子类（派生链：将来 Shop BagLayout 差异仅改 Shop 子类即生效）
function XUiPunishaarFightMainComBottomBag:_GetBagLayoutClass()
    return XUiPunishaarFightMainPanelBagLayout
end

--- 商店态启用拖拽购买提示（覆写基类 nil 默认，实例化 XUiPanelPunishaarDragBuyTips）#PanelDragBuyTips
function XUiPunishaarFightMainComBottomBag:_GetDragBuyTipsClass()
    return XUiPanelPunishaarDragBuyTips
end

return XUiPunishaarFightMainComBottomBag
