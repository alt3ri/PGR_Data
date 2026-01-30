---@type XViewModelTransfiniteGift
require("XEntity/XTransfinite/ViewModel/XViewModelTransfiniteGift")
local XViewModelTransfiniteGift = XClassPartial('XViewModelTransfiniteGift')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XViewModelTransfiniteGift
end

function XViewModelTransfiniteGift:GetScoreAndRewardArray(region)
    local timeId = XTransfiniteConfigs.GetSepcialTreatmentTimeId(region:GetId())
    local scoreArray, reward
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        scoreArray, reward = region:GetSpecialScoreAndRewardArray()
    else
        scoreArray, reward = region:GetScoreAndRewardArray()
    end
    return scoreArray, reward
end

function XViewModelTransfiniteGift:GetChallengeTaskIdList(data)
    local challengeTaskIdList
    local timeId = XTransfiniteConfigs.GetSpecialTaskTimeId(data.ChallengeTaskGroupId)
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        challengeTaskIdList = XTransfiniteConfigs.GetSpecialTaskTaskIds(data.ChallengeTaskGroupId)
    else
        challengeTaskIdList = XTransfiniteConfigs.GetTaskTaskIds(data.ChallengeTaskGroupId)
    end
    return challengeTaskIdList
end

return XViewModelTransfiniteGift