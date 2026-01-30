local XUiBigWorldPreviewVideo = require("XUi/XUiBigWorld/XCommon/XPreview/XPanel/XUiBigWorldPreviewVideo")
local XUiBigWorldPreviewPhoto = require("XUi/XUiBigWorld/XCommon/XPreview/XPanel/XUiBigWorldPreviewPhoto")
local XUiBigWorldPreviewFullScreenVideo = require(
    "XUi/XUiBigWorld/XCommon/XPreview/XPanel/XUiBigWorldPreviewFullScreenVideo")

---@class XUiBigWorldVideoPreview : XBigWorldUi
---@field PanelVideo UnityEngine.RectTransform
---@field PanelPhoto UnityEngine.RectTransform
---@field PanelFullScreenVideo UnityEngine.RectTransform
local XUiBigWorldVideoPreview = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldVideoPreview")

function XUiBigWorldVideoPreview:OnAwake()
    ---@type XUiBigWorldPreviewVideo
    self._VideoUi = XUiBigWorldPreviewVideo.New(self.PanelVideo, self)
    ---@type XUiBigWorldPreviewPhoto
    self._PhotoUi = XUiBigWorldPreviewPhoto.New(self.PanelPhoto, self)
    ---@type XUiBigWorldPreviewFullScreenVideo
    self._FullScreenVideoUi = XUiBigWorldPreviewFullScreenVideo.New(self.PanelFullScreenVideo, self)

    ---@type XPreviewData
    self._Data = false

    self:_RegisterButtonClicks()
end

---@param data XPreviewData
function XUiBigWorldVideoPreview:OnStart(data)
    self._Data = data

    if data.Type == XEnumConst.BWPreviewType.Video then
        self:RefreshVideo(data)
    elseif data.Type == XEnumConst.BWPreviewType.Image or data.Type == XEnumConst.BWPreviewType.ImageToVideo then
        self:RefreshImage(data)
    end
end

function XUiBigWorldVideoPreview:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldVideoPreview:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldVideoPreview:OnDestroy()
    if self._Data then
        self._Data:Dispose()
    end

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_PREVIEW_CLOSE)
end

function XUiBigWorldVideoPreview:PlayVideoFinish()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_PREVIEW_VIDEO_FINISH)
end

function XUiBigWorldVideoPreview:ChangeToVideo(data)
    self:PlayAnimationWithMask("ShipingDisable", function()
        self._FullScreenVideoUi:PlayVideo()
    end)

    self:RefreshVideo(data, true)

    return true
end

function XUiBigWorldVideoPreview:RefreshVideo(data, isWithoutPlay)
    if not data or not data:IsVideoValid() then
        return false
    end

    self._PhotoUi:Close()

    if data.IsFullScreen then
        self._VideoUi:Close()
        self._FullScreenVideoUi:Open()
        if not isWithoutPlay then
            self._FullScreenVideoUi:Refresh(data)
        else
            self._FullScreenVideoUi:RefreshWithoutPlay(data)
        end
    else
        self._VideoUi:Open()
        self._FullScreenVideoUi:Close()
        self._VideoUi:Refresh(data)
    end

    return true
end

function XUiBigWorldVideoPreview:RefreshImage(data)
    if not data or not data:IsImageValid() then
        return false
    end

    self._PhotoUi:Open()
    self._VideoUi:Close()
    self._FullScreenVideoUi:Close()
    self._PhotoUi:Refresh(data)

    return true
end

function XUiBigWorldVideoPreview:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiBigWorldVideoPreview:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldVideoPreview:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldVideoPreview:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldVideoPreview:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldVideoPreview:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiBigWorldVideoPreview
