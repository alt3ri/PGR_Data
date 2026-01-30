
---@class XUiBigWorldPreviewFullScreenVideo : XUiNode
---@field VideoPlayer XVideoPlayerUGUI
---@field RImgVideo UnityEngine.UI.RawImage
---@field BtnSkip XUiComponent.XUiButton
---@field BtnPause XUiComponent.XUiButton
---@field Parent XUiBigWorldVideoPreview
local XUiBigWorldPreviewFullScreenVideo = XClass(XUiNode, "XUiBigWorldPreviewFullScreenVideo")

function XUiBigWorldPreviewFullScreenVideo:OnStart()
    ---@type XPreviewData
    self._Data = false

    self:_RegisterButtonClicks()
end

function XUiBigWorldPreviewFullScreenVideo:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldPreviewFullScreenVideo:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldPreviewFullScreenVideo:OnDestroy()
    self.VideoPlayer.ActionEnded = nil
end

function XUiBigWorldPreviewFullScreenVideo:OnVideoFinish()
    self.Parent:PlayVideoFinish()
    if self._Data and self._Data.IsAutoClose then
        self.Parent:Close()
    end
end

function XUiBigWorldPreviewFullScreenVideo:OnBtnSkipClick()
    self.VideoPlayer:Stop()
    self.Parent:Close()
end

function XUiBigWorldPreviewFullScreenVideo:OnBtnPauseClick()
    if not self.VideoPlayer:IsPaused() then
        self.VideoPlayer:Pause()
    else
        self.VideoPlayer:Resume()
    end
end

---@param data XPreviewData
function XUiBigWorldPreviewFullScreenVideo:Refresh(data)
    self:RefreshWithoutPlay(data)
    self:PlayVideo()
end

function XUiBigWorldPreviewFullScreenVideo:RefreshWithoutPlay(data)
    if not data or not data:IsVideoValid() then
        return
    end
    
    self._Data = data
    self.VideoPlayer:SetInfoByVideoId(data.VideoId)
end

function XUiBigWorldPreviewFullScreenVideo:PlayVideo()
    self.VideoPlayer:Play()
end

function XUiBigWorldPreviewFullScreenVideo:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.VideoPlayer.ActionEnded = Handler(self, self.OnVideoFinish)
    self.BtnSkip:AddEventListener(Handler(self, self.OnBtnSkipClick))
    self.BtnPause:AddEventListener(Handler(self, self.OnBtnPauseClick))
end

function XUiBigWorldPreviewFullScreenVideo:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldPreviewFullScreenVideo:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldPreviewFullScreenVideo:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldPreviewFullScreenVideo:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldPreviewFullScreenVideo:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiBigWorldPreviewFullScreenVideo
