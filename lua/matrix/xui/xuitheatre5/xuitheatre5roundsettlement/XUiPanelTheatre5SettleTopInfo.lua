local XUiPanelTheatre5TopInfo = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/XUiPanelTheatre5TopInfo')

---@class XUiPanelTheatre5SettleTopInfo: XUiPanelTheatre5TopInfo
local XUiPanelTheatre5SettleTopInfo = XClass(XUiPanelTheatre5TopInfo, 'XUiPanelTheatre5SettleTopInfo')
local XUiGridTheatre5SettleCup = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiGridTheatre5SettleCup')

---@overload
function XUiPanelTheatre5SettleTopInfo:OnStart()
    XUiPanelTheatre5TopInfo.OnStart(self)
    self._CupList = {}
end

---@overload
function XUiPanelTheatre5SettleTopInfo:OnDisable()
    XUiPanelTheatre5TopInfo.OnDisable(self)
    self:StopLifeChangeTimer()
end

function XUiPanelTheatre5SettleTopInfo:ShowBattleResult(isWin)
    self.IsWin = isWin
    self.TxtWin.gameObject:SetActiveEx(isWin)
    self.TxtLost.gameObject:SetActiveEx(not isWin)
end

---@overload
function XUiPanelTheatre5SettleTopInfo:RefreshPVPCupsShow()
    local cupsNum = self._Control:GetTrophyNum()
    local targetCount = self._Control.PVPControl:GetPVPTargetCountFromConfig()

    if not XTool.IsTableEmpty(self._CupList) then
        for i, v in pairs(self._CupList) do
            v:Close()
        end
    end
    
    XUiHelper.RefreshCustomizedList(self.ListCup.transform, self.GridCup, targetCount, function(index, go)
        local grid = self._CupList[go]

        if not grid then
            grid = XUiGridTheatre5SettleCup.New(go, self)
        end
        
        grid:Open()
        grid:SetCupIsOn(index <= cupsNum)
        
        -- 如果赢了，最新的奖杯播放显示动画
        if self.IsWin then
            if index == cupsNum then
                grid:PlayAnimation('StarEnable')
            end
        end
    end)

    -- 生成修饰用的UI
    if self.GroupDian and self.ImgDian then
        XUiHelper.RefreshCustomizedList(self.GroupDian.transform, self.ImgDian, targetCount - 1)
    end
end

---@overload
function XUiPanelTheatre5SettleTopInfo:RefreshPVECupsShow()
    local chapterIdCompleted = self._Control.PVEControl:GetChapterIdCompleted()
    local chapterLevelCompleted = self._Control.PVEControl:GetChapterLevelCompleted()
    local chapterCfg = self._Control.PVEControl:GetPveChapterCfg(chapterIdCompleted)
    local chapterLevelCfgs = self._Control.PVEControl:GetPveChapterLevelCfgs(chapterCfg.LevelGroup)
    local targetCount = #chapterLevelCfgs
    local curChapterLevel = chapterLevelCompleted
    if curChapterLevel == -1 then
        curChapterLevel = targetCount + 1
    end
    
    if not XTool.IsTableEmpty(self._CupList) then
        for i, v in pairs(self._CupList) do
            v:Close()
        end
    end

    XUiHelper.RefreshCustomizedList(self.ListCup.transform, self.GridCup, targetCount, function(index, go)
        local grid = self._CupList[go]

        if not grid then
            grid = XUiGridTheatre5SettleCup.New(go, self)
        end

        grid:Open()
        grid:SetCupIsOn(index < curChapterLevel)

        -- 如果赢了，最新的奖杯播放显示动画
        if self.IsWin then
            if index == curChapterLevel - 1 then
                grid:PlayAnimation('StarEnable')
            end
        end
    end)

    -- 生成修饰用的UI
    if self.GroupDian and self.ImgDian then
        XUiHelper.RefreshCustomizedList(self.GroupDian.transform, self.ImgDian, targetCount - 1)
    end

end

---@overload
function XUiPanelTheatre5SettleTopInfo:RefreshLifeShow()
    local health = self._Control.ShopControl:GetHealth()
    local healthMax = self._Control.PVPControl:GetPVPHealthMaxFromConfig()

    if not self.IsWin then
        -- 扣血都是-1，直接分两步显示，后面迭代扣血数存在>1 时再使用Tween
        self.TxtLifeNum.text = XUiHelper.FormatText(self._Control.PVPControl:GetHealthShowTextFromClientConfig(), health + 1, healthMax)
        self:PlayAnimation('Chunk')
        self:StartLifeChangeTimer(health, healthMax)
    else
        self.TxtLifeNum.text = XUiHelper.FormatText(self._Control.PVPControl:GetHealthShowTextFromClientConfig(), health, healthMax)
    end
end

--region 生命数变化动画

function XUiPanelTheatre5SettleTopInfo:StopLifeChangeTimer()
    if self._LifeChangeTimerId then
        XScheduleManager.UnSchedule(self._LifeChangeTimerId)
        self._LifeChangeTimerId = nil
    end
end

function XUiPanelTheatre5SettleTopInfo:StartLifeChangeTimer(health, healthMax)
    self:StopLifeChangeTimer()
    
    self._LifeChangeTimerId = XScheduleManager.ScheduleOnce(function()
        self.TxtLifeNum.text = XUiHelper.FormatText(self._Control.PVPControl:GetHealthShowTextFromClientConfig(), health, healthMax)
        self._LifeChangeTimerId = nil
    end, self._Control:GetClientConfigBattleLoseLifeChangeDelay() * XScheduleManager.SECOND)
end

--endregion

return XUiPanelTheatre5SettleTopInfo