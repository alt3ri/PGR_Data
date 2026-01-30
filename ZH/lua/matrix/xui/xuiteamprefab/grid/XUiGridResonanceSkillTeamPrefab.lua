local XUiGridResonanceDoubleSkillV2P6 = require("XUi/XUiEquip/XUiGridResonanceDoubleSkillV2P6")
---@class XUiGridResonanceSkillTeamPrefab : XUiGridResonanceDoubleSkillV2P6
local XUiGridResonanceSkillTeamPrefab = XClass(XUiGridResonanceDoubleSkillV2P6, "XUiGridResonanceSkillTeamPrefab")

function XUiGridResonanceSkillTeamPrefab:RefreshBySite(characterId, site)
    self.CharacterId = characterId
    local eqpData = self.RootUi.TeamPrefab:GetAwarenessData(self.RootUi.CurrentPos, site)
    self.EquipId = eqpData and eqpData.EquipId or 0

    self:RefreshTxtPos(site)
    local isWearing = self.EquipId and self.EquipId > 0
    if isWearing then
        --已穿戴装备
        self:RefreshResonanceSkill(characterId, self.EquipId)
    else
        --未穿戴装备
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self.PanelNoResnoanceSkill.gameObject:SetActiveEx(false)
        self.ImgPos.gameObject:SetActiveEx(false)
        self.GridResnanceSkill1.gameObject:SetActive(false)
        self.GridResnanceSkill2.gameObject:SetActive(false)
    end
end

-- 重写共鸣技能点击事件（预设界面可能不需要修改共鸣，按需求开启）
function XUiGridResonanceSkillTeamPrefab:OnBtnClick()
    -- 若允许在预设界面修改共鸣，可打开专用修改界面
    -- XLuaUiManager.Open("UiTeamPrefabEquipResonanceSkillChange", ...)
end

return XUiGridResonanceSkillTeamPrefab