---@class XUiPanelLuosaitaFight
---@field _Control XMainLineLuosaitaControl
local XUiPanelLuosaitaFight = XClass(XUiNode, "XUiPanelLuosaitaFight")

function XUiPanelLuosaitaFight:OnStart()
    self.AllyUi = {}
    self.EnemyUi = {}
    XTool.InitUiObjectByUi(self.AllyUi, self.Ally)
    XTool.InitUiObjectByUi(self.EnemyUi, self.Enemy)
end

function XUiPanelLuosaitaFight:Refresh(allyData, enemyData)
    local allyCurHp = self._Control:GetPositionCurHp(allyData:GetPosId())
    local allyCurAttack = self._Control:GetPositionCurAttack(allyData:GetPosId())
    local enemCurHp = self._Control:GetPositionCurHp(enemyData:GetPosId())
    local enemCurAttack = self._Control:GetPositionCurAttack(enemyData:GetPosId())

    self.AllyUi.TxtAttack.text = tostring(allyCurAttack)
    self.AllyUi.TxtHP.text = tostring(allyCurHp)
    if enemCurAttack > 0 then
        self.AllyPreHp.text = "-" .. tostring( enemCurAttack)
    else
        self.AllyPreHp.text = ""
    end 
    self.AllyUi.ImgDead.gameObject:SetActiveEx(allyCurHp - enemCurAttack<= 0)
    self.EnemyUi.TxtAttack.text = tostring(enemCurAttack)
    self.EnemyUi.TxtHP.text = tostring(enemCurHp)
    self.EnemyPreHp.text = "-" .. tostring( allyCurAttack)
    self.EnemyUi.ImgDead.gameObject:SetActiveEx(enemCurHp - allyCurAttack <= 0)
end

return XUiPanelLuosaitaFight
