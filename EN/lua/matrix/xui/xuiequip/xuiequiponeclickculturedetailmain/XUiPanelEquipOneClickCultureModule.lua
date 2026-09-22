local XUiGridEquipOneClickCultureCost = require("XUi/XUiEquip/XUiEquipOneClickCultureDetailMain/XUiGridEquipOneClickCultureCost")

---@class XUiPanelEquipOneClickCultureModule:XUiNode
---@field Parent XUiEquipOneClickCultureDetailMain
local XUiPanelEquipOneClickCultureModule = XClass(XUiNode, "XUiPanelEquipOneClickCultureModule")

function XUiPanelEquipOneClickCultureModule:OnStart()
    self._CostGridList = {}
    self._SpecialCostGridList = {}
    self.BtnEnter:AddEventListener(handler(self, self.OnBtnEnterClick))
end

function XUiPanelEquipOneClickCultureModule:Update(data)
    self.Data = data
    self.UiTxtTitle.text = data.Title
    self.GroupMax.gameObject:SetActiveEx(data.IsComplete)
    self.BtnEnter.gameObject:SetActiveEx(not data.IsComplete)
    
    local hasCost = not XTool.IsTableEmpty(data.CostList)
    local showCost = not data.IsComplete and hasCost
    self.PanelCost.gameObject:SetActiveEx(showCost)
    if not showCost then
        for i = 1, #self._CostGridList do
            self._CostGridList[i]:Close()
        end
        for i = 1, #self._SpecialCostGridList do
            self._SpecialCostGridList[i]:Close()
        end
        return
    end

    local normalCostList = {}
    local specialCostList = {}
    for _, costData in ipairs(data.CostList or {}) do
        if costData.IsSpecial then
            table.insert(specialCostList, costData)
        else
            table.insert(normalCostList, costData)
        end
    end
    XTool.UpdateDynamicItem(self._CostGridList, normalCostList, self.GridCost, XUiGridEquipOneClickCultureCost, self)
    XTool.UpdateDynamicItem(self._SpecialCostGridList, specialCostList, self.GridCostSpecial, XUiGridEquipOneClickCultureCost, self)
    self.PanelSpecial.gameObject:SetActiveEx(#specialCostList > 0)
end

function XUiPanelEquipOneClickCultureModule:OnBtnEnterClick()
    self.Parent:OpenCultureUi(self.Data.TabIndex)
end

return XUiPanelEquipOneClickCultureModule
