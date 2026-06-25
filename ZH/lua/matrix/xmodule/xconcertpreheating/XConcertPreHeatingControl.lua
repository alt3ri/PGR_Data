---@class XConcertPreHeatingControl : XControl
---@field private _Model XConcertPreHeatingModel
local XConcertPreHeatingControl = XClass(XControl, "XConcertPreHeatingControl", false)

local TUNE_PROGRESS_MAX = 100
-- 原始准确度达到该值后，换算后的同步率直接视为 100。
local TUNE_COMPLETE_ACCURACY = 85
local TUNE_TARGET_LIGHT_OFFSET_RATIO = 0.005
local TUNE_TARGET_LIGHT_MIN_OFFSET = 0.001

-- 客户端杂项配置预留：表暂为空，后续按 Id 读取 Values[]。
function XConcertPreHeatingControl:GetClientConfig(configId, index)
    return self._Model:GetClientConfigValue(configId, index)
end

function XConcertPreHeatingControl:GetClientConfigNumber(configId, index)
    local value = self:GetClientConfig(configId, index)
    return value and tonumber(value) or nil
end

function XConcertPreHeatingControl:GetClientConfigValues(configId)
    return self._Model:GetClientConfigValues(configId)
end

-- 主界面页签和调频按钮使用：判断关卡是否已解锁。
function XConcertPreHeatingControl:IsStageOpen(stageId)
    return XMVCA.XConcertPreHeating:IsStageOpen(stageId)
end

-- 主界面未解锁 toast 使用：关卡锁定提示。
function XConcertPreHeatingControl:GetStageLockTip(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    local openTime = stageCfg and XTool.IsNumberValid(stageCfg.TimeId)
        and (XFunctionManager.GetStartTimeByTimeId(stageCfg.TimeId) or 0)
        or 0
    if openTime > 0 then
        local openTimeText = XTime.TimestampToGameDateTimeString(openTime, "yyyy/MM/dd HH:mm")
        return XUiHelper.GetText("ConcertPreHeatingStageLockTip", openTimeText)
    end

    return CS.XTextManager.GetText("ActivityBranchNotOpen")
end

-- 主界面页签使用：关卡名称。
function XConcertPreHeatingControl:GetStageName(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    return stageCfg and stageCfg.Name or ""
end

-- 调频界面玩法剪影表现使用：关卡玩法剪影图路径。
function XConcertPreHeatingControl:GetStageGamePlaySilhouetteImg(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    return stageCfg and stageCfg.StageGamePlaySilhouetteImg
end

-- 调频界面使用：进入关卡时播放的音乐 CueId。
function XConcertPreHeatingControl:GetStageCueId(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    return stageCfg and stageCfg.CueId or 0
end

-- 主界面角色展示使用：未完成用主界面剪影，完成后用主界面展示图。
function XConcertPreHeatingControl:GetStageMainUiImg(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    if not stageCfg then
        return nil
    end

    if self:IsStageFinished(stageId) then
        return stageCfg.StageMainUiDisplayImg
    end

    return stageCfg.StageMainUiSilhouetteImg
end

-- 主界面页签入口使用：关卡入口图片。
function XConcertPreHeatingControl:GetStageEntranceImg(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    return stageCfg and stageCfg.StageEntranceImg
end

-- 调频完成表现使用：有配置则加载 Spine prefab url。
function XConcertPreHeatingControl:GetStageCompleteSpinePrefabUrl(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    return stageCfg and stageCfg.TargetCompeleteSpinePrefab
end

-- 主界面按钮与大合照表现使用：是否主表现关。
function XConcertPreHeatingControl:IsMainPerformanceStage(stageId)
    local stageCfg = self._Model:GetStageCfg(stageId)
    return stageCfg and stageCfg.IsMainPerformance == true
end

-- 主界面页签 tag/按钮/立绘使用：关卡是否已完成。
function XConcertPreHeatingControl:IsStageFinished(stageId)
    if not XTool.IsNumberValid(stageId) then
        return false
    end

    return self._Model:GetFinishedStageIdMap()[stageId] == true
end

function XConcertPreHeatingControl:CheckStageIsNew(stageId)
    return XMVCA.XConcertPreHeating:CheckStageIsNew(stageId)
end

-- 配置了 AisacControlName 的控制参数必须配置 (0, 1] 内的 AisacTargetValue。
local function CheckTuneAisacConfig(controlParamCfg)
    if string.IsNilOrEmpty(controlParamCfg.AisacControlName) then
        return
    end

    local aisacTargetValue = controlParamCfg.AisacTargetValue or 0
    if aisacTargetValue <= 0 or aisacTargetValue > 1 then
        XLog.Error(string.format(
            "ConcertPreHeatingControlParam AisacTargetValue invalid, must be in (0, 1], Id: %s, AisacTargetValue: %s",
            tostring(controlParamCfg.Id),
            tostring(controlParamCfg.AisacTargetValue)
        ))
    end
end

-- 调频界面使用：调频关卡配置的控制参数，顺序对应 Slider1~4。
function XConcertPreHeatingControl:GetTuningStageControlParamCfgs(tuningStageId)
    self._TuningStageControlParamCfgs = self._TuningStageControlParamCfgs or {}
    if self._TuningStageControlParamCfgs[tuningStageId] then
        return self._TuningStageControlParamCfgs[tuningStageId]
    end

    local stageCfg = self._Model:GetStageCfg(tuningStageId)
    if not stageCfg then
        return {}
    end

    local result = {}
    for _, controlId in ipairs(stageCfg.ControlIds or {}) do
        local controlParamCfg = self._Model:GetControlParamCfg(controlId)
        if controlParamCfg then
            CheckTuneAisacConfig(controlParamCfg)
            table.insert(result, controlParamCfg)
        else
            XLog.Error(string.format(
                "ConcertPreHeatingControlParam config not found, ControlId: %s",
                tostring(controlId)
            ))
        end
    end

    self._TuningStageControlParamCfgs[tuningStageId] = result
    return result
end

local function CalculateTuneAccuracy(controlParamCfg, value)
    local minParam = controlParamCfg.MinParam or 0
    local maxParam = controlParamCfg.MaxParam or 0
    local range = maxParam - minParam
    if range <= 0 then
        return 0
    end

    local target = controlParamCfg.Target or minParam
    local accuracy = TUNE_PROGRESS_MAX - math.abs((value or minParam) - target) / range * TUNE_PROGRESS_MAX
    return XMath.Clamp(accuracy, 0, TUNE_PROGRESS_MAX)
end

local function ConvertTuneAccuracyToMatchProgress(accuracy)
    accuracy = XMath.Clamp(accuracy or 0, 0, TUNE_PROGRESS_MAX)
    if accuracy >= TUNE_COMPLETE_ACCURACY then
        return TUNE_PROGRESS_MAX
    end

    local progress
    if accuracy <= 20 then
        progress = accuracy
    elseif accuracy <= 75 then
        progress = 20 + (accuracy - 20) * 1.27
    else
        progress = 90 + (accuracy - 75)
    end

    return XMath.Clamp(progress, 0, TUNE_PROGRESS_MAX)
end

local function ConvertMatchProgressToTuneProgress(matchProgress, baseProgress)
    local progressRange = TUNE_PROGRESS_MAX - (baseProgress or 0)
    if progressRange <= 0 then
        return matchProgress >= TUNE_PROGRESS_MAX and TUNE_PROGRESS_MAX or 0
    end

    local progress = ((matchProgress or 0) - (baseProgress or 0)) / progressRange * TUNE_PROGRESS_MAX
    return XMath.Clamp(progress, 0, TUNE_PROGRESS_MAX)
end

-- 调频界面使用：判断单个控制参数是否已调到目标值附近。
function XConcertPreHeatingControl.IsTuneControlTarget(controlParamCfg, value)
    if not controlParamCfg then
        return false
    end

    local target = controlParamCfg.Target or controlParamCfg.MinParam or 0
    local minParam = controlParamCfg.MinParam or target
    local maxParam = controlParamCfg.MaxParam or target
    local offset = math.max(
        math.abs(maxParam - minParam) * TUNE_TARGET_LIGHT_OFFSET_RATIO,
        TUNE_TARGET_LIGHT_MIN_OFFSET
    )

    return math.abs((value or minParam) - target) <= offset
end

-- 调频界面使用：按滑条值计算写入音乐源的 Aisac 值。
-- 滑条位于 Target 时取峰值 AisacTargetValue，向 MinParam/MaxParam 两端偏离时按所在半区宽度对称回落到 0。
-- AisacTargetValue 配置非法时返回 0，错误在 GetTuningStageControlParamCfgs 构建缓存时上报。
function XConcertPreHeatingControl.GetTuneAisacValue(controlParamCfg, value)
    if not controlParamCfg then
        return 0
    end

    local aisacTargetValue = controlParamCfg.AisacTargetValue or 0
    if aisacTargetValue <= 0 or aisacTargetValue > 1 then
        return 0
    end

    local minParam = controlParamCfg.MinParam or 0
    local maxParam = controlParamCfg.MaxParam or 0
    local target = XMath.Clamp(controlParamCfg.Target or minParam, minParam, maxParam)
    value = XMath.Clamp(value or minParam, minParam, maxParam)

    if value <= target then
        local riseRange = target - minParam
        if riseRange <= 0 then
            return aisacTargetValue
        end

        return aisacTargetValue * (value - minParam) / riseRange
    end

    local fallRange = maxParam - target
    if fallRange <= 0 then
        return aisacTargetValue
    end

    return aisacTargetValue * (maxParam - value) / fallRange
end

-- 调频界面使用：计算内部匹配度。初始参数可能已有较高匹配度，不直接作为关卡完成度。
function XConcertPreHeatingControl:CalculateTuneMatchProgress(tuningStageId, values)
    local controlParamCfgs = self:GetTuningStageControlParamCfgs(tuningStageId)
    if XTool.IsTableEmpty(controlParamCfgs) then
        return 0
    end

    local accuracy = 0
    local tuneControlWeight = 1 / #controlParamCfgs

    for index, controlParamCfg in ipairs(controlParamCfgs) do
        local value = values and values[index] or controlParamCfg.MinParam
        local singleAccuracy = CalculateTuneAccuracy(controlParamCfg, value)
        accuracy = accuracy + singleAccuracy * tuneControlWeight
    end

    return ConvertTuneAccuracyToMatchProgress(accuracy)
end

function XConcertPreHeatingControl:GetTuneBaseMatchProgress(tuningStageId)
    self._TuningStageBaseMatchProgress = self._TuningStageBaseMatchProgress or {}
    if self._TuningStageBaseMatchProgress[tuningStageId] ~= nil then
        return self._TuningStageBaseMatchProgress[tuningStageId]
    end

    local controlParamCfgs = self:GetTuningStageControlParamCfgs(tuningStageId)
    if XTool.IsTableEmpty(controlParamCfgs) then
        return 0
    end

    local values = {}
    for index, controlParamCfg in ipairs(controlParamCfgs) do
        values[index] = controlParamCfg.MinParam or 0
    end

    local progress = self:CalculateTuneMatchProgress(tuningStageId, values)
    self._TuningStageBaseMatchProgress[tuningStageId] = progress
    return progress
end

-- 调频界面使用：计算关卡权威完成度。初始滑条状态为 0，目标状态为 100。
function XConcertPreHeatingControl:CalculateTuneProgress(tuningStageId, values)
    local matchProgress = self:CalculateTuneMatchProgress(tuningStageId, values)
    local baseProgress = self:GetTuneBaseMatchProgress(tuningStageId)
    return ConvertMatchProgressToTuneProgress(matchProgress, baseProgress)
end

function XConcertPreHeatingControl.IsTuneComplete(tuneProgress)
    return (tuneProgress or 0) >= TUNE_PROGRESS_MAX
end

return XConcertPreHeatingControl
