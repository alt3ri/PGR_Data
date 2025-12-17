---@class XBigWorldLoadingModel : XModel
local XBigWorldLoadingModel = XClass(XModel, "XBigWorldLoadingModel")

local TableKey = {
    BigWorldLoading = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldLoadingGroup = {
        Identifier = "GroupId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XBigWorldLoadingModel:OnInit()
    -- 初始化内部变量
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Loading", TableKey)
end

function XBigWorldLoadingModel:ClearPrivate()
    -- 这里执行内部数据清理
end

function XBigWorldLoadingModel:ResetAll()
    -- 这里执行重登数据清理
end

---@return XTableBigWorldLoadingGroup[]
function XBigWorldLoadingModel:GetBigWorldLoadingGroupConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BigWorldLoadingGroup) or {}
end

---@return XTableBigWorldLoadingGroup
function XBigWorldLoadingModel:GetBigWorldLoadingGroupConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldLoadingGroup, id, false) or {}
end

function XBigWorldLoadingModel:GetBigWorldLoadingGroupTypeById(id)
    local config = self:GetBigWorldLoadingGroupConfigById(id)

    return config.Type
end

function XBigWorldLoadingModel:GetBigWorldLoadingGroupLoadingIdsById(id)
    local config = self:GetBigWorldLoadingGroupConfigById(id)

    return config.LoadingIds
end

---@return XTableBigWorldLoading[]
function XBigWorldLoadingModel:GetBigWorldLoadingConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.BigWorldLoading) or {}
end

---@return XTableBigWorldLoading
function XBigWorldLoadingModel:GetBigWorldLoadingConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldLoading, id, false) or {}
end

function XBigWorldLoadingModel:GetBigWorldLoadingNameById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.Name
end

function XBigWorldLoadingModel:GetBigWorldLoadingDescById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.Desc
end

function XBigWorldLoadingModel:GetBigWorldLoadingImageUrlById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.ImageUrl
end

function XBigWorldLoadingModel:GetBigWorldLoadingWeightById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.Weight
end

function XBigWorldLoadingModel:GetBigWorldLoadingConditionIdsById(id)
    local config = self:GetBigWorldLoadingConfigById(id)

    return config.ConditionIds
end

function XBigWorldLoadingModel:GetLoadingTypeByGroupId(groupId)
    return self:GetBigWorldLoadingGroupTypeById(groupId)
end

---@return XTableBigWorldLoading[]
function XBigWorldLoadingModel:GetValidLoadingConfigsByGroupId(groupId)
    local loadingIds = self:GetBigWorldLoadingGroupLoadingIdsById(groupId)
    local result = {}

    if not XTool.IsTableEmpty(loadingIds) then
        for _, loadingId in pairs(loadingIds) do
            local config = self:GetBigWorldLoadingConfigById(loadingId)

            if self:_CheckLoadingConditions(config.ConditionIds) then
                table.insert(result, config)
            end
        end
    end

    return result
end

---@return XTableBigWorldLoading
function XBigWorldLoadingModel:GetRandomLoadingByGroupId(groupId)
    local loadingConfigs = self:GetValidLoadingConfigsByGroupId(groupId)

    if XTool.IsTableEmpty(loadingConfigs) then
        return nil
    end

    return XTool.WeightRandomSelect(loadingConfigs)
end

function XBigWorldLoadingModel:_CheckLoadingConditions(conditionIds)
    local isShow = true

    if not XTool.IsTableEmpty(conditionIds) then
        for _, conditionId in pairs(conditionIds) do
            if not XMVCA.XBigWorldService:CheckCondition(conditionId) then
                isShow = false
                break
            end
        end
    end

    return isShow
end

return XBigWorldLoadingModel
