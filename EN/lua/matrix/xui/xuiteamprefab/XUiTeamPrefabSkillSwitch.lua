local XUiGridBattleRoomSkillBase = require("XUi/XUiCharacterV2P6/Grid/XUiGridBattleRoomSkillBase")

---@class XUiGridTeamPrefabSwitchSkill : XUiGridBattleRoomSkillBase
local XUiGridTeamPrefabSwitchSkill = XClass(XUiGridBattleRoomSkillBase, "XUiGridTeamPrefabSwitchSkill")

function XUiGridTeamPrefabSwitchSkill:OnClickBtnSelect()
    self.Parent:OnSkillSelected(self.SkillId)
end

-- ============================================================
-- UI
-- ============================================================
---@class XUiTeamPrefabSkillSwitch : XLuaUi
local XUiTeamPrefabSkillSwitch = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabSkillSwitch")

function XUiTeamPrefabSkillSwitch:OnAwake()
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.OnBtnCloseClick)
    self.SkillItem.gameObject:SetActiveEx(false)
end

---@param xTeamPrefab XTeamPrefab
---@param pos int 站位
---@param closeCb function|nil 关闭后通知父 UI 刷新
function XUiTeamPrefabSkillSwitch:OnStart(xTeamPrefab, pos, closeCb)
    self.TeamPrefab = xTeamPrefab
    self.Pos = pos
    self.CloseCb = closeCb
end

function XUiTeamPrefabSkillSwitch:OnEnable()
    self:Refresh()
end

function XUiTeamPrefabSkillSwitch:Refresh()
    local characterId = self.TeamPrefab:GetEntityIdByTeamPos(self.Pos)
    local groupSkillId, skillExchangeConfig = XMVCA.XCharacter:GetSkillExchangeDesSkillIdAndConfigByCharacterId(characterId)
    if not groupSkillId then return end

    self.TxtTitle.text = XUiHelper.GetText("UiCharacterSkillSwitchTitle")
    self.SkillExchangeDesConfig = skillExchangeConfig

    -- 优先读预设存储的选择，未设置时使用配置命中的默认切换技能
    local currentSkillId = self.TeamPrefab:GetSwitchSkillByPos(self.Pos)
    if not currentSkillId then
        currentSkillId = groupSkillId
    end

    local groupSkillIds = XMVCA.XCharacter:GetGroupSkillIds(groupSkillId)
    local skillLevel = XMVCA.XCharacter:GetSkillLevel(groupSkillId)

    self.Grids = self.Grids or {}
    for index, skillId in ipairs(groupSkillIds) do
        local grid = self.Grids[index]
        if not grid then
            local go = CS.UnityEngine.Object.Instantiate(self.SkillItem, self.Content)
            grid = XUiGridTeamPrefabSwitchSkill.New(go, self)
            self.Grids[index] = grid
        end
        grid:Refresh(skillId, skillLevel, currentSkillId == skillId, index)
        grid.GameObject:SetActiveEx(true)
    end

    for i = #groupSkillIds + 1, #self.Grids do
        self.Grids[i].GameObject:SetActiveEx(false)
    end
end

function XUiTeamPrefabSkillSwitch:OnSkillSelected(skillId)
    self.TeamPrefab:UpdateSwitchSkillAtPos(self.Pos, skillId, nil, function()
        self:Close()
        if self.CloseCb then self.CloseCb() end
    end)
end

function XUiTeamPrefabSkillSwitch:OnBtnCloseClick()
    self:Close()
end
