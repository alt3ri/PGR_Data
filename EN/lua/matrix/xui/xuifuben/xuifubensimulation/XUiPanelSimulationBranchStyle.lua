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
    -- 切换二级标签时数据源变化，必须重置选中index为0（第1个格子），
    -- 否则沿用旧的CurrentSelectedIndex会导致新数据源中第1个格子被当作非选中格子播CloseAnim
    self.ChapterDynamicTable:RefreshList(datas, 0)
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

function XUiPanelSimulationBranchStyle:OnDestroy()
    if self.ChapterDynamicTable and self.ChapterDynamicTable.OnDestroy then
        self.ChapterDynamicTable:OnDestroy()
    end
end

return XUiPanelSimulationBranchStyle