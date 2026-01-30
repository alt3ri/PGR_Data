local tableInsert = table.insert
local tableSort = table.sort
local tableRemove = table.remove

---@class XAreaWarControl : XControl
---@field _Model XAreaWarModel
local XAreaWarControl = XClass(XControl, "XAreaWarControl")
function XAreaWarControl:OnInit()
    
end
XAreaWarControl.ItemEffectType = {
    GlobaleEffect = 2,
    UsingEffect = 1
}
function XAreaWarControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XAreaWarControl:RemoveAgencyEvent()

end

function XAreaWarControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

---@return XAreaWarConfig
function XAreaWarControl:GetConfig()
    return self._Model:GetConfig()
end

-- 获取收藏室数据
---@return XAreaWarItemRoom
function XAreaWarControl:GetItemRoom()
    return self._Model:GetItemRoom()
end

-- 获取交易行数据
---@return XAreaWarAuction
function XAreaWarControl:GetAuction()
    return self._Model:GetAuction()
end

--region 收藏品

-- 获取收藏室商品展示列表
---@param isOrderByHave boolean 是否根据已拥有排序
---@return XAreaWarItem[]
function XAreaWarControl:GetCollectionItemDataList(isOrderByHave)
    local dataList = {}
    -- 已获得item根据GridMaxCount进行拆分
    local itemDic = self._Model:GetItemRoom():GetItemDic()
    for itemId, item in pairs(itemDic) do
        local num = item.Num
        local gridMaxCount = self:GetConfig():GetItemGridMaxCount(itemId)
        if gridMaxCount ~= 0 and num > gridMaxCount then
            while num > gridMaxCount do
                tableInsert(dataList, { ItemId = itemId, Num = gridMaxCount})
                num = num - gridMaxCount
            end
        end
        tableInsert(dataList, { ItemId = itemId, Num = num })
    end

    -- 补充未获得Item
    local itemConfigs = self._Model:GetConfig():GetConfigItem()
    for _, itemConfig in pairs(itemConfigs) do
        local itemId = itemConfig.ItemId
        if not itemDic[itemId] then
            tableInsert(dataList, { ItemId = itemId, Num = 0})
        end
    end

    if isOrderByHave then
        tableSort(dataList, function(a, b)
            local itemIdA = a.ItemId
            local itemIdB = b.ItemId
            
            -- 已拥有 > 已解锁 > 未解锁 
            local isHaveA = a.Num > 0
            local isHaveB = b.Num > 0
            if isHaveA ~= isHaveB then
                return isHaveA

            elseif not isHaveA and not isHaveB then
                -- 已解锁 > 未解锁
                local isUnlockA = self:IsItemUnlock(itemIdA)
                local isUnlockB = self:IsItemUnlock(itemIdB)
                if isUnlockA ~= isUnlockB then
                    return isUnlockA
                end
            end
            
            -- 品质高的优先
            local qualityA = self:GetConfig():GetItemQuality(itemIdA)
            local qualityB = self:GetConfig():GetItemQuality(itemIdB)
            if qualityA ~= qualityB then
                return qualityA > qualityB
            end
            
            -- ItemId越小，优先级越高
            if itemIdA ~= itemIdB then
                return itemIdA < itemIdB
            end

            -- 相同ItemId，数量越多，优先级越高
            return a.Num > b.Num
        end)
    else
        tableSort(dataList, function(a, b)
            local itemIdA = a.ItemId
            local itemIdB = b.ItemId
            
            -- 解锁等级越小，优先级越高
            local aUnlockLv = self:GetConfig():GetItemUnlockLv(itemIdA)
            local bUnlockLv = self:GetConfig():GetItemUnlockLv(itemIdB)
            if aUnlockLv ~= bUnlockLv then
                return aUnlockLv < bUnlockLv
            end
            
            -- ItemId越小，优先级越高
            if itemIdA ~= itemIdB then
                return itemIdA < itemIdB
            end
            
            -- 相同ItemId，数量越多，优先级越高
            return a.Num > b.Num
        end)
    end

    return dataList
end

-- 获取已有收藏品展示列表数据
---@return XAreaWarItem[]
function XAreaWarControl:GetOwnItemDataList(isInGuide)
    local dataList = {}
    
    -- 已获得item根据GridMaxCount进行拆分
    local itemDic = self._Model:GetItemRoom():GetItemDic()
    for itemId, item in pairs(itemDic) do
        local num = item.Num
        local gridMaxCount = self:GetConfig():GetItemGridMaxCount(itemId)
        if gridMaxCount ~= 0 and num > gridMaxCount then
            while num > gridMaxCount do
                tableInsert(dataList, { ItemId = itemId, Num = gridMaxCount})
                num = num - gridMaxCount
            end   
        end
        tableInsert(dataList, { ItemId = itemId, Num = num })
    end
    
    table.sort(dataList, function(a, b)
        local itemIdA = a.ItemId
        local itemIdB = b.ItemId

        -- 品质高的优先
        local qualityA = self:GetConfig():GetItemQuality(itemIdA)
        local qualityB = self:GetConfig():GetItemQuality(itemIdB)
        if qualityA ~= qualityB then
            return qualityA > qualityB
        end
        
        -- ItemId越小，优先级越高
        if itemIdA ~= itemIdB then
            return itemIdA < itemIdB
        end

        -- 相同ItemId，数量越多，优先级越高
        return a.Num > b.Num
    end)

    if isInGuide then
        local item = tableRemove(dataList)
        tableInsert(dataList, 1, item)
    end
    
    return dataList
end

-- 藏品道具是否解锁
function XAreaWarControl:IsItemUnlock(itemId)
    return self._Model:IsItemUnlock(itemId)
end
function XAreaWarControl:GetGlobalProbability()
   return self._Model:GetGlobalProbability()
end
--endregion

--region 蓝点

-- 蓝点：收藏室
function XAreaWarControl:IsRedCollection()
    return self._Model:IsRedCollection()
end

-- 蓝点：获得新道具
function XAreaWarControl:IsRedNewItem()
    return self._Model:IsRedNewItem()
end

-- 蓝点：可提交稀有道具点亮
function XAreaWarControl:IsRedCanSubmitRaceItem()
    return self._Model:IsRedCanSubmitRaceItem()
end

-- 蓝点：可升级藏品室
function XAreaWarControl:IsRedUpgradeCollection()
    return self._Model:IsRedUpgradeCollection()
end

-- 蓝点：交易行订单卖出/过期
function XAreaWarControl:IsRedAuctionOrder()
    return self._Model:IsRedAuctionOrder()
end

--endregion

return XAreaWarControl