local XUiPanelBossInshotTowerChooseBossBeforeAllClear = XClass(
    XUiNode, "XUiPanelBossInshotTowerChooseBossBeforeAllClear")

local XUiPanelBossInshotTowerChooseBossBeforeAllClearSelectBtn = require(
    "XUi/XUiBossInshot/XUiPanelBossInshotTowerChooseBossBeforeAllClearSelectBtn")

local XUiPanelBossInshotTowerScoreTip = require(
    "XUi/XUiBossInshot/XUiPanelBossInshotTowerScoreTip")

function XUiPanelBossInshotTowerChooseBossBeforeAllClear:OnStart(
    switchModel, showBlackHole)

    self._SwitchModel = switchModel
end

function XUiPanelBossInshotTowerChooseBossBeforeAllClear:SetData(
    levelConf,
    towerData,
    onSelectCallback)

    self._OnSelectCallback = onSelectCallback

    if not self._ScoreTip then
        self._ScoreTip = XUiPanelBossInshotTowerScoreTip.New(
            self.PanelTowerTips, self)
    end

    self._ScoreTip:SetLevel(
        levelConf,
        towerData,
        false,
        self._Control:IsTowerFinalLevel(levelConf.Id))

    if not self._BossSelectCards then self._BossSelectCards = {} end

    XTool.SetDataForGenericGrid(
        self._BossSelectCards,
        towerData.DrawStageIds,
        self.GirdBoss.gameObject,
        self.ListBoss,
        self,
        XUiPanelBossInshotTowerChooseBossBeforeAllClearSelectBtn,
        handler(self, self.SelectBoss))

    self:SelectBoss(towerData.DrawStageIds[1])
    self.BtnFight.CallBack = handler(self, self.OnConfirm)
end

function XUiPanelBossInshotTowerChooseBossBeforeAllClear:SelectBoss(selectedStageId)
    self._SelectedStageId = selectedStageId
    self._SwitchModel(self._Control:GetTowerBossIdByStageId(selectedStageId))

    for _, btn in pairs(self._BossSelectCards) do
        btn:SetSelected(btn:GetStageId() == selectedStageId)
    end
end

function XUiPanelBossInshotTowerChooseBossBeforeAllClear:OnConfirm()
    self._OnSelectCallback(self._SelectedStageId)
end

return XUiPanelBossInshotTowerChooseBossBeforeAllClear
