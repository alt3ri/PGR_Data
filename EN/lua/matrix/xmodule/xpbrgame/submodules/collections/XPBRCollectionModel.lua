---@class XPBRCollectionModel: XModel
---@field _MainModel XPBRGameModel
local XPBRCollectionModel = XClass(XModel, 'XPBRCollectionModel')

function XPBRCollectionModel:OnInit()

end

function XPBRCollectionModel:ClearPrivate()

end

function XPBRCollectionModel:ResetAll()

end

--region ActivityData

--region Getter

--- 获取图鉴道具数据
function XPBRCollectionModel:GetCompendiumItemDataById(itemId)
    local activityDb = self._MainModel.ActivityDb

    if activityDb and activityDb.Compendiums and activityDb.Compendiums.CompendiumItems then
        local compendiumItems = activityDb.Compendiums.CompendiumItems

        return compendiumItems[itemId]
    end
end

--- 判断图鉴道具是否解锁
function XPBRCollectionModel:GetIsItemUnlockInCollection(itemId)
    local pbrItem = self:GetCompendiumItemDataById(itemId)

    if pbrItem then
        return true
    end
    
    return false
end

--- 判断图鉴怪物是否解锁
function XPBRCollectionModel:GetIsMonsterUnlockInCollection(monsterId)
    local pbrMonster = self:GetCompendiumMonsterDataById(monsterId)

    if pbrMonster then
        return true
    end
    
    return false
end

--- 获取图鉴道具累计获得次数
function XPBRCollectionModel:GetItemGainNum(itemId)
    local pbrItem = self:GetCompendiumItemDataById(itemId)

    if pbrItem then
        return pbrItem.GainNum or 0
    end

    return 0
end

--- 获取图鉴道具累计触发次数
function XPBRCollectionModel:GetItemTriggerNum(itemId)
    local pbrItem = self:GetCompendiumItemDataById(itemId)

    if pbrItem then
        return pbrItem.TriggerNum or 0
    end

    return 0
end

--- 获取图鉴道具解锁时间
function XPBRCollectionModel:GetItemUnlockTime(itemId)
    local pbrItem = self:GetCompendiumItemDataById(itemId)

    if pbrItem then
        return pbrItem.UnlockTime or math.maxinteger
    end
    
    return math.maxinteger
end

--- 获取图鉴怪物击杀次数
function XPBRCollectionModel:GetMonsterKillTimes(monsterId)
    local pbrMonster = self:GetCompendiumMonsterDataById(monsterId)

    if pbrMonster then
        return pbrMonster.BeKillNum or 0
    end

    return 0
end

--- 获取图鉴怪物伤害总数
function XPBRCollectionModel:GetMonsterDamageTotal(monsterId)
    local pbrMonster = self:GetCompendiumMonsterDataById(monsterId)

    if pbrMonster then
        return pbrMonster.DamageTotal or 0
    end

    return 0
end

--- 获得图鉴怪物解锁时间
function XPBRCollectionModel:GetMonsterUnlockTime(monsterId)
    local pbrMonster = self:GetCompendiumMonsterDataById(monsterId)
    
    if pbrMonster then
        return pbrMonster.UnlockTime or math.maxinteger
    end
    
    return math.maxinteger
end

--- 获取图鉴怪物数据
function XPBRCollectionModel:GetCompendiumMonsterDataById(monsterId)
    local activityDb = self._MainModel.ActivityDb

    if activityDb and activityDb.Compendiums and activityDb.Compendiums.CompendiumMonsters then
        local compendiumMonsters = activityDb.Compendiums.CompendiumMonsters
        
        return compendiumMonsters[monsterId]
    end
end

--endregion

--region Setter

--- 更新道具图鉴
---@param pbrItemData PbrItem
function XPBRCollectionModel:UpdateItemCompendium(pbrItemData)
    if XTool.IsTableEmpty(pbrItemData) then
        return
    end

    local activityDb = self._MainModel.ActivityDb

    if activityDb and activityDb.Compendiums then
        local compendiumItems = activityDb.Compendiums.CompendiumItems or {}

        compendiumItems[pbrItemData.ItemId] = pbrItemData

        activityDb.Compendiums.CompendiumItems = compendiumItems
    end
end

--- 更新怪物图鉴
---@param pbrMonsterData PbrMonster
function XPBRCollectionModel:UpdateMonsterCompendium(pbrMonsterData)
    if XTool.IsTableEmpty(pbrMonsterData) then
        return
    end

    local activityDb = self._MainModel.ActivityDb

    if activityDb and activityDb.Compendiums then
        local compendiumMonsters = activityDb.Compendiums.CompendiumMonsters or {}

        compendiumMonsters[pbrMonsterData.MonsterId] = pbrMonsterData

        activityDb.Compendiums.CompendiumMonsters = compendiumMonsters
    end
end

--endregion

--endregion

return XPBRCollectionModel