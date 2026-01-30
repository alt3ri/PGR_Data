local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEBattleNode:XTheatre5PVENode
local XTheatre5PVEBattleNode = XClass(XTheatre5PVENode, "XTheatre5PVEBattleNode")

function XTheatre5PVEBattleNode:Ctor()
    self._ChapterBattleData = nil
    self._IsPromote = false --是否已经推动过了，用来防止再次战斗的干扰
    self._IsBattleReturn = nil
end

---@param isBattleReturn 战斗节点跟战斗节点
function XTheatre5PVEBattleNode:SetData(chapterBattleData, isBattleReturn)
    self._ChapterBattleData = chapterBattleData
    self._IsBattleReturn = isBattleReturn
end

function XTheatre5PVEBattleNode:_OnEnter()
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_BATTLE_RESULT_EXIT, self.OnContinueChapter, self)
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_EXIT, self.OnWholeBattleExit, self)
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_AGAIN, self.OnAgainBattle, self)
    
    local curStatus = self._MainModel.CurAdventureData:GetCurPlayStatus()
    if curStatus == XMVCA.XTheatre5.EnumConst.PlayStatus.Battling then
        XMVCA.XTheatre5.BattleCom:RequestTheatre5InterruptBattle(function(giveUpSuccess, isFinish)
            if giveUpSuccess then
                if isFinish then
                    local mainControl = self._MainControl
                    self:Exit()
                    mainControl:ExitModel()
                else
                    XMVCA.XTheatre5.BattleCom:OpenMatchLoadingUi()
                end
            end
        end)
    elseif curStatus == XMVCA.XTheatre5.EnumConst.PlayStatus.BattleFinish or
            curStatus == XMVCA.XTheatre5.EnumConst.PlayStatus.NotStart then
        -- curStatus == XMVCA.XTheatre5.EnumConst.PlayStatus.ChoiceSkill then
        XMVCA.XTheatre5:RequestTheatre5EnterShop(function(success)
            if success then
                self:OpenShopPanel()
            end
        end)
    else
        self:OpenShopPanel()
    end
end

function XTheatre5PVEBattleNode:OpenShopPanel()
    if self._IsBattleReturn then
        XLuaUiManager.OpenWithCallback("UiTheatre5BattleShop", function()
            CsXUiManager.Instance:SetRevertAndReleaseLock(false)
        end)
    else     
        self:OpenUiPanel("UiTheatre5BattleShop")
    end       
end

---@param resultData XDlcFightSettleData
function XTheatre5PVEBattleNode:OnBattleResult(resultData)
    -- if not self._ChapterBattleData then
    --     return
    -- end    
    -- local maxLevelCfg = self._MainModel:GetMaxChapterLevelCfg(self._ChapterBattleData.ChapterId)
    -- --是不是最后一关
    -- if not self._ChapterBattleData.CurPveChapterLevel or maxLevelCfg.Id ~= self._ChapterBattleData.CurPveChapterLevel.Level then
    --     return
    -- end    
    -- --最后一关并且胜利了，推动章节进度
    -- if resultData and resultData.ResultData and resultData.ResultData.IsPlayerWin then
    --     local characterId = self._MainModel.PVERougeData:GetCharacterId()
    --     XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self._StoryLineId, characterId, self._CurStoryLineContentId, true)
    --     self._IsPromote = true
    -- end 
    
    
end

--整章战斗结束，胜利或失败
---@param resultData XDlcFightSettleData
function XTheatre5PVEBattleNode:OnWholeBattleExit(resultData)
    if not self._ChapterBattleData then --防止多触，已经退出的不再相应
        return
    end
    local isWin = resultData.ResultData.IsPlayerWin
     --没赢直接返回选择界面
    if not isWin then
        self:ChapterCompleted()
        return
    end
    --赢了判断是否播放AVG    
    local chapterCfg = self._MainModel:GetPveChapterCfg(self._ChapterBattleData.ChapterId)
    local isPassAvgPlay = self._MainModel.PVERougeData:IsPassAvgPlay(self._ChapterBattleData.ChapterId)
    if not isPassAvgPlay and not string.IsNilOrEmpty(chapterCfg.EndStory) then
        local chapterId = self._ChapterBattleData.ChapterId
        XDataCenter.MovieManager.PlayMovie(chapterCfg.EndStory,function()
            XMVCA.XTheatre5.PVEAgency:RequestPveAvgPlay(chapterId, false, function(success)
                if success then
                    self:ChapterCompleted()
                end        
            end)  
        end, nil, nil, false)
        return
    end
    self:ChapterCompleted()
end

--战斗结束返回继续
function XTheatre5PVEBattleNode:OnContinueChapter(resultData)
    if not self._ChapterBattleData then
        return
    end
    local isWin = resultData.ResultData.IsPlayerWin
    local nextNodeType = isWin and XMVCA.XTheatre5.EnumConst.PVENodeType.BattleChapterMain or XMVCA.XTheatre5.EnumConst.PVENodeType.Battle
    local chapterBattleData = self._MainModel.PVEAdventureData:GetCurChapterBattleData()
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CHAPTER_BATTLE_PROMOTE,
    self:GetUid(), nextNodeType, chapterBattleData, true)
end

--章节完成，回到选择界面
function XTheatre5PVEBattleNode:ChapterCompleted()
    local uiTheatre5ChooseCharacter = "UiTheatre5ChooseCharacter"
    local isOpen = XLuaUiManager.IsStackUiOpen(uiTheatre5ChooseCharacter)
    if isOpen then
        XLuaUiManager.CloseAllUpperUi(uiTheatre5ChooseCharacter, XMVCA.XTheatre5.EnumConst.GameMode.PVE) 
    else
        -- 需要判断是不是故事模式，复刷关没有故事线
        if XTool.IsNumberValidEx(self._StoryLineContentId) then
            ---@type XTableTheatre5PveStoryLineContent
            local cfg = self._MainModel:GetStoryLineContentCfg(self._StoryLineContentId)

            if cfg and cfg.IsTickOutToTitle then
                -- 如果本来就要踢出选人界面，那就不用再打开了
                XLuaUiManager.SafeClose('UiTheatre5Settlement')
            else
                XLuaUiManager.PopThenOpen(uiTheatre5ChooseCharacter, XMVCA.XTheatre5.EnumConst.GameMode.PVE)
            end
        else
            -- 非故事线中按照旧的逻辑就行
            XLuaUiManager.PopThenOpen(uiTheatre5ChooseCharacter, XMVCA.XTheatre5.EnumConst.GameMode.PVE)
        end
    end

    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_STORY_LINE_PROCESS_UPDATE, self._StoryLineId, nil, self._StoryLineContentId)
end

--章节结束再次战斗
function XTheatre5PVEBattleNode:OnAgainBattle(resultData)
    if not self._ChapterBattleData then
        return
    end
    local storyLineId = self._StoryLineId 
    local characterId = self._MainModel.PVEAdventureData:GetCharacterId()
    local mainControl = self._MainControl 
    XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_STORY_LINE_PROCESS_UPDATE)
    local beforeStoryEntranceId
    if resultData and resultData.XAutoChessGameplayResult then
        beforeStoryEntranceId = resultData.XAutoChessGameplayResult.BeforeStoryEntranceId
    end            
    mainControl:EnterStroryLineContent(storyLineId, beforeStoryEntranceId, characterId)
end

function XTheatre5PVEBattleNode:_OnExit()
    
end

function XTheatre5PVEBattleNode:_OnRelease()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_BATTLE_RESULT_EXIT,self.OnContinueChapter,self)
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_EXIT,self.OnWholeBattleExit,self)
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_WHOLE_BATTLE_AGAIN, self.OnAgainBattle, self)
    self._ChapterBattleData = nil
    self._IsBattleReturn = nil
end

return XTheatre5PVEBattleNode