local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local stringGsub = string.gsub
local tableInsert = table.insert
local XUiPanelSkipAndTask = XClass(nil, "XUiPanelSkipAndTask")

function XUiPanelSkipAndTask:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self.RewardList = {}
    self:AutoAddListener()
end

function XUiPanelSkipAndTask:AutoAddListener()
    self.BtnGo.CallBack = function()
        self:OnBtnGoClick()
    end
    self.BtnFinish.CallBack = function()
        self:OnBtnFinishClick()
    end
end

function XUiPanelSkipAndTask:Refresh(activityCfg)
    self.ActivityCfg = activityCfg or self.ActivityCfg
    self.ActivityType = self.ActivityCfg.ActivityType

    self.SkipId = self.ActivityCfg.Params[1]
    local conditionId = self.ActivityCfg.ConditionId
    local conditionDesc
    if conditionId and conditionId > 0 then
        conditionDesc = XConditionManager.GetConditionDescById(conditionId)
    end
    self.TxtTitle.text = stringGsub(self.ActivityCfg.ActivityTitle, "\\n", "\n")
    self.TxtTime.text = XUiHelper.ReplaceTextNewLine(conditionDesc)
    self.TxtContent.text = stringGsub(self.ActivityCfg.ActivityDes, "\\n", "\n")

    self.TaskData = XDataCenter.TaskManager.GetTaskDataById(self.ActivityCfg.Params[2])

    if not self.TaskData then
        return
    end
    local taskConfig = XDataCenter.TaskManager.GetTaskTemplate(self.TaskData.Id)
    self:RefreshButton()
    self:RefreshReward(taskConfig.RewardId)
end

function XUiPanelSkipAndTask:RefreshReward(rewardId)
    --刷新奖励列表
    local rewards = XRewardManager.GetRewardList(rewardId)
    if not rewards then
        return
    end

    for i = 1, #rewards do
        local grid = self.RewardList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            local tempTab = {}
            tempTab.Transform = ui.transform
            tempTab.GameObject = ui.gameObject
            XTool.InitUiObject(tempTab)
            ui.gameObject:SetActiveEx(true)
            ui.transform:SetParent(self.PanelReward, false)
            tempTab.Item = XUiGridCommon.New(self.RootUi, tempTab.GirdItem)
            grid = tempTab
            tableInsert(self.RewardList, tempTab)
        end
        grid.Item:Refresh(rewards[i])
        grid.GameObject:SetActiveEx(true)
        grid.PanelReceive.gameObject:SetActiveEx(false)
        grid.PanelReceived.gameObject:SetActiveEx(false)
        if self.TaskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            grid.PanelReceive.gameObject:SetActiveEx(true)
        elseif self.TaskData.State == XDataCenter.TaskManager.TaskState.Finish then
            grid.PanelReceived.gameObject:SetActiveEx(true)
        end
    end
    for i = #rewards + 1, #self.RewardList do
        self.RewardList[i].GameObject:SetActiveEx(false)
    end
end

--根据任务状态刷新按钮显示
function XUiPanelSkipAndTask:RefreshButton()
    self.BtnFinish.gameObject:SetActiveEx(false)
    self.BtnGo.gameObject:SetActiveEx(false)

    if self.TaskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        self.BtnFinish.gameObject:SetActiveEx(true)
    elseif self.TaskData.State == XDataCenter.TaskManager.TaskState.Active or self.TaskData.State == XDataCenter.TaskManager.TaskState.Finish then
        self.BtnGo.gameObject:SetActiveEx(true)
    end
end

function XUiPanelSkipAndTask:OnBtnGoClick()
    XFunctionManager.SkipInterface(self.UrlId)
end

function XUiPanelSkipAndTask:OnBtnFinishClick()
    if not self.TaskData then
        return
    end
    XDataCenter.TaskManager.FinishTask(self.TaskData.Id, function(rewards)
        XUiManager.OpenUiObtain(rewards, nil, function()
            self:Refresh()
        end, nil)
    end)
end

return XUiPanelSkipAndTask