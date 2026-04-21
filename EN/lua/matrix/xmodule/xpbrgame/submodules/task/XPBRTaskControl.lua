---@class XPBRTaskControl : XControl
---@field private _Model XPBRGameModel
---@field _MainControl XPBRGameControl
local XPBRTaskControl = XClass(XControl, "XPBRTaskControl")

function XPBRTaskControl:OnInit()

end

function XPBRTaskControl:AddAgencyEvent()

end

function XPBRTaskControl:RemoveAgencyEvent()

end

function XPBRTaskControl:OnRelease()

end

--region Configs

---@return XTablePBRTaskGroup
function XPBRTaskControl:GetTablePBRTaskGroupCfgById(groupId)
    return self._Model:GetTablePBRTaskGroupCfgById(groupId)
end

function XPBRTaskControl:GetCurActivityTaskGroupIds()
    local activityCfg = self._Model:GetCurActivityCfg()

    if activityCfg then
        return activityCfg.TaskGroupIds
    end
end
--endregion

function XPBRTaskControl:GetTaskDataListByGroupId(groupId, isSort, needReceiveAll)
    local groupCfg = self._Model:GetTablePBRTaskGroupCfgById(groupId)

    if not groupCfg then
        return
    end

    local taskDataList = nil
    local canRecieveTaskDataList = nil

    if groupCfg.GroupType == XMVCA.XPBRGame.EnumConst.TaskGroupType.TaskId then
        taskDataList = XDataCenter.TaskManager.GetTaskIdListData(groupCfg.TaskIds, isSort)
    elseif groupCfg.GroupType == XMVCA.XPBRGame.EnumConst.TaskGroupType.TaskTimeLimitId then
        -- 约定是任务组时，只取数组顺位第一个Id
        local timelimitTaskId = groupCfg.TaskIds[1]

        taskDataList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(timelimitTaskId, isSort)
    else
        XLog.Error('PBRTaskGroup错误的GroupType配置，groupId:' .. groupId .. ', GroupType:' .. tostring(groupCfg.GroupType))
    end

    if needReceiveAll then
        -- 收集当前所有可领取任务数据，用于一键领取
        canRecieveTaskDataList = {}
        for _, taskData in ipairs(taskDataList) do
            if XTool.IsNumberValidEx(taskData) then
                taskData = XDataCenter.TaskManager.GetTaskDataById(taskData)
            end

            if taskData and taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                table.insert(canRecieveTaskDataList, taskData)
            end
        end
    end
    
    return taskDataList, canRecieveTaskDataList
end

return XPBRTaskControl