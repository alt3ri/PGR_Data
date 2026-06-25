local XUiGridBossInshotPopupChangeBoss = XClass(
    XUiNode,
    "XUiGridBossInshotPopupChangeBoss")

function XUiGridBossInshotPopupChangeBoss:SetData(stageId, commonArgs)
    self._StageId = stageId
    local selectCallback = commonArgs.SelectCallback
    local control = commonArgs.Control
    self.BtnSelf.CallBack = function() selectCallback(stageId) end

    local bossId = control:GetTowerBossIdByStageId(stageId)
    self.BtnSelf:SetNameByGroup(0, control:GetBossName(bossId))
    self.BtnSelf:SetRawImage(control:GetBossHeadIcon(bossId))
    self.TransformTagNow.gameObject:SetActiveEx(commonArgs.CurrentSelected == stageId)
end

function XUiGridBossInshotPopupChangeBoss:SetSelected(selected)
    if selected then
        self.BtnSelf:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnSelf:SetButtonState(CS.UiButtonState.Normal)
    end
end

function XUiGridBossInshotPopupChangeBoss:GetStageId()
    return self._StageId
end

function XUiGridBossInshotPopupChangeBoss:PlayFlyInAnimation()
    self:PlayAnimation("Enable")
end

return XUiGridBossInshotPopupChangeBoss
