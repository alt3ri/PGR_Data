--- 顶部信息栏
---@class XUiPanelTheatre5TopInfo: XUiNode
---@field protected _Control XTheatre5Control
local XUiPanelTheatre5TopInfo = XClass(XUiNode, 'XUiPanelTheatre5TopInfo')

function XUiPanelTheatre5TopInfo:OnStart()
    self.ListCup.gameObject:SetActiveEx(true)
end

function XUiPanelTheatre5TopInfo:OnEnable()
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW, self.RefreshCoinShow, self)
end

function XUiPanelTheatre5TopInfo:OnDisable()
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW, self.RefreshCoinShow, self)
end

function XUiPanelTheatre5TopInfo:RefreshAll()
    self:RefreshCoinShow()
    self:RefreshCupsShow()
    self:RefreshLifeShow()
end

function XUiPanelTheatre5TopInfo:RefreshCupsShow()
    local isPvp = self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP
    if isPvp then
        self:RefreshPVPCupsShow()
    else
        self:RefreshPVECupsShow()
    end

end

function XUiPanelTheatre5TopInfo:RefreshPVPCupsShow()
    local cupsNum = self._Control:GetTrophyNum()
    local targetCount = self._Control.PVPControl:GetPVPTargetCountFromConfig()
    local isPvpExtra = self._Control:CheckIsPvpExtra()

    self.ListCup.gameObject:SetActiveEx(not isPvpExtra)
    self.PanelOvertime.gameObject:SetActiveEx(isPvpExtra)

    if isPvpExtra then
        self:RefreshPVPExtraCups(cupsNum, targetCount)
    else
        self:RefreshPVPNormalCups(cupsNum, targetCount)
    end
end

function XUiPanelTheatre5TopInfo:RefreshPVPNormalCups(cupsNum, targetCount)
    self._CupList = XUiHelper.RefreshUiObjectList(self._CupList, self.ListCup, self.GridCup, targetCount, function(index, grid)
        if grid.ImgOn then
            grid.ImgOn.gameObject:SetActiveEx(index <= cupsNum)
        end
    end)
    self:RefreshDianUI(targetCount)
end

function XUiPanelTheatre5TopInfo:RefreshPVPExtraCups(cupsNum, targetCount)
    local extraTargetCount = self._Control.PVPControl:GetPvpExtraTargetCount()
    -- 额外杯
    local extraCupsNum = math.max(0, cupsNum - targetCount)
    self._CupOvertimeList = XUiHelper.RefreshUiObjectList(self._CupOvertimeList, self.ListCupOvertime, self.GridCupOvertime, extraTargetCount, function(index, grid)
        if grid.ImgOn then
            grid.ImgOn.gameObject:SetActiveEx(index <= extraCupsNum)
        end
    end)
end

function XUiPanelTheatre5TopInfo:RefreshDianUI(targetCount)
    -- 生成修饰用的UI
    if self.GroupDian and self.ImgDian then
        XUiHelper.RefreshCustomizedList(self.GroupDian.transform, self.ImgDian, targetCount - 1)
    end
end

function XUiPanelTheatre5TopInfo:RefreshPVECupsShow()
    local chapterIdCompleted = self._Control.PVEControl:GetChapterIdCompleted()
    local chapterLevelCompleted = self._Control.PVEControl:GetChapterLevelCompleted()
    local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(chapterIdCompleted)
    local chapterLevelCfgs = self._Control.PVEControl:GetPveChapterLevelCfgs(chapterCfg.LevelGroup)
    local targetCount = #chapterLevelCfgs
    local curChapterLevel = chapterLevelCompleted
    if curChapterLevel == -1 then
        curChapterLevel = targetCount + 1
    end
    self._CupList = XUiHelper.RefreshUiObjectList(self._CupList, self.ListCup, self.GridCup, targetCount, function(index, grid)
        if grid.ImgOn then
            grid.ImgOn.gameObject:SetActiveEx(index < curChapterLevel)
        end
    end)

    -- 生成修饰用的UI
    if self.GroupDian and self.ImgDian then
        XUiHelper.RefreshCustomizedList(self.GroupDian.transform, self.ImgDian, targetCount - 1)
    end

end

function XUiPanelTheatre5TopInfo:RefreshLifeShow()
    local health = self._Control.ShopControl:GetHealth()
    local healthMax = self._Control.PVPControl:GetPVPHealthMaxFromConfig()

    self.TxtLifeNum.text = XUiHelper.FormatText(self._Control.PVPControl:GetHealthShowTextFromClientConfig(), health, healthMax)
end

function XUiPanelTheatre5TopInfo:RefreshCoinShow()
    local goldNum = self._Control.ShopControl:GetGoldNum()
    self.TxtCoinNum.text = goldNum
end

return XUiPanelTheatre5TopInfo
