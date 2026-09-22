local XUiPunishaarComBottomBagBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarComBottomBagBase")
local XUiPunishaarSellCardTipGridCard = require("XUi/XUiPunishaar/XUiPunishaarSellCardTip/XUiPunishaarSellCardTipGridCard")
local XUiPunishaarSellCardTipPanelBagLayout = require("XUi/XUiPunishaar/XUiPunishaarSellCardTip/XUiPunishaarSellCardTipPanelBagLayout")

--- 弹窗内独立 ComBottomBag：派生基类，复用两区卡牌编排 + OpenBagWithLock 等（不重写逻辑）。
--- 派生点：grid 类指向弹窗派生 grid（XUiPunishaarSellCardTipGridCard，派生 XUiGridShopCard 不重写）#69
local XUiPunishaarSellCardTipComBottomBag = XClass(XUiPunishaarComBottomBagBase, "XUiPunishaarSellCardTipComBottomBag")

function XUiPunishaarSellCardTipComBottomBag:_GetGridClass()
    return XUiPunishaarSellCardTipGridCard
end

--- 暂存区 PanelBagLayout 也指向弹窗派生类（_GetGridClass 返 SellCardTipGridCard 禁拖，对齐战斗区）#SellCardTip暂存区禁拖
function XUiPunishaarSellCardTipComBottomBag:_GetBagLayoutClass()
    return XUiPunishaarSellCardTipPanelBagLayout
end

--- 弹窗内主卡置灰（不能装配副卡的 Disable 遮罩），复用基类 OnSubCardHostHintBegin 两区置灰算法 #69
--- 不派发 SubCardHostHint 事件（避免 FightMain ComBottomBag/BagLayout 也置灰，FightMain 只收商店栏）
---@param subCardId number 待购入副卡模板 Id
function XUiPunishaarSellCardTipComBottomBag:RefreshHostHintDisable(subCardId)
    self:OnSubCardHostHintBegin(subCardId)  -- 对战区置灰
    if self._BagLayout then
        self._BagLayout:OnSubCardHostHintBegin(subCardId)  -- 背包置灰
    end
end

return XUiPunishaarSellCardTipComBottomBag
