-- DAL 联动剧情关详情，复用预制 Assets/Product/Ui/Prefab/UiDALStage/UiDALDetailStory.prefab
-- （由 MainLine2 战斗详情预制拷贝而来，数据源换为 FubenFestivalActivityManager + 通用 XFuben）
---@class XUiDALDetailStory: XLuaUi
local XUiDALDetailStory = XLuaUiManager.Register(XLuaUi, "UiDALDetailStory")

function XUiDALDetailStory:OnAwake()
    self:RegisterUiEvents()
end

function XUiDALDetailStory:OnStart(stageId, festivalId, closeCb)
    self.StageId = stageId
    self.FestivalId = festivalId
    self.CloseCb = closeCb
    self:Refresh()
end

function XUiDALDetailStory:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
        self.CloseCb = nil
    end
end

function XUiDALDetailStory:RegisterUiEvents()
    self.BtnClose:AddEventListener(function() self:OnBtnCloseClick() end)
    self.BtnPlay:AddEventListener(function() self:OnBtnPlayClick() end)
end

function XUiDALDetailStory:OnBtnCloseClick()
    self:Close()
end

function XUiDALDetailStory:Refresh()
    local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(self.FestivalId, self.StageId)
    if not fStage then return end
    self.FStage = fStage

    local stageCfg = fStage:GetStageCfg()
    local chapter = fStage:GetChapter()
    if chapter then
        self.TxtName.text = string.format("%s%d %s", chapter:GetStagePrefix(), fStage:GetOrderIndex(), fStage:GetName())
    else
        self.TxtName.text = fStage:GetName()
    end
    self.TxtDesc.text = stageCfg and stageCfg.Description or ""
    self.ClearTag.gameObject:SetActiveEx(fStage:GetIsPass())

    -- DAL 剧情关统一走影片，隐藏 CG 分支
    if self.PanelMovie and self.PanelMovie.gameObject then
        self.PanelMovie.gameObject:SetActiveEx(true)
        self.PanelMovie:SetRawImage(fStage:GetDetailStoryBg())
    end
    if self.PanelCG and self.PanelCG.gameObject then
        self.PanelCG.gameObject:SetActiveEx(false)
    end
    self.RImgMovie:SetRawImage(fStage:GetStoryIcon())
end

function XUiDALDetailStory:OnBtnPlayClick()
    if not self.FStage then return end
    local beginStoryId = XMVCA.XFuben:GetBeginStoryId(self.StageId)
    if self.FStage:GetIsPass() then
        self:PlayStoryId(beginStoryId)
    else
        XDataCenter.FubenFestivalActivityManager.FinishStoryRequest(self.StageId, function()
            if XTool.UObjIsNil(self.GameObject) then return end
            XDataCenter.FubenFestivalActivityManager.RefreshStagePassedBySettleDatas({ StageId = self.StageId })
            self:PlayStoryId(beginStoryId)
        end)
    end
end

function XUiDALDetailStory:PlayStoryId(movieId)
    self:Close()
    XDataCenter.MovieManager.PlayMovie(movieId, nil, nil, nil, nil, nil, nil, self.StageId)
end

return XUiDALDetailStory
