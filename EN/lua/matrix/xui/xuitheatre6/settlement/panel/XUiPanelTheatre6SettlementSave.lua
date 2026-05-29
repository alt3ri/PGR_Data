--- 结算保存存档面板
---@class XUiPanelTheatre6SettlementSave : XUiNode
---@field private _Control XTheatre6Control
---@field Parent XUiTheatre6Settlement
local XUiPanelTheatre6SettlementSave = XClass(XUiNode, "XUiPanelTheatre6SettlementSave")
local XUiGridTheatre6SettlementArchive = require("XUi/XUiTheatre6/Settlement/Grid/XUiGridTheatre6SettlementArchive")

function XUiPanelTheatre6SettlementSave:OnStart(mode)
    self.BtnGiveUp:AddEventListener(handler(self, self.OnBtnGiveUpClick))
    self.BtnSave:AddEventListener(handler(self, self.OnBtnSaveClick))

    self._Mode = mode
    ---@type XUiGridTheatre6SettlementArchive[]
    self._ArchiveGrids = {}
    self._IsSelectableEmpty = true
    self.GridArchive.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6SettlementSave:OnEnable()
    self._PanelRoleDetail = require("XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6CharacterAttrDetail").New(self.UiTheatre6PanelRoleDetail, self, self.Parent.SettleData and self.Parent.SettleData.FileData, self._Mode)
    self:Refresh()
end

function XUiPanelTheatre6SettlementSave:Refresh()
    self:RefreshRoleName()
    self:RefreshArchiveList()
    self:SelectDefaultEmptySlot()
    self:RefreshBtnSave()
end

function XUiPanelTheatre6SettlementSave:RefreshRoleName()
    local roleName = self._Control:GetSettlementRoleName(self._Mode)
    self.UiTxtRoleName.text = roleName or ""
end

function XUiPanelTheatre6SettlementSave:RefreshArchiveList()
    local roleId = self._Control:GetSettlementRoleId(self._Mode)
    local allArchiveList = self._Control:GetSettlementArchiveList(roleId)
    self.ArchiveDataList = {}
    if XTool.IsTableEmpty(allArchiveList) then
        return
    end

    for _, data in ipairs(allArchiveList) do
        if data.isEmpty then
            table.insert(self.ArchiveDataList, { isEmpty = true, slotIndex = data.slotIndex })
        else
            table.insert(self.ArchiveDataList, data)
        end
    end
    table.sort(self.ArchiveDataList, function(a, b)
        return a.slotIndex < b.slotIndex
    end)

    XTool.UpdateDynamicItem(self._ArchiveGrids, self.ArchiveDataList, self.GridArchive, XUiGridTheatre6SettlementArchive, self)
end

function XUiPanelTheatre6SettlementSave:RefreshBtnSave()
    local selectedData
    for _, data in ipairs(self.ArchiveDataList or table.empty) do
        if data.slotIndex == self._SelectedSlotIndex then
            selectedData = data
            break
        end
    end

    local isDisable = not selectedData
    local isReplace = selectedData and not selectedData.isEmpty
    self.BtnSave:SetDisable(isDisable, not isDisable)
    self.UiTxtSave.text = XUiHelper.GetText(isReplace and "Theatre6SaveReplace" or "Theatre6Save")
end

function XUiPanelTheatre6SettlementSave:SelectDefaultEmptySlot()
    for _, data in ipairs(self.ArchiveDataList) do
        if data.isEmpty == true then
            self:SelectSlot(data.slotIndex)
            return
        end
    end
    self._SelectedSlotIndex = nil
end

function XUiPanelTheatre6SettlementSave:SelectSlot(slotIndex)
    self._SelectedSlotIndex = slotIndex
    for _, grid in ipairs(self._ArchiveGrids) do
        grid:Update(grid.Data, grid.Index)
    end
    self:RefreshBtnSave()
end

function XUiPanelTheatre6SettlementSave:OnBtnGiveUpClick()
    local title = CS.XTextManager.GetText("Theatre6GiveUpTitle")
    local content = CS.XTextManager.GetText("Theatre6SaveGiveUpContent")
    XLuaUiManager.Open("UiTheatre6PopupCommon", title, content, nil, handler(self, self.OnConfirmGiveUp), nil)
end

function XUiPanelTheatre6SettlementSave:OnConfirmGiveUp()
    self._Control:GiveUpSettlement(function()
        XLuaUiManager.Close("UiTheatre6Settlement")
    end)
end

function XUiPanelTheatre6SettlementSave:OnBtnSaveClick()
    local selectedData
    for _, data in ipairs(self.ArchiveDataList or table.empty) do
        if data.slotIndex == self._SelectedSlotIndex then
            selectedData = data
            break
        end
    end

    if not selectedData then
        XLuaUiManager.Open("UiTheatre6ToastCommon",CS.XTextManager.GetText("Theatre6SelectSlotFirst"))
        return
    end

    if selectedData.isEmpty == true then
        self:SaveToSlot(self._SelectedSlotIndex)
    else
        XLuaUiManager.Open("UiTheatre6PopupCoverArchive", self._SelectedSlotIndex, self.Parent.SettleData.FileData)
    end
end

function XUiPanelTheatre6SettlementSave:SaveToSlot(slotIndex)
    self._Control:SaveSettlement(slotIndex, function()
        -- 保存成功，播放动效后回到主界面
        
        self:PlaySaveEffect(function()
            self:Close()
            self.Parent:Close()
        end)
    end)
end

function XUiPanelTheatre6SettlementSave:PlaySaveEffect(finishCb)
    -- TODO: 播放存档保存动效
    if finishCb then
        finishCb()
    end
end

return XUiPanelTheatre6SettlementSave