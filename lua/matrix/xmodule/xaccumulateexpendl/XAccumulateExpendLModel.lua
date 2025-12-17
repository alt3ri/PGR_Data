---@class XAccumulateExpendModelL : XModel
local XAccumulateExpendModelL = XClass(XModel, "XAccumulateExpendModelL")

local TableKey = {
    CombAccumulateExpendActivity = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
    CombAccumulateExpendReward = {
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

function XAccumulateExpendModelL:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ActivityId = nil
    self._ConfigUtil:InitConfigByTableKey("MiniActivity/CombAccumulateExpend", TableKey)
end

function XAccumulateExpendModelL:ClearPrivate()
    --这里执行内部数据清理
    -- XLog.Error("请对内部数据进行清理")
end

function XAccumulateExpendModelL:ResetAll()
    --这里执行重登数据清理
    -- XLog.Error("重登数据清理")
end

function XAccumulateExpendModelL:SetActivityId(id)
    self._ActivityId = id
end

function XAccumulateExpendModelL:GetActivityId()
    return self._ActivityId
end

-- region ActivityConfig
---@return XTableAccumulateExpendActivity[]
function XAccumulateExpendModelL:GetActivityConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.CombAccumulateExpendActivity) or {}
end

---@return XTableAccumulateExpendActivity
function XAccumulateExpendModelL:GetActivityConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombAccumulateExpendActivity, id, false) or {}
end

function XAccumulateExpendModelL:GetActivityTimeIdById(id)
    local config = self:GetActivityConfigById(id)

    return config.TimeId
end

function XAccumulateExpendModelL:GetActivityItemIdById(id)
    local config = self:GetActivityConfigById(id)

    return config.ItemId
end

function XAccumulateExpendModelL:GetActivityItemIconById(id)
    local config = self:GetActivityConfigById(id)

    return config.ItemIcon
end

function XAccumulateExpendModelL:GetActivityConditionIdsById(id)
    local config = self:GetActivityConfigById(id)

    return config.ConditionIds
end

function XAccumulateExpendModelL:GetActivityBaseRuleTitlesById(id)
    local config = self:GetActivityConfigById(id)

    return config.BaseRuleTitles
end

function XAccumulateExpendModelL:GetActivityBaseRulesById(id)
    local config = self:GetActivityConfigById(id)

    return config.BaseRules
end
-- endregion

-- region RewardConfig
---@return XTableAccumulateExpendReward[]
function XAccumulateExpendModelL:GetRewardConfigs()
    return self._ConfigUtil:GetByTableKey(TableKey.CombAccumulateExpendReward) or {}
end

---@return XTableAccumulateExpendReward
function XAccumulateExpendModelL:GetRewardConfigById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombAccumulateExpendReward, id, false) or {}
end

function XAccumulateExpendModelL:GetRewardTaskIdById(id)
    local config = self:GetRewardConfigById(id)

    return config.TaskId
end

function XAccumulateExpendModelL:GetRewardIsSpecialShowById(id)
    local config = self:GetRewardConfigById(id)

    return config.IsSpecialShow
end

function XAccumulateExpendModelL:GetRewardIsMainRewardById(id)
    local config = self:GetRewardConfigById(id)

    return config.IsMainReward
end
-- endregion

return XAccumulateExpendModelL