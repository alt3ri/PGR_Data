--- Control 部分类：卡牌拖拽会话状态中枢（表现层拖拽的逻辑中台）。
--- 职责对齐 Theatre5 的 ShopControl 拖拽部分：持有当前拖拽会话状态，
---   向表现层暴露 Begin/Focus/End 接口，EndDragCard 按"源→目标"组合路由到具体操作。
--- 设计要点（第一阶段，表现框架）：
---   - 假拖拽：表现层物体先动，本中枢只记状态、判定、发请求；无论成败表现层都归位。
---   - 操作接口可插拔：购买(_DropAction_Buy)已接现有 BuyGoods；移动/卖出为占位(等协议/入口)。
---   - 落点先按区域粒度(单格)判定；多格占位规则为后续增量。
---@type XPunishaarGameControl
local XPunishaarGameControl = XClassPartial("XPunishaarGameControl")

-- 拖拽来源/落点区域类型（表现层与本中枢约定的语义，独立于服务端 CardAreaType）
local DragArea = {
    Shop      = 1,  -- 商品栏（商店待售商品）
    FightArea = 2,  -- 对战区
    Bag       = 3,  -- 背包暂存区
    SellZone  = 4,  -- 卖出区（拖到商店区域卖出）
}
XPunishaarGameControl.DragArea = DragArea

-- 局外拖拽的表现层托管事件（grid 派发 → 当前状态实控节点接住做 reparent；与局内 FightControl.EventIds 分开）
XPunishaarGameControl.DragEventId = {
    RequestCustody = "PunishaarDragCustody",  -- 请求托管：payload = grid（拖起时派发）
    -- 副卡宿主选择态：拖起副卡时派发 Begin(payload = subCardId)，UI 容器据此给"不可作宿主的主卡格"置灰；
    -- 松手（无论成败）时派发 End(无 payload)，UI 恢复全部主卡格。
    SubCardHostHintBegin = "PunishaarSubCardHostHintBegin",
    SubCardHostHintEnd   = "PunishaarSubCardHostHintEnd",
}

--region 拖拽会话状态 ----------------------------------------------------------

--- 开始一次拖拽会话（由可拖拽 grid 在真拖拽触发时调用）。
---@param cardData table 拖拽的卡数据（商品 Goods 或 MasterCard，按 sourceArea 区分）
---@param sourceArea number DragArea：拖拽来源区域
---@param sourcePos number|nil 源位置（商品槽 index / 卡 StartPos，视来源而定）
function XPunishaarGameControl:BeginDragCard(cardData, sourceArea, sourcePos)
    self._DraggingCardData   = cardData
    self._DraggingSourceArea = sourceArea
    self._DraggingSourcePos  = sourcePos
    self._FocusArea = nil
    self._FocusPos  = nil

    -- 拖起的是副卡（商店商品 cardData.CardId 为副卡）→ 进入"副卡宿主选择"态，
    -- 通知 UI 容器给不可作宿主的主卡格置灰（DragControl 在逻辑层拿不到 grid，只能走事件）。
    self._IsDraggingSubCard = cardData and cardData.CardId ~= nil and self:GetControl():IsSubCard(cardData.CardId) or false
    if self._IsDraggingSubCard then
        self:DispatchEvent(self.DragEventId.SubCardHostHintBegin, cardData.CardId)
    end

    -- 通知 UI 拖拽开始（PanelTopShop 显隐卖出区 #50）
    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_DRAG_BEGIN)
end

--- 是否正处于拖拽会话中。
---@return boolean
function XPunishaarGameControl:GetIsDraggingCard()
    return self._DraggingCardData ~= nil
end

--- 拖拽的卡与来源（表现层/操作接口读取用）。
function XPunishaarGameControl:GetDraggingCardData()
    return self._DraggingCardData
end

function XPunishaarGameControl:GetDraggingSourceArea()
    return self._DraggingSourceArea
end

--- 设置当前指针悬停的落点目标（落点容器 OnEnter 调用）。
---@param area number DragArea：落点区域
---@param pos number|nil 落点位置（单格阶段可为 nil，区域粒度足够）
function XPunishaarGameControl:SetDragFocusTarget(area, pos)
    self._FocusArea = area
    self._FocusPos  = pos
end

--- 清除落点目标（落点容器 OnExit 调用）。
function XPunishaarGameControl:ClearDragFocusTarget()
    self._FocusArea = nil
    self._FocusPos  = nil
end

--- 当前落点区域（栏级反算 handler 读以判定是否清空 / 防抖，避免越权清卖出区焦点 #批次2）。
---@return number|nil DragArea
function XPunishaarGameControl:GetDragFocusArea()
    return self._FocusArea
end

--- 当前落点是否可放置。
--- 原位取消 #R2：同区域 focusPos == SourcePos 精确等值才判原位（无效）；
--- 多格卡拖到自身占格内其他格 ≠ 原位 → 尝试放置（下游 InsertCard repack 微移到新位；策划定：不重合即放置，防无法微调多格卡）。
---@return boolean
function XPunishaarGameControl:CheckDragDropValid()
    if not self._DraggingCardData or not self._FocusArea then
        return false
    end
    -- 同区域原位：精确等值（单格/多格统一；多格卡自身占格内位移交下游 repack 微移，不在此判原位 #R2）
    if self._FocusArea == self._DraggingSourceArea and self._FocusPos == self._DraggingSourcePos then
        return false
    end
    return true
end

--- 结束拖拽会话并按"源→目标"路由到具体操作。
--- 返回 true 表示已发起某操作（异步，成败都会经 cb 归位）；false 表示无有效操作（调用方自行归位）。
---@param cb function 归位回调（表现层传入，操作完成/无效时调用）
---@return boolean 是否已发起操作
function XPunishaarGameControl:EndDragCard(cb)
    local srcArea = self._DraggingSourceArea
    local dstArea = self._FocusArea
    local handled = false

    if self:CheckDragDropValid() then
        if srcArea == DragArea.Shop and (dstArea == DragArea.FightArea or dstArea == DragArea.Bag) then
            handled = self:_DropAction_Buy(dstArea, cb)
        elseif (srcArea == DragArea.FightArea or srcArea == DragArea.Bag)
            and (dstArea == DragArea.FightArea or dstArea == DragArea.Bag) then
            handled = self:_DropAction_Move(dstArea, cb)
        elseif (srcArea == DragArea.FightArea or srcArea == DragArea.Bag)
            and dstArea == DragArea.SellZone then
            handled = self:_DropAction_Sell(cb)
        end
    end

    -- 副卡宿主选择态结束：无论成功/失败/取消，均恢复全部主卡格（与 Begin 对称，在清理会话前派发）
    if self._IsDraggingSubCard then
        self:DispatchEvent(self.DragEventId.SubCardHostHintEnd)
    end

    -- 通知 UI 拖拽结束（PanelTopShop 隐卖出区 #50）
    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_DRAG_END)

    self:_ClearDragSession()
    return handled
end

--- 取消拖拽会话（app 切后台等异常场景）。
--- 与 EndDragCard 的清理尾对称，但**绕过操作路由**（不调 _DropAction_*，无 Buy/Move/Sell 请求）——
--- 表现层归位由 XUiCardDragHandler:OnApplicationPause 自理，本方法只清逻辑会话 + 派发 DRAG_END
--- 让 PanelBagLayoutBase._OnDragEnd 恢复 bag grids blocksRaycasts + 副卡宿主置灰恢复。
function XPunishaarGameControl:CancelDrag()
    if not self:GetIsDraggingCard() then return end
    if self._IsDraggingSubCard then
        self:DispatchEvent(self.DragEventId.SubCardHostHintEnd)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_DRAG_END)
    self:_ClearDragSession()
end

--- 清空拖拽会话状态（EndDragCard 内部 / 异常兜底）。
function XPunishaarGameControl:_ClearDragSession()
    self._DraggingCardData   = nil
    self._DraggingSourceArea = nil
    self._DraggingSourcePos  = nil
    self._FocusArea = nil
    self._FocusPos  = nil
    self._IsDraggingSubCard = nil
end

--endregion

--region 落点操作接口（可插拔；购买已接现有协议，移动/卖出占位待协议） -------------

--- 购买+落位：商品栏 → 对战区/背包。构造 ArrangeCtx(Drag source) → 选策略 → execute。
--- 主卡精确落点：BuyExact/BuyRepack；副卡挂宿主：BuySubCardMount/BuySubCardReplace（二次确认归位后者 execute，仅 Drag 路径）。
--- 副卡 invalid host（空位/非主卡/类型不匹配）在此拒止"BuySubCardWithInvalidTarget"，不进策略链。
---@param dstArea number DragArea 目标区域（FightArea/Bag）
---@param cb function 归位回调
---@return boolean
function XPunishaarGameControl:_DropAction_Buy(dstArea, cb)
    local goods = self._DraggingCardData
    local goodsIndex = self._DraggingSourcePos
    if not goods or not goodsIndex then
        return false
    end

    local area = dstArea == DragArea.FightArea
        and XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea
        or XMVCA.XPunishaar.EnumConst.CardAreaType.Bag

    local overrideCardDetail
    if self:GetControl():IsSubCard(goods.CardId) then
        -- 副卡：精确落点反查宿主主卡并校验（Mount vs Replace 由策略按 hostCard.SubCardId 区分）
        local hostCard = self._FocusPos and self:GetMasterCardByAreaPos(area, self._FocusPos)
        if not self:CanMountSubCardOnMaster(goods.CardId, hostCard) then
            -- 空位 / 非主卡 / 类型不匹配：拒止，不发请求，表现归位
            XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("BuySubCardWithInvalidTarget"))
            if cb then cb(false) end
            return true
        end
        overrideCardDetail = { StartPos = 0, SubCardId = 0, MasterCardId = hostCard.Id }
    elseif self._FocusPos then
        -- 主卡 + 有精确落点 → 直接使用玩家指定的槽位
        overrideCardDetail = { AreaType = area, StartPos = self._FocusPos, SubCardId = 0, MasterCardId = 0 }
    end

    -- 构造 Buy ctx（source="Drag"，#72 gold+升级链预判在 _BuildBuyCtx 内）→ 选策略 → execute
    -- 不经 BuyGoods（Click 入口），使 ctx.source 正确反映 Drag，供 BuySubCardReplace 区分是否二次确认
    local ctx = self:_BuildBuyCtx(goodsIndex, "Drag", overrideCardDetail, cb)
    if not ctx then
        return true  -- _BuildBuyCtx 已 cb(false)（商品/金币失败）
    end
    local strat = self:_SelectArrangeStrategy(ctx)
    if not strat then
        -- 购买域无策略可处理（满区 / 落点锁定/越界）
        self:_RejectBuyFail(ctx, cb)
        return true
    end
    strat.execute(self, ctx, cb)
    return true
end

--- 移动/换位：对战区↔背包、区域内换位。构造 ArrangeCtx → 选策略（Insert 优先 / 满区回落 Swap）→ execute。
--- 满区互换（S5）由 Swap 策略解决（编排域独有，购买域不 fallback）；无策略可处理走 _ArrangeRejectTip 3 文案区分兜底。
---@param dstArea number
---@param cb function
---@return boolean
function XPunishaarGameControl:_DropAction_Move(dstArea, cb)
    local card = self._DraggingCardData
    if not card or not card.Id or not self._FocusPos then
        return false
    end
    local targetArea = dstArea == DragArea.FightArea
        and XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea
        or XMVCA.XPunishaar.EnumConst.CardAreaType.Bag
    -- 构造 ArrangeCtx（#72 标量化+单次构造）→ 选策略 → execute
    -- direction（§7 方向选侧 Q4 路径B）：同区按 dropPos vs D.StartPos 推方向（右拖1/左拖-1）；
    -- 跨区 srcArea~=targetArea 强制 1 右优先（D 精确落 dropPos，跨区无方向语义不应左推偏离 frontSum+1 #M1）。
    -- 透传给策略（CompactedPush 选侧 / Insert 经 InsertCard 传 _RepackInsert 选 try 顺序）。
    local srcArea = card.AreaType
    local direction = (srcArea ~= targetArea) and 1 or (self._FocusPos >= card.StartPos and 1 or -1)
    local ctx = {
        domain = self.ArrangeDomain.Arrange,
        source = "Drag",
        dragCardId = card.Id,
        hasDropPos = true,
        dropPos = self._FocusPos,
        targetArea = targetArea,
        isSubCard = false,
        isSell = false,
        direction = direction,
    }
    local strat = self:_SelectArrangeStrategy(ctx)
    if not strat then
        -- 编排域无策略可处理（锁定槽 / 越界 / 真·满区且 Swap 不可行）
        self:_ArrangeRejectTip(ctx, cb)
        return true
    end
    strat.execute(self, ctx, cb)
    return true
end

--- 卖出：对战区/背包 → 商店卖出区。构造 ArrangeCtx(Sell 域) → 选 Sell 策略 → execute 调 SellCard（主卡含副卡一并卖出）#50。
---@param cb function
---@return boolean
function XPunishaarGameControl:_DropAction_Sell(cb)
    local masterCard = self._DraggingCardData
    if not masterCard or not masterCard.Id then
        if cb then cb(false) end
        return false
    end
    local ctx = {
        domain = self.ArrangeDomain.Sell,
        source = "Drag",
        dragCardId = masterCard.Id,
        hasDropPos = false,
        isSubCard = false,
        isSell = true,
    }
    local strat = self:_SelectArrangeStrategy(ctx)
    if not strat then
        if cb then cb(false) end
        return false
    end
    strat.execute(self, ctx, cb)
    return true
end

--endregion

--region 栏级反算栏容器注册 ----------------------------------------------------
-- 栏容器（对战区/背包栏）OnEnable 注册 / OnDisable 注销自身为栏级落点反算提供方；
-- XUiCardDragHandler.OnDragging 遍历注册栏做落点反算（栏内相对法+跨栏绝对法 §3.6 #批次2）。
-- 注入式：handler 经 GameControl 取栏列表，不直读 host.Parent（向上铁律）。

--- 注册一个栏级落点反算提供方（栏容器 OnEnable 调）。
---@param bar table 栏容器实例（实现 GetDragArea/GetSlotByIndex/GetSlotListCount/GetDragSlotWidth）
function XPunishaarGameControl:RegisterDragFocusBar(bar)
    if not bar then
        return
    end
    if not self._DragFocusBars then
        self._DragFocusBars = {}
    end
    -- 幂等：已注册不重复加
    for i = 1, #self._DragFocusBars do
        if self._DragFocusBars[i] == bar then
            return
        end
    end
    self._DragFocusBars[#self._DragFocusBars + 1] = bar
end

--- 注销栏级落点反算提供方（栏容器 OnDisable 调）。
---@param bar table
function XPunishaarGameControl:UnregisterDragFocusBar(bar)
    if not self._DragFocusBars then
        return
    end
    for i = #self._DragFocusBars, 1, -1 do
        if self._DragFocusBars[i] == bar then
            table.remove(self._DragFocusBars, i)
        end
    end
end

--- 取已注册的栏级落点反算提供方列表（handler OnDragging 遍历用；未注册返回 nil）。
---@return table|nil
function XPunishaarGameControl:GetDragFocusBars()
    return self._DragFocusBars
end

--endregion

return XPunishaarGameControl
