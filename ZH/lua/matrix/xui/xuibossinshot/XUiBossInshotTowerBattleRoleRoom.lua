local XUiBossInshotBattleRoleRoom = require(
    "XUi/XUiBossInshot/XUiBossInshotBattleRoleRoom")

local XUiBossInshotTowerBattleRoleRoom = XClass(
    XUiBossInshotBattleRoleRoom,
    "XUiBossInshotTowerBattleRoleRoom")

function XUiBossInshotTowerBattleRoleRoom:Ctor(team, stageId, args)
    self.Team = team
    self.StageId = stageId
    self.Args = args
end

function XUiBossInshotTowerBattleRoleRoom:AOPOnClickFight()
    local isAssist = CS.UnityEngine.PlayerPrefs.GetInt(XPrefs.AssistSwitch .. XPlayer.Id) == 1

    XMVCA.XBossInshot:SetTowerLevelId(
        self.Args.TowerLevelConfig.Id,
        self.Args.CurrentLevelId)

    self:EnterFight(self.Team, self.StageId, nil, isAssist)
    return true
end

return XUiBossInshotTowerBattleRoleRoom
