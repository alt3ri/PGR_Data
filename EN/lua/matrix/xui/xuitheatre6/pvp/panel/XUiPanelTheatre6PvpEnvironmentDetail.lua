---@class XUiPanelTheatre6PvpEnvironmentDetail : XUiNode pvp环境详情
---@field _Control XTheatre6Control
local XUiPanelTheatre6PvpEnvironmentDetail = XClass(XUiNode, "XUiPanelTheatre6PvpEnvironmentDetail")

function XUiPanelTheatre6PvpEnvironmentDetail:OnStart()
    ---@type XUiGridTheatre6PvpEnvironment
    self._Env = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpEnvironment").New(self.GridEnvironment, self)
    self.TxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
    self.TxtPrompt.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
end

function XUiPanelTheatre6PvpEnvironmentDetail:SetData(id)
    self._Config = self._Control:GetPvpBuffConfig(id)
    self._Env:SetData(id)
    self:UpdateView()
end

function XUiPanelTheatre6PvpEnvironmentDetail:UpdateView()
    self.TxtName.text = self._Config.Name
    self.TxtDesc.text = self._Control:GetPvpBuffDesc(self._Config.Id)
    self.TxtPrompt.text = self._Config.Prompt
    self:UpdateCondition()
end

function XUiPanelTheatre6PvpEnvironmentDetail:UpdateCondition()
    if XTool.IsNumberValid(self._Config.ConditionId) then
        local result, desc = XConditionManager.CheckCondition(self._Config.ConditionId)
        self.TxtUnlock.gameObject:SetActiveEx(not result)
        self.TxtUnlock.text = desc
    else
        self.TxtUnlock.gameObject:SetActiveEx(false)
    end
end

return XUiPanelTheatre6PvpEnvironmentDetail
