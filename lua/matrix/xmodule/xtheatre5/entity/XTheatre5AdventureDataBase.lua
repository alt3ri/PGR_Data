--region 类型定义

--- 商店
---@class XTheatre5ShopData
---@field ShopId
---@field Goods XTheatre5Goods[]
---@field UnlockGridsNum
---@field RefreshCnt

--- 商品
---@class XTheatre5Goods
---@field ItemInfo XTheatre5Item
---@field IsSpecialPrice
---@field IsSoldOut
---@field IsFreeze

--- 物品
---@class XTheatre5Item
---@field InstanceId
---@field ItemId
---@field ItemType
---@field IsStrengthen

--- 背包
---@class XTheatre5BagData
---@field BagItemDict table<number, XTheatre5Item>
---@field SkillDict table<number, XTheatre5Item>
---@field RuneDict table<number, XTheatre5Item>
---@field RelicDict table<number, XTheatre5Item>
---@field BagGridsNum
---@field SkillGridsNum
---@field RuneGridsNum
---@field RoundNumWithoutGridUnlock

--- 技能三选一
---@class Theatre5SkillChoiceData
---@field SkillGroups XTheatre5Goods[]

--- 属性临时加成
---@class XTheatre5AddAttrResult
---@field AttrType number@属性类型
---@field FixVal number@固定值
---@field RateVal number@万分比
---@field SpecificVal number@特定变量
---@field SpecificRateVal number@特定变量万分比


--- 任务
---@class Theatre5Mission
---@field MissionId
---@field MissionBounty Theatre5MissionBounty
---@field MissionCondition Theatre5MissionCondition
---@field MissionState @任务状态
---@field MissionRelicId number @领取的道具

---@class Theatre5MissionBounty
---@field Bounty number@条件id(Theatre5Mission表的Bounty)
---@field BountyLevel number@奖励等级

---@class Theatre5MissionCondition
---@field ConditionId number@条件id(Theatre5MissionCondition表的id)
---@field ConditionCounter number@条件计数器


--endregion

--- 局内数据基类
---@class XTheatre5AdventureDataBase
---@field Version number
---@field CharacterId number
---@field Status number
---@field RoundNum number
---@field GoldNum number
---@field Health number
---@field IdSequence number
---@field ShopData XTheatre5ShopData
---@field BagData XTheatre5BagData
---@field SkillChoiceData Theatre5SkillChoiceData
---@field CheckFailTimes number
---@field Missioning Theatre5Mission @当前接取的任务
---@field ChooseMissions table<number, Theatre5Mission> @接取界面随机的任务
---@field FreshMissionCounts table<number, number> @任务接取界面的刷新次数, key任务id，value剩余刷新次数
---@field FreshMissionBounty number[] @刷新过程中用到的[奖励],接取任务后清除
---@field FreshMissionCondition number[] @刷新过程中用到的[条件],接取任务后清除
---@field MissionLevelUpForRound number @每回合升级次数
---@field ChooseMissionBounty @领取过的任务, 需要额外传入
local XTheatre5AdventureDataBase = XClass(nil, 'XTheatre5AdventureDataBase')

function XTheatre5AdventureDataBase:Ctor()
    self._TempBuffList = {}
    self._TempAttrList = {}

    if XMain.IsEditorDebug then
        self._ObsoleteMeta = {
            __index = function(table, key)
                XLog.Error('读取遗弃的数据，table：' .. tostring(table) .. ' key: ' .. tostring(key))
            end,
            __newindex = function(table, key, value)
                XLog.Error('写入遗弃的数据，table：' .. tostring(table) .. ' key: ' .. tostring(key) .. ' value: ' .. tostring(value))
            end
        }
    end
end

function XTheatre5AdventureDataBase:ClearAdventureData()
    self:ClearData()
end

function XTheatre5AdventureDataBase:ClearData()
    self.HasData = false
    self.ShopData = nil
    self.BagData = nil
    self.SkillChoiceData = nil
    self:ClearEventData()
    self.RandomRelics = {}
    self.EffectFreeRefreshCnt = 0
    self.Missioning = nil
    self.ChooseMissions = nil
    self.FreshMissionCounts = nil
    self.FreshMissionBounty = nil
    self.FreshMissionCondition = nil
end

--region 基础信息

--- 更新金币数（局内）
function XTheatre5AdventureDataBase:UpdateGoldNum(goldNum)
    if type(goldNum) == 'number' then
        self.GoldNum = goldNum
    end
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW)
end

--- 更新生命值（局内）
function XTheatre5AdventureDataBase:UpdateHealth(health)
    self.Health = health
end

function XTheatre5AdventureDataBase:UpdateRoundNum(roundNum)
    self.RoundNum = roundNum
end

--- 更新游玩状态
function XTheatre5AdventureDataBase:UpdateCurPlayStatus(status, ignoreTrigger)
    if status then
        self.Status = status
        XLog.Debug("[XTheatre5AdventureDataBase] 更改游戏状态:", status)
        -- 只在这两个状态下，可以自由触发
        if status == XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping
                or status == XMVCA.XTheatre5.EnumConst.PlayStatus.ChoiceSkill
        then
            XLog.Debug("[XTheatre5AdventureDataBase] 触发中断事件")
            if not ignoreTrigger then
                XMVCA.XTheatre5:TriggerInterruptEvent()
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_REFRESH_LEVEL_EXP)
    end
end

--- 更新校验失败次数
function XTheatre5AdventureDataBase:UpdateCheckFailTimes(failTimes)
    self.CheckFailTimes = failTimes
end

function XTheatre5AdventureDataBase:GetGoldNum()
    return self.GoldNum or 0
end

function XTheatre5AdventureDataBase:GetHealth()
    return self.Health or 0
end

function XTheatre5AdventureDataBase:GetCharacterId()
    return self.CharacterId
end

function XTheatre5AdventureDataBase:GetRoundNum()
    return self.RoundNum or 0
end

function XTheatre5AdventureDataBase:GetCurPlayStatus()
    return self.Status
end

--- 校验失败次数
function XTheatre5AdventureDataBase:GetCheckFailTimes()
    return self.CheckFailTimes or 0
end

--endregion

--region 背包信息

--- 背包数据全量更新（局内）
function XTheatre5AdventureDataBase:UpdateFullBagData(bagData)
    if XMain.IsEditorDebug then
        if self.BagData then
            self.BagData.IsObsolete = true

            if not XTool.IsTableEmpty(self.BagData.BagItemDict) then
                for i, v in pairs(self.BagData.BagItemDict) do
                    v.IsObsolete = true
                end
            end

            if not XTool.IsTableEmpty(self.BagData.SkillDict) then
                for i, v in pairs(self.BagData.SkillDict) do
                    v.IsObsolete = true
                end
            end

            if not XTool.IsTableEmpty(self.BagData.RuneDict) then
                for i, v in pairs(self.BagData.RuneDict) do
                    v.IsObsolete = true
                end
            end

            -- v4.0 新增饰品
            if not XTool.IsTableEmpty(self.BagData.RelicDict) then
                for i, v in pairs(self.BagData.RelicDict) do
                    v.IsObsolete = true
                end
            end
        end
    end

    self.BagData = bagData
    self.HasData = true

    self:SetNeedUpdateAdds()
end

function XTheatre5AdventureDataBase:SetShopItemBuy(bagUpdates)
    for i = 1, #bagUpdates do
        local bagUpdate = bagUpdates[i]
        local item = bagUpdate.Item
        local instanceId = item.InstanceId
        for i, itemData in pairs(self.ShopData.Goods) do
            if itemData.ItemInfo.InstanceId == instanceId then
                -- 服务端没有下推商店结果, 需要自行置为已售罄
                itemData.IsSoldOut = true
            end
        end
    end
end

-- 增量更新
function XTheatre5AdventureDataBase:HandleBagUpdates(bagUpdates)
    for i = 1, #bagUpdates do
        self:HandleBagUpdate(bagUpdates[i])
    end
end

function XTheatre5AdventureDataBase:HandleBagUpdate(bagUpdate)
    if not bagUpdate then
        XLog.Warning("[XTheatre5AdventureDataBase] 更新背包数据，但是数据为空")
        return
    end
    local item = bagUpdate.Item
    if item then
        local instanceId = item.InstanceId
        if bagUpdate.UpdateType == XMVCA.XTheatre5.EnumConst.Theatre5BagUpdateType.Update then
            if bagUpdate.IsTempBag then
                self:UpdateItem(self.BagData.TempItemDict, bagUpdate.Item, bagUpdate.Index)
            else
                self:UpdateItem(self.BagData.BagItemDict, bagUpdate.Item, bagUpdate.Index)
            end

        elseif bagUpdate.UpdateType == XMVCA.XTheatre5.EnumConst.Theatre5BagUpdateType.Add then
            -- 新增也用update函数，里面有对instanceId查重
            if bagUpdate.IsTempBag then
                self:UpdateItem(self.BagData.TempItemDict, bagUpdate.Item, bagUpdate.Index)
                XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_UPDATE_BAG)
            else
                self:UpdateItem(self.BagData.BagItemDict, bagUpdate.Item, bagUpdate.Index)
            end

        elseif bagUpdate.UpdateType == XMVCA.XTheatre5.EnumConst.Theatre5BagUpdateType.Remove then
            self:RemoveItem(instanceId)
        else
            XLog.Error("[XTheatre5AdventureDataBase] 背包数据更新类型错误：" .. tostring(bagUpdate.UpdateType))
        end
    else
        XLog.Error("[XTheatre5AdventureDataBase] 服务端的Theatre5BagUpdate里没有Item，和设想的不一样")
    end
end

function XTheatre5AdventureDataBase:UpdateOneRelic(itemData)
    if not itemData then
        XLog.Error("[XTheatre5AdventureDataBase] 更新单个饰品数据失败，数据为空")
        return
    end
    if not self.BagData then
        XLog.Error("[XTheatre5AdventureDataBase] 在更新单个饰品数据之前，还没收到背包数据，不太可能吧？是不是有bug")
    end

    self.BagData = self.BagData or {}
    self.BagData.RelicDict = self.BagData.RelicDict or {}
    self.HasData = true
    self:SetNeedUpdateAdds()
    for i, v in pairs(self.BagData.RelicDict) do
        if v.InstanceId == itemData.InstanceId then
            self.BagData.RelicDict[i] = itemData
            itemData.IsObsolete = true
            return
        end
    end
    self.BagData.RelicDict[itemData.InstanceId] = itemData
    itemData.IsObsolete = true
    if not self.RelicOrders then
        self.RelicOrders = {}
    end
    self.RelicOrders[#self.RelicOrders + 1] = itemData.InstanceId
end

function XTheatre5AdventureDataBase:UpdateItem(itemDict, item, position)
    local originalItem
    local originalPosition
    for i, v in pairs(itemDict) do
        if v.InstanceId == item.InstanceId then
            originalItem = v
            originalPosition = i
            break
        end
    end
    if originalItem then
        if originalItem.Position ~= position then
            itemDict[originalPosition] = nil
            itemDict[position] = item
        else
            itemDict[position] = item
        end
    else
        itemDict[position] = item
    end
end

function XTheatre5AdventureDataBase:RemoveItem(instanceId, noTips)
    if self.BagData and self.BagData.BagItemDict then
        for i, v in pairs(self.BagData.BagItemDict) do
            if v.InstanceId == instanceId then
                self.BagData.BagItemDict[i] = nil
                return true
            end
        end
    end
    if self.BagData and self.BagData.TempItemDict then
        for i, v in pairs(self.BagData.TempItemDict) do
            if v.InstanceId == instanceId then
                self.BagData.TempItemDict[i] = nil
                return true
            end
        end
    end
    if not noTips then
        XLog.Error("[XTheatre5AdventureDataBase] 移除物品失败，找不到:" .. tostring(instanceId))
    end
    return false
end

function XTheatre5AdventureDataBase:UpdateRune(runeItemData)
    self.BagData = self.BagData or {}
    self.BagData.RuneDict = self.BagData.RuneDict or {}
    self.HasData = true
    self:SetNeedUpdateAdds()
    for i, v in pairs(self.BagData.RuneDict) do
        if v.InstanceId == runeItemData.InstanceId then
            self.BagData.RuneDict[i] = runeItemData
            runeItemData.IsObsolete = true
            return
        end
    end
    --self.BagData.RuneDict[#self.BagData.RuneDict + 1] = runeItemData

    self.BagData.BagItemDict = self.BagData.BagItemDict or {}
    for i, v in pairs(self.BagData.BagItemDict) do
        if v.InstanceId == runeItemData.InstanceId then
            self.BagData.BagItemDict[i] = runeItemData
            runeItemData.IsObsolete = true
            return
        end
    end

    XLog.Error("[XTheatre5AdventureDataBase] 强化后符文物品更新出现了不在设想中的情况")
    runeItemData.IsObsolete = true
end

function XTheatre5AdventureDataBase:GetBagSkillGridsNum()
    return self.BagData and self.BagData.SkillGridsNum or 0
end

function XTheatre5AdventureDataBase:GetBagRuneGridsNum()
    return self.BagData and self.BagData.RuneGridsNum or 0
end

--不装备的格子数量
function XTheatre5AdventureDataBase:GetBagGridsNum()
    return self.BagData and self.BagData.BagGridsNum or 0
end

function XTheatre5AdventureDataBase:GetTempBagGrids()
    return self.BagData and self.BagData.TempItemDict
end

function XTheatre5AdventureDataBase:HasTempBagGrid()
    if self.BagData and not XTool.IsTableEmpty(self.BagData.TempItemDict) then
        return true
    end
    return false
end

--- 获取背包栏指定位置的物品数据
function XTheatre5AdventureDataBase:GetItemInBagByIndex(index)
    if self.BagData and self.BagData.BagItemDict then
        return self.BagData.BagItemDict[index]
    end
end

function XTheatre5AdventureDataBase:GetItemIndexInBag(itemData)
    if self.BagData and self.BagData.BagItemDict then
        for i, v in pairs(self.BagData.BagItemDict) do
            if v.InstanceId == itemData.InstanceId then
                return i
            end
        end
    end
end

function XTheatre5AdventureDataBase:GetSkillIndexInSkillBag(itemData)
    if self.BagData and self.BagData.SkillDict then
        for i, v in pairs(self.BagData.SkillDict) do
            if v.InstanceId == itemData.InstanceId then
                return i
            end
        end
    end
end

function XTheatre5AdventureDataBase:GetRuneIndexInRuneBag(itemData)
    if self.BagData and self.BagData.RuneDict then
        for i, v in pairs(self.BagData.RuneDict) do
            if v.InstanceId == itemData.InstanceId then
                return i
            end
        end
    end
end

--- 获取临时背包栏指定位置的物品数据
function XTheatre5AdventureDataBase:GetItemInTempBagByIndex(index)
    if self.BagData and self.BagData.TempItemDict then
        return self.BagData.TempItemDict[index]
    end
end

--获得一个背包的空位索引
function XTheatre5AdventureDataBase:GetEmptyBagIndex()
    local totalCount = self:GetBagGridsNum()
    if not XTool.IsNumberValid(totalCount) then
        return
    end
    if not self.BagData then
        return 1
    end
    if XTool.IsTableEmpty(self.BagData.BagItemDict) then
        return 1
    end
    for i = 1, totalCount do
        if not self.BagData.BagItemDict[i] then
            return i
        end
    end
end

--- 判断背包是否有空位
function XTheatre5AdventureDataBase:CheckHasEmptyBagSlot()
    local index = self:GetEmptyBagIndex()

    return XTool.IsNumberValid(index)
end

--获得一个技能的空位索引
function XTheatre5AdventureDataBase:GetEmptyBagSkillIndex()
    local totalCount = self:GetBagSkillGridsNum()
    if not XTool.IsNumberValid(totalCount) then
        return
    end
    if not self.BagData or XTool.IsTableEmpty(self.BagData.SkillDict) then
        return 1
    end
    local hasCount = XTool.GetTableCount(self.BagData.SkillDict)
    if totalCount == hasCount then
        return
    end
    for i = 1, totalCount do
        if not self.BagData.SkillDict[i] then
            return i
        end
    end
end

--- 判断技能栏是否有空位
function XTheatre5AdventureDataBase:CheckHasEmptySkillSlot()
    local index = self:GetEmptyBagSkillIndex()

    return XTool.IsNumberValid(index)
end

--获得一个装备(宝珠)的空位索引
function XTheatre5AdventureDataBase:GetEmptyBagRuneIndex()
    local totalCount = self:GetBagRuneGridsNum()
    if not XTool.IsNumberValid(totalCount) then
        return
    end
    if not self.BagData or XTool.IsTableEmpty(self.BagData.RuneDict) then
        return 1
    end
    local hasCount = XTool.GetTableCount(self.BagData.RuneDict)
    if totalCount == hasCount then
        return
    end
    for i = 1, totalCount do
        if not self.BagData.RuneDict[i] then
            return i
        end
    end
end

function XTheatre5AdventureDataBase:GetRuneDict()
    if self.BagData then
        return self.BagData.RuneDict
    end
end

--- 判断装备栏是否有空位
function XTheatre5AdventureDataBase:CheckHasEmptyRuneSlot()
    local index = self:GetEmptyBagRuneIndex()

    return XTool.IsNumberValid(index)
end

--- 获取技能栏指定位置的物品数据
function XTheatre5AdventureDataBase:GetItemInSkillListByIndex(index)
    if self.BagData and self.BagData.SkillDict then
        return self.BagData.SkillDict[index]
    end
end

--- 获取玩家自身的技能Id列表
function XTheatre5AdventureDataBase:GetSkillIdsInSkillList()
    -- 转换成有序列表
    local skillIds = {}

    if self.BagData then
        for i = 1, self.BagData.SkillGridsNum do

            local skillData = self:GetItemInSkillListByIndex(i)

            if skillData then
                table.insert(skillIds, skillData.ItemId)
            end
        end
    end

    return skillIds
end

--- 获取宝珠栏指定位置的物品数据
function XTheatre5AdventureDataBase:GetItemInRuneListByIndex(index)
    if self.BagData and self.BagData.RuneDict then
        return self.BagData.RuneDict[index]
    end
end

--- 获取宝珠栏宝珠Id的列表（合并同类宝珠）
function XTheatre5AdventureDataBase:GetRuneIdsInSkillList(ignoreSame)
    -- 转换成有序列表
    local runeIds = {}

    for i = 1, self.BagData.RuneGridsNum do
        local runeData = self:GetItemInRuneListByIndex(i)

        if runeData then
            if ignoreSame then
                --table.insert(runeIds, runeData.ItemId)
                table.insert(runeIds, { ItemId = runeData.ItemId, ItemType = XMVCA.XTheatre5:GetTheatre5ItemTypeById(runeData.ItemId), Index = i, IsStrengthen = runeData.IsStrengthen })
            else
                if not runeIds[runeData.ItemId] then
                    runeIds[runeData.ItemId] = { ItemId = runeData.ItemId, ItemType = XMVCA.XTheatre5:GetTheatre5ItemTypeById(runeData.ItemId), Index = i, IsStrengthen = runeData.IsStrengthen }
                end
            end
        end
    end

    return runeIds
end

--- 判断玩家是否穿戴宝珠
function XTheatre5AdventureDataBase:CheckHasEquipGem()
    return not XTool.IsTableEmpty(self.BagData.RuneDict)
end

--- 判断玩家是否穿戴技能
function XTheatre5AdventureDataBase:CheckHasEquipSkill()
    return not XTool.IsTableEmpty(self.BagData.SkillDict)
end

--- 检查背包指定容器是否已经有物品
function XTheatre5AdventureDataBase:CheckHasItemByContainerTypeAndIndex(containerType, index)
    if containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock then
        return self:GetItemInBagByIndex(index) and true or false
    elseif containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock then
        return self:GetItemInRuneListByIndex(index) and true or false
    elseif containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillBlock then
        return self:GetItemInSkillListByIndex(index) and true or false
    elseif containerType == XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock then
        return self:GetItemInTempBagByIndex(index) and true or false
    else
        return false
    end
end

--检查是否有装备或技能
function XTheatre5AdventureDataBase:CheckHasEquipOrSkill(itemType, itemId)
    if not self.BagData then
        return false
    end
    local has = self:_CheckHasEquipOrSkillByContainer(self.BagData.BagItemDict, itemType, itemId)
    if has then
        return true
    end
    has = self:_CheckHasEquipOrSkillByContainer(self.BagData.RuneDict, itemType, itemId)
    if has then
        return true
    end
    has = self:_CheckHasEquipOrSkillByContainer(self.BagData.SkillDict, itemType, itemId)
    if has then
        return true
    end
    has = self:_CheckHasEquipOrSkillByContainer(self.BagData.TempItemDict, itemType, itemId)
    if has then
        return true
    end
    return false
end

function XTheatre5AdventureDataBase:_CheckHasEquipOrSkillByContainer(container, itemType, itemId)
    if XTool.IsTableEmpty(container) then
        return false
    end
    for k, theatre5Item in pairs(container) do
        if theatre5Item.ItemType == itemType and theatre5Item.ItemId == itemId then
            return true
        end
    end
    return false
end

--- 获取背包栏已有物品数
function XTheatre5AdventureDataBase:GetBagListItemCount()
    return XTool.GetTableCount(self.BagData.BagItemDict)
end

--- 获取未进行背包格子解锁的回合数
function XTheatre5AdventureDataBase:GetRoundNumWithoutGridUnlock()
    return self.BagData and self.BagData.RoundNumWithoutGridUnlock or 0
end

--- 获取当前背包格子解锁费用扣除量(派生类重写）
function XTheatre5AdventureDataBase:GetCurRoundGridUnlockCostReduce()
    return 0
end

--装备初始格子数
function XTheatre5AdventureDataBase:GetRuneGridInitCount()
    return 0
end
--endregion

--region 商店信息

--- 商店数据全量更新（局内）
function XTheatre5AdventureDataBase:UpdateFullShopData(shopData)
    if XMain.IsEditorDebug then
        if self.ShopData then
            self.ShopData.IsObsolete = true

            if not XTool.IsTableEmpty(self.ShopData.Goods) then
                for i, v in pairs(self.ShopData.Goods) do
                    v.IsObsolete = true
                    v.ItemInfo.IsObsolete = true
                end
            end
        end
    end

    self.ShopData = shopData
    self.HasData = true
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_REFRESH_LEVEL_EXP)
end

function XTheatre5AdventureDataBase:UpdateShopGoodsByReplaced(replaceShopGoods)
    if not XTool.IsTableEmpty(replaceShopGoods) then
        for index, goods in pairs(replaceShopGoods) do
            local oldGoods = self.ShopData.Goods[index]

            if oldGoods then
                oldGoods.IsObsolete = true
                oldGoods.ItemInfo.IsObsolete = true
            end

            self.ShopData.Goods[index] = goods
        end
        
        XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_REFRESH_STORE_SHOW)
    end
end

function XTheatre5AdventureDataBase:GetShopId()
    return self.ShopData and self.ShopData.ShopId or 0
end

function XTheatre5AdventureDataBase:GetShopUnlockGridsNum()
    return self.ShopData and self.ShopData.UnlockGridsNum or 0
end

function XTheatre5AdventureDataBase:GetShopRefreshTimes()
    return self.ShopData and self.ShopData.RefreshCnt or 0
end

function XTheatre5AdventureDataBase:GetShopGoods()
    return self.ShopData and self.ShopData.Goods or nil
end

function XTheatre5AdventureDataBase:GetShopGoodsByIndex(index)
    if self.ShopData and self.ShopData.Goods then
        return self.ShopData.Goods[index]
    end
end

function XTheatre5AdventureDataBase:GetShopGoodsByItemInstanceId(instanceId)
    if self.ShopData and self.ShopData.Goods then
        for i, v in pairs(self.ShopData.Goods) do
            if v.ItemInfo.InstanceId == instanceId then
                return v
            end
        end
    end
end

--- 判断是否所有商品都冻结
function XTheatre5AdventureDataBase:CheckAllGoodsIsFreeze()
    if not XTool.IsTableEmpty(self.ShopData.Goods) then
        local anyGoodsNoSoldOut = false;

        for i, v in pairs(self.ShopData.Goods) do
            if not v.IsSoldOut then
                anyGoodsNoSoldOut = true

                if not v.IsFreeze then
                    return false
                end
            end
        end

        if anyGoodsNoSoldOut then
            return true
        else
            return false
        end
    else
        return false
    end
end

--- 判断是否有空的商品格
function XTheatre5AdventureDataBase:CheckHasAnyGoodsIsSellOut()
    if not XTool.IsTableEmpty(self.ShopData.Goods) then
        for i, v in pairs(self.ShopData.Goods) do
            if v.IsSoldOut then
                return true
            end
        end

        return false
    else
        return true
    end
end

--- 判断是否所有商品都卖出
function XTheatre5AdventureDataBase:CheckAllGoodsAreSellOut()
    if not XTool.IsTableEmpty(self.ShopData.Goods) then
        for i, v in pairs(self.ShopData.Goods) do
            if not v.IsSoldOut then
                return false
            end
        end

        return true
    else
        return true
    end
end
--endregion

--region 技能三选一

--- 技能三选一数据全量更新
function XTheatre5AdventureDataBase:UpdateFullSkillChoiceData(skillChoiceData)
    if XMain.IsEditorDebug then
        if self.SkillChoiceData then
            self.SkillChoiceData.IsObsolete = true

            if not XTool.IsTableEmpty(self.SkillChoiceData.SkillGroups) then
                for i, v in pairs(self.SkillChoiceData.SkillGroups) do
                    v.IsObsolete = true
                end
            end
        end
    end

    self.SkillChoiceData = skillChoiceData
    self.HasData = true
end

function XTheatre5AdventureDataBase:GetSkillChoiceSkillGroup()
    return self.SkillChoiceData and self.SkillChoiceData.SkillGroups or nil
end

--endregion

--region 角色属性加成
function XTheatre5AdventureDataBase:UpdateCharacterStatusAdds(addsMap)
    self._AttrAddsMap = addsMap
    self._AttrAddsNeedUpdate = false
end

function XTheatre5AdventureDataBase:GetAttrAddsByAttrType(attrType)
    if not XTool.IsTableEmpty(self._AttrAddsMap) then
        return self._AttrAddsMap[attrType] or 0
    end
    return 0
end

function XTheatre5AdventureDataBase:SetNeedUpdateAdds()
    self._AttrAddsNeedUpdate = true
end

function XTheatre5AdventureDataBase:GetIsNeedUpdateAdds()
    return self._AttrAddsNeedUpdate
end

--endregion

--region 敌人数据

function XTheatre5AdventureDataBase:GetEnemySkillIds()

end

--- 获取敌人宝珠栏宝珠Id的列表（合并同类宝珠）
function XTheatre5AdventureDataBase:GetEnemyRuneIds()

end

function XTheatre5AdventureDataBase:GetEnemyCharacterId()

end

--endregion

--region v4.0 二期新增
-- 角色等级
function XTheatre5AdventureDataBase:GetCharacterLevel()
    return self.CharacterLv
end

-- 角色经验值
function XTheatre5AdventureDataBase:GetCharacterExp()
    return self.CharacterExp
end

-- 随机遗物
function XTheatre5AdventureDataBase:GetRandomRelics()
    return self.RandomRelics
end

-- 已经使用的遗物刷新次数
function XTheatre5AdventureDataBase:GetUseRelicRefreshCount()
    return self.UseRelicRefreshCount
end

-- V4.0新增:上局胜利可免费解锁一个格子,前端需要播放动画
function XTheatre5AdventureDataBase:GetIsCanFreeUnlockGrid()
    return self.IsCanFreeUnlockGrid
end

function XTheatre5AdventureDataBase:UpdateIsCanFreeUnlockGrid(value)
    self.IsCanFreeUnlockGrid = value
end

-- 进入商店次数
function XTheatre5AdventureDataBase:GetEnterShopCnt()
    return self.EnterShopCnt
end

-- 离开商店次数
function XTheatre5AdventureDataBase:GetLeaveShopCnt()
    return self.LeaveShopCnt
end

-- 效果队列: 里面存放一些需要客户端播放的效果, 播放结束之后, 清空
function XTheatre5AdventureDataBase:GetEffectQueue()
    return self.EffectQueue
end

function XTheatre5AdventureDataBase:GetGameMode()
    return self._GameMode
end

-- 来自服务端的更新
function XTheatre5AdventureDataBase:UpdateCharacterLevelData(characterLevelUpResponse)
    self:UpdateCharacterLevel(characterLevelUpResponse.CharacterLv)
    self:UpdateCharacterExp(characterLevelUpResponse.CharacterExp)
    self:UpdateCurPlayStatus(characterLevelUpResponse.Status)
    self:UpdateRelicUseRefreshCount(characterLevelUpResponse.UseRefreshCount)
    self:UpdateRandomRelics(characterLevelUpResponse.RandomRelics)
end

function XTheatre5AdventureDataBase:UpdateCharacterLevel(value)
    self.CharacterLv = value
end

function XTheatre5AdventureDataBase:UpdateCharacterExp(value, triggerInterruptEvent)
    self.CharacterExp = value

    if triggerInterruptEvent ~= false then
        -- 触发升级检测
        XMVCA.XTheatre5:TriggerInterruptEvent()
    end
end

function XTheatre5AdventureDataBase:UpdateRelicUseRefreshCount(value)
    self.UseRelicRefreshCount = value
end

function XTheatre5AdventureDataBase:UpdateRandomRelics(value)
    if not value then
        XLog.Error("[XTheatre5AdventureDataBase] 更新随机饰品列表，但是它的内容为空")
    end
    self.RandomRelics = value
end

function XTheatre5AdventureDataBase:UpdateEffectFreeRefreshCnt(value)
    self.EffectFreeRefreshCnt = value
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE5_REFRESH_STORE_SHOW)
end

function XTheatre5AdventureDataBase:GetEffectFreeRefreshCnt()
    return self.EffectFreeRefreshCnt
end

function XTheatre5AdventureDataBase:UpdateEnterShopCnt(value)
    self.EnterShopCnt = value
end

function XTheatre5AdventureDataBase:UpdateLeaveShopCnt(value)
    self.LeaveShopCnt = value
end

function XTheatre5AdventureDataBase:UpdateRuneAutoStrengthenCnt(value)
    self.RuneAutoStrengthenCnt = value
end

function XTheatre5AdventureDataBase:UpdateEffectQueue(value)
    self.EffectQueue = value
end

function XTheatre5AdventureDataBase:ClearEventData()
    if not XTool.IsTableEmpty(self._TempBuffList) then
        self._TempBuffList = {}
    end
    if not XTool.IsTableEmpty(self._TempAttrList) then
        self._TempAttrList = {}
    end
end

-- 进入战斗时获得的buff，只在单次战斗生效
-- 实际上是magicId
function XTheatre5AdventureDataBase:AddBuff(buffList)
    for i = 1, #buffList do
        local buffId = buffList[i]
        self._TempBuffList[#self._TempBuffList + 1] = buffId
    end
end

function XTheatre5AdventureDataBase:GetTempBuffList()
    return self._TempBuffList
end

-- 进入战斗时获得的属性，只在单次战斗生效
function XTheatre5AdventureDataBase:AddCharacterAttr(attr)
    self._TempAttrList[#self._TempAttrList + 1] = attr
end

function XTheatre5AdventureDataBase:GetTempAttrList()
    return self._TempAttrList
end

-- 此参数来自服务端的XAutoChessGameplayResult，战斗结算时处理
---@param autoChessGameplayResult XAutoChessGameplayResult
function XTheatre5AdventureDataBase:HandleAutoChessGameplayResult(autoChessGameplayResult)
    -- 战斗结算时，不触发升级检查
    self:UpdateCharacterExp(self:GetCharacterExp() + autoChessGameplayResult.AddExp, false)
    self:UpdateIsCanFreeUnlockGrid(autoChessGameplayResult.IsCanFreeUnlockGrid)
end

function XTheatre5AdventureDataBase:GetRelicDict()
    if self.BagData then
        return self.BagData.RelicDict
    end
    XLog.Error("[XTheatre5AdventureDataBase] bagData is empty")
    return {}
end

function XTheatre5AdventureDataBase:GetRelicOrders()
    return self.RelicOrders
end

---@return XTheatre5Item
function XTheatre5AdventureDataBase:GetRelicById(instanceId)
    if self.BagData then
        return self.BagData.RelicDict[instanceId]
    end
end

--endregion

--region v4.2 任务

function XTheatre5AdventureDataBase:UpdateFreshMissionCnt(cnt, positionId)
    if self.FreshMissionCounts == nil then
        self.FreshMissionCounts = {}
    end
    
    self.FreshMissionCounts[positionId] = cnt
end

function XTheatre5AdventureDataBase:UpdateChooseMissions(missions)
    if XMain.IsEditorDebug then
        if self.ChooseMissions then
            setmetatable(self.ChooseMissions, self._ObsoleteMeta)
        end
    end

    self.ChooseMissions = missions
end

function XTheatre5AdventureDataBase:UpdateMissionInChoose(pos, mission)
    if self.ChooseMissions == nil then
        self.ChooseMissions = {}
    end

    if XMain.IsEditorDebug then
        local oldMission = self.ChooseMissions[pos]

        if oldMission and self._ObsoleteMeta then
            setmetatable(oldMission, self._ObsoleteMeta)
        end
    end

    self.ChooseMissions[pos] = mission
end

function XTheatre5AdventureDataBase:UpdateCurMissioning(mission)
    if XMain.IsEditorDebug then
        if self.Missioning and self._ObsoleteMeta then
            setmetatable(self.Missioning, self._ObsoleteMeta)
        end
    end

    self.Missioning = mission
end

function XTheatre5AdventureDataBase:UpdateCurMissionLevel(newLevel)
    if self.Missioning then
        self.Missioning.MissionBounty.BountyLevel = newLevel
    end
end

function XTheatre5AdventureDataBase:UpdateCurMissionState(newState)
    if self.Missioning then
        self.Missioning.MissionState = newState
    end
end

function XTheatre5AdventureDataBase:UpdateCurMissionGetItemId(itemId)
    if self.Missioning then
        self.Missioning.MissionRelicId = itemId
    end
end

function XTheatre5AdventureDataBase:UpdateChooseMissionBounty(missions)
    self.ChooseMissionBounty = missions
end

function XTheatre5AdventureDataBase:UpdateMissionLevelUpForRound(missionLevelUpForRound)
    self.MissionLevelUpForRound = missionLevelUpForRound
end

function XTheatre5AdventureDataBase:ClearChooseMissionsAfterEndChoose()
    self.ChooseMissions = nil
    self.FreshMissionCounts = nil
    self.FreshMissionBounty = nil
    self.FreshMissionCondition = nil
end

function XTheatre5AdventureDataBase:GetChooseMissions()
    return self.ChooseMissions
end

function XTheatre5AdventureDataBase:HasChooseMissions()
    return not XTool.IsTableEmpty(self.ChooseMissions)
end

function XTheatre5AdventureDataBase:GetChooseMissionByPos(pos)
    if not XTool.IsTableEmpty(self.ChooseMissions) then
        return self.ChooseMissions[pos]
    end
end

function XTheatre5AdventureDataBase:GetFreshCountByPos(pos)
    if not XTool.IsTableEmpty(self.FreshMissionCounts) then
        return self.FreshMissionCounts[pos] or 0
    end
    
    return 0
end

function XTheatre5AdventureDataBase:GetCurMission()
    return self.Missioning
end

function XTheatre5AdventureDataBase:CheckHasBounty(bounty)
    if XTool.IsTableEmpty(self.ChooseMissionBounty) then
        return false
    end
    
    return table.contains(self.ChooseMissionBounty, bounty)
end

function XTheatre5AdventureDataBase:GetMissionLevelUpForRound()
    return self.MissionLevelUpForRound
end

--endregion

return XTheatre5AdventureDataBase