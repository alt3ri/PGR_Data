local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@field _Control XPassportControl
---@class XUiPassportPanelTask:XUiNode
local XUiPassportPanelTask = XClass(XUiNode, "XUiPassportPanelTask")

local TaskTabConfig = {
    { Type = XEnumConst.PASSPORT.TASK_TYPE.DAILY, RedCondition = XRedPointConditions.Types.CONDITION_PASSPORT_TASK_DAILY_RED },
    { Type = XEnumConst.PASSPORT.TASK_TYPE.WEEKLY, RedCondition = XRedPointConditions.Types.CONDITION_PASSPORT_TASK_WEEKLY_RED },
    { Type = XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY, RedCondition = XRedPointConditions.Types.CONDITION_PASSPORT_TASK_ACTIVITY_RED },
}

function XUiPassportPanelTask:OnStart(model3d)
    self.CurrTabIndex = 0
    self.Model3D = model3d

    self.DynamicTable = XDynamicTableNormal.New(self.PanelTask)
    self.DynamicTable:SetProxy(XDynamicGridTask)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActive(false)

    self:InitTab()
    self:InitRedPoint()
end

function XUiPassportPanelTask:OnEnable()
    self.Model3D:ShowTaskCamera(true)
end

function XUiPassportPanelTask:OnDisable()
    self.Model3D:ShowTaskCamera(false)
end

function XUiPassportPanelTask:InitTab()
    local btnGroup = {}
    for i = 1, #TaskTabConfig do
        local btn = self["Btn0" .. i]
        if btn then
            table.insert(btnGroup, btn)
        end
    end

    self.PanelNoticeTitleBtnGroup:Init(btnGroup, function(index)
        self:OnSelectTab(index)
    end)
    self.PanelNoticeTitleBtnGroup:SelectIndex(1)
end

function XUiPassportPanelTask:InitRedPoint()
    for i, config in ipairs(TaskTabConfig) do
        local btn = self["Btn0" .. i]
        if btn then
            self:AddRedPointEvent(btn, function(_, count)
                btn:ShowReddot(count >= 0)
            end, self, { config.RedCondition })
        end
    end
end

function XUiPassportPanelTask:OnSelectTab(index)
    if self.CurrTabIndex == index then
        return
    end
    self.CurrTabIndex = index
    self:Refresh()
end

function XUiPassportPanelTask:GetCurrTaskType()
    local config = TaskTabConfig[self.CurrTabIndex]
    return config and config.Type
end

function XUiPassportPanelTask:Refresh()
    if not self:IsShow() then
        return
    end

    local taskType = self:GetCurrTaskType()
    if not taskType then
        return
    end

    self.Tasks = self._Control:GetPassportTask(taskType)
    for _, taskData in ipairs(self.Tasks) do
        taskData.ExRewardId = self._Control:GetPassportTaskExRewardId(taskData.Id)
    end
    self.DynamicTable:SetDataSource(self.Tasks)
    self.DynamicTable:ReloadDataASync()
    self:UpdateTabExRewardMark()
end

function XUiPassportPanelTask:UpdateTabExRewardMark()
    for i, config in ipairs(TaskTabConfig) do
        local rImgUp = self["RImgUp0" .. i]
        if rImgUp then
            rImgUp.gameObject:SetActiveEx(self._Control:HasPassportTaskExReward(config.Type))
        end
    end
end

function XUiPassportPanelTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.Tasks[index]
        grid.RootUi = self.Parent
        grid:ResetData(data)
        grid:AppendExtraReward(data.ExRewardId)
    end
end

function XUiPassportPanelTask:UpdateTime()
    if self:GetCurrTaskType() ~= XEnumConst.PASSPORT.TASK_TYPE.WEEKLY then
        return
    end
    if not self:IsShow() then
        return
    end

    local passportTaskGroupId = self._Control:GetPassportTaskGroupIdByType(XEnumConst.PASSPORT.TASK_TYPE.WEEKLY)
    if not XTool.IsNumberValid(passportTaskGroupId) then
        return
    end

    local timeId = self._Control:GetPassportTaskGroupTimeId(passportTaskGroupId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local nowServerTime = XTime.GetServerNowTimestamp()
    if not XTool.UObjIsNil(self.TxtTime) then
        self.TxtTime.text = XUiHelper.GetTime(endTime - nowServerTime, XUiHelper.TimeFormatType.PASSPORT)
    end
end

--一键领取当前页签任务
function XUiPassportPanelTask:FinishMultiTask()
    local taskType = self:GetCurrTaskType()
    if taskType then
        self._Control:FinishMultiTaskRequest(taskType)
    end
end

function XUiPassportPanelTask:Show()
    self:Open()
    self:Refresh()
end

function XUiPassportPanelTask:Hide()
    self:Close()
end

function XUiPassportPanelTask:IsShow()
    if XTool.UObjIsNil(self.GameObject) then
        return false
    end
    return self.GameObject.activeSelf
end

return XUiPassportPanelTask