---@class XUiPopTeachVisual : XUiNode
---@field VisualImage UnityEngine.UI.RawImage
---@field VisualVideo UnityEngine.RectTransform
---@field VideoBtn XUiComponent.XUiButton
---@field ImagePlay UnityEngine.RectTransform
---@field Video XVideoPlayerUGUI
---@field Parent XUiPopupTeach
local XUiPopTeachVisual = XClass(XUiNode, "XUiPopTeachVisual")

function XUiPopTeachVisual:OnStart()
    
    self:_RegisterButtonClicks()
end

function XUiPopTeachVisual:RefreshImg(img)
    self:_ShowImagePanel(true)
    self.VisualImage:SetRawImage(img)
end

function XUiPopTeachVisual:OnVideoBtnClick()
    
end

function XUiPopTeachVisual:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.VideoBtn.CallBack = Handler(self, self.OnVideoBtnClick)
end

function XUiPopTeachVisual:_RefreshVideo()
    self:_ShowImagePanel(false)
end

function XUiPopTeachVisual:_ShowImagePanel(isShow)
    self.VisualImage.gameObject:SetActiveEx(isShow)
    self.VisualVideo.gameObject:SetActiveEx(not isShow)
end

return XUiPopTeachVisual
