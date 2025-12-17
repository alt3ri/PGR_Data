local XUiComTheatre5ChooseCharacter = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiComTheatre5ChooseCharacter')

---@class XUiComTheatre5PVEChooseCharacter: XUiComTheatre5ChooseCharacter
local XUiComTheatre5PVEChooseCharacter = XClass(XUiComTheatre5ChooseCharacter, 'XUiComTheatre5PVEChooseCharacter')

---@overload
function XUiComTheatre5PVEChooseCharacter:OnStart()
    XUiComTheatre5PVEChooseCharacter.Super.OnStart(self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_CHARACTER_HEAD, self.OnClickCharacterHead, self)
    if self.Parent.UiModelGo then
        self._UiModelGo = XTool.InitUiObjectByUi({}, self.Parent.UiModelGo)
        self._UiModelGo.FxWuya.gameObject:SetActiveEx(false)
    end    
end

---@overload
function XUiComTheatre5PVEChooseCharacter:OnEnable()
    XUiComTheatre5PVEChooseCharacter.Super.OnEnable(self)
    if not self._UiModelGo then
        return
    end
    if self._UiModelGo.FxHeiban then
        self._UiModelGo.FxHeiban.gameObject:SetActiveEx(self:CanDeduce())
    end    
end

function XUiComTheatre5PVEChooseCharacter:CanDeduce()
    local ClueBoardCfgs = self._Control.PVEControl:GetDeduceClueBoardCfgs()
    if XTool.IsTableEmpty(ClueBoardCfgs) then
        return false
    end    
    for _, ClueBoardCfg in pairs(ClueBoardCfgs) do
        local clueGroupCfgs = self._Control.PVEControl:GetDeduceClueGroupCfgs(ClueBoardCfg.ClueGroupId)
        if not XTool.IsTableEmpty(clueGroupCfgs) then
            for _, clueGroupCfg in pairs(clueGroupCfgs) do
                local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(clueGroupCfg.ClueId)
                if clueCfg.Type ==  XMVCA.XTheatre5.EnumConst.PVEClueType.Core then
                    local clueState = self._Control.PVEControl:GetClueState(clueCfg.Id)  
                    if clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Deduce then
                        local storyLineId = self._Control.PVEControl:GetStoryLineIdByScriptId(clueCfg.ScriptId) --能推演的同时在推演故事线节点
                        return XTool.IsNumberValid(storyLineId)
                    end    
                end 
            end
        end    
    end
    return false
end

---@overload
function XUiComTheatre5PVEChooseCharacter:_InitButtons()
    self.BtnRank.gameObject:SetActiveEx(false)
    self.BtnStart.CallBack = handler(self, self.OnBtnStartClickEvent)
    self.BtnTalk.CallBack = handler(self, self.OnBtnStartClickEvent)
    self.BtnAVG.CallBack = handler(self, self.OnBtnStartClickEvent)
    self.BtnDeduction.CallBack = handler(self, self.OnBtnStartClickEvent)
end

---@overload
function XUiComTheatre5PVEChooseCharacter:OnSelectCharacter(index, BtnName)
    self._EntranceName = BtnName
    local entranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(BtnName)
    if not entranceCfg then
        return false
    end
    --点击的是角色
    if XTool.IsNumberValid(index) then
        local isUnlock = self._Control.PVEControl:IsCharacterAndStoryLineUnlock(index,self._EntranceName)
        if not isUnlock then
           XUiManager.TipMsg(self._Control:GetCharacterLock()) 
           return false 
        end    
    end    
    local teachingStoryLineId = self._Control.PVEControl:GetTeachingStoryLineId()
    local storyLineCfg = self._Control.PVEControl:GetStoryLineCfg(entranceCfg.StoryLine)
    local isTeaching = entranceCfg.StoryLine == teachingStoryLineId 
        and storyLineCfg.StoryLineType == XMVCA.XTheatre5.EnumConst.PVEStoryLineType.Guide
    if isTeaching then
        local curContentId = self._Control.PVEControl:GetStoryLineContentId(entranceCfg.StoryLine)
        local characterId = self._Control.PVEControl:GetFirstCharacterId(entranceCfg.StoryLine)
        if not curContentId then                         --教学故事线未初始化
            XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(entranceCfg.StoryLine, nil, function()
                self._Control.FlowControl:EnterStroryLineContent(entranceCfg.StoryLine, nil, characterId)
            end)
            self:TeachingLineRecord()
        elseif XTool.IsNumberValid(curContentId) then    --教学故事线处于某节点
            self._Control.FlowControl:EnterStroryLineContent(entranceCfg.StoryLine, nil, characterId)
            self:TeachingLineRecord()
        end
        --否则教学故事线完成结束直接返回
        return false   
    end

    if storyLineCfg.StoryLineType == XMVCA.XTheatre5.EnumConst.PVEStoryLineType.Together 
        and not self._Control.PVEControl:IsUnlockStoryLine(entranceCfg.StoryLine) then  --点的是一个普通物体或共通线未解锁
        return false
    end    
    if not XTool.IsNumberValid(index) then  --共通线
        index = self._Control.PVEControl:GetFirstUnlockCharacterId(self._EntranceName)
    end
    --通知角色列表更新
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CLICK_SCENE_OBJECT)
    self._CharacterId = index   
    XUiComTheatre5PVEChooseCharacter.Super.OnSelectCharacter(self,index)
    self:UpdateActionBtns(self._EntranceName, index)
    return true
end

function XUiComTheatre5PVEChooseCharacter:TeachingLineRecord()
    local dict = {}
	dict["click_times"] = 1
    CS.XRecord.Record(dict, "30243", "Theatre5ClickTeachingLine")
end

function XUiComTheatre5PVEChooseCharacter:GetEntranceName()
    return self._EntranceName
end

function XUiComTheatre5PVEChooseCharacter:OnBtnStartClickEvent()
    local isUnlock = self._Control.PVEControl:IsCharacterAndStoryLineUnlock(self._CharacterId,self._EntranceName)
    if not isUnlock then
        return
    end
   
    local storyEntranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(self._EntranceName)
    local curStoryLineType = self._Control.PVEControl:GetStoryLineCurNodeType(storyEntranceCfg.StoryLine, self._EntranceName)
    if curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Deduce then
        if self:CheckIsShowDetail() then
            self:SwitchToFullView()
        end
        local contentId = self._Control.PVEControl:GetStoryLineContentId(storyEntranceCfg.StoryLine)
        local contentCfg = self._Control.PVEControl:GetStoryLineContentCfg(contentId)
        local mainClueId
        if contentCfg then
            local clueCfg = self._Control.PVEControl:GetDeduceClueCfgByScriptId(contentCfg.ContentId)
            mainClueId = clueCfg and clueCfg.Id
        end    
        XLuaUiManager.Open('UiTheatre5PVEClueBoard', mainClueId)
        return
    elseif curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Chat then
        self:SetChooseDetailShow(false, self._CharacterId)
        self._Control.FlowControl:EnterStroryLineContentWithCb(storyEntranceCfg.StoryLine, storyEntranceCfg.Id, self._CharacterId,
        XMVCA.XTheatre5.EnumConst.PVENodeType.Chat, function()
            self:SetChooseDetailShow(true, self._CharacterId)
        end)
        return       
    elseif curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.NormalBattle or 
        curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.DeduceBattle then
        local contentId = self._Control.PVEControl:GetStoryLineContentId(storyEntranceCfg.StoryLine)
        if XTool.IsNumberValid(contentId) then --无效可能是复刷章节
            local contentCfg = self._Control.PVEControl:GetStoryLineContentCfg(contentId)
            local isEnterAvgPlay = self._Control.PVEControl:IsEnterAvgPlay(contentCfg.ContentId)
            local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(contentCfg.ContentId)
            local isSkip = XTool.IsNumberValid(chapterCfg.CloseStoryTips) --跳过弹窗
            if not isSkip and not isEnterAvgPlay and not string.IsNilOrEmpty(chapterCfg.StartStory) then
                local content = self._Control.PVEControl:GetEnterChapterStoryTips()
                XUiManager.DialogTip(nil, content, XUiManager.DialogType.Normal, nil, 
                function()
                    if self:CheckIsShowDetail() then
                        self:SwitchToFullView()
                    end 
                    self._Control.FlowControl:EnterStroryLineContent(storyEntranceCfg.StoryLine, storyEntranceCfg.Id, self._CharacterId)
                end)
                return
            end
        end               
    end    
    if self:CheckIsShowDetail() then
        self:SwitchToFullView()
    end
    self._Control.FlowControl:EnterStroryLineContent(storyEntranceCfg.StoryLine, storyEntranceCfg.Id, self._CharacterId)    
end

function XUiComTheatre5PVEChooseCharacter:OnClickCharacterHead(entranceName, characterId)
    self._EntranceName = entranceName
    self._CharacterId = characterId
    self:UpdateActionBtns(entranceName, characterId)

end

--更新行动按钮
function XUiComTheatre5PVEChooseCharacter:UpdateActionBtns(entranceName, characterId)
    local entranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(entranceName)
    if not entranceCfg then
        return false
    end
    -- 角色由于剧情，暂时无法进入战斗
    local isCharacterCanSelect = self._Control:IsCharacterCanSelect(characterId)
    if not isCharacterCanSelect then
        self.BtnStart:SetButtonState(CS.UiButtonState.Disable)
        return
    end
    self.BtnStart:SetButtonState(CS.UiButtonState.Normal)
    
    local isUnlock = self._Control.PVEControl:IsCharacterAndStoryLineUnlock(characterId,entranceName)
    self.BtnStart:SetDisable(not isUnlock, isUnlock)
    local curStoryLineType = self._Control.PVEControl:GetStoryLineCurNodeType(entranceCfg.StoryLine, entranceName)
    local isTalk = isUnlock and curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Chat
    local isAVG = isUnlock and curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.AVG
    local isDeduce = isUnlock and curStoryLineType == XMVCA.XTheatre5.EnumConst.PVEChapterType.Deduce
    self.BtnStart.gameObject:SetActiveEx(not isTalk and not isAVG and not isDeduce)
    self.BtnTalk.gameObject:SetActiveEx(isTalk)
    self.BtnAVG.gameObject:SetActiveEx(isAVG)
    self.BtnDeduction.gameObject:SetActiveEx(isDeduce)
    self:CheckRepeatCharpter()
end

function XUiComTheatre5PVEChooseCharacter:CheckRepeatCharpter()
    local storyEntranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(self._EntranceName)  
    local isStoryLineCompleted = self._Control.PVEControl:IsStoryLineCompleted(storyEntranceCfg.StoryLine)
    if not isStoryLineCompleted then
        return
    end    
    local hasRepeatChapter = self._Control.PVEControl:HasUnlockRepeatChapter(self._EntranceName)
    self.BtnStart.gameObject:SetActiveEx(hasRepeatChapter)
end

--把镜头推进去掉
function XUiComTheatre5PVEChooseCharacter:SetChooseDetailShow(isShow, index)
    if isShow then
        self.PanelCharacterList:OnBtnSelect(index, true)
        self:UpdateActionBtns(self._EntranceName, self._CharacterId)
        self.DetailRoot.gameObject:SetActiveEx(true)
        self.PanelCharacterDetail:Open()
        self.PanelCharacterList:Open()
    else
        self.PanelCharacterDetail:Close()
        self.PanelCharacterList:Close()
        self.DetailRoot.gameObject:SetActiveEx(false)
    end
end

function XUiComTheatre5PVEChooseCharacter:OnDestroy()
    XUiComTheatre5PVEChooseCharacter.Super.OnDestroy(self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_CLICK_CHARACTER_HEAD, self.OnClickCharacterHead, self)
    self._UiModelGo = nil
end

function XUiComTheatre5PVEChooseCharacter:GetCurrentCharacterId()
    return self._CharacterId
end

return XUiComTheatre5PVEChooseCharacter