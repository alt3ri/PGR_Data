---Control部分类，此处用于发送PVP相关的网络请求
---@type XTheatre6Control
local XTheatre6Control = XClassPartial('XTheatre6Control')

--- 首次进入PVP
function XTheatre6Control:RequestPvpStart(cb)
    -- 已有活动数据则跳过请求
    if self._Model.Pvp:HasActivityData() then
        if cb then cb() end
        return
    end
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PvpStartRequest", nil, function(res)
        self._Model.Pvp:UpdateActivityData(res.ActivityData)
        if cb then
            cb()
        end
    end)
end

--- 更新防守阵容
---@param buffId number|nil 环境效果BuffId
---@param slots XTheatre6PvpFileSlot[]|nil 防守阵容槽位，不传则使用当前本地防守阵容
function XTheatre6Control:RequestPvpUpdateDefense(buffId, slots, cb)
    local req = {
        BuffId = buffId,
        Slots = slots
    }
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PvpUpdateDefenseRequest", req, function(res)
        self._Model.Pvp:UpdateDefenseSlots(buffId, slots)
        if cb then
            cb()
        end
    end)
end

--- 刷新匹配对手
function XTheatre6Control:RequestPvpRefreshMatch(cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PvpRefreshMatchRequest", nil, function(res)
        self._Model.Pvp:UpdateMatchResult(res.MatchResult, res.LastRefreshMatchTime, res.RefreshRemainSeconds)
        if cb then
            cb()
        end
    end)
end

--- 获取PVP体力信息
function XTheatre6Control:RequestPvpGetActionPoint(cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PvpGetActionPointRequest", nil, function(res)
        self._Model.Pvp:UpdateActionPointInfo(res)
        if cb then
            cb()
        end
    end)
end

--- 开始PVP战斗
---@param enemyId number 对手Id
---@param fileSlots XTheatre6PvpFileSlot[] 上阵存档
---@param buffId number|nil 进攻环境效果BuffId
function XTheatre6Control:RequestPvpStartFight(enemyId, fileSlots, buffId, cb)
    local req = {
        EnemyId = enemyId,
        MyFileSlots = fileSlots,
        BuffId = buffId,
    }
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PvpStartFightRequest", req, function(res)
        self._Model.Pvp:UpdateTinyBattleState(res.BattleState)
        self._Model.Pvp:SaveAttackLineupToLocal()
        if cb then
            cb()
        end
    end)
end

--- 玩家退出后重新战斗
function XTheatre6Control:RequestPvpRestartFight(cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PvpRestartFightRequest", nil, function(res)
        if res.BattleState then
            self._Model.Pvp:UpdateTinyBattleState(res.BattleState)
            self._Model.Pvp:RecordBattleResults(res.BattleState.RoundResults)
        end
        if cb then
            cb(res.FightResult)
        end
    end)
end

--- 查询PVP积分总榜
function XTheatre6Control:RequestPvpQueryRank(cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PvpQueryRankRequest", nil, function(res)
        self._Model.Pvp:UpdateRankInfo(res)
        if cb then
            cb()
        end
    end)
end

--- 获取PVP战斗记录
function XTheatre6Control:RequestPvpGetBattleRecords(cb)
    XNetwork.CallWithAutoHandleErrorCode("Theatre6PvpGetBattleRecordsRequest", nil, function(res)
        self._Model.Pvp:UpdateBattleRecords(res.BattleRecords)
        if cb then
            cb()
        end
    end)
end

return XTheatre6Control
