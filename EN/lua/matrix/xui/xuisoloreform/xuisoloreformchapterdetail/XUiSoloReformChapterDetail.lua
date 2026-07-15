---@class XUiSoloReformChapterDetail: XLuaUi
---@field private _Control XSoloReformControl
local XUiSoloReformChapterDetail = XLuaUiManager.Register(XLuaUi, 'UiSoloReformChapterDetail')
local XUiSoloReformChapterDifficultyItem = require(
    "XUi/XUiSoloReform/XUiSoloReformChapterDetail/XUiSoloReformChapterDifficultyItem"
)
local XUiSoloReformChapterFightEvent = require(
    "XUi/XUiSoloReform/XUiSoloReformChapterDetail/XUiSoloReformChapterFightEvent"
)
local XUiSoloReformChapterStarInfo = require(
    "XUi/XUiSoloReform/XUiSoloReformChapterDetail/XUiSoloReformChapterStarInfo"
)

function XUiSoloReformChapterDetail:OnAwake()
    self._ChapterId = nil
    self._CurStageId = nil
    self._ResumetageId = nil
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnReturnMain, true)
    self:RegisterClickEvent(self.BtnTeaching, self.OnTeaching, true)
    self:RegisterClickEvent(self.BtnAgain, self.OnEnterBattle, true)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpString())
end

function XUiSoloReformChapterDetail:OnStart(chapterId, defaultSelectStage)
    self._ChapterId = chapterId
    self._ResumetageId = defaultSelectStage
    self:InitPanel()
    self:InitDifficultyList(chapterId)
    -- 放到start中，编队界面到期也会被踢出去
    self._Control:StartActivityEndCheckTimer()
    -- 最后一关关闭教学入口
    if chapterId == self._Control:GetLastSoloReformChapter().Id then
        self.BtnTeaching.gameObject:SetActiveEx(XUiHelper.GetClientConfig("SoloReformPracticeEntry", XUiHelper.ClientConfigType.Boolean))
    end
end

function XUiSoloReformChapterDetail:OnEnable()
    self._Control:AddEventListener(
        XMVCA.XSoloReform.EventId.EVENT_CLICK_DIFFICULTY_TAG, self.OnClickDifficultyTag, self
    )
end

function XUiSoloReformChapterDetail:OnDisable()
    self._Control:RemoveEventListener(
        XMVCA.XSoloReform.EventId.EVENT_CLICK_DIFFICULTY_TAG, self.OnClickDifficultyTag, self
    )
end

function XUiSoloReformChapterDetail:OnClickDifficultyTag(stageId)
    for i, id in ipairs(self._StageIds or {}) do
        if id == stageId then
            self:TrySelectTab(i)
            return
        end
    end
end

function XUiSoloReformChapterDetail:OnReleaseInst()
    return { CurStageId = self._CurStageId, CurSelectFightEventId = self._FightEvent:GetCurFightEventId() }
end

function XUiSoloReformChapterDetail:OnResume(data)
    if XTool.IsTableEmpty(data) then
        return
    end
    self._ResumetageId = self._ResumetageId or data.CurStageId
    self._ResumeFightEvent = data.CurSelectFightEventId
end

function XUiSoloReformChapterDetail:InitPanel()
    self._FightEvent = XUiSoloReformChapterFightEvent.New(self.PanelReform, self)
    self._FightEvent:ResumeCurFightEventId(self._ResumeFightEvent)
    self._StarInfo = XUiSoloReformChapterStarInfo.New(self.PanelTarget, self)
    self.GridBig.gameObject:SetActiveEx(false)
    self.GridSmall.gameObject:SetActiveEx(false)
    self._DifficultyItems = {}
end

function XUiSoloReformChapterDetail:ResetDifficultyItems()
    for _, item in pairs(self._DifficultyItems) do
        item:Close()
        CS.UnityEngine.GameObject.Destroy(item.GameObject)
    end
    self._DifficultyItems = {}
    for i, stageId in ipairs(self._StageIds or {}) do
        local isSelect = i == self._CurSelectIndex
        local prefab = isSelect and self.GridBig.gameObject or self.GridSmall.gameObject
        local go = XUiHelper.Instantiate(prefab, self.PanelDifficulty)
        go:SetActiveEx(true)
        local item = XUiSoloReformChapterDifficultyItem.New(go, self, isSelect)
        item:Update(stageId, i)
        table.insert(self._DifficultyItems, item)
    end
    XUiHelper.MarkLayoutForRebuild(self.PanelDifficulty)
end

function XUiSoloReformChapterDetail:InitDifficultyList(chapterId)
    local chapterCfg = self._Control:GetSoloReformChapterCfg(chapterId)
    self._StageIds = chapterCfg.ChapterStageIds or {}
    if XTool.IsTableEmpty(self._StageIds) then
        self._CurSelectIndex = 0
        return
    end
    self._CurSelectIndex = self:GetDefaultSelectIndex()
    self._ResumetageId = nil
    self:ApplyCurrentSelection()
end

function XUiSoloReformChapterDetail:GetDefaultSelectIndex()
    -- 优先恢复，否则取已解锁最高难度，兜底取第一项
    if XTool.IsNumberValid(self._ResumetageId) then
        for i, stageId in ipairs(self._StageIds) do
            if stageId == self._ResumetageId then
                return i
            end
        end
    end
    local defaultIndex, maxUnlockDifficulty = 1, -1
    for i, stageId in ipairs(self._StageIds) do
        local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
        if self._Control:IsStageUnlock(self._ChapterId, stageCfg.Difficulty)
            and stageCfg.Difficulty > maxUnlockDifficulty then
            maxUnlockDifficulty = stageCfg.Difficulty
            defaultIndex = i
        end
    end
    return defaultIndex
end

function XUiSoloReformChapterDetail:ApplyCurrentSelection()
    local stageId = self._StageIds[self._CurSelectIndex]
    self:ResetDifficultyItems()
    if not stageId then
        return
    end
    self:OnClickDifficulty(stageId)
end

function XUiSoloReformChapterDetail:TrySelectTab(index)
    if not XTool.IsNumberValid(index) then
        return
    end
    if self._CurSelectIndex == index then
        return
    end
    local stageId = self._StageIds[index]
    if not stageId then
        return
    end
    local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
    if not self._Control:IsStageUnlock(self._ChapterId, stageCfg.Difficulty) then
        XUiManager.TipText("SoloReformLastHardCompleted")
        return
    end
    self._CurSelectIndex = index
    self:ApplyCurrentSelection()
end

function XUiSoloReformChapterDetail:GetChapterId()
    return self._ChapterId
end

function XUiSoloReformChapterDetail:OnClickDifficulty(stageId)
    if not XTool.IsNumberValid(stageId) then
        return
    end
    if self._CurStageId == stageId then
        return
    end
    self._CurStageId = stageId
    self:RefreshSwitchDiff(stageId)
end

function XUiSoloReformChapterDetail:RefreshSwitchDiff(stageId)
    local chapterCfg = self._Control:GetSoloReformChapterCfg(self._ChapterId)
    self:RefreshCharacter()
    if not self.IsKillMode then
        self._FightEvent:Update(stageId)
    end
    self._StarInfo:Update(stageId)
    self.Logo02:SetRawImage(chapterCfg.StageLogo)
    local completedCount, totalCount = self._Control:GetChapterCompletedTaskCountAndTotal(self._ChapterId)
    self.TxtStarNum.text = string.format(
        "<color=%s>%d</color>/%d", self._Control:GetColor(), completedCount, totalCount
    )
    local minPassTime = self._Control:GetChapterStageMinPassTime(self._ChapterId)
    if not string.IsNilOrEmpty(minPassTime) then
        self.TxtTime.text = minPassTime
    else
        self.TxtTime.text = XUiHelper.GetText("SoloReformTimeShowNoPass")
    end
end

function XUiSoloReformChapterDetail:RefreshCharacter()
    local chapterCfg = self._Control:GetSoloReformChapterCfg(self._ChapterId)
    local characterId = self._Control:GetChapterCharacterId(self._ChapterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    self.TxtName.text = chapterCfg.Title
    self.RImgCharacterHead:SetRawImage(chapterCfg.HeadLogo)
end

function XUiSoloReformChapterDetail:OnReturnMain()
    XLuaUiManager.RunMain()
end

function XUiSoloReformChapterDetail:OnTeaching()
    local characterId = self._Control:GetChapterCharacterId(self._ChapterId)
    local groupId = XPracticeConfigs.GetGroupIdByCharacterId(characterId)
    if not groupId then
        return
    end
    local isLock = not XDataCenter.PracticeManager.CheckPracticeChapterOpen(groupId)
    if isLock then
        local _, description = XDataCenter.PracticeManager.CheckPracticeChapterOpen(groupId)
        XUiManager.TipMsg(description)
    else
        local skipId = XPracticeConfigs.GetPracticeSkipIdByGroupId(groupId)
        if XTool.IsNumberValid(skipId) then
            if XFunctionManager.IsCanSkip(skipId) then
                XFunctionManager.SkipInterface(skipId)
            else
                local skipCfg = XFunctionConfig.GetSkipFuncCfg(skipId)
                if skipCfg and XTool.IsNumberValid(skipCfg.FunctionalId) then
                    local desc = XFunctionManager.GetFunctionOpenCondition(skipCfg.FunctionalId)
                    XUiManager.TipMsg(desc)
                end
            end
        else
            XLuaUiManager.Open("UiFubenPracticeCharacterDetail", groupId)
        end
    end
end

function XUiSoloReformChapterDetail:CanSkipToTeaching()
    local characterId = self._Control:GetChapterCharacterId(self._ChapterId)
    local groupId = XPracticeConfigs.GetGroupIdByCharacterId(characterId)
    if not groupId then
        return false
    end
    local isLock = not XDataCenter.PracticeManager.CheckPracticeChapterOpen(groupId)
    if isLock then
        return false
    end
    local skipId = XPracticeConfigs.GetPracticeSkipIdByGroupId(groupId)
    if XTool.IsNumberValid(skipId) then
        if XFunctionManager.IsCanSkip(skipId) then
            return true
        end
    end
    return false
end

function XUiSoloReformChapterDetail:OnEnterBattle()
    XMVCA.XSoloReform:SetEnterChapterId(self._ChapterId)

    local team = XMVCA.XSoloReform:GetTeam(self._ChapterId)
    local proxy = require("XUi/XUiSoloReform/XUiSoloReformRoleRoom/XUiSoloReformRoleRoomProxy")
    XMVCA.XFuben:OpenUiBattleRoleRoomWithCallback(function ()
        self:AutoOpenTeachingMessage(self._ChapterId)
    end, self._CurStageId, team, proxy)
end

function XUiSoloReformChapterDetail:AutoOpenTeachingMessage(chapterId)
    local robotId = self._Control:GetChapterRobotId(chapterId)
    XDataCenter.PracticeManager.OnJoinTeam(robotId, function ()
        XDataCenter.PracticeManager.OpenUiFubenPractice(robotId, true)
    end, handler(self, self.CancelTeachingMessage)
    )
end

function XUiSoloReformChapterDetail:CancelTeachingMessage()
end

function XUiSoloReformChapterDetail:OnDestroy()
    self._Control:StopActivityEndCheckTimer()
    self._ChapterId = nil
    self._CurStageId = nil
    self._ResumetageId = nil
    self._DifficultyItems = nil
end

return XUiSoloReformChapterDetail
