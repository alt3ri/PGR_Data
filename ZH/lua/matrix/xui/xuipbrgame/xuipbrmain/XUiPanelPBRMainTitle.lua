--- 标题界面
---@class XUiPanelPBRMainTitle: XUiNode
---@field protected _Control
---@field Parent
local XUiPanelPBRMainTitle = XClass(XUiNode, "XUiPanelPBRMainTitle")

function XUiPanelPBRMainTitle:OnStart()
    if self.TitleImgTouch then
        self.TitleImgTouch:AddEventListener(handler(self, self._OnBtnTitleClick))
    end
end

function XUiPanelPBRMainTitle:_OnBtnTitleClick()
    if self._HadClick then
        return
    end
    
    self._HadClick = true
    
    self:PlayAnimation("Enable", function()
        self._HadClick = false
    end)
end

return XUiPanelPBRMainTitle