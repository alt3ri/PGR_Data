----------------------------------------------------------------
--主界面任务奖励检测
local XRedPointConditionMainTask = {}
local SubConditions = nil
function XRedPointConditionMainTask.GetSubConditions()
    SubConditions = SubConditions or
    {
        XRedPointConditions.Types.CONDITION_TASK_TYPE,
        XRedPointConditions.Types.CONDITION_MAIN_NEWPLAYER_TASK,
        XRedPointConditions.Types.CONDITION_MAIN_NEWBIE_TASK,
    }
    return SubConditions
end

function XRedPointConditionMainTask.Check()
    -- 新手入门任务
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MAIN_NEWBIE_TASK) then
        return true
    end
    
    -- 新手目标任务
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_MAIN_NEWPLAYER_TASK) then
        return true
    end
    
    -- 每日类型任务蓝点
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.Daily) then
        return true
    end

    -- 每周类型任务蓝点
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.Weekly) then
        return true
    end

    -- 活动类型任务蓝点
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_TYPE, XDataCenter.TaskManager.TaskType.Activity) then
        return true
    end

    -- 勤务任务
    if XRedPointConditions.Check(XRedPointConditions.Types.CONDITION_TASK_CANLIVER) then
        return true
    end

    return false
end

return XRedPointConditionMainTask