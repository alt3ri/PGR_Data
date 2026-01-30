---@class XUiPlotExhibitionMainFilterGrid : XUiNode
---@field _Control XPlotExhibitionControl
---@field Parent XUiPlotExhibitionMain
local XUiPlotExhibitionMainFilterGrid = XClass(XUiNode, "XUiPlotExhibitionMainFilterGrid")

function XUiPlotExhibitionMainFilterGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end

---@param data XPlotExhibitionControlFilter
function XUiPlotExhibitionMainFilterGrid:Update(data)
    self._Data = data
    if data.IsSelected then
        self.Button:SetButtonState(CS.UiButtonState.Select)
    else
        self.Button:SetButtonState(CS.UiButtonState.Normal)
    end
    self.Button:SetNameByGroup(0, data.Name)
    self.Button:SetRawImage(data.Icon)
end

function XUiPlotExhibitionMainFilterGrid:OnClick()
    local isSelected = not self._Data.IsSelected
    if isSelected then
        -- 收集上一次ui显示上存在的角色，在下一次筛选刷新后，有新的角色出现时，播放动画
        local data = self._Control:GetUiData().Main
        local roleList = data.FilterRoleList
        local existRoleDict = {}
        for i, v in ipairs(roleList) do
            existRoleDict[v.Id] = true
        end
        self._Control:SetFilterForceSelected(self._Data.Id, isSelected)
        self.Parent:UpdateByFilter(existRoleDict)
    else
        self._Control:SetFilterForceSelected(self._Data.Id, isSelected)
        self.Parent:UpdateByFilter()
    end
end

return XUiPlotExhibitionMainFilterGrid