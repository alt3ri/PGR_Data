local XUiTheatre5SkillHandbookItemGrid = require("XUi/XUiTheatre5/XUiTheatre5SkillHandbook/XUiTheatre5SkillHandbookItemGrid")

---@class XUiTheatre5SkillHandbookTabGrid : XUiNode
---@field _Control XTheatre5Control
local XUiTheatre5SkillHandbookTabGrid = XClass(XUiNode, "XUiTheatre5SkillHandbookTabGrid")

function XUiTheatre5SkillHandbookTabGrid:OnStart()
    ---@type XUiTheatre5SkillHandbookItemGrid[]
    self._Grids = {}
end

---@param data XUiTheatre5SkillHandbookTabGridData
function XUiTheatre5SkillHandbookTabGrid:Update(data)
    if data.HideTagName then
        self.Text.transform.parent.gameObject:SetActiveEx(false)
    else
        self.Text.transform.parent.gameObject:SetActiveEx(true)
    end
    self.Text.text = data.TagName
    XTool.UpdateDynamicItemLazy(self._Grids, data.Items, self.GridShop, XUiTheatre5SkillHandbookItemGrid, self, 1, 1)
end

function XUiTheatre5SkillHandbookTabGrid:UpdateSelectState(selectedData)
    for i, grid in pairs(self._Grids) do
        grid:UpdateSelectState(selectedData)
    end
end

function XUiTheatre5SkillHandbookTabGrid:OnDisable()
    if self._TimerDelayInit then
        XScheduleManager.UnSchedule(self._TimerDelayInit)
        self:_RemoveTimerIdAndDoCallback(self._TimerDelayInit)
        self._TimerDelayInit = nil
    end
end

function XUiTheatre5SkillHandbookTabGrid:GetGrids()
    return self._Grids
end

return XUiTheatre5SkillHandbookTabGrid