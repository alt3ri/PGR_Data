local XUiGridDlcRelinkEquipPresets = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipPresets")
---@class XUiDlcRelinkPopupEquipPresets : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupEquipPresets = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupEquipPresets")

function XUiDlcRelinkPopupEquipPresets:OnAwake()
    self.GridPresets.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupEquipPresets:OnStart(characterId)
    self.CharacterId = characterId
    self:InitDynamicTable()
end

function XUiDlcRelinkPopupEquipPresets:OnEnable()
    local usedPresetCount = self._Control:GetUsedEquipPresetCount()
    local maxPresetCount = self._Control:GetEquipPresetMaxNum()
    self.TxtTitle.text = string.format("%d/%d", usedPresetCount, maxPresetCount)
    self:SetupDynamicTable()
end

function XUiDlcRelinkPopupEquipPresets:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_RELINK_SYNC_EQUIP_PRESET,
    }
end

function XUiDlcRelinkPopupEquipPresets:OnNotify(event, ...)
    if event == XEventId.EVENT_DLC_RELINK_SYNC_EQUIP_PRESET then
        self:SetupDynamicTable()
    end
end

function XUiDlcRelinkPopupEquipPresets:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelPresetsGroup)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkEquipPresets, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkPopupEquipPresets:SetupDynamicTable()
    local presetsCount = self._Control:GetEquipPresetMaxNum()
    if presetsCount <= 0 then
        return
    end

    self.DynamicTable:SetTotalCount(presetsCount)
    self.DynamicTable:ReloadDataASync(1)
end

---@param grid XUiGridDlcRelinkEquipPresets
function XUiDlcRelinkPopupEquipPresets:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(index)
    end
end

function XUiDlcRelinkPopupEquipPresets:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiDlcRelinkPopupEquipPresets:OnBtnCloseClick()
    self:Close()
end

return XUiDlcRelinkPopupEquipPresets
