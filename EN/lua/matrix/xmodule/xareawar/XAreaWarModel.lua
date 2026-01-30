---@class XAreaWarModel : XModel
---@field _Config XTableAreaWarConfig
---@field _ItemRoom XAreaWarItemRoom 收藏室数据
---@field _Auction XAreaWarAuction 交易行数据
local XAreaWarModel = XClass(XModel, "XAreaWarModel")
function XAreaWarModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._Config = require("XModule/XAreaWar/XAreaWarConfig").New(self._ConfigUtil)
end

-- 退出玩法清理内部数据
function XAreaWarModel:ClearPrivate()
    self._Config:ClearPrivate()
end

-- 重登清理数据
function XAreaWarModel:ResetAll()
    self._ItemRoom = nil
    self._AuctionInfo = nil
    self._Config:ResetAll()
end

---@return XAreaWarConfig
function XAreaWarModel:GetConfig()
    return self._Config
end

--region 协议数据
-- 获取收藏室数据
---@return XAreaWarItemRoom
function XAreaWarModel:GetItemRoom()
    if not self._ItemRoom then
        local XAreaWarItemRoom = require("XModule/XAreaWar/XEntity/XAreaWarItemRoom")
        self._ItemRoom = XAreaWarItemRoom.New()
    end
    return self._ItemRoom
end

-- 藏品是否已经解锁
function XAreaWarModel:IsItemUnlock(itemId)
    local lv = self:GetItemRoom():GetLv()
    local unlockLv = self:GetConfig():GetItemUnlockLv(itemId)
    return lv >= unlockLv
end

-- 获取交易行数据
---@return XAreaWarAuction
function XAreaWarModel:GetAuction()
    if not self._Auction then
        local XAreaWarAuction = require("XModule/XAreaWar/XEntity/XAreaWarAuction")
        self._Auction = XAreaWarAuction.New()
    end
    return self._Auction
end
--endregion

--region 蓝点

-- 蓝点：收藏室
function XAreaWarModel:IsRedCollection()
    if self:IsRedNewItem() then
        return true
    end
    if self:IsRedCanSubmitRaceItem() then
        return true
    end
    if self:IsRedUpgradeCollection() then
        return true
    end
    if self:IsRedAuctionOrder() then
        return true
    end
    return false
end

-- 蓝点：获得新道具
function XAreaWarModel:IsRedNewItem()
    local itemDic = self:GetItemRoom():GetItemDic()
    for _, item in pairs(itemDic) do
        if self:GetItemRoom():IsItemNewGet(item.ItemId) then
            return true
        end
    end
    return false
end

-- 蓝点：可提交稀有道具点亮
function XAreaWarModel:IsRedCanSubmitRaceItem()
    local itemConfigs = self:GetConfig():GetRareItems()
    for _, itemConfig in pairs(itemConfigs) do
        local itemId = itemConfig.ItemId
        local isSubmit = self:GetItemRoom():IsRaceItemSubmit(itemId)
        local itemNum = self:GetItemRoom():GetItemNum(itemId)
        if not isSubmit and itemNum > 0 then
            return true
        end
    end
    return false
end

-- 蓝点：可升级藏品室
function XAreaWarModel:IsRedUpgradeCollection()
    -- 是否有下一等级
    local lv = self:GetItemRoom():GetLv()
    if lv < 1 then lv = 1 end -- 收藏室最低为1级
    local nextLv = lv + 1
    local isNextLvExit = self:GetConfig():IsItemRoomLevelExit(nextLv)
    if not isNextLvExit then return false end

    -- 是否需要块解锁
    local needCleanBlockId = self:GetConfig():GetItemRoomLevelNeedCleanBlock(nextLv)
    local isBlockUnlock = true
    if XTool.IsNumberValidEx(needCleanBlockId) then
        isBlockUnlock = XDataCenter.AreaWarManager.IsBlockClear(needCleanBlockId)
    end
    if not isBlockUnlock then return false end

    -- 升级材料是否足够
    local lvUpItems = self:GetConfig():GetItemRoomLevelLvUpItems(lv)
    local lvUpItemCounts = self:GetConfig():GetItemRoomLevelLvUpItemCounts(lv)
    for i, itemId in ipairs(lvUpItems) do
        local needNum = lvUpItemCounts[i]
        local ownNum = self:GetItemRoom():GetItemNum(itemId)
        if ownNum < needNum then
            return false
        end
    end
    return true
end

-- 蓝点：交易行订单卖出/过期
function XAreaWarModel:IsRedAuctionOrder()
    local orderIds = self:GetItemRoom():GetSettleOrderIds()
    return #orderIds > 0
end

--endregion

function XAreaWarModel:GetGlobalProbability()
    local globalProbability = XMVCA.XAreaWar.EnumConst.ORIGIN_PROBABILITY
    for _,item in pairs( self:GetItemRoom():GetItemDic()) do
            local itemConfig = self:GetConfig():GetConfigItem(item.ItemId)
            if itemConfig.EffectType == XMVCA.XAreaWar.EnumConst.ITEM_EFFECT_TYPE.GLOBAL_EFFECT then
                globalProbability = globalProbability + math.floor(itemConfig.EffectProbability/100)
            end
    end
    return globalProbability
end
return XAreaWarModel
