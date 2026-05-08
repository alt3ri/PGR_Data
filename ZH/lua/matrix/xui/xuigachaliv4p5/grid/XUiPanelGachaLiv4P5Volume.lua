---@class XUiPanelGachaLiv4P5Volume : XUiNode 丽芙4P5卡池音量调节
---@field Parent XUiGachaLiv4P5Main
local XUiPanelGachaLiv4P5Volume = XClass(XUiNode, "XUiPanelGachaLiv4P5Volume")

local XAudioManager = CS.XAudioManager
local Key = "GachaLiv4P5VolumeInit"

---@param gachaCfg XTableGacha
function XUiPanelGachaLiv4P5Volume:OnStart(gachaCfg)
    self._YellowValue = tonumber(XGachaConfigs.GetClientConfig("BiankaVolumeValue"))
    self._InitWaitTime = tonumber(XGachaConfigs.GetClientConfig("BiankaVolumeInitWaitTime"))
    self._ClickWaitTime = tonumber(XGachaConfigs.GetClientConfig("BiankaVolumeClickWaitTime"))

    self.BtnActiveVolume.CallBack = handler(self, self.OnBtnActiveVolumeClick)
    XUiHelper.RegisterSliderChangeEvent(self, self.Slider, self.OnSlideValueChanged)

    if self.BtnSkip then
        self.BtnSkip:AddEventListener(handler(self, self.OnBtnSkipClick))

        if gachaCfg and XTool.IsNumberValidEx(gachaCfg.EnterVideoId) then
            -- 视频模式需要显示跳过按钮
            self.BtnSkip.gameObject:SetActiveEx(true)
        else
            self.BtnSkip.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelGachaLiv4P5Volume:OnDestroy()
    self:RemoveTimer()
end

function XUiPanelGachaLiv4P5Volume:OnSlideValueChanged()
    XAudioManager.Mute(false)
    XAudioManager.ChangeMusicVolume(self.Slider.value)
    XAudioManager.ChangeSFXVolume(self.Slider.value)
    XAudioManager.ChangeVoiceVolume(self.Slider.value)

    self:ChangeTipColorImg()
    self:TweenClick()
end

function XUiPanelGachaLiv4P5Volume:ChangeTipColorImg()
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

function XUiPanelGachaLiv4P5Volume:PlayStart()
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

function XUiPanelGachaLiv4P5Volume:PlayEnd()
    -- 重置用户最后设置的音量
    XLuaAudioManager.ResetSystemAudioVolume()
    self:HideAll(true)
end

function XUiPanelGachaLiv4P5Volume:HideAll(isTween)
    self:RemoveTimer()
    if isTween then
        self:PlayHideSliderTween(true)
    else
        self.PanelSlider.gameObject:SetActiveEx(false)
        self:Close()
    end
end

function XUiPanelGachaLiv4P5Volume:PlayHideSliderTween(isCloseView)
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

function XUiPanelGachaLiv4P5Volume:ShowSlider()
    self.Parent:PlayAnimation("PanelVolumeEnable")
    self.PanelSlider.gameObject:SetActiveEx(true)
end

function XUiPanelGachaLiv4P5Volume:TweenInit()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._InitWaitTime)
end

function XUiPanelGachaLiv4P5Volume:TweenClick()
    self:RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self:PlayHideSliderTween()
    end, self._ClickWaitTime)
end

function XUiPanelGachaLiv4P5Volume:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPanelGachaLiv4P5Volume:OnBtnActiveVolumeClick()
    if self.PanelSlider.gameObject.activeSelf then
        return
    end
    self:ShowSlider()
    self:TweenClick()
end

function XUiPanelGachaLiv4P5Volume:OnBtnSkipClick()
    -- 跳过视频
    if self.Parent._CG then
        self.Parent._CG:StopCG(true)
    end
    
    self:Close()
end

return XUiPanelGachaLiv4P5Volume
