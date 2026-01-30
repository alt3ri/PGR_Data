---@class XUiSoloReformPopupRewardItem: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformPopupRewardItem = XClass(XUiNode, 'XUiSoloReformPopupRewardItem')
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiSoloReformPopupRewardItem:OnStart()
    self._TaskData = nil
   XUiHelper.RegisterClickEvent(self, self.BtnReceive, self.OnBtnReceiveClick)
end
function XUiSoloReformPopupRewardItem:Update(taskData)
    self._TaskData = taskData
    local state = taskData.State
    self.TxtStarNums.text = string.format("%s/%s", taskData.CurProcess, taskData.TotalProcess)
    self.BtnReceive.gameObject:SetActiveEx(state == XDataCenter.TaskManager.TaskState.Achieved)
    self.ImgCannotReceive.gameObject:SetActiveEx(state == XDataCenter.TaskManager.TaskState.Active)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(state == XDataCenter.TaskManager.TaskState.Finish)
    self:InitRewardsList(taskData)
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

function XUiSoloReformPopupRewardItem:InitRewardsList(taskData)
    local rewards = taskData.RewardsList
    local count = rewards and #rewards or 0
    XUiHelper.RefreshCustomizedList(self.RewardsContent, self.RewardGrid, count, function(index, obj)
        local gridCommont = XUiGridCommon.New(self.Parent, obj)
        gridCommont:Refresh(rewards[index])
    end)
end

return XUiSoloReformPopupRewardItem
