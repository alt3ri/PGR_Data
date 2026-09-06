--- Control部分类（Shop partial，#72 编排策略链/找位算法/InsertCard/MoveCard 抽离至 Arrange partial）。
--- 此处留 Shop 特有：商店操作（购买提交/卖出/丢弃/冻结/刷新）+ 商店商品升级判断（UI 查询）+ 副卡选宿主子流程（PickingHost）。
--- 编排策略链 _ArrangeStrategies（在 Arrange partial）的 execute 经 self 调本 partial 的 _DoBuyGoodsFinal/SellCard（跨 partial 同类，无 self._Control 跳转）。
--- 委托 NetworkAgency:Do* + Model 同步 + 派发 ShopEventId.BuySuccess 刷新商品/装备栏。
--- 被 UI（商品卡/装备栏/Tips 按钮）+ 拖拽中枢（_DropAction_*）调用。

local XPunishaarGameControl = XClassPartial('XPunishaarGameControl')

-- 商店相关表现层事件（grid/panel 派发与订阅，与局内 FightControl.EventIds 分开）
XPunishaarGameControl.ShopEventId = {
    BuySuccess = "PunishaarShopBuySuccess", -- 购买成功：由 BuyGoods 在服务端确认后派发
    PickHostChange = "PunishaarShopPickHostChange", -- 副卡选宿主子流程态变更（进入/退出 PickingHost）#69
    LevelupAnimPlay = "PunishaarShopLevelupAnimPlay", -- 升级动画播放：BuySuccess 刷新后派发，grid 订阅检查缓存匹配+清+播 #升级动画
    RefreshShopSuccess = "PunishaarShopRefreshSuccess", -- 刷新商店成功（服务端下发新商品）：FightMain 订阅播 ReShow 根动画 #商店刷新动效
    RefreshShopFail = "PunishaarShopRefreshFail", -- 刷新商店链路失败（服务端Code失败/网络异常）：FightMain 订阅播 ReShowFail 根动画 #商店刷新动效
    ShopPanelAnimEnable = "PunishaarShopPanelAnimEnable", -- 商店栏展开动效（切态进入/BtnExpand/互斥还原）：FightMain 订阅播 PanelShopAnimEnable 根动画 #商店栏动效
    ShopPanelAnimDisable = "PunishaarShopPanelAnimDisable", -- 商店栏收起动效（BtnFoldUp/背包展开前/PickHost进入）：FightMain 订阅播 PanelShopDisable 根动画 #商店栏动效
}

--- 刷新商店商品并更新 Model 节点
---@param cb function(success: boolean)
function XPunishaarGameControl:RefreshShop(cb)
    -- 金币不足前置校验（从 UI 层移入 Control 收口）：链路失败，派发 RefreshShopFail 供 FightMain 播 ReShowFail
    local cost = self:GetControl():GetShopRefreshCost() or 0
    local gold = self:GetControl():GetCurrentGold() or 0
    if gold < cost then
        XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("ShopRefreshNotEnoughCoin"))
        self:DispatchEvent(self.ShopEventId.RefreshShopFail)
        if cb then
            cb(false)
        end
        return
    end
    XMVCA.XPunishaar.NetworkAgency:DoRefreshShop(function(node)
        if not node then
            -- 刷新链路失败（服务端 Code 失败 / 网络异常经 DoRefreshShop 补 cb(nil) 传播）：派发 Fail 供 FightMain 播 ReShowFail
            self:DispatchEvent(self.ShopEventId.RefreshShopFail)
            if cb then
                cb(false)
            end
            return
        end
        self._Model:SetCurrentNode(node)
        -- 刷新成功提示（文本来自 PunishaarClientConfig.ShopRefreshSuccess，配置未填则不弹空框）
        local successTip = self:GetControl():GetShopRefreshSuccessText()
        if not string.IsNilOrEmpty(successTip) then
            XUiManager.TipMsg(successTip)
        end
        -- 派发 RefreshShopSuccess：FightMain 订阅播 ReShow 根动画（商店列表刷新动效）#商店刷新动效
        self:DispatchEvent(self.ShopEventId.RefreshShopSuccess)
        -- 派发 BuySuccess 联动刷新：商品列表变后战斗区卡升级标记(CanOwnedCardUpgradeByShop)+
        -- 背包入口红点(HasBagCardUpgradeableByShop)需重算（与 BuyGoods/SellCard/FreezeGoods 同事件，
        -- 注释 :93 原意；实现漏派发致刷新商品后战斗区/背包入口升级标记不刷 #74）
        self:DispatchEvent(self.ShopEventId.BuySuccess)
        if cb then
            cb(true)
        end
    end)
end

--- BuyGoods 发请求 + 回流统一入口（升级/非升级路径共用，#61 抽取）。
--- 成功后 Model:SetCurrentNode + 购买成功提示 + 派发 ShopEventId.BuySuccess 刷新 UI；
--- 升级合成的 AddedCard/RemovedCardIds 由服务端 NotifyPunishaarMasterCardChange→Model:UpdateMasterCardByNotify 回流统一处理。
---@param goodsIndex number
---@param cardDetail table { AreaType, StartPos, SubCardId, MasterCardId }
---@param cb function(success: boolean)|nil
function XPunishaarGameControl:_DoBuyGoodsFinal(goodsIndex, cardDetail, cb)
    XMVCA.XPunishaar.NetworkAgency:DoBuyGoods(goodsIndex, cardDetail, function(node)
        if not node then
            if cb then
                cb(false)
            end
            return
        end
        self._Model:SetCurrentNode(node)
        -- 客户端预测更新被推开卡位置（CardPosList）：服务端 BuyGoods notify 只含新增/移除卡，
        -- 不含 repack 推开的已有卡位置变化，需客户端据 CardPosList 自更新 Model，否则 UI 显旧位置重叠
        if cardDetail and cardDetail.IsCardsPosChange and cardDetail.CardPosList then
            self._Model:UpdateCardPositions(cardDetail.CardPosList)
        end
        -- 购买成功提示（文本来自 PunishaarClientConfig.ShopBuySuccess，配置未填则不弹空框）
        local successTip = self:GetControl():GetShopBuySuccessText()
        if not string.IsNilOrEmpty(successTip) then
            XUiManager.TipMsg(successTip)
        end
        self:DispatchEvent(self.ShopEventId.BuySuccess)
        -- 升级动画播放：BuySuccess 同步刷新完成后派发（grid 已重建 Open + 新 card），grid 订阅检查缓存匹配+清+播 #升级动画
        self:DispatchEvent(self.ShopEventId.LevelupAnimPlay)
        if cb then
            cb(true)
        end
    end)
end

--- 冻结/解冻商店商品（冻结槽位下次刷新保留）。
--- 包装 DoFreezeGoods + Model 同步 + 派发 BuySuccess 刷新商品列表（冻结图标随之更新）。
--- 仅商品态支持；装备态无 frozen 字段。
---@param goodsIndex number 服务端槽位索引（1-based）
---@param isFreeze boolean true=冻结 false=解冻
---@param cb function(success: boolean)
function XPunishaarGameControl:FreezeGoods(goodsIndex, isFreeze, cb)
    local goods = self:GetControl():GetCurrentShopGoods()
    local item = goods and goods[goodsIndex]
    if not item then
        XLog.Error("[Punishaar] FreezeGoods: 商品不存在，index=" .. tostring(goodsIndex))
        if cb then
            cb(false)
        end
        return
    end
    XMVCA.XPunishaar.NetworkAgency:DoFreezeGoods(goodsIndex, isFreeze, function(node)
        if not node then
            if cb then
                cb(false)
            end
            return
        end
        self._Model:SetCurrentNode(node)
        -- 冻结/解冻成功：刷新商品列表（与 BuyGoods/SellCard/RefreshShop 同事件，冻结图标随之更新）
        self:DispatchEvent(self.ShopEventId.BuySuccess)
        if cb then
            cb(true)
        end
    end)
end

--- 卖出主卡（含镶嵌副卡一并卖出，按 Sell 总和加金币）。
--- 包装 NetworkAgency:DoSellCard，补 Model 移除（DoSellCard 内部 TODO 的本地同步），
--- 成功后派发 ShopEventId.BuySuccess 让装备栏/背包刷新（与 BuyGoods 同事件，刷新逻辑统一）。
---@param masterCardId number 主卡唯一 Id（MasterCard.Id，非 TemplateId）
---@param cb function(success: boolean)
function XPunishaarGameControl:SellCard(masterCardId, cb)
    local stage = self._Model:GetCurrentStage()
    if not stage then
        if cb then
            cb(false)
        end
        return
    end
    XMVCA.XPunishaar.NetworkAgency:DoSellCard(masterCardId, function(node)
        if not node then
            if cb then
                cb(false)
            end
            return
        end
        -- 卖出成功：本地移除该主卡（DoSellCard 内部 TODO 的兜底本地同步）
        self._Model:UpdateMasterCardByNotify(nil, { masterCardId })
        self._Model:SetCurrentNode(node)
        -- 卖出成功提示（文本来自 PunishaarClientConfig.ShopSellSuccess，配置未填则不弹空框）
        local successTip = self:GetControl():GetShopSellSuccessText()
        if not string.IsNilOrEmpty(successTip) then
            XUiManager.TipMsg(successTip)
        end
        -- 刷新装备栏/背包（与 BuyGoods 同事件）
        -- TODO: 若有独立 SellSuccess 事件再补；现复用 BuySuccess 触发统一刷新
        self:DispatchEvent(self.ShopEventId.BuySuccess)
        if cb then
            cb(true)
        end
    end)
end

--- 丢弃卡牌（主卡 or 副卡）。
--- IsMasterCard=true 丢弃主卡本身（含镶嵌副卡一并丢弃）；false 丢弃该主卡携带的副卡。
--- 成功后 Model 本地同步 + 派发 ShopEventId.BuySuccess 刷新 UI（与 BuyGoods/SellCard 同事件统一刷新）。
---@param masterCardId number 主卡唯一 Id（丢弃副卡时亦用此定位其所在主卡）
---@param isMasterCard boolean true=丢弃主卡，false=丢弃副卡
---@param cb function(success: boolean)
function XPunishaarGameControl:DiscardCard(masterCardId, isMasterCard, cb)
    XMVCA.XPunishaar.NetworkAgency:DoDiscardCard(masterCardId, isMasterCard, function(success)
        if not success then
            if cb then
                cb(false)
            end
            return
        end
        -- 本地同步：丢弃主卡→移除；丢弃副卡→清 SubCardId
        if isMasterCard then
            self._Model:UpdateMasterCardByNotify(nil, { masterCardId })
        else
            self._Model:UpdateSubCardByNotify(masterCardId, 0)
        end
        self:DispatchEvent(self.ShopEventId.BuySuccess)
        if cb then
            cb(true)
        end
    end)
end

--- 计算主卡出售金额（主卡 Sell + 副卡 Sell）。
--- 规则：主卡按 Type*100+Size*10+Level 查 CardSale.Sell；若主卡携副卡，副卡按同 key（Level 默认 1）查 Sell 并累加。
---@param masterCard table Server.XPunishaarMasterCard（含 TemplateId/Level/SubCardId）
---@return number 出售金额合计
function XPunishaarGameControl:GetCardSellPrice(masterCard)
    if not masterCard then
        return 0
    end
    local mainCfg = self:GetTablePunishaarCard(masterCard.TemplateId, true)
    if not mainCfg then
        return 0
    end

    local mainSaleKey = mainCfg.Type * 100 + mainCfg.Size * 10 + (masterCard.Level or 1)
    local mainSaleCfg = self:GetTablePunishaarCardSale(mainSaleKey, true)
    local total = (mainSaleCfg and mainSaleCfg.Sell) or 0

    -- 副卡出售价值累加（副卡不能单独售卖，仅捆绑卖出时累计）
    local subCardId = masterCard.SubCardId
    if subCardId and subCardId ~= 0 then
        local subCfg = self:GetTablePunishaarCard(subCardId, true)
        if subCfg then
            -- 副卡无 level（#44），默认 1
            local subSaleKey = subCfg.Type * 100 + subCfg.Size * 10 + 1
            local subSaleCfg = self:GetTablePunishaarCardSale(subSaleKey, true)
            total = total + ((subSaleCfg and subSaleCfg.Sell) or 0)
        end
    end

    return total
end

--region ----------商店商品升级判断（UI 查询）----------
-- 注：升级链预判 HasNextCardLevel / _FindOwnedCardByLevel / GetGoodsUpgradeChain 已迁 Arrange partial（编排策略链用）；
-- 此处留 UI 查询（需求1/2/3），调 self:HasNextCardLevel 跨 partial 同类可达。

--- 【需求1】判断商品栏指定主卡商品能否与玩家持有的某张主卡触发合成升级。
--- 升级规则（2026-07-29 重定，#61 落地）：同 CardId 同 Level 两张 → 有下一级则合成升级只留 1 张（被合成卡消耗）、到顶则允许共存；
--- 不同 Level 同 CardId 共存不互斥（原 Rule2 "高级替代" 已作废）。
--- 纯读判断，无副作用，任意时刻可调（非商店节点 TotalMasterCards 仍可查）。
---@param goods table Server.XPunishaarGoods（主卡商品，含 CardId/Level/IsBought）
---@return boolean 可触发合成升级
function XPunishaarGameControl:CanGoodsUpgradeOwnedCard(goods)
    if not goods or not goods.CardId or goods.CardId == 0 then
        return false
    end
    if goods.IsBought then
        return false
    end  -- 已购商品不可再买，不显可升级（对齐 CanOwnedCardUpgradeByShop:256 跳过 IsBought）
    if not self:GetControl():IsMasterCard(goods.CardId) then
        return false
    end  -- 仅主卡适用升级规则
    local stage = self._Model:GetCurrentStage()
    local cards = stage and stage.TotalMasterCards
    if not cards then
        return false
    end
    local goodsLevel = goods.Level or 0
    for _, owned in pairs(cards) do
        if owned.TemplateId == goods.CardId then
            local ownedLevel = owned.Level or 0
            -- 同级合成（须存在下一级；到顶不可合成，两张共存）
            if ownedLevel == goodsLevel and self:HasNextCardLevel(goods.CardId, goodsLevel) then
                return true
            end
        end
    end
    return false
end

--- 【需求2】判断玩家指定的主卡能否通过购买商店当前商品触发合成升级。
--- 升级规则（#61）：商店有同 CardId 同 Level 未购商品 → 有下一级则合成升级、到顶则共存；不同 Level 不互斥。
--- 仅主卡适用；非商店节点（无商品）返回 false。
---@param masterCard table Server.XPunishaarMasterCard（玩家持有的主卡，含 TemplateId/Level）
---@return boolean 可通过购买商品合成升级
function XPunishaarGameControl:CanOwnedCardUpgradeByShop(masterCard)
    if not masterCard or not masterCard.TemplateId or masterCard.TemplateId == 0 then
        return false
    end
    if not self:GetControl():IsMasterCard(masterCard.TemplateId) then
        return false
    end  -- 仅主卡适用升级规则
    local goodsList = self:GetControl():GetCurrentShopGoods()
    if not goodsList then
        return false
    end
    local cardId = masterCard.TemplateId
    local ownLevel = masterCard.Level or 0
    for _, goods in ipairs(goodsList) do
        -- 跳过已购商品（IsBought=true 已不可再买）
        if goods.CardId == cardId and not goods.IsBought then
            local goodsLevel = goods.Level or 0
            -- 同级合成（须存在下一级；到顶不可合成，共存）
            if goodsLevel == ownLevel and self:HasNextCardLevel(cardId, ownLevel) then
                return true
            end
        end
    end
    return false
end

--- 【需求3】判断玩家背包暂存区是否有任意主卡可通过购买商店当前商品升级（聚合需求2）。
--- 仅遍历 AreaType==Bag 的主卡，任一可升级即返回 true。
---@return boolean
function XPunishaarGameControl:HasBagCardUpgradeableByShop()
    local stage = self._Model:GetCurrentStage()
    local cards = stage and stage.TotalMasterCards
    if not cards then
        return false
    end
    local BagArea = XMVCA.XPunishaar.EnumConst.CardAreaType.Bag
    for _, owned in pairs(cards) do
        if owned.AreaType == BagArea and self:GetControl():IsMasterCard(owned.TemplateId) then
            if self:CanOwnedCardUpgradeByShop(owned) then
                return true
            end
        end
    end
    return false
end

--endregion

--region ----------副卡选宿主子流程（PickingHost）#69----------

--- 进入副卡选宿主子流程：设 ctx + 派发事件让 UI 刷副作用（收商店栏+锁背包+主卡 Disable）+ 打开 NormalPop 承载弹窗(预留)。
--- 本玩法专属详情页购买路径（与拖拽路径有意不同：覆盖不二次确认，见方案 Q2）。
--- Control 只派发事件，UI 订阅自刷；NormalPop 弹窗本体 prefab 后补，现预留打开/关闭流程。
---@param goodsIndex number 商品槽位 index（source=Goods 副卡）
---@param subCardId number 待购入副卡模板 Id
function XPunishaarGameControl:EnterPickHost(goodsIndex, subCardId)
    self._PickingHostCtx = { goodsIndex = goodsIndex, subCardId = subCardId }
    -- NormalPop 承载弹窗（通用：选宿主/奖励位置不足）透明底不挡背包编排 #69
    XLuaUiManager.Open("UiPunishaarSellCardTip", { mode = "PickHost", subCardId = subCardId, goodsIndex = goodsIndex })
    self:DispatchEvent(self.ShopEventId.PickHostChange, true)
end

--- 退出副卡选宿主子流程：清 ctx + 派发事件让 FightMain 还原（展商店栏）+ 关弹窗。
--- 幂等：非 PickingHost 时 no-op。
function XPunishaarGameControl:ExitPickHost()
    if not self._PickingHostCtx then
        return
    end
    self._PickingHostCtx = nil
    XLuaUiManager.Close("UiPunishaarSellCardTip")
    self:DispatchEvent(self.ShopEventId.PickHostChange, false)
end

--- 是否在副卡选宿主子流程中。
function XPunishaarGameControl:IsPickingHost()
    return self._PickingHostCtx ~= nil
end

--- 取待购入副卡模板 Id（PickingHost 期间恒定，就是点购买的那张商品副卡）。
function XPunishaarGameControl:GetPickingSubCardId()
    return self._PickingHostCtx and self._PickingHostCtx.subCardId
end

--- 取待购入商品槽位 index。
function XPunishaarGameControl:GetPickingGoodsIndex()
    return self._PickingHostCtx and self._PickingHostCtx.goodsIndex
end

--endregion

return XPunishaarGameControl
