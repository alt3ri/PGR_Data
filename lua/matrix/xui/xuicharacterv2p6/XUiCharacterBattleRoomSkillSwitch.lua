local XUiCharacterSkillSwich = require("XUi/XUiCharacter/XUiCharacterSkillSwich")
local XUiCharacterBattleRoomSkillSwitch = XLuaUiManager.Register(XUiCharacterSkillSwich, "UiCharacterBattleRoomSkillSwitch")

function XUiCharacterBattleRoomSkillSwitch:OnStart(skillId, skillLevel, switchCb)
    self.SkillId = skillId
    self.SkillLevel = skillLevel
    self.SwitchCb = switchCb
    self.SkillExchangeDesConfig = XMVCA.XCharacter:GetSkillExchangeDesConfigBySkillId(skillId)
end

function XUiCharacterBattleRoomSkillSwitch:GetGridProxy()
    local XUiGridUiCharacterBattleRoomSkill = require("XUi/XUiCharacterV2P6/Grid/XUiGridUiCharacterBattleRoomSkill")
    return XUiGridUiCharacterBattleRoomSkill
end

function XUiCharacterBattleRoomSkillSwitch:DoOnRefresh()
    self.TxtTitle.text = XUiHelper.GetText("UiCharacterSkillSwitchTitle")
end

function XUiCharacterBattleRoomSkillSwitch:Refresh()
    self:DoOnRefresh()

    local curSkillId = self.SkillId
    local groupSkillIds = XMVCA.XCharacter:GetGroupSkillIds(curSkillId)

    self.Grids = self.Grids or {}
    for index, skillId in ipairs(groupSkillIds) do
        local grid = self.Grids[index]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.SkillItem, self.Content)
            local switchCb = function()
                self:Refresh()
                self.SwitchCb()
            end
            grid = self:GetGridProxy().New(go, self, switchCb)
            self.Grids[index] = grid
        end

        local isCurrent = XMVCA.XCharacter:IsSkillUsing(skillId)
        grid:Refresh(skillId, self.SkillLevel, isCurrent, index)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #groupSkillIds + 1, #self.Grids do
        self.Grids[i].GameObject:SetActiveEx(false)
    end
end

return XUiCharacterBattleRoomSkillSwitch