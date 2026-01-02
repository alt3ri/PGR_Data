local XUiGridDlcRelinkSwitchStyle = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkSwitchStyle")
---@class XUiDlcRelinkPopupSwitchCareer : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupSwitchCareer = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupSwitchCareer")

function XUiDlcRelinkPopupSwitchCareer:OnAwake()
    self.GridOccupation.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupSwitchCareer:OnStart(characterId, styleType, callBack)
    self.CharacterId = characterId
    self.StyleType = styleType
    self.CallBack = callBack
    self:InitDynamicTable()
end

function XUiDlcRelinkPopupSwitchCareer:OnEnable()
    self:SetupDynamicTable()
end

function XUiDlcRelinkPopupSwitchCareer:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelOccupationGroup)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkSwitchStyle, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkPopupSwitchCareer:SetupDynamicTable()
    self.CharacterConfigs = self._Control:GetCharacterConfigs(self.CharacterId)
    self.DynamicTable:SetDataSource(self.CharacterConfigs)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridDlcRelinkSwitchStyle
function XUiDlcRelinkPopupSwitchCareer:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.CharacterConfigs[index], index == self.StyleType)
    end
end

function XUiDlcRelinkPopupSwitchCareer:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiDlcRelinkPopupSwitchCareer:OnBtnCloseClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

return XUiDlcRelinkPopupSwitchCareer
