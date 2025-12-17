---@type XStrongholdManager 分类
local XStrongholdManager = XDataCenter.StrongholdManager

if not XDataCenter.CrossVersionManager.GetEnable() then
    return
end

function XStrongholdManager.GetGroupRewardId(groupId)
    local maxId = XStrongholdConfigs.GetSpecialGroupMaxId()
    local levelId = XStrongholdManager.GetLevelId()
    local _ActivityId = self:GetActivityId()
    if _ActivityId > maxId then
        return XStrongholdConfigs.GetGroupRewardId(groupId, levelId)
    end
    return XStrongholdConfigs.GetSpecialGroupRewardId(groupId, levelId)
end

return XStrongholdManager