---@class XUiGridMainLine2Message: XUiNode
---@field protected _Control XMainLine2Control
---@field Parent
local XUiGridMainLine2Message = XClass(XUiNode, "XUiGridMainLine2Message")

function XUiGridMainLine2Message:OnStart(messagePosId)
    self.MessagePosId = messagePosId
    
    if self.GridBtn then
        self.GridBtn:AddEventListener(handler(self, self._OnBtnClickEvent))
    end
end

function XUiGridMainLine2Message:Refresh(messagePosId)
    self.MessagePosId = messagePosId or self.MessagePosId

    self:_RefreshIconShow(self.MessagePosId)
    self:_RefreshStateShow(self.MessagePosId)
end

function XUiGridMainLine2Message:GetMessagePosId()
    return self.MessagePosId
end

function XUiGridMainLine2Message:_RefreshIconShow(messagePosId)
    if self.GridBtn then
        local icon = self._Control.MessageControl:GetCfgMessageIconById(messagePosId)

        if not string.IsNilOrEmpty(icon) then
            self.GridBtn:SetSprite(icon)
        end
    end
end

function XUiGridMainLine2Message:_RefreshStateShow(messagePosId)
    local curState = self._Control.MessageControl:GetMessageStateById(messagePosId)

    if self.GridBtn then
        self.GridBtn:ShowReddot(curState <= self._Control.MessageControl.EnumConst.MessageState.None)
    end

    if self.ImgFinish then
        self.ImgFinish.gameObject:SetActiveEx(curState >= self._Control.MessageControl.EnumConst.MessageState.AllRead)
    end
end

function XUiGridMainLine2Message:_OnBtnClickEvent()
    self:_SetMessageHadRead()
    
    XLuaUiManager.Open("UiMainLinePopupExplore", self.MessagePosId)
end

function XUiGridMainLine2Message:_SetMessageHadRead()
    local curState = self._Control.MessageControl:GetMessageStateById(self.MessagePosId)

    if curState == self._Control.MessageControl.EnumConst.MessageState.None then
        self._Control.MessageControl:DoMainLine2MessageStateUpdateRequest(self.MessagePosId, self._Control.MessageControl.EnumConst.MessageState.HadRead)
    end
end

return XUiGridMainLine2Message