---@class XTheatre6SubPvpModel : XModel
---@field _MainModel XTheatre6Model
---@field private _ActivityData Theatre6PvpActivityData|nil PVP活动数据
---@field private _CurrentLineupDict table<number, XTheatre6PvpCurrentLineupData> 当前阵容数据（key=LineupMode）
---@field private _BattleRecords table<number,XTheatre6PvpBattleRecord> 战斗记录列表
---@field private _RankInfo XTheatre6PvpRankInfo|nil PVP总榜数据
local XTheatre6SubPvpModel = XClass(XModel, "XTheatre6SubPvpModel")

local SlotType = XEnumConst.Theatre6.SlotType
local AttackLineupSaveKey = "XTheatre6SubPvpModel_AttackLineup"

function XTheatre6SubPvpModel:OnInit()
    self._ActivityData = nil
    self._CurrentLineupDict = nil
    self._BattleRecords = nil
    self._RankInfo = nil
    self._SummaryDatas = nil
end

function XTheatre6SubPvpModel:ClearPrivate()
    --退出玩法后，重新进入玩法不用弹段位奖励弹窗
    self:ClearCurrentRankRewardGoods()
end

function XTheatre6SubPvpModel:ResetAll()
    self._ActivityData = nil
    self._CurrentLineupDict = nil
    self._BattleRecords = nil
    self._RankInfo = nil
    self._SummaryDatas = nil
    self._RecordBattleResults = nil
end

---@param activityData Theatre6PvpActivityData|nil
function XTheatre6SubPvpModel:UpdateActivityData(activityData)
    self._ActivityData = activityData
    self._ActivityData.IsExistActionPoint = true
    self:LoadAttackLineupFromLocal()
end

---@param buffId number|nil 环境效果BuffId
---@param slots XTheatre6PvpFileSlot[]|nil 防守阵容槽位数据
function XTheatre6SubPvpModel:UpdateDefenseSlots(buffId, slots)
    if not self._ActivityData then
        self._ActivityData = {}
    end
    self._ActivityData.DefenseBuffId = buffId or 0
    self._ActivityData.Lineups = slots or {}
    self:UpdateCurrentLineupData(XEnumConst.Theatre6.Pvp.LineupMode.Defend, slots, buffId)
end

---@param matchResult XTheatre6PvpMatchResult|nil 匹配结果数据
---@param lastRefreshMatchTime number 刷新匹配的时间戳
---@param refreshRemainSeconds number 距下次可再次刷新的剩余秒数（0=当前可刷新）
function XTheatre6SubPvpModel:UpdateMatchResult(matchResult, lastRefreshMatchTime, refreshRemainSeconds)
    if not matchResult then
        return
    end
    if not self._ActivityData then
        self._ActivityData = {}
    end
    self._ActivityData.Enemies = matchResult.Enemies or {}
    if lastRefreshMatchTime then
        self._ActivityData.LastRefreshMatchTime = lastRefreshMatchTime
    end
    if refreshRemainSeconds then
        self._ActivityData.RefreshRemainSeconds = refreshRemainSeconds
    end
end

---@param actionPointInfo ActionPointInfo|nil
function XTheatre6SubPvpModel:UpdateActionPointInfo(actionPointInfo)
    if not actionPointInfo then
        return
    end
    if not self._ActivityData then
        self._ActivityData = {}
    end
    self._ActivityData.IsExistActionPoint = true
    self._ActivityData.ActionPoint = actionPointInfo.ActionPoint
    self._ActivityData.LastActionPointRecoverTime = actionPointInfo.LastActionPointRecoverTime
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_PVP_ACTION_POINT_UPDATE)
end

---@param tinyBattleState Theatre6PvpTinyBattleState|nil
function XTheatre6SubPvpModel:UpdateTinyBattleState(tinyBattleState)
    if not self._ActivityData then
        self._ActivityData = {}
    end
    self._ActivityData.TinyBattleState = tinyBattleState
end

---@param battleStats XTheatre6PvpBattleCountStats|nil
function XTheatre6SubPvpModel:UpdateBattleStats(battleStats)
    if not battleStats then
        return
    end
    if not self._ActivityData then
        self._ActivityData = {}
    end
    -- 仅包含本次大局结束有变化的字段，其余字段为 null，客户端应按字段为非 null 时全量覆盖处理。
    self._ActivityData.BattleStats = self._ActivityData.BattleStats or {}
    if battleStats.NormalBattleCounts then
        self._ActivityData.BattleStats.NormalBattleCounts = battleStats.NormalBattleCounts
    end
    if battleStats.NormalBattleWinCounts then
        self._ActivityData.BattleStats.NormalBattleWinCounts = battleStats.NormalBattleWinCounts
    end
    if battleStats.AdvanceBattleCounts then
        self._ActivityData.BattleStats.AdvanceBattleCounts = battleStats.AdvanceBattleCounts
    end
    if battleStats.AdvanceBattleWinCounts then
        self._ActivityData.BattleStats.AdvanceBattleWinCounts = battleStats.AdvanceBattleWinCounts
    end
end

--- 刷新当前阵容数据
---@param lineupMode number 阵容模式
---@param fileDataList Theatre6FileData[]|nil 存档数据列表
---@param buffId number|nil 环境效果BuffId
function XTheatre6SubPvpModel:UpdateCurrentLineupData(lineupMode, fileDataList, buffId)
    local lineupData = self:GetCurrentLineupData(lineupMode, true)
    if XTool.IsNumberValid(buffId) then
        lineupData.BuffId = buffId
    end
    if fileDataList then
        lineupData.LineupInfo = {} -- 先清空原有数据
        for index, fileData in ipairs(fileDataList) do
            lineupData.LineupInfo[index] = {
                CharacterId = fileData.CharacterId,
                SlotId = fileData.SlotId,
            }
        end
    end
end

function XTheatre6SubPvpModel:UpdateRank(rankId, rankScore)
    if not self._ActivityData then
        return
    end
    self._ActivityData.RankId = rankId
    self._ActivityData.Score = rankScore
end

function XTheatre6SubPvpModel:GetCurActivityId()
    return self._ActivityData and self._ActivityData.ActivityId or 0
end

function XTheatre6SubPvpModel:GetCurRankId()
    return self._ActivityData and self._ActivityData.RankId or 0
end

function XTheatre6SubPvpModel:GetCurScore()
    return self._ActivityData and self._ActivityData.Score or 0
end

function XTheatre6SubPvpModel:GetCurActionPoint()
    return self._ActivityData and self._ActivityData.ActionPoint or 0
end

function XTheatre6SubPvpModel:GetIsExistActionPoint()
    return self._ActivityData and self._ActivityData.IsExistActionPoint or false
end

function XTheatre6SubPvpModel:GetLastActionPointRecoverTime()
    return self._ActivityData and self._ActivityData.LastActionPointRecoverTime or 0
end

function XTheatre6SubPvpModel:GetSearchEnemies()
    return self._ActivityData and self._ActivityData.Enemies or {}
end

function XTheatre6SubPvpModel:GetLastRefreshMatchTime()
    return self._ActivityData and self._ActivityData.LastRefreshMatchTime or 0
end

function XTheatre6SubPvpModel:GetRefreshRemainSeconds()
    return self._ActivityData and self._ActivityData.RefreshRemainSeconds or 0
end

function XTheatre6SubPvpModel:GetDefenseLineups()
    return self._ActivityData and self._ActivityData.Lineups or {}
end

function XTheatre6SubPvpModel:GetAttackBuffId()
    return self._ActivityData and self._ActivityData.AttackBuffId or 0
end

function XTheatre6SubPvpModel:GetDefenseBuffId()
    return self._ActivityData and self._ActivityData.DefenseBuffId or 0
end

function XTheatre6SubPvpModel:GetTinyBattleState()
    return self._ActivityData and self._ActivityData.TinyBattleState
end

function XTheatre6SubPvpModel:ClearTinyBattleState()
    if self._ActivityData then
        self._ActivityData.TinyBattleState = nil
    end
end

function XTheatre6SubPvpModel:GetPvpRankRecord(activityId)
    if not self._ActivityData or not self._ActivityData.PvpRankRecords then
        return nil
    end
    return self._ActivityData.PvpRankRecords[activityId]
end

---@return XTheatre6PvpBattleCountStats|nil
function XTheatre6SubPvpModel:GetBattleStats()
    return self._ActivityData and self._ActivityData.BattleStats
end

--- 是否有活动数据
function XTheatre6SubPvpModel:HasActivityData()
    return self._ActivityData ~= nil and XTool.IsNumberValid(self._ActivityData.ActivityId)
end

function XTheatre6SubPvpModel:HasActivityPvpActionPoin()
    return self._ActivityData ~= nil and self._ActivityData.IsExistActionPoint
end

---@return XTheatre6PvpCurrentLineupData|nil
function XTheatre6SubPvpModel:GetCurrentLineupData(lineupMode, createIfNotExist)
    self._CurrentLineupDict = self._CurrentLineupDict or {}
    local lineupData = self._CurrentLineupDict[lineupMode]
    if not lineupData and createIfNotExist then
        lineupData = { LineupInfo = {}, BuffId = 0 }
        self._CurrentLineupDict[lineupMode] = lineupData
    end
    return lineupData
end

function XTheatre6SubPvpModel:GetActivityConfig()
    local activityId = self:GetCurActivityId()
    if not XTool.IsNumberValid(activityId) then
        return nil
    end
    return self._MainModel:GetPvpActivityConfig(activityId)
end

---整体获取对战记录
---@param battleRecords XTheatre6PvpBattleRecord[]
function XTheatre6SubPvpModel:UpdateBattleRecords(battleRecords)
    self._BattleRecords = {}
    for _, records in ipairs(battleRecords) do
        self._BattleRecords[records.BattleId] = records
    end
end

---增量更新对战记录
---@param battleRecords XTheatre6PvpBattleRecord[]
function XTheatre6SubPvpModel:AddBattleRecords(battleRecords)
    if not self._BattleRecords then
        self._BattleRecords = {}
    end
    for _, records in ipairs(battleRecords) do
        self._BattleRecords[records.BattleId] = records
    end
end

---@return table<number,XTheatre6PvpBattleRecord>
function XTheatre6SubPvpModel:GetBattleRecords()
    return self._BattleRecords
end

---@param rewardedRanks number[]|nil
function XTheatre6SubPvpModel:UpdateRewardedRanks(rewardedRanks, rewardGoods)
    if not self._ActivityData then
        self._ActivityData = {}
    end

    --self._ActivityData.RewardedRanks = XLazy.ToMap(rewardedRanks)
    self._ActivityData.RewardedRanks = {}
    if not XTool.IsTableEmpty(rewardedRanks) then
        for _, rankId in pairs(rewardedRanks) do
            self._ActivityData.RewardedRanks[rankId] = true
        end
    end

    self._ActivityData.CurrentRankRewardGoods = rewardGoods
end

---@return number[]
function XTheatre6SubPvpModel:GetRewardedRanks()
    return self._ActivityData and self._ActivityData.RewardedRanks or {}
end

function XTheatre6SubPvpModel:GetCurrentRankRewardGoods()
    return self._ActivityData and self._ActivityData.CurrentRankRewardGoods or nil
end

function XTheatre6SubPvpModel:ClearCurrentRankRewardGoods()
    if self._ActivityData then
        self._ActivityData.CurrentRankRewardGoods = nil
    end
end

function XTheatre6SubPvpModel:UpdateRankInfo(response)
    if not response then
        self._RankInfo = nil
        return
    end
    self._RankInfo = self._RankInfo or {}
    self._RankInfo.RankPlayerInfos = response.RankPlayerInfos or {}
    self._RankInfo.TotalCount = response.TotalCount or 0
    self._RankInfo.SelfRank = response.SelfRank or -1
end

---@return XTheatre6PvpRankInfo|nil
function XTheatre6SubPvpModel:GetRankInfo()
    return self._RankInfo
end

---怪物 SkillIds 转为存档技能数据，对齐服务端 Theatre6Skill.AddSkillSlot 的槽位优先级
---@param monsterConfig XTableTheatre6Monster
---@return XTheatre6Skill[]
function XTheatre6SubPvpModel:BuildMonsterSkillDataList(monsterConfig)
    if XTool.IsTableEmpty(monsterConfig.SkillIds) then
        return table.empty
    end

    local skills = {}
    local slotUsedCountDict = {}
    for _, skillId in ipairs(monsterConfig.SkillIds) do
        local skillConfig = self._MainModel:GetSkillCfgById(skillId)
        local sortConfigKey = self._MainModel.Skill:GetSkillSlotSortConfigKeys(skillConfig.Type)
        local slotSorts = self._MainModel:GetConfigValues(sortConfigKey)
        if not XTool.IsTableEmpty(slotSorts) then
            for _, slotTypeStr in ipairs(slotSorts) do
                local slotType = tonumber(slotTypeStr)
                local slotCapacity = self._MainModel.Skill:GetSlotCapacity(slotType)
                local usedCount = slotType and slotUsedCountDict[slotType] or 0
                local nextPosition = usedCount + 1
                if nextPosition <= slotCapacity then
                    table.insert(skills, {
                        SlotType = slotType,
                        Position = nextPosition,
                        SkillId = skillId,
                    })
                    slotUsedCountDict[slotType] = nextPosition
                    break
                end
            end
        end
    end

    return skills
end

---计算存档分数，对齐服务端 Theatre6Settle.DoCalcTotalScore
---@param fileData Theatre6FileData
---@return number
function XTheatre6SubPvpModel:DoCalcTotalScore(fileData)
    if not fileData then
        return 0
    end

    local totalScore = 0
    totalScore = totalScore + self:CalcAttrPackTotalScore(fileData.AttrPacks)
    totalScore = totalScore + self:CalcSkillTotalScore(fileData.Skills, fileData.CharacterId)
    totalScore = totalScore + self:CalcAttrTotalScore(fileData.Attrs)
    return totalScore
end

---@param attrPacks XTheatre6AttrPack[]
---@return number
function XTheatre6SubPvpModel:CalcAttrPackTotalScore(attrPacks)
    local totalScore = 0
    for _, attrPack in ipairs(attrPacks) do
        local attrPackConfig = self._MainModel:GetAttrPackConfig(attrPack.PackId)
        if attrPackConfig then
            totalScore = totalScore + (attrPackConfig.SaveScore or 0) * (attrPack.Num or 0)
        end
    end
    return totalScore
end

---@param skills XTheatre6Skill[]
---@param characterId number
---@return number
function XTheatre6SubPvpModel:CalcSkillTotalScore(skills, characterId)
    local totalScore = 0
    local activeSkillCount = 0

    for _, skill in pairs(skills) do
        if skill.SlotType ~= SlotType.Bag then
            local skillConfig = self._MainModel:GetSkillCfgById(skill.SkillId)
            if skillConfig then
                totalScore = totalScore + (skillConfig.SaveScore or 0)
                if skill.SlotType == SlotType.Active then
                    activeSkillCount = activeSkillCount + 1
                end
            end
        end
    end

    totalScore = totalScore + self:CalcInitSkillScore(characterId, activeSkillCount)
    return totalScore
end

---@param characterId number
---@param activeSkillCount number
---@return number
function XTheatre6SubPvpModel:CalcInitSkillScore(characterId, activeSkillCount)
    local characterConfig = self._MainModel:GetCharacterConfig(characterId)
    if not characterConfig then
        return 0
    end

    local initScore = 0
    activeSkillCount = activeSkillCount or 0
    for i = activeSkillCount + 1, #characterConfig.BaseSkill do
        local skillId = characterConfig.BaseSkill[i]
        if XTool.IsNumberValid(skillId) then
            local skillConfig = self._MainModel:GetSkillCfgById(skillId)
            if skillConfig then
                initScore = initScore + (skillConfig.SaveScore or 0)
            end
        end
    end
    return initScore
end

---@param attrs XTheatre6Attr[]
---@return number
function XTheatre6SubPvpModel:CalcAttrTotalScore(attrs)
    local totalScore = 0
    for _, attr in ipairs(attrs) do
        local attrConfig = self._MainModel:GetAttrConfig(attr.AttrId)
        if attrConfig then
            totalScore = totalScore + (attrConfig.SaveScore or 0) * (attr.Value or 0)
        end
    end
    return totalScore
end

function XTheatre6SubPvpModel:AddSummaryData(round, summaryData)
    self._SummaryDatas[round] = summaryData.Theatre6Record
end

function XTheatre6SubPvpModel:InitSummaryData()
    self._SummaryDatas = {}
end

function XTheatre6SubPvpModel:GetSummaryData()
    return self._SummaryDatas
end

---检查战斗记录是否完整
---如果有第1、3把数据，但没有第2把数据，则认为数据不完整
---如果有第1、2把数据，但没有第3把数据，则认为数据完整
function XTheatre6SubPvpModel:IsSummaryDataComplete(totalRound)
    if not XTool.IsNumberValid(totalRound) or XTool.IsTableEmpty(self._SummaryDatas) then
        return false
    end
    for i = 1, totalRound - 1 do
        if not self._SummaryDatas[i] and self._SummaryDatas[i + 1] then
            return false
        end
    end
    return true
end

function XTheatre6SubPvpModel:InitBattleResults()
    self._RecordBattleResults = nil
end

---缓存服务端发送的结果发给战斗
function XTheatre6SubPvpModel:RecordBattleResults(roundResults)
    self._RecordBattleResults = roundResults
end

function XTheatre6SubPvpModel:GetBattleResults()
    return self._RecordBattleResults
end

--- 从本地缓存恢复进攻阵容
function XTheatre6SubPvpModel:LoadAttackLineupFromLocal()
    local lineupData = self:GetCurrentLineupData(XEnumConst.Theatre6.Pvp.LineupMode.Attack, true)
    local cached = self._MainModel:GetPvpLocalRecordData(AttackLineupSaveKey)
    if cached then
        lineupData.LineupInfo = cached.LineupInfo or {}
        lineupData.BuffId = cached.BuffId
    end
    if not XTool.IsNumberValid(lineupData.BuffId) then
        lineupData.BuffId = self:GetAttackBuffId()
    end
end

--- 将当前进攻阵容写入本地缓存
function XTheatre6SubPvpModel:SaveAttackLineupToLocal()
    local lineupData = self:GetCurrentLineupData(XEnumConst.Theatre6.Pvp.LineupMode.Attack)
    if not lineupData then
        return
    end
    self._MainModel:SavePvpLocalRecordData(AttackLineupSaveKey, {
        BuffId = lineupData.BuffId,
        LineupInfo = lineupData.LineupInfo,
    })
end

function XTheatre6SubPvpModel:UpdateBattleResultData(curPvpRound, pvpFightResult, summaryData)
    self:RecordBattleResults(pvpFightResult.RoundResults)
    self:UpdateRewardedRanks(pvpFightResult.RewardedRanks, pvpFightResult.RankRewardGoods)
    self:AddSummaryData(curPvpRound, summaryData)
end

return XTheatre6SubPvpModel

---@class ActionPointInfo
---@field ActionPoint number PVP体力
---@field LastActionPointRecoverTime number 上次体力恢复时间戳（Unix秒）
---@field IsExistActionPoint bool 是否存在体力数值

---首次进入PVP下发的活动数据
---@class Theatre6PvpActivityData : ActionPointInfo
---@field ActivityId number 活动ID
---@field RankId number 段位ID
---@field Score number 分数（同段位内的积分）
---@field PlayerState number 玩家游戏状态
---@field TinyBattleState Theatre6PvpTinyBattleState|nil 当前进行中的PVP对战状态（nil=无进行中对战）
---@field Enemies XTheatre6PvpMatchEnemy[] 匹配到的敌人
---@field Lineups Theatre6FileData[]|nil 防守阵容
---@field RewardedRanks number[] 已领取段位奖励的段位ID列表
---@field LastRefreshMatchTime number 上次进攻搜索刷新时间
---@field RefreshRemainSeconds number 距下次可再次刷新的剩余秒数（0=当前可刷新）
---@field AttackBuffId number 进攻环境效果默认选择
---@field DefenseBuffId number|nil 防守环境效果默认选择
---@field PvpRankRecords table<number, XTheatre6PvpRankRecord> 历史段位记录，用于客户端条件解锁判断
---@field BattleStats XTheatre6PvpBattleCountStats PVP战斗次数统计，用于客户端条件解锁判断

--- 当前进行中的PVP对战状态
---@class Theatre6PvpTinyBattleState
---@field EnemyId number 对手编号
---@field EnemyData XTheatre6PvpPlayerBattleDb 对手数据快照
---@field MyLineups Theatre6FileData[] 我方上阵存档序列
---@field RoundResults boolean[] 每局结果（true=胜利）
---@field CurrentRound number 当前第几局（从1开始）
---@field IsFinished boolean 是否已结算

---阵容槽位标识
---@class XTheatre6PvpFileSlot
---@field CharacterId number 角色ID
---@field SlotId number 存档槽位ID

---PVP积分变化明细
---@class XTheatre6PvpScoreDetail
---@field BaseWinScore number 基础胜利分
---@field EloScore number ELO战斗过程分
---@field AllWinScore number 全胜奖励分
---@field DefenseScore number 防守分数

---匹配池中的玩家条目
---@class XTheatre6PvpPlayerBattleDb
---@field PlayerId number 玩家ID
---@field UpdateTime number 更新时间
---@field Name string 玩家名
---@field HeadPortraitId number 头像
---@field HeadFrameId number 头像框
---@field RankId number 段位ID
---@field Score number 分数
---@field SaveFiles Theatre6FileData[] 3个存档
---@field RobotId number 机器人ID（非机器人时为0）
---@field DefenseBuffId number 环境效果

---匹配到的单个对手封装
---@class XTheatre6PvpMatchEnemy
---@field Uid number 对手唯一标识
---@field BattleData XTheatre6PvpPlayerBattleDb 对手战斗数据
---@field MistNum number 防守迷雾

---匹配结果
---@class XTheatre6PvpMatchResult
---@field Code number 错误码
---@field Enemies XTheatre6PvpMatchEnemy[] 匹配到的对手列表

---存档数据
---@class Theatre6FileData
---@field SlotId number 槽位
---@field CharacterId number 角色ID
---@field Score number 存档分数
---@field BuildTags number[] 标签
---@field Attrs XTheatre6Attr[] 属性
---@field Skills XTheatre6Skill[] 技能
---@field AttrPacks XTheatre6AttrPack[] 遗物
---@field Buffs XTheatre6BuffSaveData[] Buff
---@field FashionId number 时装ID

---@class XTheatre6Skill
---@field SlotType number 技能槽位类型
---@field Position number 位置
---@field SkillId number 技能ID

---@class XTheatre6Attr
---@field AttrId number 属性ID
---@field Value number 属性值

---@class XTheatre6AttrPack
---@field PackId number 遗物ID
---@field Num number 数量

---@class XTheatre6BuffSaveData
---@field BuffId number Buff ID
---@field TriggerCount number 触发次数
---@field AddMagic number 增益（万分比）

---阵容数据
---@class XTheatre6PvpCurrentLineupData
---@field BuffId number 环境效果BuffId
---@field LineupInfo table<number, XTheatre6PvpFileSlot> 阵容槽位信息列表（索引从1开始，最多3个）

---PVP战斗记录
---@class XTheatre6PvpBattleRecord
---@field BattleTime number 战斗时间戳（Unix秒）
---@field IsAttacker boolean 是否为进攻方
---@field IsWin boolean 是否胜利
---@field ScoreChange number 积分变化
---@field EnemyInfo XTheatre6PvpPlayerBattleDb 对手数据快照
---@field MyRankId number 战斗时我方段位ID

---PVP排行榜玩家信息
---@class XTheatre6PvpRankPlayer
---@field Id number 玩家ID
---@field Name string 玩家名
---@field HeadPortraitId number 头像
---@field HeadFrameId number 头像框
---@field Score number 分数

---PVP排行榜数据
---@class XTheatre6PvpRankInfo
---@field RankPlayerInfos XTheatre6PvpRankPlayer[] 榜单玩家列表
---@field TotalCount number 榜单总人数
---@field SelfRank number 自己排名（-1=未上榜）

---PVP历史段位记录
---@class XTheatre6PvpRankRecord
---@field RankId number 当前段位ID
---@field Score number 当前分数

---PVP战斗次数统计
---@class XTheatre6PvpBattleCountStats
---@field NormalBattleCounts table<number, number> 普通战斗总次数（key=段位ID, value=次数）
---@field NormalBattleWinCounts table<number, number> 普通战斗胜利次数（key=段位ID, value=次数）
---@field AdvanceBattleCounts table<number, number> 进阶战斗总次数（key=段位ID, value=次数）
---@field AdvanceBattleWinCounts table<number, number> 进阶战斗胜利次数（key=段位ID, value=次数）

