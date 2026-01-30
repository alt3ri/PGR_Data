--- 肉鸽5 任务红点
local XRedPointTheatre5Task = {}

function XRedPointTheatre5Task.Check()
    -- 先判断活动是否开启
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre5, true, true) then
        return false
    end
 
    local configs = XMVCA.XTheatre5:GetValidShopOrTaskList(XMVCA.XTheatre5.EnumConst.TaskShopType.Task)
    if not configs or #configs <= 0 then
        return false
    end
    local taskTimeLimitId = {}
    for _, config in pairs(configs) do
        if config.TaskTimeLimitId then
            table.insert(taskTimeLimitId, config.TaskTimeLimitId)
        end
    end
    -- 有任务可领取
    for i = 1, #taskTimeLimitId do
        local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskTimeLimitId[i])
        if taskTimeLimitCfg and taskTimeLimitCfg.TaskId then
            for _, taskId in pairs(taskTimeLimitCfg.TaskId) do
                if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                    return true
                end
            end
        end
    end
    -- 有任务新增
    for _, config in pairs(configs) do
        if XMVCA.XTheatre5:CheckNewTaskByTaskConfig(config) then
            return true
        end
    end
    return false
end

return XRedPointTheatre5Task