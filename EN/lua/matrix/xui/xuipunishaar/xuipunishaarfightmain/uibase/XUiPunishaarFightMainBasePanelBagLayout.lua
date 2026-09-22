local XUiPunishaarPanelBagLayoutBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarPanelBagLayoutBase")

--- 基底态·背包暂存区容器（当前与商店/战前态零差异，继承基类；分离时按需覆写基类 _Get* 系列）。#66
---@class XUiPunishaarFightMainBasePanelBagLayout : XUiPunishaarPanelBagLayoutBase
local XUiPunishaarFightMainBasePanelBagLayout = XClass(XUiPunishaarPanelBagLayoutBase, "XUiPunishaarFightMainBasePanelBagLayout")

return XUiPunishaarFightMainBasePanelBagLayout
