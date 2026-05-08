---@class XUiGridTheatre6TaskDemand : XUiNode 材料任务需求
---@field _Control XTheatre6Control
---@field Parent XUiTheatre6RoomEitheror
local XUiGridTheatre6TaskDemand = XClass(XUiNode, "XUiGridTheatre6TaskDemand")

local TaskState = XEnumConst.Theatre6.TaskState
local WaitTime = 1000

function XUiGridTheatre6TaskDemand:OnStart()
    self:ShowCountChange(nil)
    self:ShowHighLight(false)
end

---@param taskData XTheatre6StageTaskProtocol
function XUiGridTheatre6TaskDemand:SetData(taskData, slotIndex)
    ---@type XTheatre6StageTaskProtocol
    self._TaskData = taskData
    ---@type XTheatre6StageTaskGoodsSlotProtocol
    local goodsSlot = taskData.GoodsSlots[slotIndex]

    local taskConfig = self._Control:GetTaskConfig(taskData.TaskId)
    local isShowCondition = XTool.IsNumberValid(taskConfig.ConditionId)

    self.TxtCondition.gameObject:SetActiveEx(isShowCondition)
    self.PanelGoods.gameObject:SetActiveEx(not isShowCondition)

    local cur, total
    if isShowCondition then
        cur, total = taskData.Schedule, taskConfig.ConditionValue
        self.TxtCondition.text = self._Control:GetConditionConfig(taskConfig.ConditionId).Desc
    else
        cur, total = goodsSlot.Amount, goodsSlot.NeedNum
        local icon = self._Control:GetStageGoodsConfig(goodsSlot.GoodsId).Icon
        self.RImgResource:SetRawImage(icon)
    end

    --显示材料变化
    local changeValue
    if self._Amount and cur > self._Amount then
        changeValue = cur - self._Amount
    end
    self._Amount, self._NeedNum = cur, total
    if changeValue then
        self:ShowCountChange(changeValue)
    end
end

function XUiGridTheatre6TaskDemand:UpdateView()
    if self:IsTaskFinish() then
        self.TxtNum.text = XUiHelper.GetText("Theatre6TaskFinish")
        self.UiImgBar.fillAmount = 1
    else
        self.TxtNum.text = string.format("%s/%s", self._Amount, self._NeedNum)
        self.UiImgBar.fillAmount = math.min(1, self._Amount / self._NeedNum)
    end
end

function XUiGridTheatre6TaskDemand:ShowCountChange(add)
    local isAdd = XTool.IsNumberValid(add)
    self.TxtNumAdd.gameObject:SetActiveEx(isAdd)
    self.UiImgBarAdd.gameObject:SetActiveEx(isAdd)
    
    if not isAdd then
        return
    end

    self.TxtNumAdd.text = string.format("+%s", add)
    self.UiImgBarAdd.fillAmount = math.min(1, self._Amount / self._NeedNum)
    local timerId = XScheduleManager.ScheduleOnce(function()
        self.TxtNumAdd.gameObject:SetActiveEx(false)
        self.UiImgBarAdd.gameObject:SetActiveEx(false)
        self:UpdateView()
    end, WaitTime)
    self.Parent:_AddTimerId(timerId)
end

---显示高亮
function XUiGridTheatre6TaskDemand:ShowHighLight(isVisible)
    local isFinish = self:IsTaskFinish()
    self.RImgResourceFaguang.gameObject:SetActiveEx(not isFinish and isVisible)
end

function XUiGridTheatre6TaskDemand:IsTaskFinish()
    return self._Amount and self._Amount >= self._NeedNum
end

return XUiGridTheatre6TaskDemand
