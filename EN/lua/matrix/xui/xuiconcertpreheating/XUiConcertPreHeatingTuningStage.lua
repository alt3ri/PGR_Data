---@class XUiConcertPreHeatingTuningStage : XLuaUi
---@field _Control XConcertPreHeatingControl
local XUiConcertPreHeatingTuningStage = XLuaUiManager.Register(XLuaUi, "UiConcertPreHeatingTuningStage")
local XUiConcertPreHeatingPanelSpine = require("XUi/XUiConcertPreHeating/Grid/XUiConcertPreHeatingPanelSpine")

function XUiConcertPreHeatingTuningStage:OnAwake()
    self._Sliders = { self.Slider1, self.Slider2, self.Slider3, self.Slider4 }
    local lights = { self.ImgSliderLightOn1, self.ImgSliderLightOn2, self.ImgSliderLightOn3, self.ImgSliderLightOn4 }
    self._SliderTargetLights = lights
    self._ControlValues = {}

    self:InitButton()
    self:InitSliderEvent()
    self:InitPanelSpine()
end

function XUiConcertPreHeatingTuningStage:OnDestroy()
    self:StopSnapTransition()
end

function XUiConcertPreHeatingTuningStage:InitButton()
    self:BindHelpBtn(self.BtnHelp, "ConcertPreHeatingHelp")
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnSoundSet.CallBack = function() XLuaUiManager.Open("UiSet") end
end

function XUiConcertPreHeatingTuningStage:InitSliderEvent()
    for _, slider in ipairs(self._Sliders) do
        XUiHelper.RegisterSliderChangeEvent(self, slider, self.OnSliderValueChanged)
    end
end

function XUiConcertPreHeatingTuningStage:InitPanelSpine()
    self.PanelSpineNode = XUiConcertPreHeatingPanelSpine.New(self.PanelSpine, self, function() self:Close() end)
end

function XUiConcertPreHeatingTuningStage:OnStart(tuningStageId)
    self:InitTime()
    self._TuningStageId = tuningStageId
    self._ControlParamCfgs = self._Control:GetTuningStageControlParamCfgs(tuningStageId)
    self._HasSearch = false
    self._IsFinished = false
    self._StageStartTime = XTime.GetServerNowTimestamp()

    local cueId = self._Control:GetStageCueId(self._TuningStageId)
    if XTool.IsNumberValid(cueId) then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, cueId)
    end
    self:InitSliders()
    self:InitPointCloudMorph()
    self.PanelPlay.gameObject:SetActiveEx(true)
    self.PanelSpineNode:Close()
    self:RefreshSliderDrivenState()
end

function XUiConcertPreHeatingTuningStage:InitTime()
    local endTime = XMVCA.XConcertPreHeating:GetActivityEndTime()
    if not XTool.IsNumberValid(endTime) then
        return
    end

    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XMVCA.XConcertPreHeating:HandleActivityEnd()
        end
    end)
end

function XUiConcertPreHeatingTuningStage:InitSliders()
    for index, slider in ipairs(self._Sliders) do
        local controlParamCfg = self._ControlParamCfgs[index]
        slider.gameObject:SetActiveEx(controlParamCfg ~= nil)
        slider.enabled = controlParamCfg ~= nil
        slider.interactable = controlParamCfg ~= nil

        if controlParamCfg then
            local minParam = controlParamCfg.MinParam or 0
            local maxParam = controlParamCfg.MaxParam or 0
            slider.minValue = minParam
            slider.maxValue = maxParam
            slider:SetBorderValue(minParam, maxParam)
            slider:SetValueWithoutNotify(minParam)
        end
    end
end

function XUiConcertPreHeatingTuningStage:InitPointCloudMorph()
    local gamePlaySilhouetteImg = self._Control:GetStageGamePlaySilhouetteImg(self._TuningStageId)
    self.TargetImagePointCloudMorph.gameObject:SetActiveEx(true)
    self.TargetImagePointCloudMorph:SetScatterSeed(self._TuningStageId or 0)
    self.TargetImagePointCloudMorph:SetRawImage(gamePlaySilhouetteImg)
    self.TargetImagePointCloudMorph:SetMorphProgress(0)
end

local function GetSignalTipText(stageProgress)
    if stageProgress < 70 then
        return XUiHelper.GetText("ConcertPreHeatingTuneSignalFar")
    end

    if stageProgress < 80 then
        return XUiHelper.GetText("ConcertPreHeatingTuneSignalNear")
    end

    if stageProgress < 95 then
        return XUiHelper.GetText("ConcertPreHeatingTuneSignalVeryNear")
    end

    return XUiHelper.GetText("ConcertPreHeatingTuneSignalSyncing")
end

function XUiConcertPreHeatingTuningStage:RefreshChannelTips(stageProgress)
    self.PanelChannelTips.gameObject:SetActiveEx(not self._IsFinished)
    if self._IsFinished then
        return
    end

    self.PanelBeforeSearch.gameObject:SetActiveEx(not self._HasSearch)
    self.PanelSignal.gameObject:SetActiveEx(self._HasSearch)

    if self._HasSearch then
        self.TxtSignalTips.text = GetSignalTipText(stageProgress or 0)
    end
end

function XUiConcertPreHeatingTuningStage:RefreshSliderTargetLights()
    for index, light in ipairs(self._SliderTargetLights) do
        if light then
            local slider = self._Sliders[index]
            local controlParamCfg = self._ControlParamCfgs and self._ControlParamCfgs[index]
            local isTarget = slider and self._Control.IsTuneControlTarget(controlParamCfg, slider.value)
            light.gameObject:SetActiveEx(isTarget)
        end
    end
end

-- 按当前滑条值刷新调频表现，并返回权威关卡完成度。
function XUiConcertPreHeatingTuningStage:RefreshSliderDrivenState()
    local controlValues = self._ControlValues
    for index, controlParamCfg in ipairs(self._ControlParamCfgs) do
        local slider = self._Sliders[index]
        controlValues[index] = slider and slider.value or controlParamCfg.MinParam
        if slider and not string.IsNilOrEmpty(controlParamCfg.AisacControlName) then
            local aisacValue = self._Control.GetTuneAisacValue(controlParamCfg, controlValues[index])
            CS.XAudioManager.ChangeMusicSourceAisac(controlParamCfg.AisacControlName, aisacValue)
        end
    end

    for index = #self._ControlParamCfgs + 1, #controlValues do
        controlValues[index] = nil
    end

    local stageProgress = self._Control:CalculateTuneStageProgress(self._TuningStageId, controlValues)
    self:RefreshSliderTargetLights()
    self.TargetImagePointCloudMorph:SetMorphProgress((stageProgress or 0) / 100)
    self:RefreshChannelTips(stageProgress)
    -- TODO：SandControlType/CueControlType 枚举和表现接口确定后，在这里驱动音频和强度分档表现。

    return stageProgress
end

function XUiConcertPreHeatingTuningStage:OnSliderValueChanged()
    if self._IsFinished then
        return
    end

    self._HasSearch = true
    local stageProgress = self:RefreshSliderDrivenState()
    self:TryFinishTuneStage(stageProgress)
end

-- 玩家操作后使用权威关卡完成度检查是否完成调频关卡。
function XUiConcertPreHeatingTuningStage:TryFinishTuneStage(stageProgress)
    if self._IsFinished then
        return
    end

    if not self._Control.IsTuneStageComplete(stageProgress) then
        return
    end

    self:FinishTuneStage()
end

-- 完成时将滑条吸附到目标值：配置过渡时间 > 0 时逐帧平滑过渡，否则瞬间吸附。
function XUiConcertPreHeatingTuningStage:SyncSliderToTarget(onComplete)
    self:StopSnapTransition()

    local transitionTime = self._Control:GetTuneSnapTransitionTime()
    if not transitionTime or transitionTime <= 0 then
        self:ApplySliderTargetValues(1)
        if onComplete then
            onComplete()
        end
        return
    end

    -- 记录每条滑条的起点值，按归一化进度插值到目标。
    self._SnapStartValues = {}
    for index, controlParamCfg in ipairs(self._ControlParamCfgs) do
        local slider = self._Sliders[index]
        self._SnapStartValues[index] = slider and slider.value or (controlParamCfg.MinParam or 0)
    end

    local elapsed = 0
    self._SnapTransitionTimer = XScheduleManager.ScheduleForever(function()
        elapsed = elapsed + (CS.UnityEngine.Time.deltaTime or 0)
        local progress = XMath.Clamp(elapsed / transitionTime, 0, 1)
        self:ApplySliderTargetValues(progress)

        if progress >= 1 then
            self:StopSnapTransition()
            if onComplete then
                onComplete()
            end
        end
    end, 0)
end

-- 按归一化进度把滑条从起点插值到目标值；progress>=1 直接落到目标。
function XUiConcertPreHeatingTuningStage:ApplySliderTargetValues(progress)
    for index, controlParamCfg in ipairs(self._ControlParamCfgs) do
        local slider = self._Sliders[index]
        if slider then
            local target = controlParamCfg.Target or controlParamCfg.MinParam or 0
            local value = target
            if progress < 1 then
                local startValue = self._SnapStartValues and self._SnapStartValues[index] or target
                value = startValue + (target - startValue) * progress
            end
            slider:SetValueWithoutNotify(value)
        end
    end

    self:RefreshSliderDrivenState()
end

function XUiConcertPreHeatingTuningStage:StopSnapTransition()
    if self._SnapTransitionTimer then
        XScheduleManager.UnSchedule(self._SnapTransitionTimer)
        self._SnapTransitionTimer = nil
    end
    self._SnapStartValues = nil
end

function XUiConcertPreHeatingTuningStage:FinishTuneStage()
    self._IsFinished = true
    for _, slider in ipairs(self._Sliders) do
        slider.enabled = false
        slider.interactable = false
    end

    -- 完成耗时在命中时刻固定，不把吸附过渡时间算进上报值。
    local settleDuration = XTime.GetServerNowTimestamp() - self._StageStartTime
    -- 吸附过渡结束后再隐藏点云并发起结算，保证过渡过程玩家可见。
    self:SyncSliderToTarget(function()
        self.TargetImagePointCloudMorph.gameObject:SetActiveEx(false)
        XMVCA.XConcertPreHeating:ConcertPreHeatingSettleRequest(self._TuningStageId, settleDuration)
        XLuaUiManager.Open("UiConcertPreHeatingTuningStageCorrectTips", function() self:OnCorrectTipsClose() end)
    end)
end

function XUiConcertPreHeatingTuningStage:OnCorrectTipsClose()
    if self._Control:IsMainPerformanceStage(self._TuningStageId) then
        -- 关闭 Stage 前先通知栈里的 Main，让它回到 OnEnable 时播最终演出。
        XEventManager.DispatchEvent(XEventId.EVENT_CONCERT_PRE_HEATING_PLAY_MAIN_PERFORMANCE, self._TuningStageId)
        self:Close()
        return
    end

    self:PlayStageCompletePerformance()
end

function XUiConcertPreHeatingTuningStage:PlayStageCompletePerformance()
    local spinePrefabUrl = self._Control:GetStageCompleteSpinePrefabUrl(self._TuningStageId)
    if string.IsNilOrEmpty(spinePrefabUrl) then
        self:Close()
        return
    end

    self.PanelSpineNode:LoadSpinePrefab(spinePrefabUrl)
    self:PlayAnimationWithMask("StageFinish")
    local stageFinish = self.Transform:Find("Animation/StageFinish")
    local playableDirector = stageFinish:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    local delayTime = (playableDirector.duration or 0) / 2
    if delayTime <= 0 then
        self:ShowStageSpine()
        return
    end

    self:DelayCall(function() self:ShowStageSpine() end, delayTime)
end

function XUiConcertPreHeatingTuningStage:ShowStageSpine()
    self.PanelSpineNode:Open()
    self.PanelSpineNode:PlaySpinePerformance(true, function()
        self.PanelPlay.gameObject:SetActiveEx(false)
    end)
end

return XUiConcertPreHeatingTuningStage
