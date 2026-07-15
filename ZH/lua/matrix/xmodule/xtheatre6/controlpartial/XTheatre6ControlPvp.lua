---Control部分类，此处用于处理PVP相关逻辑
---@type XTheatre6Control
local XTheatre6Control = XClassPartial('XTheatre6Control')

function XTheatre6Control:OnInitPvp()
    self:StartPvpActionPointRecoverTimer()
end

function XTheatre6Control:OnReleasePvp()
    self:StopPvpActionPointRecoverTimer()
    self._RobotFileDataCache = nil
end

function XTheatre6Control:GetPvpActivityEndTime()
    local timeId = self:GetPvpActivityTimeId()
    return XFunctionManager.GetEndTimeByTimeId(timeId)
end

function XTheatre6Control:IsPvpInActivityTime()
    local timeId = self:GetPvpActivityTimeId()
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

---@return Theatre6FileData[]
function XTheatre6Control:GetAllFileData()
    return self._Model:GetAllFileData()
end

--- 检查PVP模式是否解锁
function XTheatre6Control:CheckPvpModeUnlock()
    local conditionId = self:GetIntPvpConfigValue("UnlockPvpModeConditionId")
    if not XTool.IsNumberValid(conditionId) then
        return true
    end
    return XConditionManager.CheckCondition(conditionId)
end

--region PVP段位相关
function XTheatre6Control:GetPvpCurRankId()
    return self._Model.Pvp:GetCurRankId()
end

function XTheatre6Control:GetPvpCurScore()
    return self._Model.Pvp:GetCurScore()
end

function XTheatre6Control:GetCurrentRankConfig()
    local rankId = self:GetPvpCurRankId()
    if not XTool.IsNumberValid(rankId) then
        return nil
    end
    return self:GetPvpRankConfig(rankId)
end

function XTheatre6Control:GetNextRankConfig()
    local rankId = self:GetPvpCurRankId()
    if not XTool.IsNumberValid(rankId) then
        return nil
    end
    return self:GetPvpRankConfig(rankId + 1, true)
end

function XTheatre6Control:GetPvpRankRewardIds()
    local rankConfig = self:GetNextRankConfig()
    return rankConfig and rankConfig.RewardIds or {}
end

function XTheatre6Control:GetPvpRankMistNum()
    local rankConfig = self:GetCurrentRankConfig()
    return rankConfig and rankConfig.MistNum or 0
end

--- 是否处于PVP挑战状态
function XTheatre6Control:IsPVPChallengeState()
    local rankConfig = self:GetCurrentRankConfig()
    if not rankConfig or not XTool.IsNumberValid(rankConfig.MaxScore) then
        return false
    end

    local score = self:GetPvpCurScore()
    if score < rankConfig.MaxScore then
        return false
    end

    local nextConfig = self:GetNextRankConfig()
    if not nextConfig then
        return false
    end
    local timeId = nextConfig.TimeId
    if not XTool.IsNumberValid(timeId) then
        return true
    end

    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

--- 当前段位的PVP增益BuffGroupId是否有效
function XTheatre6Control:IsPvpBuffGroupIdValid()
    local rankConfig = self:GetCurrentRankConfig()
    return rankConfig and XTool.IsNumberValid(rankConfig.PvpBuffGroupId)
end

---获取敌方存档列表（如果是机器人则生成对应的存档数据）
---@param enemyData XTheatre6PvpPlayerBattleDb
function XTheatre6Control:GetEnemySaveFiles(enemyData)
    if XTool.IsNumberValid(enemyData.RobotId) then
        return self:BuiltRobotSaveFiles(enemyData.RobotId)
    end
    return enemyData.SaveFiles
end

---生成机器人存档
---@return Theatre6FileData[]
function XTheatre6Control:BuiltRobotSaveFiles(robotId)
    if not self._RobotFileDataCache then
        self._RobotFileDataCache = {}
    end

    ---@type Theatre6FileData[]
    local fileDatas = self._RobotFileDataCache[robotId]
    if fileDatas then
        return fileDatas
    end

    fileDatas = {}
    local robotConfig = self:GetRobotConfig(robotId)
    for index = 1, 3 do
        local monsterId = robotConfig.UseMonsterIds[index]
        local monsterConfig = self:GetMonsterConfig(monsterId)

        ---@type Theatre6FileData
        local fileData = {}
        fileData.SlotId = index
        fileData.CharacterId = monsterConfig.CharacterId
        fileData.FashionId = self._Model:GetCharacterConfig(monsterConfig.CharacterId).FashionIds[1]
        fileData.BuildTags = monsterConfig.BuildTags
        fileData.Attrs = {}
        for attrId, value in pairs(monsterConfig.AttrTypes or {}) do
            table.insert(fileData.Attrs, {
                AttrId = attrId,
                Value = value,
            })
        end
        fileData.AttrPacks = {}
        for i, packId in ipairs(monsterConfig.AttrPacks) do
            table.insert(fileData.AttrPacks, {
                PackId = packId,
                Num = monsterConfig.AttrPackNums[i],
            })
        end
        fileData.Skills = self._Model.Pvp:BuildMonsterSkillDataList(monsterConfig)
        fileData.Score = self._Model.Pvp:DoCalcTotalScore(fileData)
        table.insert(fileDatas, fileData)
    end

    self._RobotFileDataCache[robotId] = fileDatas
    return fileDatas
end
--endregion

--region PVP匹配相关
function XTheatre6Control:GetPvpSearchEnemies()
    return self._Model.Pvp:GetSearchEnemies()
end

function XTheatre6Control:GetPvpRefreshRemainSeconds()
    return self._Model.Pvp:GetRefreshRemainSeconds()
end

--- 获取刷新匹配的剩余冷却时间（秒）
function XTheatre6Control:GetPvpRefreshMatchRemainCd()
    local lastTime = self._Model.Pvp:GetLastRefreshMatchTime()
    if not XTool.IsNumberValid(lastTime) then
        return -1
    end
    local cd = self:GetPvpRefreshRemainSeconds()
    if not XTool.IsNumberValid(cd) then
        return -1
    end
    local remain = lastTime + cd - XTime.GetServerNowTimestamp()
    return remain
end

--- 获取玩家背景展示的立绘
---@param fileDataList Theatre6FileData[]
function XTheatre6Control:GetPvpPlayerBigPortrait(fileDataList, mistNum, slotIndex)
    if not fileDataList then
        return nil
    end
    if self:IsPVPSlotMist(fileDataList, mistNum, slotIndex) then
        return self:GetPvpClientConfigValue("EnemyDefaultBigPortrait")
    end
    local fileData = fileDataList[slotIndex]
    local characterId = fileData and fileData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        return nil
    end
    local characterConfig = self:GetCharacterConfig(characterId)
    local fashionConfig = self:GetFashionConfig(characterConfig.FashionIds[1])
    return fashionConfig and fashionConfig.PvpBigPortrait
end

--- 槽位是否是迷雾
---@param fileDataList Theatre6FileData[]
function XTheatre6Control:IsPVPSlotMist(fileDataList, mistNum, slotIndex)
    if not fileDataList or not XTool.IsNumberValid(slotIndex) or mistNum <= 0 then
        return false
    end
    local fileDataNum = #fileDataList
    if slotIndex > fileDataNum then
        return false
    end
    return slotIndex > fileDataNum - mistNum
end

---@return Theatre6PvpTinyBattleState
function XTheatre6Control:GetPvpTinyBattleState()
    return self._Model.Pvp:GetTinyBattleState()
end

--- 是否处于PVP对战中
function XTheatre6Control:IsPvpInTinyBattle()
    local tinyBattleState = self:GetPvpTinyBattleState()
    return not XTool.IsTableEmpty(tinyBattleState)
end

--- 清理PVP对战状态数据（如对局结束后）
function XTheatre6Control:ClearPvpTinyBattleState()
    self._Model.Pvp:ClearTinyBattleState()
end

---对局玩家个人对战信息
function XTheatre6Control:GetBattleRecords()
    return self._Model.Pvp:GetBattleRecords()
end

---对局玩家伤害信息
function XTheatre6Control:GetSummaryData()
    return self._Model.Pvp:GetSummaryData()
end
--endregion

--region PVP体力相关
function XTheatre6Control:GetPvpCurActionPoint()
    return self._Model.Pvp:GetCurActionPoint()
end

function XTheatre6Control:GetPvpIsExistActionPoint()
    return self._Model.Pvp:GetIsExistActionPoint()
end

function XTheatre6Control:GetPvpMaxActionPoint()
    return self:GetIntPvpConfigValue("ActionPointMaxLimit")
end

function XTheatre6Control:GetPvpLastActionPointRecoverTime()
    return self._Model.Pvp:GetLastActionPointRecoverTime()
end

function XTheatre6Control:GetPvpActionPointRecoverInterval()
    return self:GetIntPvpConfigValue("ActionPointRecoverInterval")
end

--- PVP体力是否已满
function XTheatre6Control:IsPvpActionPointFull()
    local cur = self:GetPvpCurActionPoint()
    local max = self:GetPvpMaxActionPoint()
    return XTool.IsNumberValid(max) and cur >= max
end

--- 启动PVP体力恢复定时器
--- 服务端不会主动下推体力恢复，需要客户端按上次恢复时间戳倒计时，到点后主动请求服务端恢复体力
function XTheatre6Control:StartPvpActionPointRecoverTimer()
    self:StopPvpActionPointRecoverTimer()
    self._PvpActionPointRecoverTimer = XScheduleManager.ScheduleForever(handler(self, self.CheckPvpActionPointRecover), XScheduleManager.SECOND)
end

function XTheatre6Control:StopPvpActionPointRecoverTimer()
    if self._PvpActionPointRecoverTimer then
        XScheduleManager.UnSchedule(self._PvpActionPointRecoverTimer)
        self._PvpActionPointRecoverTimer = nil
    end
    self._LastPvpActionPointRequestTime = nil
end

--- 倒计时结束后请求服务端恢复体力（延后1秒避免误差）
function XTheatre6Control:CheckPvpActionPointRecover()
    -- 活动不在开启时间内则不请求体力
    if not self:IsPvpInActivityTime() then
        return
    end
    if not self._Model.Pvp:HasActivityPvpActionPoin() then
        return
    end
    if self:IsPvpActionPointFull() then
        return
    end
    local lastRecoverTime = self:GetPvpLastActionPointRecoverTime()
    local interval = self:GetPvpActionPointRecoverInterval()
    if not XTool.IsNumberValid(lastRecoverTime) or not XTool.IsNumberValid(interval) then
        return
    end
    local now = XTime.GetServerNowTimestamp()
    if now < lastRecoverTime + interval + 1 then
        return
    end
    -- 请求未返回前避免按秒重复发送
    if self._LastPvpActionPointRequestTime and now - self._LastPvpActionPointRequestTime < 10 then
        return
    end
    self._LastPvpActionPointRequestTime = now
    self:RequestPvpGetActionPoint()
end
--endregion

--region PVP阵容相关
--- 获取当前上阵的存档列表
---@return XTheatre6PvpFileSlot[]
function XTheatre6Control:GetPvpCurrentLineupInfo(lineupMode)
    local curLineupData = self._Model.Pvp:GetCurrentLineupData(lineupMode)
    return curLineupData and curLineupData.LineupInfo or {}
end

--- 获取当前上阵的环境效果BuffId
function XTheatre6Control:GetPvpCurrentLineupBuffId(lineupMode)
    local curLineupData = self._Model.Pvp:GetCurrentLineupData(lineupMode)
    return curLineupData and curLineupData.BuffId or 0
end

---@return Theatre6FileData[]
function XTheatre6Control:GetPvpCurrentLineupFileDataList(lineupMode)
    local lineupInfo = self:GetPvpCurrentLineupInfo(lineupMode)
    if XTool.IsTableEmpty(lineupInfo) then
        return {}
    end

    local fileDataList = {}
    for index, info in pairs(lineupInfo) do
        local fileData = self._Model:GetFileDataBySlot(info.CharacterId, info.SlotId)
        if fileData then
            fileDataList[index] = fileData
        end
    end
    return fileDataList
end

--- 获取当前上阵存档实际数量
function XTheatre6Control:GetPvpCurrentLineupCount(lineupMode)
    local lineupInfo = self:GetPvpCurrentLineupInfo(lineupMode)
    if XTool.IsTableEmpty(lineupInfo) then
        return 0
    end
    local count = 0
    for _ in pairs(lineupInfo) do
        count = count + 1
    end
    return count
end

--- 尝试更新当前上阵的存档列表
function XTheatre6Control:TryPvpUpCurrentLineupInfo(lineupMode, fileData, targetIndex)
    if not fileData or not XTool.IsNumberValid(targetIndex) then
        return false
    end
    local curLineupData = self._Model.Pvp:GetCurrentLineupData(lineupMode, true)
    curLineupData.LineupInfo[targetIndex] = {
        CharacterId = fileData.CharacterId,
        SlotId = fileData.SlotId,
    }
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE, lineupMode, true)
    return true
end

--- 尝试更新当前上阵的环境效果BuffId
function XTheatre6Control:TryPvpUpCurrentLineupBuffId(lineupMode, buffId)
    if not XTool.IsNumberValid(buffId) then
        return false
    end
    local curLineupData = self._Model.Pvp:GetCurrentLineupData(lineupMode, true)
    curLineupData.BuffId = buffId
    return true
end

--- 移除当前上阵的指定索引的存档
function XTheatre6Control:RemovePvpCurrentLineupInfo(lineupMode, targetIndex)
    if not XTool.IsNumberValid(targetIndex) then
        return false
    end
    local curLineupData = self._Model.Pvp:GetCurrentLineupData(lineupMode)
    if not curLineupData or not curLineupData.LineupInfo[targetIndex] then
        return false
    end
    curLineupData.LineupInfo[targetIndex] = nil
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE, lineupMode, false)
    return true
end

--- 获取当前上阵的存档索引列表
function XTheatre6Control:GetPvpCurrentLineupInfoIndexes(lineupMode, characterId, slotId)
    local lineupInfo = self:GetPvpCurrentLineupInfo(lineupMode)
    if XTool.IsTableEmpty(lineupInfo) then
        return {}
    end

    local indexes = {}
    for index, info in pairs(lineupInfo) do
        if info.CharacterId == characterId and info.SlotId == slotId then
            table.insert(indexes, index)
        end
    end
    table.sort(indexes)
    return indexes
end

--- 获取当前上阵的存档数量
function XTheatre6Control:GetPvpCurrentLineupInfoCount(lineupMode, characterId, slotId)
    local lineupInfo = self:GetPvpCurrentLineupInfo(lineupMode)
    if XTool.IsTableEmpty(lineupInfo) then
        return 0
    end

    local count = 0
    for _, info in pairs(lineupInfo) do
        if info.CharacterId == characterId and info.SlotId == slotId then
            count = count + 1
        end
    end
    return count
end

--- 获取当前上阵的存档中，去重后的唯一角色-槽位组合数量
function XTheatre6Control:GetPvpCurrentLineupCharacterSlotCount(lineupMode)
    local lineupInfo = self:GetPvpCurrentLineupInfo(lineupMode)
    if XTool.IsTableEmpty(lineupInfo) then
        return 0
    end

    local count = 0
    local archiveMap = {}
    for _, info in pairs(lineupInfo) do
        local slotMap = archiveMap[info.CharacterId]
        if not slotMap then
            slotMap = {}
            archiveMap[info.CharacterId] = slotMap
        end
        if not slotMap[info.SlotId] then
            slotMap[info.SlotId] = true
            count = count + 1
        end
    end
    return count
end

--- 获取当前上阵的存档中，去重后的唯一角色-槽位组合的上阵限制数量
function XTheatre6Control:GetPvpCurrentLineupCharacterSlotLimit(lineupMode)
    if lineupMode == XEnumConst.Theatre6.Pvp.LineupMode.Defend then
        return self:GetPvpMaxSlotDefenseLineupLimit()
    else
        return self:GetPvpSlotAttackLineupLimit()
    end
end

function XTheatre6Control:GetPvpLineupSlotRepeatLimit()
    return self:GetIntPvpConfigValue("LineupSlotRepeatLimit")
end

function XTheatre6Control:GetPvpSlotAttackLineupLimit()
    return self:GetIntPvpConfigValue("SlotAttackLineupLimit")
end

function XTheatre6Control:GetPvpMaxSlotDefenseLineupLimit()
    return self:GetIntPvpConfigValue("MaxSlotDefenseLineupLimit")
end

---交换两个槽位上的存档
function XTheatre6Control:SwapPvpCurrentLineupSlots(lineupMode, fromIndex, toIndex)
    if fromIndex == toIndex or not XTool.IsNumberValid(fromIndex) or not XTool.IsNumberValid(toIndex) then
        return false
    end
    local lineupInfo = self:GetPvpCurrentLineupInfo(lineupMode)
    if XTool.IsTableEmpty(lineupInfo) then
        return false
    end
    local fromInfo, toInfo = lineupInfo[fromIndex], lineupInfo[toIndex]
    if not fromInfo and not toInfo then
        return false
    end
    lineupInfo[fromIndex], lineupInfo[toIndex] = toInfo, fromInfo
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE, lineupMode, false)
    return true
end

---将指定存档一次性放入多个槽位
---@param lineupMode number
---@param fileData Theatre6FileData 要上阵的存档
---@param slotIndexes number[] 目标槽位索引列表
---@return boolean
function XTheatre6Control:ReplacePvpCurrentLineupSlots(lineupMode, fileData, slotIndexes)
    if not fileData or XTool.IsTableEmpty(slotIndexes) then
        return false
    end
    local curLineupData = self._Model.Pvp:GetCurrentLineupData(lineupMode, true)
    for _, slotIndex in ipairs(slotIndexes) do
        if XTool.IsNumberValid(slotIndex) then
            curLineupData.LineupInfo[slotIndex] = {
                CharacterId = fileData.CharacterId,
                SlotId = fileData.SlotId,
            }
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE, lineupMode, false)
    return true
end

--- 当前存档是否已达到上阵上限
function XTheatre6Control:IsPvpArchiveReachLineupLimit(lineupMode, characterId, slotId)
    local lineupCount = self:GetPvpCurrentLineupInfoCount(lineupMode, characterId, slotId)
    local lineupLimit = self:GetPvpLineupSlotRepeatLimit()
    return lineupCount >= lineupLimit
end

--- 当前存档是否已经上阵
function XTheatre6Control:IsPvpArchiveCurrentLineup(lineupMode, characterId, slotId)
    local lineupInfo = self:GetPvpCurrentLineupInfo(lineupMode)
    if XTool.IsTableEmpty(lineupInfo) then
        return false
    end

    for _, info in pairs(lineupInfo) do
        if info.CharacterId == characterId and info.SlotId == slotId then
            return true
        end
    end
    return false
end

--- 当前存档是否已经上阵在指定索引位置
function XTheatre6Control:IsPvpArchiveInCurrentLineupSlot(lineupMode, characterId, slotId, targetIndex)
    local lineupInfo = self:GetPvpCurrentLineupInfo(lineupMode)
    if XTool.IsTableEmpty(lineupInfo) or not XTool.IsNumberValid(targetIndex) then
        return false
    end

    local info = lineupInfo[targetIndex]
    return info and info.CharacterId == characterId and info.SlotId == slotId
end

--- 检查防守阵容上阵信息是否有变化
function XTheatre6Control:CheckPvpDefenseLineupChange()
    local curLineupInfo = self:GetPvpCurrentLineupInfo(XEnumConst.Theatre6.Pvp.LineupMode.Defend)
    local defenseLineups = self._Model.Pvp:GetDefenseLineups()
    local maxLimit = self:GetPvpMaxSlotDefenseLineupLimit()
    for index = 1, maxLimit do
        local curInfo = curLineupInfo[index]
        local oldInfo = defenseLineups[index]
        if (curInfo == nil) ~= (oldInfo == nil) then
            return true
        end
        if curInfo and (curInfo.CharacterId ~= oldInfo.CharacterId or curInfo.SlotId ~= oldInfo.SlotId) then
            return true
        end
    end
    return false
end

--- 判断指定 (角色ID, 槽位ID) 是否属于当前防守阵容
---@param characterId number
---@param slotId number
---@return boolean
function XTheatre6Control:CheckArchiveInDefenseLineup(characterId, slotId)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(slotId) then
        return false
    end

    local defenseLineups = self._Model.Pvp:GetDefenseLineups()

    if not XTool.IsTableEmpty(defenseLineups) then
        for _, fileData in ipairs(defenseLineups) do
            if fileData.CharacterId == characterId and fileData.SlotId == slotId then
                return true
            end
        end
    end

    return false
end

---获取防守存档标识图标
---@return string
function XTheatre6Control:GetDefenseArchiveIcon()
    return self._Model:GetClientConfigValue("DefenseArchiveIcon") or ""
end

--- 同步防守阵容上阵信息
function XTheatre6Control:SyncPvpDefenseLineup()
    local defenseLineups = self._Model.Pvp:GetDefenseLineups()
    local defenseBuffId = self._Model.Pvp:GetDefenseBuffId()
    self._Model.Pvp:UpdateCurrentLineupData(XEnumConst.Theatre6.Pvp.LineupMode.Defend, defenseLineups, defenseBuffId)
end

--- 模拟将存档放入目标索引后，检查上阵信息是否满足限制
--- 上阵存档数达上限时，弹出toast【最多上阵N个存档】
--- 单个存档上阵次数达上限时，弹出toast【每个存档最多上阵N次】
function XTheatre6Control:CheckPvpArchiveBeforeLineup(lineupMode, characterId, slotId, targetIndex)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(slotId) or not XTool.IsNumberValid(targetIndex) then
        return false, ""
    end

    -- 构造模拟阵容：把 (characterId, slotId) 放到 targetIndex 上
    local simulatedLineup = {}
    local newInfo = { CharacterId = characterId, SlotId = slotId }
    local hasTargetIndex = false
    local curLineupInfo = self:GetPvpCurrentLineupInfo(lineupMode)
    if not XTool.IsTableEmpty(curLineupInfo) then
        for index, info in pairs(curLineupInfo) do
            if index == targetIndex then
                simulatedLineup[index] = newInfo
                hasTargetIndex = true
            else
                simulatedLineup[index] = info
            end
        end
    end
    if not hasTargetIndex then
        simulatedLineup[targetIndex] = newInfo
    end

    -- 统计存档数与最大重复次数
    local archiveCountMap = {}
    local uniqueCount = 0
    local maxRepeatCount = 0
    for _, info in pairs(simulatedLineup) do
        local slotCountMap = archiveCountMap[info.CharacterId]
        if not slotCountMap then
            slotCountMap = {}
            archiveCountMap[info.CharacterId] = slotCountMap
        end
        local count = (slotCountMap[info.SlotId] or 0) + 1
        if count == 1 then
            uniqueCount = uniqueCount + 1
        end
        slotCountMap[info.SlotId] = count
        if count > maxRepeatCount then
            maxRepeatCount = count
        end
    end

    local uniqueLimit = self:GetPvpCurrentLineupCharacterSlotLimit(lineupMode)
    if XTool.IsNumberValid(uniqueLimit) and uniqueCount > uniqueLimit then
        local tips = self:GetPvpClientConfigValue("ArchiveLineupLimitTips")
        return false, string.format(tips, uniqueLimit)
    end

    local repeatLimit = self:GetPvpLineupSlotRepeatLimit()
    if XTool.IsNumberValid(repeatLimit) and maxRepeatCount > repeatLimit then
        local tips = self:GetPvpClientConfigValue("ArchiveReachLineupLimitTips")
        return false, string.format(tips, repeatLimit)
    end

    return true
end

--- 一键上阵
--- 进攻/防守 将玩家分数最高的两个存档,按照从左至右的顺序进行进攻上阵，第一个存档上阵两次。
function XTheatre6Control:OneClickPvpLineup(lineupMode, fileDataList)
    if XTool.IsTableEmpty(fileDataList) then
        return false
    end

    ---@type Theatre6FileData[]
    local sortedFileDataList = {}
    for _, fileData in pairs(fileDataList) do
        table.insert(sortedFileDataList, fileData)
    end
    table.sort(sortedFileDataList, function(a, b)
        if a.Score ~= b.Score then
            return a.Score > b.Score
        end
        return a.CharacterId > b.CharacterId
    end)

    -- 进攻/防守都只取分数最高的两个存档（如果有），且第一个存档（分数最高）额外再上阵一次
    local topArchiveCount = 2
    local takeCount = math.min(topArchiveCount, #sortedFileDataList)
    if takeCount <= 0 then
        return false
    end

    local lineupInfo = {}
    for i = 1, takeCount do
        lineupInfo[i] = sortedFileDataList[i]
    end

    -- 进攻/防守逻辑一致：第一个存档（分数最高）上阵两次
    table.insert(lineupInfo, 1, sortedFileDataList[1])

    local buffId
    if lineupMode == XEnumConst.Theatre6.Pvp.LineupMode.Attack then
        buffId = self._Model.Pvp:GetAttackBuffId()
    else
        buffId = self._Model.Pvp:GetDefenseBuffId()
    end
    self._Model.Pvp:UpdateCurrentLineupData(lineupMode, lineupInfo, buffId)
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE, lineupMode, false)
    return true
end

--- 一键下阵：清空当前阵容的所有上阵存档
function XTheatre6Control:ClearPvpCurrentLineupInfo(lineupMode)
    local curLineupData = self._Model.Pvp:GetCurrentLineupData(lineupMode)
    if not curLineupData or XTool.IsTableEmpty(curLineupData.LineupInfo) then
        return false
    end
    curLineupData.LineupInfo = {}
    XEventManager.DispatchEvent(XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE, lineupMode, false)
    return true
end
--endregion

--region PVP排行榜与战斗记录
---@return XTheatre6PvpRankInfo|nil
function XTheatre6Control:GetPvpRankInfo()
    return self._Model.Pvp:GetRankInfo()
end

---@return number[]
function XTheatre6Control:GetPvpRewardedRanks()
    return self._Model.Pvp:GetRewardedRanks()
end

function XTheatre6Control:GetCurrentRankRewardGoods()
    return self._Model.Pvp:GetCurrentRankRewardGoods()
end

function XTheatre6Control:GetPvpRankConfigs(isSort)
    local configs = self._Model:GetPvpRankConfigs()
    local result = {}

    if not XTool.IsTableEmpty(configs) then
        for id, config in pairs(configs) do
            result[id] = config
        end
    end

    if isSort then
        table.sort(result, function(rankA, rankB)
            return rankA.MinScore <= rankB.MinScore
        end)
    end

    return result
end

function XTheatre6Control:OpenPvpRank()
    self:RequestPvpQueryRank(function()
        XLuaUiManager.Open("UiTheatre6PVPRank")
    end)
end

function XTheatre6Control:OpenPvpRankDetail()
    XLuaUiManager.Open("UiTheatre6PVPRankDetail")
end

function XTheatre6Control:TryPopupRankReward()
    local rewardGoodsList = self:GetCurrentRankRewardGoods()

    if not XTool.IsTableEmpty(rewardGoodsList) then
        XLuaUiManager.Open("UiTheatre6PopupGetReward", rewardGoodsList, nil)
        self._Model.Pvp:ClearCurrentRankRewardGoods()
    end
end

--endregion

--region PVP结算相关

---获取回合结算伤害列表（与pve不同 这里传进来的是C#对象）
function XTheatre6Control:GetPvpRoundSettlementDamageList(roleData, isSkillReadOnly)
    local damageList = {}
    local skillDamageRecord = self:TryGetCSDictValue(roleData.DamageRecord, 0, table.empty)
    local buffDamageRecord = self:TryGetCSDictValue(roleData.DamageRecord, 1, table.empty)
    local skillEnergyRecord = self:TryGetCSDictValue(roleData.EnergyCastRecord, 0, table.empty)
    local buffEnergyRecord = self:TryGetCSDictValue(roleData.EnergyCastRecord, 1, table.empty)
    local skillCountRecord = roleData.SkillCountRecord or table.empty

    for skillId, damage in pairs(skillDamageRecord) do
        table.insert(damageList, {
            SkillId = skillId,
            Times = skillCountRecord[skillId],
            HpDamage = damage,
            SpDamage = skillEnergyRecord[skillId],
            TotalDamage = roleData.TotalDamage,
            TotalEnergyCast = roleData.TotalEnergyCast,
            IsBuff = false,
            IsSkillReadOnly = isSkillReadOnly
        })
    end

    for tagId, damage in pairs(buffDamageRecord) do
        --buff如果没有造成伤害则不显示
        if XTool.IsNumberValid(damage) then
            table.insert(damageList, {
                SkillId = tagId,
                Times = 0,
                HpDamage = damage,
                SpDamage = buffEnergyRecord[tagId],
                TotalDamage = roleData.TotalDamage,
                TotalEnergyCast = roleData.TotalEnergyCast,
                IsBuff = true
            })
        end
    end

    -- 按伤害降序排序
    table.sort(damageList, function(a, b)
        return a.HpDamage > b.HpDamage
    end)

    return damageList
end

---当角色未造成任何伤害时 显示第一个主动技能造成0点伤害
---@param fileData Theatre6FileData
function XTheatre6Control:SetPvpRoundSettlementEmptyDamage(damageList, fileData)
    for _, skill in ipairs(fileData.Skills) do
        if skill.SlotType == XEnumConst.Theatre6.SlotType.Active and skill.Position == 1 then
            table.insert(damageList, {
                SkillId = skill.SkillId,
                Times = 0,
                HpDamage = 0,
                SpDamage = 0,
                TotalDamage = 0,
                TotalEnergyCast = 0,
                IsBuff = false,
                IsSkillReadOnly = true
            })
            return
        end
    end
end

function XTheatre6Control:TryGetCSDictValue(dict, key, defaultValue)
    if not dict then
        return defaultValue
    end
    local ok, value = dict:TryGetValue(key)
    if ok then
        return value
    end
    return defaultValue
end

---获取环境效果描述
function XTheatre6Control:GetPvpBuffDesc(buffId)
    local config = self._Model:GetPvpBuffConfig(buffId)
    local desc = config.Desc
    if not desc then
        return ""
    end
    desc = self:ReplaceAttrPlaceholder(desc)
    desc = XUiHelper.ReplaceTextNewLine(desc)
    return CS.XTextManager.FormatString(desc, table.unpack(config.DescParams))
end

--endregion

---防守阵容的环境设置按钮是否显示红点
function XTheatre6Control:IsChooseEnvRedPoint()
    return self:IsPvpBuffGroupIdValid() and self._Model:IsChooseEnvRedPoint()
end

---关闭防守阵容的环境设置按钮红点
function XTheatre6Control:CloseChooseEnvRedPoint()
    self._Model:CloseChooseEnvRedPoint()
end

return XTheatre6Control
