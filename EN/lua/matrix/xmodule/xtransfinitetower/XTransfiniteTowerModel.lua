---@class XTransfiniteTowerModel : XModel
---@field private _DataDb XTransfiniteTowerDataDb 活动存档（全量）
local XTransfiniteTowerModel = XClass(XModel, "XTransfiniteTowerModel")

function XTransfiniteTowerModel:OnInit()
    self._DataDb = nil
end

---Control 生命周期结束时触发（界面全关/进战斗都会走到）
---服务端存档不能在这里清，否则进一次战斗回来进度就没了；只清界面级临时缓存
function XTransfiniteTowerModel:ClearPrivate()
    self._RankShowMap = nil
    self._RankCacheData = nil
end

---重登清理
function XTransfiniteTowerModel:ResetAll()
    self._DataDb = nil
end

--region Notify 存档

---@param data table NotifyTransfiniteTowerData 的 XTransfiniteTowerDataDb
function XTransfiniteTowerModel:NotifyData(data)
    self._DataDb = data
end

---单章节推送：按 ChapterId 原地替换，无则追加
---服务端可能在全量存档之前就推单章节（首次进塔时才创建存档），此时自建容器承接
---@param chapterInfo TransfiniteTowerChapterInfo
function XTransfiniteTowerModel:UpdateChapterInfo(chapterInfo)
    if not chapterInfo then return end
    if not self._DataDb then
        self._DataDb = {}
    end
    if not self._DataDb.ChapterInfoList then
        self._DataDb.ChapterInfoList = { chapterInfo }
        return
    end
    local list = self._DataDb.ChapterInfoList
    for i = 1, #list do
        if list[i].ChapterId == chapterInfo.ChapterId then
            list[i] = chapterInfo
            return
        end
    end
    list[#list + 1] = chapterInfo
end

---@return XTransfiniteTowerDataDb
function XTransfiniteTowerModel:GetDataDb()
    return self._DataDb
end

--endregion

--region 章节塔查询

---@return TransfiniteTowerChapterInfo
function XTransfiniteTowerModel:GetChapterInfo(chapterId)
    if not self._DataDb or not self._DataDb.ChapterInfoList then return end
    for _, info in ipairs(self._DataDb.ChapterInfoList) do
        if info.ChapterId == chapterId then
            return info
        end
    end
end

---本轮爬塔数据（nil=无进行中的爬塔：未开始或已结算终结）
---@return TransfiniteTowerChapterBattleInfo
function XTransfiniteTowerModel:GetCurBattleInfo(chapterId)
    local info = self:GetChapterInfo(chapterId)
    return info and info.CurBattleInfo
end

---当前进度（已通关最大层序号，回溯会回退）
---@return number
function XTransfiniteTowerModel:GetStageProgressIndex(chapterId)
    local battleInfo = self:GetCurBattleInfo(chapterId)
    return battleInfo and battleInfo.StageProgressIndex or 0
end

---历史最大通关层序号（回溯不回退、跨轮保留，仅用于塔通关标记，不代表本轮进度）
---@return number
function XTransfiniteTowerModel:GetMaxPassedOrder(chapterId)
    local info = self:GetChapterInfo(chapterId)
    return info and info.MaxPassedOrder or 0
end

---是否允许自选 MVP
---@return boolean
function XTransfiniteTowerModel:CanSetMvp(chapterId)
    local info = self:GetChapterInfo(chapterId)
    return info ~= nil and info.CanSetMvp
end

---历史最佳到达层数（New 标签用）
---@return number
function XTransfiniteTowerModel:GetBestOrder(chapterId)
    local info = self:GetChapterInfo(chapterId)
    return info and info.BestOrder or 0
end

---历史最佳总用时
---@return number
function XTransfiniteTowerModel:GetBestTotalSpendTime(chapterId)
    local info = self:GetChapterInfo(chapterId)
    return info and info.BestTotalSpendTime or 0
end

---当前有效回溯点层序号（0=无）
---@return number
function XTransfiniteTowerModel:GetRollbackOrder(chapterId)
    local battleInfo = self:GetCurBattleInfo(chapterId)
    return battleInfo and battleInfo.RollbackOrder or 0
end

---@return TransfiniteTowerSettleInfo
function XTransfiniteTowerModel:GetSettleInfo(chapterId)
    local info = self:GetChapterInfo(chapterId)
    return info and info.SettleInfo
end

---更新最佳成绩
function XTransfiniteTowerModel:UpdateSettleInfo(chapterId, settleInfo)
    if not settleInfo then return end
    local info = self:GetChapterInfo(chapterId)
    if not info then return end
    info.SettleInfo = settleInfo
end

---暂存本次章节结算的响应数据
function XTransfiniteTowerModel:SetCurSettleResult(settleInfo, rank, totalCount)
    self._CurSettleInfo = settleInfo
    self._CurSettleRank = rank
    self._CurSettleTotalCount = totalCount
end

---@return TransfiniteTowerSettleInfo, number, number
function XTransfiniteTowerModel:GetCurSettleResult()
    return self._CurSettleInfo, self._CurSettleRank, self._CurSettleTotalCount
end

---@return TransfiniteTowerRankInfo
function XTransfiniteTowerModel:GetRankInfo(chapterId)
    local info = self:GetChapterInfo(chapterId)
    return info and info.RankInfo
end

--endregion

--region 单层记录查询

---按层序号取本轮单层通关记录
---@return TransfiniteTowerStageRecord
function XTransfiniteTowerModel:GetStageRecord(chapterId, order)
    local battleInfo = self:GetCurBattleInfo(chapterId)
    if not battleInfo or not battleInfo.StageRecordList then return end
    for _, rec in ipairs(battleInfo.StageRecordList) do
        if rec.Order == order then
            return rec
        end
    end
end

---本轮单层通关用时（秒）；上轮记录另走 GetLastStageRecord，取舍由 Control 决定
---@return number
function XTransfiniteTowerModel:GetStageSpendTime(chapterId, order)
    local rec = self:GetStageRecord(chapterId, order)
    return rec and rec.SpendTime or 0
end

---本塔最近一次胜利通关所用的选角快照
---@return XTransfiniteTowerTeamSelection|nil
function XTransfiniteTowerModel:GetLastTeamSelection(chapterId)
    local battleInfo = self:GetCurBattleInfo(chapterId)
    return battleInfo and battleInfo.LastTeamSelection
end

---本轮已确认各层通关用时之和（秒）
---@return number
function XTransfiniteTowerModel:GetConfirmedTotalSpendTime(chapterId)
    local battleInfo = self:GetCurBattleInfo(chapterId)
    if not battleInfo or not battleInfo.StageRecordList then return 0 end
    local total = 0
    for _, rec in ipairs(battleInfo.StageRecordList) do
        total = total + (rec.SpendTime or 0)
    end
    return total
end

---待确认的关卡战斗记录（战斗胜利暂存，单层结算协议确认后清空）
---@return TransfiniteTowerStageRecord
function XTransfiniteTowerModel:GetPendingStageRecord(chapterId)
    local battleInfo = self:GetCurBattleInfo(chapterId)
    return battleInfo and battleInfo.PendingStageRecord
end

--endregion

--region 上轮爬塔留存记录（与本轮 CurBattleInfo 互斥，需先重置进度才能开新一轮）

---是否存在上轮留存记录
---@return boolean
function XTransfiniteTowerModel:HasLastStageRecord(chapterId)
    return not XTool.IsTableEmpty(self:GetLastStageRecordList(chapterId))
end

---上轮各层通关记录列表
---@return TransfiniteTowerLastStageRecord[]
function XTransfiniteTowerModel:GetLastStageRecordList(chapterId)
    local info = self:GetChapterInfo(chapterId)
    return info and info.LastStageRecordList
end

---按层序号取上轮单层记录（列表下标即层序号）
---@return TransfiniteTowerLastStageRecord
function XTransfiniteTowerModel:GetLastStageRecord(chapterId, order)
    local info = self:GetChapterInfo(chapterId)
    if not info or XTool.IsTableEmpty(info.LastStageRecordList) then return end
    return info.LastStageRecordList[order]
end

---客户端预扣一次出战次数（乐观更新）
---@param characterCfgId number Character 表配置 Id；0/nil 表示全选模式下未配置的自机，改用 characterId 区分
function XTransfiniteTowerModel:AddCharacterUsedCount(chapterId, characterCfgId, characterId)
    local battleInfo = self:GetCurBattleInfo(chapterId)
    if not battleInfo then return end
    if not battleInfo.CharacterCountList then
        battleInfo.CharacterCountList = {}
    end
    local hasCfgId = XTool.IsNumberValid(characterCfgId)
    local list = battleInfo.CharacterCountList
    for _, cc in ipairs(list) do
        -- 匹配规则与 GetCharacterUsedCount / GetCharacterUsedCountByCharacterId 保持一致
        local isMatch = hasCfgId and cc.CharacterCfgId == characterCfgId
            or not hasCfgId and not XTool.IsNumberValid(cc.CharacterCfgId) and cc.CharacterId == characterId
        if isMatch then
            cc.UsedCount = cc.UsedCount + 1
            return
        end
    end
    list[#list + 1] = { CharacterCfgId = characterCfgId or 0, CharacterId = characterId, UsedCount = 1 }
end

--endregion

--region 角色次数

---按 CharacterCfgId 取角色已用挑战次数
---@return number
function XTransfiniteTowerModel:GetCharacterUsedCount(chapterId, characterCfgId)
    local battleInfo = self:GetCurBattleInfo(chapterId)
    if not battleInfo or not battleInfo.CharacterCountList then return 0 end
    for _, cc in ipairs(battleInfo.CharacterCountList) do
        if cc.CharacterCfgId == characterCfgId then
            return cc.UsedCount
        end
    end
    return 0
end

---按真实角色 Id 取已用挑战次数（未配进 Character 表的自机，服务端 CharacterCfgId 记 0）
---@return number
function XTransfiniteTowerModel:GetCharacterUsedCountByCharacterId(chapterId, characterId)
    local battleInfo = self:GetCurBattleInfo(chapterId)
    if not battleInfo or not battleInfo.CharacterCountList then return 0 end
    for _, cc in ipairs(battleInfo.CharacterCountList) do
        if not XTool.IsNumberValid(cc.CharacterCfgId) and cc.CharacterId == characterId then
            return cc.UsedCount
        end
    end
    return 0
end

--endregion

--region 排行榜条目缓存（拉榜响应临时数据，供"查看他人记录"复用，随界面释放清掉）

---@param list TransfiniteTowerRankShow[]
function XTransfiniteTowerModel:SetRankShowList(list)
    if XTool.IsTableEmpty(list) then
        self._RankShowMap = nil
        return
    end
    self._RankShowMap = {}
    for _, show in ipairs(list) do
        self._RankShowMap[show.Id] = show
    end
end

---@return TransfiniteTowerRankShow
function XTransfiniteTowerModel:GetRankShow(playerId)
    return self._RankShowMap and self._RankShowMap[playerId]
end

---暂存一次拉榜的完整展示数据（预取缓存，页面打开时先渲染旧的避免卡顿，更新到再刷新）
---@param data table|nil { reward, rankList, myRankData, lastRankTotalSpendTime }
function XTransfiniteTowerModel:SetRankCacheData(data)
    self._RankCacheData = data
end

---@return table|nil 缓存数据，未拉过返回 nil
function XTransfiniteTowerModel:GetRankCacheData()
    return self._RankCacheData
end

--endregion

--region 教学关查询

---是否已通过指定教学关
---@return boolean
function XTransfiniteTowerModel:IsTeachStagePassed(stageId)
    if not self._DataDb or not self._DataDb.PassedTeachStageIds then return false end
    for _, id in ipairs(self._DataDb.PassedTeachStageIds) do
        if id == stageId then
            return true
        end
    end
    return false
end

--endregion

return XTransfiniteTowerModel
