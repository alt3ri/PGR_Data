---@class XUiPanelTheatre6UpgradeNow : XUiNode 左侧当前等级与属性面板
---@field _Control XTheatre6Control
local XUiPanelTheatre6UpgradeNow = XClass(XUiNode, "XUiPanelTheatre6UpgradeNow")

local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridTheatre6Attribute = require("XUi/XUiTheatre6/OutSider/Grid/XUiGridTheatre6Attribute")

function XUiPanelTheatre6UpgradeNow:OnStart()
    self._AttrDataList = {}
    self:InitDynamicTable()
    self.GirdAttribute.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6UpgradeNow:InitDynamicTable()
    self._DynamicTable = XDynamicTableNormal.New(self.ListAttribute)
    self._DynamicTable:SetProxy(XUiGridTheatre6Attribute, self)
    self._DynamicTable:SetDelegate(self)
end

---刷新面板
---@param talentConfigs XTableTheatre6Talent[] 按等级排序的养成配置
---@param currentLv number 当前等级
function XUiPanelTheatre6UpgradeNow:Refresh(talentConfigs, currentLv)
    self.UiTxtLv.text = CS.XTextManager.GetText("TheatreDecorationTipsLevel", currentLv)
    self:CalcAttrSums(talentConfigs, currentLv)
    self._DynamicTable:SetDataSource(self._AttrDataList)
    self._DynamicTable:ReloadDataSync(1)
end

---计算已解锁等级的属性总和，按属性类型聚合
---@param talentConfigs XTableTheatre6Talent[]
---@param currentLv number
function XUiPanelTheatre6UpgradeNow:CalcAttrSums(talentConfigs, currentLv)
    local attrSumDict = {}
    local attrOrder = {}

    for _, cfg in ipairs(talentConfigs) do
        if cfg.Level > currentLv then
            break
        end
        if cfg.AttrTypes then
            for i, attrId in ipairs(cfg.AttrTypes) do
                if not attrSumDict[attrId] then
                    attrSumDict[attrId] = 0
                    table.insert(attrOrder, attrId)
                end
                attrSumDict[attrId] = attrSumDict[attrId] + (cfg.AttrNums[i] or 0)
            end
        end
    end

    self._AttrDataList = {}
    for _, attrId in ipairs(attrOrder) do
        table.insert(self._AttrDataList, { AttrId = attrId, TotalValue = attrSumDict[attrId] })
    end
end

function XUiPanelTheatre6UpgradeNow:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._AttrDataList[index]
        if data then
            grid:Update(data.AttrId, data.TotalValue)
        end
    end
end

return XUiPanelTheatre6UpgradeNow
