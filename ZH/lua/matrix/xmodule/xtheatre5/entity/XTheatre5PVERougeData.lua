---XTheatre5PveAdventureData
---@class XTheatre5PVERougeData
local XTheatre5PVERougeData = XClass(nil, 'XTheatre5PVERougeData')
function XTheatre5PVERougeData:Ctor(model)
    ---@type XTheatre5Model
    self._OwnerModel = model
    self.CurPveStoryLineId = nil --当前故事线[初始化是此字段为教学线]
    self.CurStoryEntranceId = nil --当前正在进行的复刷章节
    self.PveStoryLines = nil --[教学线,角色线,共通线]等故事线进度
    self.PveClues = nil  --线索
    self.PveScripts = nil --推演脚本
    self.HistoryChapters = nil --[首次进入和首次通关]章节需要播放AVG,需要记录状态
    self.PveCharacters = nil --解锁的角色
end

function XTheatre5PVERougeData:UpdatePveCharacters(pveCharacters)
    if XTool.IsTableEmpty(pveCharacters) then
        return
    end

    if XTool.IsTableEmpty(self.PveCharacters) then
        self.PveCharacters = pveCharacters
        return
    end
    for key, data in pairs(pveCharacters) do
        self.PveCharacters[key] = data
    end
end

function XTheatre5PVERougeData:UpdateCurStoryLineId(storyLineId)
    self.CurPveStoryLineId = storyLineId
end

function XTheatre5PVERougeData:UpdateCurStoryEntranceId(storyEntranceId)
    self.CurStoryEntranceId = storyEntranceId
end

function XTheatre5PVERougeData:UpdatePveStoryLines(pveStoryLines)
    self.PveStoryLines = pveStoryLines
end

function XTheatre5PVERougeData:UpdatePveStoryLine(pveStoryLineData)
    if not pveStoryLineData then
        return
    end
    self.PveStoryLines[pveStoryLineData.StoryLineId] = pveStoryLineData   

end

function XTheatre5PVERougeData:UpdatePveClues(pveClues)
    self.PveClues = pveClues
end

function XTheatre5PVERougeData:UpdateGainClue(clueId)
    if not XTool.IsNumberValid(clueId) then
        return
    end    
    if not self.PveClues then
        self.PveClues = {}
    end
    if self.PveClues[clueId] then
        return
    end
    self.PveClues[clueId] = {ClueId = clueId, IsComplete = false}    
end

function XTheatre5PVERougeData:UpdatePveScripts(pveScripts)
    self.PveScripts = pveScripts
end

function XTheatre5PVERougeData:UpdatePveScript(scriptId, step, isCompleted)
    if not self.PveScripts then
        self.PveScripts = {}
    end
    if not self.PveScripts[scriptId] then
        self.PveScripts[scriptId] = {}
    end
    local scriptData = self.PveScripts[scriptId]
    scriptData.ScriptId = scriptId
    scriptData.CurStep = step
    scriptData.IsComplete = isCompleted
    --推演完成，线索要设置完成
    if isCompleted then 
        local scriptCfg = self._OwnerModel:GetDeduceScriptCfg(scriptId)
        local clueGroupCfgs = self._OwnerModel:GetDeduceClueGroupCfgs(scriptCfg.PreClueGroupId) 
        if not XTool.IsTableEmpty(clueGroupCfgs) then
            for k, cfg in pairs(clueGroupCfgs) do  --前置线索都解锁可以推演
                 local preClueData = self:GetClueData(cfg.ClueId)
                 if preClueData then
                    preClueData.IsComplete = true
                 end    
            end       
        end
        --更新核心线索
        local clueCfg = self._OwnerModel:GetDeduceClueCfgByScriptId(scriptId)
        if clueCfg then
           self.PveClues[clueCfg.Id] = {ClueId = clueCfg.Id, IsComplete = true}
        end
    end           

end

function XTheatre5PVERougeData:UpdateHistoryChapters(historyChapters)
    self.HistoryChapters = historyChapters
end

--章节AVG播放完成
function XTheatre5PVERougeData:UpdateChapterAVGCompleted(chapterId, isEnterAvg)
    if not self.HistoryChapters then
        self.HistoryChapters = {}
    end
    if not self.HistoryChapters[chapterId] then
        self.HistoryChapters[chapterId] = {}
    end
    self.HistoryChapters[chapterId].ChapterId = chapterId
    if isEnterAvg then
        self.HistoryChapters[chapterId].IsEnterAvgPlay = true
    else
        self.HistoryChapters[chapterId].IsPassAvgPlay = true
    end            
end

function XTheatre5PVERougeData:UpdateHistoryEvent(chapterId, eventId)
    if not self.HistoryChapters then
        self.HistoryChapters = {}
    end
    if not self.HistoryChapters[chapterId] then
        self.HistoryChapters[chapterId] = {}
        self.HistoryChapters[chapterId].ChapterId = chapterId
    end
    if not self.HistoryChapters[chapterId].FinishEvents then
        self.HistoryChapters[chapterId].FinishEvents = {}
    end
    table.insert(self.HistoryChapters[chapterId].FinishEvents, eventId)    
end

function XTheatre5PVERougeData:UpdateChapterData(storyLineId, contentId, chapterData)     
    if not self.PveStoryLines or not self.PveStoryLines[storyLineId] then
        XLog.Error(string.format("故事线没有初始化,storyLineId:%d,contentId:%d", storyLineId, contentId))
        return
    end
    self.PveStoryLines[storyLineId].PveChapterData = chapterData
    self.PveStoryLines[storyLineId].CurContentId = contentId
end

function XTheatre5PVERougeData:UpdateFinishChapterData(storyLineId, contentId)
    if not XTool.IsNumberValid(storyLineId) or not XTool.IsNumberValid(contentId) then
        return
    end    
    if not self.PveStoryLines or not self.PveStoryLines[storyLineId] then
        XLog.Error(string.format("故事线没有初始化,storyLineId:%d,contentId:%d", storyLineId, contentId))
        return
    end
    if not self.PveStoryLines[storyLineId].FinishContents then
        self.PveStoryLines[storyLineId].FinishContents = {}
    end
    table.insert(self.PveStoryLines[storyLineId].FinishContents, contentId)       
end

--故事线解锁
function XTheatre5PVERougeData:UpdateUnlockStoryLine(storyLineDic)
    if XTool.IsTableEmpty(storyLineDic) then
        return
    end
    if not self.PveStoryLines then
        self.PveStoryLines = {}
    end
    for k, v in pairs(storyLineDic) do
        self.PveStoryLines[k] = v
    end    
end

function XTheatre5PVERougeData:CheckHasClue(clueId)
    if not self.PveClues then
        return false
    end
   return self.PveClues[clueId] ~= nil
end

function XTheatre5PVERougeData:IsUnlockStoryLine(storyLineId)
    return self.PveStoryLines and self.PveStoryLines[storyLineId] ~= nil
end

function XTheatre5PVERougeData:GetCurPveStoryLineId()
    return self.CurPveStoryLineId
end

function XTheatre5PVERougeData:GetPveStoryLines()
    return self.PveStoryLines
end

function XTheatre5PVERougeData:GetCurStoryEntranceId()
    return self.CurStoryEntranceId
end

--判断事件双倍的
function XTheatre5PVERougeData:GetHistoryFinishEvents(chapterId)
    if not self.HistoryChapters then
        return
    end    
    return self.HistoryChapters[chapterId] and self.HistoryChapters[chapterId].FinishEvents
end

--contentId是否完成或解锁
function XTheatre5PVERougeData:IsCompletedOrUnlockByContentId(contentId)
    if not self.PveStoryLines then
        return false
    end
    for _, storyLineData in pairs(self.PveStoryLines) do
        if storyLineData.CurContentId == contentId then
            return true
        end
        if not XTool.IsTableEmpty(storyLineData.FinishContents) then
            for _, completedContentId in pairs(storyLineData.FinishContents) do
                if completedContentId == contentId then
                    return true
                end    
            end    
        end    
    end
    return false
end

function XTheatre5PVERougeData:IsCompletedByContentId(contentId)
    if not self.PveStoryLines then
        return false
    end
    for _, storyLineData in pairs(self.PveStoryLines) do
        if not XTool.IsTableEmpty(storyLineData.FinishContents) then
            for _, completedContentId in pairs(storyLineData.FinishContents) do
                if completedContentId == contentId then
                    return true
                end    
            end    
        end    
    end
    return false
end

--角色是否解锁
function XTheatre5PVERougeData:IsCharacterUnlock(characterId)
    if self.PveCharacters and self.PveCharacters[characterId] then
        return true
    end    
    return false
end

function XTheatre5PVERougeData:GetCharacterFashionId(characterId)
    if self.PveCharacters and self.PveCharacters[characterId] then
        return self.PveCharacters[characterId].FashionId
    end    
end

--返回出于故事线结束节点的故事线，优先级很高会拍脸
--return XTheatre5PveStoryLineData
function XTheatre5PVERougeData:GetStoryLineEndingNodeData()
    if XTool.IsTableEmpty(self.PveStoryLines) then
        return
    end
    for k, pveStoryLineData in pairs(self.PveStoryLines) do
        if XTool.IsNumberValid(pveStoryLineData.CurContentId) then
            local storyLineContentCfg = self._OwnerModel:GetStoryLineContentCfg(pveStoryLineData.CurContentId)
            if storyLineContentCfg then
                if storyLineContentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.StoryLineEnd then
                    return pveStoryLineData
                end
            end
        end        
    end
end

--return PveStoryLineContent.Id
function XTheatre5PVERougeData:GetStoryLineContentId(storyLineId)
    if not self.PveStoryLines or not self.PveStoryLines[storyLineId] then
        return
    end
    return self.PveStoryLines[storyLineId].CurContentId     
end

--故事线当前章节数据
--return XTheatre5PveChapterData
function XTheatre5PVERougeData:GetChapterData(storyLineId)
    if not self.PveStoryLines or not self.PveStoryLines[storyLineId] then
        return
    end
    return self.PveStoryLines[storyLineId].PveChapterData 
end

function XTheatre5PVERougeData:GetCharacterId(storyLineId)
    if not self.PveStoryLines or not self.PveStoryLines[storyLineId] then
        return
    end
    return self.PveStoryLines[storyLineId].PveCharacterId 
end

--故事线完成
function XTheatre5PVERougeData:IsStoryLineCompleted(storyLineId)
    local storyLineData = self.PveStoryLines and self.PveStoryLines[storyLineId]
    if storyLineData then
        if XTool.IsTableEmpty(storyLineData.FinishContents) then
            return false
        end
        local contentCfgs = self._OwnerModel:GetContentCfgs(storyLineId)
        if contentCfgs then
            for _, contentCfg in pairs(contentCfgs) do
                local completed = false
                for k, completedContentId in pairs(storyLineData.FinishContents) do
                    if contentCfg.Id == completedContentId then
                        completed = true
                        break
                    end
                end
                if not completed then
                    return false
                end
            end
        end
        return true
    end
    return false
end

function XTheatre5PVERougeData:IsEnterAvgPlay(chapterId)
    if XTool.IsTableEmpty(self.HistoryChapters) then
        return false
    end
    for k, data in pairs(self.HistoryChapters) do
        if data.ChapterId == chapterId and data.IsEnterAvgPlay then
            return true
        end    
    end
    return false
end

function XTheatre5PVERougeData:IsPassAvgPlay(chapterId)
    if XTool.IsTableEmpty(self.HistoryChapters) then
        return false
    end
    for k, data in pairs(self.HistoryChapters) do
        if data.ChapterId == chapterId and data.IsPassAvgPlay then
            return true
        end    
    end
    return false
end

function XTheatre5PVERougeData:GetClueData(culeId)
    return self.PveClues and self.PveClues[culeId]
end

function XTheatre5PVERougeData:GetScriptData(scriptId)
    return self.PveScripts and self.PveScripts[scriptId]
end

--得到一个开始但未完成的推演id
function XTheatre5PVERougeData:GetOneNoCompleteScriptId()
    if XTool.IsTableEmpty(self.PveScripts) then
        return
    end
    for _, scriptData in pairs(self.PveScripts) do
        if not scriptData.IsComplete then
            return scriptData.ScriptId
        end    
    end    
end

function XTheatre5PVERougeData:CheckDuceScriptIsComplete(scriptId)
    if XTool.IsTableEmpty(self.PveScripts) then
        return false
    end

    for _, scriptData in pairs(self.PveScripts) do
        if scriptData.ScriptId == scriptId then
            return scriptData.IsComplete
        end
    end
    
    return false
end

function XTheatre5PVERougeData:GetOneNoCompleteDeduceStoryLineId()
    if XTool.IsTableEmpty(self.PveStoryLines) then
        return
    end
    local deduceScriptId = self:GetOneNoCompleteScriptId()
    if not XTool.IsNumberValid(deduceScriptId) then
        return
    end
    for _, storyLineData in pairs(self.PveStoryLines) do
        if XTool.IsNumberValid(storyLineData.CurContentId) then
            local storyLineContentCfg = self._OwnerModel:GetStoryLineContentCfg(storyLineData.CurContentId)
            if storyLineContentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Deduce
                and storyLineContentCfg.ContentId == deduceScriptId then
                    return storyLineData.StoryLineId
            end
        end                   
    end        
end

function XTheatre5PVERougeData:ClearData()
    self.CurPveStoryLineId = nil
    self.PveStoryLines = nil
    self.PveClues = nil
    self.HistoryChapters = nil
end

return XTheatre5PVERougeData