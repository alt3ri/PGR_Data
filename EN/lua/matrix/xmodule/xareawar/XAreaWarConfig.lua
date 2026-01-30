-- tableKey{ tableName = {ReadFunc , DirPath, Identifier, TableDefindName, CacheType} }
local TableKey =
{
    AreaWarItem = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "ItemId" },
    AreaWarItemRoomLevel = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "Lv" },
    AreaWarAuction = { Identifier = "ItemId" },
    AreaWarAuctionSell = { Identifier = "ItemId" },
    AreaWarItemQuality = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Quality" },
    AreaWarModel = { DirPath = XConfigUtil.DirectoryType.Client },
}

-- 玩法配置表读取
---@class XAreaWarConfig
local XAreaWarConfig = XClass(nil, "XAreaWarConfig")

function XAreaWarConfig:Ctor(configUtil)
    self._ConfigUtil = configUtil
    self._ConfigUtil:InitConfigByTableKey("AreaWar", TableKey)
end

function XAreaWarConfig:OnInit()
    
end

-- 退出玩法清理内部数据
function XAreaWarConfig:ClearPrivate()
    
end

-- 重登清理数据
function XAreaWarConfig:ResetAll()

end

--region AreaWarItem
function XAreaWarConfig:GetConfigItem(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.AreaWarItem, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.AreaWarItem)
    end
end

function XAreaWarConfig:IsExitItem(id)
    local configs = self._ConfigUtil:GetByTableKey(TableKey.AreaWarItem)
    return configs[id] ~= nil
end

function XAreaWarConfig:GetItemQuality(id)
    local config = self:GetConfigItem(id)
    return config.Quality
end

function XAreaWarConfig:GetItemUnlockLv(id)
    local config = self:GetConfigItem(id)
    return config.UnlockLv
end

function XAreaWarConfig:GetItemName(id)
    local config = self:GetConfigItem(id)
    return config.Name
end

function XAreaWarConfig:GetItemIcon(id)
    local config = self:GetConfigItem(id)
    return config.Icon
end

function XAreaWarConfig:GetRareRewardId(id)
    local config = self:GetConfigItem(id)
    return config.RareRewardId
end

function XAreaWarConfig:GetItemGridMaxCount(id)
    local config = self:GetConfigItem(id)
    return config.GridMaxCount
end

function XAreaWarConfig:GetItemDesc(id)
    local config = self:GetConfigItem(id)
    return config.Desc
end

function XAreaWarConfig:GetItemModelId(id)
    local config = self:GetConfigItem(id)
    return config.ModelId
end

-- 获得稀有道具
function XAreaWarConfig:GetRareItems()
    local result = {}
    local configs = self:GetConfigItem()
    for _, config in pairs(configs) do
        if config.IsRare then
            table.insert(result, config)
        end
    end
    return result
end

--endregion

--region AreaWarItemRoomLevel
function XAreaWarConfig:GetConfigItemRoomLevel(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.AreaWarItemRoomLevel, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.AreaWarItemRoomLevel)
    end
end

function XAreaWarConfig:IsItemRoomLevelExit(id)
    local configs = self:GetConfigItemRoomLevel()
    return configs[id] ~= nil
end

function XAreaWarConfig:GetItemRoomLevelRewardId(id)
    local config = self:GetConfigItemRoomLevel(id)
    return config.RewardId
end

function XAreaWarConfig:GetItemRoomLevelShowAttrs(id)
    local config = self:GetConfigItemRoomLevel(id)
    return config.ShowAttrs
end

function XAreaWarConfig:GetItemRoomLevelLvUpItems(id)
    local config = self:GetConfigItemRoomLevel(id)
    return config.LvUpItems
end

function XAreaWarConfig:GetItemRoomLevelLvUpItemCounts(id)
    local config = self:GetConfigItemRoomLevel(id)
    return config.LvUpItemCounts
end

function XAreaWarConfig:GetItemRoomLevelNeedCleanBlock(id)
    local config = self:GetConfigItemRoomLevel(id)
    return config.NeedCleanBlock
end
--endregion

--region AreaWarAuction
function XAreaWarConfig:GetConfigAuction(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.AreaWarAuction, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.AreaWarAuction)
    end
end

function XAreaWarConfig:GetAuctionBasePrice(id)
    local config = self:GetConfigAuction(id)
    return config.BasePrice
end

--endregion

--region AreaWarAuctionSell
function XAreaWarConfig:GetConfigAuctionSell(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.AreaWarAuctionSell, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.AreaWarAuctionSell)
    end
end

-- 获取销售最低价格
function XAreaWarConfig:GetAuctionSellPriceMin(id)
    local config = self:GetConfigAuctionSell(id)
    local priceMin
    for _, price in pairs(config.PriceIntervalMins) do
        if priceMin == nil or priceMin > price then
            priceMin = price
        end
    end
    return priceMin
end

-- 获取销售最高价格
function XAreaWarConfig:GetAuctionSellPriceMax(id)
    local config = self:GetConfigAuctionSell(id)
    local priceMax
    for _, price in pairs(config.PriceIntervalMaxs) do
        if priceMax == nil or priceMax < price then
            priceMax = price
        end
    end
    return priceMax
end

function XAreaWarConfig:GetAuctionSellPriceDefault(id)
    local config = self:GetConfigAuctionSell(id)
    return config.PriceDefault
end

function XAreaWarConfig:GetAuctionSellPriceInterval(id)
    local config = self:GetConfigAuctionSell(id)
    return config.PriceInterval
end

--endregion

--region AreaWarItemQuality
function XAreaWarConfig:GetConfigItemQuality(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.AreaWarItemQuality, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.AreaWarItemQuality)
    end
end

function XAreaWarConfig:GetItemQualityName(id)
    local config = self:GetConfigItemQuality(id)
    return config.Name
end

function XAreaWarConfig:GetItemQualityIcon(id)
    local config = self:GetConfigItemQuality(id)
    return config.Icon
end

function XAreaWarConfig:GetItemQualitySellTipsType(id)
    local config = self:GetConfigItemQuality(id)
    return config.SellTipsType
end

function XAreaWarConfig:GetItemQualitySellTips(id)
    local config = self:GetConfigItemQuality(id)
    return config.SellTips
end

function XAreaWarConfig:GetItemQualityEffect(id)
    local config = self:GetConfigItemQuality(id)
    return config.Effect
end

-- 获取品质Id列表，需要排序
function XAreaWarConfig:GetItemQualityIdsWithOrder()
    local qualityIds = {}
    local qualityConfigs = self:GetConfigItemQuality()
    for _, qualityConfig in pairs(qualityConfigs) do
        table.insert(qualityIds, qualityConfig.Quality)
    end
    
    table.sort(qualityIds)
    return qualityIds
end
--endregion

--region AreaWarModel
function XAreaWarConfig:GetConfigModel(id)
    if id then
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.AreaWarModel, id)
    else
        return self._ConfigUtil:GetByTableKey(TableKey.AreaWarModel)
    end
end
--endregion

return XAreaWarConfig
