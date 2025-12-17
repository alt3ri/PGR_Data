local XUiCharacterSkillSwich = require("XUi/XUiCharacter/XUiCharacterSkillSwich")
local XUiRobotBattleRoomSkillSwitch = XLuaUiManager.Register(XUiCharacterSkillSwich, "UiRobotBattleRoomSkillSwitch")

function XUiRobotBattleRoomSkillSwitch:OnStart(skillId, skillLevel, switchCb, exchangeDesConfig, xRobot)
    self.SkillId = skillId
    self.SkillLevel = skillLevel
    self.SwitchCb = switchCb
    self.ExchangeDesConfig = exchangeDesConfig
    self.XRobot = xRobot
    self.SkillExchangeDesConfig = XRobotManager.GetRobotSkillExchangeDesConfigBySkillId(xRobot:GetId() ,skillId)
end

function XUiRobotBattleRoomSkillSwitch:GetGridProxy()
    local XUiGridUiRobotBattleRoomSkill = require("XUi/XUiCharacterV2P6/Grid/XUiGridUiRobotBattleRoomSkill")
    return XUiGridUiRobotBattleRoomSkill
end

function XUiRobotBattleRoomSkillSwitch:DoOnRefresh()
    self.TxtTitle.text = XUiHelper.GetText("UiCharacterSkillSwitchTitle")
end

function XUiRobotBattleRoomSkillSwitch:Refresh()
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

        local isCurrent = self.XRobot:IsSkillUsing(skillId)
        grid:Refresh(skillId, self.SkillLevel, isCurrent, index)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #groupSkillIds + 1, #self.Grids do
        self.Grids[i].GameObject:SetActiveEx(false)
    end
end

return XUiRobotBattleRoomSkillSwitch