---@class XQuestBaseAction
---@field _Container XQuestActionContainer
---@field _OperateData XBigWorldQuestOpData
local XQuestBaseAction = XClass(nil, "XQuestBaseAction")

function XQuestBaseAction:Ctor()
end

function XQuestBaseAction:Init(container, ...)
    self._Container = container
    self:OnInit(...)
end

function XQuestBaseAction:OnInit(...)
end

function XQuestBaseAction:Execute()
end

function XQuestBaseAction:Finish()
    if self:IsFinished() then
        return
    end
    
    self:OnFinish()
    local container = self._Container
    self._Container = nil
    container:RecycleAction(self)
    container:RunNext()
end

function XQuestBaseAction:OnFinish()
end

function XQuestBaseAction:IsFinished()
    return self._Container == nil
end

function XQuestBaseAction:OnPause()
end

function XQuestBaseAction:OnResume()
    if self:IsFinished() then
        return
    end
    self._Container:RunNext()
end

function XQuestBaseAction:OnDestroy()
end

function XQuestBaseAction:GetActionType()
    XLog.Error("子类请实现此方法")
end

return XQuestBaseAction