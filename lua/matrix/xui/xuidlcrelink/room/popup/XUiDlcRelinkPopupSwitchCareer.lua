local XUiGridDlcRelinkSwitchOccupation = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkSwitchOccupation")
---@class XUiDlcRelinkPopupSwitchCareer : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupSwitchCareer = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupSwitchCareer")

function XUiDlcRelinkPopupSwitchCareer:OnAwake()
    self.GridOccupation.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupSwitchCareer:OnStart(characterId, occupationType, callBack)
    self.CharacterId = characterId
    self.OccupationType = occupationType
    self.CallBack = callBack
    self:InitDynamicTable()
end

function XUiDlcRelinkPopupSwitchCareer:OnEnable()
    self:SetupDynamicTable()
end

function XUiDlcRelinkPopupSwitchCareer:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelOccupationGroup)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkSwitchOccupation, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkPopupSwitchCareer:SetupDynamicTable()
    self.CharacterConfigs = self._Control:GetCharacterConfigs(self.CharacterId)
    self.DynamicTable:SetDataSource(self.CharacterConfigs)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridDlcRelinkSwitchOccupation
function XUiDlcRelinkPopupSwitchCareer:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.CharacterConfigs[index], index == self.OccupationType)
    end
end

function XUiDlcRelinkPopupSwitchCareer:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
end

function XUiDlcRelinkPopupSwitchCareer:OnBtnCloseClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

return XUiDlcRelinkPopupSwitchCareer
