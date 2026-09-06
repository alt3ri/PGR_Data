---@class XUiGridPunishaarTask: XUiNode
---@field protected _Control XPunishaarControl
local XUiGridPunishaarTask = XClass(XUiNode, 'XUiGridPunishaarTask')
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
--任务子组件
function XUiGridPunishaarTask:OnStart()
    self._TaskData = nil
    self.BtnReceive:AddEventListener(handler(self, self.OnBtnReceiveClick))
    self.BtnSkip:AddEventListener(handler(self, self.OnBtnSkip))
end

function XUiGridPunishaarTask:Update(taskData)
    self._TaskData = taskData

    local config = XDataCenter.TaskManager.GetTaskTemplate(taskData.Id)
    if not config then
        return
    end

    self.tableData = config
    self.TxtTaskName.text = config.Title
    self.TxtTaskDescribe.text = XUiHelper.ReplaceTextNewLine(config.Desc)

    -- 进度
    local curProcess = taskData.CurProcess or 0
    local totalProcess = taskData.TotalProcess or 0

    if totalProcess > 0 then
        self.TxtStarNums.text = string.format("%s/%s", curProcess, totalProcess)
        self.TaskProgress.fillAmount = curProcess / totalProcess
    else
        self.TxtStarNums.text = ""
        self.TaskProgress.fillAmount = 0
    end

    -- 状态
    local state = taskData.State
    local isAchieved = state == XDataCenter.TaskManager.TaskState.Achieved
    local isFinished = state == XDataCenter.TaskManager.TaskState.Finish
    local isDoing = not isAchieved and not isFinished
    local canSkip = isDoing and XTool.IsNumberValid(config.SkipId)

    self.BtnReceive.gameObject:SetActiveEx(isAchieved)
    self.BtnSkip.gameObject:SetActiveEx(isDoing)
    self.ImgAlreadyReceived.gameObject:SetActiveEx(isFinished)

    self.BtnSkip:SetButtonState(canSkip and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self:InitRewardsList(taskData)
end

function XUiGridPunishaarTask:OnBtnReceiveClick()
    if self._TaskData.State
        ~= XDataCenter.TaskManager.TaskState.Achieved then
        return
    end

    XDataCenter.TaskManager.FinishTask(
        self._TaskData.Id,
        function(rewardGoodsList)
            XUiManager.OpenUiObtain(rewardGoodsList)
            self.Parent:OnGainTaskReward()
        end
    )
end

function XUiGridPunishaarTask:OnBtnSkip()
    local config = XDataCenter.TaskManager.GetTaskTemplate(self._TaskData.Id)
    local skipId = config and config.SkipId

    if not XTool.IsNumberValid(skipId) then
        return
    end

    if XDataCenter.RoomManager.RoomData then
        local title = CS.XTextManager.GetText("TipTitle")
        local content = CS.XTextManager.GetText("OnlineInstanceQuitRoom")

        XUiManager.DialogTip(
            title,
            content,
            XUiManager.DialogType.Normal,
            nil,
            function()
                XLuaUiManager.RunMain()
                XFunctionManager.SkipInterface(skipId)
            end
        )
        return
    end

    XFunctionManager.SkipInterface(skipId)
end

function XUiGridPunishaarTask:InitRewardsList(taskData)
    local rewards = taskData.RewardsList
    local count = rewards and #rewards or 0
    XUiHelper.RefreshCustomizedList(self.RewardsContent, self.RewardGrid, count, function(index, obj)
        local gridCommont = XUiGridCommon.New(self.Parent, obj)
        gridCommont:Refresh(rewards[index])
    end)
end

return XUiGridPunishaarTask
