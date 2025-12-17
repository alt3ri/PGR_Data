---@class XTheatre5PVEAgency
---@field private _OwnerAgency XTheatre5Agency
---@field private _Model XTheatre5Model
local XTheatre5PVEAgency = XClass(nil, 'XTheatre5PVEAgency')

function XTheatre5PVEAgency:Init(ownerAgency, model)
    self._OwnerAgency = ownerAgency
    self._Model = model
   
end

--region 协议请求

local function CommonRequestCallbcak(res,cb,func)
    if res.Code ~= XCode.Success then
        XUiManager.TipCode(res.Code)
        if cb then
            cb(false)
        end
        return
    end
    
    if func then
        func(res)
    end    

    if cb then
        cb(true,res)
    end

end

--故事线推进请求
function XTheatre5PVEAgency:RequestPveStoryLinePromote(storyLineId,storyLineContentId, cb)
    XNetwork.Call("PveStoryLinePromoteRequest", {StoryLineId = storyLineId,ContentId = storyLineContentId}, function(res)
            CommonRequestCallbcak(res,cb,function(res)
            --战斗章节完成不走主动推送，服务器自己处理
            self._Model.PVERougeData:UpdateChapterData(storyLineId, res.CurContentId, res.PveAdventureData)
            self._Model.PVERougeData:UpdateFinishChapterData(storyLineId, storyLineContentId)
            if not XTool.IsNumberValid(storyLineContentId) then --这是教学关的，要设置当前故事线
                self._Model.PVERougeData:UpdateCurStoryLineId(storyLineId)
            end    
            XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_STORY_LINE_PROCESS_UPDATE, storyLineId, res.CurContentId)
        end)
       
    end)
end

--事件推进请求
function XTheatre5PVEAgency:RequestPveEventPromote(eventId,optionId, cb)
    XNetwork.Call("PveEventPromoteRequest", {EventId = eventId,OptionId = optionId}, function(res)
            CommonRequestCallbcak(res,cb,function(res)
                if res.Code == XCode.Success then
                    self._Model.PVERougeData:UpdateGainClue(res.ClueId)
                    if not XTool.IsNumberValid(res.NextEventId) then
                        local chapterData = self._Model.PVEAdventureData:GetCurChapterBattleData()
                        local firstEventId = self._Model.PVEAdventureData:GetFirstEventId()
                        self._Model.PVERougeData:UpdateHistoryEvent(chapterData.ChapterId, firstEventId)
                    end    
                    self._Model.PVEAdventureData:UpdatePVENextEvent(res.NextEventId)
                    -- v4.0 新增经验值
                    local exp = self._Model.CurAdventureData:GetCharacterExp()
                    self._Model.CurAdventureData:UpdateCharacterExp(exp + res.Exp)
                    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_PVE_UPDATE_EVENT,res)
                end    
            end)
    end)
end

--战斗章节初始化
function XTheatre5PVEAgency:RequestPveChapterEnter(storyEntranceId,storyLineId,characterId,cb)
    XNetwork.Call("PveChapterEnterRequest", {StoryEntranceId = storyEntranceId, StoryLineId = storyLineId, CharacterId = characterId},
    function(res)
        CommonRequestCallbcak(res, cb, function(res)
            self._Model.PVEAdventureData:UpdatePVEAdventureData(res.PveAdventureData)
            self._Model.PVERougeData:UpdateCurStoryEntranceId(storyEntranceId)
            self._Model.PVERougeData:UpdateCurStoryLineId(storyLineId)  
        end)
    end)
end

--道具宝箱N选1
function XTheatre5PVEAgency:RequestItemBoxSelect(boxInstanceId, itemInstanceId, cb)
    XNetwork.Call("XTheatre5ItemBoxSelectRequest", {BoxInstanceId = boxInstanceId,ItemInstanceId = itemInstanceId}, function(res)
        CommonRequestCallbcak(res,cb, function(res)
            self._Model.PVEAdventureData:UpdateItemBoxSelectCompleted(boxInstanceId)
        end)
    end)
end

--打开宝箱
function XTheatre5PVEAgency:RequestItemBoxOpen(boxInstanceId, cb)
    XNetwork.Call("XTheatre5ItemBoxOpenRequest", {BoxInstanceId = boxInstanceId}, function(res)
        CommonRequestCallbcak(res, cb, function(res)
            if res.OpenType == XMVCA.XTheatre5.EnumConst.ItemBoxOpenType.SelectOne then
                self._Model.PVEAdventureData:UpdateAddItemBoxSelect(res.UsedInstanceId, res.ItemBoxSelectData)
            end    
        end)
    end)
end

--完成章节AVG
function XTheatre5PVEAgency:RequestPveAvgPlay(chapterId, isEnterAvg, cb)
    XNetwork.Call("PveAvgPlayRequest", {ChapterId = chapterId, IsEnterAvg = isEnterAvg}, function(res)
    CommonRequestCallbcak(res, cb, function(res)
        self._Model.PVERougeData:UpdateChapterAVGCompleted(chapterId, isEnterAvg)
    end)
end)
end

--回答推演问题
function XTheatre5PVEAgency:RequestAnswerQuestion(scriptId, step, isRightNum, cb)
    XNetwork.Call("XTheatre5PveAnswerQuestionRequest", {ScriptId = scriptId, Step = step, IsCorrect = isRightNum}, function(res)
        CommonRequestCallbcak(res, cb, function(res)
            if XTool.IsNumberValid(isRightNum) then
                self._Model.PVERougeData:UpdatePveScript(scriptId, step, res.IsScriptCompleted)
            end    
        end)
    end)
end


--endregion

function XTheatre5PVEAgency:IsCompletedByContentId(contentId)
    return self._Model.PVERougeData:IsCompletedByContentId(contentId)
end


--有拍脸节点
function XTheatre5PVEAgency:HaveForceNode()
    local haveChapterBattle = self._Model.PVEAdventureData:HaveChapterBattle()
    local endingNodeData = self._Model.PVERougeData:GetStoryLineEndingNodeData()
    return haveChapterBattle or endingNodeData ~= nil
end

function XTheatre5PVEAgency:Release()
    self._OwnerAgency = nil
    self._Model = nil
    self._AdvanceSettleContent = nil
end

--todo 协议请求

return XTheatre5PVEAgency
