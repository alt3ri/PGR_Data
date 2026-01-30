local XUiGridSimulationBranchStyleChallenge = require('XUi/XUiFuben/XUiFubenSimulation/XUiGridSimulationBranchStyleChallenge')
local XUiFubenChapterDynamicTable = require('XUi/XUiFuben/UiDynamicList/XUiFubenChapterDynamicTable') -- Chapter大图列表

---@class XUiPanelSimulationBranchStyle
local XUiPanelSimulationBranchStyle = XClass(nil, 'XUiPanelSimulationBranchStyle')

function XUiPanelSimulationBranchStyle:Ctor(ui, parent)
    XUiHelper.InitUiClass(self, ui)
    self.Parent = parent
    
    ---@type XUiFubenChapterDynamicTable
    self.ChapterDynamicTable = XUiFubenChapterDynamicTable.New(self, self.PanelChapterListCurrent, XUiGridSimulationBranchStyleChallenge, handler(self, self.OnBtnChapterClicked))
end

function XUiPanelSimulationBranchStyle:SetupDynamicTable(datas)
    self.ChapterDynamicTable:RefreshList(datas)
end

---@param manager XFubenBaseAgency
function XUiPanelSimulationBranchStyle:OnBtnChapterClicked(index, manager)
    -- 只有是选中的，才直接打开界面
    if self.ChapterDynamicTable:GetCurrentSelectedIndex() == index then
        manager:ExOpenMainUi()
        return
    end
    
    -- 未选中要先跳过去播动画
    self.Mask.gameObject:SetActiveEx(true)
    
    self.ChapterDynamicTable:TweenToIndex(index, XFubenConfigs.ExtralLineWaitTime, function()
        self.Mask.gameObject:SetActiveEx(false)
    end)
end

return XUiPanelSimulationBranchStyle