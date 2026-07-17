local XBossInshotModel = require("XModule/XBossInshot/XBossInshotModel")

---@class XUiGridBossInshotTowerLevelSelectorBtn : XUiNode
---@field private _Control XBossInshotControl

local XUiGridBossInshotTowerLevelSelectorBtn = XClass(
    XUiNode, "XUiGridBossInshotTowerLevelSelectorBtn")

function XUiGridBossInshotTowerLevelSelectorBtn:SetData(levelConf, args)
    self._LevelConf = levelConf
    local isChallengeLevel = levelConf.Type == XBossInshotModel.TowerLevelType.ChallengeLevel

    self.BtnPanelLow.gameObject:SetActiveEx(not isChallengeLevel)
    self.BtnPanelHigh.gameObject:SetActiveEx(isChallengeLevel)

    local btn

    if isChallengeLevel then
        btn = self.BtnPanelHigh
    else
        btn = self.BtnPanelLow
    end

    self.BtnSelf = btn:GetObject("BtnSelf")
    self.BtnSelf.CallBack = handler(self, args.OnClickCallback)

    self.BtnSelf:SetName(
        CS.XTextManager.GetText("BossInshotTowerFloor", self._LevelConf.Id))

    local isLocked = self:IsLocked()
    local displayStageId = self:GetDisplayStageId()
    local txtScore = btn:GetObject("TxtScore")
    local rImgScore = btn:GetObject("RImgScore")
    local imgBgScore = btn:GetObject("ImgBgScore")

    rImgScore.gameObject:SetActiveEx(false)
    btn:GetObject("PanelScore").gameObject:SetActiveEx(not isLocked)
    imgBgScore.gameObject:SetActiveEx(false)

    self:RefreshRedPoint(args.RedPointCancelledLevel)

    if not isLocked then
        local levelData = self:GetBossTowerData()

        local record = nil

        if displayStageId ~= 0 then
            local bossId = self._Control:GetTowerBossIdByStageId(displayStageId)
            record = levelData.BossMaxScoreDict[bossId]
        end

        if record then
            local bestScore

            if XTool.IsTableEmpty(record.CharacterScoreDict) then
                bestScore = 0
            else
                local _, bestScore2 = XTool.MaxBy(
                    record.CharacterScoreDict,
                    function(_, v) return v end)

                bestScore = bestScore2
            end

            txtScore.text = tonumber(bestScore)

            local levelConf = self._Control:GetTowerScoreLevelConf(
                self._LevelConf.Id, bestScore)

            rImgScore.gameObject:SetActiveEx(true)
            rImgScore:SetRawImage(levelConf.LevelIcon)

            imgBgScore.gameObject:SetActiveEx(true)
        else
            txtScore.text = CS.XTextManager.GetText(
                "BossInshotTowerLevelSelectorBtnNoScore")
        end
    end

    self:_SetBossIcon(args.Control, btn, isChallengeLevel)
end

function XUiGridBossInshotTowerLevelSelectorBtn:RefreshRedPoint(
    redPointCancelledLevel)

    if self:IsLocked() then
        self.BtnSelf:ShowReddot(false)
        return
    end

    self.BtnSelf:ShowReddot(redPointCancelledLevel < self._LevelConf.Id)
end

function XUiGridBossInshotTowerLevelSelectorBtn:_SetBossIcon(
    control,
    btnUiObj,
    isChallengeLevel)

    local stageId = self:GetDisplayStageId()
    local showQuestion
    if stageId ~= 0 then
        local bossId = control:GetTowerBossIdByStageId(stageId)
        local icon = control:GetBossHeadIcon(bossId)
        showQuestion = false
        self.BtnSelf:SetRawImage(icon)
    else
        showQuestion = true
    end

    if isChallengeLevel then
        for i = 1, 4 do
            btnUiObj:GetObject("ImgQuestion" .. i).gameObject:SetActiveEx(showQuestion)
            btnUiObj:GetObject("RImgHead" .. i).gameObject:SetActiveEx(not showQuestion)
        end
    end
end

-- 获得要显示的关卡ID，用于展示Boss信息等
-- 如果是普通层则返回唯一一个StageId
-- 如果是挑战层，则返回当前选中的StageId，如果没有选中则返回0
function XUiGridBossInshotTowerLevelSelectorBtn:GetDisplayStageId()
    if self._LevelConf.Type == 1 then
        return self._LevelConf.Stages[1]
    else
        local levelData = self:GetBossTowerData()

        if self._Control:IsTowerAllClear()
            and levelData.SelectStageIdAfterAllPass
            and levelData.SelectStageIdAfterAllPass ~= 0 then

            return levelData.SelectStageIdAfterAllPass
        end

        if not levelData then
            return 0
        else
            return levelData.SelectStageId   -- 这里可能是0，需要等待玩家选择关卡
        end
    end
end

function XUiGridBossInshotTowerLevelSelectorBtn:SetSelected(selected)
    if self:IsLocked() then
        self.BtnSelf:SetButtonState(CS.UiButtonState.Disable)
    elseif selected then
        self.BtnSelf:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnSelf:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiGridBossInshotTowerLevelSelectorBtn:GetLevelConf()
    return self._LevelConf
end

function XUiGridBossInshotTowerLevelSelectorBtn:GetBossTowerData()
    return self._Control:GetBossTowerData(self._LevelConf.Id)
end


XUiGridBossInshotTowerLevelSelectorBtn.LockReason = {
    NotLocked = 0,
    NotReach = 1,
    NotInTime = 2
}

function XUiGridBossInshotTowerLevelSelectorBtn:IsLocked()
    return self:GetLockReason() ~= XUiGridBossInshotTowerLevelSelectorBtn.LockReason.NotLocked
end

function XUiGridBossInshotTowerLevelSelectorBtn:GetLockReason()
    if not XFunctionManager.CheckInTimeByTimeId(self._LevelConf.TimeId) then
        return XUiGridBossInshotTowerLevelSelectorBtn.LockReason.NotInTime
    end

    if self._LevelConf.Id > self._Control:GetBossTowerCurrentLevel() then
        return XUiGridBossInshotTowerLevelSelectorBtn.LockReason.NotReach
    end

    return XUiGridBossInshotTowerLevelSelectorBtn.LockReason.NotLocked
end

return XUiGridBossInshotTowerLevelSelectorBtn
