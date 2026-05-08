---@class XUiPanelTheatre6UpgradePreview : XUiNode 右侧等级预览面板
---@field _Control XTheatre6Control
local XUiPanelTheatre6UpgradePreview = XClass(XUiNode, "XUiPanelTheatre6UpgradePreview")

local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre6Upgrade = require("XUi/XUiTheatre6/OutSider/Grid/XUiGridTheatre6Upgrade")

function XUiPanelTheatre6UpgradePreview:OnStart()
    self._TalentDataList = {}
    self:InitDynamicTable()
    self.GirdUpgrad.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6UpgradePreview:InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.Transform)
    self._DynamicTable:SetProxy(XUiGridTheatre6Upgrade, self)
    self._DynamicTable:SetDelegate(self)
end

---刷新面板
---@param talentConfigs XTableTheatre6Talent[] 按等级排序的养成配置
---@param currentLv number 当前等级
---@param curExp number 当前经验
function XUiPanelTheatre6UpgradePreview:Refresh(talentConfigs, currentLv, curExp)
    self._CurrentLv = currentLv
    self._CurExp = curExp
    self._TalentDataList = talentConfigs
    self._DynamicTable:SetDataSource(self._TalentDataList)
    self._DynamicTable:ReloadDataSync(1)
end

---@param grid XUiGridTheatre6Upgrade
function XUiPanelTheatre6UpgradePreview:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local talentCfg = self._TalentDataList[index]
        if talentCfg then
            grid:Update(talentCfg, self._CurrentLv, self._CurExp)
        end
    end
end

return XUiPanelTheatre6UpgradePreview
