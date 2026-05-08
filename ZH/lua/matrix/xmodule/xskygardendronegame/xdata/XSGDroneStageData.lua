---@class XSGDroneStageData
local XSGDroneStageData = XClass(nil, "XSGDroneStageData")

function XSGDroneStageData:Ctor()
    self._StageId = 0
    self._IsFinish = 0
    self._MinCostTime = 0
    self._MaxScore = 0
    self._FinishTarget = {}
end

function XSGDroneStageData:Update(stageId, data)
    self._StageId = stageId
    self._IsFinish = data.IsFinished
    self._MinCostTime = data.MinCostTime
    self._MaxScore = data.MaxScore

    self._FinishTarget = {}
    for _, targetId in pairs(data.FinishedStarTargets) do
        self._FinishTarget[targetId] = true
    end
end

function XSGDroneStageData:IsEmpty()
    return not XTool.IsNumberValid(self._StageId)
end

function XSGDroneStageData:IsFinish()
    return self._IsFinish or false
end

function XSGDroneStageData:IsTargetFinish(targetId)
    return self._FinishTarget[targetId] or false
end

function XSGDroneStageData:GetFinishTarget()
    return self._FinishTarget
end

function XSGDroneStageData:GetStageId()
    return self._StageId or 0
end

function XSGDroneStageData:GetMinCostTime()
    return self._MinCostTime or 0
end

function XSGDroneStageData:GetMaxScore()
    return self._MaxScore or 0
end

return XSGDroneStageData