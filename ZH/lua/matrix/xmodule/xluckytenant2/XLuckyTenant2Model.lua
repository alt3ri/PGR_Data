local XLuckyTenant2ConfigModel = require("XModule/XLuckyTenant2/XLuckyTenant2ConfigModel")

---@class XLuckyTenant2Model : XLuckyTenant2ConfigModel
local XLuckyTenant2Model = XClass(XLuckyTenant2ConfigModel, "XLuckyTenant2Model")

function XLuckyTenant2Model:OnInit()
    self:_InitTableKey()
    self._ActivityId = 0
    self._PlayingStageId = 0
    self._PlayingStageRound = 0
    self._StageRecord = false
    self._StageTask = false
    self._RoundsToNormalClear = false
    self._RoundsToPerfectClear = false
end

function XLuckyTenant2Model:ClearPrivate()
    self._StageTask = false
end

function XLuckyTenant2Model:ResetAll()
    self._ActivityId = 0
    self._PlayingStageId = 0
    self._PlayingStageRound = 0
    self._StageRecord = false
    self._StageTask = false
    self._RoundsToNormalClear = false
    self._RoundsToPerfectClear = false
end

---@return XTable.XTableLuckyTenant2Activity
function XLuckyTenant2Model:GetActivityConfig()
    local activityId = self._ActivityId
    local config = self:GetLuckyTenant2ActivityById(activityId)
    if config then
        return config
    end
end

function XLuckyTenant2Model:GetHelpKey()
    local config = self:GetActivityConfig()
    if not config then
        return "LuckyTenant2Game"
    end
    return config.HelpId
end

---关卡首次进入时是否已展示过图文教程（由 SaveUtil 持久化）
---@param stageId number
---@return boolean
function XLuckyTenant2Model:IsStageTutorialShown(stageId)
    if not stageId or not self._SaveUtil then
        return false
    end
    return self._SaveUtil:GetData("StageTutorialShown_" .. tostring(stageId)) == true
end

---标记关卡图文教程已展示（关闭教学界面时由 Control 调用）
---@param stageId number
function XLuckyTenant2Model:SetStageTutorialShown(stageId)
    if not stageId or not self._SaveUtil then
        return
    end
    self._SaveUtil:SaveData("StageTutorialShown_" .. tostring(stageId), true)
end

function XLuckyTenant2Model:GetStages()
    local activityId = self._ActivityId
    local result = {}
    local stages = self:GetLuckyTenant2StageConfigs()
    for id, stage in pairs(stages) do
        if stage.ActivityId == activityId then
            result[#result + 1] = stage
        end
    end
    return result
end

---获取章节列表（根据活动ID）
---@return XTable.XTableLuckyTenant2Chapter[]
function XLuckyTenant2Model:GetChapters()
    local activityId = self._ActivityId
    local result = {}
    local chapters = self:GetLuckyTenant2ChapterConfigs()
    for id, chapter in pairs(chapters) do
        -- 如果章节配置有ActivityId字段，则按ActivityId过滤；否则返回所有章节
        if not chapter.ActivityId or chapter.ActivityId == activityId then
            result[#result + 1] = chapter
        end
    end
    -- 按ID排序
    table.sort(result, function(a, b)
        return a.Id < b.Id
    end)
    return result
end

function XLuckyTenant2Model:GetStageRecord(stageId)
    if self._StageRecord then
        return self._StageRecord[stageId]
    end
    return false
end

function XLuckyTenant2Model:GetRoundsToNormalClear(stageId)
    local stages = self:GetStageTasks(stageId)
    for i = 1, #stages do
        ---@type XTable.XTableLuckyTenant2StageTask
        local stage = stages[i]
        if stage.NormalClear then
            return stage.Round, stage.Score
        end
    end
    return 0, 0
end

function XLuckyTenant2Model:GetQuestAmount(stageId)
    local stageQuests = self:GetStageTasks(stageId)
    return #stageQuests
end

function XLuckyTenant2Model:GetRoundsToPerfectClear(stageId)
    local stageQuests = self:GetStageTasks(stageId)
    for i = 1, #stageQuests do
        ---@type XTable.XTableLuckyTenant2StageTask
        local stage = stageQuests[i]
        if stage.PerfectClear then
            return stage.Round, stage.Score
        end
    end
    if stageQuests[#stageQuests] then
        return stageQuests[#stageQuests].Round, 0
    end
    return 0, 0
end

---@return XTable.XTableLuckyTenant2StageTask[]
function XLuckyTenant2Model:GetStageTasks(stageId)
    if not self._StageTask then
        self._StageTask = {}
    end
    if self._StageTask[stageId] then
        return self._StageTask[stageId]
    end
    local result = {}
    for i = 1, 99 do
        local questId = stageId * 1000 + i
        local config = self:GetLuckyTenant2StageTaskConfigById(questId)
        if config then
            result[#result + 1] = config
        else
            break
        end
    end
    self._StageTask[stageId] = result
    return result
end

function XLuckyTenant2Model:IsStagePassed(stageId)
    local record = self:GetStageRecord(stageId)
    if record then
        if record.IsNormalClear or record.IsPerfectClear then
            return true
        end
    end
    return false
end

function XLuckyTenant2Model:GetPlayingStageId()
    return self._PlayingStageId
end

function XLuckyTenant2Model:GetPlayingStageRound()
    return self._PlayingStageRound
end

function XLuckyTenant2Model:SetDataFromServer(LuckyTenant2StagesNotify)
    self._ActivityId = LuckyTenant2StagesNotify.ActivityId
    self._PlayingStageRound = LuckyTenant2StagesNotify.CurrentStageRound
    self._PlayingStageId = LuckyTenant2StagesNotify.CurrentStage
    self._StageRecord = LuckyTenant2StagesNotify.Stages
end

function XLuckyTenant2Model:SetStageRecord(record)
    if not record or not record.StageId then
        return
    end
    self._StageRecord = self._StageRecord or {}
    self._StageRecord[record.StageId] = record
end

function XLuckyTenant2Model:SetPlayingStageId(value)
    self._PlayingStageId = value
end

function XLuckyTenant2Model:SetPlayingStageRound(value)
    self._PlayingStageRound = value
end

function XLuckyTenant2Model:ClearPlayingStage()
    self:SetPlayingStageId(0)
    self:SetPlayingStageRound(0)
end

function XLuckyTenant2Model:OnStagePassed(recordNew)
    if not recordNew or not recordNew.StageId then
        return
    end
    local record = self:GetStageRecord(recordNew.StageId)
    if record then
        local isNewRecord = false
        -- 处理 Score 比较（处理 nil 值）
        local newScore = recordNew.Score or 0
        local oldScore = record.Score or 0
        if newScore > oldScore then
            record.Score = recordNew.Score
            isNewRecord = true
        end
        -- 处理 Round 比较（处理 nil 值）
        local newRound = recordNew.Round or 0
        local oldRound = record.Round or 0
        if newRound > oldRound then
            record.Round = recordNew.Round
            isNewRecord = true
        end
        record.IsNewRecord = isNewRecord
        record.IsNormalClear = record.IsNormalClear or recordNew.IsNormalClear
    else
        recordNew.IsNewRecord = true
        self:SetStageRecord(recordNew)
    end
end

function XLuckyTenant2Model:IsActivityOpen()
    if self._ActivityId and self._ActivityId > 0 then
        local config = self:GetActivityConfig()
        if config then
            local timeId = config.TimeId
            if XFunctionManager.CheckInTimeByTimeId(timeId) then
                return true
            end
        end
    end
    return false
end

---获取有效的回合配置（根据当前关卡和回合数）
---@param stageId number 关卡ID
---@param currentRound number 当前回合数
---@return XTable.XTableLuckyTenant2ChessRound|false
function XLuckyTenant2Model:GetValidRoundConfig(stageId, currentRound)
    local roundConfigs = self:GetLuckyTenant2ChessRoundConfigs()
    local result = false

    local startId = stageId * 1000 + 1
    local startRoundConfig = roundConfigs[startId]
    if startRoundConfig then
        for i = startId, startId + 99 do
            local round = roundConfigs[i]
            if not round then
                break
            end
            if round.StageId ~= stageId then
                break
            end
            if currentRound >= round.StartRound then
                result = round
            end
        end
    else
        XLog.Error("[XLuckyTenant2Model] 麻烦配置成, 回合表的id = stageId * 1000 + index, 比如1001")
    end
    if not result then
        XLog.Error("[XLuckyTenant2Model] 暴力遍历round表了")
        for i = 1, #roundConfigs do
            local round = roundConfigs[i]
            if round.StageId == stageId then
                if currentRound >= round.StartRound then
                    result = round
                end
            end
        end
    end
    return result
end

return XLuckyTenant2Model
