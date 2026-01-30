---@class XUiPanelLuosaitaFight
---@field _Control XMainLineLuosaitaControl
local XUiPanelLuosaitaFight = XClass(XUiNode, "XUiPanelLuosaitaFight")

function XUiPanelLuosaitaFight:OnStart()
    self.AllyUi = {}
    self.EnemyUi = {}
    XTool.InitUiObjectByUi(self.AllyUi, self.Ally)
    XTool.InitUiObjectByUi(self.EnemyUi, self.Enemy)
end

---@param allyData XMainLineLuosaitaPositionInfo
---@param enemyData XMainLineLuosaitaPositionInfo
function XUiPanelLuosaitaFight:Refresh(allyData, enemyData)
    local allyCurHp = self._Control:GetPositionCurHp(allyData:GetPosId())
    local allyCurAttack = self._Control:GetPositionCurAttack(allyData:GetPosId())
    local enemyCurHp = self._Control:GetPositionCurHp(enemyData:GetPosId())
    local enemyCurAttack = self._Control:GetPositionCurAttack(enemyData:GetPosId())

    local armyHead = self._Control:GetConfig():GetArmyHead(allyData:GetArmyId())
    self.AllyUi.RImgHead:SetRawImage(armyHead)
    self.AllyUi.TxtAttack.text = tostring(allyCurAttack)
    self.AllyUi.TxtHP.text = tostring(allyCurHp)
    if enemyCurAttack > 0 then
        self.AllyPreHp.text = "-" .. tostring(enemyCurAttack)
    else
        self.AllyPreHp.text = ""
    end 
    self.AllyUi.ImgDead.gameObject:SetActiveEx(allyCurHp - enemyCurAttack <= 0)

    local enemyHead = self._Control:GetConfig():GetEnemyHead(enemyData:GetEnemyId())
    self.EnemyUi.RImgHead:SetRawImage(enemyHead)
    self.EnemyUi.TxtAttack.text = tostring(enemyCurAttack)
    self.EnemyUi.TxtHP.text = tostring(enemyCurHp)
    self.EnemyPreHp.text = "-" .. tostring( allyCurAttack)
    self.EnemyUi.ImgDead.gameObject:SetActiveEx(enemyCurHp - allyCurAttack <= 0)
end

return XUiPanelLuosaitaFight
