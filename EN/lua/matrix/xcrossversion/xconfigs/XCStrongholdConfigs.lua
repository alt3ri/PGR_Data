local TABLE_SPECIALREWARD_PATH = "Share/Fuben/Stronghold/StrongholdRewardSpecialTreatment.tab"
local TABLE_SPECIALGROUP_PATH = "Share/Fuben/Stronghold/StrongholdGroupSpecialTreatment.tab"

local SpecialRewardConfig = {}
local SpecialGroupConfig = {}

XStrongholdConfigs = XStrongholdConfigs or {}

if not XDataCenter.CrossVersionManager.GetEnable() then
    return
end

function XStrongholdConfigs.InitCrossVersion()
    SpecialRewardConfig = XTableManager.ReadByIntKey(TABLE_SPECIALREWARD_PATH, XTable.XTableStrongholdRewardSpecialTreatment, "Id")
    SpecialGroupConfig = XTableManager.ReadByIntKey(TABLE_SPECIALGROUP_PATH, XTable.XTableStrongholdGroupSpecialTreatment, "Id")
end

function XStrongholdConfigs.GetSpecialGroupRewardId(groupId, activityId)
    local maxId = XStrongholdConfigs.GetSpecialGroupMaxId()
    for id, config in pairs(SpecialGroupConfig) do
        if config.ActivityId == maxId and config.StrongholdGroupId == groupId then
            return config.RewardId[activityId]
        end
    end
    return nil
end

function XStrongholdConfigs.GetSpecialRewardId(StrongholdId, maxId)
    for id, config in pairs(SpecialRewardConfig) do
        if config.StrongholdRewardId == StrongholdId and config.ActivityId == maxId then
            return config.RewardId
        end
    end
end

function XStrongholdConfigs.GetSpecialMaxId()
    local maxId = 0
    for id, config in pairs(SpecialRewardConfig) do
        if config.ActivityId > maxId then
            maxId = config.ActivityId
        end
    end
    return maxId
end

function XStrongholdConfigs.GetSpecialGroupMaxId()
    local maxId = 0
    for id, config in pairs(SpecialGroupConfig) do
        if config.ActivityId > maxId then
            maxId = config.ActivityId
        end
    end
    return maxId
end