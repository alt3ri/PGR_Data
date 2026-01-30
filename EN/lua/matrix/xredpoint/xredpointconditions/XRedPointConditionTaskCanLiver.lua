----------------------------------------------------------------
--单个类型任务奖励检测
local XRedPointConditionTaskCanLiver = {}
local Events = nil
function XRedPointConditionTaskCanLiver.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVENT_TASK_SYNC),
        XRedPointEventElement.New(XEventId.EVENT_FUNCTION_OPEN_COMPLETE),
    }
    return Events
end

function XRedPointConditionTaskCanLiver.Check()
    local itemRestrictType = XEnumConst.ItemRestrict.Type.DrawCanLiver

    -- 已达到最大，直接无红点
    if XMVCA.XItemRestrict:IsAllItemsReachMax(itemRestrictType) then
        return false
    end

    -- 多 group 支持
    local taskGroupIds = XMVCA.XItemRestrict:GetTaskGroupIdList(itemRestrictType)
    if not taskGroupIds or #taskGroupIds == 0 then
        return false
    end

    -- 遍历所有group中所有task
    for _, groupId in ipairs(taskGroupIds) do
        if XTool.IsNumberValid(groupId) then
            local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId)
            if taskList then
                for _, task in pairs(taskList) do
                    if task.State == XDataCenter.TaskManager.TaskState.Achieved then
                        return true    -- 有一个可领就亮红点
                    end
                end
            end
        end
    end

    return false
end

return XRedPointConditionTaskCanLiver
