local XUiSkyGardenShoppingStreetInsideBuildGridMaterial = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetInsideBuildGridMaterial")
---@class XUiSkyGardenShoppingStreetInsideBuildDessert : XUiNode
---@field GridMaterial UnityEngine.RectTransform
---@field BtnMinus XUiComponent.XUiButton
---@field TxtNum UnityEngine.UI.Text
---@field BtnAdd XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetInsideBuildDessert = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildDessert")

function XUiSkyGardenShoppingStreetInsideBuildDessert:OnStart()
    ---@type XUiSkyGardenShoppingStreetInsideBuildGridMaterial
    self._GridMaterialsUi = {}
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:Reset()
    local resetData = self._Control:GetResetData(XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType.Dessert)
    self:_UpdateByData(resetData)
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:HasResetTips()
    local resetData = self._Control:GetResetData(XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType.Dessert)
    local goodsIdList = {}
    if not resetData then
        local gold = XMath.Clamp(self._DessertCfg.InitGold, self._MinNum, self._MaxNum)
        if gold ~= self._Price then return false end

        for i = 1, self._DessertCount do
            goodsIdList[i] = self._DessertCfg.Goods[i]
        end
    else
        if self._Price ~= resetData.Gold then return false end
        for i = 1, self._DessertCount do
            goodsIdList[i] = resetData.GoodsIdList[i]
        end
    end

    for i, v in pairs(self._TempSort) do
        if v ~= goodsIdList[self._DessertCount - i + 1] then return false end
    end
    return true
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:TempCheckInfo()
    self._tempCache = {}
    self._tempCache["Price"] = self._Price
    local Goods = {}
    for i, v in pairs(self._TempSort) do
        Goods[i] = v
    end
    self._tempCache["Goods"] = Goods
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:HasSaveTips()
    if self._tempCache["Price"] ~= self._Price then return true end
    for i, v in pairs(self._TempSort) do
        if self._tempCache["Goods"][i] ~= v then
            return true
        end
    end
    return false
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:_UpdateByData(dessertData)
    self._TempSort = {}
    local goodsIdList, gold
    if dessertData then
        goodsIdList = dessertData.GoodsIdList
        gold = dessertData.Gold
    else
        goodsIdList = {}
        for i = 1, self._DessertCount do
            goodsIdList[i] = self._DessertCfg.Goods[i]
        end
        gold = XMath.Clamp(self._DessertCfg.InitGold, self._MinNum, self._MaxNum)
    end
    for i = 1, self._DessertCount do
        self._TempSort[i] = goodsIdList[self._DessertCount - i + 1]
    end
    self._Price = gold

    self:_UpdateGrid()
    self:_UpdatePrice()
    self:TempCheckInfo()
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:SetBuilding(pos, isInside)
    self._BuildPos = pos
    self._IsInside = isInside

    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local buildingId = shopAreaData:GetShopId()
    self._DessertCfg = self._Control:GetShopDessertConfigsByShopId(buildingId)
    self._DessertCount = #self._DessertCfg.Goods
    self._MinNum = self._DessertCfg.GoldMin
    self._MaxNum = self._DessertCfg.GoldMax

    self:_UpdateByData(shopAreaData:GetDessertData())
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:MoveGrid(from, to)
    if not from or not to then return end
    -- if from > to then
    --     table.insert(self._TempSort, to, table.remove(self._TempSort, from))
    -- else
    --     table.insert(self._TempSort, from, table.remove(self._TempSort, to))
    -- end
    self._TempSort[from], self._TempSort[to] = self._TempSort[to], self._TempSort[from]
    self:_UpdateGrid()
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:_UpdateGrid()
    self._GoodsId = {}
    for i = 1, #self._TempSort do
        local index = self._TempSort[i]
        if index and index <= self._DessertCount then
            local dessertId = self._DessertCfg.Goods[index]
            self._GoodsId[#self._GoodsId + 1] = dessertId
        end
    end
    XTool.UpdateDynamicItem(self._GridMaterialsUi, self._GoodsId, self.GridMaterial, XUiSkyGardenShoppingStreetInsideBuildGridMaterial, self)
    
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local shopId = shopAreaData:GetShopId()
    local areaId = self._Control:GetAreaIdByShopId(shopId)

    local dessertIds = {}
    for i = 1, self._DessertCount do
        dessertIds[i] = self._Control:DessertIdSwitchX3cId(self._TempSort[self._DessertCount - i + 1])
    end
    self._Control:X3CChangeShowShowGoods(areaId, XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType.Dessert, dessertIds)
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:_UpdatePrice()
    self.TxtNum.text = self._Price
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:MoveOffset(index, offset)
    -- XLog.Debug("MoveOffset", index, offset)
    self.XAudioObjectPlayer:PlayByKeyName("MoveOffset")
    self:MoveGrid(index, index + offset)
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuildDessert:OnBtnMinusClick()
    local newPrice = XMath.Clamp(self._Price - 1, self._MinNum, self._MaxNum)
    if self._Price == newPrice then return end
    
    if self.BtnMinusPressEnable then
        self.BtnMinusPressEnable:PlayTimelineAnimation()
    end
    self._Price = newPrice
    self:_UpdatePrice()
end

function XUiSkyGardenShoppingStreetInsideBuildDessert:OnBtnAddClick()
    local newPrice = XMath.Clamp(self._Price + 1, self._MinNum, self._MaxNum)
    if self._Price == newPrice then return end
    
    if self.BtnAddEnable then
        self.BtnAddEnable:PlayTimelineAnimation()
    end
    self._Price = newPrice
    self:_UpdatePrice()
end

--endregion
function XUiSkyGardenShoppingStreetInsideBuildDessert:OnBtnSaveClick(isForce)
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local sendData = {}
    for i = 1, self._DessertCount do
        sendData[i] = self._TempSort[self._DessertCount - i + 1]
    end
    self._Control:SgStreetShopSetupDessertRequest(
        shopAreaData:GetShopId(),
        sendData,
        self._Price
    )
    self:TempCheckInfo()
end

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuildDessert:_RegisterButtonClicks()
    self.BtnMinus:AddEventListener(handler(self, self.OnBtnMinusClick))
    self.BtnAdd:AddEventListener(handler(self, self.OnBtnAddClick))
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuildDessert
