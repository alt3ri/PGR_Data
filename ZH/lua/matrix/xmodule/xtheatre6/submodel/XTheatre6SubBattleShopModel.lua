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

function XTheatre6SubBattleShopModel:NotifyTheatre6NewRoomData(roomDataDb)
    if not roomDataDb then return end
    self:SetShopFreshCount(self._MainModel:GetCurPlayMode(), roomDataDb.ShopFreshCount)
    self:SetShopGoods(self._MainModel:GetCurPlayMode(), roomDataDb.ShopGoods)
end

function XTheatre6SubBattleShopModel:NotifyTheatre6ActivityData(roomDataDb)
    if not roomDataDb then return end
    self:SetShopFreshCount(self._MainModel:GetCurPlayMode(), roomDataDb.ShopFreshCount)
    self:SetShopGoods(self._MainModel:GetCurPlayMode(), roomDataDb.ShopGoods)
end

function XTheatre6SubBattleShopModel:ClearPlayModeData(playMode)
    self._ShopGoods[playMode] = nil
    self:SetShopFreshCount(playMode, nil)
    self:SetShopGoods(playMode, nil)
end

function XTheatre6SubBattleShopModel:SetShopGoods(modeId, goodsData)
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

function XTheatre6SubBattleShopModel:GetCurShopId()
    return self._MainModel:GetCurRoomData() and self._MainModel:GetCurRoomData().ShopId or 0
end

function XTheatre6SubBattleShopModel:GetShopGoods()
    if not self._ShopGoods or not self._ShopGoods[self._MainModel:GetCurPlayMode()] or  #self._ShopGoods[self._MainModel:GetCurPlayMode()] <= 0 then
        local roomData = self._MainModel:GetCurRoomData()
        self:SetShopGoods(self._MainModel:GetCurPlayMode(), roomData.ShopGoods)
    end
    return self._ShopGoods[self._MainModel:GetCurPlayMode()]
end

---更新商店商品的已购买状态
---@param pos number 商品位置
---@param isSell boolean 是否已购买
function XTheatre6SubBattleShopModel:UpdateShopGoodIsSell(pos, isSell)
    local shopGood = self._ShopGoods[self._MainModel:GetCurPlayMode()][pos + 1] --pos从1开始，数据里是从0开始
    if shopGood then
        shopGood.IsSell = isSell
    end
end

function XTheatre6SubBattleShopModel:UpdateShopGoodIsLock(pos, isLock)
    local shopGood = self._ShopGoods[self._MainModel:GetCurPlayMode()][pos + 1]
    if shopGood then
        shopGood.IsLock = isLock
    else
        XLog.Error("XTheatre6SubBattleShopModel:UpdateShopGoodIsLock error: can not find shop good, shopId is ",
            self:GetCurShopId(), " position is ", pos)
    end
end

function XTheatre6SubBattleShopModel:SetShopFreshCount(modeId, count)
    if not self._ShopFreshCount[modeId] then
        self._ShopFreshCount[modeId] = nil
    end
    self._ShopFreshCount[modeId] = count
end

function XTheatre6SubBattleShopModel:GetShopFreshCount()
    if not self._ShopFreshCount[self._MainModel:GetCurPlayMode()] or self._ShopFreshCount[self._MainModel:GetCurPlayMode()] == 0 then
        local roomData = self._MainModel:GetCurRoomData()
        self:SetShopFreshCount(self._MainModel:GetCurPlayMode(), roomData.ShopFreshCount)
    end
    return self._ShopFreshCount[self._MainModel:GetCurPlayMode()]
end

--endregion


return XTheatre6SubBattleShopModel
