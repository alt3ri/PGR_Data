local XUiPanelBossInshotTowerChooseBossBeforeAllClearSelectBtn = XClass(
    XUiNode, "XUiPanelBossInshotTowerChooseBossBeforeAllClearSelectBtn")

function XUiPanelBossInshotTowerChooseBossBeforeAllClearSelectBtn:SetData(
    stageId, onClickCallback)

    self._StageId = stageId
    local bossId = self._Control:GetTowerBossIdByStageId(stageId)
    self.BtnSelf:SetName(self._Control:GetBossName(bossId))
    self.BtnSelf:SetRawImage(self._Control:GetBossHeadIcon(bossId))
    self.BtnSelf.CallBack = function() onClickCallback(self._StageId) end
end

function XUiPanelBossInshotTowerChooseBossBeforeAllClearSelectBtn:GetStageId()
    return self._StageId
end

function XUiPanelBossInshotTowerChooseBossBeforeAllClearSelectBtn:SetSelected(selected)
    if selected then
        self.BtnSelf:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnSelf:SetButtonState(CS.UiButtonState.Normal)
    end
end

return XUiPanelBossInshotTowerChooseBossBeforeAllClearSelectBtn
