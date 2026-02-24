local XUiGridCharacterCareerV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiGridCharacterCareerV2P6")
---@class XUiPanelCharacterCareerDetail : XUiNode
local XUiPanelCharacterCareerDetail = XClass(XUiNode, "XUiPanelCharacterCareerDetail")

function XUiPanelCharacterCareerDetail:OnStart()
    self.GridCareerDetail.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

function XUiPanelCharacterCareerDetail:Refresh(characterId)
    self.CharacterId = characterId
    self:SetupDynamicTable()
end

function XUiPanelCharacterCareerDetail:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelCareerDetails)
    self.DynamicTable:SetProxy(XUiGridCharacterCareerV2P6, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelCharacterCareerDetail:SetupDynamicTable()
    self.CareerIds = XMVCA.XCharacter:GetAllCharacterCareerIds()
    local curCareerId = XMVCA.XCharacter:GetCharacterCareer(self.CharacterId)
    local _, index = table.contains(self.CareerIds, curCareerId)
    self.DynamicTable:SetDataSource(self.CareerIds)
    self.DynamicTable:ReloadDataASync(index or 1)
end

---@param grid XUiGridCharacterCareer
function XUiPanelCharacterCareerDetail:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.CareerIds[index], self.CharacterId)
    end
end

return XUiPanelCharacterCareerDetail
