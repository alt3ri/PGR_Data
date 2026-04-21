--- 定义所有配置的加载、读取接口
---@type XPBRGameModel
local XPBRGameModel = XClassPartial("XPBRGameModel")

local TableNormal = {
    PBRActivity = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PBRStage = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'StageId' },
    PBRCharacter = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'CharacterId' },

    PBRClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = 'Key' },
    PBRConfig = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.String, Identifier = 'Key' },

    PBRTaskGroup = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },

    PBRMetaProgressionNodeGroup = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'NodeGroup' },

    PBRMetaProgression = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'NodeId' },
}

local TablePrivate = {
    PBRCharacterStats = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'CharacterId' },
    PBRStatsDesc = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'StatsId' },

    PBRItem =  { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'ItemId' },
    PBRItemGroup =  { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'OrbGroup' },
    PBRSkillGroupDesc =  { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PBRMonsterWave = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'WaveId' },
    PBRArchiveMonster = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },

    PBRRichTextIconConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = 'Key' },
}

function XPBRGameModel:InitConfigs()
    self._ConfigUtil:InitConfigByTableKey('Pbr', TableNormal, XConfigUtil.CacheType.Normal)
    self._ConfigUtil:InitConfigByTableKey('Pbr', TablePrivate, XConfigUtil.CacheType.Private)
end

function XPBRGameModel:ClearPrivateConfigByPartial()

end

function XPBRGameModel:ResetConfigs()

end

--region ReadAll

---@return XTablePBRActivity[]
function XPBRGameModel:GetTablePBRActivityCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.PBRActivity)
end

---@return XTablePBRStage[]
function XPBRGameModel:GetTablePBRStageCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.PBRStage)
end

---@return XTablePBRCharacter[]
function XPBRGameModel:GetTablePBRCharacterCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.PBRCharacter)
end

---@return XTablePBRCharacterStats[]
function XPBRGameModel:GetTablePBRCharacterStatsCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.PBRCharacterStats)
end

---@return XTablePBRStatsDesc[]
function XPBRGameModel:GetTablePBRStatsDescCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.PBRStatsDesc)
end

---@return XTablePBRItem[]
function XPBRGameModel:GetTablePBRItemCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.PBRItem)
end

---@return XTablePBRItemGroup[]
function XPBRGameModel:GetTablePBRItemGroupCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.PBRItemGroup)
end

---@return XTablePBRMonsterWave[]
function XPBRGameModel:GetTablePBRMonsterWaveCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.PBRMonsterWave)
end

---@return XTablePBRSkillGroupDesc[]
function XPBRGameModel:GetTablePBRSkillGroupDescCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.PBRSkillGroupDesc)
end

---@return XTablePBRArchiveMonster[]
function XPBRGameModel:GetTablePBRArchiveMonsterCfgs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.PBRArchiveMonster)
end

---@return XTablePBRMetaProgression[]
function XPBRGameModel:GetTablePBRMetaProgressionCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.PBRMetaProgression)
end

---@return XTablePBRTaskGroup[]
function XPBRGameModel:GetTablePBRTaskGroupCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.PBRTaskGroup)
end

---@return XTablePBRMetaProgressionNodeGroup[]
function XPBRGameModel:GetTablePBRMetaProgressionNodeGroupCfgs()
    return self._ConfigUtil:GetByTableKey(TableNormal.PBRMetaProgressionNodeGroup)
end

---@return XTablePBRRichTextIconConfig[]
function XPBRGameModel:GetTablePBRRichTextIconConfigs()
    return self._ConfigUtil:GetByTableKey(TablePrivate.PBRRichTextIconConfig)
end
--endregion

--region ReadSingle

---@return XTablePBRActivity
function XPBRGameModel:GetTablePBRActivityCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.PBRActivity, id, notips)
end

---@return XTablePBRStage
function XPBRGameModel:GetTablePBRStageCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.PBRStage, id, notips)
end

---@return XTablePBRCharacter
function XPBRGameModel:GetTablePBRCharacterCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.PBRCharacter, id, notips)
end

---@return XTablePBRCharacterStats
function XPBRGameModel:GetTablePBRCharacterStatsCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.PBRCharacterStats, id, notips)
end

---@return XTablePBRStatsDesc
function XPBRGameModel:GetTablePBRStatsDescCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.PBRStatsDesc, id, notips)
end

---@return XTablePBRClientConfig
function XPBRGameModel:GetTablePBRClientConfigCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.PBRClientConfig, id, notips)
end

---@return XTablePBRItem
function XPBRGameModel:GetTablePBRItemCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.PBRItem, id, notips)
end

---@return XTablePBRItemGroup
function XPBRGameModel:GetTablePBRItemGroupCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.PBRItemGroup, id, notips)
end

---@return XTablePBRConfig
function XPBRGameModel:GetTablePBRConfigCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.PBRConfig, id, notips)
end

---@return XTablePBRMonsterWave
function XPBRGameModel:GetTablePBRMonsterWaveCfgById(waveId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.PBRMonsterWave, waveId, notips)
end

---@return XTablePBRSkillGroupDesc
function XPBRGameModel:GetTablePBRSkillGroupDescCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.PBRSkillGroupDesc, id, notips)
end

---@return XTablePBRArchiveMonster
function XPBRGameModel:GetTablePBRArchiveMonsterById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.PBRArchiveMonster, id, notips)
end

---@return XTablePBRMetaProgression
function XPBRGameModel:GetTablePBRMetaProgressionCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.PBRMetaProgression, id, notips)
end

---@return XTablePBRTaskGroup
function XPBRGameModel:GetTablePBRTaskGroupCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.PBRTaskGroup, id, notips)
end

---@return XTablePBRMetaProgressionNodeGroup
function XPBRGameModel:GetTablePBRMetaProgressionNodeGroupCfgById(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.PBRMetaProgressionNodeGroup, id, notips)
end

---@return XTablePBRRichTextIconConfig
function XPBRGameModel:GetTablePBRRichTextIconConfigByKey(key, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TablePrivate.PBRRichTextIconConfig, key, notips)
end
--endregion

--region ReadCommonConfig

function XPBRGameModel:GetClientPBRText(key, index)
    index = index or 1
    
    local cfg = self:GetTablePBRClientConfigCfgById(key)

    if cfg then
        return cfg.Values[index] or ''
    end
    
    return ''
end

function XPBRGameModel:GetClientPBRTextArray(key, index)
    index = index or 1

    local cfg = self:GetTablePBRClientConfigCfgById(key)

    if cfg then
        return cfg.Values
    end
end

function XPBRGameModel:GetClientPBRNumber(key, index)
    index = index or 1

    local cfg = self:GetTablePBRClientConfigCfgById(key)

    if cfg then
        local numStr = cfg.Values[index]

        if not string.IsNilOrEmpty(numStr) and string.IsFloatNumber(numStr) then
            return tonumber(numStr)
        end
    end

    return 0
end

function XPBRGameModel:GetClientPBRNumberArray(key)
    local cfg = self:GetTablePBRClientConfigCfgById(key)

    if cfg and not XTool.IsTableEmpty(cfg.Values) then
        local numberArray = {}

        for i, numStr in ipairs(cfg.Values) do
            if not string.IsNilOrEmpty(numStr) and string.IsFloatNumber(numStr) then
                numberArray[i] = tonumber(numStr)
            else
                numberArray[i] = 0
            end
        end
        
        return numberArray
    end
end

function XPBRGameModel:GetConfigPBRNumber(key, index)
    index = index or 1

    local cfg = self:GetTablePBRConfigCfgById(key)

    if cfg then
        return cfg.Values[index] or 0
    end
    
    return 0
end
--endregion