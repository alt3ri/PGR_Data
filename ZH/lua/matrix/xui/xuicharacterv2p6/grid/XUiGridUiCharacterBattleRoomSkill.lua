local XUiGridBattleRoomSkillBase = require("XUi/XUiCharacterV2P6/Grid/XUiGridBattleRoomSkillBase")

---@class XUiGridUiCharacterBattleRoomSkill XUiGridUiCharacterBattleRoomSkill
---@field _Control XCharacterControl
local XUiGridUiCharacterBattleRoomSkill = XClass(XUiGridBattleRoomSkillBase, "XUiGridUiCharacterBattleRoomSkill")

function XUiGridUiCharacterBattleRoomSkill:OnClickBtnSelect()
    XMVCA.XCharacter:ReqSwitchSkill(self.SkillId, self.SwitchCb)
end

return XUiGridUiCharacterBattleRoomSkill