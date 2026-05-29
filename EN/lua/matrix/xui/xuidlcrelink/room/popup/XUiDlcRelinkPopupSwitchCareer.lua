local XUiGridDlcRelinkSwitchStyle = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkSwitchStyle")
---@class XUiDlcRelinkPopupSwitchCareer : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupSwitchCareer = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupSwitchCareer")

function XUiDlcRelinkPopupSwitchCareer:OnAwake()
    self.GridOccupation.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupSwitchCareer:OnStart(characterId, styleType, callBack, isNotSelf)
    self.CharacterId = characterId
    self.StyleType = styleType
    self.CallBack = callBack
    self.IsNotSelf = isNotSelf
    self:InitDynamicTable()
end

function XUiDlcRelinkPopupSwitchCareer:OnEnable()
    self.PanelTitle.gameObject:SetActiveEx(not self.IsNotSelf)
    self.PanelTitleView.gameObject:SetActiveEx(self.IsNotSelf)
    self:SetupDynamicTable()
end

function XUiDlcRelinkPopupSwitchCareer:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelOccupationGroup)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkSwitchStyle, self, self.IsNotSelf)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkPopupSwitchCareer:SetupDynamicTable()
    local configs = self._Control:GetCharacterConfigs(self.CharacterId)
    if self.IsNotSelf then
        self.CharacterConfigs = { configs[self.StyleType] }
    else
        self.CharacterConfigs = configs
    end
    self.DynamicTable:SetDataSource(self.CharacterConfigs)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridDlcRelinkSwitchStyle
function XUiDlcRelinkPopupSwitchCareer:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        if self.IsNotSelf then
            grid:RefreshOther(self.CharacterId, self.StyleType)
        else
            grid:Refresh(self.CharacterConfigs[index], index == self.StyleType)
        end
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
