---推演问题
---@class XUiTheatre5PVEReasoningAnswerItem: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEReasoningAnswerItem = XClass(XUiNode, 'XUiTheatre5PVEReasoningAnswerItem')

function XUiTheatre5PVEReasoningAnswerItem:OnStart()
    self._ClueId = nil
    self._IsSelect = false
    self.BtnGridAnswer:AddEventListener(function()
        self:OnClickAnswer()
    end)
    self.BtnGridAnswer.ExitCheck = false

end

function XUiTheatre5PVEReasoningAnswerItem:Update(clueId)
    self._ClueId = clueId
    local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueId)
    if not clueCfg then
        return
    end
    self.BtnGridAnswer:SetName(clueCfg.Title)
    if self.BtnNormalEnable then
        self.BtnNormalEnable.playOnAwake = false  --手动播快速连点会有问题，需要自动播
    end    
    self.BtnGridAnswer:SetButtonState(CS.UiButtonState.Normal)
    if self.BtnNormalEnable then
        self.BtnNormalEnable.playOnAwake = true
    end    
    self.BtnGridAnswer.enabled = true
    self._IsSelect = false   
end

function XUiTheatre5PVEReasoningAnswerItem:SetSelect(clueId)
    self._IsSelect = self._ClueId == clueId
    self.BtnGridAnswer.enabled = not self._IsSelect 
    if self.BtnGridAnswer then 
        self.BtnGridAnswer:SetButtonState(self._IsSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    end
end

function XUiTheatre5PVEReasoningAnswerItem:OnClickAnswer()
    if self._IsSelect then
        return
    end    
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_SELECT_DEDUCE_ANSWER, self._ClueId)
end

return XUiTheatre5PVEReasoningAnswerItem