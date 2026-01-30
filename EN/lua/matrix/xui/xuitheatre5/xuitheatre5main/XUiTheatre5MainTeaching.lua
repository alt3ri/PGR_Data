--- 主界面教学
---@class XUiTheatre5MainTeaching: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5MainTeaching = XClass(XUiNode, 'XUiTheatre5MainTeaching')

function XUiTheatre5MainTeaching:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnStart, self.OnClickStartEvent,true)
end

function XUiTheatre5MainTeaching:OnEnable()
    local isTeaching = self._Control.PVEControl:IsInTeachingStoryLine()
    self.PanelFirst.gameObject:SetActiveEx(isTeaching)
    self.PanelSecond.gameObject:SetActiveEx(not isTeaching)  
end

function XUiTheatre5MainTeaching:OnClickStartEvent()
    if self._Control:GetCurPlayingMode() ~= XMVCA.XTheatre5.EnumConst.GameMode.PVE then
        XMVCA.XTheatre5:RequestPveOrPvpChange(function(success)
            if success then
                self:EnterPVEMode()
            end    
        end)
    else
        self:EnterPVEMode()
    end    
end

function XUiTheatre5MainTeaching:EnterPVEMode()
    self:PlayAnimationWithMask("Enter", function()
        self._Control.FlowControl:EnterModel()
    end)
end

return XUiTheatre5MainTeaching