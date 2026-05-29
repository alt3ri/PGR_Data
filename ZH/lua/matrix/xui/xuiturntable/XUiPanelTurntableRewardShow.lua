---@class XUiPanelTurntableRewardShow: XUiNode
local XUiPanelTurntableRewardShow = XClass(XUiNode, 'XUiPanelTurntableRewardShow')

function XUiPanelTurntableRewardShow:OnEnable()
    self:PlayEnableAnimation()
end

function XUiPanelTurntableRewardShow:OnDisable()
    XDataCenter.ItemManager.SetAutoGiftRewardShowLock(false)
end

function XUiPanelTurntableRewardShow:PlayEnableAnimation()
    self:PlayAnimationWithMask('PanelSettllementEnable')
end

function XUiPanelTurntableRewardShow:CloseEx()
    local isBegin = false
    
    self:PlayAnimationWithMask("PanelSettllementDisable", function()
        self:Close()
    end, function() 
        isBegin = true
    end)

    if not isBegin then
        self:Close()
    end
end

return XUiPanelTurntableRewardShow