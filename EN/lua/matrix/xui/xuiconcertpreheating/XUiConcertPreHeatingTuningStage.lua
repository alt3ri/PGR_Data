---@class XUiConcertPreHeatingTuningStage : XLuaUi
---@field _Control XConcertPreHeatingControl
local XUiConcertPreHeatingTuningStage = XLuaUiManager.Register(XLuaUi, "UiConcertPreHeatingTuningStage")
local XUiConcertPreHeatingPanelSpine = require("XUi/XUiConcertPreHeating/Grid/XUiConcertPreHeatingPanelSpine")

function XUiConcertPreHeatingTuningStage:OnAwake()
    self._Sliders = { self.Slider1, self.Slider2, self.Slider3, self.Slider4 }
    local lights = { self.ImgSliderLightOn1, self.ImgSliderLightOn2, self.ImgSliderLightOn3, self.ImgSliderLightOn4 }
    self._SliderTargetLights = lights
    self._SliderValues = {}

    self:InitButton()
    self:InitSliderEvent()
    self:InitPanelSpine()
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

local function GetSignalTipText(tuneProgress)
    if tuneProgress < 70 then
        return XUiHelper.GetText("ConcertPreHeatingTuneSignalFar")
    end

    if tuneProgress < 80 then
        return XUiHelper.GetText("ConcertPreHeatingTuneSignalNear")
    end

    if tuneProgress < 95 then
        return XUiHelper.GetText("ConcertPreHeatingTuneSignalVeryNear")
    end

    return XUiHelper.GetText("ConcertPreHeatingTuneSignalSyncing")
end

function XUiConcertPreHeatingTuningStage:RefreshChannelTips(tuneProgress)
    self.PanelChannelTips.gameObject:SetActiveEx(not self._IsFinished)
    if self._IsFinished then
        return
    end

    self.PanelBeforeSearch.gameObject:SetActiveEx(not self._HasSearch)
    self.PanelSignal.gameObject:SetActiveEx(self._HasSearch)

    if self._HasSearch then
        self.TxtSignalTips.text = GetSignalTipText(tuneProgress or 0)
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

-- 按当前滑条值刷新调频表现，并返回当前调频进度。
function XUiConcertPreHeatingTuningStage:RefreshSliderDrivenState()
    local sliderValues = self._SliderValues
    for index, controlParamCfg in ipairs(self._ControlParamCfgs) do
        local slider = self._Sliders[index]
        sliderValues[index] = slider and slider.value or controlParamCfg.MinParam
        if slider and not string.IsNilOrEmpty(controlParamCfg.AisacControlName) then
            local aisacValue = self._Control.GetTuneAisacValue(controlParamCfg, sliderValues[index])
            CS.XAudioManager.ChangeMusicSourceAisac(controlParamCfg.AisacControlName, aisacValue)
        end
    end

    for index = #self._ControlParamCfgs + 1, #sliderValues do
        sliderValues[index] = nil
    end

    local tuneProgress = self._Control:CalculateTuneProgress(self._TuningStageId, sliderValues)
    self:RefreshSliderTargetLights()
    self.TargetImagePointCloudMorph:SetMorphProgress((tuneProgress or 0) / 100)
    self:RefreshChannelTips(tuneProgress)
    -- TODO：SandControlType/CueControlType 枚举和表现接口确定后，在这里驱动音频和强度分档表现。

    return tuneProgress
end

function XUiConcertPreHeatingTuningStage:OnSliderValueChanged()
    if self._IsFinished then
        return
    end

    self._HasSearch = true
    local tuneProgress = self:RefreshSliderDrivenState()
    self:TryFinishTuneStage(tuneProgress)
end

-- 玩家操作后检查是否完成调频关卡。
function XUiConcertPreHeatingTuningStage:TryFinishTuneStage(tuneProgress)
    if self._IsFinished then
        return
    end

    if not self._Control.IsTuneComplete(tuneProgress) then
        return
    end

    self:FinishTuneStage()
end

-- 完成时将滑条吸附到目标值。
function XUiConcertPreHeatingTuningStage:SyncSliderToTarget()
    for index, controlParamCfg in ipairs(self._ControlParamCfgs) do
        local slider = self._Sliders[index]
        local target = controlParamCfg.Target or controlParamCfg.MinParam or 0
        if slider then
            slider:SetValueWithoutNotify(target)
        end
    end

    self:RefreshSliderDrivenState()
end

function XUiConcertPreHeatingTuningStage:FinishTuneStage()
    self._IsFinished = true
    for _, slider in ipairs(self._Sliders) do
        slider.enabled = false
        slider.interactable = false
    end

    self:SyncSliderToTarget()
    self.TargetImagePointCloudMorph.gameObject:SetActiveEx(false)

    XMVCA.XConcertPreHeating:ConcertPreHeatingSettleRequest(self._TuningStageId, XTime.GetServerNowTimestamp() - self._StageStartTime)
    XLuaUiManager.Open("UiConcertPreHeatingTuningStageCorrectTips", function() self:OnCorrectTipsClose() end)
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
