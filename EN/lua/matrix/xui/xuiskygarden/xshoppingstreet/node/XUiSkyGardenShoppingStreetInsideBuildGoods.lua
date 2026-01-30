-- local XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods")
local XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods")
---@class XUiSkyGardenShoppingStreetInsideBuildGoods : XUiNode
local XUiSkyGardenShoppingStreetInsideBuildGoods = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildGoods")

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnStart()
    self._GoodSort = {}
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnEnable()
    self._GoodsList = {}
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnDisable()
    XTool.UpdateDynamicItem(self._GoodsList, nil, self.GridSmallGoods, XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods, self)
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:Reset()
    local resetData = self._Control:GetResetData(XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType.Grocery)
    self:_UpdateByData(resetData)
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:HasResetTips()
    local resetData = self._Control:GetResetData(XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType.Grocery)
    local list = {}
    if resetData then
        local t = resetData.ShelfDatas or {}
        for _, v in pairs(t) do
            list[v.GoodsId] = v.GoldCount or 0
        end
    end
    local count = 0
    for _, v in pairs(self._TempGoods) do
        if v.id then
            if not list[v.id] or list[v.id] ~= v.num then
                return false
            end
            count = count + 1
        end
    end
    if table.nums(list) ~= count then
        return false
    end
    return true
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:TempCheckInfo()
    self._tempCache = {}
    for i = 1, #self._TempGoods do
        local goodsData = self._TempGoods[i]
        if goodsData.id then
            self._tempCache[goodsData.id] = goodsData.num
        end
    end
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:HasSaveTips()
    for _, v in pairs(self._TempGoods) do
        if v.id and (not self._tempCache[v.id] or self._tempCache[v.id] ~= v.num) then
            return true
        end
    end
    return false
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:_UpdateByData(groceryData)
    local shelfDatas
    if groceryData then
        shelfDatas = groceryData.ShelfDatas
    else
        shelfDatas = {}
    end

    self._TempGoods = {}
    self._SelectGoodsId = {}
    -- self._SelectGoodsDetailId = {}
    for i = 1, self._GoodsCfg.ShelfNum do
        if not self._TempGoods[i] then
            local goodsData = shelfDatas[i]
            if goodsData then
                self._TempGoods[i] = {
                    id = goodsData.GoodsId,
                    num = goodsData.GoldCount,
                }
            else
                self._TempGoods[i] = {}
            end
        end
    end

    for _, v in ipairs(self._TempGoods) do
        if v.id then
            self._SelectGoodsId[v.id] = true
            table.insert(self._GoodSort, v.id)
        end
    end

    XTool.UpdateDynamicItem(self._GoodsList, self._GoodsCfg.Goods, self.GridSmallGoods, XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods, self)
    -- XTool.UpdateDynamicItem(self._SelectGoodsDetailId, self._TempGoods, self.GirdGoods, XUiSkyGardenShoppingStreetInsideBuildGoodsGirdGoods, self)

    self:UpdateShopModel()
    self:TempCheckInfo()
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:SetBuilding(pos, isInside)
    self._BuildPos = pos
    self._IsInside = isInside
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local buildingId = shopAreaData:GetShopId()
    self._GoodsCfg = self._Control:GetShopGroceryConfigsByShopId(buildingId)
    self:_UpdateByData(shopAreaData:GetGroceryData())
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnBtnSaveClick(isForce)
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local shopId = shopAreaData:GetShopId()
    local list = {}
    for i = 1, #self._TempGoods do
        local goodsData = self._TempGoods[i]
        if goodsData.id then
            list[i] = {
                GoodsId = goodsData.id,
                GoldCount = goodsData.num,
            }
        else
            list[i] = {}
        end
    end
    self._Control:SgStreetShopSetupGroceryRequest(shopId, list)
    self:TempCheckInfo()
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:IsSelectGoodId(goodId)
    return self._SelectGoodsId[goodId]
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:GetTempData(goodId)
    for _, v in pairs(self._TempGoods) do
        if v.id == goodId then return v end
    end
    -- local goodCfg = self._Control:GetShopGroceryGoodsConfigsByGoodId(goodId)
    -- local v = {
    --     id = goodId,
    --     num = goodCfg.GoldInit,
    -- }
    -- table.insert(self._TempGoods, v)
    -- return v
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnGoodsClick(index)
    local clickGoodId = self._TempGoods[index].id
    self._TempGoods[index].id = nil
    -- self._SelectGoodsDetailId[index]:Update(self._TempGoods[index])

    for index, goodId in pairs(self._GoodsCfg.Goods) do
        if goodId == clickGoodId then
            self._SelectGoodsId[goodId] = nil
            self._GoodsList[index]:SetSelect(false)
            break
        end
    end
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:OnGridSmallGoodsClick(index, goodId)
    local cnt = 0
    for _, hasGood in pairs(self._SelectGoodsId) do
        if hasGood then
            cnt = cnt + 1 
        end
    end
    if not self._SelectGoodsId[goodId] and cnt >= self._GoodsCfg.ShelfNum then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_ShopSelectGoodFull"))
        return
    end
    self._SelectGoodsId[goodId] = not self._SelectGoodsId[goodId]
    self._GoodsList[index]:SetSelect(self._SelectGoodsId[goodId])
    if self._SelectGoodsId[goodId] then
        self.XAudioObjectPlayer:PlayByKeyName("Select")
    else
        self.XAudioObjectPlayer:PlayByKeyName("Unselect")
    end

    if self._SelectGoodsId[goodId] then
        for i = 1, 3 do
            if not self._GoodSort[i] or self._GoodSort[i] == 0 then
                self._GoodSort[i] = goodId
                break
            end
        end
    else
        for i, v in pairs(self._GoodSort) do
            if v == goodId then
                self._GoodSort[i] = 0
                break
            end
        end
    end

    for paramsIndex, v in pairs(self._TempGoods) do
        if self._SelectGoodsId[goodId] then
            if not v.id then
                local goodCfg = self._Control:GetShopGroceryGoodsConfigsByGoodId(goodId)
                self._TempGoods[paramsIndex].id = goodId
                self._TempGoods[paramsIndex].num = goodCfg.GoldInit
                -- self._SelectGoodsDetailId[paramsIndex]:Update(self._TempGoods[paramsIndex])
                break
            end
        else
            if v.id == goodId then
                self._TempGoods[paramsIndex].id = nil
                -- self._SelectGoodsDetailId[paramsIndex]:Update(self._TempGoods[paramsIndex])
                break
            end
        end
    end
    self._GoodsList[index]:Update()
    self:UpdateShopModel()
end

function XUiSkyGardenShoppingStreetInsideBuildGoods:UpdateShopModel()
    for i = 1, 3 do
        if not self._GoodSort[i] then
            self._GoodSort[i] = 0
        end
    end
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local shopId = shopAreaData:GetShopId()
    local areaId = self._Control:GetAreaIdByShopId(shopId)
    self._Control:X3CChangeShowShowGoods(areaId, XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType.Grocery, self._GoodSort)
end

return XUiSkyGardenShoppingStreetInsideBuildGoods
