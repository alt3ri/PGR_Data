--- 局内控制器
---@class XPBRInGameControl : XControl
---@field private _Model XPBRGameModel
---@field _MainControl XPBRGameControl
local XPBRInGameControl = XClass(XControl, "XPBRInGameControl")

function XPBRInGameControl:OnInit()

end

function XPBRInGameControl:AddAgencyEvent()

end

function XPBRInGameControl:RemoveAgencyEvent()

end

function XPBRInGameControl:OnRelease()

end

--- 检查指定道具是否已拥有，如果拥有，返回下一阶的道具Id
function XPBRInGameControl:CheckIsHasItemAndGetNextItemId(itemId)
    if self._Model:CheckIsHasItemInSegmentSettleData(itemId) then
        -- 获取该道具配置，检查它的组内比自己高一级的道具Id
        local itemCfg = self._Model:GetTablePBRItemCfgById(itemId)

        if itemCfg and XTool.IsNumberValidEx(itemCfg.OrbGroup) then
            local itemGroupCfg = self._Model:GetTablePBRItemGroupCfgById(itemCfg.OrbGroup)

            if itemGroupCfg and not XTool.IsTableEmpty(itemGroupCfg.ItemIds) then
                for _, id in pairs(itemGroupCfg.ItemIds) do
                    if id ~= itemId then
                        local otherItemCfg = self._Model:GetTablePBRItemCfgById(id)
                        if otherItemCfg and (otherItemCfg.ItemTier - itemCfg.ItemTier) == 1 then
                            return true, id
                        end
                    end

                end
            end
        end
    end

    return false
end

--- 检查商店中的高阶技能是否可以替换玩家已拥有的同组低阶技能
--- 用于商店显示替换升阶提示：当商店刷出高阶技能，玩家拥有同组低阶技能时返回true
---@param shopItemId number 商店中的道具Id
---@return boolean, number|nil @是否可替换升阶，玩家拥有的低阶道具Id
function XPBRInGameControl:CheckItemIsHigherThanOwnedSkill(shopItemId)
    local shopItemCfg = self._Model:GetTablePBRItemCfgById(shopItemId)

    if not shopItemCfg or shopItemCfg.ItemType ~= XMVCA.XPBRGame.EnumConst.ItemType.Skill then
        return false
    end

    if not XTool.IsNumberValidEx(shopItemCfg.OrbGroup) then
        return false
    end

    local itemGroupCfg = self._Model:GetTablePBRItemGroupCfgById(shopItemCfg.OrbGroup)

    if not itemGroupCfg or XTool.IsTableEmpty(itemGroupCfg.ItemIds) then
        return false
    end

    -- 遍历同组所有道具，检查玩家是否拥有比自己低阶的技能
    for _, id in pairs(itemGroupCfg.ItemIds) do
        if id ~= shopItemId then
            local ownedItemCfg = self._Model:GetTablePBRItemCfgById(id)
            if ownedItemCfg and (shopItemCfg.ItemTier - ownedItemCfg.ItemTier) >= 1 then
                -- 检查玩家是否拥有这个低阶技能
                if self._Model:CheckIsHasItemInSegmentSettleData(id) then
                    return true, id
                end
            end
        end
    end

    return false
end

--- 检查商店中是否有可以替换玩家已拥有技能的同组高阶技能
--- 用于已拥有技能UI显示升阶提示：接收已拥有技能ItemId，查找商店中是否有同组高阶技能
---@param ownedItemId number 玩家已拥有的技能道具Id
---@return boolean, number|nil @是否存在高阶技能，商店中高阶技能的道具Id
function XPBRInGameControl:CheckShopHasHigherTierSkillForOwned(ownedItemId)
    local ownedItemCfg = self._Model:GetTablePBRItemCfgById(ownedItemId)

    if not ownedItemCfg or ownedItemCfg.ItemType ~= XMVCA.XPBRGame.EnumConst.ItemType.Skill then
        return false
    end

    if not XTool.IsNumberValidEx(ownedItemCfg.OrbGroup) then
        return false
    end

    local sellItemIds = self:GetShopSellItemIds()

    if XTool.IsTableEmpty(sellItemIds) then
        return false
    end

    -- 遍历商店道具，查找同组高阶技能
    for _, sellItemId in pairs(sellItemIds) do
        -- 跳过已选择的道具
        if not self:GetIsItemChoseByItemId(sellItemId) then
            local sellItemCfg = self._Model:GetTablePBRItemCfgById(sellItemId)

            if sellItemCfg and sellItemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Skill then
                -- 同组且阶数更高
                if sellItemCfg.OrbGroup == ownedItemCfg.OrbGroup and sellItemCfg.ItemTier > ownedItemCfg.ItemTier then
                    return true, sellItemId
                end
            end
        end
    end

    return false
end

--- 将局内已拥有的道具Id按照道具类型分类后返回
---@return table<number, table<number>> key:道具类型 value:道具Id列表
function XPBRInGameControl:GetOwnedItemIdsByType()
    local ownedItemData = self._Model:GetAllItemsInSegmentSettleData()
    
    return self:GetItemIdsFromItemDatasByType(ownedItemData, true)
end

--- 将道具按照类型分类、排序后返回
---@param itemDatas table<number, PbrItem>
---@return table<number, table<PbrItem>> key:道具类型 value:道具Id列表
function XPBRInGameControl:GetItemIdsFromItemDatasByType(itemDatas, isSort)
    local itemTypeDict = {}

    if not XTool.IsTableEmpty(itemDatas) then
        for _, itemData in pairs(itemDatas) do
            local itemCfg = self._Model:GetTablePBRItemCfgById(itemData.ItemId)

            if itemCfg then
                local itemType = itemCfg.ItemType

                if not itemTypeDict[itemType] then
                    itemTypeDict[itemType] = {}
                end

                table.insert(itemTypeDict[itemType], itemData)
            end
        end

        -- 按照获得时间排序、id小的在前
        if isSort and not XTool.IsTableEmpty(itemTypeDict) then
            for itemType, itemList in pairs(itemTypeDict) do
                table.sort(itemList, function(itemDataA, itemDataB)
                    if itemDataA and itemDataB then
                        if itemDataA.UnlockTime ~= itemDataB.UnlockTime then
                            return itemDataA.UnlockTime < itemDataB.UnlockTime
                        end
                    end

                    return itemDataA.ItemId < itemDataB.ItemId
                end)
            end
        end
    end

    return itemTypeDict
end

--- 获取当前暂离局内的关卡Id和角色Id，用于返回局内
function XPBRInGameControl:GetCurrentLeaveStageAndCharId()
    return self._Model:GetStageIdInSegmentSettleData(), self._Model:GetCharacterIdInSegmentSettleData()
end

--- 获取局内当前波次
function XPBRInGameControl:GetWaveInSegmentSettleData()
    return self._Model:GetWaveInSegmentSettleData()
end

function XPBRInGameControl:GetSegmentSettleData()
    return self._Model:GetSegmentSettleData()
end

--- 获取当前已刷新次数及刷新次数上限
---@return number, number @curCount, maxCount
function XPBRInGameControl:GetShopRefreshCount()
    local segmentData = self._Model:GetSegmentSettleData()
    if segmentData and segmentData.ShopData then
        return segmentData.ShopData.UseFreshCount or 0, segmentData.ShopData.MaxFreshCount
    end
end

--- 获取当前已选择次数及选择次数上限
function XPBRInGameControl:GetShopSelectCount()
    local segmentData = self._Model:GetSegmentSettleData()
    if segmentData and segmentData.ShopData then
        return segmentData.ShopData.UseChooseCount or 0, segmentData.ShopData.MaxChooseCount or 0
    end
end

function XPBRInGameControl:GetShopLeftSelectCount()
    local segmentData = self._Model:GetSegmentSettleData()
    if segmentData and segmentData.ShopData then
        local useChooseCount = segmentData.ShopData.UseChooseCount or 0
        local maxChooseCount = segmentData.ShopData.MaxChooseCount or 0
        return maxChooseCount - useChooseCount
    end
end

function XPBRInGameControl:GetIsShopHasChooseTimes()
    return self._Model:GetIsShopHasChooseTimes()
end

--- 获取当前的商品
function XPBRInGameControl:GetShopSellItemIds()
    local segmentData = self._Model:GetSegmentSettleData()

    if segmentData and segmentData.ShopData then
        return segmentData.ShopData.SellItems
    end
end

--- 获取商店数据
function XPBRInGameControl:GetShopData()
    local segmentData = self._Model:GetSegmentSettleData()

    if segmentData and segmentData.ShopData then
        return segmentData.ShopData
    end
end

--- 判断当前商店指定道具Id是否已选择
function XPBRInGameControl:GetIsItemChoseByItemId(itemId)
    return self._Model:GetIsItemChoseByItemId(itemId)
end

--- 判断当前售卖的道具中是否有指定道具
function XPBRInGameControl:GetIsHasItemInSellsByItemId(itemId)
    local sellItems = self:GetShopSellItemIds()

    if not XTool.IsTableEmpty(sellItems) then
        for i, v in pairs(sellItems) do
            if v == itemId then
                return true
            end
        end
    end
    
    return false
end

--- 在商店里选择一个道具，需要在请求前做额外的判断
---@param cb fun(success: boolean)
function XPBRInGameControl:TrySelectItem(itemId, cb)
    if not XTool.IsNumberValidEx(itemId) then
        if cb then
            cb(false)
        end
        return
    end
    
    local itemCfg = self._Model:GetTablePBRItemCfgById(itemId)

    if not itemCfg then
        if cb then
            cb(false)
        end
        return
    end

    -- 判断是否有选择次数
    if not self._Model:GetIsShopHasChooseTimes() then
        XUiManager.TipMsg(self._Model:GetClientPBRText('ShopNoChooseTimesTips'))
        return
    end

    -- 判断该道具是否已经选择了
    if self._Model:GetIsItemChoseByItemId(itemId) then
        XUiManager.TipMsg(self._Model:GetClientPBRText('ShopSelectChoseItemTips'))
        return
    end

    if itemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Skill then
        local items = self._Model:GetAllItemsInSegmentSettleData()
        local hasSameColorDiffGroupSkill = false
        local oldItemId = nil
        
        if not XTool.IsTableEmpty(items) then
            for i, v in pairs(items) do
                local tempItemCfg = self._Model:GetTablePBRItemCfgById(v.ItemId)

                if tempItemCfg and tempItemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Skill and tempItemCfg.OrbColor == itemCfg.OrbColor then
                    -- 判断是否同组
                    if itemCfg.OrbGroup ~= tempItemCfg.OrbGroup then
                        hasSameColorDiffGroupSkill = true
                        oldItemId = tempItemCfg.ItemId
                        break
                    end
                end
            end
        end

        if hasSameColorDiffGroupSkill then
            -- 提示会替换
            XLuaUiManager.Open("UiPBRPopupSkillReplace", oldItemId, itemId, function()
                XMVCA.XPBRGame.NetworkAgency:DoPbrShopChooseRequest(itemId, cb)
            end)
            return
        end
    end
    
    
    XMVCA.XPBRGame.NetworkAgency:DoPbrShopChooseRequest(itemId, cb)
end

--- 清空商店数据
function XPBRInGameControl:ClearShopData()
    self._Model:ClearShopData()
end

function XPBRInGameControl:GetCurSelectCharId()
    return self._Model:GetCurSelectCharId()
end

--- 获取局内玩家属性（战斗外）
function XPBRInGameControl:GetCharacterAttribs()
    local segmentSettleData = self._Model:GetSegmentSettleData()

    if segmentSettleData then
        return segmentSettleData.CurAttrs
    end
end

--- 获取局内玩家属性（战斗外）
function XPBRInGameControl:GetCharacterMaxAttribs()
    local segmentSettleData = self._Model:GetSegmentSettleData()

    if segmentSettleData then
        return segmentSettleData.MaxAttrs
    end
end

function XPBRInGameControl:ContinueGame()
    -- 如果有商店数据，就进商店，否则进战斗
    local stageId, characterId = self:GetCurrentLeaveStageAndCharId()
    
    if self._Model:GetIsHasShopData() then
        XLuaUiManager.Open('UiPBRShopNew', stageId)
    else
        if XTool.IsNumberValidEx(stageId) and XTool.IsNumberValidEx(characterId) then
            self._MainControl:SetCurSelectCharId(characterId)

            XMVCA.XFuben:EnterFightByStageId(stageId, nil, false, 1, nil)
        end
    end
end

--- 新一局刚开始时客户端本地构造的缓存. 只构造需要的数据，其他的等服务端下发
function XPBRInGameControl:SetSegmentSettleDataCacheInBegin(stageId, characterId, force)
    -- 清空商店弹窗屏蔽缓存
    self._Model:SetShopSelectGiveupIgnorePopup(nil)

    self._Model:SetSegmentSettleDataCacheInBegin(stageId, characterId, force)
end

function XPBRInGameControl:SetFightExitType(type)
    self._Model:SetFightExitType(type)
end

function XPBRInGameControl:GetFightExitType()
    return self._Model:GetFightExitType()
end

--- 判断当前波次是否是无尽模式
function XPBRInGameControl:CheckIsInEndlessMode()
    local stageId = self._Model:GetStageIdInSegmentSettleData()

    if not XTool.IsNumberValidEx(stageId) then
        return false
    end
    
    local stageCfg = self._Model:GetTablePBRStageCfgById(stageId)
    
    if stageCfg and stageCfg.StageType == XMVCA.XPBRGame.EnumConst.StageCustomType.Challenge then
        local wave = self._Model:GetWaveInSegmentSettleData()
        
        return XTool.IsNumberValidEx(wave) and wave > stageCfg.FinishWaves
    end
end

--region 商店弹窗提示控制

function XPBRInGameControl:GetIsShopSelectGiveupIgnorePopup()
    return self._Model:GetIsShopSelectGiveupIgnorePopup()
end

function XPBRInGameControl:SetShopSelectGiveupIgnorePopup(isIgnore)
   self._Model:SetShopSelectGiveupIgnorePopup(isIgnore) 
end

--endregion

--region Configs

---@return XTablePBRMonsterWave
function XPBRInGameControl:GetTablePBRMonsterWaveCfgById(waveId, notips)
    return self._Model:GetTablePBRMonsterWaveCfgById(waveId, notips)
end

--endregion

return XPBRInGameControl