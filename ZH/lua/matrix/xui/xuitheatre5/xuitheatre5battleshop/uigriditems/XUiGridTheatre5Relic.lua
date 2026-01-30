---@class XUiGridTheatre5Relic : XUiNode
---@field _Control XTheatre5Control
local XUiGridTheatre5Relic = XClass(XUiNode, "XUiGridTheatre5Relic")

function XUiGridTheatre5Relic:OnStart()
    if self.GridRelic then
        XUiHelper.RegisterClickEvent(self, self.GridRelic, self.OnClick)
    else
        local button = XUiHelper.TryGetComponent(self.Transform, "UiTheatre5GridRelic", "XUiButton")
        if button then
            XUiHelper.RegisterClickEvent(self, button, self.OnClick)
        end
    end
    self.RImgIcon = self.RImgIcon or XUiHelper.TryGetComponent(self.Transform, "UiTheatre5GridRelic/PanelNone/PanelRelic/RImgIcon", "RawImage")
end

---@param data XUiGridTheatre5RelicData
function XUiGridTheatre5Relic:Update(data)
    self._Data = data
    if data.IsUnlock then
        if self.PanelNone then
            self.PanelNone.gameObject:SetActiveEx(true)
        end
        if self.PanelLock then
            self.PanelLock.gameObject:SetActiveEx(false)
        end
        self.RImgIcon:SetRawImage(data.Icon)
    else
        if self.PanelNone then
            self.PanelNone.gameObject:SetActiveEx(false)
        end
        if self.PanelLock then
            self.PanelLock.gameObject:SetActiveEx(true)
        end
        if self.TxtNum and data.Level then
            self.TxtNum.text = data.Level
        end
    end
end

function XUiGridTheatre5Relic:OnClick()
    if self._Data.IsUnlock then
        self._Control:SetItemSelected(self)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self._Data.Item, XMVCA.XTheatre5.EnumConst.ItemContainerType.NormalDetails)
    end
end

-- 兼容XUiGridTheatre5Item
function XUiGridTheatre5Relic:UnSelect()
end

return XUiGridTheatre5Relic