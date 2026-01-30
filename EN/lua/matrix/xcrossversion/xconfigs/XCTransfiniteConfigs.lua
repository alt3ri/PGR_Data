---@type XTransfiniteConfigs
XTransfiniteConfigs = XTransfiniteConfigs or {}

if not XDataCenter.CrossVersionManager.GetEnable() then
    return
end

--region SpecialTask
local _ConfigSpecialTask
local function GetSpecialConfigTask()
    if not _ConfigSpecialTask then
        _ConfigSpecialTask = XConfig.New("Share/Fuben/Transfinite/TransfiniteTaskGroupSpecialTreatment.tab", XTable.XTableTransfiniteTaskGroupSpecialTreatment, "Id")
    end
    return _ConfigSpecialTask
end

local function GetSpecialTask(id)
    local config = GetSpecialConfigTask()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetSpecialTaskTimeId(id)
    return GetSpecialTask(id).TimeId
end

function XTransfiniteConfigs.GetSpecialTaskTaskIds(id)
    return GetSpecialTask(id).TaskIds
end
--endregion SpecialTask

--region SepcialTreatmentConfig
local _ConfigSepcialTreatment
local function GetConfigSepcialTreatment()
    if not _ConfigSepcialTreatment then
        _ConfigSepcialTreatment = XConfig.New("Share/Fuben/Transfinite/TransfiniteScoreRewardGroupSpecialTreatment.tab", XTable.XTableTransfiniteScoreRewardGroupSpecialTreatment, "Id")
    end
    return _ConfigSepcialTreatment
end

local function GetSepcialTreatment(id)
    local config = GetConfigSepcialTreatment()
    return config:GetConfig(id)
end

function XTransfiniteConfigs.GetSepcialTreatmentTimeId(id)
    return GetSepcialTreatment(id).TimeId
end

function XTransfiniteConfigs.GetSpecialScoreArray(regionId)
    local config = GetSepcialTreatment(regionId)
    return config.Score, config.RewardId
end
--endregion SepcialTreatmentConfig