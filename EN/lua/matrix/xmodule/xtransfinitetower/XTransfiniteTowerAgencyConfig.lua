---Agency 部分类：模块配置表的唯一注册点 + 对外配置查询接口
---表路径 Share/Fuben/TransfiniteTower/。Agency 常驻、生命周期长于 Control，
---故所有表在此注册（Agency scope）；Control 侧只做转发（见 ControlPartial/XTransfiniteTowerControlConfig）。
---@type XTransfiniteTowerAgency
local XTransfiniteTowerAgency = XClassPartial("XTransfiniteTowerAgency")

local Share = XConfigUtil.DirectoryType.Share

local function SortByOrder(a, b)
    return a.Order < b.Order
end

local function SortById(a, b)
    return a.Id < b.Id
end

local TableKey = {
    TransfiniteTowerActivity       = { DirPath = Share, Identifier = "Id" },
    TransfiniteTowerChapter        = { DirPath = Share, Identifier = "Id" },
    TransfiniteTowerStage          = { DirPath = Share, Identifier = "Id" },
    TransfiniteTowerCharacter      = { DirPath = Share, Identifier = "Id" },
    TransfiniteTowerCharacterGroup = { DirPath = Share, Identifier = "Id" },
    TransfiniteTowerFightCount     = { DirPath = Share, Identifier = "FightCount" },
    TransfiniteTowerConfig         = { DirPath = Share, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
}

function XTransfiniteTowerAgency:InitConfig()
    self:InitConfigByTabKey("Fuben/TransfiniteTower", TableKey)
end

--region Get 封装（按 id/key 查单条配置）

---@return XTableTransfiniteTowerActivity
function XTransfiniteTowerAgency:GetActivityCfg(activityId)
    return self:GetConfigByTabKeyAndIdKey(TableKey.TransfiniteTowerActivity, activityId)
end

---@return XTableTransfiniteTowerChapter
function XTransfiniteTowerAgency:GetChapterCfg(chapterId)
    return self:GetConfigByTabKeyAndIdKey(TableKey.TransfiniteTowerChapter, chapterId)
end

---塔的开放结束时间戳（Proxy/页面踢出判断用）；未配时间返回 0
---@param chapterId number
---@return number
function XTransfiniteTowerAgency:GetTowerUnlockEndTime(chapterId)
    local cfg = self:GetChapterCfg(chapterId)
    if not cfg or not XTool.IsNumberValid(cfg.UnLockTimeId) then return 0 end
    return XFunctionManager.GetEndTimeByTimeId(cfg.UnLockTimeId) or 0
end

---塔开放时间是否已结束
---@param chapterId number
---@return boolean
function XTransfiniteTowerAgency:IsTowerClosed(chapterId)
    local endTime = self:GetTowerUnlockEndTime(chapterId)
    return endTime > 0 and endTime < XTime.GetServerNowTimestamp()
end

---@return XTableTransfiniteTowerStage
function XTransfiniteTowerAgency:GetStageCfg(stageCfgId)
    return self:GetConfigByTabKeyAndIdKey(TableKey.TransfiniteTowerStage, stageCfgId)
end

---@return XTableTransfiniteTowerCharacter
function XTransfiniteTowerAgency:GetCharacterCfg(characterCfgId)
    return self:GetConfigByTabKeyAndIdKey(TableKey.TransfiniteTowerCharacter, characterCfgId)
end

---@return XTableTransfiniteTowerCharacterGroup
function XTransfiniteTowerAgency:GetCharacterGroupCfg(characterGroupId)
    return self:GetConfigByTabKeyAndIdKey(TableKey.TransfiniteTowerCharacterGroup, characterGroupId)
end

---@return XTableTransfiniteTowerFightCount
function XTransfiniteTowerAgency:GetFightCountCfg(fightCount)
    return self:GetConfigByTabKeyAndIdKey(TableKey.TransfiniteTowerFightCount, fightCount)
end

---通用配置项（按 Key 取，Values 为字符串数组）
---@return XTableTransfiniteTowerConfig
function XTransfiniteTowerAgency:GetConfigByKey(key)
    return self:GetConfigByTabKeyAndIdKey(TableKey.TransfiniteTowerConfig, key)
end

--endregion

--region 列表查询 helper（按 StageGroupId 建索引缓存，避免每次全表扫）

---按 StageGroupId 取该组所有 Stage 配置，按 Order 升序返回
---@return XTableTransfiniteTowerStage[]
function XTransfiniteTowerAgency:GetStagesByGroupId(stageGroupId)
    if not self._StageGroupCache then
        self._StageGroupCache = {}
        local all = self:GetAllConfigByTabKey(TableKey.TransfiniteTowerStage)
        if all then
            for _, stage in pairs(all) do
                local list = self._StageGroupCache[stage.StageGroupId]
                if not list then
                    list = {}
                    self._StageGroupCache[stage.StageGroupId] = list
                end
                list[#list + 1] = stage
            end
            for _, list in pairs(self._StageGroupCache) do
                table.sort(list, SortByOrder)
            end
        end
    end
    return self._StageGroupCache[stageGroupId] or table.empty
end

---取当前 Stage 的下一层 Stage（同组 Order+1）；无下一层返回 nil
---@return XTableTransfiniteTowerStage
function XTransfiniteTowerAgency:GetNextStageCfg(stageCfgId)
    local cur = self:GetStageCfg(stageCfgId)
    if not cur then return end
    local list = self:GetStagesByGroupId(cur.StageGroupId)
    for i = 1, #list do
        if list[i].Id == stageCfgId then
            return list[i + 1]
        end
    end
end

---战斗关卡id（Stage.StageId）→ 本模块关卡配置（缓存 battleStageId→cfg）
---@return XTableTransfiniteTowerStage
function XTransfiniteTowerAgency:GetStageCfgByBattleStageId(battleStageId)
    if not self._BattleStageIdToCfg then
        self._BattleStageIdToCfg = {}
        local all = self:GetAllConfigByTabKey(TableKey.TransfiniteTowerStage)
        if all then
            for _, cfg in pairs(all) do
                self._BattleStageIdToCfg[cfg.StageId] = cfg
            end
        end
    end
    return self._BattleStageIdToCfg[battleStageId]
end

---排行章节塔 Id：Chapter 表中第一个（Id 最小）配了 IsRank 的塔；无则返回 nil
---@return number
function XTransfiniteTowerAgency:GetRankChapterId()
    if self._RankChapterId == nil then
        local all = self:GetAllConfigByTabKey(TableKey.TransfiniteTowerChapter)
        local found = 0
        if all then
            for id, chapter in pairs(all) do
                -- IsRank 未配时读出来是 0，不能直接当布尔用
                if XTool.IsNumberValid(chapter.IsRank) and (found == 0 or id < found) then
                    found = id
                end
            end
        end
        -- 用 0 表示"查过且没有"，避免每次都重扫全表
        self._RankChapterId = found
    end
    return self._RankChapterId > 0 and self._RankChapterId or nil
end

---取当前 Stage 所属 Chapter（反查 Chapter.StageGroupId）
---@return XTableTransfiniteTowerChapter
function XTransfiniteTowerAgency:GetChapterByStageGroupId(stageGroupId)
    if not self._GroupToChapterCache then
        self._GroupToChapterCache = {}
        local all = self:GetAllConfigByTabKey(TableKey.TransfiniteTowerChapter)
        if all then
            for _, chapter in pairs(all) do
                self._GroupToChapterCache[chapter.StageGroupId] = chapter
            end
        end
    end
    return self._GroupToChapterCache[stageGroupId]
end

---取当前 Stage 所属 Chapter 的 Id（stageCfgId → StageGroupId → 反查 Chapter）
---@return number
function XTransfiniteTowerAgency:GetChapterIdByStageCfg(stageCfgId)
    local stage = self:GetStageCfg(stageCfgId)
    if not stage then return end
    local chapter = self:GetChapterByStageGroupId(stage.StageGroupId)
    return chapter and chapter.Id
end

---取所有领航员 Character 配置（Type==2），按 Id 升序；同一 CharacterId 多行配置只保留 Id 最小的一条
---@return XTableTransfiniteTowerCharacter[]
function XTransfiniteTowerAgency:GetLeaderCharacterCfgList()
    if not self._LeaderCharListCache then
        local all = self:GetAllConfigByTabKey(TableKey.TransfiniteTowerCharacter)
        local list = {}
        if all then
            for _, cfg in pairs(all) do
                if cfg.Type == 2 then
                    list[#list + 1] = cfg
                end
            end
            table.sort(list, SortById)
            -- 去重
            local seen, uniqueList = {}, {}
            for _, cfg in ipairs(list) do
                if not seen[cfg.CharacterId] then
                    seen[cfg.CharacterId] = true
                    uniqueList[#uniqueList + 1] = cfg
                end
            end
            list = uniqueList
        end
        self._LeaderCharListCache = list
    end
    return self._LeaderCharListCache
end

---遍历 Character 表，按 characterId 找 Character 配置（缓存 characterId→cfg）
---@return XTableTransfiniteTowerCharacter
function XTransfiniteTowerAgency:GetCharacterCfgByCharacterId(characterId)
    if not self._CharIdToCfgMap then
        self._CharIdToCfgMap = {}
        local all = self:GetAllConfigByTabKey(TableKey.TransfiniteTowerCharacter)
        if all then
            for _, cfg in pairs(all) do
                self._CharIdToCfgMap[cfg.CharacterId] = cfg
            end
        end
    end
    return self._CharIdToCfgMap[characterId]
end

---遍历 Activity 表找当前开放中的 TimeId（同一时间只有一个 Activity 开放）
---@return number timeId, number activityId
function XTransfiniteTowerAgency:GetOpenActivityTimeId()
    if not self._ActivityListCache then
        local all = self:GetAllConfigByTabKey(TableKey.TransfiniteTowerActivity)
        self._ActivityListCache = {}
        if all then
            for _, cfg in pairs(all) do
                self._ActivityListCache[#self._ActivityListCache + 1] = cfg
            end
        end
    end
    for _, cfg in ipairs(self._ActivityListCache) do
        if XFunctionManager.CheckInTimeByTimeId(cfg.TimeId) then
            return cfg.TimeId, cfg.Id
        end
    end
end

--endregion

return XTransfiniteTowerAgency
