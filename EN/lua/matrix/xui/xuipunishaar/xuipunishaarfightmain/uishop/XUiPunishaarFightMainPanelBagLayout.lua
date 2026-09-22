local XUiPunishaarPanelBagLayoutBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarPanelBagLayoutBase")

--- 商店态·背包暂存区容器（当前与战前态零差异，继承基类；分离时按需覆写基类 _Get* 系列）。
---@class XUiPunishaarFightMainPanelBagLayout : XUiPunishaarPanelBagLayoutBase
local XUiPunishaarFightMainPanelBagLayout = XClass(XUiPunishaarPanelBagLayoutBase, "XUiPunishaarFightMainPanelBagLayout")

return XUiPunishaarFightMainPanelBagLayout
