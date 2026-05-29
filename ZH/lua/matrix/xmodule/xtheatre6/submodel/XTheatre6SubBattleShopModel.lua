---@class XTheatre6SubBattleShopModel : XModel 局内商店
---@field _MainModel XTheatre6Model
---@field _ShopGoods table<number, XTheatre6ShopGoodData> 商店商品数据，key为玩法id
---@field _ShopFreshCount table<number, number> 商店刷新次数，key为玩法
local XTheatre6SubBattleShopModel = XClass(XModel, "XTheatre6SubBattleShopModel")


function XTheatre6SubBattleShopModel:OnInit()
    self._ShopGoods = {}
    self._ShopFreshCount = {}
end

function XTheatre6SubBattleShopModel:ClearPrivate()
    self._ShopGoods = {}
    self._ShopFreshCount = {}
end

function XTheatre6SubBattleShopModel:ResetAll()
    self:ClearPrivate()
end

function XTheatre6SubBattleShopModel:NotifyTheatre6NewRoomData(roomDataDb, playMode)
    if not roomDataDb then return end
    playMode = playMode or self._MainModel:GetCurPlayMode()
    self:SetShopFreshCount(playMode, roomDataDb.ShopFreshCount)
    self:SetShopGoods(playMode, roomDataDb.ShopGoods)
end

function XTheatre6SubBattleShopModel:NotifyTheatre6ActivityData(roomDataDb, playMode)
    if not roomDataDb then return end
    playMode = playMode or self._MainModel:GetCurPlayMode()
    self:SetShopFreshCount(playMode, roomDataDb.ShopFreshCount)
    self:SetShopGoods(playMode, roomDataDb.ShopGoods)
end

function XTheatre6SubBattleShopModel:ClearPlayModeData(playMode)
    self._ShopGoods[playMode] = nil
    self:SetShopFreshCount(playMode, nil)
    self:SetShopGoods(playMode, nil)
end

function XTheatre6SubBattleShopModel:SetShopGoods(modeId, goodsData)
    if not modeId then
        return
    end
    if not self._ShopGoods[modeId] or goodsData == nil then
        self._ShopGoods[modeId] = nil
    end
    if goodsData == nil then
        return
    end
    local shopGoods = {}
    for _, good in pairs(goodsData) do
        shopGoods[#shopGoods + 1] = good
    end
    table.sort(shopGoods, function(a, b)
        if a.Position == b.Position then
            XLog.Error("XTheatre6Control:GetShopGoods error: shop goods position is same, shopId is ",
                self:GetCurShopId(), " position is ", a.Position)
            return a.GoodId < b.GoodId
        end
        return a.Position < b.Position
    end)
    self._ShopGoods[modeId] = shopGoods
end

function XTheatre6SubBattleShopModel:SyncCurRoomShopData(shopGoods, shopFreshCount)
    local playMode = self._MainModel:GetCurPlayMode()
    local modelData = self._MainModel:GetCurPlayModeData()
    local roomData = modelData and modelData.CurrentRoomDataDb
    if not roomData then
        return
    end

    if shopGoods ~= nil then
        roomData.ShopGoods = shopGoods
        self:SetShopGoods(playMode, shopGoods)
    end
    if shopFreshCount ~= nil then
        roomData.ShopFreshCount = shopFreshCount
        self:SetShopFreshCount(playMode, shopFreshCount)
    end
end

function XTheatre6SubBattleShopModel:GetCurShopId()
    return self._MainModel:GetCurRoomData() and self._MainModel:GetCurRoomData().ShopId or 0
end

function XTheatre6SubBattleShopModel:GetShopGoods()
    if not self._ShopGoods or not self._ShopGoods[self._MainModel:GetCurPlayMode()] or #self._ShopGoods[self._MainModel:GetCurPlayMode()] <= 0 then
        local roomData = self._MainModel:GetCurRoomData()
        if roomData then
            self:SetShopGoods(self._MainModel:GetCurPlayMode(), roomData.ShopGoods)
        end
    end
    return self._ShopGoods[self._MainModel:GetCurPlayMode()]
end

function XTheatre6SubBattleShopModel:GetShopGoodByPos(pos)
    local shopGoods = self:GetShopGoods()
    if XTool.IsTableEmpty(shopGoods) then
        return nil
    end
    for _, shopGood in pairs(shopGoods) do
        if shopGood.Position == pos then
            return shopGood
        end
    end
    return nil
end

function XTheatre6SubBattleShopModel:UpdateShopGoodDataInList(goodsList, shopGoodData)
    if XTool.IsTableEmpty(goodsList) or not shopGoodData then
        return nil
    end
    for _, shopGood in pairs(goodsList) do
        if shopGood.Position == shopGoodData.Position then
            for key, value in pairs(shopGoodData) do
                shopGood[key] = value
            end
            return shopGood
        end
    end
    return nil
end

function XTheatre6SubBattleShopModel:UpdateCurRoomShopGoodData(shopGoodData)
    local modelData = self._MainModel:GetCurPlayModeData()
    local roomData = modelData and modelData.CurrentRoomDataDb
    if not roomData then
        return
    end
    self:UpdateShopGoodDataInList(roomData.ShopGoods, shopGoodData)
end

function XTheatre6SubBattleShopModel:UpdateShopGoodData(shopGoodData)
    if not shopGoodData then
        return
    end

    local shopGoods = self:GetShopGoods()
    if not self:UpdateShopGoodDataInList(shopGoods, shopGoodData) then
        XLog.Error("XTheatre6SubBattleShopModel:UpdateShopGoodData error: can not find shop good, shopId is ",
            self:GetCurShopId(), " position is ", shopGoodData.Position)
    end
    self:UpdateCurRoomShopGoodData(shopGoodData)
end

---更新商店商品的已购买状态
---@param pos number 商品位置
---@param isSell boolean 是否已购买
function XTheatre6SubBattleShopModel:UpdateShopGoodIsSell(pos, isSell)
    local shopGood = self:GetShopGoodByPos(pos)
    if shopGood then
        shopGood.IsSell = isSell
        self:UpdateCurRoomShopGoodData(shopGood)
    else
        XLog.Error("XTheatre6SubBattleShopModel:UpdateShopGoodIsSell error: can not find shop good, shopId is ",
            self:GetCurShopId(), " position is ", pos)
    end
end

function XTheatre6SubBattleShopModel:UpdateShopGoodIsLock(pos, isLock)
    local shopGood = self:GetShopGoodByPos(pos)
    if shopGood then
        shopGood.IsLock = isLock
        self:UpdateCurRoomShopGoodData(shopGood)
    else
        XLog.Error("XTheatre6SubBattleShopModel:UpdateShopGoodIsLock error: can not find shop good, shopId is ",
            self:GetCurShopId(), " position is ", pos)
    end
end

function XTheatre6SubBattleShopModel:SetShopFreshCount(modeId, count)
    if not modeId then
        return
    end
    if not self._ShopFreshCount[modeId] then
        self._ShopFreshCount[modeId] = nil
    end
    self._ShopFreshCount[modeId] = count
end

function XTheatre6SubBattleShopModel:GetShopFreshCount()
    local freshCount = self._ShopFreshCount[self._MainModel:GetCurPlayMode()]
    if not freshCount or freshCount == 0 then
        local roomData = self._MainModel:GetCurRoomData()
        if roomData then
            self:SetShopFreshCount(self._MainModel:GetCurPlayMode(), roomData.ShopFreshCount)
        end
    end
    return self._ShopFreshCount[self._MainModel:GetCurPlayMode()]
end

--endregion


return XTheatre6SubBattleShopModel
