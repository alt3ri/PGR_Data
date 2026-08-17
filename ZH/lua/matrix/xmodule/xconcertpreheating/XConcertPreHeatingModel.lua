---@class XConcertPreHeatingModel : XModel
local XConcertPreHeatingModel = XClass(XModel, "XConcertPreHeatingModel")

local ConcertPreHeatingTableKey =
{
    ConcertClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String },
    ConcertPreHeatingActivity = {},
    ConcertPreHeatingStage = {},
    ConcertPreHeatingControlParam = {},
    ConcertVideoConfig = {},
}

function XConcertPreHeatingModel:OnInit()
    self._ActivityId = nil
    self._FinishedStageIds = {}
    self._FinishedStageIdMap = {}
    self._ServerVideoConfigMap = nil

    self._ConfigUtil:InitConfigByTableKey("MiniActivity/MusicGame/ConcertPreHeating", ConcertPreHeatingTableKey, XConfigUtil.CacheType.Normal)
end

function XConcertPreHeatingModel:ClearPrivate()
end

function XConcertPreHeatingModel:ResetAll()
    self._ActivityId = nil
    self._FinishedStageIds = {}
    self._FinishedStageIdMap = {}
    self._ServerVideoConfigMap = nil
end

--region ----------server data----------

function XConcertPreHeatingModel:RefreshActivityData(data)
    local activityData = data and (data.ConcertPreHeatingDataDb or data)
    if XTool.IsTableEmpty(activityData) then
        return
    end

    self._ActivityId = activityData.ActivityId
    self._FinishedStageIds = {}
    self._FinishedStageIdMap = {}

    for _, stageInfo in pairs(activityData.StageFinish or {}) do
        local stageId = stageInfo.StageId
        if XTool.IsNumberValid(stageId) and not self._FinishedStageIdMap[stageId] then
            self._FinishedStageIdMap[stageId] = true
            table.insert(self._FinishedStageIds, stageId)
        end
    end
end

-- 服务端推送的直播/回放链接与时间，优先级高于本地表。
function XConcertPreHeatingModel:RefreshServerVideoConfigs(data)
    local configMap = data and (data.ConcertVideoConfigs or data)
    self._ServerVideoConfigMap = {}

    for id, config in pairs(configMap or {}) do
        local configId = config.Id or id
        if XTool.IsNumberValid(configId) then
            self._ServerVideoConfigMap[configId] = config
        end
    end
end

function XConcertPreHeatingModel:GetCurActivityId()
    return self._ActivityId
end

function XConcertPreHeatingModel:GetFinishedStageIds()
    return self._FinishedStageIds or {}
end

function XConcertPreHeatingModel:GetFinishedStageIdMap()
    return self._FinishedStageIdMap or {}
end

function XConcertPreHeatingModel:GetServerVideoConfigMap()
    return self._ServerVideoConfigMap or {}
end

--endregion ----------server data----------

--region ----------config----------

---@return XTableConcertClientConfig[]
function XConcertPreHeatingModel:GetAllClientConfigCfgs()
    return self._ConfigUtil:GetByTableKey(ConcertPreHeatingTableKey.ConcertClientConfig) or {}
end

---@return XTableConcertClientConfig
function XConcertPreHeatingModel:GetClientConfigCfg(configId)
    if not configId or configId == "" then
        return nil
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ConcertPreHeatingTableKey.ConcertClientConfig, configId, true)
end

---@return XTableConcertPreHeatingActivity[]
function XConcertPreHeatingModel:GetAllActivityCfgs()
    return self._ConfigUtil:GetByTableKey(ConcertPreHeatingTableKey.ConcertPreHeatingActivity) or {}
end

---@return XTableConcertPreHeatingActivity
function XConcertPreHeatingModel:GetActivityCfg(activityId)
    if not XTool.IsNumberValid(activityId) then
        return nil
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ConcertPreHeatingTableKey.ConcertPreHeatingActivity, activityId, true)
end

---@return XTableConcertPreHeatingStage[]
function XConcertPreHeatingModel:GetAllStageCfgs()
    return self._ConfigUtil:GetByTableKey(ConcertPreHeatingTableKey.ConcertPreHeatingStage) or {}
end

---@return XTableConcertPreHeatingStage
function XConcertPreHeatingModel:GetStageCfg(stageId)
    if not XTool.IsNumberValid(stageId) then
        return nil
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ConcertPreHeatingTableKey.ConcertPreHeatingStage, stageId, true)
end

---@return XTableConcertPreHeatingControlParam
function XConcertPreHeatingModel:GetControlParamCfg(controlId)
    if not XTool.IsNumberValid(controlId) then
        return nil
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ConcertPreHeatingTableKey.ConcertPreHeatingControlParam, controlId, true)
end

---@return XTableConcertVideoConfig[]
function XConcertPreHeatingModel:GetAllVideoConfigCfgs()
    return self._ConfigUtil:GetByTableKey(ConcertPreHeatingTableKey.ConcertVideoConfig) or {}
end

---@return XTableConcertVideoConfig
function XConcertPreHeatingModel:GetVideoConfigCfg(configId)
    if not XTool.IsNumberValid(configId) then
        return nil
    end

    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(ConcertPreHeatingTableKey.ConcertVideoConfig, configId, true)
end

--endregion ----------config----------

return XConcertPreHeatingModel
