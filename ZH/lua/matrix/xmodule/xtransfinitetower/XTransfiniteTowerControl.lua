---@class XTransfiniteTowerControl : XControl
---@field private _Model XTransfiniteTowerModel
local XTransfiniteTowerControl = XClass(XControl, "XTransfiniteTowerControl", true)
-- 配置查询部分类
XClassPartialRequire("XModule/XTransfiniteTower/ControlPartial/XTransfiniteTowerControlConfig", "XTransfiniteTowerControl")

-- 作战准备按钮状态
XTransfiniteTowerControl.BattlePrepareState = {
    Normal = 1,       -- 作战准备：即将挑战的下一层（亮起）
    PrevNotPass = 2,  -- 上层未通关：更后面的层（置灰）
    Completed = 3,    -- 作战完成：通关链中间的层（置灰）
    Rechallenge = 4,  -- 重新挑战：通关链的最后一层（亮起）
    NeedReset = 5,    -- 上轮记录未清（置灰，点击提示先重置进度）
}

-- 解锁时间文案的日期格式（不含年，避免按钮文本过长）
local TIME_FORMAT_UNLOCK = "MM/dd HH:mm"

-- 排行榜拉取节流间隔（秒）：主页/排行页频繁开关时避免重复请求
local RANK_FETCH_INTERVAL = 60

-- 队伍位数
local TEAM_POS_COUNT = 3

-- 空成员槽占位数据，调用方只读；数据源接入后由真实数据替代
local EmptyMemberSlot = {
    IsEmpty = true,
    SlotType = 0,
    IsPilot = false,
    EnergyPoint = 0,
    FightId = 0,
}

-- 成员槽结果表复用体，避免塔层项滚动时反复建表；调用方同步读完即弃
local MemberSlotResult = {
    IsEmpty = false,
    SlotType = 0,
    IsPilot = false,
    EnergyPoint = 0,
    FightId = 0,
}

function XTransfiniteTowerControl:OnInit()
    self:InitConfig()
end

function XTransfiniteTowerControl:AddAgencyEvent()
    -- Control 生命周期启动时注册事件
end

function XTransfiniteTowerControl:RemoveAgencyEvent()

end

function XTransfiniteTowerControl:OnRelease()
    self._Model = false
end

--region 活动主界面（UiTransfiniteTowerMain）
-- 数据来源（配表/服务端）未就绪，以下接口先返回空值/默认态，接入后在此填充。

---主界面四座塔入口对应的塔配置id（按入口展示顺序）
---@return number[]
function XTransfiniteTowerControl:GetMainTowerCfgIds()
    -- 遍历 Activity 表找当前开放中的，取其 ChapterIds
    local _, activityId = self:GetAgency():GetOpenActivityTimeId()
    if not activityId then return table.empty end
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.ChapterIds or table.empty
end

---塔入口名称
---@return string
function XTransfiniteTowerControl:GetTowerEntranceName(towerCfgId)
    local cfg = self:GetChapterCfg(towerCfgId)
    return cfg and cfg.Name or ""
end

---塔入口通关进度文本（X/Y：本轮已通关层/总层数）
---@return string
function XTransfiniteTowerControl:GetTowerProgressText(towerCfgId)
    local progress = self._Model:GetStageProgressIndex(towerCfgId)
    if progress <= 0 then
        local lastRecords = self._Model:GetLastStageRecordList(towerCfgId)
        progress = lastRecords and #lastRecords or 0
    end
    local total = #self:GetTowerStageCfgIds(towerCfgId)
    return progress .. "/" .. total
end

---塔入口是否解锁（解锁时间 + 前置条件都满足；未配的项视为通过）
---@return boolean
function XTransfiniteTowerControl:IsTowerEntranceUnlock(towerCfgId)
    local cfg = self:GetChapterCfg(towerCfgId)
    if not cfg then return false end
    if XTool.IsNumberValid(cfg.UnLockTimeId) and not XFunctionManager.CheckInTimeByTimeId(cfg.UnLockTimeId) then
        return false
    end
    local isPass = XConditionManager.CheckConditionAndDefaultPass(cfg.ConditionId)
    return isPass
end

---塔入口未解锁的原因提示（时间未到 / 前置条件不满足，条件描述由条件表给）
---@return string
function XTransfiniteTowerControl:GetTowerLockedTip(towerCfgId)
    local cfg = self:GetChapterCfg(towerCfgId)
    if not cfg then return "" end
    if XTool.IsNumberValid(cfg.UnLockTimeId) and not XFunctionManager.CheckInTimeByTimeId(cfg.UnLockTimeId) then
        return XUiHelper.GetText("TransfiniteTowerTowerLockedTip")
    end
    local _, desc = XConditionManager.CheckConditionAndDefaultPass(cfg.ConditionId)
    return desc or ""
end

---塔入口未解锁时的解锁时间文案；已解锁或未配时间返回空串
---@return string
function XTransfiniteTowerControl:GetTowerUnlockTimeText(towerCfgId)
    if self:IsTowerEntranceUnlock(towerCfgId) then return "" end
    local cfg = self:GetChapterCfg(towerCfgId)
    if not cfg or not XTool.IsNumberValid(cfg.UnLockTimeId) then return "" end

    local now = XTime.GetServerNowTimestamp()
    local startTime = XFunctionManager.GetStartTimeByTimeId(cfg.UnLockTimeId) or 0
    local endTime = XFunctionManager.GetEndTimeByTimeId(cfg.UnLockTimeId) or 0

    -- 已过结束时间：活动关闭
    if endTime > 0 and now > endTime then
        return XUiHelper.GetText("TransfiniteTowerTowerClosed")
    end
    -- 时间已到开放期内，卡在前置条件
    if startTime > 0 and now >= startTime then
        return XUiHelper.GetText("TransfiniteTowerTowerLockConditionNotMatch")
    end
    if startTime <= 0 then return "" end
    -- 未到开放时间
    return XUiHelper.GetText("TransfiniteTowerTowerUnlockTime", XTime.TimestampToGameDateTimeString(startTime, TIME_FORMAT_UNLOCK))
end

---塔的解锁开始时间戳；未配时间返回 0
---@return number
function XTransfiniteTowerControl:GetTowerUnlockStartTime(towerCfgId)
    local cfg = self:GetChapterCfg(towerCfgId)
    if not cfg or not XTool.IsNumberValid(cfg.UnLockTimeId) then return 0 end
    return XFunctionManager.GetStartTimeByTimeId(cfg.UnLockTimeId) or 0
end

---塔的结束时间
---@return number
function XTransfiniteTowerControl:GetTowerUnlockEndTime(towerCfgId)
    local cfg = self:GetChapterCfg(towerCfgId)
    if not cfg or not XTool.IsNumberValid(cfg.UnLockTimeId) then return 0 end
    return XFunctionManager.GetEndTimeByTimeId(cfg.UnLockTimeId) or 0
end

---塔是否已关闭
---@return boolean
function XTransfiniteTowerControl:IsTowerClosed(towerCfgId)
    local endTime = self:GetTowerUnlockEndTime(towerCfgId)
    return endTime > 0 and endTime < XTime.GetServerNowTimestamp()
end

---塔入口是否已通关（历史最大通关层达到总层数，显示通关标记）
---@return boolean
function XTransfiniteTowerControl:IsTowerEntranceComplete(towerCfgId)
    local totalCount = #self:GetTowerStageCfgIds(towerCfgId)
    if totalCount <= 0 then return false end
    return self._Model:GetMaxPassedOrder(towerCfgId) >= totalCount
end

---本轮爬塔是否已通关最后一层
---@return boolean
function XTransfiniteTowerControl:IsCurrentRunCompleted(towerCfgId)
    local totalCount = #self:GetTowerStageCfgIds(towerCfgId)
    if totalCount <= 0 then return false end
    return self._Model:GetStageProgressIndex(towerCfgId) >= totalCount
end

---排行榜是否解锁
---@return boolean, string
function XTransfiniteTowerControl:IsRankUnlock()
    local chapterId = self:GetRankChapterId()
    if not chapterId then return false, "" end
    local cfg = self:GetChapterCfg(chapterId)
    if not cfg then return false, "" end
    local endTime = self:GetTowerUnlockEndTime(chapterId)
    if endTime > 0 and endTime < XTime.GetServerNowTimestamp() then
        return false, XUiHelper.GetText("TransfiniteTowerRankCloseTip")
    end
    if XTool.IsNumberValid(cfg.UnLockTimeId) and not XFunctionManager.CheckInTimeByTimeId(cfg.UnLockTimeId) then
        local startTime = self:GetTowerUnlockStartTime(chapterId)
        if startTime <= 0 then return false, "" end
        return false, XUiHelper.GetText("TransfiniteTowerRankUnlockTip", XTime.TimestampToGameDateTimeString(startTime, TIME_FORMAT_UNLOCK))
    end
    if not XConditionManager.CheckConditionAndDefaultPass(cfg.ConditionId) then
        return false, XUiHelper.GetText("TransfiniteTowerRankUnlockCondition")
    end
    return true, ""
end

---进入指定塔（打开选关界面）
function XTransfiniteTowerControl:OpenTower(towerCfgId)
    XLuaUiManager.Open("UiTransfiniteTowerStage", towerCfgId)
end

---打开任务界面
function XTransfiniteTowerControl:OpenTaskUi()
    XLuaUiManager.Open("UiTransfiniteTowerTask")
end

---打开排行榜界面
function XTransfiniteTowerControl:OpenRankUi()
    XLuaUiManager.Open("UiTransfiniteTowerRank")
end

---拉取排行榜并写入缓存
function XTransfiniteTowerControl:RefreshRankCache()
    local now = XTime.GetServerNowTimestamp()
    if self._LastRankFetchTime and now - self._LastRankFetchTime < RANK_FETCH_INTERVAL then
        return
    end
    local chapterId = self:GetRankChapterId()
    if not chapterId then return end
    self:RequestGetRank(chapterId, function(res)
        self._LastRankFetchTime = XTime.GetServerNowTimestamp()
        local rankList = {}
        if res.RankList then
            self._Model:SetRankShowList(res.RankList)
            local myRankInfo = self._Model:GetRankInfo(chapterId)
            for _, show in ipairs(res.RankList) do
                local mvpFightId = show.MvpFightId
                if show.Id == XPlayer.Id and myRankInfo then
                    mvpFightId = myRankInfo.MvpFightId
                end
                rankList[#rankList + 1] = {
                    PlayerId = show.Id,
                    TowerCfgId = chapterId,
                    Name = show.Name,
                    Head = show.HeadPortraitId,
                    Frame = show.HeadFrameId or 0,
                    Rank = show.RankNum,
                    Stage = show.MaxOrder,
                    UseTime = show.TotalSpendTime,
                    TotalPower = show.TotalPower,
                    MvpFightId = mvpFightId,
                }
            end
        end
        self._Model:SetRankCacheData({
            reward = self:GetRankRewardPreview(chapterId),
            rankList = rankList,
            myRankData = self:BuildMyRankData(chapterId, res.Rank, res.TotalCount),
            lastRankTotalSpendTime = res.LastRankTotalSpendTime or 0,
        })
        XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_TOWER_RANK_UPDATE)
    end)
end

---取排行榜缓存展示数据
---@return table|nil { reward, rankList, myRankData, lastRankTotalSpendTime }
function XTransfiniteTowerControl:GetRankCacheData()
    return self._Model:GetRankCacheData()
end

---自己的排名条数据
---@param rank number 响应里的名次，0=未上榜
---@param totalCount number 响应里的榜单总人数，排名超 1000 时用于显示百分比
---@return table|nil 未上榜返回 nil，调用方据此隐藏排名条
function XTransfiniteTowerControl:BuildMyRankData(chapterId, rank, totalCount)
    if not XTool.IsNumberValid(rank) then return end
    local rankInfo = self._Model:GetRankInfo(chapterId)
    if not rankInfo then return end
    return {
        PlayerId = XPlayer.Id,
        TowerCfgId = chapterId,
        Name = XPlayer.Name,
        Head = XPlayer.CurrHeadPortraitId,
        Frame = XPlayer.CurrHeadFrameId,
        Rank = rank,
        TotalCount = totalCount,
        Stage = rankInfo.MaxOrder,
        UseTime = rankInfo.TotalSpendTime,
        TotalPower = rankInfo.TotalPower,
        MvpFightId = rankInfo.MvpFightId,
    }
end

---排行奖励预览（榜单顶部 Grid256New 展示，取排行塔 RankRewardIds 第一项的首个奖励）
---@return table
function XTransfiniteTowerControl:GetRankRewardPreview(chapterId)
    local chapter = self:GetChapterCfg(chapterId)
    if not chapter or XTool.IsTableEmpty(chapter.RankRewardIds) then return end
    local rewards = XRewardManager.GetRewardList(chapter.RankRewardIds[1])
    return rewards and rewards[1]
end

---取排行章节塔 Id（Chapter 表中第一个配了 IsRank 的塔）
---@return number
function XTransfiniteTowerControl:GetRankChapterId()
    return self:GetAgency():GetRankChapterId()
end

---距离榜单下次刷新的剩余时间（秒），按 Config 表 RankRefreshTime 的每日刷新点算
---@return number
function XTransfiniteTowerControl:GetRankRemainTime()
    if not self._RankRefreshOclock then
        self._RankRefreshOclock = 0
        local cfg = self:GetConfigByKey("RankRefreshTime")
        local timeStr = cfg and cfg.Values and cfg.Values[1]
        if not string.IsNilOrEmpty(timeStr) then
            local hour, minute, second = string.match(timeStr, "(%d+):(%d+):(%d+)")
            if hour then
                -- GetServerLeftTimeToTargetTime 的入参是小时(可带小数)
                self._RankRefreshOclock = tonumber(hour) + tonumber(minute) / 60 + tonumber(second) / 3600
            end
        end
    end
    if self._RankRefreshOclock <= 0 then return 0 end
    local remain = XTime.GetServerLeftTimeToTargetTime(self._RankRefreshOclock)
    return remain > 0 and remain or 0
end

--endregion

--region 塔层选关（UiTransfiniteTowerStage）
-- 数据来源（配表/服务端）未就绪，以下接口先返回空值/默认态，接入后在此填充。

---本塔的关卡配置id列表（爬层顺序）
---@return number[]
function XTransfiniteTowerControl:GetTowerStageCfgIds(towerCfgId)
    local cache = self._TowerStageListCache and self._TowerStageListCache[towerCfgId]
    if cache then
        return cache
    end
    local chapter = self:GetChapterCfg(towerCfgId)
    if not chapter or not chapter.StageGroupId then
        return table.empty
    end
    local list = {}
    for _, stage in ipairs(self:GetStagesByGroupId(chapter.StageGroupId)) do
        list[#list + 1] = stage.Id
    end
    self._TowerStageListCache = self._TowerStageListCache or {}
    self._TowerStageListCache[towerCfgId] = list
    return list
end

---是否显示底部最终层（8/15 层塔显示，3 层教学塔不显示）
---@return boolean
function XTransfiniteTowerControl:IsShowBossGrid(towerCfgId)
    local chapter = self:GetChapterCfg(towerCfgId)
    return chapter ~= nil and chapter.Type ~= 1
end

---最终层关卡配置id
---@return number
function XTransfiniteTowerControl:GetTowerBossStageCfgId(towerCfgId)
    local list = self._TowerStageListCache and self._TowerStageListCache[towerCfgId]
    if not list then
        list = self:GetTowerStageCfgIds(towerCfgId)
    end
    return list and list[#list] or 0
end

---标题「XX之塔—YY」（YY 为选中层序号）
---@return string
function XTransfiniteTowerControl:GetTowerTitle(towerCfgId, selectedStageCfgId)
    local chapter = self:GetChapterCfg(towerCfgId)
    if not chapter then return "" end
    local stage = self:GetStageCfg(selectedStageCfgId)
    local order = stage and stage.Order or 0
    return chapter.Name .. "—" .. order
end

---选中层的怪物模型名（Stage.Model）；未配返回 nil
---@return string|nil
function XTransfiniteTowerControl:GetStageModelName(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    if not stage or string.IsNilOrEmpty(stage.Model) then return end
    return stage.Model
end

---副标题（跟随选中层，取 Stage.SubTitle）
---@param stageCfgId number 选中层
---@return string
function XTransfiniteTowerControl:GetTowerSubTitle(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    return stage and stage.SubTitle or ""
end

---是否为教学塔（3 层教学塔，Chapter.Type==1）
---@return boolean
function XTransfiniteTowerControl:IsTeachTower(towerCfgId)
    return self:GetAgency():IsTeachTower(towerCfgId)
end

---是否为末位结算塔（15 层塔走 LastSettlement，其余走 SettlementPopup）
---@return boolean
function XTransfiniteTowerControl:IsLastSettleTower(towerCfgId)
    return self:GetAgency():IsLastSettleTower(towerCfgId)
end

---本塔本轮已通关层数
---@return number
function XTransfiniteTowerControl:GetTowerPassedCount(towerCfgId)
    return self._Model:GetStageProgressIndex(towerCfgId)
end

---选中层的词缀详情列表（每项含 Icon/Name/Desc）
---@return table[]
function XTransfiniteTowerControl:GetStageTraitList(stageCfgId)
    return self:GetAgency():GetStageTraitList(stageCfgId)
end

---选中层的上阵要求提示（与编队界面同源）；无要求返回 nil
---@return string
function XTransfiniteTowerControl:GetStageFormationTip(stageCfgId)
    return self:GetAgency():GetStageFormationTip(stageCfgId)
end

---是否存在上轮爬塔留存记录（与本轮进度互斥，须先重置进度才能开新一轮）
---教学塔无总结算也就没有留存记录，且界面上没有重置入口，故不参与该判定
---@return boolean
function XTransfiniteTowerControl:HasLastStageRecord(towerCfgId)
    return self._Model:HasLastStageRecord(towerCfgId)
end

---作战准备按钮状态
---以本轮进度 StageProgressIndex 为界：之前的层=作战完成，通关链最后一层=重新挑战，
---下一层=作战准备，再往后=上层未通关。MaxPassedOrder 是跨轮历史值，不能用来判本轮
---@return number BattlePrepareState
function XTransfiniteTowerControl:GetBattlePrepareState(towerCfgId, stageCfgId)
    local state = XTransfiniteTowerControl.BattlePrepareState
    local stage = self:GetStageCfg(stageCfgId)
    if stage and stage.Order == 1
        and self:IsTeachTower(towerCfgId) and self:HasLastStageRecord(towerCfgId) then
        return state.Normal
    end
    -- 上轮记录未清 = 塔已终结，任何层都要先重置进度
    if self:HasLastStageRecord(towerCfgId) then
        return state.NeedReset
    end
    if not stage then return state.Normal end
    local progress = self._Model:GetStageProgressIndex(towerCfgId)
    if stage.Order < progress then
        return state.Completed
    elseif stage.Order == progress then
        return state.Rechallenge
    elseif stage.Order == progress + 1 then
        return state.Normal
    end
    return state.PrevNotPass
end

---是否为回溯层
---@return boolean
function XTransfiniteTowerControl:IsRollbackLayer(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    return stage ~= nil and stage.IsReset == true
end

---回溯按钮是否可用：只有当前生效的那个回溯点能点
---低层回溯点会被后解锁的高层回溯点覆盖
---@return boolean
function XTransfiniteTowerControl:IsRollbackBtnActive(towerCfgId, stageCfgId)
    if self:HasLastStageRecord(towerCfgId) then return false end
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return false end
    return stage.Order == self._Model:GetRollbackOrder(towerCfgId)
end

---回溯不可用时的提示文案（高层回溯点已激活 / 本层尚未通关）
---@return string
function XTransfiniteTowerControl:GetRollbackDisableTip(towerCfgId, stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return "" end
    if self._Model:GetRollbackOrder(towerCfgId) > stage.Order then
        return XUiHelper.GetText("TransfiniteTowerRollbackHigherActive")
    end
    -- 本层未通关，回溯点还没激活
    if stage.Order > self._Model:GetStageProgressIndex(towerCfgId) then
        return XUiHelper.GetText("TransfiniteTowerRollbackNotReached")
    end
    return ""
end

---当前可挑战层的关卡id（定位按钮用）
---@return number
function XTransfiniteTowerControl:GetTopStageCfgId(towerCfgId)
    local list = self:GetTowerStageCfgIds(towerCfgId)
    if XTool.IsTableEmpty(list) then return 0 end
    local progress = self._Model:GetStageProgressIndex(towerCfgId)
    local idx = math.min(progress + 1, #list)
    return list[idx]
end

---重置章节塔：清空上轮留存记录，之后才能开新一轮爬塔
---界面刷新由服务端推 ChapterInfo 后的 EVENT_TRANSFINITE_TOWER_DATA_CHANGE 驱动
function XTransfiniteTowerControl:ResetTowerProgress(towerCfgId)
    self:RequestResetChapter(towerCfgId, function()
        self:GetAgency():ClearKickTipCookie(towerCfgId)
        XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerResetProgressTip"))
    end)
end

---回溯通关记录至记录点（回溯目标层由服务端按当前有效回溯点决定，协议只需 chapterId）
---界面刷新由服务端推 ChapterInfo 后的 EVENT_TRANSFINITE_TOWER_DATA_CHANGE 驱动
function XTransfiniteTowerControl:RollbackToStage(towerCfgId)
    self:RequestRollback(towerCfgId, function()
        XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerRollbackSuccessTip"))
    end)
end

---进入作战准备界面（打开通用编队界面 UiBattleRoleRoom，注入超限启航 Proxy 定制）
---@param lockedTeam XTeam 可选：锁定阵容（重新挑战用，不可换人）
---@param defaultTeam XTeam 可选：默认阵容（可换人；不传则回退到选角快照继承）
function XTransfiniteTowerControl:EnterBattlePrepare(towerCfgId, stageCfgId, lockedTeam, defaultTeam)
    local XUiTransfiniteTowerBattleRoleRoomProxy = require("XUi/XUiTransfiniteTower/BattleRoleRoom/XUiTransfiniteTowerBattleRoleRoomProxy")
    local stageId = self:GetBattleStageId(stageCfgId)
    local team = lockedTeam or defaultTeam or self:CreateTeamByLastSelection(towerCfgId)
    if not team then
        team = XDataCenter.TeamManager.CreateTempTeam({ 0, 0, 0 })
    end
    local proxyArg = {
        TowerCfgId = towerCfgId,
        StageCfgId = stageCfgId,
        IsTeamLocked = lockedTeam ~= nil,
    }
    XMVCA.XFuben:OpenUiBattleRoleRoom(stageId, team, XUiTransfiniteTowerBattleRoleRoomProxy, nil, nil, proxyArg)
end

---队伍快照
---@return XTeam 无快照返回 nil
function XTransfiniteTowerControl:CreateTeamByLastSelection(towerCfgId)
    local selection = self._Model:GetLastTeamSelection(towerCfgId)
    if not selection then return end
    local cardIds = selection.CardIds or table.empty
    local robotIds = selection.RobotIds or table.empty
    -- CardIds 与 RobotIds 同槽位互斥，按位取非 0 的一边
    local entityIds = {}
    local hasEntity = false
    for i = 1, TEAM_POS_COUNT do
        local entityId = (cardIds[i] or 0) > 0 and cardIds[i] or (robotIds[i] or 0)
        entityIds[i] = entityId
        if entityId > 0 then
            hasEntity = true
        end
    end
    if not hasEntity then return end
    local team = XDataCenter.TeamManager.CreateTempTeam(entityIds)
    team:UpdateCaptainPosAndFirstFightPos(selection.CaptainPos or 0, selection.FirstFightPos or 0)
    return team
end

---提前结算：走章节结算，跳转分支与最后一层结算一致
function XTransfiniteTowerControl:EnterEarlySettlement(towerCfgId)
    self:GetAgency():DoChapterSettle(towerCfgId)
end

---重新挑战：进编队界面，但队伍锁定为该层上次的通关阵容，不允许换人
function XTransfiniteTowerControl:RechallengeStage(towerCfgId, stageCfgId)
    self:EnterBattlePrepare(towerCfgId, stageCfgId, self:CreateTeamByStageRecord(towerCfgId, stageCfgId))
end

---用该层通关记录里的阵容建一支临时队伍
---@return XTeam 无记录返回 nil
function XTransfiniteTowerControl:CreateTeamByStageRecord(towerCfgId, stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return end
    local record = self:GetStageRecordTeam(towerCfgId, stage.Order)
    if XTool.IsTableEmpty(record) then return end
    local entityIds = {}
    for i = 1, TEAM_POS_COUNT do
        entityIds[i] = record[i] and record[i].FightId or 0
    end
    return XDataCenter.TeamManager.CreateTempTeam(entityIds)
end

--endregion

--region 塔层项 / 成员槽位（XUiGridTowerStage / XUiGridMemberSlot）

---关卡层序号
---@return string
function XTransfiniteTowerControl:GetStageOrderText(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    return stage and tostring(stage.Order) or ""
end

---关卡怪物立绘
---@return string
function XTransfiniteTowerControl:GetStageBossIcon(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    return stage and stage.ImgBoss or ""
end

---关卡是否已解锁
---@return boolean
function XTransfiniteTowerControl:IsStageUnlock(stageCfgId)
    local chapterId = self:GetChapterIdByStageCfg(stageCfgId)
    if not chapterId then return false end
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return false end
    if self:HasLastStageRecord(chapterId) then return true end
    return stage.Order <= self._Model:GetStageProgressIndex(chapterId) + 1
end

---关卡是否已通关（本轮；有上轮留存记录时按上轮展示）
---@return boolean
function XTransfiniteTowerControl:IsStagePass(stageCfgId)
    local chapterId = self:GetChapterIdByStageCfg(stageCfgId)
    if not chapterId then return false end
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return false end
    if self._Model:GetLastStageRecord(chapterId, stage.Order) then return true end
    return stage.Order <= self._Model:GetStageProgressIndex(chapterId)
end

---关卡是否记录通关时间（仅 15 层塔的层）
---@return boolean
function XTransfiniteTowerControl:IsRecordTimeStage(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return false end
    local chapter = self:GetChapterByStageGroupId(stage.StageGroupId)
    return chapter ~= nil and chapter.Type == 3
end

---关卡通关时间文本（mm:ss）：有上轮留存记录时优先取上轮（两者互斥）
---@return string
function XTransfiniteTowerControl:GetStageClearTimeText(stageCfgId)
    local chapterId = self:GetChapterIdByStageCfg(stageCfgId)
    if not chapterId then return "" end
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return "" end
    local lastRec = self._Model:GetLastStageRecord(chapterId, stage.Order)
    local spendTime = lastRec and lastRec.SpendTime or self._Model:GetStageSpendTime(chapterId, stage.Order)
    return XUiHelper.GetTime(spendTime)
end

---回溯点是否生效中（用于塔层项右上角回溯标签亮灭）
---@return boolean
function XTransfiniteTowerControl:IsRollbackPointActive(stageCfgId)
    local chapterId = self:GetChapterIdByStageCfg(stageCfgId)
    if not chapterId then return false end
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return false end
    return stage.Order == self._Model:GetRollbackOrder(chapterId)
end

---某关卡某槽位的成员数据
---结构：{ IsEmpty, SlotType, IsPilot, EnergyPoint, CharacterId }
---@return table
function XTransfiniteTowerControl:GetStageMemberSlotData(stageCfgId, slotIndex)
    local chapterId = self:GetChapterIdByStageCfg(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    if not chapterId or not stage then return EmptyMemberSlot end
    local team = self:GetStageRecordTeam(chapterId, stage.Order)
    local member = team and team[slotIndex]
    if not member then
        -- TODO[配表]：未通关时按 charactergroup 给空槽类型底纹
        return EmptyMemberSlot
    end
    -- 结果表复用：调用方（XUiGridMemberSlot:Refresh）同步读完即弃，避免滚动列表反复建表
    local result = MemberSlotResult
    result.IsEmpty = false
    result.SlotType = 0
    result.IsPilot = member.IsNavigator or false
    result.EnergyPoint = self:CalcMemberEnergyPoint(chapterId, stage.Order, member.FightId, stageCfgId)
    result.FightId = member.FightId
    return result
end

---出战 id → 角色小头像
---@param fightId number 自机 CharacterId 或试用机器人 RobotId
---@return string|nil
function XTransfiniteTowerControl:GetFightHeadIcon(fightId)
    if not XTool.IsNumberValid(fightId) then return end
    if XRobotManager.CheckIsRobotId(fightId) then
        local robot = XRobotManager.GetRobotTemplate(fightId)
        if not robot or not XTool.IsNumberValid(robot.CharacterId) then return end
        return XMVCA.XCharacter:GetCharSmallHeadIcon(robot.CharacterId, true)
    end
    return XMVCA.XCharacter:GetCharSmallHeadIcon(fightId)
end

---角色半身立绘
function XTransfiniteTowerControl:GetFightHalfBodyImage(fightId)
    if not XTool.IsNumberValid(fightId) then return end
    local characterId = fightId
    if XRobotManager.CheckIsRobotId(fightId) then
        local robot = XRobotManager.GetRobotTemplate(fightId)
        characterId = robot and robot.CharacterId
    end
    if not XTool.IsNumberValid(characterId) then return end
    return XMVCA.XCharacter:GetCharHalfBodyImage(characterId)
end

---取某层的出战角色列表：有上轮留存记录时优先取上轮（两者互斥）
---@return TransfiniteTowerFightCharacter[]
function XTransfiniteTowerControl:GetStageRecordTeam(chapterId, order)
    local lastRec = self._Model:GetLastStageRecord(chapterId, order)
    if lastRec then
        return lastRec.Team
    end
    local rec = self._Model:GetStageRecord(chapterId, order)
    return rec and rec.Team
end

---该角色打到本层时消耗的是第几点体力（= 含本层在内的累计出战次数）
---@param stageCfgId number 该记录所属层，用于取对应 CharacterGroup 的初始体力
---@return number
function XTransfiniteTowerControl:CalcMemberEnergyPoint(chapterId, order, fightId, stageCfgId)
    local agency = self:GetAgency()
    local energy = agency:GetEntityEnergyBeforeStage(chapterId, stageCfgId, fightId)
    return agency:GetEntityEnergyMax(fightId) - energy + 1
end

---空槽位类型对应的底纹图
---@return string
function XTransfiniteTowerControl:GetSlotTypeIcon(slotType)
    -- TODO[配表]：旗子/身体/两者底纹
    return ""
end

--endregion

--region 领航员教学（UiTransfiniteTowerTeach）
-- 数据来源（配表/服务端）未就绪，以下接口先返回空值，接入后在此填充。

---教学界面的领航员列表（Character 表 Type==2 的配置）
---@return table[]
function XTransfiniteTowerControl:GetTeachPilotList()
    return self:GetLeaderCharacterCfgList()
end

---领航员角色id（头像由 UI 层用 XMVCA.XCharacter 拼）
---@return number
function XTransfiniteTowerControl:GetPilotCharacterId(pilotData)
    return pilotData and pilotData.CharacterId or 0
end

---领航员名称
---@return string
function XTransfiniteTowerControl:GetPilotName(pilotData)
    if not pilotData then return "" end
    return XMVCA.XCharacter:GetCharacterName(pilotData.CharacterId)
end

---领航员强化（改造）名称
---@return string
function XTransfiniteTowerControl:GetPilotBuffName(pilotData)
    return pilotData and pilotData.BuffName or ""
end

---领航员强化详情文本
---@return string
function XTransfiniteTowerControl:GetPilotBuffDesc(pilotData)
    return pilotData and pilotData.BuffDescDetail or ""
end

---领航员强化演示视频 id
---@return number
function XTransfiniteTowerControl:GetPilotVideoId(pilotData)
    return pilotData and pilotData.VideoId or 0
end

---进入领航员教学关
function XTransfiniteTowerControl:EnterTeachStage(pilotData)
    local stage = XTool.IsNumberValid(pilotData and pilotData.TeachStageId)
        and self:GetStageCfg(pilotData.TeachStageId)
    if not stage then
        return
    end
    -- 教学演示优先用该领航员的试用机器人；未配 RobotId 退回自机角色
    local entityId = 0
    if pilotData then
        entityId = XTool.IsNumberValid(pilotData.RobotId) and pilotData.RobotId or pilotData.CharacterId or 0
    end
    local team = XDataCenter.TeamManager.CreateTempTeam({ entityId, 0, 0 })
    team:UpdateCaptainPosAndFirstFightPos(1, 1)
    self:EnterBattlePrepare(nil, stage.Id, team)
end

--endregion

--region 15层塔结算（UiTransfiniteTowerLastSettlement）

---本次结算信息：优先用章节结算响应暂存的，没有（如直接查看历史）才回退到存档
---@return TransfiniteTowerSettleInfo
function XTransfiniteTowerControl:GetCurSettleInfo(towerCfgId)
    local settleInfo = self._Model:GetCurSettleResult()
    return settleInfo or self._Model:GetSettleInfo(towerCfgId)
end

---常规队员列表
---@param excludeMvp boolean false 可拿到含 MVP 的全量列表（MVP 切换弹窗用）
function XTransfiniteTowerControl:GetLastSettleMemberList(towerCfgId, playerId, excludeMvp)
    if excludeMvp == nil then excludeMvp = true end
    local characters, mvpFightId
    if playerId then
        local show = self._Model:GetRankShow(playerId)
        characters = show and show.Characters
        mvpFightId = show and show.MvpFightId
    else
        local settleInfo = self:GetCurSettleInfo(towerCfgId)
        characters = settleInfo and settleInfo.Characters
        mvpFightId = settleInfo and settleInfo.MvpFightId
    end
    if XTool.IsTableEmpty(characters) then return table.empty end
    local list = {}
    for _, c in ipairs(characters) do
        if not excludeMvp or c.FightId ~= mvpFightId then
            list[#list + 1] = self:BuildSettleMember(c.FightId, c)
        end
    end
    return list
end

---把角色快照（结算 / 榜单两种来源结构一致）转成界面用的成员项
---FightId 是出战 id：IsTrial 为真时它是试用机器人的 RobotId，否则是自机 CharacterId
---@return table
function XTransfiniteTowerControl:BuildSettleMember(fightId, charData)
    local isTrial = charData and charData.IsTrial or false
    local characterId = XEntityHelper.GetCharacterIdByEntityId(fightId)
    local priority = XTool.IsNumberValid(characterId)
        and XMVCA.XCharacter:GetCharacterPriority(characterId) or 0
    return {
        IsEmpty = false,
        FightId = fightId,
        -- 试用机器人不展示品阶
        Quality = not isTrial and charData and charData.Quality or 0,
        IsSSSPlus = not isTrial and charData and charData.Quality >= 6 or false,
        IsTrial = isTrial,
        Power = charData and charData.Power or 0,
        Priority = priority,
    }
end

---荣誉队员（MVP），结构同上单项
---@param playerId number 可选，他人记录
---@return table
function XTransfiniteTowerControl:GetLastSettleMvpMember(towerCfgId, playerId)
    local mvpFightId, characters
    if playerId then
        local show = self._Model:GetRankShow(playerId)
        mvpFightId = show and show.MvpFightId
        characters = show and show.Characters
    else
        local settleInfo = self:GetCurSettleInfo(towerCfgId)
        mvpFightId = settleInfo and settleInfo.MvpFightId
        characters = settleInfo and settleInfo.Characters
    end
    if not XTool.IsNumberValid(mvpFightId) then return { IsEmpty = true } end
    -- 从角色快照里找 MVP 的品阶与试用标记
    local mvpChar
    if characters then
        for _, c in ipairs(characters) do
            if c.FightId == mvpFightId then
                mvpChar = c
                break
            end
        end
    end
    return self:BuildSettleMember(mvpFightId, mvpChar)
end

---通关统计 { MemberCount, TotalPower, ClearedStage, TotalTime, Rank, IsRankNew }
---15 层塔结算界面与 3/8 层塔结算弹窗（UiTransfiniteTowerSettlementPopup）共用，改动需同时兼顾两边
---@param playerId number 可选，他人记录（数据来自拉榜缓存的 RankShow）
---@return table
function XTransfiniteTowerControl:GetLastSettleStats(towerCfgId, playerId)
    if playerId then
        local show = self._Model:GetRankShow(playerId)
        if not show then return table.empty end
        return {
            MemberCount = show.Characters and #show.Characters or 0,
            TotalPower = show.TotalPower or 0,
            ClearedStage = show.MaxOrder or 0,
            TotalTime = show.TotalSpendTime or 0,
            Rank = show.RankNum or 0,
            IsRankNew = false,
        }
    end
    local settleInfo = self:GetCurSettleInfo(towerCfgId)
    if not settleInfo then return table.empty end
    local _, rank, totalCount = self._Model:GetCurSettleResult()
    return {
        MemberCount = settleInfo.Characters and #settleInfo.Characters or 0,
        TotalPower = settleInfo.TotalPower or 0,
        ClearedStage = settleInfo.Order or 0,
        TotalTime = settleInfo.TotalSpendTime or 0,
        Rank = rank,
        TotalCount = totalCount,
        IsRankNew = settleInfo.IsNewRecord,
    }
end

---他人玩家信息（头像/头像框/名字），用于查看他人记录
---@return table { HeadPortraitId, HeadFrameId, Name }
function XTransfiniteTowerControl:GetOthersPlayerInfo(playerId)
    local show = self._Model:GetRankShow(playerId)
    if not show then return { HeadPortraitId = 0, HeadFrameId = 0, Name = "" } end
    -- 榜单不下发头像框
    return { HeadPortraitId = show.HeadPortraitId or 0, HeadFrameId = 0, Name = show.Name or "" }
end

---打开他人结算记录（排行榜点击「查看记录」，只读模式）
function XTransfiniteTowerControl:OpenOthersLastSettlement(towerCfgId, playerId)
    XLuaUiManager.Open("UiTransfiniteTowerLastSettlement", towerCfgId, playerId)
end

---打开 MVP 切换弹窗
function XTransfiniteTowerControl:OpenSwitchMvpPopup(towerCfgId)
    XLuaUiManager.Open("UiTransfiniteTowerSwitchMvpPopup", towerCfgId)
end

---请求切换 MVP
---@param mvpFightId number 出战 id（自机 CharacterId 或试用机器人 RobotId）
---@param cb function 成功回调
function XTransfiniteTowerControl:RequestSwitchMvp(towerCfgId, mvpFightId, cb)
    self:RequestSetMvp(towerCfgId, mvpFightId, function()
        local settleInfo = self._Model:GetCurSettleResult()
        if settleInfo then
            settleInfo.MvpFightId = mvpFightId
        end
        XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_TOWER_MVP_CHANGE)
        if cb then cb() end
    end)
end

--endregion

--region 3/8 层塔简单结算弹窗（UiTransfiniteTowerSettlementPopup）

---弹窗标题「结算-XX之塔」
---@return string
function XTransfiniteTowerControl:GetSettlePopupTitle(towerCfgId)
    local chapter = self:GetChapterCfg(towerCfgId)
    if not chapter then return "" end
    return XUiHelper.GetText("TransfiniteTowerSettlePopupTitle", chapter.Name)
end

--endregion

--region 进战编队（UiBattleRoleRoom 超限启航定制 Proxy）
-- 数据来源（配表/服务端）未就绪，以下接口先返回空值/默认态，接入后在此填充。

---关卡配置id → 战斗关卡id（进 UiBattleRoleRoom 用）
---@return number
function XTransfiniteTowerControl:GetBattleStageId(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    return stage and stage.StageId or 0
end

--endregion

--region 战斗胜利结算（UiTransfiniteTowerSettlement）
-- 层序号与本层用时由战斗结算 TransfiniteTowerFightResult 直接下发，界面自持，不经 Control

---本层是否新纪录
---@param spendTime number 本次通关用时
---@return boolean
function XTransfiniteTowerControl:IsSettleNewRecord(stageCfgId, spendTime)
    local chapterId = self:GetChapterIdByStageCfg(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    if not chapterId or not stage then return false end
    local record = self._Model:GetStageRecord(chapterId, stage.Order)
        or self._Model:GetLastStageRecord(chapterId, stage.Order)
    return record == nil or (record.SpendTime or 0) > (spendTime or 0)
end

---全塔累计通关时间（秒，最后一层显示）
---@return number
function XTransfiniteTowerControl:GetSettleTotalClearTime(towerCfgId, curStageSpendTime)
    local confirmed = self._Model:GetConfirmedTotalSpendTime(towerCfgId)
    if confirmed > 0 then
        return confirmed + (curStageSpendTime or 0)
    end
    local total = 0
    for _, rec in ipairs(self._Model:GetLastStageRecordList(towerCfgId) or table.empty) do
        total = total + (rec.SpendTime or 0)
    end
    return total + (curStageSpendTime or 0)
end

---是否显示单层通关时间（仅 15 层塔）
---@return boolean
function XTransfiniteTowerControl:IsSettleShowStageTime(towerCfgId)
    return self:IsLastSettleTower(towerCfgId)
end

---是否显示重新挑战按钮（仅 15 层塔）
---@return boolean
function XTransfiniteTowerControl:IsSettleShowBtnAgain(towerCfgId)
    return self:IsLastSettleTower(towerCfgId)
end

---当前层是否为该塔最后一层
---@return boolean
function XTransfiniteTowerControl:IsSettleFinalStage(towerCfgId, stageCfgId)
    return stageCfgId == self:GetTowerBossStageCfgId(towerCfgId)
end

---下一层是否带词缀
---@return boolean
function XTransfiniteTowerControl:IsNextStageHasTrait(stageCfgId)
    local nextStage = self:GetNextStageCfg(stageCfgId)
    if not nextStage then return false end
    return not XTool.IsTableEmpty(nextStage.BuffDetailIds)
end

---下一层上阵队伍需求是否变化
---@return boolean
function XTransfiniteTowerControl:IsNextStageTeamChange(stageCfgId)
    local cur = self:GetStageCfg(stageCfgId)
    local nextStage = self:GetNextStageCfg(stageCfgId)
    if not cur or not nextStage then return false end
    return cur.CharacterGroupId ~= nextStage.CharacterGroupId
        or cur.NavigatorMode ~= nextStage.NavigatorMode
        or cur.NavigatorCount ~= nextStage.NavigatorCount
end

---挑战下一层：结算本层的请求发出即可，不阻塞跳转，点击立刻进下一层作战准备
---本地先预扣本场出战角色的体力，避免下一层编队界面显示的还是扣减前的值
function XTransfiniteTowerControl:SettleChallengeNext(towerCfgId, stageCfgId)
    local nextStage = self:GetNextStageCfg(stageCfgId)
    if not nextStage then return end
    local team = self:CreateTeamByFightSnapshot()
    self:GetAgency():ExitToStage()
    self:GetAgency():RequestStageSettle(towerCfgId)
    self:GetAgency():PredictConsumeEnergy(towerCfgId, stageCfgId)
    self:EnterBattlePrepare(towerCfgId, nextStage.Id, nil, team)
end

function XTransfiniteTowerControl:CreateTeamByFightSnapshot()
    local beginData = XMVCA.XFuben:GetFightBeginData()
    local snapshot = beginData and beginData.TeamSnapshot
    if not snapshot then
        return
    end
    local cardIds = snapshot.CardIds or table.empty
    local robotIds = snapshot.RobotIds or table.empty
    local entityIds = {}
    for i = 1, TEAM_POS_COUNT do
        entityIds[i] = (cardIds[i] or 0) > 0 and cardIds[i] or (robotIds[i] or 0)
    end
    local team = XDataCenter.TeamManager.CreateTempTeam(entityIds)
    team:UpdateCaptainPosAndFirstFightPos(snapshot.CaptainPos or 1, snapshot.FirstFightPos or 1)
    return team, snapshot
end

---重新挑战本层：原地重启
function XTransfiniteTowerControl:SettleRechallenge(towerCfgId, stageCfgId)
    local team, snapshot = self:CreateTeamByFightSnapshot()
    if not team then
        XLog.Error("超限启航重新挑战缺少本场编队快照")
        return
    end
    XLuaUiManager.SafeClose("UiTransfiniteTowerSettlement")
    XMVCA.XFuben:EnterFightByStageId(self:GetBattleStageId(stageCfgId), team:GetId(),
        snapshot.IsHasAssist or false,
        snapshot.ChallengeCount or 1)
end

---保留本层战绩并退回选关界面
function XTransfiniteTowerControl:SettleSaveAndExit(towerCfgId, stageCfgId)
    self:GetAgency():ExitToStage()
    self:GetAgency():RequestStageSettle(towerCfgId)
end

---放弃本层战绩退回选关界面（不发请求，服务端待确认记录自行失效）
function XTransfiniteTowerControl:SettleExitNoSave(towerCfgId, stageCfgId)
    self:GetAgency():ExitToStage()
end

---最后一层点击【结算】：整条链路跨越退战（Control 会被释放），编排在 Agency
function XTransfiniteTowerControl:EnterFinalSettle(towerCfgId)
    self:GetAgency():EnterFinalSettle(towerCfgId)
end

--endregion

--region 网络请求

---回溯至记录点
---@param chapterId number (= towerCfgId)
---@param cb function 成功回调
function XTransfiniteTowerControl:RequestRollback(chapterId, cb)
    XNetwork.Call("TransfiniteTowerRollbackRequest", { ChapterId = chapterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 存档更新靠服务端推 NotifyTransfiniteTowerData，此处只触发回调
        if cb then cb() end
    end)
end

---重置章节塔（清空上轮留存记录，重新挑战整塔前须先重置）
---@param chapterId number (= towerCfgId)
---@param cb function 成功回调
function XTransfiniteTowerControl:RequestResetChapter(chapterId, cb)
    XNetwork.Call("TransfiniteTowerResetChapterRequest", { ChapterId = chapterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

---自选 MVP（LastSettlement 替换 MVP 后点确认）
---@param chapterId number (= towerCfgId)
---@param mvpFightId number 出战 id（自机 CharacterId 或试用机器人 RobotId）
---@param cb function 成功回调
function XTransfiniteTowerControl:RequestSetMvp(chapterId, mvpFightId, cb)
    XNetwork.Call("TransfiniteTowerSetMvpRequest", { ChapterId = chapterId, MvpFightId = mvpFightId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

---拉取排行榜（仅排行章节塔）
---@param chapterId number (= towerCfgId)
---@param cb function 成功回调，参数 response
function XTransfiniteTowerControl:RequestGetRank(chapterId, cb)
    XNetwork.Call("TransfiniteTowerGetRankRequest", { ChapterId = chapterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb(res) end
    end)
end

--endregion

return XTransfiniteTowerControl
