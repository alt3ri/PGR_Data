---@class XUiGridPopupExploreChoice: XUiNode
---@field protected _Control XMainLine2Control
---@field Parent
local XUiGridPopupExploreChoice = XClass(XUiNode, "XUiGridPopupExploreChoice")

function XUiGridPopupExploreChoice:OnStart(clickHandler, ownMessageId)
    self._ClickHandler = clickHandler
    self.OwnMessageId = ownMessageId
    
    self.GridBtn:AddEventListener(handler(self, self.OnBtnClickEvent))
end

function XUiGridPopupExploreChoice:OnDestroy()
    self._ClickHandler = nil
end

function XUiGridPopupExploreChoice:Refresh(index, contentId, content)
    self.Index = index
    self.ContentId = contentId
    
    self.GridBtn:SetNameByGroup(0, content)
    
    -- 判断本地缓存，过去是否选择过
    self:_RefreshHistoryShow()
end

function XUiGridPopupExploreChoice:_RefreshHistoryShow()
    local isAllRead = XTool.IsNumberValidEx(self.OwnMessageId) and self._Control.MessageControl:GetMessageStateById(self.OwnMessageId) == self._Control.MessageControl.EnumConst.MessageState.AllRead
    local isChoiceSelected = isAllRead or self._Control.MessageControl:CheckContentChoiceHasSelected(self.ContentId, self.Index)
    
    self.GridBtn:SetButtonState(isChoiceSelected and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
end

function XUiGridPopupExploreChoice:OnBtnClickEvent()
    if self._ClickHandler then
        self._ClickHandler(self.Index)
    end
    
    self._Control.MessageControl:SetContentChoiceHasSelected(self.ContentId, self.Index)
    self:_RefreshHistoryShow()
end

return XUiGridPopupExploreChoice