--- 结算存档槽位Grid
---@class XUiGridTheatre6SettlementEnemy : XUiNode
---@field _Control XTheatre6Control
---@field Parent XUiPanelTheatre6SettlementDetail
local XUiGridTheatre6SettlementEnemy = XClass(XUiNode, "XUiGridTheatre6SettlementEnemy")

function XUiGridTheatre6SettlementEnemy:OnStart()

end

---@param data table FightRecord {DifficultyType, FightResultType, FightId, MonsterId}
---@param index number
function XUiGridTheatre6SettlementEnemy:Update(data, index)
    self._Data = data

    local monsterConfig = self._Control:GetMonsterConfig(data.MonsterId)
    local characterConfig = self._Control:GetCharacterConfig(monsterConfig.CharacterId)
    local fashionConfig = self._Control:GetFashionConfig(characterConfig.FashionIds[1])
    self.UiRImgEnemy:SetRawImage(fashionConfig.Portrait)
    self.UiTxtDifficulty.text = XUiHelper.GetText(data.DifficultyType == 1 and "Theatre6DifficultyEasy" or "Theatre6DifficultyHard")

    self:ChangeState(data.FightResultType)
end

function XUiGridTheatre6SettlementEnemy:ChangeState(state)
    self.ImgDotWin.gameObject:SetActiveEx(state == XEnumConst.Theatre6.FightType.Win)
    self.ImgDotLose.gameObject:SetActiveEx(state == XEnumConst.Theatre6.FightType.Lose)
    self.ImgDotDead.gameObject:SetActiveEx(state == XEnumConst.Theatre6.FightType.Dead)
end

return XUiGridTheatre6SettlementEnemy