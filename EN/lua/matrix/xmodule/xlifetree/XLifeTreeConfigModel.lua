---@class XLifeTreeConfigModel : XModel
local XLifeTreeConfigModel = XClass(XModel, "XLifeTreeConfigModel")

local XLifeTreeTableKey = {
    LifeTreeCharacter = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LifeTreeCharacterCatalog = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
    LifeTreeChapter = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    LifeTreeClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String, CacheType = XConfigUtil.CacheType.Normal },
    LifeTreeConstellation = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
}

function XLifeTreeConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("LifeTree", XLifeTreeTableKey)
end

-- ==================== LifeTreeCharacter ====================

---@return XTableLifeTreeCharacter[]
function XLifeTreeConfigModel:GetLifeTreeCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(XLifeTreeTableKey.LifeTreeCharacter)
end

---@return XTableLifeTreeCharacter
function XLifeTreeConfigModel:GetLifeTreeCharacterConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(XLifeTreeTableKey.LifeTreeCharacter, id, false)
end

-- ==================== LifeTreeCharacterCatalog ====================

---@return XTableLifeTreeCharacterCatalog[]
function XLifeTreeConfigModel:GetLifeTreeCharacterCatalogConfigs()
    return self._ConfigUtil:GetByTableKey(XLifeTreeTableKey.LifeTreeCharacterCatalog)
end

---@return XTableLifeTreeCharacterCatalog
function XLifeTreeConfigModel:GetLifeTreeCharacterCatalogConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(XLifeTreeTableKey.LifeTreeCharacterCatalog, id, false)
end

-- ==================== LifeTreeChapter ====================

---@return XTableLifeTreeChapter[]
function XLifeTreeConfigModel:GetLifeTreeChapterConfigs()
    return self._ConfigUtil:GetByTableKey(XLifeTreeTableKey.LifeTreeChapter)
end

---@return XTableLifeTreeChapter
function XLifeTreeConfigModel:GetLifeTreeChapterConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(XLifeTreeTableKey.LifeTreeChapter, id, false)
end

-- ==================== LifeTreeClientConfig ====================

---@return XTableLifeTreeClientConfig[]
function XLifeTreeConfigModel:GetLifeTreeClientConfigConfigs()
    return self._ConfigUtil:GetByTableKey(XLifeTreeTableKey.LifeTreeClientConfig)
end

---@return XTableLifeTreeClientConfig
function XLifeTreeConfigModel:GetLifeTreeClientConfigConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(XLifeTreeTableKey.LifeTreeClientConfig, id, false)
end

-- ==================== LifeTreeConstellation ====================

---@return XTableLifeTreeConstellation[]
function XLifeTreeConfigModel:GetLifeTreeConstellationConfigs()
    return self._ConfigUtil:GetByTableKey(XLifeTreeTableKey.LifeTreeConstellation)
end

---@return XTableLifeTreeConstellation
function XLifeTreeConfigModel:GetLifeTreeConstellationConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(XLifeTreeTableKey.LifeTreeConstellation, id, false)
end

return XLifeTreeConfigModel
