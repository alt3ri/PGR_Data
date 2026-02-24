---@class XUiSoloReformPopupRewardItem: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformPopupRewardItem = XClass(XUiNode, 'XUiSoloReformPopupRewardItem')
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiSoloReformPopupRewardItem:OnStart()
    self._TaskData = nil
    self.BtnReceive:AddEventListener(handler(self, self.OnBtnReceiveClick))
    self.BtnSkip:AddEventListener(handler(self, self.OnBtnSkip))
end

function XUiSoloReformPopupRewardItem:Update(taskData,taskType)
    self._TaskData = taskData
    local state = taskData.State
    -- self.TxtTaskNumQian.gameObject:SetActiveEx(taskType ~= 2)
    if taskData.TotalProcess > 0 then
        self.TxtStarNums.text = string.format("%s/%s", taskData.CurProcess, taskData.TotalProcess)
        self.TaskProgress.fillAmount = taskData.CurProcess / taskData.TotalProcess
    else
        self.TaskProgress.fillAmount = 0
        self.TxtStarNums.text = ""
    end
    self.BtnReceive.gameObject:SetActiveEx(state == XDataCenter.TaskManager.TaskState.Achieved)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(state == XDataCenter.TaskManager.TaskState.Finish)
    self:InitRewardsList(taskData)

    local config = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
    self.tableData = config
    self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = XUiHelper.ReplaceTextNewLine(config.Desc)
    self.BtnSkip.gameObject:SetActiveEx(state == XDataCenter.TaskManager.TaskState.Active and config.SkipId ~= nil)
    self.ImgCannotReceive.gameObject:SetActiveEx(state == XDataCenter.TaskManager.TaskState.Active and
        config.SkipId == nil)
    -- self.TxtSubTypeTip.text = config.Suffix or ""
end

function XUiSoloReformPopupRewardItem:OnBtnReceiveClick()
    local taskCondition = self._TaskData.State

    if taskCondition == XDataCenter.TaskManager.TaskState.Achieved then
        XDataCenter.Reform2ndManager.RequestFinishTask(self._TaskData.Id, function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            self._Control:DispatchEvent(XMVCA.XSoloReform.EventId.EVENT_GAIN_TASK_REWARD)
        end)
    end
end

function XUiSoloReformPopupRewardItem:OnBtnSkip()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self._TaskData.Id)

    XFunctionManager.SkipInterface(config.SkipId)
end

function XUiSoloReformPopupRewardItem:InitRewardsList(taskData)
    local rewards = taskData.RewardsList
    local count = rewards and #rewards or 0
    XUiHelper.RefreshCustomizedList(self.RewardsContent, self.RewardGrid, count, function(index, obj)
        local gridCommont = XUiGridCommon.New(self.Parent, obj)
        gridCommont:Refresh(rewards[index])
    end)
end

return XUiSoloReformPopupRewardItem
