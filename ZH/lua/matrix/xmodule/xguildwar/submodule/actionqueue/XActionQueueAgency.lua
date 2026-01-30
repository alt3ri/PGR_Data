--- 公会战行为队列相关的子agency
---@class XActionQueueAgency : XAgency
---@field private _Model XGuildWarModel
local XActionQueueAgency = XClass(XAgency, "XActionQueueAgency")

-- 原逻辑迁移
-- 根据UI类型获取动画播放队列(根据XGuildWarConfig获取UI需要的动画和顺序)
-- PlayType:XGuildWarConfig.GWActionType
local InsertActinGroupList = function(allActinGroupList, actinGroup)
    if actinGroup and next(actinGroup) then
        table.sort(actinGroup, function (a, b)
            return a.ActionId < b.ActionId
        end)
        table.insert(allActinGroupList, actinGroup)
    end
end

-- 原逻辑迁移
-- 根据多个UI类型获取动画播放队列 并按顺序插入
-- PlayTypeList:XGuildWarConfig.GWActionType[]
local MergeActionGroupList = function(GroupList1,GroupList2)
    for index, list in ipairs(GroupList2) do
        table.insert(GroupList1,list)
    end
    --如果有特殊参数 合并特殊参数(合并逻辑有待更新)
    if GroupList2.ExtraParam then
        for key, value in pairs(GroupList2.ExtraParam) do
            GroupList1.ExtraParam[key] = value
        end
    end
end

-- 原逻辑迁移
-- 各行为事件具体执行的逻辑
local DoActionDict = {
    [XGuildWarConfig.GWActionType.MonsterDead] = function(self, actionGroup)--怪物死亡
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_DEAD, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.MonsterBorn] = function(self, actionGroup)--怪物诞生
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_BORN, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.MonsterMove] = function(self, actionGroup)--怪物移动
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_MOVE, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.BaseBeHit] = function(self, actionGroup)--基地受伤
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_BASEHIT, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.NodeDestroyed] = function(self, actionGroup)--节点攻破
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_NODEDESTROY, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.TransferWeakness] = function(self, actionGroup)--交换弱点
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_TRANSFER_WEAKNESS, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.AllGuardNodeDead] = function(self, actionGroup)--守卫死亡
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_ALL_GUARD_NODE_DEAD, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.BaseBeHitByBoss] = function(self, actionGroup)--基地被boss攻击
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_BASE_BE_HIT_BY_BOSS, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.RoundStart] = function(self, actionGroup)--回合开始
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_ROUND_START, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.BossMerge] = function(self, actionGroup)--BOSS合体)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_BOSS_MERGE, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.BossTreatMonster] = function(self, actionGroup)--BOSS治疗怪物
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_BOSS_TREAT_MONSTER, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.MonsterBornTimeChange] = function(self, actionGroup)--前哨怪物出生时间改变
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_MONSTER_BORN_TIME_CHANGE, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.ReinforcementBorn] = function(self, actionGroup)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_BORN, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.ReinforcementMove] = function(self, actionGroup)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_MOVE, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.ReinforcementAttack] = function(self, actionGroup)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_ATTACK, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.ReinforcementDead] = function(self, actionGroup)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_REINFORCEMENTS_DEAD, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.DragonRageEmpty] = function(self, actionGroup)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_EMPTY, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.DragonRageFull] = function(self, actionGroup)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_FULL, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.NodeChangeToRelic] = function(self, actionGroup)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_CHANGE_RELIC, actionGroup)
    end,

    [XGuildWarConfig.GWActionType.NewGameThrough] = function(self, actionGroup)
        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTION_DRAGON_RAGE_NEW_GAMETHROUH, actionGroup)
    end,
}

function XActionQueueAgency:OnInit()

end

function XActionQueueAgency:OnRelease()

end

--region set

--- 全量下发，一般是活动数据整体请求或登录下推
function XActionQueueAgency:UpdateFullActionList(actionList)
    self:ActionListFilter(actionList)
    self._Model.ActionQueueModel:UpdateFullActionList(actionList)
end

--- 实时下发行为列表
--- 一般进度推进为增量，新周目实时下推为全量
---@param isFull @是否全量，针对全量需要对历史行为保底处理
function XActionQueueAgency:AddActionListRealTime(actionList, isFull)
    self:ActionListFilter(actionList)
    
    -- 入列
    self._Model.ActionQueueModel:UpdateAdditionalActionList(actionList)

    if isFull then
        -- action本体可能在第一阶段过滤没有过滤干净，需要根据第二阶段的规则筛一遍，防止接下来的数据覆盖出现旧数据
        if not XTool.IsTableEmpty(actionList) then
            for i = #actionList, 1, -1 do
                if self:CheckActionIsShowed(actionList[i]) then
                    table.remove(actionList, i)
                end
            end
        end
    end

    -- 立刻覆盖行为携带的额外数据、同步UI表现
    local battleMng = XDataCenter.GuildWarManager.GetBattleManager()

    if battleMng then
        battleMng:UpdateActionData(actionList)
    end
end

--- 设置动作是否是历史的（该接口暂留agency供非XUiNode类型的界面对象访问）
function XActionQueueAgency:SetIsHistoryAction(isHistory)
    self._Model.ActionQueueModel:SetIsHistoryAction(isHistory)
end

--- 更新已经播放完毕动画的ID字典
function XActionQueueAgency:UpdateShowedActionIdDic(idList)
    self._Model.ActionQueueModel:UpdateShowedActionIdDic(idList)
end

function XActionQueueAgency:ResetShowedActionIdDic(idList)
    self._Model.ActionQueueModel:ResetShowedActionIdDic(idList)
end
--endregion

--region get

function XActionQueueAgency:GetIsActionInZoom()
    return self._Model.ActionQueueModel:GetIsActionInZoom()
end

function XActionQueueAgency:GetIsWaitingActionCallback()
    return self._Model.ActionQueueModel:GetIsWaitingActionCallback()
end

function XActionQueueAgency:CheckActionIsShowed(id)
    return self._Model.ActionQueueModel:GetActionIsShowed(id)
end

function XActionQueueAgency:CheckActionPlaying()
    return self._Model.ActionQueueModel:GetIsActionPlaying()
end

function XActionQueueAgency:CheckIsCanGuide()
    return (not self:GetIsWaitingActionCallback()) and (not self:CheckActionPlaying())
end

--todo 后续UI改造后可迁移至control
--- 获取行动动画队列是否还有动画没有播放
function XActionQueueAgency:GetIsHasCanPlayAction(playTypeList)
    local getTypeHashSet = function(PlayType)
        local playTypeActionConfig = XGuildWarConfig.GWPlayType2Action[PlayType] or {}
        local hashSet = {}
        for index,actionType in ipairs(playTypeActionConfig) do
            hashSet[actionType] = true
        end
        return hashSet
    end
    local typeHashSetList = {}
    for index, playType in ipairs(playTypeList) do
        table.insert(typeHashSetList,getTypeHashSet(playType))
    end
    
    local actionList = self._Model.ActionQueueModel:GetWaittingActionList()
    
    for _,action in pairs(actionList or {}) do
        for index, hashSet in ipairs(typeHashSetList) do
            if hashSet[action.ActionType] and (not self._Model.ActionQueueModel:GetActionIsShowed(action.ActionId)) then
                return true
            end
        end
    end
    return false
end
--endregion

-- 检查某UI的行动动画列表 并播放行动动画 动画播放队列根据XGuildWarConfig获取UI需要的动画和顺序
-- PlayTypeList:XGuildWarConfig.GWPlayType2Action[]
function XActionQueueAgency:CheckActionList(PlayTypeList)
    if not self._Model.ActionQueueModel:GetIsActionPlaying() then
        local firstIndex = 1
        local actionGroupList = self:GetUisActionGroupList(PlayTypeList)
        local actionGroup = actionGroupList[firstIndex]
        XLog.Warning("CheckActionList:",actionGroupList)
        if actionGroup and next(actionGroup) then
            local actionIdList = {}
            for _,action in pairs(actionGroup) do
                table.insert(actionIdList, action.ActionId)
            end
            local callback =  function (success)
                self._Model.ActionQueueModel:SetIsWaitingActionCallback(false)

                if not success then
                    return
                end
                
                local type = actionGroup[1].ActionType
                self._Model.ActionQueueModel:MarkPlayingAction(type)
                self._Model.ActionQueueModel:UpdateShowedActionIdDic(actionIdList)
                if DoActionDict[type] then
                    --当前动画行列允许缩放，且需要缩放，并且没在缩放时，执行缩放动画逻辑。
                    if actionGroupList.UiParam.CanZoom and self._Model.ActionQueueModel:GetActionGroupNeedZoom(actionGroup) and not self:GetIsActionInZoom() then
                        XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_OPEN_MOVIEMODE,function ()
                            DoActionDict[type](self, actionGroup)
                        end, actionGroup)
                        
                        self._Model.ActionQueueModel:SetIsActionInZoom(true)
                    else
                        DoActionDict[type](self, actionGroup)
                    end
                end
            end
            
            self._Model.ActionQueueModel:SetIsWaitingActionCallback(true)

            -- debug 不请求, 如此就可以不停播放
            --XScheduleManager.ScheduleOnce(callback, 0)
            XDataCenter.GuildWarManager.RequestPopupActionID(actionIdList, callback)
        else
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_ACTIONLIST_OVER)
            XEventManager.DispatchEvent(XEventId.EVENT_GUILDWAR_CLOSE_MOVIEMODE)
            self._Model.ActionQueueModel:SetIsHistoryAction(false)
            self._Model.ActionQueueModel:SetIsActionInZoom(false)
        end
    end
end

--todo 后续UI改造后可迁移至control
-- 行动动画播放完毕时调用(UI调用)
-- PlayTypeList:XGuildWarConfig.GWActionType[]
function XActionQueueAgency:DoActionFinish(actionType,PlayTypeList)
    self._Model.ActionQueueModel:ClearPlayingActionMark(actionType)
    self:CheckActionList(PlayTypeList)
end

--- 获取单个类型的动画组（原逻辑迁移）
function XActionQueueAgency:GetUiActionGroupList(playType)
    local resultActionList = {}
    local playTypeActionConfig = XGuildWarConfig.GWPlayType2Action[playType] or {}
    local playType2Sequence = {}
    for index,actionType in ipairs(playTypeActionConfig) do
        playType2Sequence[actionType] = index
    end
    local newTurnActionGourpList = function()
        local gourp = {}
        for index,actionType in ipairs(playTypeActionConfig) do
            gourp[index] = {}
        end
        return gourp
    end
    local tempActionGourpByTurn = {}
    local allTurn = 1
    tempActionGourpByTurn[allTurn] = newTurnActionGourpList()
    
    local actionList = self._Model.ActionQueueModel:GetWaittingActionList()

    if not XTool.IsTableEmpty(actionList) then
        for _,action in pairs(actionList) do
            if not self._Model.ActionQueueModel:GetActionIsShowed(action.ActionId) then
                local index = playType2Sequence[action.ActionType]
                if index then
                    table.insert(tempActionGourpByTurn[allTurn][index], action)
                    goto continue
                end
            end
            if action.ActionType == XGuildWarConfig.GWActionType.NextTurn then
                allTurn = allTurn + 1
                tempActionGourpByTurn[allTurn] = newTurnActionGourpList()
            end
            ::continue::
        end
    end

    for turn = 1, allTurn do
        local Gourp = tempActionGourpByTurn[turn]
        for index, list in ipairs(Gourp) do
            InsertActinGroupList(resultActionList, list)
        end
    end
    resultActionList.ExtraParam = playTypeActionConfig.ExtraParam
    return resultActionList
end

--- 获取指定多个类型的
function XActionQueueAgency:GetUisActionGroupList(playTypeList)
    local resultActionList = {}
    resultActionList.ExtraParam = {}
    resultActionList.UiParam = playTypeList.UiParam or {}
    for index, playType in ipairs(playTypeList) do
        local actionList = self:GetUiActionGroupList(playType)
        MergeActionGroupList(resultActionList, actionList)
    end
    return resultActionList
end

-- 逻辑迁移
function XActionQueueAgency:ActionListFilter(actionList)
    if not XTool.IsTableEmpty(actionList) then
        -- 援军的行动只播最新的，需要把旧的过滤掉
        local actionMap = {} -- key: actionType, value: turnIndex
        local turnIndex = 0
        local needToMarkPlayed = {}

        for i = #actionList, 1, -1 do
            local action = actionList[i]

            if action.ActionType == XGuildWarConfig.GWActionType.NextTurn then
                turnIndex = turnIndex + 1
            elseif action.ActionType >= XGuildWarConfig.GWActionType.ReinforcementBorn and action.ActionType <= XGuildWarConfig.GWActionType.ReinforcementDead then
                if actionMap[action.ActionType] ~= nil then
                    if turnIndex ~= actionMap[action.ActionType] then
                        local removedAction = table.remove(actionList, i)
                        table.insert(needToMarkPlayed, removedAction.ActionId)
                    end
                else
                    actionMap[action.ActionType] = turnIndex
                end
            end
        end

        -- 过滤掉的action需要请求为已播放，防止下次登录再次被下发下来
        if not XTool.IsTableEmpty(needToMarkPlayed) then
            -- 不在回调里缓存，这是因为可能还没等到回调就有其他协议发送同id的行为下来，导致错误的重复执行
            self:UpdateShowedActionIdDic(needToMarkPlayed)
            XDataCenter.GuildWarManager.RequestPopupActionID(needToMarkPlayed, function(success)
                if not success then
                    self:ResetShowedActionIdDic(needToMarkPlayed)
                end
            end)
        end
    end

    --- 龙怒系统玩法action过滤逻辑
    if self._MainAgency.DragonRageCom:IsOpenDragonRageSystem() then
        -- 找到最新的周目action
        local lastNewGameActionId = self._MainAgency.DragonRageCom:GetCurLatestNewGameActionId()
        local newGameActionId = 0

        for i = #actionList, 1, -1 do
            local action = actionList[i]
            if action.ActionType == XGuildWarConfig.GWActionType.NewGameThrough then
                if not XTool.IsNumberValid(lastNewGameActionId) or action.ActionId > lastNewGameActionId then
                    if action.ActionId > newGameActionId then
                        newGameActionId = action.ActionId
                    end
                end
            end
        end

        if XTool.IsNumberValid(newGameActionId) and not self:CheckActionIsShowed(newGameActionId) then
            self._MainAgency.DragonRageCom:SetCurLatestNewGameActionId(newGameActionId)
            self._MainAgency.DragonRageCom:SetIsNewGameThroughActionWaitToPlay(true)
            local needToMarkPlayed = {}
            -- 移除所有比最新周目action的Id还小的action
            for i = #actionList, 1, -1 do
                local action = actionList[i]
                if action.ActionId < newGameActionId then
                    local removedAction = table.remove(actionList, i)
                    table.insert(needToMarkPlayed, removedAction.ActionId)
                end
            end

            -- 过滤掉的action需要请求为已播放，防止下次登录再次被下发下来
            if not XTool.IsTableEmpty(needToMarkPlayed) then
                -- 不在回调里缓存，这是因为可能还没等到回调就有其他协议发送同id的行为下来，导致错误的重复执行
                self:UpdateShowedActionIdDic(needToMarkPlayed)

                XDataCenter.GuildWarManager.RequestPopupActionID(needToMarkPlayed, function(success)
                    if not success then
                        self:ResetShowedActionIdDic(needToMarkPlayed)
                    end
                end)
            end
        end
    end
end

return XActionQueueAgency