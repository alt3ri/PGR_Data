---@class XLifeTreeControl : XControl
---@field private _Model XLifeTreeModel
local XLifeTreeControl = XClass(XControl, "XLifeTreeControl")
function XLifeTreeControl:OnInit()
    --初始化内部变量
end

function XLifeTreeControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XLifeTreeControl:RemoveAgencyEvent()

end

function XLifeTreeControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

--- 获取角色解锁次数
---@param characterId number
---@return number status
function XLifeTreeControl:GetCharacterUnlockStatus(characterId)
    return self._Model:GetCharacterUnlockCount(characterId)
end

--- 获取角色解锁次数
---@param catalogId number
---@return number count
function XLifeTreeControl:GetCharacterUnlockCountByCatalogId(catalogId)
    return self._Model:GetCharacterUnlockCountByCatalogId(catalogId)
end

-- 角色是否解锁
---@param catalogId number
---@return boolean
function XLifeTreeControl:IsCharacterUnlock(catalogId)
    local catalogConfig = self._Model:GetLifeTreeCharacterCatalogConfigById(catalogId)
    local curUnlockCount = self._Model:GetCharacterUnlockCount(catalogConfig.CharacterId)
    return curUnlockCount > 0
end

-- 角色是否解锁完成
---@param catalogId number
---@return boolean
function XLifeTreeControl:IsCharacterUnlockFinish(catalogId)
    local catalogConfig = self._Model:GetLifeTreeCharacterCatalogConfigById(catalogId)
    local characterId = catalogConfig.CharacterId
    local charConfig = self._Model:GetLifeTreeCharacterConfigById(characterId)
    local allUnlockCount = #charConfig.ConditionIds
    local curUnlockCount = self._Model:GetCharacterUnlockCount(characterId)
    return curUnlockCount >= allUnlockCount
end

-- 获取角色的神卡状态
function XLifeTreeControl:GetCharacterDivineState(catalogId)
    local catalogConfig = self._Model:GetLifeTreeCharacterCatalogConfigById(catalogId)
    if catalogConfig.CardType ~= XMVCA.XLifeTree.EnumConst.CARD_TYPE.DIVINE then
        XLog.Error(string.format("CatalogId = [%s] 非神卡，无法获得角色当前神卡类型!", catalogId))
        return
    end

    local divineTypes = XMVCA.XLifeTree.EnumConst.DIVINE_UNLOCK_PROCESS_TO_TYPE[catalogConfig.DivineUnlockProcessType]
    if not divineTypes then
        XLog.Error(string.format("XLifeTreeEnumConst.DIVINE_UNLOCK_PROCESS_TO_TYPE缺少神卡解锁流程[%s]定义!", catalogConfig.DivineUnlockProcessType))
        return
    end

    -- 未解锁
    local unlockCount = self._Model:GetCharacterUnlockCountByCatalogId(catalogId)
    if unlockCount == 0 then
        return XMVCA.XLifeTree.EnumConst.DIVINE_TYPE.UNLOCK
    end
    
    local divineType = divineTypes[unlockCount]
    if divineType == nil then
        XLog.Error(string.format("XLifeTreeEnumConst.DIVINE_UNLOCK_PROCESS_TO_TYPE神卡解锁流程[%s]，缺少第[%s]次解锁对应神卡类型定义!", catalogConfig.DivineUnlockProcessType, unlockCount))
    end
    return divineType
end

--region 配置表
---@return XTableLifeTreeCharacter
function XLifeTreeControl:GetLifeTreeCharacterConfigById(id)
    return self._Model:GetLifeTreeCharacterConfigById(id)
end

---@return XTableLifeTreeCharacterCatalog
function XLifeTreeControl:GetLifeTreeCharacterCatalogConfigById(id)
    return self._Model:GetLifeTreeCharacterCatalogConfigById(id)
end

---@return XTableLifeTreeChapter
function XLifeTreeControl:GetLifeTreeChapterConfigById(id)
    return self._Model:GetLifeTreeChapterConfigById(id)
end

---@return XTableLifeTreeClientConfig
function XLifeTreeControl:GetLifeTreeClientConfigConfigById(id)
    return self._Model:GetLifeTreeClientConfigConfigById(id)
end

---@return XTableLifeTreeConstellation[]
function XLifeTreeControl:GetLifeTreeConstellationConfigs()
    return self._Model:GetLifeTreeConstellationConfigs()
end

---@return XTableLifeTreeConstellation
function XLifeTreeControl:GetLifeTreeConstellationConfigById(id)
    return self._Model:GetLifeTreeConstellationConfigById(id)
end

---获取星座神卡CatalogId
---@param constellationId number 星座Id
---@return number CatalogId
function XLifeTreeControl:GetConstellationDivineCharacterCatalogId(constellationId)
    return self._Model:GetConstellationDivineCharacterCatalogId(constellationId)
end

-- 获取所有任务
---@return table<number>
function XLifeTreeControl:GetAllTaskIds()
    return self._Model:GetAllTaskIds()
end

-- 获取任务Id列表
---@param constellationId number
---@return table<number> 任务Id列表
function XLifeTreeControl:GetTaskIds(constellationId)
    return self._Model:GetTaskIds(constellationId)
end

--endregion

return XLifeTreeControl