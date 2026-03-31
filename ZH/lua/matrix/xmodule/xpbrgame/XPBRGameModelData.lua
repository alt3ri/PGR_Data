--- 定义所有的玩法数据访问接口
---@type XPBRGameModel
local XPBRGameModel = XClassPartial("XPBRGameModel")

--region Getter

function XPBRGameModel:GetActivityId()
    return self.ActivityDb and self.ActivityDb.ActivityId or 0
end

function XPBRGameModel:GetIsHasSegmentSettleData()
    if not self.ActivityDb then
        return false
    end

    if not self.ActivityDb.SegmentSettleData then
        return false
    end
    
    return true
end

---@return PbrStageRecord
function XPBRGameModel:GetStageRecordById(stageId)
    if self.ActivityDb and self.ActivityDb.StageRecords then
        return self.ActivityDb.StageRecords[stageId]
    end
end

--- 判断局内是否已拥有指定道具
function XPBRGameModel:CheckIsHasItemInSegmentSettleData(itemId)
    if self.ActivityDb and self.ActivityDb.SegmentSettleData then
        local gameData = self.ActivityDb.SegmentSettleData

        if not XTool.IsTableEmpty(gameData.Items) then
            return gameData.Items[itemId] and true or false
        end
    end
    
    return false
end

--- 获取局内已获得的所有道具数据
function XPBRGameModel:GetAllItemsInSegmentSettleData()
    if self.ActivityDb and self.ActivityDb.SegmentSettleData then
        local gameData = self.ActivityDb.SegmentSettleData

        return gameData.Items
    end

end

--- 获取局内关卡Id
function XPBRGameModel:GetStageIdInSegmentSettleData()
    if self.ActivityDb and self.ActivityDb.SegmentSettleData then
        local gameData = self.ActivityDb.SegmentSettleData
        return gameData.StageId
    end
end

--- 获取局内当前波次
function XPBRGameModel:GetWaveInSegmentSettleData()
    if self.ActivityDb and self.ActivityDb.SegmentSettleData then
        local gameData = self.ActivityDb.SegmentSettleData
        return gameData.Wave
    end
    
    return 0
end

--- 获取局内角色Id
function XPBRGameModel:GetCharacterIdInSegmentSettleData()
    if self.ActivityDb and self.ActivityDb.SegmentSettleData then
        local gameData = self.ActivityDb.SegmentSettleData
        return gameData.CharacterId
    end
end

--- 获取商店数据
function XPBRGameModel:GetIsHasShopData()
    if self.ActivityDb and self.ActivityDb.SegmentSettleData then
        local gameData = self.ActivityDb.SegmentSettleData
        return gameData.ShopData and true or false
    end
    
    return false
end

--- 获取局内数据
---@return PbrSegmentSettleData
function XPBRGameModel:GetSegmentSettleData()
    if self.ActivityDb then
        return self.ActivityDb.SegmentSettleData
    end
end

--- 获取商店当前剩余刷新次数
function XPBRGameModel:GetShopUseFreshCount()
    if self.ActivityDb and self.ActivityDb.SegmentSettleData and self.ActivityDb.SegmentSettleData.ShopData then
        return self.ActivityDb.SegmentSettleData.ShopData.UseFreshCount or 0
    end
end

--- 判断商店当前是否有剩余刷新次数
function XPBRGameModel:GetIsShopHasFreshTimes()
    local segmentData = self:GetSegmentSettleData()
    if segmentData and segmentData.ShopData then
        local useFreshCount = segmentData.ShopData.UseFreshCount or 0
        local maxFreshCount = segmentData.ShopData.MaxFreshCount or 0
        
        return useFreshCount < maxFreshCount
    end
end

--- 判断商店当前是否有剩余选择次数
function XPBRGameModel:GetIsShopHasChooseTimes()
    local segmentData = self:GetSegmentSettleData()
    if segmentData and segmentData.ShopData then
        local useChooseCount = segmentData.ShopData.UseChooseCount or 0
        local maxChooseCount = segmentData.ShopData.MaxChooseCount or 0

        return useChooseCount < maxChooseCount
    end
end

--- 判断当前商店指定道具Id是否已选择
function XPBRGameModel:GetIsItemChoseByItemId(itemId)
    -- 选择后立刻刷新，保留接口
    return false
end

--- 获取当前的商品
function XPBRGameModel:GetShopSellItemIds()
    local segmentData = self:GetSegmentSettleData()

    if segmentData and segmentData.ShopData then
        return segmentData.ShopData.SellItems
    end
end
--endregion


--region Setter

--- 全量更新活动数据
function XPBRGameModel:UpdateFUllActivityData(activityData)
    ---@type XPbrDataDb
    self.ActivityDb = activityData
end

--- 更新已解锁天赋节点缓存
function XPBRGameModel:SetUnlockStrengthNode(nodeId)
    if self.ActivityDb and self.ActivityDb.MetaProgression then
        local unlockNodes = self.ActivityDb.MetaProgression.UnlockNodes

        if unlockNodes == nil then
            unlockNodes = {}
        end

        if not table.contains(unlockNodes, nodeId) then
            table.insert(unlockNodes, nodeId)
        end

        self.ActivityDb.MetaProgression.UnlockNodes = unlockNodes
    end
end

function XPBRGameModel:UpdateFullSegmentSettleData(segmentSettleData)
    if self.ActivityDb then
        self.ActivityDb.SegmentSettleData = segmentSettleData
    end
end

--- 更新商店当前已刷新次数
function XPBRGameModel:SetShopUseFreshCount(useFreshCount)
    if self.ActivityDb and self.ActivityDb.SegmentSettleData and self.ActivityDb.SegmentSettleData.ShopData then
        self.ActivityDb.SegmentSettleData.ShopData.UseFreshCount = useFreshCount
    end
end

--- 更新商店当前货物列表
function XPBRGameModel:SetShopItemList(itemList)
    if self.ActivityDb and self.ActivityDb.SegmentSettleData and self.ActivityDb.SegmentSettleData.ShopData then
        self.ActivityDb.SegmentSettleData.ShopData.SellItems = itemList
    end
end

--- 更新商店当前已选择次数
function XPBRGameModel:SetShopUseChooseCount(useChooseCount)
    if self.ActivityDb and self.ActivityDb.SegmentSettleData and self.ActivityDb.SegmentSettleData.ShopData then
        self.ActivityDb.SegmentSettleData.ShopData.UseChooseCount = useChooseCount
    end
end

--- 更新角色道具栏
function XPBRGameModel:UpdateItemDataFromSelect(selectItemId, resultItemData, resultType)
    if not self.ActivityDb or not self.ActivityDb.SegmentSettleData then
        return
    end

    local gameData = self.ActivityDb.SegmentSettleData

    if gameData.Items == nil then
        gameData.Items = {}
    end
    
    if resultType == XMVCA.XPBRGame.EnumConst.GameShop.ChooseResultType.Addition then
        gameData.Items[resultItemData.ItemId] = resultItemData
    elseif resultType == XMVCA.XPBRGame.EnumConst.GameShop.ChooseResultType.Upgrade then
        -- 升阶是把原来同itemId的移除，添加新的
        gameData.Items[selectItemId] = nil
        gameData.Items[resultItemData.ItemId] = resultItemData
    elseif resultType == XMVCA.XPBRGame.EnumConst.GameShop.ChooseResultType.Replace then
        -- 替换是将原来同色不同组的itemId或者同色同组但低阶的ItemId移除
        local hasOldItem, id = false, nil
        local safeCounter = 10 -- 保底计数，防止意料之外的bug导致死循环

        local selectItemCfg = self:GetTablePBRItemCfgById(selectItemId)

        if not selectItemCfg then
            return
        end
        
        repeat
            safeCounter = safeCounter - 1
            hasOldItem, id = false, nil

            for itemId, itemData in pairs(gameData.Items) do
                local itemCfg = self:GetTablePBRItemCfgById(itemId)

                if itemCfg and itemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Skill then
                    if selectItemCfg.OrbColor == itemCfg.OrbColor then
                        local needRemove = false
                        
                        -- 同色不同组
                        if selectItemCfg.OrbGroup ~= itemCfg.OrbGroup then
                            needRemove = true
                        elseif selectItemCfg.ItemTier > itemCfg.ItemTier then
                            -- 同组低阶
                            needRemove = true
                        end
                        
                        if needRemove then
                            hasOldItem = true
                            id = itemId
                            break
                        end
                    end
                end
            end

            if hasOldItem then
                gameData.Items[id] = nil
            end

        until not hasOldItem or safeCounter < 0

        gameData.Items[resultItemData.ItemId] = resultItemData
    end
end

--- 清空商店数据缓存(客户端退出商店进入下一波需手动清缓存）
function XPBRGameModel:ClearShopData()
    if self.ActivityDb and self.ActivityDb.SegmentSettleData then
        local gameData = self.ActivityDb.SegmentSettleData
        gameData.ShopData = nil
    end
end

--- 新一局刚开始时客户端本地构造的缓存. 只构造需要的数据，其他的等服务端下发
function XPBRGameModel:SetSegmentSettleDataCacheInBegin(stageId, characterId, force)
    if self.ActivityDb then
        if force or not self.ActivityDb.SegmentSettleData then
            self.ActivityDb.SegmentSettleData = {
                StageId = stageId,
                Wave = 1,
                CharacterId = characterId,
            }
        end
    end
end

--- 本地改关卡进度缓存
function XPBRGameModel:SetStageProgressByStageId(stageId, newHistoryMaxWave)
    if self.ActivityDb and self.ActivityDb.StageRecords then
        local stageRecord = self.ActivityDb.StageRecords[stageId]

        if not stageRecord then
            -- 如果没有该关卡数据，先本地构造一下
            stageRecord = {}
            stageRecord.StageId = stageId
            
            self.ActivityDb.StageRecords[stageId] = stageRecord
        end

        stageRecord.HistoryMaxWave = newHistoryMaxWave
    end
end

--- 更新关卡数据
function XPBRGameModel:UpdateStageRecordByStageId(stageId, data)
    if self.ActivityDb and self.ActivityDb.StageRecords then
        self.ActivityDb.StageRecords[stageId] = data
    end
end
--endregion