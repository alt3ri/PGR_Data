--- 主卡详情内容子面板（普通 XUiNode，由 TipsRoot 气泡壳加载并定位；不继承 bubble、不带 BtnClose）。
--- 展示单张主卡的描述/标签/副卡槽，并按所处上下文显示操作按钮组。
--- PanelBuy/PanelSell/PanelDiscard 互斥（同一时刻只显示一个），由 OperationMode 驱动 SetActiveEx 切换。主卡保留环节显 Discard（gc:IsRewardPlacementActive），其余场景无 Discard。
local XUiPanelPunishaarMainCard = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarMainCardTips/XUiPanelPunishaarMainCard")
local XUiPanelPunishaarCardTag = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarMainCardTips/XUiPanelPunishaarCardTag")
local XUiPanelPunishaarSubCardSlot = require("XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarMainCardTips/XUiPanelPunishaarSubCardSlot")

---@class XUiPunishaarMainCardTips: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field PanelTop @主卡内容根节点（承载 XUiPanelPunishaarMainCard：ImgHead/GroupStar/TxtDamageNum/TxtCDNum）
---@field PanelSubCardSlot @副卡槽位根节点（固定 1 个副卡槽，挂 XUiPanelPunishaarSubCardSlot，不克隆列表）
---@field PanelBuy @购买操作区根节点（内含 BtnBuy，与 PanelSell 互斥）
---@field PanelSell @出售操作区根节点（内含 BtnSell + TxtSellPrice，与 PanelBuy 互斥）
---@field PanelCardTag @卡牌类型/尺寸标签根节点（容器，直接挂 XUiPanelPunishaarCardTag；IconTag/TxtType/TxtSlotSize 为其子节点）
---@field CardTag @兼容保留（旧字段，不再用于创建 CardTagPanel #44）
---@field TxtDesc UnityEngine.UI.Text 卡牌描述（对应 PunishaarCard.Desc）
---@field BtnLock XUiComponent.XUiButton 冻结/解冻按钮（商品冻结态切换；装备态不显示）
---@field BtnBuy XUiComponent.XUiButton 购买按钮
---@field BtnSell XUiComponent.XUiButton 出售按钮
---@field BtnDiscard XUiComponent.XUiButton 丢弃按钮（主卡保留环节腾位路径，gc:IsRewardPlacementActive 时显；非商店不售出走丢弃）#主卡Discard
---@field PanelDiscard UnityEngine.RectTransform 丢弃操作区根节点（内含 BtnDiscard；prefab 有则显，无则 BtnDiscard 直显）#主卡Discard
---@field DetailRootLeft UnityEngine.RectTransform 副卡详情气泡左侧锚点（主卡偏右时副卡在左，pivot.x=1 从右边沿展开）
---@field DetailRootRight UnityEngine.RectTransform 副卡详情气泡右侧锚点（主卡偏左/默认时副卡在右，pivot.x=0 从左边沿展开）
local XUiPunishaarMainCardTips = XClass(XUiNode, "XUiPunishaarMainCardTips")

--- 详情数据来源（detail.source）
local TipsSource = {
    Goods = 1, -- 商店待售商品（显示购买按钮）
    Equipped = 2, -- 对战区已装备主卡（显示出售按钮）
}

--- 互斥操作按钮组模式（主卡保留环节显 Discard；商店显 Buy/Sell；PreFight/只读显 None）
local OperationMode = {
    None = 0,
    Buy = 1,
    Sell = 2,
    Discard = 3,  -- 主卡丢弃（主卡保留环节腾位，gc:IsRewardPlacementActive 时显；非商店不售出走丢弃）#主卡Discard
}

function XUiPunishaarMainCardTips:OnStart()
    -- 主卡内容子面板：prefab 须提供 PanelMainCard 节点承载 ImgHead/GroupStar 等字段
    if self.PanelTop then
        self.MainCardPanel = XUiPanelPunishaarMainCard.New(self.PanelTop, self)
        self.MainCardPanel:Open()
    else
        XLog.Warning("[Punishaar] XUiPunishaarMainCardTips: PanelTop 节点缺失，主卡内容无法显示")
    end

    -- 类型/尺寸标签（单实例）：用 PanelCardTag 作挂载节点（prefab 直接在其下放 IconTag/TxtType/TxtSlotSize #44）
    if self.PanelCardTag then
        self.CardTagPanel = XUiPanelPunishaarCardTag.New(self.PanelCardTag, self)
        self.CardTagPanel:Open()
    end

    -- 副卡槽（固定 1 个，不克隆）
    if self.PanelSubCardSlot then
        self.SubCardSlot = XUiPanelPunishaarSubCardSlot.New(self.PanelSubCardSlot, self)
        self.SubCardSlot:Open()
    end

    if self.BtnLock then
        self.BtnLock:AddEventListener(handler(self, self._OnBtnLock))
    end
    if self.BtnBuy then
        self.BtnBuy:AddEventListener(handler(self, self._OnBtnBuy))
    end
    if self.BtnSell then
        self.BtnSell:AddEventListener(handler(self, self._OnBtnSell))
    end
    if self.BtnDiscard then
        self.BtnDiscard:AddEventListener(handler(self, self._OnBtnDiscard))
    end

    self._IsLocked = false
    self._IsOperating = false
    self:SetOperationMode(OperationMode.None)
end

--- 刷新主卡详情。
---@param detail table|nil 详情契约：{ source=TipsSource, cardId, level, goodsIndex?(source=1), masterCard?(source=2), operationMode?(覆盖) }
function XUiPunishaarMainCardTips:Refresh(detail)
    self._Detail = detail
    if not detail or not detail.cardId or detail.cardId == 0 then
        return
    end

    local cardCfg = self._Control:GetTablePunishaarCard(detail.cardId)

    if self.MainCardPanel then
        self.MainCardPanel:Refresh(detail)
    end
    if self.CardTagPanel then
        self.CardTagPanel:Open()
        self.CardTagPanel:Refresh(cardCfg)
    end
    if self.SubCardSlot then
        -- 有副卡才显示副卡节点并刷新；无副卡（含商品态 source=1 无 masterCard / 装备态 SubCardId==0）整节点隐藏。
        -- 用 Open/Close 而非 SetActiveEx：Close 置 _IsNodeShow=false，防框架 EnableChildNodes 在 MainCardTips 重显时自动重激活空副卡节点。
        local hasSubCard = detail.masterCard and detail.masterCard.SubCardId and detail.masterCard.SubCardId ~= 0
        if hasSubCard then
            self.SubCardSlot:Open()
            self.SubCardSlot:Refresh(detail.masterCard)
        else
            self.SubCardSlot:Close()
        end
    end
    if self.TxtDesc then
        -- 描述文本走 PunishaarCard.Desc，DescParams 占位符替换经 GetCardDesc 统一处理
        self.TxtDesc.text = self._Control:GetCardDesc(detail.cardId)
    end

    --[[
    原冻结状态读取（屏蔽期不执行，恢复时取消注释 #CEFreeze）
    -- BtnLock 状态读服务端 Goods.Frozen（source=1 商品冻结态；source=2 装备态无 frozen → 未冻结）
    self._IsLocked = detail.frozen == true
    --]]
    self:_RefreshLockBtn()  -- 冻结功能屏蔽：恒隐 BtnLock（#CEFreeze）
    self:SetOperationMode(self:_ResolveOperationMode(detail))

    -- 价格显示走 SetNameByGroup(1, ...)（约定：XUiButton group 1 = 价格文本）
    if detail.source == TipsSource.Goods and cardCfg then
        -- 购买价 = CardSale.Buy
        local saleKey = cardCfg.Type * 100 + cardCfg.Size * 10 + (detail.level or 1)
        local saleCfg = self._Control.GameControl:GetTablePunishaarCardSale(saleKey, true)
        local buyPrice = saleCfg and saleCfg.Buy or 0
        if self.BtnBuy then
            self.BtnBuy:SetNameByGroup(1, tostring(buyPrice))
            -- 金币不足时购买按钮 Disable #46
            local gold = self._Control:GetCurrentGold() or 0
            self.BtnBuy:SetDisable(gold < buyPrice)
        end
    elseif detail.source == TipsSource.Equipped and detail.masterCard then
        -- 出售价 = 主卡 Sell + 副卡 Sell
        if self.BtnSell then
            self.BtnSell:SetNameByGroup(1, tostring(self._Control.GameControl:GetCardSellPrice(detail.masterCard)))
        end
    end
end

function XUiPunishaarMainCardTips:RefreshCollection(detail)
    self._Detail = detail

    if not detail or not detail.cardId or detail.cardId == 0 then
        return
    end

    local collectionLocked = detail.collectionLocked == true

    self.PanelTop_Collectionlock.gameObject:SetActiveEx(
            collectionLocked
    )

    if self.CardTagPanel then
        self.CardTagPanel:Close()
    end

    if self.SubCardSlot then
        self.SubCardSlot:Close()
    end

    if self.BtnLock then
        self.BtnLock.gameObject:SetActiveEx(false)
    end

    self:SetOperationMode(OperationMode.None)

    if collectionLocked then
        if self.MainCardPanel then
            self.MainCardPanel:Close()
        end

        if self.TxtDesc then
            self.TxtDesc.gameObject:SetActiveEx(true)
            local desc = self._Control:GetCollectionLockDesc() or ""
            self.TxtDesc.text = XUiHelper.ReplaceTextNewLine(desc)
        end

        return
    end

    local cardCfg = self._Control:GetTablePunishaarCard(
            detail.cardId,
            true
    )

    if self.MainCardPanel then
        self.MainCardPanel:Open()

        if detail.collectionSubCard == true then
            self.MainCardPanel:RefreshCollectionSubCard(
                    detail.cardId
            )
        else
            detail.collectionMode = true
            self.MainCardPanel:SetCollectionSubCardMode(false, cardCfg)
            self.MainCardPanel:Refresh(detail)
        end
    end

    if self.TxtDesc then
        self.TxtDesc.gameObject:SetActiveEx(true)
        -- 描述文本走 PunishaarCard.Desc，DescParams 占位符替换经 GetCardDesc 统一处理
        self.TxtDesc.text = self._Control:GetCardDesc(detail.cardId)
    end
end

--- 由 detail 解析应显示的操作模式：detail.operationMode 优先；否则按 source 默认。
---@param detail table
---@return number
function XUiPunishaarMainCardTips:_ResolveOperationMode(detail)
    if not detail then
        return OperationMode.None
    end
    -- 只读（如结算界面复盘）：不出买卖按钮
    if detail.readOnly then
        return OperationMode.None
    end
    -- 战前准备阶段不允许卖出（PreFight 无商品，Buy 不会显；仅压 Sell）
    local fightState = self._Control.GameControl
            and self._Control.GameControl.RunControl
            and self._Control.GameControl.RunControl:GetCurrentFightState()
    if fightState == XMVCA.XPunishaar.EnumConst.FightState.PreFight then
        return OperationMode.None
    end
    if detail.operationMode then
        return detail.operationMode
    end
    if detail.source == TipsSource.Goods then
        -- 已购商品只读（无 Buy 按钮）
        return detail.isBought and OperationMode.None or OperationMode.Buy
    elseif detail.source == TipsSource.Equipped then
        -- 主卡保留环节（reward-placement）：主卡走丢弃路径（非商店不售出）；其余场景售出 #主卡Discard
        local gc = self._Control and self._Control.GameControl
        if gc and gc.IsRewardPlacementActive and gc:IsRewardPlacementActive() then
            return OperationMode.Discard
        end
        return OperationMode.Sell
    end
    return OperationMode.None
end

--- 切换互斥操作按钮组：仅匹配 mode 的那个 Panel 显示。
---@param mode number
function XUiPunishaarMainCardTips:SetOperationMode(mode)
    self._OperationMode = mode
    if self.PanelBuy then
        self.PanelBuy.gameObject:SetActiveEx(mode == OperationMode.Buy)
    end
    if self.PanelSell then
        self.PanelSell.gameObject:SetActiveEx(mode == OperationMode.Sell)
    end
    -- Discard 模式：显 PanelDiscard（prefab 有则显容器）；无 PanelDiscard 容器则直显 BtnDiscard #主卡Discard
    if self.PanelDiscard then
        self.PanelDiscard.gameObject:SetActiveEx(mode == OperationMode.Discard)
    elseif self.BtnDiscard then
        self.BtnDiscard.gameObject:SetActiveEx(mode == OperationMode.Discard)
    end
end

function XUiPunishaarMainCardTips:_OnBtnBuy()
    if self._IsOperating then
        return
    end
    local detail = self._Detail
    if not detail or detail.goodsIndex == nil then
        return
    end
    if detail.isBought then
        return
    end  -- 已购商品不可重复购买
    -- 金币先验：不足弹 tips 不发请求 #46
    local cardCfg = self._Control:GetTablePunishaarCard(detail.cardId)
    if cardCfg then
        local saleKey = cardCfg.Type * 100 + cardCfg.Size * 10 + (detail.level or 1)
        local saleCfg = self._Control.GameControl:GetTablePunishaarCardSale(saleKey, true)
        local price = saleCfg and saleCfg.Buy or 0
        local gold = self._Control:GetCurrentGold() or 0
        if gold < price then
            XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("PunishaarShopBuyGoldNotEnough"))
            return
        end
    end
    self._IsOperating = true
    self._Control.GameControl:BuyGoods(detail.goodsIndex, function(success)
        self._IsOperating = false
        if success and self.Parent then
            self.Parent:Hide()
        end
    end)
end

function XUiPunishaarMainCardTips:_OnBtnSell()
    if self._IsOperating then
        return
    end
    local detail = self._Detail
    local masterCard = detail and detail.masterCard
    if not masterCard then
        return
    end
    self._IsOperating = true
    self._Control.GameControl:SellCard(masterCard.Id, function(success)
        self._IsOperating = false
        if success and self.Parent then
            self.Parent:Hide()
        end
    end)
end

--- 丢弃主卡（主卡保留环节腾位路径，gc:IsRewardPlacementActive 时显此按钮；非商店不售出走丢弃）#主卡Discard
function XUiPunishaarMainCardTips:_OnBtnDiscard()
    if self._IsOperating then
        return
    end
    local detail = self._Detail
    local masterCard = detail and detail.masterCard
    if not masterCard then
        return
    end
    self._IsOperating = true
    -- IsMasterCard=true：丢弃主卡自身（服务端 XPunishaarDiscardCardRequest）；成功关详情，MasterCardChange 触发 SellCardTip 刷背包+TryAutoPlace
    self._Control.GameControl:DiscardCard(masterCard.Id, true, function(success)
        self._IsOperating = false
        XLog.Debug(string.format("[主卡Discard诊断] DiscardCard 响应: masterCard.Id=%s success=%s", tostring(masterCard.Id), tostring(success)))
        if success then
            if self.Parent then
                self.Parent:Hide()
            end
            -- DiscardCard 仅本地 UpdateMasterCardByNotify + BuySuccess，未发 MasterCardChange；
            -- 主卡保留环节 SellCardTip 订阅 MasterCardChange 刷背包+TryAutoPlace，故显式补发触发腾位后自动放入奖励卡 #主卡Discard
            XLog.Debug("[主卡Discard诊断] 补发 MasterCardChange（触发 SellCardTip 刷背包+TryAutoPlace）")
            XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE)
        end
    end)
end

function XUiPunishaarMainCardTips:_OnBtnLock()
    -- 冻结功能屏蔽：入口 guard，不响应点击（即使 BtnLock 误显）#CEFreeze
    --[[
    原冻结切换逻辑（屏蔽期不执行，恢复时取消注释 #CEFreeze）
    if self._IsOperating then return end
    local detail = self._Detail
    -- 仅商品态（source=Goods）支持冻结；装备态无 frozen 字段
    if not detail or detail.goodsIndex == nil or detail.source ~= TipsSource.Goods then
        return
    end
    self._IsOperating = true
    -- 切换冻结态：当前冻结→解冻，未冻结→冻结；成功后 Hide（商品列表经 BuySuccess 已刷新冻结图标）
    self._Control.GameControl:FreezeGoods(detail.goodsIndex, not detail.frozen, function(success)
        self._IsOperating = false
        if success and self.Parent then self.Parent:Hide() end
    end)
    --]]
end

function XUiPunishaarMainCardTips:_RefreshLockBtn()
    if not self.BtnLock then
        return
    end
    -- 冻结功能屏蔽：BtnLock 恒隐（入口屏蔽），冻结态遮罩(ImgFrozen)保留 #CEFreeze
    self.BtnLock.gameObject:SetActiveEx(false)
    --[[
    原冻结按钮文本逻辑（屏蔽期不执行，恢复时取消注释 #CEFreeze）
    -- 文本按冻结态切换：已冻结→"解冻"，未冻结→"冻结"（_IsLocked 在 Refresh 读 detail.frozen）
    local desc = XMVCA.XPunishaar:GetClientStringByKey("BtnFreezeNames", self._IsLocked and 2 or 1)
    self.BtnLock:SetNameByGroup(0, desc)
    --]]
end

function XUiPunishaarMainCardTips:OnDisable()
    -- 防操作锁残留：界面被覆盖中断期间网络回调未返回，复位操作锁
    self._IsOperating = false
end

function XUiPunishaarMainCardTips:OnDestroy()
    self._Detail = nil
end

return XUiPunishaarMainCardTips
