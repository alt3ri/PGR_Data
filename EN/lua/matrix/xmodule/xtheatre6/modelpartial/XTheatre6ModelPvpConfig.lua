---Model部分类，此处用于注册和处理与Pvp配置表直接关联的读取接口
---@type XTheatre6Model
local XTheatre6Model = XClassPartial('XTheatre6Model')

local PvpTableKey = {
    Theatre6PvpActivity = {},
    Theatre6PvpBuff = {},
    Theatre6PvpBuffGroup = {},
    Theatre6PvpConfig = { CacheType = XConfigUtil.CacheType.Normal, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    Theatre6PvpRank = {},
    Theatre6PvpClientConfig = { CacheType = XConfigUtil.CacheType.Normal, DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String },
    Theatre6PvpRobot = {},
}

function XTheatre6Model:OnInitPvpConfig()
    self._ConfigUtil:InitConfigByTableKey("Theatre6Pvp", PvpTableKey)
end

function XTheatre6Model:PvpConfigClearPrivate()

end

function XTheatre6Model:PvpConfigResetAll()

end

---@return XTableTheatre6PvpActivity[]
function XTheatre6Model:GetPvpActivityConfigs()
    return self._ConfigUtil:GetByTableKey(PvpTableKey.Theatre6PvpActivity)
end

---@return XTableTheatre6PvpActivity
function XTheatre6Model:GetPvpActivityConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PvpTableKey.Theatre6PvpActivity, id)
end

---@return XTableTheatre6PvpBuff
function XTheatre6Model:GetPvpBuffConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PvpTableKey.Theatre6PvpBuff, id)
end

---@return XTableTheatre6PvpBuffGroup
function XTheatre6Model:GetPvpBuffGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PvpTableKey.Theatre6PvpBuffGroup, id)
end

---@return XTableTheatre6PvpConfig
function XTheatre6Model:GetPvpConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PvpTableKey.Theatre6PvpConfig, id)
end

---@return XTableTheatre6PvpRank
function XTheatre6Model:GetPvpRankConfig(id, noTips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PvpTableKey.Theatre6PvpRank, id, noTips)
end

---@return XTableTheatre6PvpRank[]
function XTheatre6Model:GetPvpRankConfigs()
    return self._ConfigUtil:GetByTableKey(PvpTableKey.Theatre6PvpRank)
end

---@return XTableTheatre6PvpClientConfig
function XTheatre6Model:GetPvpClientConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PvpTableKey.Theatre6PvpClientConfig, id)
end

---@return string[]
function XTheatre6Model:GetPvpConfigValues(key)
    local config = self:GetPvpConfig(key)
    if not config then
        XLog.Error(string.format("Pvp配置不存在！key=%s", key))
        return nil
    end
    return config.Values
end

---@return string
function XTheatre6Model:GetPvpConfigValue(key, index)
    index = index or 1
    local values = self:GetPvpConfigValues(key)
    return values and values[index] or ""
end

---@return number
function XTheatre6Model:GetIntPvpConfigValue(key, index)
    local value = self:GetPvpConfigValue(key, index)
    return tonumber(value) or 0
end

---@return string[]
function XTheatre6Model:GetPvpClientConfigValues(key)
    local config = self:GetPvpClientConfig(key)
    if not config then
        XLog.Error(string.format("Pvp客户端配置不存在！key=%s", key))
        return nil
    end
    return config.Values
end

---@return string
function XTheatre6Model:GetPvpClientConfigValue(key, index)
    index = index or 1
    local values = self:GetPvpClientConfigValues(key)
    return values and values[index] or ""
end

---@return number
function XTheatre6Model:GetIntPvpClientConfigValue(key, index)
    local value = self:GetPvpClientConfigValue(key, index)
    return tonumber(value) or 0
end

---@return XTableTheatre6PvpRobot
function XTheatre6Model:GetRobotConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(PvpTableKey.Theatre6PvpRobot, id)
end

return XTheatre6Model
