local XUiFubenBossSingleHeadGrid = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleHeadGrid")

---@class XUiFubenBossSingleDetailPanelReset : XUiNode
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleDetailPanelReset = XClass(XUiNode, "XUiFubenBossSingleDetailPanelReset")

function XUiFubenBossSingleDetailPanelReset:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnClickHelp)
    XUiHelper.RegisterClickEvent(self, self.BtnReset, self.OnClickReset)

    self.GridBossAutoFight2 = XUiHelper.Instantiate(self.GridBossAutoFight1, self.GridBossAutoFight1.transform.parent)
    self.GridBossAutoFight3 = XUiHelper.Instantiate(self.GridBossAutoFight1, self.GridBossAutoFight1.transform.parent)
    ---@type XUiFubenBossSingleHeadGrid[]
    self._TeamMemberList = {
        XUiFubenBossSingleHeadGrid.New(self.GridBossAutoFight1, self),
        XUiFubenBossSingleHeadGrid.New(self.GridBossAutoFight2, self),
        XUiFubenBossSingleHeadGrid.New(self.GridBossAutoFight3, self),
    }
end

---@param config XTable.XTableBossSingleSection
function XUiFubenBossSingleDetailPanelReset:Update(config)
    if not config then
        XLog.Error("[XUiFubenBossSingleDetailPanelReset] 无效的config")
        return
    end
    self._CurBossStageConfig = config

    for _, grid in pairs(self._TeamMemberList) do
        grid:Close()
    end

    local autoFightData = self._Control:GetRecordCurrentByStageId(self._CurBossStageConfig.StageId)

    if not autoFightData then
        XUiManager.TipText("BossSingleAutoFightDesc1")
        return
    end

    for i, characterId in pairs(autoFightData.Characters) do
        if characterId > 0 then
            local grid = self._TeamMemberList[i]
            grid:SetCharacterId(characterId)
            grid:Open()
        end
    end

    local score = config.Score + self._Control:GetBaseScoreByStageId(self._CurBossStageConfig.StageId)
    --local curScore = autoFightData:GetScore() or 0
    local curScore = self._Control:GetStageCurrentScore(self._CurBossStageConfig.StageId)
    self.TxtScore1.text = curScore
    self.TxtScore2.text = "/" .. tostring(score)
end

function XUiFubenBossSingleDetailPanelReset:OnClickHelp()
    XUiManager.UiFubenDialogTip(XUiHelper.GetText("BossSingleTitleReset"), XUiHelper.GetText("BossSingleTipReset"))
end

function XUiFubenBossSingleDetailPanelReset:OnClickReset()
    if self._Control:IsResetCoolDown() then
        XUiManager.TipText("BossSingleResetCooldown")
        return
    end

    XMVCA.XFubenBossSingle:BossSingleResetStageRequest(self._CurBossStageConfig.StageId)
    self:Close()
    self._Control:StartResetCoolDown()
    self.Parent:ScheduleResetCooldown()
end

return XUiFubenBossSingleDetailPanelReset