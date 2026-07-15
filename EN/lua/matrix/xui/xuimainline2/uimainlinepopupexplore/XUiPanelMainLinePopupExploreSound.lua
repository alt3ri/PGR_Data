--- 弹窗人物“实时”通讯面板
---@class XUiPanelMainLinePopupExploreSound: XUiNode
---@field protected _Control
---@field Parent
local XUiPanelMainLinePopupExploreSound = XClass(XUiNode, "XUiPanelMainLinePopupExploreSound")

function XUiPanelMainLinePopupExploreSound:OnDisable()
    self:StopAudioPlay()
end

---@param contentCfg XTableMainLine2MessageContents
function XUiPanelMainLinePopupExploreSound:Refresh(contentCfg)
    self.UiTxtItemName.text = contentCfg.Name or ''
    self.UiSoundTxtDesc.text = contentCfg.Desc or ''

    if not string.IsNilOrEmpty(contentCfg.RoleIcon) then
        self.RImglItemIcon.gameObject:SetActiveEx(true)
        self.RImgItemNpc:SetRawImage(contentCfg.RoleIcon)
    else
        self.RImglItemIcon.gameObject:SetActiveEx(false)
    end

    -- 音频播放
    if XTool.IsNumberValidEx(contentCfg.CueId) then
        self.TxtTime.gameObject:SetActiveEx(true)

        self:StartAudioPlay(contentCfg.CueId)
    else
        self.TxtTime.gameObject:SetActiveEx(false)

        self:StopAudioPlay()
    end

    if self.Typewriter then
        self.Typewriter:Play()
    end
end

--region 音频播放相关

function XUiPanelMainLinePopupExploreSound:StopAudioPlay()
    if self._AudioProgressTimeId then
        XScheduleManager.UnSchedule(self._AudioProgressTimeId)
        self._AudioProgressTimeId = nil
    end

    if self._AudioInfo then
        self._AudioInfo:Stop()
        self._AudioInfo = nil
    end
end

function XUiPanelMainLinePopupExploreSound:StartAudioPlay(cueId)
    self:StopAudioPlay()
    self._AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)

    self:_UpdateAudioProgressShow()
    self._AudioProgressTimeId = XScheduleManager.ScheduleForever(handler(self, self._UpdateAudioProgressShow), XScheduleManager.SECOND)
end

function XUiPanelMainLinePopupExploreSound:_UpdateAudioProgressShow()
    if not self._AudioInfo then
        self:StopAudioPlay()
        return
    end

    local curTime = self._AudioInfo.Playing and math.max(0, self._AudioInfo.Time) or self._AudioInfo.Duration
    local leftTime = math.max(0, (self._AudioInfo.Duration - curTime) / XScheduleManager.SECOND)

    self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)

    if not self._AudioInfo.Playing then
        self:StopAudioPlay()
    end
end

--endregion

return XUiPanelMainLinePopupExploreSound