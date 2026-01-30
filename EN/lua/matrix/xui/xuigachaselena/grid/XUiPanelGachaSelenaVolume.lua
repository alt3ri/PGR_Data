---@class XUiPanelGachaSelenaVolume : XUiNode 露西亚卡池音量调节
---@field Parent XUiGachaSelenaMain
local XUiPanelGachaSelenaVolume = XClass(XUiNode, "XUiPanelGachaSelenaVolume")

local XAudioManager = CS.XAudioManager
local Key = "GachaSelenaVolumeInit"

function XUiPanelGachaSelenaVolume:OnStart()
    self._YellowValue = tonumber(XGachaConfigs.GetClientConfig("SelenaVolumeValue"))
    self._InitWaitTime = tonumber(XGachaConfigs.GetClientConfig("SelenaVolumeInitWaitTime"))
    self._ClickWaitTime = tonumber(XGachaConfigs.GetClientConfig("SelenaVolumeClickWaitTime"))

    self.BtnActiveVolume.CallBack = handler(self, self.OnBtnActiveVolumeClick)
    XUiHelper.RegisterSliderChangeEvent(self, self.Slider, self.OnSlideValueChanged)
end

function XUiPanelGachaSelenaVolume:OnDestroy()
    self:RemoveTimer()
end

function XUiPanelGachaSelenaVolume:OnSlideValueChanged()
    XAudioManager.Mute(false)
    XAudioManager.ChangeMusicVolume(self.Slider.value)
    XAudioManager.ChangeSFXVolume(self.Slider.value)
    XAudioManager.ChangeVoiceVolume(self.Slider.value)

    self:ChangeTipColorImg()
    self:TweenClick()
end

function XUiPanelGachaSelenaVolume:ChangeTipColorImg()
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

function XUiPanelGachaSelenaVolume:PlayStart()
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

function XUiPanelGachaSelenaVolume:PlayEnd()
    -- 重置用户最后设置的音量
    XLuaAudioManager.ResetSystemAudioVolume()
    self:HideAll(true)
end

function XUiPanelGachaSelenaVolume:HideAll(isTween)
    self:RemoveTimer()
    if isTween then
        self:PlayHideSliderTween(true)
    else
        self.PanelSlider.gameObject:SetActiveEx(false)
        self:Close()
    end
end

function XUiPanelGachaSelenaVolume:PlayHideSliderTween(isCloseView)
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

function XUiPanelGachaSelenaVolume:ShowSlider()
    self.Parent:PlayAnimation("PanelVolumeEnable")
    self.PanelSlider.gameObject:SetActiveEx(true)
end

function XUiPanelGachaSelenaVolume:TweenInit()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._InitWaitTime)
end

function XUiPanelGachaSelenaVolume:TweenClick()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._ClickWaitTime)
end

function XUiPanelGachaSelenaVolume:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPanelGachaSelenaVolume:OnBtnActiveVolumeClick()
    if self.PanelSlider.gameObject.activeSelf then
        return
    end
    self:ShowSlider()
    self:TweenClick()
end

return XUiPanelGachaSelenaVolume
