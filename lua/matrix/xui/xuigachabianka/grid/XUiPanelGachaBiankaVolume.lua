---@class XUiPanelGachaBiankaVolume : XUiNode 比安卡卡池音量调节
---@field Parent XUiGachaBiankaMain
local XUiPanelGachaBiankaVolume = XClass(XUiNode, "XUiPanelGachaBiankaVolume")

local XAudioManager = CS.XAudioManager
local Key = "GachaBiankaVolumeInit"

function XUiPanelGachaBiankaVolume:OnStart()
    self._YellowValue = tonumber(XGachaConfigs.GetClientConfig("BiankaVolumeValue"))
    self._InitWaitTime = tonumber(XGachaConfigs.GetClientConfig("BiankaVolumeInitWaitTime"))
    self._ClickWaitTime = tonumber(XGachaConfigs.GetClientConfig("BiankaVolumeClickWaitTime"))

    self.BtnActiveVolume.CallBack = handler(self, self.OnBtnActiveVolumeClick)
    XUiHelper.RegisterSliderChangeEvent(self, self.Slider, self.OnSlideValueChanged)
end

function XUiPanelGachaBiankaVolume:OnDestroy()
    self:RemoveTimer()
end

function XUiPanelGachaBiankaVolume:OnSlideValueChanged()
    XAudioManager.Mute(false)
    XAudioManager.ChangeMusicVolume(self.Slider.value)
    XAudioManager.ChangeSFXVolume(self.Slider.value)
    XAudioManager.ChangeVoiceVolume(self.Slider.value)

    self:ChangeTipColorImg()
    self:TweenClick()
end

function XUiPanelGachaBiankaVolume:ChangeTipColorImg()
    if not CS.XAudioManager.CheckAudioCanPlayLevel() then
        self.ImgRed.gameObject:SetActiveEx(true)
        self.ImgYellow.gameObject:SetActiveEx(false)
        self.ImgGreen.gameObject:SetActiveEx(false)
    elseif self.Slider.value <= self._YellowValue then
        self.ImgRed.gameObject:SetActiveEx(false)
        self.ImgYellow.gameObject:SetActiveEx(true)
        self.ImgGreen.gameObject:SetActiveEx(false)
    else
        self.ImgRed.gameObject:SetActiveEx(false)
        self.ImgYellow.gameObject:SetActiveEx(false)
        self.ImgGreen.gameObject:SetActiveEx(true)
    end
end

function XUiPanelGachaBiankaVolume:PlayStart()
    self:Open()

    local musicVolume = XLuaAudioManager.GetCategoriesVolumeByType(XLuaAudioManager.SoundType.Music)
    local sfxVolume = XLuaAudioManager.GetCategoriesVolumeByType(XLuaAudioManager.SoundType.SFX)
    local voiceVolume = XLuaAudioManager.GetCategoriesVolumeByType(XLuaAudioManager.SoundType.Voice)
    self.Slider.value = math.min(musicVolume, sfxVolume, voiceVolume)
    self:ChangeTipColorImg()

    local isInit = not XSaveTool.GetData(Key)
    if isInit then
        self:ShowSlider()
        self:TweenInit()
    else
        self.PanelSlider.gameObject:SetActiveEx(false)
    end

    XSaveTool.SaveData(Key, true)
end

function XUiPanelGachaBiankaVolume:PlayEnd()
    -- 重置用户最后设置的音量
    XLuaAudioManager.ResetSystemAudioVolume()
    self:HideAll(true)
end

function XUiPanelGachaBiankaVolume:HideAll(isTween)
    self:RemoveTimer()
    if isTween then
        self:PlayHideSliderTween(true)
    else
        self.PanelSlider.gameObject:SetActiveEx(false)
        self:Close()
    end
end

function XUiPanelGachaBiankaVolume:PlayHideSliderTween(isCloseView)
    if self.PanelSlider.gameObject.activeSelf then
        self.Parent:PlayAnimation("PanelVolumeDisable", function()
            self.PanelSlider.gameObject:SetActiveEx(false)
            if isCloseView then
                self:Close()
            end
        end)
    else
        if isCloseView then
            self:Close()
        end
    end
end

function XUiPanelGachaBiankaVolume:ShowSlider()
    self.Parent:PlayAnimation("PanelVolumeEnable")
    self.PanelSlider.gameObject:SetActiveEx(true)
end

function XUiPanelGachaBiankaVolume:TweenInit()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._InitWaitTime)
end

function XUiPanelGachaBiankaVolume:TweenClick()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._ClickWaitTime)
end

function XUiPanelGachaBiankaVolume:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPanelGachaBiankaVolume:OnBtnActiveVolumeClick()
    if self.PanelSlider.gameObject.activeSelf then
        return
    end
    self:ShowSlider()
    self:TweenClick()
end

return XUiPanelGachaBiankaVolume
