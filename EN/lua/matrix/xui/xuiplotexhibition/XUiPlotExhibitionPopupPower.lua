local XUiPlotExhibitionPopupPowerGrid = require("XUi/XUiPlotExhibition/XUiPlotExhibitionPopupPowerGrid")

---@class XUiPlotExhibitionPopupPower : XLuaUi
---@field _Control XPlotExhibitionControl
local XUiPlotExhibitionPopupPower = XLuaUiManager.Register(XLuaUi, "UiPlotExhibitionPopupPower")

function XUiPlotExhibitionPopupPower:OnAwake()
    self.GridMember.gameObject:SetActiveEx(false)
    self:BindExitBtns(self.BtnTanchuangCloseBig)
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListMember, XUiPlotExhibitionPopupPowerGrid)
end

function XUiPlotExhibitionPopupPower:OnStart()
end

function XUiPlotExhibitionPopupPower:OnEnable()
    self:Update()
end

function XUiPlotExhibitionPopupPower:OnDisable()
end

function XUiPlotExhibitionPopupPower:Update()
    self._Control:UpdateForceDetail()
    local data = self._Control:GetUiData().ForceDetail
    self.TxtPowerName.text = data.Force.Name
    self.TxtPowerDetail.text = data.Force.Desc
    self.RImgPowerIcon:SetRawImage(data.Force.Logo)
    self.DynamicTable:SetDataSource(data.CharacterList)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiPlotExhibitionPopupPowerGrid
function XUiPlotExhibitionPopupPower:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        ---@type XTablePlotExhibitionForceCharacter
        local data = self.DynamicTable:GetData(index)
        local characterId = data.CharacterId
        local roleId = self._Control:GetRoleIdByCharacterId(characterId)
        local role = self._Control:GetRole(roleId)
        self._Control:SetRole4UiDetail(role)
        self:Close()
        XEventManager.DispatchEvent(XEventId.EVENT_PLOT_EXHIBITION_UPDATE_DETAIL, characterId)
    end
end

return XUiPlotExhibitionPopupPower