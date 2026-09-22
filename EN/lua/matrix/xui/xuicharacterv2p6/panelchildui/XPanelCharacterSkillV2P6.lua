---@class XPanelCharacterSkillV2P6 : XUiNode
---@field _Control XCharacterControl
local XPanelCharacterSkillV2P6 = XClass(XUiNode, "XPanelCharacterSkillV2P6")
local XUiGridSkillItemV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiGridSkillItemV2P6")

function XPanelCharacterSkillV2P6:OnStart()
    ---@type XCharacterAgency
    local ag = XMVCA:GetAgency(ModuleId.XCharacter)
    self.CharacterAgency = ag
    self.SkillGrids = {}
    self:InitButton()
end

function XPanelCharacterSkillV2P6:InitButton()
    self.BtnOneClick:AddEventListener(handler(self, self.OnBtnOneClickClick))
    XUiHelper.RegisterClickEvent(self, self.GridSkillItem7, self.OnGotoWeaponOverrunSkillDetail)
end

function XPanelCharacterSkillV2P6:OnBtnOneClickClick()
    XMVCA.XCharacter:OpenUiRoleCultureDetailMain(self.CharacterId)
end

function XPanelCharacterSkillV2P6:RefreshUiShow()
    self.CharacterId = self.Parent.ParentUi.CurCharacter.Id
    self.CurCharacter = self.Parent.ParentUi.CurCharacter

    self.BtnSkillTeach.gameObject:SetActive(XPanelCharacterSkillV2P6.BUTTON_SKILL_TEACH_ACTIVE)
    local isOneClickOpen = XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.CharacterOneClick)
        and self._Control:CheckRoleCultureHasAnyUpgradableByCurState(self.CharacterId)
    self.BtnOneClick.gameObject:SetActiveEx(isOneClickOpen)
    self:RefreshTrainingItemBubble()
    self.IsShow = true
    self.GameObject:SetActive(true)
    self:ShowSkillItemPanel()
    self:UpdateSkill()
end

--- 一键养成道具持有提示：有道具才展示气泡
function XPanelCharacterSkillV2P6:RefreshTrainingItemBubble()
    local count = self._Control:GetRoleCultureSpecialItemCount()
    self.GroupBubble.gameObject:SetActiveEx(count > 0)
    if count <= 0 then
        return
    end
    self.IconTrainingItem:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self._Control:GetRoleCultureSpecialItemId()))
    self.TxtItemNum.text = "x" .. count
end

function XPanelCharacterSkillV2P6:UpdateSkill()
    local characterId = self.CharacterId
    local characterType = XMVCA.XCharacter:GetCharacterType(self.CharacterId)
    local skills = XMVCA.XCharacter:GetCharacterSkills(characterId)
    local isShowEnhanceSkill = self.CharacterAgency:CheckIsShowEnhanceSkill(self.CharacterId)
    local isEnableGridSkillItem6 = isShowEnhanceSkill and characterType == XEnumConst.CHARACTER.CharacterType.Normal
    local isEnableGridSkillItem7 = self:IsShowWeaponOverrunLevel2Skill()
    local isShowPanelSkillItem6 = isEnableGridSkillItem6 or isEnableGridSkillItem7
    self.PanelSkillItem6.gameObject:SetActiveEx(true)

    for i = 1, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
        local grid = self.SkillGrids[i]
        if not grid  then
            grid = XUiGridSkillItemV2P6.New(self["GridSkillItem" .. i], self, self.Parent)
            grid:Open()
            grid:SetClickCb(function ()
                self:OnGotoSkillDetail(i)
            end)
            self.SkillGrids[i] = grid
        end
        grid:UpdateNormalSkillInfo(characterId, skills[i])
    end

    local characterSkillGateConfig = self.CharacterAgency:GetModelCharacterSkillGate()
    if isShowEnhanceSkill then
        for i = XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS + 1, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS + 2 do
            local grid = self.SkillGrids[i]
            if not grid then
                grid = XUiGridSkillItemV2P6.New(self["GridSkillItem" .. i], self, self.Parent)
                grid:Open()
                local skillGridIndex = i
                grid:SetClickCb(function ()
                    self:OnGotoEnhanceSkillDetail(skillGridIndex)
                end)
                self.SkillGrids[i] = grid
            end

            grid:UpdateEnhanceSkillInfo(characterId, characterSkillGateConfig[i])
        end

        if characterType == XEnumConst.CHARACTER.CharacterType.Normal then
            self.SkillGrids[5]:Close()
            self.SkillGrids[6]:Open()
        else
            self.SkillGrids[5]:Open()
            if isShowPanelSkillItem6 then
                self.SkillGrids[6]:Open()
            else
                self.SkillGrids[6]:Close()
            end
        end
    else
        if self.SkillGrids[5] then
            self.SkillGrids[5]:Close()
        else
            self.GridSkillItem5.gameObject:SetActiveEx(false)
        end

        local grid = self.SkillGrids[6]
        if not grid then
            grid = XUiGridSkillItemV2P6.New(self.GridSkillItem6, self, self.Parent)
            grid:Open()
            local skillGridIndex = XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS + 2
            grid:SetClickCb(function ()
                self:OnGotoEnhanceSkillDetail(skillGridIndex)
            end)
            self.SkillGrids[6] = grid
        end
        if isShowPanelSkillItem6 then
            grid:Open()
        else
            grid:Close()
        end
        grid:UpdateEnhanceSkillInfo(characterId, characterSkillGateConfig[6])
    end

    self.IsEnableGridSkillItem6 = isEnableGridSkillItem6
    self.IsEnableGridSkillItem7 = isEnableGridSkillItem7
    self.SkillGrids[6].Btn:SetDisable(not isEnableGridSkillItem6)
    self.GridSkillItem7.gameObject:SetActiveEx(isShowPanelSkillItem6)
    self.GridSkillItem7:SetDisable(not isEnableGridSkillItem7)
    self.GridSkillItem7:ShowReddot(false)
    if not isShowPanelSkillItem6 then
        self.SkillGrids[6]:Close()
    end
    self.PanelSkillItem6.gameObject:SetActiveEx(isShowPanelSkillItem6)
end

function XPanelCharacterSkillV2P6:IsShowWeaponOverrunLevel2Skill()
    local characterConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId, true)
    local exclusiveEquipId = characterConfig and characterConfig.ExclusiveEquipId
    if not XTool.IsNumberValid(exclusiveEquipId) then
        return false
    end

    return XMVCA.XEquip:GetWeaponOverrunAttrCfgByTemplateId(exclusiveEquipId, self.CharacterId) ~= nil
end

function XPanelCharacterSkillV2P6:HidePanel()
    self.BtnSkillTeach.gameObject:SetActive(XPanelCharacterSkillV2P6.BUTTON_SKILL_TEACH_ACTIVE)
    self.IsShow = false
    self.GameObject:SetActive(false)
    self:HideSkillItemPanel()
end

function XPanelCharacterSkillV2P6:HideSkillItemPanel()
    self.PanelSkillItems.gameObject:SetActive(false)
end

function XPanelCharacterSkillV2P6:ShowSkillItemPanel()
    self.PanelSkillItems.gameObject:SetActive(true)
    self.PanelSkillInfo.gameObject:SetActive(false)
    self.BtnSkillTeach.gameObject:SetActive(XPanelCharacterSkillV2P6.BUTTON_SKILL_TEACH_ACTIVE)
    self.SkillItemsQiehuan:PlayTimelineAnimation()
end

function XPanelCharacterSkillV2P6:OnGotoSkillDetail(i)
    XLuaUiManager.Open("UiSkillDetailsParentV2P6", self.CharacterId, XEnumConst.CHARACTER.SkillDetailsType.Normal, i)
    local skillEvoIndex = 4
    if i == skillEvoIndex then
        XMVCA.XCharacter:BuryingUiCharacterAction(self.Parent.Name, XGlobalVar.BtnUiCharacterSystemV2P6.BtnGridSkillItem4, self.CharacterId)
    end
end

---@param skillGridIndex number
function XPanelCharacterSkillV2P6:OnGotoEnhanceSkillDetail(skillGridIndex)
    local isShowEnhanceSkill = self.CharacterAgency:CheckIsShowEnhanceSkill(self.CharacterId)
    if not isShowEnhanceSkill then
        return
    end

    -- 此处 +2 对应技能面板的 GridSkillItem6（普通构造体跃升技能）
    local normalEnhanceSkillGridIndex = XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS + 2
    local isNormalEnhanceSkillGrid = skillGridIndex == normalEnhanceSkillGridIndex
    if isNormalEnhanceSkillGrid and not self.IsEnableGridSkillItem6 then
        return
    end

    -- 为的是将skill的第四个和 独域/跃升技能的界面连在一起。虽然他们并不是真的1-6这个顺序。但是在玩家看来是的
    XLuaUiManager.Open("UiSkillDetailsParentV2P6", self.CharacterId, XEnumConst.CHARACTER.SkillDetailsType.Enhance)
end

-- 谐振Ⅱ使用 GridSkillItem7
function XPanelCharacterSkillV2P6:OnGotoWeaponOverrunSkillDetail()
    if not self.IsEnableGridSkillItem7 then
        return
    end

    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.EquipOverrun) then
        local tips = XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.EquipOverrun)
        XUiManager.TipError(tips)
        return
    end

    XLuaUiManager.Open("UiSkillDetailsParentV2P6", self.CharacterId, XEnumConst.CHARACTER.SkillDetailsType.WeaponOverrun)
end

return XPanelCharacterSkillV2P6
