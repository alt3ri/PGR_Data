local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")
---@class XUiFubenExperimentBattleRoomProxy : XUiBattleRoleRoomDefaultProxy
local XUiFubenExperimentBattleRoomProxy = XClass(XUiBattleRoleRoomDefaultProxy, "XUiFubenExperimentBattleRoomProxy")

---@param team XTeam
---@param stageId number
function XUiFubenExperimentBattleRoomProxy:GetIsCanEnterFight(team, stageId)
    -- 内部版本，如果队伍为空，也可以进入战斗
    if XMain.IsInternal and team:GetIsEmpty() then
        return true
    end
    return self.Super.GetIsCanEnterFight(self, team, stageId)
end

---@param rootUi XUiBattleRoleRoom
function XUiFubenExperimentBattleRoomProxy:AOPOnEnableAfter(rootUi)
    -- 内部版本, 如果队伍为空，按钮也可以点击
    if XMain.IsInternal and rootUi.Team:GetIsEmpty() then
        rootUi.BtnEnterFight:SetDisable(false, true)
    end
end

return XUiFubenExperimentBattleRoomProxy
