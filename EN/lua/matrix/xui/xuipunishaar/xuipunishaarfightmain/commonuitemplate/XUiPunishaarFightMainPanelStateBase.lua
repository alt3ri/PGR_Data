--- Shop/PreFight 状态根节点基类：DragRoot 卡牌拖拽托管 + BuySuccess 刷新订阅。
--- 子类覆写 _OnBuySuccess()（Shop=RefreshAll / PreFight=Refresh）；OnStart/专有按钮/子面板在子类自理。
--- A 级塌缩 B-1：OnCardDragCustody 与 OnEnable/OnDisable 事件模式在 PanelShop/PanelFightBefore 字节级相同，hoist 至此。
---@class XUiPunishaarFightMainPanelStateBase : XUiNode
---@field _Control XPunishaarControl
---@field DragRoot UnityEngine.GameObject 拖拽中卡牌的高层挂载节点（避免被其他 UI 遮挡）
local XUiPunishaarFightMainPanelStateBase = XClass(XUiNode, "XUiPunishaarFightMainPanelStateBase")

function XUiPunishaarFightMainPanelStateBase:OnEnable()
    self:_OnBuySuccess()
    self._Control.GameControl:AddEventListener(self._Control.GameControl.ShopEventId.BuySuccess, self._OnBuySuccess, self)
    -- notify 回流：服务端 NotifyPunishaarMasterCardChange（持有卡变更）。可能先于/后于 BuyGoods 回调：
    --   先于：SetCurrentNode 未调 → 商品 Goods 旧（IsBought 未更新）→ 标记 isFromMasterCardChange 跳过商品栏可升级判定（防误显）#升级动画
    --   后于：补刷（BuySuccess 时 Model 未含新卡 → 此事件补刷装备栏）#M1
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE, self._OnMasterCardChange, self)
    -- 卡牌拖拽托管：grid 拖起时派发 RequestCustody，由本节点 reparent 到 DragRoot 高层
    self._Control.GameControl:AddEventListener(self._Control.GameControl.DragEventId.RequestCustody, self.OnCardDragCustody, self)
end

function XUiPunishaarFightMainPanelStateBase:OnDisable()
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.ShopEventId.BuySuccess, self._OnBuySuccess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE, self._OnMasterCardChange, self)
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.DragEventId.RequestCustody, self.OnCardDragCustody, self)
end

--- BuySuccess 刷新钩子（子类覆写：Shop=RefreshAll，PreFight=Refresh）。OnEnable 时也调一次做初刷。
--- isFromMasterCardChange=true：MASTER_CARD_CHANGE 触发（SetCurrentNode 可能未调，商品 Goods IsBought 旧）→ 子类跳过商品栏可升级判定
function XUiPunishaarFightMainPanelStateBase:_OnBuySuccess(isFromMasterCardChange)
    -- 基类空，子类覆写
end

--- MASTER_CARD_CHANGE wrapper：标记 isFromMasterCardChange=true 调 _OnBuySuccess（子类跳过商品栏可升级判定）
function XUiPunishaarFightMainPanelStateBase:_OnMasterCardChange()
    self:_OnBuySuccess(true)
end

--- 拖拽托管：将卡牌移到高层 DragRoot，防止被同级面板遮挡。
---@param grid XUiGridShopCard
function XUiPunishaarFightMainPanelStateBase:OnCardDragCustody(grid)
    if XTool.UObjIsNil(self.DragRoot) then
        return
    end
    grid.Transform:SetParent(self.DragRoot.transform, false)
    grid.Transform:SetAsLastSibling()
end

return XUiPunishaarFightMainPanelStateBase
