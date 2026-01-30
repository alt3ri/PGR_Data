---@class XUiBWProcessAnimationBase : XUiNode
---@field CanvasGroup UnityEngine.CanvasGroup
local XUiBWProcessAnimationBase = XClass(XUiNode, "XUiBWProcessAnimationBase")

function XUiBWProcessAnimationBase:SetEnableAnimationName(name)
    self.__EnableAnimationName = name
end

function XUiBWProcessAnimationBase:PlayEnableAnimation()
    if not string.IsNilOrEmpty(self.__EnableAnimationName) then
        self:PlayAnimation(self.__EnableAnimationName, function()
            self:SetAlpha(1)
        end)
    end
end

function XUiBWProcessAnimationBase:SetAlpha(alpha)
    if self.CanvasGroup then
        self.CanvasGroup.alpha = alpha or 0
    end
end

return XUiBWProcessAnimationBase
