---@class XUiPanelLottoVolume : XUiNode
---@field Parent XUiGachaSelenaMain
local XUiPanelLottoVolume = XClass(XUiNode, "XUiPanelLottoVolume")

local XAudioManager = CS.XAudioManager
local Key = "GachaSelenaVolumeInit"

function XUiPanelLottoVolume:OnStart()
    self._YellowValue = tonumber(XGachaConfigs.GetClientConfig("SelenaVolumeValue"))
    self._InitWaitTime = tonumber(XGachaConfigs.GetClientConfig("SelenaVolumeInitWaitTime"))
    self._ClickWaitTime = tonumber(XGachaConfigs.GetClientConfig("SelenaVolumeClickWaitTime"))

    self.BtnActiveVolume.CallBack = handler(self, self.OnBtnActiveVolumeClick)
    XUiHelper.RegisterSliderChangeEvent(self, self.Slider, self.OnSlideValueChanged)
end

function XUiPanelLottoVolume:OnDestroy()
    self:RemoveTimer()
end

function XUiPanelLottoVolume:OnSlideValueChanged()
    XAudioManager.Mute(false)
    XAudioManager.ChangeMusicVolume(self.Slider.value)
    XAudioManager.ChangeSFXVolume(self.Slider.value)
    XAudioManager.ChangeVoiceVolume(self.Slider.value)

    self:ChangeTipColorImg()
    self:TweenClick()
end

function XUiPanelLottoVolume:ChangeTipColorImg()
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

function XUiPanelLottoVolume:PlayStart()
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

function XUiPanelLottoVolume:PlayEnd()
    -- 重置用户最后设置的音量
    XLuaAudioManager.ResetSystemAudioVolume()
    self:HideAll(true)
end

function XUiPanelLottoVolume:HideAll(isTween)
    self:RemoveTimer()
    if isTween then
        self:PlayHideSliderTween(true)
    else
        self.PanelSlider.gameObject:SetActiveEx(false)
        self:Close()
    end
end

function XUiPanelLottoVolume:PlayHideSliderTween(isCloseView)
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

function XUiPanelLottoVolume:ShowSlider()
    self.Parent:PlayAnimation("PanelVolumeEnable")
    self.PanelSlider.gameObject:SetActiveEx(true)
end

function XUiPanelLottoVolume:TweenInit()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._InitWaitTime)
end

function XUiPanelLottoVolume:TweenClick()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._ClickWaitTime)
end

function XUiPanelLottoVolume:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPanelLottoVolume:OnBtnActiveVolumeClick()
    if self.PanelSlider.gameObject.activeSelf then
        return
    end
    self:ShowSlider()
    self:TweenClick()
end

return XUiPanelLottoVolume
