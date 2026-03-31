local XUiCommonBubblePanel = require('XUi/XUiCommon/XUiCommonBubblePanel')
---@class XUiPanelChatCopyBubble: XUiCommonBubblePanel
---@field protected _Control
---@field Parent
local XUiPanelChatCopyBubble = XClass(XUiCommonBubblePanel, "XUiPanelChatCopyBubble")



function XUiPanelChatCopyBubble:OnStart()
    self:SetPopupPanelRectTrans(self.BtnCopy.transform)
    self:SetViewArea(self.Transform.rect.width, self.Transform.rect.height)

    if self.BtnClose then
        self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    end
    self.BtnCopy:AddEventListener(handler(self, self.OnBtnCopyClick))
end

function XUiPanelChatCopyBubble:OnBtnCopyClick()
    if not string.IsNilOrEmpty(self.CopyMsg) then
        XTool.CopyToClipboard(self.CopyMsg)
    end
    
    self:Close()
end

function XUiPanelChatCopyBubble:OnBtnCloseClick()
    self:Close()
end

function XUiPanelChatCopyBubble:ShowCopyByCopyContent(copyMsg, worldPos, pivot)
    self.CopyMsg = copyMsg
    
    self:SetPosition(worldPos, pivot)
end

return XUiPanelChatCopyBubble