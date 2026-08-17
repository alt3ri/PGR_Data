---@class XConcertPreHeatingControl : XControl
---@field private _Model XConcertPreHeatingModel
local XConcertPreHeatingControl = XClass(XControl, "XConcertPreHeatingControl", false)

local TUNE_PERCENT_MAX = 100
local TUNE_TARGET_LIGHT_OFFSET_RATIO = 0.005
local TUNE_TARGET_LIGHT_MIN_OFFSET = 0.001

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

-- 调频数值由原始输入派生出三层语义，禁止混用：
-- 输入 controlValue：单杆 Slider 的原始值，对应 ControlParam 的 MinParam/MaxParam/Target。
-- 1. controlAccuracy：单杆原始值对 Target 的接近度，范围 0~100；初始值不一定为 0。
--    例如 Min=0、Max=100、Target=70、controlValue=0 时，单杆准确度是 30，而不是 0。
-- 2. matchProgress：所有单杆准确度取平均后再经手感曲线映射的内部匹配进度；
--    它保留了初始杆位自带的匹配度，只用于换算，不直接交给 UI 或完成判定。
-- 3. stageProgress：从 matchProgress 中扣除本关初始匹配进度后重新归一化的权威关卡完成度；
--    初始杆位恒为 0，平均单杆准确度达到完成阈值时为 100，供点云、信号提示和关卡完成判定消费。
local function CalculateControlAccuracy(controlParamCfg, controlValue)
    local minParam = controlParamCfg.MinParam or 0
    local maxParam = controlParamCfg.MaxParam or 0
    local range = maxParam - minParam
    if range <= 0 then
        return 0
    end

    local target = controlParamCfg.Target or minParam
    local controlAccuracy = TUNE_PERCENT_MAX
        - math.abs((controlValue or minParam) - target) / range * TUNE_PERCENT_MAX
    return XMath.Clamp(controlAccuracy, 0, TUNE_PERCENT_MAX)
end

local function ConvertAverageControlAccuracyToMatchProgress(averageControlAccuracy, completionAverageAccuracy)
    averageControlAccuracy = XMath.Clamp(averageControlAccuracy or 0, 0, TUNE_PERCENT_MAX)
    -- completionAverageAccuracy 未传时取 0，使任何准确度都判定完成，暴露漏配。
    completionAverageAccuracy = completionAverageAccuracy or 0
    if averageControlAccuracy >= completionAverageAccuracy then
        return TUNE_PERCENT_MAX
    end

    local matchProgress
    if averageControlAccuracy <= 20 then
        matchProgress = averageControlAccuracy
    elseif averageControlAccuracy <= 75 then
        matchProgress = 20 + (averageControlAccuracy - 20) * 1.27
    else
        matchProgress = 90 + (averageControlAccuracy - 75)
    end

    return XMath.Clamp(matchProgress, 0, TUNE_PERCENT_MAX)
end

local function ConvertMatchProgressToStageProgress(matchProgress, initialMatchProgress)
    local matchProgressRange = TUNE_PERCENT_MAX - (initialMatchProgress or 0)
    if matchProgressRange <= 0 then
        return matchProgress >= TUNE_PERCENT_MAX and TUNE_PERCENT_MAX or 0
    end

    local stageProgress = ((matchProgress or 0) - (initialMatchProgress or 0))
        / matchProgressRange * TUNE_PERCENT_MAX
    return XMath.Clamp(stageProgress, 0, TUNE_PERCENT_MAX)
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

-- 调频界面使用：完成后滑条吸附到目标值的过渡时长（秒），未配置时报错，非正数视为瞬间吸附。
function XConcertPreHeatingControl:GetTuneSnapTransitionTime()
    local config = self._Model:GetClientConfigCfg("TuneSnapTransitionTimeSecond")
    local value = config and tonumber(config.Values[1])
    if not value then
        XLog.Error("ConcertClientConfig missing config, Id: TuneSnapTransitionTimeSecond")
        return 0
    end

    return value
end

-- 计算内部匹配进度；结果仅供 CalculateTuneStageProgress 做初始值归零换算。
local function CalculateTuneMatchProgress(controlParamCfgs, controlValues, completionAverageAccuracy)
    local averageControlAccuracy = 0
    local controlWeight = 1 / #controlParamCfgs

    for index, controlParamCfg in ipairs(controlParamCfgs) do
        local controlValue = controlValues and controlValues[index] or controlParamCfg.MinParam
        local controlAccuracy = CalculateControlAccuracy(controlParamCfg, controlValue)
        averageControlAccuracy = averageControlAccuracy + controlAccuracy * controlWeight
    end

    return ConvertAverageControlAccuracyToMatchProgress(averageControlAccuracy, completionAverageAccuracy)
end

-- 唯一对外的调频关卡完成度：初始杆位为 0，完成为 100，供 UI 表现和完成判定消费。
function XConcertPreHeatingControl:CalculateTuneStageProgress(tuningStageId, controlValues)
    local controlParamCfgs = self:GetTuningStageControlParamCfgs(tuningStageId)
    if XTool.IsTableEmpty(controlParamCfgs) then
        return 0
    end

    local completionAccuracyCfg = self._Model:GetClientConfigCfg("TuneCompleteAccuracy")
    local completionAverageAccuracy = completionAccuracyCfg and tonumber(completionAccuracyCfg.Values[1])
    if not completionAverageAccuracy then
        XLog.Error("ConcertClientConfig missing config, Id: TuneCompleteAccuracy")
        completionAverageAccuracy = 0
    end

    local matchProgress = CalculateTuneMatchProgress(controlParamCfgs, controlValues, completionAverageAccuracy)
    self._TuningStageInitialMatchProgressMap = self._TuningStageInitialMatchProgressMap or {}
    local initialMatchProgress = self._TuningStageInitialMatchProgressMap[tuningStageId]
    if initialMatchProgress == nil then
        local initialControlValues = {}
        for index, controlParamCfg in ipairs(controlParamCfgs) do
            initialControlValues[index] = controlParamCfg.MinParam or 0
        end

        initialMatchProgress = CalculateTuneMatchProgress(
            controlParamCfgs,
            initialControlValues,
            completionAverageAccuracy
        )
        self._TuningStageInitialMatchProgressMap[tuningStageId] = initialMatchProgress
    end

    return ConvertMatchProgressToStageProgress(matchProgress, initialMatchProgress)
end

-- 只接受 CalculateTuneStageProgress 返回的权威关卡完成度，不接受单杆准确度或内部匹配进度。
function XConcertPreHeatingControl.IsTuneStageComplete(stageProgress)
    return (stageProgress or 0) >= TUNE_PERCENT_MAX
end

function XConcertPreHeatingControl:OnRelease()
    self._TuningStageControlParamCfgs = nil
    self._TuningStageInitialMatchProgressMap = nil
end

return XConcertPreHeatingControl
