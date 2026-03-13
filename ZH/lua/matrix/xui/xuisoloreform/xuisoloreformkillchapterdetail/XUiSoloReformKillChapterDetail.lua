---@class XUiSoloReformKillChapterDetail : XUiSoloReformKillChapterDetailPartial
-- local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSoloReformKillChapterDetailGrid = require(
    "XUi/XUiSoloReform/XUiSoloReformKillChapterDetail/XUiSoloReformKillChapterDetailGrid")
local XUiSoloReformChapterDetail = require("XUi/XUiSoloReform/XUiSoloReformChapterDetail/XUiSoloReformChapterDetail")
local XUiSoloReformChapterStarInfo = require("XUi/XUiSoloReform/XUiSoloReformChapterDetail/XUiSoloReformChapterStarInfo")

local XUiSoloReformKillChapterDetail = XLuaUiManager.Register(XUiSoloReformChapterDetail, "UiSoloReformKillChapterDetail")

function XUiSoloReformKillChapterDetail:OnStart(chapterId, defaultSelectStage)
    self.IsKillMode = true
    self.Super.OnStart(self, chapterId, defaultSelectStage)
    self.PanelReform.gameObject:SetActiveEx(false)
end

function XUiSoloReformKillChapterDetail:InitPanel()
    self._StarInfo = XUiSoloReformChapterStarInfo.New(self.PanelTarget, self)
end

function XUiSoloReformKillChapterDetail:InitDifficultyList(chapterId)
    local chapterCfg = self._Control:GetSoloReformChapterCfg(chapterId)
    if XTool.IsTableEmpty(chapterCfg.ChapterStageIds) then
        return
    end
    self._CellList = {}
    local stageTypes = {}
    local tabGroup = {}
    self.GridBoss.gameObject:SetActiveEx(false)
    self.BtnBoss.gameObject:SetActiveEx(false)
    self._ReformUis = {}
    local selectIndex = 1

    for index, chapterStageId in pairs(chapterCfg.ChapterStageIds) do
        local stageType = self._Control:GetChapterStageStageType(chapterStageId)
        if not stageTypes[stageType] then
            local gridGo = XUiHelper.Instantiate(self.GridBoss, self.GridBoss.parent)
            gridGo.gameObject:SetActiveEx(true)
            table.insert(stageTypes, gridGo)
            self:RefreshGridGroup(gridGo, chapterStageId)

            self._ReformUis[stageType] = {}
        end
        local stageBtn = XUiHelper.Instantiate(self.BtnBoss, stageTypes[stageType])
        stageBtn.gameObject:SetActiveEx(true)
        self._CellList[chapterStageId] = {}
        self:RefreshGridItem(stageBtn, chapterStageId)
        tabGroup[index] = self._CellList[chapterStageId].BtnBoss
        local unlock = self._CellList[chapterStageId].Unlock
        if unlock then
            selectIndex = index
        end
    end
    local fightEventCfgs = self._Control:GetSoloReformUnlockFightEventCfgs(self._ChapterId)

    for index, cfg in pairs(fightEventCfgs) do
        table.insert(self._ReformUis[cfg.StageType], cfg)
    end

    -- self:InitDynamicTable()
    self.PanelTagGroup:Init(tabGroup, function(tabIndex)
        local chapterStageId = chapterCfg.ChapterStageIds[tabIndex]
        local stageType = self._Control:GetChapterStageStageType(chapterStageId)
        local unlock = self._CellList[chapterStageId].Unlock
        if unlock then
            self:OnClickDifficulty(chapterStageId)
            self:RefreshPanelReform(stageType)
        else
            XUiManager.TipText("SoloReformLastHardCompleted")
        end
    end)

  
    if self._ResumetageId then
        selectIndex = table.indexof(chapterCfg.ChapterStageIds, self._ResumetageId)
    end
    self.PanelTagGroup:SelectIndex(selectIndex)
    self._ResumetageId = nil
end

function XUiSoloReformKillChapterDetail:OnReleaseInst()
    local data = {
        CurStageId = self._CurStageId,
        CurSelectFightEventId = self._ReformUis[self.StageType].Id
    }
    return data
end

function XUiSoloReformKillChapterDetail:RefreshGridGroup(gridGo, firstStageId)
    local gridUi = {}
    XTool.InitUiObjectByUi(gridUi, gridGo)
    local stageCfg = self._Control:GetSoloReformStageCfg(firstStageId)
    gridUi.RImgBoss:SetRawImage(stageCfg.Img)
    gridUi.TxtName.text = stageCfg.StageEnemyName
end

function XUiSoloReformKillChapterDetail:RefreshGridItem(stageItemGo, stageId)
    local stageItemUi = {}
    local stageCfg = self._Control:GetSoloReformStageCfg(stageId)
    local starStateList = self._Control:GetStageStarStateByStageId(stageCfg.Id)
    XTool.InitUiObjectByUi(stageItemUi, stageItemGo)
    stageItemUi.GridStar.gameObject:SetActiveEx(false)
    self._CellList[stageId].BtnBoss = stageItemUi.BtnBoss
    self._CellList[stageId] = XUiHelper.RefreshUiObjectList(self._CellList[stageId], stageItemUi.GridStar.parent,
        stageItemUi.GridStar,
        stageCfg.StarNum, function(index, grid)
            grid.ImgStarOff.gameObject:SetActiveEx(not starStateList[index])
            grid.ImgStarOn.gameObject:SetActiveEx(starStateList[index])
        end)
    stageItemUi.BtnBoss:SetNameByGroup(0, stageCfg.TitleName)
    local score = self._Control:GetKillStageScore(self._ChapterId, stageId)
    stageItemUi.BtnBoss:SetNameByGroup(1, score or "") --score
    stageItemUi.BtnBoss:SetRawImageVisible(score ~= nil)
    if score then
        local levelicon = self._Control:GetScoreLevelIcon(score, stageCfg.Difficulty)
        stageItemUi.BtnBoss:SetRawImageVisible(levelicon ~= nil)
        stageItemUi.BtnBoss:SetRawImage(levelicon)
    end
    local unlock = XMVCA.XSoloReform:IsKillStageUnlock(self._ChapterId, stageId)
    stageItemUi.BtnBoss:SetDisable(not unlock)
    self._CellList[stageId].Unlock = unlock
    local rimgBossGroup = { stageItemUi.RImgBoss, stageItemUi.RImgBossNormal, stageItemUi.RImgBossSelect, stageItemUi
        .RImgBossDisable }
    for _, value in pairs(rimgBossGroup) do
        value:SetRawImage(stageCfg.Icon)
    end
end

function XUiSoloReformKillChapterDetail:RefreshPanelReform(stageType)
    self.ScrollListUi = self.ScrollListUi or {}
    self.UIPanelReform = self.UIPanelReform or {}
    if self.StageType == stageType then
        return
    end


    self.StageType = stageType
    for index, grid in pairs(self.UIPanelReform) do
        grid:Close()
    end

    for index, cfg in pairs(self._ReformUis[self.StageType]) do
        local gridUi = self.UIPanelReform[index]
        if not gridUi then
            local grid = XUiHelper.Instantiate(self.PanelReform, self.PanelReform.transform.parent)
            gridUi = XUiSoloReformKillChapterDetailGrid.New(grid, self)
            self.UIPanelReform[index] = gridUi
        end

        gridUi:Refresh(cfg)
        gridUi:Open()
    end
    self.ScrollListDetail.verticalNormalizedPosition = 1
    self._StarInfo.Time.gameObject:SetActiveEx(false)
    
end

return XUiSoloReformKillChapterDetail
