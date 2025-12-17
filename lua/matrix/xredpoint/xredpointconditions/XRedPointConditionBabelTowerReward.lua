local XRedPointConditionBabelTowerReward = {}

-- activityType : XFubenBabelTowerConfigs.ActivityType
function XRedPointConditionBabelTowerReward.Check(activityType)
    local taskDatas = nil
    if activityType == nil or activityType == 0 then
        taskDatas = XDataCenter.FubenBabelTowerManager.GetFullTaskList()
    elseif activityType == XFubenBabelTowerConfigs.ActivityType.Normal then
        taskDatas = XDataCenter.FubenBabelTowerManager.GetTasksByGroupIndex(1, false)
    elseif activityType == XFubenBabelTowerConfigs.ActivityType.Extra then
        taskDatas = XDataCenter.FubenBabelTowerManager.GetTasksByGroupIndex(2, false)
    end
    if XTool.IsTableEmpty(taskDatas) then
        return false
    end
    for _, taskData in pairs(taskDatas) do
        if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
            return true
        end
    end
    return false
end

return XRedPointConditionBabelTowerReward