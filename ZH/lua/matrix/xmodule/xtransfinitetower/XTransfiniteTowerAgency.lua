local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
---@class XTransfiniteTowerAgency : XFubenActivityAgency
---@field private _Model XTransfiniteTowerModel
local XTransfiniteTowerAgency = XClass(XFubenActivityAgency, "XTransfiniteTowerAgency", true)
-- 配置查询部分类
XClassPartialRequire("XModule/XTransfiniteTower/XTransfiniteTowerAgencyConfig", "XTransfiniteTowerAgency")

function XTransfiniteTowerAgency:OnInit()
    -- 注册到活动章节入口（玩家从活动列表进入）
    self:RegisterActivityAgency()
    -- 注册战斗钩子（战斗流程按 StageType 回调本模块 PreFight/EnterFight/ShowReward）
    self:RegisterFuben(XEnumConst.FuBen.StageType.TransfiniteTower)
    -- 初始化跨模块对外查询用的配置表
    self:InitConfig()
end

function XTransfiniteTowerAgency:InitRpc()
    XRpc.NotifyTransfiniteTowerData = handler(self, self.NotifyData)
    XRpc.NotifyTransfiniteTowerChapterInfo = handler(self, self.NotifyChapterInfo)
    XRpc.NotifyTransfiniteTowerRankReward = handler(self, self.NotifyRankReward)
end

local KICK_TIP_COOKIE_KEY = "TransfiniteTowerKickTip_%s"
local GENERAL_SKILL_KEY = "TransfiniteTowerGeneralSkill_%s_%s"

function XTransfiniteTowerAgency:GetStageProgressIndex(chapterId)
    return self._Model:GetStageProgressIndex(chapterId)
end

function XTransfiniteTowerAgency:HasKickTipShown(chapterId, progress)
    local cookie = XSaveTool.GetData(string.format(KICK_TIP_COOKIE_KEY, chapterId))
    return cookie ~= nil and cookie[progress] == true
end

function XTransfiniteTowerAgency:MarkKickTipShown(chapterId, progress)
    local key = string.format(KICK_TIP_COOKIE_KEY, chapterId)
    local cookie = XSaveTool.GetData(key) or {}
    cookie[progress] = true
    XSaveTool.SaveData(key, cookie)
end

function XTransfiniteTowerAgency:ClearKickTipCookie(chapterId)
    XSaveTool.RemoveData(string.format(KICK_TIP_COOKIE_KEY, chapterId))
end

---全量存档推送（登录/战斗后）
function XTransfiniteTowerAgency:NotifyData(data)
    self._Model:NotifyData(data and data.TransfiniteTowerDataDb or data)
    XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_TOWER_DATA_CHANGE)
end

---单章节塔推送（每层战斗结束 / 结算 / 回溯 / 重置后发）
function XTransfiniteTowerAgency:NotifyChapterInfo(data)
    self._Model:UpdateChapterInfo(data and data.ChapterInfo)
    XEventManager.DispatchEvent(XEventId.EVENT_TRANSFINITE_TOWER_DATA_CHANGE)
end

---排行结算发奖弹窗（在线/登录直发）
function XTransfiniteTowerAgency:NotifyRankReward(data)
    if not data or XTool.IsTableEmpty(data.RewardGoodsList) then
        return
    end
    self._PendingRankReward = data.RewardGoodsList
    if XLuaUiManager.IsUiShow("UiMain") then
        self:FlushPendingRankReward()
    elseif not self._OnMainUiEnableCb then
        self._OnMainUiEnableCb = handler(self, self.OnMainUiEnable)
        XEventManager.AddEventListener(XEventId.EVENT_MAINUI_ENABLE, self._OnMainUiEnableCb)
    end
end

function XTransfiniteTowerAgency:OnMainUiEnable()
    if self._OnMainUiEnableCb then
        XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_ENABLE, self._OnMainUiEnableCb)
        self._OnMainUiEnableCb = nil
    end
    self:FlushPendingRankReward()
end

function XTransfiniteTowerAgency:FlushPendingRankReward()
    if self._PendingRankReward then
        local rewardList = self._PendingRankReward
        self._PendingRankReward = nil
        XUiManager.OpenUiObtain(self:MergeRankRewardList(rewardList))
    end
end

function XTransfiniteTowerAgency:MergeRankRewardList(rewardList)
    local seen, order = {}, {}
    for _, reward in ipairs(rewardList or table.empty) do
        if reward and XTool.IsNumberValid(reward.TemplateId) and not seen[reward.TemplateId] then
            seen[reward.TemplateId] = true
            order[#order + 1] = { TemplateId = reward.TemplateId, Count = 1 }
        end
    end
    return order
end

function XTransfiniteTowerAgency:InitEvent()
    -- 战斗结算回包时派发（此时仍在战斗场景内），用战斗结算动作作为结算界面背景
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, self.OnFightSettleReward, self)
end

---战斗结算：胜利时在战斗内弹本模块结算界面,失败直接退战走通用失败结算
function XTransfiniteTowerAgency:OnFightSettleReward(settleData)
    if not settleData then
        return
    end
    local stageCfg = self:GetStageCfgByBattleStageId(settleData.StageId)
    if not stageCfg then
        return
    end
    if not settleData.IsWin then
        self:ExitFight()
        return
    end
    local fightResult = settleData.TransfiniteTowerFightResult
    if not fightResult then
        -- 是教学关
        return
    end
    local chapterId = self:GetChapterIdByStageCfg(stageCfg.Id)
    XLuaUiManager.Open("UiTransfiniteTowerSettlement", chapterId, stageCfg.Id, fightResult.Order, fightResult.SpendTime)
end

---退出战斗（结算界面的各个出口在跳转前调用）
function XTransfiniteTowerAgency:ExitFight()
    CS.XFight.ExitForClient(true)
end

--region 章节结算流程
-- 整条链路横跨退战：ExitFight 会清空 UI 栈进而释放 Control，之后的网络回调里 Control 已失效，
-- 所以放常驻的 Agency，不放 Control。

---是否为末位结算塔（15 层塔走 LastSettlement，其余走 SettlementPopup）
---@return boolean
function XTransfiniteTowerAgency:IsLastSettleTower(chapterId)
    local chapter = self:GetChapterCfg(chapterId)
    return chapter ~= nil and chapter.Type == 3
end

---关闭单层结算界面并退出战斗（结算界面是在战斗内弹的，3D 结算动作作为背景，此时战斗仍未退出）
function XTransfiniteTowerAgency:ExitToStage()
    self:ExitFight()
    XLuaUiManager.SafeClose("UiTransfiniteTowerSettlement")
end

---最后一层点击【结算】：先结算本层，再走章节结算
function XTransfiniteTowerAgency:EnterFinalSettle(chapterId)
    self:ExitToStage()
    self:RequestStageSettle(chapterId, function()
        self:DoChapterSettle(chapterId)
    end)
end

---章节结算 + 按塔类型跳转（15 层塔进 MVP 荣誉结算，其余弹结算弹窗）
---本次结算数据只在响应里下发：存档里的 SettleInfo 是「多轮中最好成绩」，成绩不如上轮时不会被覆盖，
---直接读存档会把上一轮的成绩显示成本次结果，所以这里把响应暂存给结算界面用
function XTransfiniteTowerAgency:DoChapterSettle(chapterId)
    self:RequestChapterSettle(chapterId, function(settleInfo, rank, totalCount)
        self._Model:SetCurSettleResult(settleInfo, rank, totalCount)
        -- 存档只留最好成绩：创了新纪录才把这次的结算写回去
        if settleInfo and settleInfo.IsNewRecord then
            self._Model:UpdateSettleInfo(chapterId, settleInfo)
        end
        if self:IsLastSettleTower(chapterId) then
            XLuaUiManager.Open("UiTransfiniteTowerLastSettlement", chapterId)
        else
            XLuaUiManager.Open("UiTransfiniteTowerSettlementPopup", chapterId)
        end
    end)
end

---单关卡结算（确认保留本层战绩，服务端应用 PendingStageRecord）
---@param cb function 成功回调
function XTransfiniteTowerAgency:RequestStageSettle(chapterId, cb)
    XNetwork.Call("TransfiniteTowerStageSettleRequest", { ChapterId = chapterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb() end
    end)
end

---章节塔结算（提前结算 / 最后一层结算）；MVP 由服务端按战力定，客户端不传
---@param cb function 成功回调，参数 (SettleInfo, rank, totalCount)
function XTransfiniteTowerAgency:RequestChapterSettle(chapterId, cb)
    XNetwork.Call("TransfiniteTowerChapterSettleRequest", { ChapterId = chapterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if cb then cb(res.SettleInfo, res.Rank, res.TotalCount) end
    end)
end

--endregion

--region override 基类虚方法

function XTransfiniteTowerAgency:ExGetConfig()
    if XTool.IsTableEmpty(self.ExConfig) then
        ---@type XTableFubenActivity
        self.ExConfig = XFubenConfigs.GetFubenActivityConfigByManagerName(self.__cname)
    end
    return self.ExConfig
end

function XTransfiniteTowerAgency:ExOpenMainUi()
    if not self:ExCheckInTime() then
        XUiManager.TipText("CommonActivityNotStart")
        return false
    end
    XLuaUiManager.Open("UiTransfiniteTowerMain")
    return true
end

--endregion

--region 战斗钩子（RegisterFuben 注册，按 StageType 被 CallCustomFunc 分派）

---@param stage XTableStage 通用关卡配置
function XTransfiniteTowerAgency:PreFight(stage, teamId, isAssist, challengeCount)
    local team = XDataCenter.TeamManager.GetXTeam(teamId) or XDataCenter.TeamManager.GetTempTeam(teamId)
    if not team then
        XLog.Error("超限启航进战找不到队伍, teamId: " .. tostring(teamId))
        return
    end
    local preFight = {}
    preFight.StageId = stage.StageId
    preFight.RobotIds = team:GetRobotIdsOrder()
    preFight.CardIds = team:GetCharacterIdsOrder()
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1
    preFight.CaptainPos = team:GetCaptainPos()
    preFight.FirstFightPos = team:GetFirstFightPos()
    preFight.GeneralSkill = team:GetCurGeneralSkill()
    preFight.EnterCgIndex = team:GetEnterCgIndex()
    preFight.SettleCgIndex = team:GetSettleCgIndex()
    self._LastPreFightData = preFight
    return preFight
end

function XTransfiniteTowerAgency:CustomRecordFightBeginData(stageId)
    if self._LastPreFightData and self._LastPreFightData.StageId == stageId then
        local beginData = XMVCA.XFuben:GetFightBeginData()
        if beginData then
            beginData.TeamSnapshot = self._LastPreFightData
        end
    end
end

---最后调用战斗进入接口时分派：战斗内（结算界面点重新挑战）原地重启，不退战不加载场景
function XTransfiniteTowerAgency:CustomOnCallFight(fightData, args)
    if XFightUtil.IsFighting() then
        XMVCA.XFuben:ResetSettle()
        CS.XFight.Restart(fightData, args)
    else
        CS.XFight.Enter(fightData, args)
    end
end

function XTransfiniteTowerAgency:OpenFightLoading(stageId)
    XMVCA.XFuben:OpenFightLoading(stageId)
end

---是否教学关战斗
---@param battleStageId number 通用战斗关卡 id（Stage.StageId）
---@return boolean
function XTransfiniteTowerAgency:IsTeachBattleStage(battleStageId)
    local stageCfg = self:GetStageCfgByBattleStageId(battleStageId)
    if not stageCfg then
        return false
    end
    return self:GetChapterIdByStageCfg(stageCfg.Id) == nil
end

---普通塔不自动退出战斗
---@return boolean
function XTransfiniteTowerAgency:CheckAutoExitFight(stageId)
    return self:IsTeachBattleStage(stageId)
end

---塔层胜利停在动画时不走默认 FinishFight；教学关走通用
function XTransfiniteTowerAgency:FinishFight(settleData)
    if not settleData then
        return
    end
    if settleData.IsWin then
        if self:IsTeachBattleStage(settleData.StageId) then
            XMVCA.XFuben:FinishFight(settleData)
        end
        return
    end
    XMVCA.XFuben:ChallengeLose(settleData)
end

---塔层屏蔽通用局外结算界面（单层结算界面在战斗内弹过）；教学关走通用 UiSettleWin
function XTransfiniteTowerAgency:ShowReward(winData, playEndStory)
    if not self:IsTeachBattleStage(winData and winData.StageId) then
        return
    end
    XLuaUiManager.OpenWithCloseCallback("UiSettleWin", function()
        XLuaUiManager.CloseAllUpperUi("UiTransfiniteTowerMain")
    end, winData)
end

---教学关通关查询
---@param battleStageId number 通用战斗关卡 id（Stage.StageId）
---@return boolean
function XTransfiniteTowerAgency:CheckPassedByStageId(battleStageId)
    local stageCfg = self:GetStageCfgByBattleStageId(battleStageId)
    if not stageCfg then
        return false
    end
    local chapterId = self:GetChapterIdByStageCfg(stageCfg.Id)
    if not chapterId then
        return false
    end
    return self:IsChapterAllPassed(chapterId)
end

---该塔是否整塔通关过
---@return boolean
function XTransfiniteTowerAgency:IsChapterAllPassed(chapterId)
    local chapter = self:GetChapterCfg(chapterId)
    if not chapter or not chapter.StageGroupId then
        return false
    end
    local totalCount = #self:GetStagesByGroupId(chapter.StageGroupId)
    return totalCount > 0 and self._Model:GetMaxPassedOrder(chapterId) >= totalCount
end

---是否为教学塔
---@return boolean
function XTransfiniteTowerAgency:IsTeachTower(chapterId)
    local chapter = self:GetChapterCfg(chapterId)
    return chapter ~= nil and chapter.Type == 1
end

---教学塔是否通关
---@return boolean
function XTransfiniteTowerAgency:IsTeachTowerFreePractice(chapterId)
    if not self:IsTeachTower(chapterId) then
        return false
    end
    return self:IsChapterAllPassed(chapterId)
end
--endregion

--region 活动框架级对外接口（活动时间 / 任务，供 UI 与其他模块红点等查询）
-- 数据来源（配表/服务端）未就绪，先返回空值，接入后在此填充。

---活动剩余时间（秒）
---@return number
function XTransfiniteTowerAgency:GetActivityRemainTime()
    local timeId = self:GetOpenActivityTimeId()
    if not timeId then return 0 end
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    local remain = endTime - XTime.GetServerNowTimestamp()
    return remain > 0 and remain or 0
end

---活动结束时间戳（任务界面 SetAutoCloseInfo 用）
---@return number
function XTransfiniteTowerAgency:GetActivityEndTime()
    local timeId = self:GetOpenActivityTimeId()
    if not timeId then return 0 end
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

---当前活动的限时任务组 id
---@return number
function XTransfiniteTowerAgency:GetTaskTimeLimitId()
    local _, activityId = self:GetOpenActivityTimeId()
    if not activityId then return 0 end
    local cfg = self:GetActivityCfg(activityId)
    return cfg and cfg.TaskTimeLimitId or 0
end

---当前活动的任务列表（通用 TaskManager 任务对象数组，已按状态排序）
---@return table[]
function XTransfiniteTowerAgency:GetTaskList()
    local groupId = self:GetTaskTimeLimitId()
    if not XTool.IsNumberValid(groupId) then return table.empty end
    return XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId)
end

---任务进度（已完成数, 总数）
---@return number, number
function XTransfiniteTowerAgency:GetTaskProgress()
    local list = self:GetTaskList()
    local total = #list
    if total <= 0 then return 0, 0 end
    local finishState = XDataCenter.TaskManager.TaskState.Finish
    local finished = 0
    for i = 1, total do
        if list[i].State == finishState then
            finished = finished + 1
        end
    end
    return finished, total
end

---是否有任务奖励可领（红点用）
---@return boolean
function XTransfiniteTowerAgency:HasTaskRewardCanGet()
    local groupId = self:GetTaskTimeLimitId()
    if not XTool.IsNumberValid(groupId) then return false end
    return XDataCenter.TaskManager.CheckTimeLimitTaskAnyCanFinishByGroupId(groupId)
end

---任务奖励预览（无奖励时 rewardData 为 nil，调用方据此隐藏气泡）
---@return table[]|nil 奖励项列表（XRewardData），未配返回 nil
function XTransfiniteTowerAgency:GetTaskRewardPreview()
    local cfg = self:GetConfigByKey("TaskRewards")
    local rewardIds = cfg and cfg.Values
    if XTool.IsTableEmpty(rewardIds) then return nil end
    local list = {}
    for _, rewardId in ipairs(rewardIds) do
        local rewards = XRewardManager.GetRewardList(tonumber(rewardId))
        if not XTool.IsTableEmpty(rewards) then
            list[#list + 1] = rewards[1]
        end
    end
    if #list <= 0 then return nil end
    return list
end

--endregion

--region 进战编队对外接口（供通用编队界面 UiBattleRoleRoom 的超限启航 Proxy 查询）
-- Proxy 由通用战斗框架实例化，对本模块而言是外部调用方，故走 Agency 对外接口。
-- 数据来源（配表/服务端）未就绪，先返回空值/默认态，接入后在此填充。

-- 体力槽默认上限（InitFightCounts 未配时用）
XTransfiniteTowerAgency.ENERGY_MAX = 3

-- 疲劳 DeBuff 的血量上限削减比例，下标为已出战次数（0 次不显示 DeBuff）
local DEBUFF_HP_REDUCE = { 33, 66, 100 }

-- Stage.NavigatorMode：3=禁止领航员上阵
local NAVIGATOR_MODE_FORBIDDEN = 3

-- 体力条颜色
local ENERGY_COLORS = {
    XUiHelper.Hexcolor2Color("f8232d"),
    XUiHelper.Hexcolor2Color("d6910d"),
    XUiHelper.Hexcolor2Color("10b310"),
}

---体力条颜色
---@param energy number 剩余体力
---@return UnityEngine.Color
function XTransfiniteTowerAgency:GetEnergyColor(energy)
    local index = math.max(1, math.min(energy or 0, #ENERGY_COLORS))
    return ENERGY_COLORS[index]
end

---编队界面打开时存当前 chapterId / stageCfgId（详情 Proxy 查体力与选角池用，因其拿不到这两个 id）
function XTransfiniteTowerAgency:SetCurrentChapterId(chapterId)
    self._CurrentChapterId = chapterId
end

---@return number
function XTransfiniteTowerAgency:GetCurrentChapterId()
    return self._CurrentChapterId
end

function XTransfiniteTowerAgency:SetCurrentStageCfgId(stageCfgId)
    self._CurrentStageCfgId = stageCfgId
end

---@return number
function XTransfiniteTowerAgency:GetCurrentStageCfgId()
    return self._CurrentStageCfgId
end

function XTransfiniteTowerAgency:SetStageUiTowerCfgId(towerCfgId)
    self._StageUiTowerCfgId = towerCfgId
end


function XTransfiniteTowerAgency:GetStageUiTowerCfgId()
    return self._StageUiTowerCfgId
end

---编队界面点战斗时记下本场队伍与所属关卡，供结算界面【重新挑战】原地重打复用
function XTransfiniteTowerAgency:SetLastFightTeamId(teamId, stageCfgId)
    self._LastFightTeamId = teamId
    self._LastFightStageCfgId = stageCfgId
end

---缓存每塔上次选择的效应
function XTransfiniteTowerAgency:SaveLastGeneralSkill(towerCfgId, skillId)
    XSaveTool.SaveData(string.format(GENERAL_SKILL_KEY, towerCfgId, XPlayer.Id), skillId)
end

function XTransfiniteTowerAgency:GetLastGeneralSkill(towerCfgId)
    local skillId = XSaveTool.GetData(string.format(GENERAL_SKILL_KEY, towerCfgId, XPlayer.Id))
    return XTool.IsNumberValid(skillId) and skillId or nil
end

---取指定关卡上一场使用的队伍 id；非同一关卡返回 nil（避免串层）
---@return number
function XTransfiniteTowerAgency:GetLastFightTeamId(stageCfgId)
    if self._LastFightStageCfgId ~= stageCfgId then return end
    return self._LastFightTeamId
end

---当前层可选的编队角色列表
---@param characterType number 通用界面的角色类型筛选
---@return table[]
function XTransfiniteTowerAgency:GetStageSelectableEntities(characterType)
    local stage = self:GetStageCfg(self:GetCurrentStageCfgId())
    local group = stage and self:GetCharacterGroupCfg(stage.CharacterGroupId)
    if not group then
        return XMVCA.XCharacter:GetOwnCharacterList(characterType)
    end

    local allowCharIds, robots, lockedCharIds = {}, {}, {}
    for _, charCfgId in ipairs(group.TowerCharacterIds or table.empty) do
        local cfg = self:GetCharacterCfg(charCfgId)
        if cfg then
            -- 解锁时间未到：该行配置的自机与试用机器人都不进选角池
            if XTool.IsNumberValid(cfg.UnLockTimeId) and not XFunctionManager.CheckInTimeByTimeId(cfg.UnLockTimeId) then
                if XTool.IsNumberValid(cfg.CharacterId) then
                    lockedCharIds[cfg.CharacterId] = true
                end
                goto continue
            end
            if XTool.IsNumberValid(cfg.CharacterId) then
                allowCharIds[cfg.CharacterId] = true
                -- 同角色其他行已解锁则整体不锁（全选模式下按角色判定）
                lockedCharIds[cfg.CharacterId] = nil
            end
            if XTool.IsNumberValid(cfg.RobotId) then
                local robot = XRobotManager.GetRobotById(cfg.RobotId)
                if robot then
                    robots[#robots + 1] = robot
                else
                    XLog.Error("超限启航 Character 表配置的 RobotId 不存在: " .. tostring(cfg.RobotId))
                end
            end
        end
        ::continue::
    end

    local isAllCharacter = XTool.IsNumberValid(group.IsAllCharacter)
    -- 剔除自机领航员
    local isForbidLeader = stage.NavigatorMode == NAVIGATOR_MODE_FORBIDDEN
    local entities = {}
    for _, entity in ipairs(XMVCA.XCharacter:GetOwnCharacterList(characterType)) do
        if isAllCharacter or allowCharIds[entity.Id] then
            -- 全选模式下，配置了解锁时间且未到的自机同样不显示
            if not lockedCharIds[entity.Id] and not (isForbidLeader and self:IsLeaderEntity(entity.Id)) then
                entities[#entities + 1] = entity
            end
        end
    end
    for i = 1, #robots do
        entities[#entities + 1] = robots[i]
    end
    return entities
end

function XTransfiniteTowerAgency:GetLeaderFirstSortTable()
    local stage = self:GetStageCfg(self:GetCurrentStageCfgId())
    if not stage or stage.NavigatorMode == NAVIGATOR_MODE_FORBIDDEN then
        return
    end
    local leaderSort = CharacterSortFunType.Custom1
    local energySort = CharacterSortFunType.Custom2
    return {
        CheckFunList = {
            [leaderSort] = function(idA, idB)
                return self:IsLeaderEntity(idA) ~= self:IsLeaderEntity(idB)
            end,
            [energySort] = function(idA, idB)
                return self:IsEntityEnergyEmpty(idA) ~= self:IsEntityEnergyEmpty(idB)
            end,
        },
        SortFunList = {
            [leaderSort] = function(idA, idB)
                local isLeaderA = self:IsLeaderEntity(idA)
                local isLeaderB = self:IsLeaderEntity(idB)
                if isLeaderA ~= isLeaderB then
                    return isLeaderA
                end
            end,
            [energySort] = function(idA, idB)
                local emptyA = self:IsEntityEnergyEmpty(idA)
                local emptyB = self:IsEntityEnergyEmpty(idB)
                if emptyA ~= emptyB then
                    return not emptyA   
                end
            end,
        },
    }
end

---客户端预扣本场出战角色的一点体力
function XTransfiniteTowerAgency:PredictConsumeEnergy(chapterId, stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    local isRechallenge = stage ~= nil
        and stage.Order <= self._Model:GetStageProgressIndex(chapterId)
    if isRechallenge then
        return
    end
    local beginData = XMVCA.XFuben:GetFightBeginData()
    local charList = beginData and beginData.CharList
    if XTool.IsTableEmpty(charList) then return end
    for _, fightId in ipairs(charList) do
        if XTool.IsNumberValid(fightId) and not self:IsLeaderEntity(fightId) then
            local characterId = XEntityHelper.GetCharacterIdByEntityId(fightId)
            if XTool.IsNumberValid(characterId) then
                local cfg = self:GetStageCharacterCfg(fightId)
                self._Model:AddCharacterUsedCount(chapterId, cfg and cfg.Id or 0, characterId)
            end
        end
    end
end

---实体是否为领航员
---@return boolean
function XTransfiniteTowerAgency:IsLeaderEntity(fightId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(fightId)
    if not XTool.IsNumberValid(characterId) then return false end
    local cfg = self:GetCharacterCfgByCharacterId(characterId)
    return cfg ~= nil and cfg.Type == 2
end

---实体体力上限
---@return number
function XTransfiniteTowerAgency:GetEntityEnergyMax(fightId)
    return self.ENERGY_MAX
end

---获取指定关卡 CharacterGroup 内对应的 Character 配置
---@param fightId number 自机 CharacterId 或试用机器人 RobotId
---@param stageCfgId number 可选，不传则用当前进战关卡（选关界面须显式传，此时无当前关卡）
---@return XTableTransfiniteTowerCharacter
function XTransfiniteTowerAgency:GetStageCharacterCfg(fightId, stageCfgId)
    stageCfgId = stageCfgId or self:GetCurrentStageCfgId()
    if not XTool.IsNumberValid(stageCfgId) then return end
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return end
    local groupId = stage.CharacterGroupId
    local group = self:GetCharacterGroupCfg(groupId)
    if not group then return end

    if not self._StageCharCfgCache then
        self._StageCharCfgCache = {}
    end
    local cache = self._StageCharCfgCache[groupId]
    if not cache then
        cache = {}
        for _, charCfgId in ipairs(group.TowerCharacterIds or table.empty) do
            local cfg = self:GetCharacterCfg(charCfgId)
            if cfg then
                if XTool.IsNumberValid(cfg.CharacterId) then
                    cache[cfg.CharacterId] = cfg
                end
                if XTool.IsNumberValid(cfg.RobotId) then
                    cache[cfg.RobotId] = cfg
                end
            end
        end
        self._StageCharCfgCache[groupId] = cache
    end
    return cache[fightId]
end

---实体初始体力
---@param fightId number 自机 CharacterId 或试用机器人 RobotId
---@param stageCfgId number 可选，不传则用当前进战关卡（选关界面须显式传，此时无当前关卡）
---@return number
function XTransfiniteTowerAgency:GetEntityInitCount(fightId, stageCfgId)
    stageCfgId = stageCfgId or self:GetCurrentStageCfgId()
    if not XTool.IsNumberValid(stageCfgId) then return self.ENERGY_MAX end
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return self.ENERGY_MAX end
    local group = self:GetCharacterGroupCfg(stage.CharacterGroupId)
    if not group then return self.ENERGY_MAX end
    local cfg = self:GetStageCharacterCfg(fightId, stageCfgId)
    if not cfg then return self.ENERGY_MAX end
    for i, charCfgId in ipairs(group.TowerCharacterIds or table.empty) do
        if charCfgId == cfg.Id then
            local count = (group.InitFightCounts or table.empty)[i]
            return count ~= nil and count or self.ENERGY_MAX
        end
    end
    return self.ENERGY_MAX
end

---实体当前剩余体力（0~初始体力）；= 初始体力 - 该塔实际出战次数
---教学塔直接返回配置初始体力，不扣已出战次数
---@return number
function XTransfiniteTowerAgency:GetEntityEnergy(towerCfgId, fightId)
    if self:IsTeachTower(towerCfgId) then
        return self:GetEntityInitCount(fightId)
    end
    local initCount = self:GetEntityInitCount(fightId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(fightId)
    if not XTool.IsNumberValid(characterId) then return initCount end
    local cfg = self:GetStageCharacterCfg(fightId)
    local usedCount
    if cfg then
        usedCount = self._Model:GetCharacterUsedCount(towerCfgId, cfg.Id)
    else
        usedCount = self._Model:GetCharacterUsedCountByCharacterId(towerCfgId, characterId)
    end
    local remain = initCount - usedCount
    return remain > 0 and remain or 0
end

---重新挑战时展示"挑战该层前"的剩余体力
---按该层之前（不含本层）的累计出战次数算
---@param chapterId number
---@param stageCfgId number
---@param fightId number
---@return number
function XTransfiniteTowerAgency:GetEntityEnergyBeforeStage(chapterId, stageCfgId, fightId)
    if self:IsLeaderEntity(fightId) then return 0 end
    if self:IsTeachTower(chapterId) then
        return self:GetEntityInitCount(fightId, stageCfgId)
    end
    local initCount = self:GetEntityInitCount(fightId, stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return initCount end
    local characterId = XRobotManager.GetCharacterId(fightId)
    if not XTool.IsNumberValid(characterId) then return initCount end
    local count = 0
    for i = 1, stage.Order - 1 do
        local team = self._Model:GetLastStageRecord(chapterId, i)
        team = team and team.Team or (function()
            local rec = self._Model:GetStageRecord(chapterId, i)
            return rec and rec.Team
        end)()
        if team then
            for _, member in ipairs(team) do
                if XRobotManager.GetCharacterId(member.FightId) == characterId then
                    count = count + 1
                    break
                end
            end
        end
    end
    local remain = initCount - count
    return remain > 0 and remain or 0
end

---选中层的词缀列表（每项含 Icon/Name/Desc），复用 BabelTower 词缀配置
---结果按 stageCfgId 缓存：塔层项列表滚动时每格都会查，且词缀由配表决定不会变
---@return table[]
function XTransfiniteTowerAgency:GetStageTraitList(stageCfgId)
    if not self._StageTraitCache then
        self._StageTraitCache = {}
    end
    local cache = self._StageTraitCache[stageCfgId]
    if cache then
        return cache
    end
    local stage = self:GetStageCfg(stageCfgId)
    if not stage or XTool.IsTableEmpty(stage.BuffDetailIds) then
        self._StageTraitCache[stageCfgId] = table.empty
        return table.empty
    end
    local list = {}
    for _, buffId in ipairs(stage.BuffDetailIds) do
        local buff = XFubenBabelTowerConfigs.GetBabelBuffConfigs(buffId)
        if buff then
            list[#list + 1] = {
                Icon = buff.BuffBg,
                Name = buff.Name,
                Desc = buff.Desc,
                TriangleBg = buff.BuffTriangleBg,
            }
        end
    end
    self._StageTraitCache[stageCfgId] = list
    return list
end

---上阵要求提示（与选关界面 TxtFormationTips 同源）；返回 nil 则不显示
---@return string
function XTransfiniteTowerAgency:GetStageFormationTip(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return end
    if stage.NavigatorMode == 1 then
        return XUiHelper.GetText("TransfiniteTowerFormationAtLeast", stage.NavigatorCount)
    elseif stage.NavigatorMode == 2 then
        return XUiHelper.GetText("TransfiniteTowerFormationCan", stage.NavigatorCount)
    elseif stage.NavigatorMode == 3 then
        return XUiHelper.GetText("TransfiniteTowerFormationForbid")
    end
end

---校验上阵领航员数量是否满足本层要求
---NavigatorMode：1=至少 NavigatorCount 名，2=最多 NavigatorCount 名（可以不带），3=禁止带
---@param leaderCount number 当前上阵的领航员数量
---@return string|nil
function XTransfiniteTowerAgency:GetLeaderCountInvalidTip(stageCfgId, leaderCount)
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return end
    if stage.NavigatorMode == 1 then
        if leaderCount < stage.NavigatorCount then
            return XUiHelper.GetText("TransfiniteTowerBattleNeedLeader")
        end
        if leaderCount > stage.NavigatorCount then
            return XUiHelper.GetText("TransfiniteTowerBattleLeaderTooMany", stage.NavigatorCount)
        end
    elseif stage.NavigatorMode == 2 then
        if leaderCount > stage.NavigatorCount then
            return XUiHelper.GetText("TransfiniteTowerBattleLeaderTooMany", stage.NavigatorCount)
        end
    elseif stage.NavigatorMode == 3 then
        if leaderCount > 0 then
            return XUiHelper.GetText("TransfiniteTowerBattleForbidLeader")
        end
    end
end

---是否显示回溯点失效提醒（已激活一个回溯点，且当前层是新的回溯点）
---@return boolean
function XTransfiniteTowerAgency:IsShowEnterWarn(towerCfgId, stageCfgId)
    local rollbackOrder = self._Model:GetRollbackOrder(towerCfgId)
    if rollbackOrder <= 0 then return false end
    local stage = self:GetStageCfg(stageCfgId)
    if not stage or stage.IsReset ~= true then return false end
    return stage.Order > rollbackOrder
end

--endregion

--region 角色详情对外接口（供通用角色详情界面 UiBattleRoomRoleDetail 的超限启航 Proxy 查询）
-- 数据来源（配表/服务端）未就绪，先返回空值/默认态，接入后在此填充。

---领航员专属强化名（PanelRoleModeBuff.TxtTitle）
---@return string
function XTransfiniteTowerAgency:GetLeaderBuffName(fightId)
    local cfg = self:GetLeaderCharacterCfg(fightId)
    return cfg and cfg.BuffName or ""
end

---领航员专属强化详情（PanelRoleModeBuff.TxtBuffDec）
---@return string
function XTransfiniteTowerAgency:GetLeaderBuffDesc(fightId)
    local cfg = self:GetLeaderCharacterCfg(fightId)
    return cfg and cfg.BuffDesc or ""
end

---实体→角色id→领航员 Character 配置（非领航员返回 nil）
---@return XTableTransfiniteTowerCharacter
function XTransfiniteTowerAgency:GetLeaderCharacterCfg(fightId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(fightId)
    if not XTool.IsNumberValid(characterId) then return end
    local cfg = self:GetCharacterCfgByCharacterId(characterId)
    if cfg and cfg.Type == 2 then
        return cfg
    end
end

---非领航员角色的 Buff 描述（读 Character.BuffDesc），无则返回 nil
---@return string
function XTransfiniteTowerAgency:GetRoleBuff(fightId)
    local characterId = XEntityHelper.GetCharacterIdByEntityId(fightId)
    if not XTool.IsNumberValid(characterId) then return end
    local cfg = self:GetCharacterCfgByCharacterId(characterId)
    return cfg and cfg.BuffDesc
end

---非领航员角色的疲劳 DeBuff 描述与详情；未消耗体力返回 nil 表示不显示
---@return string desc, string infoDesc
function XTransfiniteTowerAgency:GetRoleDebuff(fightId)
    local chapterId = self:GetCurrentChapterId()
    if not chapterId then return end
    local remain = self:GetEntityEnergy(chapterId, fightId)
    local usedCount = self:GetEntityEnergyMax(fightId) - remain
    local reduce = DEBUFF_HP_REDUCE[usedCount]
    if not reduce then return end
    local cfg = self:GetConfigByKey("CharacterDebuff")
    if not cfg or XTool.IsTableEmpty(cfg.Values) then return end
    return XUiHelper.FormatText(cfg.Values[1], reduce), cfg.Values[2]
end

---实体已出战次数；领航员不消耗体力恒为 0
---@return number
function XTransfiniteTowerAgency:GetEntityUsedCount(fightId)
    if self:IsLeaderEntity(fightId) then return 0 end
    local chapterId = self:GetCurrentChapterId()
    if not chapterId then return 0 end
    local characterId = XEntityHelper.GetCharacterIdByEntityId(fightId)
    if not XTool.IsNumberValid(characterId) then return 0 end
    local cfg = self:GetStageCharacterCfg(fightId)
    if cfg then
        return self._Model:GetCharacterUsedCount(chapterId, cfg.Id)
    else
        return self._Model:GetCharacterUsedCountByCharacterId(chapterId, characterId)
    end
end

---实体体力是否已耗尽（耗尽则不允许上阵）；领航员不受体力限制
---教学塔按配置初始体力判定，初始为 0 则视为耗尽
---@return boolean
function XTransfiniteTowerAgency:IsEntityEnergyEmpty(fightId)
    if self:IsLeaderEntity(fightId) then return false end
    local chapterId = self:GetCurrentChapterId()
    if not chapterId then return false end
    return self:GetEntityEnergy(chapterId, fightId) <= 0
end

---打开领航员教学界面并默认选中指定角色（角色详情强化面板 BtnTeach 跳转用）
function XTransfiniteTowerAgency:OpenTeachWithSelect(characterId)
    XLuaUiManager.Open("UiTransfiniteTowerTeach", characterId)
end

---角色剩余体力占比（0~1，角色详情左侧格子体力条 ImgStaminaExpFill.fillAmount 用）
---@return number ratio, number energy 占比与剩余体力
function XTransfiniteTowerAgency:GetEntityStaminaRatio(fightId)
    local chapterId = self:GetCurrentChapterId()
    if not chapterId then return 0, 0 end
    local energy = self:GetEntityEnergy(chapterId, fightId)
    local max = self:GetEntityEnergyMax(fightId)
    return max > 0 and energy / max or 0, energy
end

--endregion

return XTransfiniteTowerAgency
