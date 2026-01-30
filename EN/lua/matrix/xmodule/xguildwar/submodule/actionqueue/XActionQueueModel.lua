--- 公会战行为队列数据的子model
---@class XActionQueueModel: XModel
local XActionQueueModel = XClass(XModel, "XActionQueueModel")

function XActionQueueModel:OnInit()
    -- 已播放完毕的actionId字典
    self._ShowedActionIdDic = nil
    -- 最新播完的actionId：actionId是顺延的流水Id
    self._LatestShowedActionId = 0

    self._ActionWaittingList = nil  -- 待播放的行为列表
    self._ActionIdMap = nil     -- 行为Id集合，用于去重
    self._ActionZoomDic = nil   -- 需要缩放镜头进行表现的行为Id集合

    -- 行动动画是否是历史动画
    self._IsHistoryAction = false
    
    self._IsActionPlayingDic = nil  -- 正在播放的行为类型集合
    self._IsActionInZoom = false     -- 行动动画是否缩放
    self._IsWaitingActionCallback = false    -- 等待动画播放请求
end

function XActionQueueModel:ClearPrivate()
    --- 退出公会战界面时, 清空正在播放动画的缓存标记, 防止出现错误缓存时登录状态卡流程
    self._IsActionPlayingDic = nil
    self._IsActionInZoom = false
    self._IsWaitingActionCallback = false
end

function XActionQueueModel:ResetAll()
    self._ShowedActionIdDic = nil
    self._LatestShowedActionId = 0

    self._ActionWaittingList = nil
    self._ActionIdMap = nil
    self._ActionZoomDic = nil
    
    self._IsHistoryAction = false
end

--region set

--- 活动数据整体下推时全量更新活动的action（包括历史action）
function XActionQueueModel:UpdateFullActionList(actionList)
    -- 只留下未播放的部分
    self._ActionWaittingList = {}
    self._ActionIdMap = {}
    self._ActionZoomDic = {}

    if not XTool.IsTableEmpty(actionList) then
        for i, v in pairs(actionList) do
            if v.ActionId > self._LatestShowedActionId and not self._ActionIdMap[v.ActionId] then
                table.insert(self._ActionWaittingList, v)
                self._ActionIdMap[v.ActionId] = true
                self._ActionZoomDic[v.ActionId] = true
            end
        end
    end
end

--- 实时增量更新活动的action（不包括历史action)
function XActionQueueModel:UpdateAdditionalActionList(actionList)
    -- 常规入列
    if not XTool.IsTableEmpty(actionList) then
        for i, v in pairs(actionList) do
            if v.ActionId > self._LatestShowedActionId and not self._ActionIdMap[v.ActionId] then
                table.insert(self._ActionWaittingList, v)
                self._ActionIdMap[v.ActionId] = true

                v.IsRealTime = true
            end
        end
    end

    -- 针对特殊的action类型需要设置到缩放缓存中
    for i, v in pairs(actionList) do
        if v.ActionType == XGuildWarConfig.GWActionType.DragonRageFull then
            self._ActionZoomDic[v.ActionId] = true
        end
    end
end

--- 更新已经播放完毕动画的ID字典
function XActionQueueModel:UpdateShowedActionIdDic(idList)
    if not XTool.IsTableEmpty(idList) then
        if self._ShowedActionIdDic == nil then
            self._ShowedActionIdDic = {}
        end

        for _,id in pairs(idList) do
            self._ShowedActionIdDic[id] = true
            
            -- 记录已播放行为的最新id，以便新增或全量下发时剔除过时action
            if id > self._LatestShowedActionId then
                self._LatestShowedActionId = id
            end
        end
    end
end

--- 取消动画Id标记缓存（用于请求失败时复原
function XActionQueueModel:ResetShowedActionIdDic(idList)
    if not XTool.IsTableEmpty(idList) then
        if self._ShowedActionIdDic == nil then
            return
        end

        for _,id in pairs(idList) do
            self._ShowedActionIdDic[id] = nil

            -- 记录已播放行为的最新id，以便新增或全量下发时剔除过时action
            if id < self._LatestShowedActionId then
                self._LatestShowedActionId = id
            end
        end
    end
end

--设置历史动作动画
function XActionQueueModel:SetIsHistoryAction(IsHistory)
    self._IsHistoryAction = IsHistory
end

function XActionQueueModel:ClearPlayingActionMark(actionType)
    if self._IsActionPlayingDic then
        self._IsActionPlayingDic[actionType] = nil
    end
end

function XActionQueueModel:MarkPlayingAction(actionType)
    if self._IsActionPlayingDic == nil then
        self._IsActionPlayingDic = {}
    end

    self._IsActionPlayingDic[actionType] = true
end

function XActionQueueModel:SetIsActionInZoom(isInZoom)
    self._IsActionInZoom = isInZoom
end

function XActionQueueModel:SetIsWaitingActionCallback(isWaittingCb)
    self._IsWaitingActionCallback = isWaittingCb
end

--endregion

--region get

function XActionQueueModel:GetWaittingActionList()
    return self._ActionWaittingList
end

--- 检查某个动画是否已经播放
function XActionQueueModel:GetActionIsShowed(id)
    return self._ShowedActionIdDic and self._ShowedActionIdDic[id] or false
end

--- 检查是否历史动作动画
function XActionQueueModel:GetIsHistoryAction()
    return self._IsHistoryAction
end

function XActionQueueModel:GetIsActionInZoom()
    return self._IsActionInZoom
end

function XActionQueueModel:GetIsWaitingActionCallback()
    return self._IsWaitingActionCallback or false
end

--- 检查动作动画需不需要定位缩放操作
function XActionQueueModel:GetActionGroupNeedZoom(actionGroup)
    if XTool.IsTableEmpty(self._ActionZoomDic) then
        return false
    end

    if not XTool.IsTableEmpty(actionGroup) then
        for _,action in pairs(actionGroup) do
            if self._ActionZoomDic[action.ActionId] then
                return true
            end
        end
    end
    
    return false
end

--- 检查是否正在播放动画
function XActionQueueModel:GetIsActionPlaying()
    if XTool.IsTableEmpty(self._IsActionPlayingDic) then
        return false
    end
    
    for _,playing in pairs(self._IsActionPlayingDic) do
        if playing then
            return true
        end
    end
    return false
end
--endregion

return XActionQueueModel