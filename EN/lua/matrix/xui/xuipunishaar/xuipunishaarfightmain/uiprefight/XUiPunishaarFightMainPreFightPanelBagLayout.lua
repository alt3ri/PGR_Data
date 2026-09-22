local XUiPunishaarPanelBagLayoutBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarPanelBagLayoutBase")

--- 战前态·背包暂存区容器（当前与商店态零差异，继承基类；分离时按需覆写基类 _Get* 系列）。
---@class XUiPunishaarFightMainPreFightPanelBagLayout : XUiPunishaarPanelBagLayoutBase
local XUiPunishaarFightMainPreFightPanelBagLayout = XClass(XUiPunishaarPanelBagLayoutBase, "XUiPunishaarFightMainPreFightPanelBagLayout")

return XUiPunishaarFightMainPreFightPanelBagLayout
