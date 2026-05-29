--- 结算存档槽位Grid
---@class XUiGridTheatre6SettlementArchive : XUiNode
---@field _Control XTheatre6Control
---@field Parent XUiPanelTheatre6SettlementSave
local XUiGridTheatre6SettlementArchive = XClass(XUiNode, "XUiGridTheatre6SettlementArchive")

function XUiGridTheatre6SettlementArchive:OnStart()
    self.GridArchive:AddEventListener(handler(self,self.OnBtnGridArchiveClick))
    
    self._Tags = {}
end

function XUiGridTheatre6SettlementArchive:Update(data, index)
    self.Data = data
    self.Index = index

    self.PanelArchive.gameObject:SetActiveEx(not data.isEmpty)
    self.PanelEmpty.gameObject:SetActiveEx(data.isEmpty)

    if data.isEmpty then
        if self.Parent._IsSelectableEmpty then
            self:UpdateSelectState()
        else
            self.GridArchive:SetButtonState(XUiButtonState.Disable)
        end
        return
    end

    self:RefreshArchiveCard(data)
    self:UpdateSelectState()
end

function XUiGridTheatre6SettlementArchive:UpdateSelectState()
    local isSelected = self.Data.slotIndex == self.Parent._SelectedSlotIndex
    if isSelected then
        self.GridArchive:SetButtonState(XUiButtonState.Select)
    else
        self.GridArchive:SetButtonState(XUiButtonState.Normal)
    end
end

---刷新存档卡片内容
---@param data table
function XUiGridTheatre6SettlementArchive:RefreshArchiveCard(data)
    self.RImgRole:SetRawImage(data.roleIcon)
    self.UiTxtScore.text = tostring(data.score)
    local tagData = self._Control:GetShowBuildTagWithSort(data.tags)
    XUiHelper.RefreshCustomizedList(self.ImgBgTag.transform.parent, self.ImgBgTag.transform, #tagData, function(i, go)
        local grid = {}
        XUiHelper.InitUiClass(grid, go)
        grid.UiTxtName.text = tagData[i].Name
        grid.UiImgIcon:SetRawImage(tagData[i].Icon)
    end)
end

function XUiGridTheatre6SettlementArchive:OnBtnGridArchiveClick()
    self.Parent:SelectSlot(self.Data.slotIndex, self.GridArchive.transform)
end

return XUiGridTheatre6SettlementArchive