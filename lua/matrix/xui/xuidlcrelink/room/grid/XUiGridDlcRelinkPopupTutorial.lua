---@class XUiGridDlcRelinkPopupTutorial : XUiNode
---@field Parent XUiDlcRelinkPopupTutorial
---@field _Control XDlcRelinkControl
---@field Video XVideoPlayerUGUI
local XUiGridDlcRelinkPopupTutorial = XClass(XUiNode, "XUiGridDlcRelinkPopupTutorial")

function XUiGridDlcRelinkPopupTutorial:SetData(videoId, imageUrl, desc)
    self:StopVideo()
    if XTool.IsNumberValid(videoId) then
        self.VisualImage.gameObject:SetActiveEx(false)
        self:PlayVideo(videoId)
    else
        self.VisualImage.gameObject:SetActiveEx(true)
        self.VisualImage:SetRawImage(imageUrl)
    end
    self.TxtContent.text = XUiHelper.ReplaceTextNewLine(desc)
end

function XUiGridDlcRelinkPopupTutorial:PlayVideo(videoConfigId)
    if not XTool.IsNumberValid(videoConfigId) then
        self.VideoMask.gameObject:SetActiveEx(false)
        return
    end

    self.VideoMask.gameObject:SetActiveEx(true)
    self.Video:SetInfoByVideoId(videoConfigId)
    self.Video:Play()
end

function XUiGridDlcRelinkPopupTutorial:StopVideo()
    if self.Video then
        self.Video:Stop()
        self.VideoMask.gameObject:SetActiveEx(false)
    end
end

function XUiGridDlcRelinkPopupTutorial:OnDestroy()
    self:StopVideo()
end

return XUiGridDlcRelinkPopupTutorial
