local TableKey = {
    ItemUsePackage = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    ItemExchange = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    ItemCombine = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "ItemId", CacheType = XConfigUtil.CacheType.Normal },

}
---@class XItemConfigModel 纯配置模块
local XItemConfigModel = XClass(XModel, "XItemConfigModel")

function XItemConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("Item", TableKey)
end

---@return XTableItemUsePackage
function XItemConfigModel:GetItemUsePackageConfig(id,noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(
        TableKey.ItemUsePackage, id, noTips)
end

---@return XTableItemExchange
function XItemConfigModel:GetItemExchangeConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(
        TableKey.ItemExchange, id)
end

---@return XTableItemExchange[]
function XItemConfigModel:GetItemExchangeConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.ItemExchange)
end

---@param itemId number
---@return XTableItemExchange[]
function XItemConfigModel:GetItemExchangeConfigsByItemId(itemId)
    local configs = self:GetItemExchangeConfigs()
    local result = {}
    for _, config in ipairs(configs) do
        if config.ItemId == itemId then
            table.insert(result, config)
        end
    end
    return result
end

function XItemConfigModel:GetItemCombineById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.ItemCombine, id,true)
end

---@return XTableItemCombine[]
function XItemConfigModel:GetItemCombinesByGroupId(groupId)
    local result = {}
    local configs = self._ConfigUtil:GetByTableKey(TableKey.ItemCombine)
    for _, config in pairs(configs) do
        if config.GroupId == groupId then
            table.insert(result, config)
        end
    end
    return result
end

return XItemConfigModel
