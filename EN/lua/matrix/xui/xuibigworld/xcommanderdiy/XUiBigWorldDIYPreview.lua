---@class XUiBigWorldDIYPreview : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtPreview UnityEngine.UI.Text
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field _Control XBigWorldCommanderDIYControl
local XUiBigWorldDIYPreview = XClass(XUiNode, "XUiBigWorldDIYPreview")

function XUiBigWorldDIYPreview:OnStart()
    self:_RegisterButtonClicks()
end

function XUiBigWorldDIYPreview:OnBtnTanchuangCloseClick()
    self:Close()
end

---@param entity XBWCommanderDIYPartEntity
function XUiBigWorldDIYPreview:Refresh(entity)
    self.TxtTitle.text = entity:GetName()
    self.TxtPreview.text = entity:GetDescription()
end

function XUiBigWorldDIYPreview:_RegisterButtonClicks()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnTanchuangCloseClick))
end

return XUiBigWorldDIYPreview