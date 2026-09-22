--- 真正显示副卡及副卡的拖拽主体（商店单独售卖的副卡商品）。
--- 拖拽机制（XGoInputHandler 三阶段/阈值/跟手/reparent/blocksRaycasts/保底定时器）委托 XUiCardDragHandler
---   （C 级塌缩：原复制自 XUiGridShopCard 的 ~130 行同构拖拽 plumbing 已 hoist 至 handler）。
---   拖的是 UiPunishaarSubCard 节点（self.Transform），归位回原 parent/localPos/sibling。
--- 字段：_DragArea=Shop（商品栏来源）、_DragCardData=goods、_DragSourcePos=goodsIndex，复用 Control.BeginDragCard/EndDragCard。
local XUiCardDragHandler = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiCardDragHandler")

---@class XUiComShopSubCardItem: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field PanelSubCard @副卡显示根节点（内含 GroupControl：Role/Pet 两 Group 切头像）
---@field GroupControl XUiGroupControl 头像分组控制器（Role/Pet 两 Group，按副卡 Type 切状态 + SetRawImage 设图）#67 #71
---@field PnlFrozen @冻结态根节点（商品栏副卡冻结显示 #71）
---@field BtnClick XUiComponent.XUiButton 点击打开副卡详情（与 XGoInputHandler 同 SubCardItem 子树，阈值区分 click/drag；grid top-level BtnClick 副卡时禁用避免遮挡）
local XUiComShopSubCardItem = XClass(XUiNode, "XUiComShopSubCardItem")

function XUiComShopSubCardItem:OnStart()
    if self.BtnClick then
        -- 点击（未达拖拽阈值）→ 经 SubCardShow.Parent(grid) 调 grid 的详情入口（已 IsSubCard→ShowSubCardTips 分流）
        self.BtnClick:AddEventListener(handler(self, self._OnBtnClick))
    end
    if self.PnlFrozen then
        self.PnlFrozen.gameObject:SetActiveEx(false)
    end
end

--- 点击副卡打开详情：复用 grid._OnCardClick（读 grid._Goods，IsSubCard 分流到 ShowSubCardTips）。
function XUiComShopSubCardItem:_OnBtnClick()
    local grid = self.Parent and self.Parent.Parent
    if grid and grid._OnCardClick then
        grid:_OnCardClick()
    end
end

--- 刷新副卡商品显示（GroupControl 切 Role/Pet 头像 + 冻结态；详细信息在详情页）。
--- 意识/共鸣双轨（#71，#67 改 GroupControl）：按 cardCfg.Type==Awareness 切 Role/Pet 组 + SetRawImage 设图。
---@param goods table Server.XPunishaarGoods
---@param goodsIndex number 服务端槽位索引（0-based）
function XUiComShopSubCardItem:Refresh(goods, goodsIndex)
    self._DragCardData  = goods
    self._DragSourcePos = goodsIndex
    if not goods or goods.CardId == 0 then return end
    local cardCfg = self._Control:GetTablePunishaarCard(goods.CardId)

    -- 副卡头像：GroupControl 按 Type==Awareness（意识轨=Role / 共鸣轨=Pet）切组 + SetRawImage 设图
    if self.GroupControl then
        local isRole = cardCfg ~= nil and cardCfg.Type == XMVCA.XPunishaar.EnumConst.CardType.Awareness
        self.GroupControl:ChangeGroup(isRole and "Role" or "Pet")
        if cardCfg and not string.IsNilOrEmpty(cardCfg.Icon) then
            self.GroupControl:SetRawImage(0, cardCfg.Icon)
        end
    end

    -- 冻结态：商品栏副卡的冻结显示走 PnlFrozen（对齐主卡走 head 内 ImgFrozen 的分工 #67/#71）
    if self.PnlFrozen then
        self.PnlFrozen.gameObject:SetActiveEx(goods.Frozen == true)
    end
end

--region 拖拽（Theatre5 假拖拽，委托 XUiCardDragHandler）

--- 由外壳调用开启拖拽能力，声明来源区域。幂等：重复调只更新 area（机制 init 一次）。
--- 拖拽机制由 XUiCardDragHandler 持有；host 持 _DragArea/_DragCardData/_DragSourcePos 供 handler 用。
---@param dragArea number Control.DragArea：Shop
function XUiComShopSubCardItem:EnableDrag(dragArea)
    self._DragArea = dragArea
    if not self._DragHandler then
        self._DragHandler = XUiCardDragHandler.New(self)
    end
    self._DragHandler:Enable()
end

function XUiComShopSubCardItem:OnDisable()
    -- 隐藏时若仍在拖拽：强制归位并清会话。GO inactive 后 Unity 不再派发 EndDrag 回调，
    -- 不中断则节点永久滞留 DragRoot + 逻辑层拖拽会话残留致后续拖拽被 GetIsDraggingCard 拒。
    if self._DragHandler then
        self._DragHandler:CancelDragIfDragging()
    end
end

function XUiComShopSubCardItem:OnDestroy()
    if self._DragHandler then
        self._DragHandler:OnDestroy()
    end
end

--endregion

return XUiComShopSubCardItem
