--- 强化显示
---@class XUiSoloReformChapterFightEvent: XUiNode
---@field protected _Control XSoloReformControl
local XUiSoloReformChapterFightEvent = XClass(XUiNode, 'XUiSoloReformChapterFightEvent')
local XUiSoloReformChapterStrengthItem = require(
    "XUi/XUiSoloReform/XUiSoloReformChapterDetail/XUiSoloReformChapterStrengthItem"
)

function XUiSoloReformChapterFightEvent:OnStart()
    self._StrengthCellList = {}
    self._StageId = nil
    self._FightEventId = nil
    self:InitStrengthList()
end

function XUiSoloReformChapterFightEvent:OnEnable()
    self._Control:AddEventListener(XMVCA.XSoloReform.EventId.EVENT_CLICK_FIGHT_EVENT_TAG, self.OnClickStrength, self)
end

function XUiSoloReformChapterFightEvent:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XSoloReform.EventId.EVENT_CLICK_FIGHT_EVENT_TAG, self.OnClickStrength, self)
end

function XUiSoloReformChapterFightEvent:Update(stageId)
    self._StageId = stageId
end

function XUiSoloReformChapterFightEvent:InitStrengthList()
    local fightEventCfgs = self._Control:GetSoloReformUnlockFightEventCfgs(self:GetChapterId())
    if XTool.IsTableEmpty(fightEventCfgs) then
        return
    end
    local fightEventIds = {}
    for _, cfg in ipairs(fightEventCfgs) do
        table.insert(fightEventIds, cfg.FightEventId)
    end

    -- local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
    -- if XTool.IsTableEmpty(stageCfg.FightEventIds) then
    --     return
    -- end
    if self.GridReform then
        self._StrengthCellList = {}
        local buttons = {}
        XUiHelper.RefreshCustomizedList(self.GridReform.parent, self.GridReform, #fightEventIds, function (index, grid)
            local cell = self._StrengthCellList[index]
            if not cell then
                cell = XUiSoloReformChapterStrengthItem.New(grid, self)
                self._StrengthCellList[index] = cell
            end
            cell:Open()
            cell:Update(fightEventIds[index], self:GetCurFightEventId() == fightEventIds[index])
            table.insert(buttons, cell.BtnGridReform)
        end)
        self.BtnGroup:Init(buttons, function (index)
            self._StrengthCellList[index]:OnClickStrength()
            self:RefreshFightEventInfo(fightEventIds[index])
        end)
        self.BtnGroup:SelectIndex(1)
    end
end

function XUiSoloReformChapterFightEvent:GetChapterId()
    return self.Parent:GetChapterId()
end

function XUiSoloReformChapterFightEvent:ResumeCurFightEventId(fightEventId)
    if XTool.IsNumberValid(fightEventId) then
        self:OnClickStrength(fightEventId)
    end
end

function XUiSoloReformChapterFightEvent:GetCurFightEventId()
    return self._FightEventId
end

function XUiSoloReformChapterFightEvent:OnClickStrength(fightEventId)
    if self._FightEventId == fightEventId then
        return
    end
    self._FightEventId = fightEventId

    self:RefreshFightEventInfo(fightEventId)
end

function XUiSoloReformChapterFightEvent:RefreshFightEventInfo(fightEventId)
    local fightEventCfg = self._Control:GetSoloReformUnlockFightEvent(fightEventId)
    local chapterId = self:GetChapterId()
    local passDifficulty = self._Control:GetChapterPassDifficulty(chapterId)
    local isUnlock = fightEventCfg.UnlockDiff <= passDifficulty
    if self.PanelOn then
        self.PanelOn.gameObject:SetActiveEx(isUnlock)
    end
    if self.PanelOff then
        self.PanelOff.gameObject:SetActiveEx(not isUnlock)
    end
    local chapterCfg = self._Control:GetSoloReformChapterCfg(chapterId)
    for _, stageId in pairs(chapterCfg.ChapterStageIds) do
        local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
        if stageCfg.Difficulty == fightEventCfg.UnlockDiff then
            local battleStageCfg = XMVCA.XFuben:GetStageCfg(stageId)
            self.TxtOffTips.text = XUiHelper.GetText("SoloReformHardUnlock", battleStageCfg.Name)
            break
        end
    end

    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(fightEventCfg.Desc)

    local videoPlayer = self.VideoPlayer
    if XTool.IsNumberValid(fightEventCfg.VideoId) and not XTool.UObjIsNil(videoPlayer) then
        local videoPlayerInst = videoPlayer.VideoPlayerInst
        if not XTool.UObjIsNil(videoPlayerInst) then
            videoPlayer:SetInfoByVideoId(fightEventCfg.VideoId)
            videoPlayer:RePlay()
        end
    end
end

function XUiSoloReformChapterFightEvent:OnDestroy()
    self._StrengthCellList = nil
    self._FightEventId = nil
    self._StageId = nil
end

return XUiSoloReformChapterFightEvent
