local XUiSkyGardenShoppingStreetInsideBuildSet = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildSet")
-- local XUiSkyGardenShoppingStreetInsideBuildFoodShow = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildFoodShow")

---@class XUiSkyGardenShoppingStreetInsideBuildFood : XUiNode
---@field PanelSetA UnityEngine.RectTransform
---@field PanelSetB UnityEngine.RectTransform
---@field PanelSetC UnityEngine.RectTransform
---@field PanelSetD UnityEngine.RectTransform
---@field PanelFood UnityEngine.RectTransform
---@field BtnMinus XUiComponent.XUiButton
---@field TxtNum UnityEngine.UI.Text
---@field BtnAdd XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetInsideBuildFood = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildFood")

local FoodGoodId2AddSound = {
    [1] = "1",
    [2] = "2",
    [3] = "3",
}
local FoodGoodId2ReduceSound = "ReduceSound"

local FoodUiKey2Obj = {
    [1] = {
        ObjectName = "PanelSetB",
        LuaName = "PanelSetBUi",
    },
    [2] = {
        ObjectName = "PanelSetC",
        LuaName = "PanelSetCUi",
    },
    [3] = {
        ObjectName = "PanelSetD",
        LuaName = "PanelSetDUi",
    },
}

function XUiSkyGardenShoppingStreetInsideBuildFood:OnStart()
    self:_RegisterButtonClicks()
    -- self.PanelFoodUi = XUiSkyGardenShoppingStreetInsideBuildFoodShow.New(self.PanelFood, self)
end

function XUiSkyGardenShoppingStreetInsideBuildFood:Reset()
    local resetData = self._Control:GetResetData(XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType.Food)
    self:_UpdateByData(resetData)
end

function XUiSkyGardenShoppingStreetInsideBuildFood:HasResetTips()
    local resetData = self._Control:GetResetData(XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType.Food)
    if not resetData then
        resetData = {}
        resetData.Gold = XMath.Clamp(self._FoodCfg.InitGold, self._MinNum, self._MaxNum)
        resetData.ChefId = self._FoodCfg.Chef[1]
        local GoodsCountList = {}
        for i = 1, #self._FoodCfg.Goods do
            local goodId = self._FoodCfg.Goods[i]
            local cfg = self._Control:GetShopFoodGoodsConfigsByGoodId(goodId)
            GoodsCountList[i] = cfg.GoodsInit
        end
        resetData.GoodsCountList = GoodsCountList
    end

    local curChefId = resetData.ChefId
    local resetChefIdIndex = 1
    for i = 1, #self._FoodCfg.Chef do
        local chefId = self._FoodCfg.Chef[i]
        if curChefId == chefId then
            resetChefIdIndex = i
            break
        end
    end

    if self._ChefIndex ~= resetChefIdIndex or self._Price ~= resetData.Gold then
        return false
    end
    for i = 1, #resetData.GoodsCountList do
        local resetNum = resetData.GoodsCountList[i]
        local goodsNum = self._TempGoods[i]
        if resetNum ~= goodsNum then return false end
    end
    return true
end

function XUiSkyGardenShoppingStreetInsideBuildFood:TempCheckInfo()
    self._tempCache = {}
    self._tempCache["ChefId"] = self._ChefIndex
    self._tempCache["Price"] = self._Price
    local Goods = {}
    for i, v in pairs(self._TempGoods) do
        Goods[i] = v
    end
    self._tempCache["Goods"] = Goods
end

function XUiSkyGardenShoppingStreetInsideBuildFood:HasSaveTips()
    if self._tempCache["Price"] ~= self._Price then return true end
    if self._tempCache["ChefId"] ~= self._ChefIndex then return true end
    for i, v in pairs(self._TempGoods) do
        if self._tempCache["Goods"][i] ~= v then
            return true
        end
    end
    return false
end

function XUiSkyGardenShoppingStreetInsideBuildFood:_UpdateByData(foodData)
    local curChefId, GoodsCountList
    if foodData then
        curChefId = foodData.ChefId
        self._Price = foodData.Gold
        GoodsCountList = foodData.GoodsCountList
    else
        self._Price = XMath.Clamp(self._FoodCfg.InitGold, self._MinNum, self._MaxNum)
        GoodsCountList = {}
    end
    self._ChefIndex = 1
    if curChefId then
        for i = 1, #self._FoodCfg.Chef do
            local chefId = self._FoodCfg.Chef[i]
            if curChefId == chefId then
                self._ChefIndex = i
                break
            end
        end
    end

    self._idMap = {}
    self._TempGoods = {}
    self._InitFinish = false
    for i = 1, #FoodUiKey2Obj do
        local uiconfig = FoodUiKey2Obj[i]
        local goodId = self._FoodCfg.Goods[i]
        local hasGood = goodId ~= nil
        self[uiconfig.ObjectName].gameObject:SetActive(hasGood)
        if hasGood and not self[uiconfig.LuaName] then
            self[uiconfig.LuaName] = XUiSkyGardenShoppingStreetInsideBuildSet.New(self[uiconfig.ObjectName], self)
        end
        if hasGood then
            local cfg = self._Control:GetShopFoodGoodsConfigsByGoodId(goodId)
            self._idMap[i] = goodId
            -- self.PanelFoodUi:SetImageList(i, cfg.ImgPathGroup)
            self._TempGoods[i] = GoodsCountList[i] or cfg.GoodsInit
            local luaUiNode = self[uiconfig.LuaName]
            luaUiNode:SetUpdateCallback(function(index)
                if self._TempGoods[i] ~= index then
                    if index > self._TempGoods[i] then
                        self.XAudioObjectPlayer:PlayByKeyName(FoodGoodId2AddSound[goodId])
                    else
                        self.XAudioObjectPlayer:PlayByKeyName(FoodGoodId2ReduceSound)
                    end
                    -- XLog.Debug(goodId, "数量变化", self._TempGoods[i], "->", index)
                end
                luaUiNode:SetName(index)
                self._TempGoods[i] = index
                self:_UpdateFoodShow(i, index)
            end)
            luaUiNode:SetIcon(cfg.GoodsRes)
            luaUiNode:SetTilte(cfg.GoodsName)
            luaUiNode:SetIndex(self._TempGoods[i], cfg.GoodsMin, cfg.GoodsMax)
        end
    end

    local chiefImagePaths = {}
    local chiefNum = #self._FoodCfg.Chef
    for i = 1, chiefNum do
        local chefId = self._FoodCfg.Chef[i]
        local chefCfg = self._Control:GetShopFoodChefConfigsByChefId(chefId)
        chiefImagePaths[i] = chefCfg.ImgPath
    end
    -- self.PanelFoodUi:SetImageList(4, chiefImagePaths)

    if not self.PanelSetAUi then
        self.PanelSetAUi = XUiSkyGardenShoppingStreetInsideBuildSet.New(self.PanelSetA, self)
    end
    self.PanelSetAUi:SetUpdateCallback(function(index)
        local chefId = self._FoodCfg.Chef[index]
        if not chefId then return end
        local chefCfg = self._Control:GetShopFoodChefConfigsByChefId(chefId)
        if not chefCfg then return end
        self.PanelSetAUi:SetName(chefCfg.ChefName)
        self._ChefIndex = index
        -- self.PanelFoodUi:SetChefSelect(index)
        self:_UpdateFoodShowModel()
    end)
    self.PanelSetAUi:SetIndex(self._ChefIndex, 1, chiefNum, true)
    self:_UpdatePrice()
    self._InitFinish = true
    self:_UpdateFoodShowModel()
    self:TempCheckInfo()
end

function XUiSkyGardenShoppingStreetInsideBuildFood:SetBuilding(pos, isInside)
    self._BuildPos = pos
    self._IsInside = isInside
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local buildingId = shopAreaData:GetShopId()
    self._FoodCfg = self._Control:GetShopFoodConfigsByShopId(buildingId)
    self._MinNum = self._FoodCfg.GoldMin
    self._MaxNum = self._FoodCfg.GoldMax

    self:_UpdateByData(shopAreaData:GetFoodData())
end

function XUiSkyGardenShoppingStreetInsideBuildFood:_UpdateFoodShowModel()
    if not self._InitFinish then return end
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local shopId = shopAreaData:GetShopId()
    local areaId = self._Control:GetAreaIdByShopId(shopId)
    local x3cId = {}
    for i = 1, #self._TempGoods do
        x3cId[self._Control:FoodIdSwitchX3cId(self._idMap[i])] = self._TempGoods[i]
    end
    x3cId[4] = self._Control:FoodChefIdSwitchX3cId(self._ChefIndex)
    
    self._Control:X3CChangeShowShowGoods(areaId, XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType.Food, x3cId)
end

function XUiSkyGardenShoppingStreetInsideBuildFood:_UpdateFoodShow(index, count)
    -- self.PanelFoodUi:SetFoodSelect(index, count)
    self:_UpdateFoodShowModel()
end

function XUiSkyGardenShoppingStreetInsideBuildFood:_UpdatePrice()
    self.TxtNum.text = self._Price
end

function XUiSkyGardenShoppingStreetInsideBuildFood:OnBtnSaveClick(isForce)
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local shopId = shopAreaData:GetShopId()
    local foodCfg = self._Control:GetShopFoodConfigsByShopId(shopId)
    self._Control:SgStreetShopSetupFoodRequest(shopId, foodCfg.Chef[self._ChefIndex], self._TempGoods, self._Price)
    self:TempCheckInfo()
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuildFood:OnBtnMinusClick()
    local newPrice = XMath.Clamp(self._Price - 1, self._MinNum, self._MaxNum)
    if self._Price == newPrice then return end
    
    if self.BtnMinusPressEnable then
        self.BtnMinusPressEnable:PlayTimelineAnimation()
    end
    self._Price = newPrice
    self:_UpdatePrice()
end

function XUiSkyGardenShoppingStreetInsideBuildFood:OnBtnAddClick()
    local newPrice = XMath.Clamp(self._Price + 1, self._MinNum, self._MaxNum)
    if self._Price == newPrice then return end
    
    if self.BtnAddEnable then
        self.BtnAddEnable:PlayTimelineAnimation()
    end
    self._Price = newPrice
    self:_UpdatePrice()
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuildFood:_RegisterButtonClicks()
    self.BtnMinus:AddEventListener(handler(self, self.OnBtnMinusClick))
    self.BtnAdd:AddEventListener(handler(self, self.OnBtnAddClick))
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuildFood
