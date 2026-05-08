---@class XUiGridTheatre6TaskDetail : XUiNode 任务详情
---@field Parent XUiTheatre6RoomChooseTask
---@field _Control XTheatre6Control
---@param _TaskData XTheatre6StageTaskProtocol
---@param _SlotData XTheatre6StageTaskSlotDataProtocol
local XUiGridTheatre6TaskDetail = XClass(XUiNode, "XUiGridTheatre6TaskDetail")

local TaskState = XEnumConst.Theatre6.TaskState
local Choose = 1 --任务选择
local Show = 2 --任务展示
local Settle = 3 --任务结算

function XUiGridTheatre6TaskDetail:OnStart()
    self.BtnRefresh:AddEventListener(handler(self, self.OnBtnRefreshClick))
    self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClick))
    self.BtnRefresh.gameObject:SetActiveEx(false)
end

---任务展示/结算
---@param taskData XTheatre6StageTaskProtocol
function XUiGridTheatre6TaskDetail:SetData(taskData, isSettle)
    self._TaskData = taskData
    self._TaskId = taskData.TaskId
    self._Mode = isSettle and Settle or Show
    self._IsTaskFinish = self._Control:IsStageTaskFinish(self._TaskData) --任务是否已完成
    self:ShowTaskInfo()
    self:ShowDemand(true)
    self:ShowReward()
    self:ShowProgressReward()
    self.PanelChoose.gameObject:SetActiveEx(false)
    self.PanelSettlement.gameObject:SetActiveEx(true)
end

---任务选择
---@param slotData XTheatre6StageTaskSlotDataProtocol
function XUiGridTheatre6TaskDetail:SetSlotData(slotData, taskGroupId)
    local modelData = self._Control:GetCurPlayModeData()
    self._SlotData = slotData
    self._TaskId = slotData.TaskId
    self._TaskData = modelData.StageTasks[self._TaskId]
    self._Mode = Choose
    self._TaskGroupConfig = self._Control:GetStageTaskGroupConfig(taskGroupId)
    self:ShowTaskInfo()
    self:SetBtnRefresh()
    self:ShowDemand(false)
    self:ShowReward()
    self.PanelChoose.gameObject:SetActiveEx(true)
    self.PanelSettlement.gameObject:SetActiveEx(false)
end

function XUiGridTheatre6TaskDetail:UpdateChoose(isSelected)
    self.RImgBgChoose.gameObject:SetActiveEx(isSelected)
end

function XUiGridTheatre6TaskDetail:ShowTaskInfo()
    self._TaskConfig = self._Control:GetTaskConfig(self._TaskId)
    self.UiTxtName.text = self._TaskConfig.Name
    local starCount = self._Control:GetIntClientConfigValue("TaskQualityToStarCount", self._TaskConfig.Quality) or 0
    XUiHelper.RefreshCustomizedList(self.ImgStar.parent, self.ImgStar, starCount)
    self:UpdateChoose(false)
end

function XUiGridTheatre6TaskDetail:SetBtnRefresh()
    local freeRefresh = self._Control:GetTaskFreeRefreshTimes(self._TaskGroupConfig.Id)
    local count = self._SlotData.RefreshCount - freeRefresh
    local cost = 0
    if count >= 0 then
        cost = self._TaskGroupConfig.RefreshStartGold + count * self._TaskGroupConfig.RefreshAddGold
    end

    if cost <= 0 then
        self.BtnRefresh:SetName(XUiHelper.GetText("Theatre6FreeRefresh"))
        self.BtnRefresh:SetRawImageVisible(false)
    else
        self.BtnRefresh:SetName(cost)
        self.BtnRefresh:SetRawImageVisible(true)
        self.BtnRefresh:SetRawImage(self._Control:GetCoinIcon())
    end

    local modelData = self._Control:GetCurPlayModeData()
    self._IsGoldEnough = modelData.GoldAmount >= cost
    self._IsRefreshCountEnough = self._SlotData.RefreshCount < self._TaskGroupConfig.MaxRefresh
    self.BtnRefresh.gameObject:SetActiveEx(self._IsRefreshCountEnough)
    self.BtnRefresh:SetButtonState(self._IsGoldEnough and XUiButtonState.Normal or XUiButtonState.Disable)
end

function XUiGridTheatre6TaskDetail:ShowDemand(isShowProgress)
    local conditionId = self._TaskConfig.ConditionId
    local isShowCondition = XTool.IsNumberValid(conditionId)
    ---@type XTheatre6StageTaskGoodsSlotProtocol[]
    local goodsSlots = self._TaskData.GoodsSlots
    local node = self._Mode == Choose and self.GridDemandChoose or self.GridDemandSettle
    local count = isShowCondition and 1 or #goodsSlots

    XUiHelper.RefreshCustomizedList(node.parent, node, count, function(i, go)
        local grid = {}
        XUiHelper.InitUiClass(grid, go)

        grid.TxtCondition.gameObject:SetActiveEx(isShowCondition)
        grid.BtnClick.gameObject:SetActiveEx(not isShowCondition)
        grid.PanelGoods.gameObject:SetActiveEx(not isShowCondition)

        local cur, total = 0, 0
        if isShowCondition then
            local condConfig = self._Control:GetConditionConfig(conditionId)
            cur, total = self._TaskData.Schedule, self._TaskConfig.ConditionValue
            grid.TxtCondition.text = condConfig.Desc
        else
            local data = goodsSlots[i]
            cur, total = data.Amount, data.NeedNum
            grid.RImgResource:SetRawImage(self._Control:GetStageGoodsConfig(data.GoodsId).Icon)
            grid.BtnClick:AddEventListener(function()
                self._Control:OpenGoodsTip(data.GoodsId)
            end)
        end

        local isFinish = cur >= total
        if isShowProgress then
            grid.UiPanelFinsh.gameObject:SetActiveEx(isFinish)
            grid.UiImgBar.fillAmount = (isFinish or total == 0) and 1 or math.min(1, cur / total)
        end

        local isShowFinish = isShowProgress and isFinish
        grid.TxtNum.text = isShowFinish and XUiHelper.GetText("Theatre6TaskFinish") or string.format("%s/%s", cur, total)
    end)
end

function XUiGridTheatre6TaskDetail:ShowReward()
    ---@type Theatre6PreviewRewardGoodsProtocol
    local rewardGoods = self._TaskData.RewardGoods
    XUiHelper.RefreshCustomizedList(self.GridItem.parent, self.GridItem, #rewardGoods, function(i, go)
        ---@type XUiGridTheatre6TaskReward
        local grid = require("XUi/XUiTheatre6/Task/Grid/XUiGridTheatre6TaskReward").New(go, self)
        grid:Update(rewardGoods[i])
        if self._Mode == Settle then
            grid:SetFinish(self._IsTaskFinish)
        end
    end)
end

---显示任务完成进度及对应的进度奖励
function XUiGridTheatre6TaskDetail:ShowProgressReward()
    local isSettleMode = self._Mode == Settle
    self.UiTxtSettlement.gameObject:SetActiveEx(isSettleMode)
    self.GridResource.gameObject:SetActiveEx(isSettleMode and not self._IsTaskFinish)

    if self._Mode == Choose then
        return
    end

    if self._IsTaskFinish then
        self.UiTxtSettlement.text = XUiHelper.GetText("Theatre6TaskProgressFinish")
    else
        if not self._GridResource then
            ---@type XUiGridTheatre6BossRewardResource
            self._GridResource = require("XUi/XUiTheatre6/Boss/Grid/XUiGridTheatre6BossRewardResource").New(self.GridResource, self)
        end
        self._GridResource:RefreshGold(self._TaskData.FailAddNum)
        self.UiTxtSettlement.text = string.format("%s%%", math.ceil(self._TaskData.Progress / 10))
    end
end

function XUiGridTheatre6TaskDetail:GetTaskId()
    return self._TaskId
end

function XUiGridTheatre6TaskDetail:OnBtnRefreshClick()
    if not self._IsRefreshCountEnough then
        self._Control:ShowTipWithKey("Theatre6TaskRefreshTip")
        return
    end

    if not self._IsGoldEnough then
        self._Control:ShowTipWithKey("Theatre6TaskGoldTip")
        return
    end

    self._Control:RequestRefreshTask(self._TaskId, self._SlotData.Index, function()
        self.Parent:UpdateTask()
        self:SetBtnRefresh()
    end)
end

function XUiGridTheatre6TaskDetail:OnBtnChooseClick()
    self.Parent:ChooseTask(self._SlotData.Index)
end

return XUiGridTheatre6TaskDetail
