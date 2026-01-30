---@class XTheatre5PVEControl : XControl
---@field private _Model XTheatre5Model
---@field private _MainControl XTheatre5Control
local XTheatre5PVEControl = XClass(XControl, "XTheatre5PVEControl")

function XTheatre5PVEControl:OnInit()
 
end

function XTheatre5PVEControl:AddAgencyEvent()

end

function XTheatre5PVEControl:RemoveAgencyEvent()

end

function XTheatre5PVEControl:GetPveChapterCfg(chapterId)
    return self._Model:GetPveChapterCfg(chapterId)
end

function XTheatre5PVEControl:GetChapterLevelCfg(levelGroupId, level)
    return self._Model:GetChapterLevelCfg(levelGroupId, level)
end

function XTheatre5PVEControl:GetPveChapterLevelCfg(levelId)
    return self._Model:GetPveChapterLevelCfg(levelId)
end

function XTheatre5PVEControl:GetPVEEventCfg(eventId)
    return self._Model:GetPVEEventCfg(eventId)
end

function XTheatre5PVEControl:GetPveSceneChatCfgs(chatGroupId)
    return self._Model:GetPveSceneChatCfgs(chatGroupId)
end

function XTheatre5PVEControl:GetCurPveStoryLineId()
    return self._Model.PVERougeData:GetCurPveStoryLineId()
end

function XTheatre5PVEControl:GetCurStoryEntranceId()
    return self._Model.PVERougeData:GetCurStoryEntranceId()
end

--return PveStoryLineContent.Id
function XTheatre5PVEControl:GetStoryLineContentId(storyLineId)
    return self._Model.PVERougeData:GetStoryLineContentId(storyLineId)    
end

function XTheatre5PVEControl:GetCurChapterBattleData()
    return self._Model.PVEAdventureData:GetCurChapterBattleData()
end

function XTheatre5PVEControl:GetPveEventLevelCfgs(eventLevelGroupId)
    return self._Model:GetPveEventLevelCfgs(eventLevelGroupId)
end

function XTheatre5PVEControl:GetPveEventOptionCfgs(eventOptionGroupId)
    return self._Model:GetPveEventOptionCfgs(eventOptionGroupId)
end

function XTheatre5PVEControl:GetPveEventOptionCfg(eventOptionId)
    return self._Model:GetPveEventOptionCfg(eventOptionId)
end

function XTheatre5PVEControl:GetPVEEndingCfg(pveEndingId)
    return self._Model:GetPVEEndingCfg(pveEndingId)
end

function XTheatre5PVEControl:GetPveSceneChatStoryPoolCfg(chatStoryPoolId)
    return self._Model:GetPveSceneChatStoryPoolCfg(chatStoryPoolId)
end

function XTheatre5PVEControl:CanPveBattle()
    return self._Model.PVEAdventureData:CanPveBattle()
end

function XTheatre5PVEControl:GetItemBoxCfg(itemBoxId)
    return self._Model:GetItemBoxCfg(itemBoxId)
end

function XTheatre5PVEControl:GetItemBoxSelectData()
    return self._Model.PVEAdventureData:GetItemBoxSelectData()
end

function XTheatre5PVEControl:GetCurEventId()
    return self._Model.PVEAdventureData:GetCurEventId()
end

function XTheatre5PVEControl:GetStoryLineCfg(storyLineId)
    return  self._Model:GetStoryLineCfg(storyLineId)
end

function XTheatre5PVEControl:GetCharacterPveStoryEntranceCfg(characterId)
    return self._Model:GetCharacterPveStoryEntranceCfg(characterId)
end

function XTheatre5PVEControl:GetEventRoleIcon(eventId)
    local eventCfg = self:GetPVEEventCfg(eventId)
    return self:_GetEventInfoByCharacterId(eventCfg.RoleIcons)        
end

function XTheatre5PVEControl:GetEventRoleName(eventId)
    local eventCfg = self:GetPVEEventCfg(eventId)
    return self:_GetEventInfoByCharacterId(eventCfg.RoleNames)        
end

function XTheatre5PVEControl:GetEventRoleContent(eventId)
    local eventCfg = self:GetPVEEventCfg(eventId)
    return self:_GetEventInfoByCharacterId(eventCfg.RoleContents)        
end

--没有配对应的索引的数据就默认取第一个
function XTheatre5PVEControl:_GetEventInfoByCharacterId(infos)
    if XTool.IsTableEmpty(infos) then
        return
    end    
    local defaultRoleName = infos[1]
    local curCharacterId = self._Model.PVEAdventureData:GetCharacterId()
    if not XTool.IsNumberValid(curCharacterId) then
        return defaultRoleName
    end
    local characterCfg = self._Model:GetTheatre5CharacterCfgById(curCharacterId)
    if not XTool.IsNumberValid(characterCfg.Index) then
        return defaultRoleName
    end
    if string.IsNilOrEmpty(infos[characterCfg.Index]) then
        return defaultRoleName
    end
    return infos[characterCfg.Index] 
end

--是否有获得普通线索
function XTheatre5PVEControl:CheckHasClue(clueId)
    return self._Model.PVERougeData:CheckHasClue(clueId)
end


function XTheatre5PVEControl:UnlockDeduceScript(deduceScriptId)
    local deduceScriptCfg = self:GetDeduceScriptCfg(deduceScriptId)
    local clueCfgs = self:GetDeduceClueGroupCfgs(deduceScriptCfg.PreClueGroupId)
    for _, clueCfg in pairs(clueCfgs) do
        --核心线索不会获得，条件解锁了就有
        if clueCfg.Type == XMVCA.XTheatre5.EnumConst.PVEClueShowType.Core then
            local isCondition = XConditionManager.CheckConditionAndDefaultPass(clueCfg.ShowConditionId)
            if not isCondition then
                return false
            end
        end        
        if not self:CheckHasClue(clueCfg.Id) then
            return false
        end    
    end
    return true
end

function XTheatre5PVEControl:GetUnlockDeduceScriptCount(deduceScriptId)
    local deduceScriptCfg = self:GetDeduceScriptCfg(deduceScriptId)
    local clueGroupCfgs = self:GetDeduceClueGroupCfgs(deduceScriptCfg.PreClueGroupId) --PreClueGroupId中没有核心线索
    local count = 0
    for _, clueGroupCfg in pairs(clueGroupCfgs) do
        local clueCfg = self:GetDeduceClueCfg(clueGroupCfg.ClueId)
        if self:CheckHasClue(clueCfg.Id) then
            count = count + 1
        end    
    end
    return count
end

--角色和对应的故事线是否解锁
function XTheatre5PVEControl:IsCharacterAndStoryLineUnlock(characterId,entranceName)    
    if not XTool.IsNumberValid(characterId) or string.IsNilOrEmpty(entranceName) then
        return false
    end    
    local characterUnlock = self._Model.PVERougeData:IsCharacterUnlock(characterId)
    if not characterUnlock then
        return false
    end

    local storyEntranceCfg = self._Model:GetPveStoryEntranceCfg(entranceName)
    --入口有没有解锁
    if not XTool.IsNumberValid(storyEntranceCfg.StoryIsOpen) then
        return false
    end    

    local isUnlockStoryLine = self._Model.PVERougeData:IsUnlockStoryLine(storyEntranceCfg.StoryLine) --故事线是否解锁看服务器数据
    if not isUnlockStoryLine then
        return false
    end    
    local storyLineCfg = self._Model:GetStoryLineCfg(storyEntranceCfg.StoryLine)
    if storyLineCfg.StoryLineType == XMVCA.XTheatre5.EnumConst.PVEStoryLineType.Together then
        if not XTool.IsTableEmpty(storyLineCfg.StoryLineCharacter) then
            for _, characterIdTemp in pairs(storyLineCfg.StoryLineCharacter) do
                if characterIdTemp == characterId then
                    return true
                end    
            end
        end
        return false
    -- elseif storyLineCfg.StoryLineType == XMVCA.XTheatre5.EnumConst.PVEStoryLineType.Normal then
    --     if not XTool.IsNumberValid(storyEntranceCfg.StoryIsOpen) then
    --         return false
    --     end
    --     return XConditionManager.CheckCondition(storyLineCfg.StoryLineCondition)
    end
    return true                         
end

--点击共通线时，默认选择第一个解锁的角色
function XTheatre5PVEControl:GetFirstUnlockCharacterId(togetherLineEntranceName)
    local allCharacterCfgs = self._MainControl:GetTheatre5CharacterCfgs()
    if XTool.IsTableEmpty(allCharacterCfgs) then
        return
    end
    for _, cfg in pairs(allCharacterCfgs) do
        if self._Model.PVERougeData:IsCharacterUnlock(cfg.Id) and self:IsCharacterAndStoryLineUnlock(cfg.Id,togetherLineEntranceName) then
            return cfg.Id
        end    
    end       
end

function XTheatre5PVEControl:GetPveStoryEntranceCfg(entranceName)
    return self._Model:GetPveStoryEntranceCfg(entranceName)
end

function XTheatre5PVEControl:IsPveStoryEntranceOpen(entranceName)
    local config, isValid = self:GetPveStoryEntranceCfg(entranceName)
    if config then
        return true, isValid
    end
    return false, isValid
end

function XTheatre5PVEControl:GetPVEChatWriteTime()
    return self._Model:GetTheatre5ConfigValByKey('PveChatWriteTime')
end

function XTheatre5PVEControl:GetTeachingStoryLineId()
    return self._Model:GetTheatre5ConfigValByKey('TeachingPveStoryLineId') 
end

function XTheatre5PVEControl:GetStorySkipPage()
    return self._Model:GetTheatre5ConfigValByKey('SkipSotryPage') 
end

---@param right 回答正确
function XTheatre5PVEControl:GetDeduceTipsTime(right)
    return self._Model:GetTheatre5ConfigValByKey('DeduceTipsTime', right and 2 or 1) 
end

function XTheatre5PVEControl:GetClueBoardMaskScaleMinOrMax(isMin)
    local value = self._Model:GetTheatre5ConfigValByKey('ClueBoardMaskMinAndMax', isMin and 1 or 2)
    if not XTool.IsNumberValid(value) then
        value = isMin and 500 or 1000
    end
    return value/1000    
end

function XTheatre5PVEControl:GetClueBoardScaleLimitPoint()
    local value = self._Model:GetTheatre5ConfigValByKey('ClueBoardScaleLimitPoint')
    return value and value/1000 or 1 
end

function XTheatre5PVEControl:GetMainClueBoardRect(isWidth)
    local index = isWidth and 1 or 2
    local value = self._Model:GetTheatre5ConfigValByKey('MainClueBoardRect', index)
    return value and value or 0 
end

function XTheatre5PVEControl:GetClueBoardFocusTime()
    local value = self._Model:GetTheatre5ConfigValByKey('ClueBoardFocusTime')
    return value and value/1000 or 0.2  
end

function XTheatre5PVEControl:GetClueBoardProcessStep()
    local value = self._Model:GetTheatre5ConfigValByKey('PveSlideButton')
    return XTool.IsNumberValid(value) and value or 20  
end

function XTheatre5PVEControl:GetPveChapterLevelCfgs(levelGroupId)
    return self._Model:GetPveChapterLevelCfgs(levelGroupId)
end

--当前是否是教学故事线
function XTheatre5PVEControl:IsInTeachingStoryLine()
    return XMVCA.XTheatre5:IsInTeachingStoryLine() 
end

--点击物体触发的对话组
---@return chatGroupId,characters
function XTheatre5PVEControl:GetPveSceneChatClickObjectChatData(sceneObject)
    local chatPoolCfgs = self._Model:GetPveSceneChatObjectPoolCfgs(sceneObject)
    if not chatPoolCfgs then
        return
    end
    local showChatPoolDatas = {}
    local totalWeigh = 0
    for _, cfg in pairs(chatPoolCfgs) do
       if XConditionManager.CheckConditionAndDefaultPass(cfg.Condition) then
            local value = self._Model:GetData("Theatre5PveSceneChatObjectPool"..cfg.Id)
            local weigh = XTool.IsNumberValid(value) and cfg.Weigh or cfg.FirstWeigh
            totalWeigh = totalWeigh + weigh
            table.insert(showChatPoolDatas, {cfg, weigh})
       end      
    end
    if totalWeigh <= 0 then
        return
    end
    local random = math.random(1, totalWeigh)  
    local curAdd = 0
    for _,data in ipairs(showChatPoolDatas) do
        curAdd = curAdd + data[2]
        if curAdd >= random then
            self._Model:SaveData("Theatre5PveSceneChatObjectPool"..data[1].Id, 1)
            return data[1].SceneChatGroup, data[1].Characters
        end    
    end     
end

function XTheatre5PVEControl:IsUnlockStoryLine(storyLineId)
    return self._Model.PVERougeData:IsUnlockStoryLine(storyLineId)
end

--章节结束，只能用缓存的数据
function XTheatre5PVEControl:GetCurRunningNodeStoryLineId()
    return self._MainControl.FlowControl:GetCurRunningNodeStoryLineId()
end

function XTheatre5PVEControl:GetCurRunningNodeStoryLineContentId()
    return self._MainControl.FlowControl:GetCurRunningNodeStoryLineContentId()
end

--判断章节结束后能否再次战斗
function XTheatre5PVEControl:CanAgainBattle(resultData)
    --没有正在跑的故事线，在外部结算的, 外部有故事线推进代表章节结束，推演章节会这么做
    if self._MainControl.FlowControl:GetCurRunningNodeState() ~= XMVCA.XTheatre5.EnumConst.PVENodeState.Running then
        if resultData and resultData.XAutoChessGameplayResult.PveStoryLineData then
            return false
        end    
        return true
    end    
    if resultData and resultData.XAutoChessGameplayResult then
        if XTool.IsNumberValid(resultData.XAutoChessGameplayResult.BeforeStoryEntranceId) then --复刷章节可以再次战斗
            return true
        end
    end        
    local curBattleStoryLineId = self:GetCurRunningNodeStoryLineId()
    local curBattleStoryLineContentId = self:GetCurRunningNodeStoryLineContentId()
    if not XTool.IsNumberValid(curBattleStoryLineId) or not XTool.IsNumberValid(curBattleStoryLineContentId) then
        return false
    end    
    local storyLineContentId = self._Model.PVERougeData:GetStoryLineContentId(curBattleStoryLineId)
    if storyLineContentId == curBattleStoryLineContentId then --服务器contentId没更新说明该章节未通关
        return true
    end    
    return false
end

--故事线当前该执行的节点类型
function XTheatre5PVEControl:GetStoryLineCurNodeType(storyLineId, entranceName)
    local isStoryLineCompleted = self:IsStoryLineCompleted(storyLineId)
    local hasRepeatChapter = self:HasUnlockRepeatChapter(entranceName)
    if isStoryLineCompleted and hasRepeatChapter then
        return XMVCA.XTheatre5.EnumConst.PVEChapterType.NormalBattle --复刷章节也是战斗
    end
    local contentId = self:GetStoryLineContentId(storyLineId)
    if not XTool.IsNumberValid(contentId) then
        return
    end

    local contentCfg = self._Model:GetStoryLineContentCfg(contentId)
    return contentCfg and contentCfg.ContentType             
end

function XTheatre5PVEControl:GetChacterStoryDesc(entranceName)
    local entranceCfg = self:GetPveStoryEntranceCfg(entranceName)
    if not entranceCfg then
        return
    end
    local isStoryLineCompleted = self:IsStoryLineCompleted(entranceCfg.StoryLine)
    local hasRepeatChapter = self:HasUnlockRepeatChapter(entranceName)
    if isStoryLineCompleted then
        if hasRepeatChapter then
            return self._Model:GetTheatre5ClientConfigText('RepeatChapterChacterDesc')
        end
        return    
    end
    local contentId = self:GetStoryLineContentId(entranceCfg.StoryLine)
    if not XTool.IsNumberValid(contentId) then
        return
    end
    local contentCfg = self._Model:GetStoryLineContentCfg(contentId)
    return contentCfg and contentCfg.CharacterStoryDesc 
end

function XTheatre5PVEControl:GetDeduceClueCfg(clueId)
    return self._Model:GetDeduceClueCfg(clueId)
end

function XTheatre5PVEControl:GetDeduceClueCfgByScriptId(deduceScriptId)
    return self._Model:GetDeduceClueCfgByScriptId(deduceScriptId)
end

function XTheatre5PVEControl:GetDeduceScriptCfg(deduceScriptId)
    return self._Model:GetDeduceScriptCfg(deduceScriptId)
end

function XTheatre5PVEControl:GetPveDeduceQuestionCfgs(questionGroupId)
    return self._Model:GetPveDeduceQuestionCfgs(questionGroupId)
end

function XTheatre5PVEControl:GetScriptData(scriptId)
    return self._Model.PVERougeData:GetScriptData(scriptId)
end

function XTheatre5PVEControl:GetDeduceClueGroupCfgs(clueGroupId)
    return self._Model:GetDeduceClueGroupCfgs(clueGroupId) 
end

function XTheatre5PVEControl:GetFirstCharacterId(storyLineId)
    return self._Model:GetFirstCharacterId(storyLineId)
end

function XTheatre5PVEControl:GetStoryLineContentCfg(storyLineContentId, notips)
    return self._Model:GetStoryLineContentCfg(storyLineContentId, notips)
end

function XTheatre5PVEControl:IsStoryLineCompleted(storyLineId)
    return self._Model.PVERougeData:IsStoryLineCompleted(storyLineId)
end

function XTheatre5PVEControl:GetRouge5CurrencyCfg(currencyId)
    return self._Model:GetRouge5CurrencyCfg(currencyId)
end

function XTheatre5PVEControl:GetPveGoldLayerDesc(index)
    return self._Model:GetTheatre5ClientConfigText('PveGoldLayerDesc', index)
end

function XTheatre5PVEControl:GetEnterChapterStoryTips()
    return self._Model:GetTheatre5ClientConfigText('EnterChapterStoryTips')
end

function XTheatre5PVEControl:GetEventOptionIncomplete()
    return self._Model:GetTheatre5ClientConfigText('EventOptionIncomplete')
end

function XTheatre5PVEControl:GetPveVersionError()
    return self._Model:GetTheatre5ClientConfigText('PveVersionError')
end


function XTheatre5PVEControl:GetDeduceClueBoardCfgs()
    return self._Model:GetDeduceClueBoardCfgs()
end

function XTheatre5PVEControl:GetDeduceClueBoardCfg(deduceClueBoardId)
    return self._Model:GetDeduceClueBoardCfg(deduceClueBoardId)
end

function XTheatre5PVEControl:IsUnlockDeduceClueBoard(deduceClueBoardId)
    local clueBoardCfg = self:GetDeduceClueBoardCfg(deduceClueBoardId)
      local unlock = XConditionManager.CheckConditionAndDefaultPass(clueBoardCfg.ConditionId)
                and XTool.IsNumberValid(clueBoardCfg.IsOpen)
    return unlock            
end

function XTheatre5PVEControl:HasUnlockRepeatChapter(entranceName)
    local repeatChapterId = self:GetRepeatChapterId(entranceName)
    return XTool.IsNumberValid(repeatChapterId)
end

function XTheatre5PVEControl:GetRepeatChapterId(entranceName)
    local storyEntranceCfg = self._Model:GetPveStoryEntranceCfg(entranceName)
    if XTool.IsTableEmpty(storyEntranceCfg.RepeatChapter) then
        return false
    end    
    local isStoryLineCompleted = self._Model.PVERougeData:IsStoryLineCompleted(storyEntranceCfg.StoryLine)
    if not isStoryLineCompleted then
        return false
    end
    local count = #storyEntranceCfg.RepeatChapter --从后往前取，备用
    for i = count, 1, -1 do
        if XConditionManager.CheckConditionAndDefaultPass(storyEntranceCfg.RepeatChapterCondition[i]) then
            return storyEntranceCfg.RepeatChapter[i]
        end    
    end
end

--获得线索的状态
function XTheatre5PVEControl:GetClueState(clueId)
    local clueCfg = self._Model:GetDeduceClueCfg(clueId)
    local clueType = clueCfg.Type
    local clueData = self._Model.PVERougeData:GetClueData(clueId)
    if clueData then
        if clueData.IsComplete then
            return XMVCA.XTheatre5.EnumConst.PVEClueState.Completed
        end
        if clueType == XMVCA.XTheatre5.EnumConst.PVEClueType.Normal then 
            return XMVCA.XTheatre5.EnumConst.PVEClueState.Unlock  --核心线索不能获得
        end    
    end
    local iscontentCompletedOrUnlock = self._Model.PVERougeData:IsCompletedOrUnlockByContentId(clueCfg.OpenStoryLineContentId)
    local isCondition = XConditionManager.CheckConditionAndDefaultPass(clueCfg.ShowConditionId)
    if not iscontentCompletedOrUnlock or not isCondition then
        return XMVCA.XTheatre5.EnumConst.PVEClueState.NoShow
    end

    --核心线索可展示就是解锁了
    if clueType == XMVCA.XTheatre5.EnumConst.PVEClueType.Core then
        --核心线索不配推演默认完成
        if not XTool.IsNumberValid(clueCfg.ScriptId) then
            return XMVCA.XTheatre5.EnumConst.PVEClueState.Completed
        end    
        local scriptCfg = self._Model:GetDeduceScriptCfg(clueCfg.ScriptId)
        local clueGroupCfgs = self:GetDeduceClueGroupCfgs(scriptCfg.PreClueGroupId) 
        if not XTool.IsTableEmpty(clueGroupCfgs) then
            local canDeduce = true
            for k, cfg in pairs(clueGroupCfgs) do  --前置线索都解锁可以推演
                 local preClueData = self._Model.PVERougeData:GetClueData(cfg.ClueId)
                 if not preClueData then
                     canDeduce = false
                     break
                 end    
            end
            if canDeduce then
                return XMVCA.XTheatre5.EnumConst.PVEClueState.Deduce
            end         
        end
        return XMVCA.XTheatre5.EnumConst.PVEClueState.Unlock 
    else
        return XMVCA.XTheatre5.EnumConst.PVEClueState.Lock  --普通线索显示未获得就是未解锁
    end    
end

function XTheatre5PVEControl:GetStoryLineIdByScriptId(deduceScriptId)
    local storyLines = self._Model.PVERougeData:GetPveStoryLines()
    if XTool.IsTableEmpty(storyLines) then
        return
    end
    for _, storyLineData in pairs(storyLines) do
        if XTool.IsNumberValid(storyLineData.CurContentId) then
            local storyLineContentCfg = self._Model:GetStoryLineContentCfg(storyLineData.CurContentId)
            if storyLineContentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Deduce
                and storyLineContentCfg.ContentId == deduceScriptId then
                    return storyLineData.StoryLineId
            end
        end                   
    end        
end

function XTheatre5PVEControl:GetHistoryFinishEvents(chapterId)
    return self._Model.PVERougeData:GetHistoryFinishEvents(chapterId)
end

function XTheatre5PVEControl:IsEnterAvgPlay(chapterId)
    return self._Model.PVERougeData:IsEnterAvgPlay(chapterId)
end

function XTheatre5PVEControl:GetBattleStatus()
    return self._Model.PVEAdventureData:GetBattleStatus()
end

function XTheatre5PVEControl:GetChapterIdCompleted()
    return self._Model.PVEAdventureData:GetChapterIdCompleted()
end

function XTheatre5PVEControl:GetChapterLevelCompleted()
    return self._Model.PVEAdventureData:GetChapterLevelCompleted()
end

function XTheatre5PVEControl:GetTaskOrShopCfgs(taskShopType)
    return self._Model:GetTaskOrShopCfgs(taskShopType)
end

function XTheatre5PVEControl:SaveDeduceRecodeData(deduceData)
    if not deduceData or not XTool.IsNumberValid(deduceData.DeduceId) then
        return
    end    
    XSaveTool.SaveData(self:GetDeduceRecodeLocalKey(deduceData.DeduceId), deduceData)  
end

function XTheatre5PVEControl:GetDeduceRecodeData(deduceScriptId)
    if not XTool.IsNumberValid(deduceScriptId) then
        return
    end    
    local data = XSaveTool.GetData(self:GetDeduceRecodeLocalKey(deduceScriptId))
    if data then
        return data
    end
    local deduceData = {}
    deduceData.DeduceId = deduceScriptId
    deduceData.StartTimeStamp = XTime.GetServerNowTimestamp()
    local deduceScriptCfg = self:GetDeduceScriptCfg(deduceScriptId)
    local questionCfgs = self:GetPveDeduceQuestionCfgs(deduceScriptCfg.QuestionGroupId)
    deduceData.QuestionCount = XTool.IsTableEmpty(questionCfgs) and 0 or #questionCfgs
    deduceData.AnswerErrorList = {}  -- DeduceQuestionId -> Times
    self:SaveDeduceRecodeData(deduceData)
    return deduceData      
end

--推演打点
function XTheatre5PVEControl:DeduceRecode(deduceData)
    if not deduceData or not XTool.IsNumberValid(deduceData.DeduceId) then
        return
    end
    CS.XRecord.Record(deduceData, "30244", "Theatre5Deduce")    
    XSaveTool.RemoveData(self:GetDeduceRecodeLocalKey(deduceData.DeduceId))
end

function XTheatre5PVEControl:AddOnceAnswerError(deduceData, questionId)
    if not deduceData or not deduceData.AnswerErrorList then
        return
    end
    for i_, questionData in pairs(deduceData.AnswerErrorList) do
        if questionData.DeduceQuestionId == questionId then
           questionData.Times = questionData.Times + 1
           return
        end    
    end
    table.insert(deduceData.AnswerErrorList, {DeduceQuestionId = questionId, Times = 1})
    self:SaveDeduceRecodeData(deduceData)  
end

function XTheatre5PVEControl:GetDeduceRecodeLocalKey(deduceScriptId)
    return string.format("Theatre5_Deduce_Recode_%s_%s", XPlayer.Id, deduceScriptId)
end

function XTheatre5PVEControl:OnRelease()

end

--- 判断进入角色选择界面后是否立刻进入故事线
function XTheatre5PVEControl:CheckEnterContentInCharaChoose()
    -- 判断是否有故事线处于分支、回溯节点
    local storyLines = self._Model.PVERougeData:GetPveStoryLines()
    if XTool.IsTableEmpty(storyLines) then
        return
    end
    
    for _, storyLineData in pairs(storyLines) do
        if XTool.IsNumberValid(storyLineData.CurContentId) then
            local storyLineContentCfg = self._Model:GetStoryLineContentCfg(storyLineData.CurContentId)
            if storyLineContentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVENodeType.Branch
                    or storyLineContentCfg.ContentType == XMVCA.XTheatre5.EnumConst.PVENodeType.Backtrack then
                return storyLineData.StoryLineId
            end
        end
    end
end

--region Config

function XTheatre5PVEControl:GetClientConfigCrowModelOutLineShowCondition()
    return self._Model:GetTheatre5ClientConfigNum('CrowModelOutLineShowCondition')
end

function XTheatre5PVEControl:GetClientConfigCrowModelOutLineHideCondition()
    return self._Model:GetTheatre5ClientConfigNum('CrowModelOutLineHideCondition')
end

--endregion

return XTheatre5PVEControl