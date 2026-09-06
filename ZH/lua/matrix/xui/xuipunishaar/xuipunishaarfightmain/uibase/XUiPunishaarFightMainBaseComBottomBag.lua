local XUiPunishaarComBottomBagBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarComBottomBagBase")
local XUiPunishaarFightMainBasePanelBagLayout = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiBase/XUiPunishaarFightMainBasePanelBagLayout")

--- 基底态·对战区+背包暂存容器（当前与商店/战前态零差异，继承基类；分离时按需覆写 _Get* 系列）。#66
--- 与 PanelFightBefore 的 PreFightComBottomBag 完全独立（独立 prefab 节点 + 独立 XUiNode，避监听双绑）。
---@class XUiPunishaarFightMainBaseComBottomBag : XUiPunishaarComBottomBagBase
local XUiPunishaarFightMainBaseComBottomBag = XClass(XUiPunishaarComBottomBagBase, "XUiPunishaarFightMainBaseComBottomBag")

--- 基底态持有基底态的 BagLayout 子类（派生链：将来 Base BagLayout 差异仅改本子类即生效）
function XUiPunishaarFightMainBaseComBottomBag:_GetBagLayoutClass()
    return XUiPunishaarFightMainBasePanelBagLayout
end

return XUiPunishaarFightMainBaseComBottomBag
