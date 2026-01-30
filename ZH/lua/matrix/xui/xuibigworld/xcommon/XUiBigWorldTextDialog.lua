
---@class XUiBigWorldTextDialog : XBigWorldUi
---@field NewsTabList XUiComponent.XUiButton[]
local XUiBigWorldTextDialog = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTextDialog")

function XUiBigWorldTextDialog:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldTextDialog:OnStart(dialogId)
    self._DialogId = dialogId
    self:InitView()
end 

function XUiBigWorldTextDialog:InitUi()
    
end 

function XUiBigWorldTextDialog:InitCb()
    self.BtnClose:AddEventListener(handler(self, self.Close))
end 

function XUiBigWorldTextDialog:InitView()
    local template = XMVCA.XBigWorldService:GetTextDialogTemplate(self._DialogId)
    self.TxtTitle.text = template.Title
    self.TxtContent.text = XUiHelper.ReplaceTextNewLine(template.Content)
end