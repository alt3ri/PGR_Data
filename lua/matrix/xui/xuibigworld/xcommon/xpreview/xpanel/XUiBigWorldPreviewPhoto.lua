---@class XUiBigWorldPreviewPhoto : XUiNode
---@field RImgPhoto UnityEngine.UI.RawImage
---@field BtnTanchuangClose XUiComponent.XUiButtonExt
---@field Parent XUiBigWorldVideoPreview
local XUiBigWorldPreviewPhoto = XClass(XUiNode, "XUiBigWorldPreviewPhoto")

function XUiBigWorldPreviewPhoto:OnStart()
    self:_RegisterButtonClicks()
end

function XUiBigWorldPreviewPhoto:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldPreviewPhoto:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldPreviewPhoto:OnDestroy()
end

function XUiBigWorldPreviewPhoto:OnBtnTanchuangCloseClick()
    if self._Data and self._Data.Type == XEnumConst.BWPreviewType.ImageToVideo then
        if self.Parent:ChangeToVideo(self._Data) then
            return
        end
    end

    self.Parent:Close()
end

---@param data XPreviewData
function XUiBigWorldPreviewPhoto:Refresh(data)
    if not data or not data:IsImageValid() then
        return
    end

    self._Data = data

    data:RefreshRawImage(self.RImgPhoto)
end

function XUiBigWorldPreviewPhoto:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnTanchuangClose:AddEventListener(Handler(self, self.OnBtnTanchuangCloseClick))
end

function XUiBigWorldPreviewPhoto:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldPreviewPhoto:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldPreviewPhoto:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldPreviewPhoto:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldPreviewPhoto:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiBigWorldPreviewPhoto
