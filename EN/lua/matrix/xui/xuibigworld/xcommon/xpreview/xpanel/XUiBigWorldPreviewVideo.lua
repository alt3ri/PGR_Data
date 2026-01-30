
---@class XUiBigWorldPreviewVideo : XUiNode
---@field VisualImage UnityEngine.UI.RawImage
---@field VisualVideo UnityEngine.RectTransform
---@field BtnVideo XUiComponent.XUiButton
---@field Video XVideoPlayerUGUI
---@field ImagePlay UnityEngine.RectTransform
---@field ImgTime UnityEngine.UI.Image
---@field TxtTime UnityEngine.UI.Text
---@field BtnTanchuangClose XUiComponent.XUiButtonExt
---@field Parent XUiBigWorldVideoPreview
local XUiBigWorldPreviewVideo = XClass(XUiNode, "XUiBigWorldPreviewVideo")

function XUiBigWorldPreviewVideo:OnStart()
    ---@type XPreviewData
    self._Data = false
    self._IsPlaying = false

    self:_RegisterButtonClicks()
end

function XUiBigWorldPreviewVideo:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldPreviewVideo:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldPreviewVideo:OnDestroy()
    self.Video.ActionEnded = nil
end

function XUiBigWorldPreviewVideo:OnBtnVideoClick()
    if self._IsPlaying then
        self.Video:Stop()
        self:_RefreshPlay(false)
    else
        self.Video:Prepare()
        self:_RefreshPlay(true)
    end
end

function XUiBigWorldPreviewVideo:OnVideoFinish()
    self:_RefreshPlay(false)
    self.Parent:PlayVideoFinish()

    if self._Data and self._Data.IsAutoClose then
        self.Parent:Close()
    end
end

function XUiBigWorldPreviewVideo:OnBtnTanchuangCloseClick()
    self.Video:Stop()
    self.Parent:Close()
end

---@param data XPreviewData
function XUiBigWorldPreviewVideo:Refresh(data)
    if not data or not data:IsVideoValid() then
        return
    end

    local videoLength = CS.XVideoManager.GetVideoLengthByVideoConfigId(data.VideoId)

    self._Data = data
    self:_RefreshPlay(false)
    self.Video.gameObject:SetActiveEx(true)
    self.Video:SetInfoByVideoId(data.VideoId)

    data:RefreshRawImage(self.VisualImage)

    if XTool.IsNumberValid(videoLength) then
        self.ImgTime.gameObject:SetActiveEx(true)
        self.TxtTime.text = XUiHelper.GetTime(videoLength, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    else
        self.ImgTime.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldPreviewVideo:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.Video.ActionEnded = Handler(self, self.OnVideoFinish)
    self.BtnVideo:AddEventListener(Handler(self, self.OnBtnVideoClick))
    self.BtnTanchuangClose:AddEventListener(Handler(self, self.OnBtnTanchuangCloseClick))
end

function XUiBigWorldPreviewVideo:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldPreviewVideo:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldPreviewVideo:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldPreviewVideo:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldPreviewVideo:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldPreviewVideo:_RefreshPlay(isPlaying)
    self._IsPlaying = isPlaying
    self.ImagePlay.gameObject:SetActiveEx(not isPlaying)
    self.VisualImage.gameObject:SetActiveEx(not isPlaying)
end

return XUiBigWorldPreviewVideo
