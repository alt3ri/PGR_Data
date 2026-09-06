local XUiPunishaarComBottomBagBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarComBottomBagBase")
local XUiPunishaarFightMainPreFightPanelBagLayout = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiPreFight/XUiPunishaarFightMainPreFightPanelBagLayout")

--- 战前态·对战区+背包暂存容器（当前与商店态零差异，继承基类；分离时按需覆写基类 _Get* 系列）。
---@class XUiPunishaarFightMainPreFightComBottomBag : XUiPunishaarComBottomBagBase
local XUiPunishaarFightMainPreFightComBottomBag = XClass(XUiPunishaarComBottomBagBase, "XUiPunishaarFightMainPreFightComBottomBag")

--- 战前态持有战前态的 BagLayout 子类（派生链：将来 PreFight BagLayout 差异仅改 PreFight 子类即生效）
function XUiPunishaarFightMainPreFightComBottomBag:_GetBagLayoutClass()
    return XUiPunishaarFightMainPreFightPanelBagLayout
end

return XUiPunishaarFightMainPreFightComBottomBag
