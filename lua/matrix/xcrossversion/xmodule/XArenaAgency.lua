local super = require("XModule/XArena/XArenaAgency")
---@type XArenaAgency 分类
local XArenaAgency = XClassPartial('XArenaAgency')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XArenaAgency
end

function XArenaAgency:GetChallengeTaskIds(activityData, challengeId)
    local taskIds
    local maxId = self._Model:GetSpecialGroupMaxId()
    local activityNo = activityData:GetActivityNo()
    if activityNo <= maxId then
        taskIds = self._Model:GetSpecialGroupTaskIdByChallengeId(challengeId)
    else
        taskIds = self._Model:GetChallengeAreaTaskIdByChallengeId(challengeId)
    end
    return taskIds
end

return XArenaAgency