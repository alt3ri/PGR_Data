local XBigWorldViewData = require("XUi/XUiBigWorld/XHud/ViewData/XBigWorldViewData")

---@class XBigWorldQuestData : XBigWorldViewData
---@field ObjectiveList XBigWorldObjectiveData[]
---@field Objective XBigWorldObjectiveData
---@field Operate number 操作类型
---@field QuestId number 任务Id
---@field StepId number 步骤Id
---@field IsTempShow boolean 临时展示，在倒计时完成后刷新界面
local XBigWorldQuestData = XClass(XBigWorldViewData, "XBigWorldQuestData")

function XBigWorldQuestData:OnReset()
    self.Operate = 0
    self.QuestId = 0
    self.StepId = 0
    self.IsTempShow = false
    self.ObjectiveList = false
    self.Objective = false
    self.IsSingle = false
    self.IsSkipAnimation = false
end

function XBigWorldQuestData:SetParams(operate, questId, stepId, isSingle, objectiveList, isTempShow, isSkipAnimation)
    self.Operate = operate or 0
    self.QuestId = questId or 0
    self.StepId = stepId or 0
    self.IsSingle = isSingle or false
    if isSingle then
        self.Objective = objectiveList
    else
        self.ObjectiveList = objectiveList or false
    end
    self.IsTempShow = isTempShow or false
    self.IsSkipAnimation = isSkipAnimation or false
end

function XBigWorldQuestData:GetHashCode()
    if not self:IsAlive() then
        XLog.Error("XBigWorldQuestData:GetHashCode - Cannot get hash code for recycled data.")
        return 0
    end
    local k = self.PrimaryKey
    k = k * self.SecondaryKey + self.QuestId
    k = k * self.SecondaryKey + self.StepId

    if self.Objective then
        k = k * self.SecondaryKey + self.Objective:GetHashCode()
    end
    if self.ObjectiveList then
        for _, objective in ipairs(self.ObjectiveList) do
            k = k * self.SecondaryKey + objective:GetHashCode()
        end
    end
    return k * self.Operate
end

function XBigWorldQuestData:GetQuestId()
    return self.QuestId
end

function XBigWorldQuestData:GetStepId()
    return self.StepId
end

function XBigWorldQuestData:GetOperate()
    return self.Operate
end

function XBigWorldQuestData:CheckIsSingle()
    return self.IsSingle
end

function XBigWorldQuestData:CheckIsTempShow()
    return self.IsTempShow
end

---@return XBigWorldObjectiveData[]
function XBigWorldQuestData:GetObjectiveList()
    return self.ObjectiveList
end

---@return XBigWorldObjectiveData
function XBigWorldQuestData:GetObjective()
    return self.Objective
end

function XBigWorldQuestData:CheckIsSkipAnimation()
    return self.IsSkipAnimation
end

return XBigWorldQuestData