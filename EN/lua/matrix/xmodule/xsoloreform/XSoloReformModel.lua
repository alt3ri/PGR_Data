---@class XSoloReformModel : XModel
local XSoloReformModel = XClass(XModel, "XSoloReformModel")

local TableKey = {
    SoloReformCfg = {CacheType = XConfigUtil.CacheType.Normal},
    SoloReformChapter = {CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.IntAll},
    SoloReformStage = {CacheType = XConfigUtil.CacheType.Normal, ReadFunc = XConfigUtil.ReadType.IntAll},
    SoloReformUnlockFightEvent = {Identifier = "FightEventId"},
}
local LONG_TERM_VERSION = 1
local SAVE_KEY_LONGTERM = 'LONGT_TERM'

function XSoloReformModel:OnInit()
    ---@type XSoloReformDataDb
    self._SoloReformData = {}
    self._SoloReformUnlockFightEventDic = nil
    self._ConfigUtil:InitConfigByTableKey('Fuben/SoloReform', TableKey)
    self._SaveUtil:SetCustomVersionGetFunc(handler(self, self.LongTermVersionGetFunc), SAVE_KEY_LONGTERM)
end

function XSoloReformModel:LongTermVersionGetFunc()
    local activityId = self:GetActivityId()
    if not XTool.IsNumberValid(activityId) then
        return LONG_TERM_VERSION
    end    
    return activityId
end

function XSoloReformModel:UpdateSoloReformData(data)
    self:ResetAll()
    if not data then
        return
    end    
    if not XTool.IsTableEmpty(data.SoloReformDataDb) then
        for k, v in pairs(data.SoloReformDataDb) do
            self._SoloReformData[k] = v
        end
    end
end

function XSoloReformModel:UpdateSoloStarState(stageId, starNum)
    if not self._SoloReformData.StageFinishStar then
        self._SoloReformData.StageFinishStar = {}
    end
    self._SoloReformData.StageFinishStar[stageId] = starNum    
end

function XSoloReformModel:UpdateChapterData(chapterId, stageId, timeStamp)
    if not self._SoloReformData.ChapterStageDatas then
        self._SoloReformData.ChapterStageDatas = {}
    end
    if not self._SoloReformData.ChapterStageDatas[chapterId] then
        self._SoloReformData.ChapterStageDatas[chapterId] = {ChapterId = chapterId, PassStageId = stageId}
    end
    local characterData = self._SoloReformData.ChapterStageDatas[chapterId]
    local curStage = self:GetSoloReformStageCfg(characterData.PassStageId)
    local stageCfg = self:GetSoloReformStageCfg(stageId)
    if stageCfg.Difficulty > curStage.Difficulty then
         characterData.PassStageId = stageId
    end     
    local maxStageId = self:GetMaxDifficultyStageId(chapterId)
    if stageId == maxStageId then
        if not XTool.IsNumberValid(characterData.MinPassTime) or characterData.MinPassTime > timeStamp then
            characterData.MinPassTime = timeStamp
        end
    end        
end

--region sever
function XSoloReformModel:GetActivityId()
    return self._SoloReformData and self._SoloReformData.ActivityId
end

function XSoloReformModel:GetChapterStageDatas()
    return self._SoloReformData.ChapterStageDatas
end

---@return type XSoloReformChapterData
function XSoloReformModel:GetChapterStageData(chapterId)
    return self._SoloReformData.ChapterStageDatas and self._SoloReformData.ChapterStageDatas[chapterId]
end

function XSoloReformModel:GetMinChapterPassTime(chapterId)
    local chapterData = self:GetChapterStageData(chapterId)
    return chapterData and chapterData.MinPassTime
end

function XSoloReformModel:GetStageFinishStar(stageId)
    return self._SoloReformData.StageFinishStar and self._SoloReformData.StageFinishStar[stageId]
end

--endregion

function XSoloReformModel:GetCompletedTaskCountAndTotal()
    local showChapterList = self:GetAllShowChapterCfgs()
    local totalCount = 0 
    local completedCount = 0
    for k, chapterCfg in pairs(showChapterList) do
        local ChapterCompletedCount, ChapterTotalCount = self:GetChapterCompletedTaskCountAndTotal(chapterCfg.Id)
        completedCount = completedCount + ChapterCompletedCount
        totalCount = totalCount + ChapterTotalCount
    end
    return completedCount, totalCount
end

--return 完成任务数，总任务数
function XSoloReformModel:GetChapterCompletedTaskCountAndTotal(chapterId)
    local chapterCfg = self:GetSoloReformChapterCfg(chapterId)
    if XTool.IsTableEmpty(chapterCfg.ChapterStageId) then
        return
    end
    local totalCount = 0 
    local completedCount = 0
    for _, stageId in pairs(chapterCfg.ChapterStageId) do
        local stageCfg = self:GetSoloReformStageCfg(stageId)
        totalCount = totalCount + stageCfg.StarNum
        local stageStarStates = self:GetStageStarStateByStageId(stageId)
        for _, state in pairs(stageStarStates) do
            if state then
               completedCount = completedCount + 1
            end    
        end
    end
    return completedCount, totalCount    
end

--stage星级任务的状态，0101 = false,true，false,true, 从右到左是1 2 3
function XSoloReformModel:GetStageStarStateByStageId(stageId)
    local stageCfg = self:GetSoloReformStageCfg(stageId)
    local stageStates = {}
    if not XTool.IsNumberValid(stageCfg.StarNum) then
        return stageStates
    end    
    for i = 1, stageCfg.StarNum do
        stageStates[i] = false
    end
    local stageFinishStarValue = self:GetStageFinishStar(stageId)
    if XTool.IsNumberValid(stageFinishStarValue) then
        for i = 1, #stageStates do
            local result = stageFinishStarValue % 2
            stageStates[i] = result > 0 and true or false
            stageFinishStarValue = math.floor(stageFinishStarValue / 2)
        end
    end
    return stageStates    
end

--所有需要显示的关卡
function XSoloReformModel:GetAllShowChapterCfgs()
    local allCfgs = self:GetAllSoloReformChapterCfgs()
    local allCfgList = {}
    local now = XTime.GetServerNowTimestamp()
    for _, cfg in pairs(allCfgs) do
        local endTime = XFunctionManager.GetEndTimeByTimeId(cfg.OpenTime)
        if endTime == 0 or endTime > now then  --过期的不要， 不配时间默认添加
            table.insert(allCfgList, cfg)
        end    
    end
    table.sort(allCfgList, function (a, b)
        if a.Order ~= b.Order then
            return a.Order < b.Order
        end
        return a.Id < b.Id    
    end)
    return allCfgList
end


--region config
function XSoloReformModel:GetSoloReformCfg(id, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SoloReformCfg, id, notips)
end

function XSoloReformModel:GetAllSoloReformChapterCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.SoloReformChapter)
end

function XSoloReformModel:GetSoloReformChapterCfg(chapterId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SoloReformChapter, chapterId, notips)
end

function XSoloReformModel:GetSoloReformStageCfg(stageId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SoloReformStage, stageId, notips)
end

function XSoloReformModel:GetSoloReformUnlockFightEvent(fightEventId, notips)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.SoloReformUnlockFightEvent, fightEventId, notips)
end

function XSoloReformModel:GetSoloReformUnlockFightEventCfgs(chapterId)
    if not self._SoloReformUnlockFightEventDic then
        self._SoloReformUnlockFightEventDic = {}
        local allCfg = self._ConfigUtil:GetByTableKey(TableKey.SoloReformUnlockFightEvent)
        for _, cfg in pairs(allCfg) do
            if not self._SoloReformUnlockFightEventDic[cfg.ChapterId] then
                self._SoloReformUnlockFightEventDic[cfg.ChapterId] = {}
            end
            table.insert(self._SoloReformUnlockFightEventDic[cfg.ChapterId], cfg)      
        end
        for _, cfgs in pairs(self._SoloReformUnlockFightEventDic) do
            table.sort(cfgs, function(a, b)
                if a.UnlockDiff ~= b.UnlockDiff then
                    return a.UnlockDiff <= b.UnlockDiff
                end
                return a.FightEventId < b.FightEventId     
            end)
        end
    end
    return self._SoloReformUnlockFightEventDic[chapterId]    
end

function XSoloReformModel:GetMaxDifficultyStageId(chapterId)
    local chapterCfg = self:GetSoloReformChapterCfg(chapterId)
    if XTool.IsTableEmpty(chapterCfg.ChapterStageId) then
        return
    end
    local targetStageCfg
    for _, stageId in pairs(chapterCfg.ChapterStageId) do
        local stageCfg = self:GetSoloReformStageCfg(stageId)
        if not targetStageCfg then
            targetStageCfg = stageCfg
        end
        if stageCfg.Difficulty > targetStageCfg.Difficulty then
            targetStageCfg = stageCfg
        end    
    end
    return targetStageCfg and targetStageCfg.Id    
end    

--endregion

--同一个章节所有关卡共用一个队伍
function XSoloReformModel:GetStageTeamKey(chapterId)
    return string.format("Solo_Reform_Team_%s_%s", self:LongTermVersionGetFunc(), chapterId)
end

--region 蓝点

function XSoloReformModel:MarkLocalChapterReddot(chapterId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_LONGTERM, self:GetChapterReddotKey(chapterId) , true)
end

function XSoloReformModel:CheckLocalChapterReddot(chapterId)
    return not self._SaveUtil:GetDataByBlockKey(SAVE_KEY_LONGTERM, self:GetChapterReddotKey(chapterId))
end

function XSoloReformModel:GetChapterReddotKey(chapterId)
    return string.format("Solo_Reform_Chapter_%s", chapterId)
end

function XSoloReformModel:MarkLocalStrengthReddot(fightEventId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_LONGTERM, self:GetStrengthReddotKey(fightEventId) , true)
end

function XSoloReformModel:CheckLocalStrengthReddot(fightEventId)
    return not self._SaveUtil:GetDataByBlockKey(SAVE_KEY_LONGTERM, self:GetStrengthReddotKey(fightEventId))
end

function XSoloReformModel:GetStrengthReddotKey(fightEventId)
    return string.format("Solo_Reform_Strength_%s", fightEventId)
end

--endregion

function XSoloReformModel:ClearPrivate()
    self._SoloReformUnlockFightEventDic = nil
end

function XSoloReformModel:ResetAll()
     self._SoloReformData = {}
end

return XSoloReformModel