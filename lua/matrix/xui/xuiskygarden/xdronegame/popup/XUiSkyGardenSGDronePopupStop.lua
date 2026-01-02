---@class XUiSkyGardenSGDronePopupStop : XBigWorldUi
---@field BtnTanchuangClose XUiComponent.XUiButtonExt
---@field TxtTeach UnityEngine.UI.Text
---@field BtnLeave XUiComponent.XUiButtonExt
---@field BtnCancel XUiComponent.XUiButtonExt
---@field BtnConfirm XUiComponent.XUiButtonExt
---@field Visual UnityEngine.RectTransform
---@field BtnVideo XUiComponent.XUiButton
---@field VideoPlayer XVideoPlayerUGUI
---@field ImgPlay UnityEngine.UI.Image
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDronePopupStop = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDronePopupStop")

function XUiSkyGardenSGDronePopupStop:OnAwake()
    self._StageId = 0
    self._IsPlaying = false

    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDronePopupStop:OnStart(stageId, droneId)
    self._StageId = stageId
    self:_Refresh(droneId)
    self:_RefreshVideo(droneId)
end

function XUiSkyGardenSGDronePopupStop:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDronePopupStop:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDronePopupStop:OnDestroy()
end

function XUiSkyGardenSGDronePopupStop:OnBtnVideoClick()
    if self._IsPlaying then
        self.VideoPlayer:Stop()
        self._IsPlaying = false
        self.ImagePlay.gameObject:SetActiveEx(true)
    else
        self.VideoPlayer:Prepare()
        self._IsPlaying = true
        self.ImagePlay.gameObject:SetActiveEx(false)
    end
end

function XUiSkyGardenSGDronePopupStop:OnBtnCloseClick()
    self:Close()
    CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.ResumeGame()
end

function XUiSkyGardenSGDronePopupStop:OnBtnConfirmClick()
    self:Close()
    CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.RestoreGame()
end

function XUiSkyGardenSGDronePopupStop:OnBtnCancelClick()
    self:Close()
    CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.RestartGame()
end

function XUiSkyGardenSGDronePopupStop:OnBtnLeaveClick()
    local instance = CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.Instance
    local settleType = self._Control.SettleType.Leave
    local collectCount = instance.Engine.StageData.CollectCount
    local recordData = instance.Engine.RecordData

    self._Control:RecordStage(self._StageId, recordData, collectCount, settleType)

    self:Close()
    
    if instance.Engine.HasArchive then
        XMVCA.XBigWorldUI:SafeClose("UiSkyGardenSGDroneStageDetail")
        XMVCA.XBigWorldUI:SafeClose("UiSkyGardenSGDroneStage")
        XMVCA.XBigWorldUI:SafeClose("UiSkyGardenSGDroneChapter")
    end

    CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.ReleaseGame()
end

function XUiSkyGardenSGDronePopupStop:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnVideo:AddEventListener(Handler(self, self.OnBtnVideoClick))
    self.BtnLeave:AddEventListener(Handler(self, self.OnBtnLeaveClick))
    self.BtnCancel:AddEventListener(Handler(self, self.OnBtnCancelClick))
    self.BtnConfirm:AddEventListener(Handler(self, self.OnBtnConfirmClick))
    self.BtnTanchuangClose:AddEventListener(Handler(self, self.OnBtnCloseClick))
end

function XUiSkyGardenSGDronePopupStop:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDronePopupStop:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDronePopupStop:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDronePopupStop:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDronePopupStop:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDronePopupStop:_Refresh(droneId)
    local hasArchive = CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance.Instance.Engine.HasArchive

    self.TxtTeach.text = self._Control:GetDroneDescription(droneId)
    self.BtnConfirm.gameObject:SetActiveEx(hasArchive)
    self.BtnCancel.gameObject:SetActiveEx(not hasArchive)
end

function XUiSkyGardenSGDronePopupStop:_RefreshVideo(droneId)
    local videoId = self._Control:GetDroneTeachingVideoId(droneId)

    if XTool.IsNumberValid(videoId) then
        self._IsPlaying = false
        self.Visual.gameObject:SetActiveEx(true)
        self.BtnVideo.gameObject:SetActiveEx(true)
        self.VideoPlayer:SetInfoByVideoId(videoId)
    else
        self.BtnVideo.gameObject:SetActiveEx(false)
    end
end

return XUiSkyGardenSGDronePopupStop
