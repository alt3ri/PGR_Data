---@class XPunishaarSubModelOutSide: XModel
---@field _MainModel XPunishaarModel
local XPunishaarSubModelOutSide = XClass(XModel, "XPunishaarSubModelOutSide")

function XPunishaarSubModelOutSide:OnInit()
end

function XPunishaarSubModelOutSide:ClearPrivate()
end

function XPunishaarSubModelOutSide:ResetAll()
    self._CatalogsDict = nil
    self._UnlockedCatalogIdDict = nil
    self._PassedStageIds = nil
    self._PunishaarStages = nil
    self._SaveStageIds = nil
end

---登录推送初始化：保存关卡进度和四类图鉴已解锁卡牌集合，
---用于局外关卡状态、图鉴解锁状态及图鉴红点判断。
---@param saveStageIds userdata 有存档的关卡Id集合
---@param passedStageIds userdata 已通关的关卡Id集合
---@param characterCatalogs userdata 已解锁角色卡Id集合
---@param partnerCatalogs userdata 已解锁辅助机卡Id集合
---@param equipCatalogs userdata 已解锁意识卡Id集合
---@param resonanceCatalogs userdata 已解锁共鸣卡Id集合
function XPunishaarSubModelOutSide:InitLoginData(saveStageIds, passedStageIds, characterCatalogs, partnerCatalogs, equipCatalogs, resonanceCatalogs)
    local CatalogType = XMVCA.XPunishaar.EnumConst.CatalogType

    self._SaveStageIds = saveStageIds
    self._PassedStageIds = passedStageIds

    self._CatalogsDict = {
        [CatalogType.Character] = characterCatalogs,
        [CatalogType.Partner] = partnerCatalogs,
        [CatalogType.Equip] = equipCatalogs,
        [CatalogType.Resonance] = resonanceCatalogs,
    }

    self:RebuildUnlockedCatalogCache()
end

function XPunishaarSubModelOutSide:InitDataDb(data)
    self._CatalogsDict = {
        [XMVCA.XPunishaar.EnumConst.CatalogType.Character] = data.CharacterCardCatalogsDict,
        [XMVCA.XPunishaar.EnumConst.CatalogType.Partner] = data.PartnerCardCatalogsDict,
        [XMVCA.XPunishaar.EnumConst.CatalogType.Equip] = data.EquipCatalogs,
        [XMVCA.XPunishaar.EnumConst.CatalogType.Resonance] = data.ResonanceCatalogs
    }
    self._PassedStageIds  = data.PassedStageIds
    self._PunishaarStages = data.StageSaves
    self:RebuildUnlockedCatalogCache()
end

---查询卡牌是否已解锁
---@param catalogType number XPunishaarEnum.CatalogType
---@param cardId number
---@return boolean
function XPunishaarSubModelOutSide:IsCollectionUnlocked(catalogType, cardId)
    local idDict =
    self._UnlockedCatalogIdDict
        and self._UnlockedCatalogIdDict[catalogType]

    return idDict and idDict[cardId] == true or false
end

function XPunishaarSubModelOutSide:RebuildUnlockedCatalogCache()
    local CatalogType = XMVCA.XPunishaar.EnumConst.CatalogType

    self._UnlockedCatalogIdDict = {
        [CatalogType.Character] = {},
        [CatalogType.Partner] = {},
        [CatalogType.Equip] = {},
        [CatalogType.Resonance] = {},
    }

    if not self._CatalogsDict then
        return
    end

    local function AddHashSet(catalogType, hashSet)
        if not hashSet then
            return
        end

        local idDict = self._UnlockedCatalogIdDict[catalogType]

        XTool.LoopHashSet(hashSet, function(cardId)
            if cardId and cardId ~= 0 then
                idDict[cardId] = true
            end
        end)
    end

    -- 角色、辅助机：等级 → Catalog → Catalogs
    for _, catalogType in ipairs({ CatalogType.Character, CatalogType.Partner, }) do
        local catalogMap = self._CatalogsDict[catalogType]

        if catalogMap then
            XTool.LoopMap(catalogMap, function(_, catalog)
                if catalog then
                    AddHashSet(catalogType, catalog.Catalogs)
                end
            end)
        end
    end

    -- 意识、共鸣：直接是 HashSet<int>
    AddHashSet(CatalogType.Equip, self._CatalogsDict[CatalogType.Equip])

    AddHashSet(CatalogType.Resonance, self._CatalogsDict[CatalogType.Resonance])
end

function XPunishaarSubModelOutSide:AddCollectionUnlocked(catalogType, cardId)
    if not catalogType or not cardId or cardId == 0 then
        return false
    end

    self._UnlockedCatalogIdDict = self._UnlockedCatalogIdDict or {}

    local idDict = self._UnlockedCatalogIdDict[catalogType]

    if not idDict then
        idDict = {}
        self._UnlockedCatalogIdDict[catalogType] = idDict
    end

    if idDict[cardId] then
        return false
    end

    idDict[cardId] = true
    return true
end

function XPunishaarSubModelOutSide:LoopCollectionIds(catalogType, callback)
    local idDict = self._UnlockedCatalogIdDict and self._UnlockedCatalogIdDict[catalogType]

    if not idDict then
        return false
    end

    for cardId in pairs(idDict) do
        if callback(cardId) == true then
            return true
        end
    end

    return false
end
--region ----------public start----------

function XPunishaarSubModelOutSide:GetCollectionDatas(index)
    if not self._CatalogsDict then
        return nil
    end
    return self._CatalogsDict[index]
end

function XPunishaarSubModelOutSide:IsPassStage(stageId)
    return self._PassedStageIds and table.contains(self._PassedStageIds, stageId)
end

--- 通关后本地写入通关记录（镜像 SetSaveStage 范式：nil 建表 + 去重）。
--- 修复通关后下一关需重登录才解锁的 bug（服务端已标通关但客户端 _PassedStageIds 缺失）。
---@param stageId number 通关的关卡 Id
function XPunishaarSubModelOutSide:AddPassedStage(stageId)
    if not stageId or stageId == 0 then return end
    if not self._PassedStageIds then
        self._PassedStageIds = {}
    end
    if not table.contains(self._PassedStageIds, stageId) then
        table.insert(self._PassedStageIds, stageId)
    end
end

--- 判断关卡是否有进行中存档。
--- 优先查完整存档字典（GetStageData 后可用），其次查登录推送的 id set。
---@param stageId number
---@return boolean
function XPunishaarSubModelOutSide:IsHasSaveStage(stageId)
    if self._PunishaarStages then
        return self._PunishaarStages[stageId] ~= nil
    end
    return self._SaveStageIds ~= nil and table.contains(self._SaveStageIds, stageId)
end

--- 写入本地存档缓存
---@param stageId number
---@param stage table Server.XPunishaarStage
function XPunishaarSubModelOutSide:SetSaveStage(stageId, stage)
    if not self._PunishaarStages then
        self._PunishaarStages = {}
    end
    self._PunishaarStages[stageId] = stage
    -- 同步更新 id 列表（避免两套数据不一致）
    if self._SaveStageIds and not table.contains(self._SaveStageIds, stageId) then
        table.insert(self._SaveStageIds, stageId)
    end
end

--- 结算时清除指定关卡的存档缓存（与 SetSaveStage 对称）。
---@param stageId number
function XPunishaarSubModelOutSide:ClearSaveStage(stageId)
    if self._PunishaarStages then
        self._PunishaarStages[stageId] = nil
    end
    if self._SaveStageIds then
        for i = #self._SaveStageIds, 1, -1 do
            if self._SaveStageIds[i] == stageId then
                table.remove(self._SaveStageIds, i)
                break
            end
        end
    end
end

--- 获取指定关卡的进行中存档
---@param stageId number 关卡Id
---@return table|nil Server.XPunishaarStage
function XPunishaarSubModelOutSide:GetSaveStage(stageId)
    return self._PunishaarStages and self._PunishaarStages[stageId] or nil
end

--- 获取当前存档数量
---@return number
function XPunishaarSubModelOutSide:GetSaveStageCount()
    local count = 0
    -- GetStageData后，完整存档数据优先
    if self._PunishaarStages then
        XTool.LoopMap(self._PunishaarStages, function()
            count = count + 1
        end)
        return count
    end

    -- 尚未获取完整数据时，使用登录推送的存档Id集合
    if self._SaveStageIds then
        XTool.LoopHashSet(self._SaveStageIds, function()
            count = count + 1
        end)
    end

    return count
end

--endregion ----------public end----------

return XPunishaarSubModelOutSide
