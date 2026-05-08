-- ============================================================
-- Grid（内联，仅供本文件使用）
-- ============================================================
local DescribeType = { Title = 1, Specific = 2 }

---@class XUiGridTeamPrefabSwitchSkill : XUiNode
local XUiGridTeamPrefabSwitchSkill = XClass(XUiNode, "XUiGridTeamPrefabSwitchSkill")

function XUiGridTeamPrefabSwitchSkill:Ctor(ui, parent, onSelectCb)
    self.OnSelectCb = onSelectCb
    self.BtnSelect.CallBack = function() self:OnBtnSelectClick() end
    self.TxtSkillTitleGo = {}
    self.TxtSkillSpecificGo = {}
    self.TxtSkillName.gameObject:SetActiveEx(false)
    self.TxtSkillbrief.gameObject:SetActiveEx(false)
end

function XUiGridTeamPrefabSwitchSkill:Refresh(skillId, skillLevel, isCurrent)
    self.SkillId = skillId
    self.SelectIcon.gameObject:SetActiveEx(isCurrent)
    self.BtnSelect.gameObject:SetActiveEx(not isCurrent)

    local gradeConfig = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(skillId, skillLevel)
    self.TxtSkillBT.text = gradeConfig.Name

    for _, go in pairs(self.TxtSkillTitleGo) do go:SetActiveEx(false) end
    for _, go in pairs(self.TxtSkillSpecificGo) do go:SetActiveEx(false) end
    for index, message in pairs(gradeConfig.SpecificDes or {}) do
        local title = gradeConfig.Title and gradeConfig.Title[index]
        if title then self:SetTextInfo(DescribeType.Title, index, title) end
        self:SetTextInfo(DescribeType.Specific, index, message)
    end
end

function XUiGridTeamPrefabSwitchSkill:SetTextInfo(txtType, index, info)
    local txtSkillGo, target
    if txtType == DescribeType.Title then
        txtSkillGo = self.TxtSkillTitleGo
        target = self.TxtSkillName.gameObject
    else
        txtSkillGo = self.TxtSkillSpecificGo
        target = self.TxtSkillbrief.gameObject
    end
    local txtGo = txtSkillGo[index]
    if not txtGo then
        txtGo = XUiHelper.Instantiate(target, self.PanelReward)
        txtSkillGo[index] = txtGo
    end
    txtGo:SetActiveEx(true)
    txtGo:GetComponent("Text").text = XUiHelper.ConvertLineBreakSymbol(info)
    txtGo.transform:SetAsLastSibling()
end

function XUiGridTeamPrefabSwitchSkill:OnBtnSelectClick()
    if self.OnSelectCb then self.OnSelectCb(self.SkillId) end
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
    local groupSkillId = XMVCA.XCharacter:GetSkillExchangeDesSkillIdAndConfigByCharacterId(characterId)
    if not groupSkillId then return end

    -- 优先读预设存储的选择，未设置时 fallback 角色全局激活态
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
            grid = XUiGridTeamPrefabSwitchSkill.New(go, self, function(selectedSkillId)
                self:OnSkillSelected(selectedSkillId)
            end)
            self.Grids[index] = grid
        end
        grid:Refresh(skillId, skillLevel, currentSkillId == skillId)
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
