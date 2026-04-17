---@class XReCallActivityAgency : XAgency
---@field private _Model XReCallActivityModel
local XReCallActivityAgency = XClass(XAgency, "XReCallActivityAgency")

function XReCallActivityAgency:OnInit()
    --初始化一些变量
end

function XReCallActivityAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyHoldRegressionData = Handler(self, self.OnNotifyHoldRegressionData)
    XRpc.NotifyHoldRegressionTaskInfo = Handler(self, self.OnNotifyHoldRegressionTaskInfo)
    XRpc.NotifyHoldRegressionIgnoreChannel = Handler(self, self.OnNotifyHoldRegressionIgnoreChannel)
end

function XReCallActivityAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XReCallActivityAgency:OnNotifyHoldRegressionData(data)
    if data.HoldRegressionData then
        self._Model:SetRecallData(data.HoldRegressionData)
        self._Model:UpdateTaskData(data.HoldRegressionData.InviteInfo.TaskInfos)
        self._Model:SetInviteCount(data.HoldRegressionData.InviteInfo.InviteCount)
        self._Model:SetIsGetShareReward(data.HoldRegressionData.IsGetShareReward)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_RECALL_OPEN_STATUS_UPDATE)
end

function XReCallActivityAgency:OnNotifyHoldRegressionTaskInfo(data)
    self._Model:UpdateTaskData(data.HoldRegressionInviteInfo.TaskInfos)
    self._Model:SetInviteCount(data.HoldRegressionInviteInfo.InviteCount)
    XEventManager.DispatchEvent(XEventId.EVENT_RECALL_TASK_UPDATE)
end

function XReCallActivityAgency:OnNotifyHoldRegressionIgnoreChannel(data)
    self._Model:SetIgnoreChannelIds(data.IgnoreChannelIds)
end

function XReCallActivityAgency:GetReCallTimeId()
    return self._Model:GetCurReCallTimeId()
end

function XReCallActivityAgency:GetReCallIsOpen()
    local timeId = self:GetReCallTimeId()
    if XFunctionManager.CheckInTimeByTimeId(timeId) then
        return true
    end
    return false
end

function XReCallActivityAgency:CheckIsFirstOpen()
    if self:GetReCallIsOpen() then
        return not XSaveTool.GetData(string.format("%d%s", XPlayer.Id, "ReCallAlreadyIn"))
    else
        return false
    end
end

function XReCallActivityAgency:CheckHasReward()
    local taskData = self._Model:GetTaskData()
    for _, task in pairs(taskData) do
        if task and task.Finish and not task.isComplete then
            return true
        end
    end

    return false
end

function XReCallActivityAgency:CheckCanInvite()
    local reCallData = self._Model:GetRecallData()
    if XTool.IsTableEmpty(reCallData) then
        return false
    end
    if not self._Model:GetCurInviteInTime() then
        return false
    end
    if reCallData.IsRegression and reCallData.InviteId and reCallData.InviteId == 0 then
        return true
    end
    return false
end

function XReCallActivityAgency:CheckIsRegressionPlayer()
    local reCallData = self._Model:GetRecallData()
    if XTool.IsTableEmpty(reCallData) then
        return false
    end
    if not self._Model:GetCurInviteInTime() then
        return false
    end
    return reCallData.IsRegression
end

function XReCallActivityAgency:CheckInviteActivityOpen()
    local reCallData = self._Model:GetRecallData()
    if XTool.IsTableEmpty(reCallData) then
        return false
    end
    if not self._Model:GetCurInviteInTime() then
        return false
    end
    
    return true
end

--- 获取该玩家的邀请码
function XReCallActivityAgency:PlayIdToHexUpper()
    --- 保底获取当前Id
    local fixedPlayerId = XPlayer.Id
    
    local reCallData = self._Model:GetRecallData()
    -- 优先使用服务端缓存的Id，兼容迁移导致的PlayerId变化
    if not XTool.IsTableEmpty(reCallData) and XTool.IsNumberValidEx(reCallData.GenId) then
        fixedPlayerId = reCallData.GenId
    end
    
    return string.upper(string.format("HG%08X", fixedPlayerId))
end

--- 邀请码校验
function XReCallActivityAgency:CheckMsgContainsInviteCode(msg)
    if string.IsNilOrEmpty(msg) then
        return false
    end
    
    -- 客户端只校验格式，不与玩家本身的邀请码匹配
    if string.find(msg, "HG%w%w%w%w%w%w%w%w") then
        return true
    end
    
    return false
end

--- 邀请码校验
--- 有明确边界，用于邀请码的使用场景
function XReCallActivityAgency:CheckInviteCodeFormatValid(inviteCode)
    if string.find(inviteCode, "^HG%w%w%w%w%w%w%w%w$") then
        return true
    end
    
    return false
end

--- 检查是否开启邀请码频道
function XReCallActivityAgency:CheckOpenChatChannel()
    if not self:CheckInviteActivityOpen() then
        -- 活动本身未开启
        return false
    end
    
    -- 检查当期活动是否开启频道
    return self._Model:GetCurReCallIsOpenChatChannel() or false
end

--- 检查并拦截在非回归频道发送邀请码
function XReCallActivityAgency:CheckInviteCodeSendInvalidChannel(msg, channelType, notips)
    if not self:CheckOpenChatChannel() then
        return false
    end
    
    -- 检查是否在允许发邀请码的频道
    local curChannelId = XDataCenter.ChatManager.GetCurrentChatChannelId()
    local inviteChannelId = self._Model:GetCurReCallChatChannelId()
    
    -- 频道id，业务这里是在服务端下发的id基础上+1，需要还原回去与配置比较
    curChannelId = curChannelId - 1

    if channelType == ChatChannelType.World and curChannelId == inviteChannelId then
        -- 世界频道的回归子频道是不会禁止的
        return false
    end
    
    local banChannelTypes = self._Model:GetClientConfigReCallNumArray('BanInviteChannelType')

    if not banChannelTypes or not table.contains(banChannelTypes, channelType) then
        -- 不属于配置的禁用频道类型
        return false
    end

    if self:CheckMsgContainsInviteCode(msg) then
        if not notips then
            XUiManager.TipMsg(self._Model:GetClientConfigReCallText('ChatSentInviteInvalidChannelTips'))
        end        
        return true
    end
end

function XReCallActivityAgency:GetCurReCallChatChannelId()
    return self._Model:GetCurReCallChatChannelId()
end

function XReCallActivityAgency:GetClientConfigReCallText(key, index)
    return self._Model:GetClientConfigReCallText(key, index)
end

function XReCallActivityAgency:GetClientConfigReCallNumber(key, index)
    return self._Model:GetClientConfigReCallNumber(key, index)
end

--- 获取回归玩家的任务
---@param refTaskDatas @复用table
function XReCallActivityAgency:GetRegressionTaskDataList(refTaskDatas)
    if self:CheckIsRegressionPlayer() then
        local reCallData = self._Model:GetRecallData()
        
        local cfg = self._Model:GetActivityConfigById(reCallData.ActivityId)

        if cfg then
            if XTool.IsNumberValidEx(cfg.TaskGroupId) then
                return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(cfg.TaskGroupId, false, nil, refTaskDatas)
            end
        end
    end
    
    return refTaskDatas
end

--- 判断任务是否是回归玩家专属任务
--- 仅玩家有开放活动才判断
function XReCallActivityAgency:CheckIsRegressionTaskById(taskId)
    if self:CheckIsRegressionPlayer() then
        local reCallData = self._Model:GetRecallData()

        local cfg = self._Model:GetActivityConfigById(reCallData.ActivityId)

        if cfg and XTool.IsNumberValidEx(cfg.TaskGroupId) then
            local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(cfg.TaskGroupId)

            if taskTimeLimitCfg then
                return table.contains(taskTimeLimitCfg.TaskId, taskId)
            end
        end
    end
    
    return false
end

--- 回归玩家复刷关是否能获得双倍奖励
function XReCallActivityAgency:CheckRegressionPlayerHasMultyRewardTimes(stageId)
    local maxCount, usedCount = 0, 0
    
    
    local cfg = self._Model:GetCurActivityCfg()

    if cfg then
        maxCount = cfg.MultiRewardCount or 0
    end

    local recallData = self._Model:GetRecallData()

    if recallData and not XTool.IsTableEmpty(recallData.MultiRewardInfos) then
        for i, v in pairs(recallData.MultiRewardInfos) do
            if v.StageId == stageId then
                usedCount = v.GetMultiRewardCount
                break
            end
        end
    end
    
    return usedCount < maxCount
end

--region 红点相关

--- 检查回归专属页签是否有点击标记
function XReCallActivityAgency:GetBackOnlyTagIsMark()
    return self._Model:GetBackOnlyTagIsMark()
end

--endregion

return XReCallActivityAgency