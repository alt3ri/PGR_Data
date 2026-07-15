--- 结算存档槽位Grid
---@class XUiGridTheatre6SettlementArchive : XUiNode
---@field _Control XTheatre6Control
---@field Parent XUiPanelTheatre6SettlementSave
local XUiGridTheatre6SettlementArchive = XClass(XUiNode, "XUiGridTheatre6SettlementArchive")

function XUiGridTheatre6SettlementArchive:OnStart()
    self.GridArchive:AddEventListener(handler(self,self.OnBtnGridArchiveClick))
    
    self._Tags = {}
    self:ShowTagDefend(false)
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
            self:SetButtonState(XUiButtonState.Disable)
        end
        return
    end

    self:RefreshArchiveCard(data)
    self:UpdateSelectState()
end

function XUiGridTheatre6SettlementArchive:UpdateSelectState()
    local isSelected = self.Data.slotIndex == self.Parent._SelectedSlotIndex
    if isSelected then
        self:SetButtonState(XUiButtonState.Select)
    else
        self:SetButtonState(XUiButtonState.Normal)
    end
end

function XUiGridTheatre6SettlementArchive:SetButtonState(state)
    self.GridArchive:SetButtonState(state)
    self.GridArchive.TempState = state
end

---刷新存档卡片内容
---@param data table
function XUiGridTheatre6SettlementArchive:RefreshArchiveCard(data)
    local isDefense = (not data.isEmpty) and self._Control:CheckArchiveInDefenseLineup(data.characterId, data.slotIndex)

    self.RImgRole:SetRawImage(data.roleIcon)
    self.UiTxtScore.text = tostring(data.score)

    if self.TagDefend then
        self.TagDefend.gameObject:SetActiveEx(isDefense)

        if isDefense then
            self.TagDefend:SetImage(self._Control:GetDefenseArchiveIcon())
        end
    end

    XUiHelper.RefreshCustomizedList(self.ImgBgTag.transform.parent, self.ImgBgTag.transform, #data.tags, function(i, go)
        local grid = {}
        local cfg = self._Control:GetBuildTagConfig(data.tags[i])
        XUiHelper.InitUiClass(grid, go)
        grid.UiTxtName.text = cfg.Name
        grid.UiImgIcon:SetRawImage(cfg.Icon)
    end)
end

function XUiGridTheatre6SettlementArchive:OnBtnGridArchiveClick()
    self.Parent:SelectSlot(self.Data.slotIndex, self.GridArchive.transform)
end

function XUiGridTheatre6SettlementArchive:ShowTagDefend(isVisible)
    self.GridArchive:ShowTag(isVisible)
end

return XUiGridTheatre6SettlementArchive