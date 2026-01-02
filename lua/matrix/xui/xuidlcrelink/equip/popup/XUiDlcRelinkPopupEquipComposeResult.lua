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

    self:SortEquipList()
end

function XUiDlcRelinkPopupEquipComposeResult:OnEnable()
    self:SetupDynamicTable()
end

-- 装备列表排序
-- 1.按品质排，品质越高越前
-- 2.按类型排，主控装备比常规装备优先
function XUiDlcRelinkPopupEquipComposeResult:SortEquipList()
    table.sort(self.EquipUidList, function(a, b)
        local templateIdA = self._Control:GetEquipTemplateIdByEquipUid(a)
        local templateIdB = self._Control:GetEquipTemplateIdByEquipUid(b)
        local qualityA = self._Control:GetEquipQuality(templateIdA)
        local qualityB = self._Control:GetEquipQuality(templateIdB)
        if qualityA ~= qualityB then
            return qualityA > qualityB
        end
        local isMainEquipA = self._Control:GetEquipType(templateIdA) == XEnumConst.DlcRelink.EquipType.Main
        local isMainEquipB = self._Control:GetEquipType(templateIdB) == XEnumConst.DlcRelink.EquipType.Main
        if isMainEquipA ~= isMainEquipB then
            return isMainEquipA
        end
        return a < b
    end)
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

    self.DynamicTable:SetDataSource(self.EquipUidList)
    self.DynamicTable:ReloadDataSync(1)
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkPopupEquipComposeResult:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equipUid = self.EquipUidList[index]
        grid:Refresh(equipUid)
        local isSelected = equipUid == self.CurSelectEquipUid
        grid:SetSelect(isSelected)
        grid.BtnEquip.gameObject:SetActiveEx(true)
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
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnSure:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiDlcRelinkPopupEquipComposeResult:OnBtnCloseClick()
    self:Close()
end

return XUiDlcRelinkPopupEquipComposeResult
