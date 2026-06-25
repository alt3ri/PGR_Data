local XUiPanelBossInshotTowerScoreTip = XClass(
    XUiNode, "XUiPanelBossInshotTowerScoreTip")

function XUiPanelBossInshotTowerScoreTip:SetLevel(
    levelConf,
    towerData,
    isAllClear,
    isFinalLevel)

    local getText = CS.XTextManager.GetText

    -- 全部通关的情况
    if isAllClear then
        self.TxtTips.text = getText("BossInshotTowerScoreTipAllClear")
        return
    end

    -- 已通关本层的情况
    if towerData.IsPass then
        self.TxtTips.text = getText("BossInshotTowerScoreTipStageClear")
        return
    end

    -- 尚未通关本层，且没有降层的情况
    if levelConf.FailReBackToId == -1 or levelConf.FailReBackToId == levelConf.Id then
        self.TxtTips.text = getText("BossInshotTowerScoreTipUnlockNext", levelConf.PassScore)
        return
    end

    -- 尚未通关本层，但有降层的情况
    local chances = levelConf.ProtectCount - towerData.TriggerProtectCount + 1

    local key

    if not isFinalLevel then
        key = "BossInshotTowerScoreTipUnlockNextFailN"

        if chances <= 1 then
            key = "BossInshotTowerScoreTipUnlockNextFail1"
        elseif chances == 2 then
            key = "BossInshotTowerScoreTipUnlockNextFail2"
        end
    else
        key = "BossInshotTowerScoreTipFinalFailN"

        if chances <= 1 then
            key = "BossInshotTowerScoreTipFinalFail1"
        elseif chances == 2 then
            key = "BossInshotTowerScoreTipFinalFail2"
        end
    end

    self.TxtTips.text = getText(
        key,
        levelConf.PassScore,
        levelConf.FailReBackToId + 1,
        chances)
end

return XUiPanelBossInshotTowerScoreTip
