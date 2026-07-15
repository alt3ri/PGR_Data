---@class XUiGridTheatre6PvpEnvironment : XUiNode pvp环境
---@field _Control XTheatre6Control
local XUiGridTheatre6PvpEnvironment = XClass(XUiNode, "XUiGridTheatre6PvpEnvironment")

function XUiGridTheatre6PvpEnvironment:OnStart()
    self.GridEnvironment.ExitCheck = false
end

function XUiGridTheatre6PvpEnvironment:SetData(id)
    self._Config = self._Control:GetPvpBuffConfig(id)
    self.GridEnvironment:SetRawImage(self._Config.Icon)
    self.GridEnvironment:SetNameByGroup(0, self._Config.Name)
    if XTool.IsNumberValid(self._Config.ConditionId) then
        local result, _ = XConditionManager.CheckCondition(self._Config.ConditionId)
        self.GridEnvironment:SetButtonState(result and XUiButtonState.Normal or XUiButtonState.Disable)
    else
        self.GridEnvironment:SetButtonState(XUiButtonState.Normal)
    end
end

return XUiGridTheatre6PvpEnvironment
