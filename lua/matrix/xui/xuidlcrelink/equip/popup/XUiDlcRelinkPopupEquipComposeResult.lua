local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
---@class XUiDlcRelinkPopupEquipComposeResult : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupEquipComposeResult = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupEquipComposeResult")

function XUiDlcRelinkPopupEquipComposeResult:OnAwake()
    self.GridEquipment.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupEquipComposeResult:OnStart(equipUidList)
    if XTool.IsTableEmpty(equipUidList) then
        return
    end
    self.EquipUidList = equipUidList
    self:InitDynamicTable()

    self.CurSelectGrid = nil
    self.CurSelectEquipUid = 0
end

function XUiDlcRelinkPopupEquipComposeResult:OnEnable()
    self:SetupDynamicTable()
end

function XUiDlcRelinkPopupEquipComposeResult:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkEquipment, self, handler(self, self.OnEquipItemCallBack))
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkPopupEquipComposeResult:SetupDynamicTable()
    local isEmpty = XTool.IsTableEmpty(self.EquipUidList)
    self.None.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        self.DynamicTable:Clear()
        return
    end

    local index = #self.EquipUidList
    self.DynamicTable:SetDataSource(self.EquipUidList)
    self.DynamicTable:ReloadDataSync(index)
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkPopupEquipComposeResult:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equipUid = self.EquipUidList[index]
        grid:Refresh(equipUid)
        local isSelected = equipUid == self.CurSelectEquipUid
        grid:SetSelect(isSelected)
        if isSelected and not self.CurSelectGrid then
            self.CurSelectGrid = grid
            self:ShowEquipBubble(equipUid, grid.Transform)
        end
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkPopupEquipComposeResult:OnEquipItemCallBack(grid)
    local equipUid = grid:GetEquipUid()
    if equipUid == self.CurSelectEquipUid then
        return
    end
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self.CurSelectEquipUid = equipUid
    self.CurSelectGrid = grid
    self:ShowEquipBubble(equipUid, grid.Transform)
end

-- 右侧装备气泡展示
---@param targetTransform UnityEngine.RectTransform
function XUiDlcRelinkPopupEquipComposeResult:ShowEquipBubble(equipUid, targetTransform)
    XLuaUiManager.Open("UiDlcRelinkBubbleEquipDetail", equipUid, targetTransform, handler(self, self.OnBubbleEquipDetailClose))
end

function XUiDlcRelinkPopupEquipComposeResult:OnBubbleEquipDetailClose()
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    self.CurSelectEquipUid = 0
    self.CurSelectGrid = nil
end

function XUiDlcRelinkPopupEquipComposeResult:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSure, self.OnBtnCloseClick)
end

function XUiDlcRelinkPopupEquipComposeResult:OnBtnCloseClick()
    self:Close()
end

return XUiDlcRelinkPopupEquipComposeResult
