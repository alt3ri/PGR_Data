---@class XBigWorldSkipFunctionConfigModel : XModel
local XBigWorldSkipFunctionConfigModel = XClass(XModel, "XBigWorldSkipFunctionConfigModel")

local SkipFunctionTableKey = {
    BigWorldSkipFunction = { DirPath = XConfigUtil.DirectoryType.Client, CacheType = XConfigUtil.CacheType.Normal },
}

function XBigWorldSkipFunctionConfigModel:_InitTableKey()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/SkipFunction", SkipFunctionTableKey)
end

---@return XTableBigWorldSkipFunction[]
function XBigWorldSkipFunctionConfigModel:GetBigWorldSkipFunctionConfigs()
    return self._ConfigUtil:GetByTableKey(SkipFunctionTableKey.BigWorldSkipFunction) or {}
end

---@return XTableBigWorldSkipFunction
function XBigWorldSkipFunctionConfigModel:GetBigWorldSkipFunctionConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(SkipFunctionTableKey.BigWorldSkipFunction, id, false) or {}
end

function XBigWorldSkipFunctionConfigModel:GetBigWorldSkipFunctionSkipNameById(id)
    local config = self:GetBigWorldSkipFunctionConfigById(id)

    return config.SkipName
end

function XBigWorldSkipFunctionConfigModel:GetBigWorldSkipFunctionConditionIdById(id)
    local config = self:GetBigWorldSkipFunctionConfigById(id)

    return config.ConditionId
end

function XBigWorldSkipFunctionConfigModel:GetBigWorldSkipFunctionParamsById(id)
    local config = self:GetBigWorldSkipFunctionConfigById(id)

    return config.Params
end

return XBigWorldSkipFunctionConfigModel