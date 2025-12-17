local XUiGridBattleRoomSkillBase = require("XUi/XUiCharacterV2P6/Grid/XUiGridBattleRoomSkillBase")

---@class XUiGridUiRobotBattleRoomSkill XUiGridUiRobotBattleRoomSkill
---@field _Control XCharacterControl
local XUiGridUiRobotBattleRoomSkill = XClass(XUiGridBattleRoomSkillBase, "XUiGridUiRobotBattleRoomSkill")

function XUiGridUiRobotBattleRoomSkill:OnClickBtnSelect()
    ---@type XRobot
    local xRobot = self.Parent.XRobot
    local groupSkillIds = XMVCA.XCharacter:GetGroupSkillIds(self.SkillId)
    local removeLevel = nil
    for index, skillId in ipairs(groupSkillIds) do
        if skillId ~= self.SkillId then
            removeLevel = xRobot:RemoveSkillId(skillId)
        end
    end
    xRobot:AddSkillId(self.SkillId, removeLevel)
    if self.SwitchCb then
        self.SwitchCb()
    end
end

return XUiGridUiRobotBattleRoomSkill