---@class XUiBigWorldMessageVisual : XUiNode
---@field VisualImage UnityEngine.UI.RawImage
---@field VisualVideo UnityEngine.RectTransform
---@field BtnVideo XUiComponent.XUiButton
---@field Video XVideoPlayerUGUI
---@field ImagePlay UnityEngine.RectTransform
---@field ImgTime UnityEngine.UI.RawImage
---@field TxtTime UnityEngine.UI.Text
---@field _Control XBigWorldMessageControl
---@field Parent XUiBigWorldMessageGrid
local XUiBigWorldMessageVisual = XClass(XUiNode, "XUiBigWorldMessageVisual")

-- region 生命周期

function XUiBigWorldMessageVisual:OnStart()
    self:_RegisterButtonClicks()
end

function XUiBigWorldMessageVisual:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageVisual:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldMessageVisual:OnDestroy()
end

-- endregion

function XUiBigWorldMessageVisual:OnBtnVideoClick()
    self.Parent:OpenPreview()
end

function XUiBigWorldMessageVisual:Refersh(videoImage, voideoId)
    if not XTool.IsNumberValid(voideoId) then
        return
    end

    local videoLength = CS.XVideoManager.GetVideoLengthByVideoConfigId(voideoId)

    self.Video.gameObject:SetActiveEx(true)
    self.ImagePlay.gameObject:SetActiveEx(true)
    self.VisualImage.gameObject:SetActiveEx(true)
    self.VisualImage:SetImage(videoImage, function()
        self._Control:AdaptImageSize(self.VisualImage)
    end)

    if XTool.IsNumberValid(videoLength) then
        self.ImgTime.gameObject:SetActiveEx(true)
        self.TxtTime.text = XUiHelper.GetTime(videoLength, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    else
        self.ImgTime.gameObject:SetActiveEx(false)
    end
end

-- region 私有方法

function XUiBigWorldMessageVisual:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnVideo:AddEventListener(Handler(self, self.OnBtnVideoClick))
end

function XUiBigWorldMessageVisual:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMessageVisual:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMessageVisual:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldMessageVisual:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldMessageVisual:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

-- endregion

return XUiBigWorldMessageVisual
