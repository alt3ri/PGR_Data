local LEVEL_PREFIX_FORMAT = "+%s"
local stringFormat = string.format
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local CSXTextManagerGetText = CS.XTextManager.GetText

local XUiPanelSkillLevelDetail = XClass(nil, "XUiPanelSkillLevelDetail")

function XUiPanelSkillLevelDetail:Ctor(ui)
    self.DetailGrids = {}
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridDetails.gameObject:SetActiveEx(false)
    self.BtnClose.CallBack = function() self.GameObject:SetActiveEx(false) end
end

function XUiPanelSkillLevelDetail:Refresh(characterId, skillId)
    local detailGrids = self.DetailGrids

    local grid = detailGrids.ResonanceLevel
    local resonanceLevel = XMVCA.XCharacter:GetResonanceSkillLevel(characterId, skillId)
    if resonanceLevel and resonanceLevel > 0 then
        if not grid then
            grid = self:NewGrid()
            detailGrids.ResonanceLevel = grid
        end

        grid.TxtName.text = CSXTextManagerGetText("CharacterSkillLevelDetailResonanace")
        grid.TxtLv.text = stringFormat(LEVEL_PREFIX_FORMAT, resonanceLevel)
        grid.GameObject:SetActiveEx(true)
    elseif grid then
        grid.GameObject:SetActiveEx(false)
    end

    local grid2 = detailGrids.AssignLevel
    local assignLevel = XDataCenter.FubenAssignManager.GetSkillLevel(characterId, skillId)
    if assignLevel and assignLevel > 0 then
        if not grid2 then
            grid2 = self:NewGrid()
            detailGrids.AssignLevel = grid2
        end

        grid2.TxtName.text = CSXTextManagerGetText("CharacterSkillLevelDetailAssign")
        grid2.TxtLv.text = stringFormat(LEVEL_PREFIX_FORMAT, assignLevel)
        grid2.GameObject:SetActiveEx(true)
    elseif grid2 then
        grid2.GameObject:SetActiveEx(false)
    end

    -- 新增：武器超限来源
    local grid3 = detailGrids.WeaponOverrunLevel
    local weaponLevel = XMVCA.XCharacter:GetWeaponOverrunUpSkillLevel(characterId, skillId)
    if weaponLevel and weaponLevel > 0 then
        if not grid3 then
            grid3 = self:NewGrid()
            detailGrids.WeaponOverrunLevel = grid3
        end
        grid3.TxtName.text = CSXTextManagerGetText("CharacterSkillLevelDetailWeaponOverrun")
        grid3.TxtLv.text = stringFormat(LEVEL_PREFIX_FORMAT, weaponLevel)
        grid3.GameObject:SetActiveEx(true)
    elseif grid3 then
        grid3.GameObject:SetActiveEx(false)
    end
end

function XUiPanelSkillLevelDetail:RefreshByNpcData(npcData, skillId, assignChapterRecords)
    local detailGrids = self.DetailGrids

    local grid = detailGrids.ResonanceLevel
    local resonanceSkillLevelMap = XMagicSkillManager.GetResonanceSkillLevelMap(npcData)
    local resonanceLevel = resonanceSkillLevelMap[skillId] or 0

    if resonanceLevel and resonanceLevel > 0 then
        if not grid then
            grid = self:NewGrid()
            detailGrids.ResonanceLevel = grid
        end

        grid.TxtName.text = CSXTextManagerGetText("CharacterSkillLevelDetailResonanace")
        grid.TxtLv.text = stringFormat(LEVEL_PREFIX_FORMAT, resonanceLevel)
        grid.GameObject:SetActiveEx(true)
    elseif grid then
        grid.GameObject:SetActiveEx(false)
    end

    local grid2 = detailGrids.AssignLevel
    local assignLevel = XDataCenter.FubenAssignManager.GetSkillLevelByCharacterData(npcData.Character, skillId, assignChapterRecords)
    if resonanceLevel and assignLevel > 0 then
        if not grid2 then
            grid2 = self:NewGrid()
            detailGrids.AssignLevel = grid2
        end

        grid2.TxtName.text = CSXTextManagerGetText("CharacterSkillLevelDetailAssign")
        grid2.TxtLv.text = stringFormat(LEVEL_PREFIX_FORMAT, assignLevel)
        grid2.GameObject:SetActiveEx(true)
    elseif grid2 then
        grid2.GameObject:SetActiveEx(false)
    end
end

function XUiPanelSkillLevelDetail:NewGrid()
    local grid = {}
    local go = CSUnityEngineObjectInstantiate(self.GridDetails, self.PanelDetails)
    grid.GameObject = go.gameObject
    grid.Transform = go.transform
    XTool.InitUiObject(grid)
    grid.GameObject:SetActiveEx(true)
    return grid
end

return XUiPanelSkillLevelDetail