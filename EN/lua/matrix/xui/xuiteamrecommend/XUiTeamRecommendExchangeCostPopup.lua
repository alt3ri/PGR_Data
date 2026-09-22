local XUiGridTRExchangeCost = require("XUi/XUiTeamRecommend/Grid/XUiGridTRExchangeCost")

---@class XUiTeamRecommendExchangeCostPopup : XLuaUi
local XUiTeamRecommendExchangeCostPopup = XLuaUiManager.Register(XLuaUi, "UiTeamRecommendExchangeCostPopup")

function XUiTeamRecommendExchangeCostPopup:OnAwake()
    self:InitUi()
    self:InitButton()
end

function XUiTeamRecommendExchangeCostPopup:OnStart(recommendCharData, closeCb)
    self.RecommendCharData = recommendCharData
    self.CloseCb = closeCb
    if not self.RecommendCharData then
        self:Close()
        return
    end

    self:RequestShopInfo(function() self:Refresh() end)
end

function XUiTeamRecommendExchangeCostPopup:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiTeamRecommendExchangeCostPopup:InitUi()
    self.RouteGridList = {}
    self.TargetGridList = {}

    self.GridCostIcon.gameObject:SetActiveEx(false)
    self.Grid256.gameObject:SetActiveEx(false)

    self:InitAsset()
end

function XUiTeamRecommendExchangeCostPopup:InitAsset()
    self.AssetPanel = XUiHelper.XUiPanelAsset(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.AssetPanel:Close()
end

function XUiTeamRecommendExchangeCostPopup:InitButton()
    self.BtnCloseMask.CallBack = function() self:Close() end
    self.BtnTanchuangCloseBig.CallBack = function() self:Close() end
    self.BtnExchange.CallBack = function() self:OnBtnExchangeClick() end
end

--- 按目标槽位逐个消耗可穿戴意识，返回实际缺少的意识模板列表
function XUiTeamRecommendExchangeCostPopup:BuildMissingAwarenessTemplateIdList()
    local candidateCountMap = {}
    local missingTemplateIdList = {}
    local awarenessTargetSlotList = self.RecommendCharData.AwarenessSlotList
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local templateId = awarenessTargetSlotList[site].EquipTemplateId
        local candidateCount = candidateCountMap[templateId]
        if candidateCount == nil then
            local candidateEquipIds = XMVCA.XEquip:GetEnableEquipIdsByTemplateId(templateId, self.RecommendCharData.CharacterId)
            candidateCount = #candidateEquipIds
        end

        if candidateCount > 0 then
            candidateCount = candidateCount - 1
        else
            table.insert(missingTemplateIdList, templateId)
        end
        candidateCountMap[templateId] = candidateCount
    end
    return missingTemplateIdList
end

function XUiTeamRecommendExchangeCostPopup:RequestShopInfo(cb)
    local shopIdList = self:BuildNeedRequestShopIdList()
    local index = 1

    local function requestNext()
        local shopId = shopIdList[index]
        if not shopId then
            cb()
            return
        end

        index = index + 1
        XShopManager.GetShopInfo(shopId, requestNext)
    end

    requestNext()
end

function XUiTeamRecommendExchangeCostPopup:BuildNeedRequestShopIdList()
    local shopIdMap = {}
    local shopIdList = {}
    for _, templateId in ipairs(self:BuildMissingAwarenessTemplateIdList()) do
        local star = XMVCA.XEquip:GetEquipStar(templateId)
        for _, shopId in ipairs(XEnumConst.Shop.AwarenessStarToShopIdList[star] or {}) do
            if not shopIdMap[shopId] then
                shopIdMap[shopId] = true
                table.insert(shopIdList, shopId)
            end
        end
    end
    return shopIdList
end

function XUiTeamRecommendExchangeCostPopup:Refresh()
    if self:IsAllAwarenessCandidateReady() then
        self:Close()
        return
    end

    self:RefreshRouteList()
    self:RefreshConsumeList()
    self:RefreshAsset()
    self:RefreshShopName()
    self:RefreshTargetAwarenessList()
end

function XUiTeamRecommendExchangeCostPopup:RefreshRouteList()
    self.RouteList = self:BuildRouteList()

    local selectedIndex = 1
    for index, route in ipairs(self.RouteList) do
        if route.ShopId == self.SelectedShopId then
            selectedIndex = index
            break
        end
    end

    self.SelectedRouteIndex = selectedIndex
    self.SelectedShopId = self.RouteList[selectedIndex] and self.RouteList[selectedIndex].ShopId or nil
end

function XUiTeamRecommendExchangeCostPopup:BuildRouteList()
    local routeList = {}
    local routeMap = {}
    for _, templateId in ipairs(self:BuildMissingAwarenessTemplateIdList()) do
        local exchangeInfo = XDataCenter.ItemManager.GetItemAutoExchangeInfo(templateId)
        if exchangeInfo then
            for index, shopId in ipairs(exchangeInfo.ShopIdList) do
                local consume = exchangeInfo.ConsumeList[index][1]
                local route = routeMap[shopId]
                if not route then
                    route = {
                        ShopId = shopId,
                        ConsumeId = consume.ConsumeId,
                        UnitConsumeCount = consume.ConsumeCount,
                        ConsumeCount = 0,
                        GoodsList = {},
                    }
                    routeMap[shopId] = route
                    table.insert(routeList, route)
                elseif route.ConsumeId ~= consume.ConsumeId or route.UnitConsumeCount ~= consume.ConsumeCount then
                    XLog.Error(string.format("XUiTeamRecommendExchangeCostPopup.BuildRouteList error: shopId=%s 的意识商品消耗配置不一致", tostring(shopId)))
                end

                route.ConsumeCount = route.ConsumeCount + consume.ConsumeCount
                table.insert(route.GoodsList, {
                    TemplateId = templateId,
                    GoodsId = exchangeInfo.GoodsIdList[index],
                    ConsumeCount = consume.ConsumeCount,
                })
            end
        end
    end
    return routeList
end

function XUiTeamRecommendExchangeCostPopup:RefreshConsumeList()
    local routeList = self.RouteList
    self.PanelConsumeListEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(routeList))

    for _, grid in ipairs(self.RouteGridList) do
        grid:Close()
    end

    for index, route in ipairs(routeList) do
        local grid = self.RouteGridList[index]
        if not grid then
            local go = index == 1 and self.GridCostIcon or XUiHelper.Instantiate(self.GridCostIcon.gameObject, self.GridCostIcon.transform.parent)
            grid = XUiGridTRExchangeCost.New(go, self)
            self.RouteGridList[index] = grid
        end
        grid:Open()
        grid:Refresh(route, index, self.SelectedRouteIndex)
    end
end

function XUiTeamRecommendExchangeCostPopup:RefreshAsset()
    local route = self:GetSelectedRoute()
    if not route then
        self.AssetPanel:Close()
        return
    end

    self.AssetPanel:Open()
    self.AssetPanel:RefreshBindItem(route.ConsumeId)
end

function XUiTeamRecommendExchangeCostPopup:RefreshShopName()
    local route = self:GetSelectedRoute()
    self.TxtShop.text = route and XItemConfigs.GetAutoExchangeTokenShopName(route.ConsumeId) or ""
end

local AwarenessConsumeInsufficientCountColor = XUiHelper.Hexcolor2Color("E6292EFF")
local AwarenessNormalCountColor = XUiHelper.Hexcolor2Color("000000FF")

function XUiTeamRecommendExchangeCostPopup:RefreshTargetAwarenessList()
    local goodsStateQueueMap = {}
    for _, goodsState in ipairs(self:BuildSelectedRouteGoodsStateList()) do
        local templateId = goodsState.Goods.TemplateId
        goodsStateQueueMap[templateId] = goodsStateQueueMap[templateId] or {}
        table.insert(goodsStateQueueMap[templateId], goodsState)
    end

    local gridIndex = 0
    for _, templateId in ipairs(self:BuildMissingAwarenessTemplateIdList()) do
        gridIndex = gridIndex + 1
        local grid = self:GetTargetGrid(gridIndex)
        local goodsStateQueue = goodsStateQueueMap[templateId]
        local goodsState = goodsStateQueue and table.remove(goodsStateQueue, 1) or nil
        local isConsumeEnough = goodsState and goodsState.IsConsumeEnough or false
        grid:Refresh({ TemplateId = templateId, Count = 1 })
        grid:SetReceived(not isConsumeEnough)
        grid:SetPanelTag(isConsumeEnough)
        grid:SetCountColor(isConsumeEnough and AwarenessNormalCountColor or AwarenessConsumeInsufficientCountColor)
    end

    for index = gridIndex + 1, #self.TargetGridList do
        self.TargetGridList[index].GameObject:SetActiveEx(false)
    end
end

function XUiTeamRecommendExchangeCostPopup:GetTargetGrid(site)
    local grid = self.TargetGridList[site]
    if grid then
        grid.GameObject:SetActiveEx(true)
        return grid
    end

    local go = site == 1 and self.Grid256 or XUiHelper.Instantiate(self.Grid256.gameObject, self.Grid256.transform.parent)
    grid = XUiHelper.XUiGridCommon(self, go)
    self.TargetGridList[site] = grid
    grid.GameObject:SetActiveEx(true)
    return grid
end

function XUiTeamRecommendExchangeCostPopup:IsAllAwarenessCandidateReady()
    return XTool.IsTableEmpty(self:BuildMissingAwarenessTemplateIdList())
end

function XUiTeamRecommendExchangeCostPopup:GetSelectedRoute()
    return self.RouteList and self.RouteList[self.SelectedRouteIndex] or nil
end

function XUiTeamRecommendExchangeCostPopup:OnSelectRoute(index)
    if self.SelectedRouteIndex == index then
        return
    end

    self.SelectedRouteIndex = index
    self.SelectedShopId = self.RouteList[index].ShopId
    self:RefreshConsumeList()
    self:RefreshAsset()
    self:RefreshShopName()
    self:RefreshTargetAwarenessList()
end

function XUiTeamRecommendExchangeCostPopup:OnBtnExchangeClick()
    if self.IsBuying then
        return
    end

    local buyList = self:BuildBuyList()
    if XTool.IsTableEmpty(buyList) then
        XUiManager.TipText("BuyNeedItemInsufficient")
        return
    end

    self:BuyNextGoods(buyList, 1)
end

function XUiTeamRecommendExchangeCostPopup:BuildBuyList()
    local buyList = {}
    for _, goodsState in ipairs(self:BuildSelectedRouteGoodsStateList()) do
        if goodsState.IsConsumeEnough then
            table.insert(buyList, {
                ShopId = goodsState.ShopId,
                GoodsId = goodsState.Goods.GoodsId,
            })
        end
    end
    return buyList
end

function XUiTeamRecommendExchangeCostPopup:BuildSelectedRouteGoodsStateList()
    local route = self:GetSelectedRoute()
    local goodsStateList = {}
    if not route then
        return goodsStateList
    end

    local ownConsumeCount = XDataCenter.ItemManager.GetCount(route.ConsumeId)
    for _, goods in ipairs(route.GoodsList) do
        local isConsumeEnough = ownConsumeCount >= goods.ConsumeCount
        table.insert(goodsStateList, {
            Goods = goods,
            ShopId = route.ShopId,
            IsConsumeEnough = isConsumeEnough,
        })
        if isConsumeEnough then
            ownConsumeCount = ownConsumeCount - goods.ConsumeCount
        end
    end
    return goodsStateList
end

function XUiTeamRecommendExchangeCostPopup:BuyNextGoods(buyList, index)
    local buyData = buyList[index]
    if not buyData then
        self.IsBuying = false
        XUiManager.TipText("BuySuccess")
        self:Refresh()
        return
    end

    self.IsBuying = true
    XShopManager.BuyShop(buyData.ShopId, buyData.GoodsId, 1, function()
        self:BuyNextGoods(buyList, index + 1)
    end, function()
        self.IsBuying = false
        self:Refresh()
    end)

end
