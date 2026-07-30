--- 章节主界面事件节点
---@class XUiTheatre5PVEChapterEventItem: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEChapterEventItem = XClass(XUiNode, 'XUiTheatre5PVEChapterEventItem')

function XUiTheatre5PVEChapterEventItem:OnStart()
    XUiHelper.RegisterClickEvent(self, self.UiTheatre5BtnYes, self.OnClickStartEvent, true, true, 0.5)
    self._EventId = nil 
end

--eventData = {EventId = number, IsNew = bool}
function XUiTheatre5PVEChapterEventItem:Update(eventData, index)
    self._EventId = eventData.EventId
    self.Normal.gameObject:SetActiveEx(not eventData.IsNew)
    self.New.gameObject:SetActiveEx(eventData.IsNew)
    local eventCfg = self._Control.PVEControl:GetPVEEventCfg(eventData.EventId)
    if eventData.IsNew then
        self.RImgBgNew:SetRawImage(eventCfg.Icon)
        self.TxtTitleNew.text = eventCfg.LocationName
        self.TxtDetailNew.text = eventCfg.LocationDescUnselect
    else
        self.RImgBg:SetRawImage(eventCfg.Icon)
        self.TxtTitle.text = eventCfg.LocationName
        self.TxtDetail.text = eventCfg.LocationDesc
    end
  
    self:ForceRebuildLayout()
end

function XUiTheatre5PVEChapterEventItem:OnClickStartEvent()
    if not XTool.IsNumberValid(self._EventId) then
        return
    end    
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_PVE_EVENT_SELECT, self._EventId)
    self._EventId = nil --防止连点

end

function XUiTheatre5PVEChapterEventItem:ForceRebuildLayout()
    if self.Transform then
        local rectTrans = self.Transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(rectTrans)
    end    
end

function XUiTheatre5PVEChapterEventItem:OnDestroy()
    self._EventId = nil
end

return XUiTheatre5PVEChapterEventItem