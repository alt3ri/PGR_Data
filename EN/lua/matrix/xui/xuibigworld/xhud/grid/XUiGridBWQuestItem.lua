---@class XUiGridBWQuestItem : XUiNode
---@field Parent XUiBigWorldPanelQuest
local XUiGridBWQuestItem = XClass(XUiNode, "XUiGridBWQuestItem")

local CsHold = CS.UnityEngine.Playables.DirectorWrapMode.Hold

function XUiGridBWQuestItem:OnStart()
    XUiHelper.RegisterClickEvent(self.Parent, self.Transform, self.Parent.OnQuestClick)
    self.FxGridQuestEnable = self.Transform:FindTransform("FxGridQuestEnable")
    self.FxGridQuestFinish = self.Transform:FindTransform("FxGridQuestFinish")
    self.QuestEnable = self.Animation:FindTransform("QuestEnable")
end

function XUiGridBWQuestItem:OnEnable()
end

function XUiGridBWQuestItem:OnDisable()
    self.FxGridQuestEnable.gameObject:SetActiveEx(false)
    self.FxGridQuestFinish.gameObject:SetActiveEx(false)
end

---@param objective XBigWorldObjectiveData
function XUiGridBWQuestItem:Update(objective, index)
    self:SetObjectiveId(objective.Id)
    self.TxtContent.text = objective.Description
    local isFinish = objective.IsCompleted
    self:UpdateFinish(isFinish)
end

function XUiGridBWQuestItem:UpdateFinish(isFinish)
    self.Complete.gameObject:SetActiveEx(isFinish)
    self.UnComplete.gameObject:SetActiveEx(not isFinish)
end

function XUiGridBWQuestItem:SetObjectiveId(id)
    self._Id = id
end

function XUiGridBWQuestItem:GetObjectiveId()
    return self._Id
end

function XUiGridBWQuestItem:CreateYellowFlash()
    return self.Parent:CreateObjectiveAnimation(self.GridQuestEnable)
end

function XUiGridBWQuestItem:CreateGreenFlash()
    return self.Parent:CreateObjectiveAnimation(self.GridQuestFinish)
end

function XUiGridBWQuestItem:CreateFade()
    return self.Parent:CreateObjectiveAnimation(self.QuestEnable)
end

function XUiGridBWQuestItem:PlayYellowFlash()
    self.GridQuestEnable:PlayTimelineAnimation(nil, nil, CsHold, true)
end

function XUiGridBWQuestItem:PlayGreenFlash()
    self.GridQuestFinish:PlayTimelineAnimation(nil, nil, CsHold, true)
end

function XUiGridBWQuestItem:PlayFade()
    self.QuestEnable:PlayTimelineAnimation(nil, nil, CsHold, true)
end

return XUiGridBWQuestItem