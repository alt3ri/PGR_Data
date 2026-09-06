local XUiGridTRWeaponResonanceDetailSkill = require("XUi/XUiTeamRecommend/Grid/XUiGridTRWeaponResonanceDetailSkill")
local XUiTeamRecommendWeaponResonanceDetailPopup = XLuaUiManager.Register(XLuaUi, "UiTeamRecommendWeaponResonanceDetailPopup")
local SlotCount = XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT

local function BuildSkillGridData(skillInfo, isTarget, actualSkillInfo, isBindCurrentCharacter)
    return {
        SkillInfo = skillInfo,
        IsTarget = isTarget,
        IsResonanced = isBindCurrentCharacter and actualSkillInfo and actualSkillInfo:IsSame(skillInfo) or false,
        IsNotResonanceCharacter = false,
    }
end

local function GetTargetSkillInfo(targetData)
    if not targetData or not XTool.IsNumberValid(targetData.ResonanceType) or not XTool.IsNumberValid(targetData.SkillId) then
        return nil
    end

    return XMVCA.XEquip:CreateResonanceSkillInfo(targetData.ResonanceType, targetData.SkillId)
end

-- 获取当前槽位有效的实际共鸣技能
local function GetActualSkillInfo(equipId, slot)
    if not XTool.IsNumberValid(equipId) then
        return nil
    end

    local skillInfo = XMVCA.XEquip:GetResonanceSkillInfo(equipId, slot)
    return XTool.IsNumberValid(skillInfo and skillInfo.Id) and skillInfo or nil
end

function XUiTeamRecommendWeaponResonanceDetailPopup:OnAwake()
    self.SlotGridList = {}
    self.SkillGridList = {}
    self.BtnTanchuangCloseBig:AddEventListener(handler(self, self.Close))
    self.BtnCloseMask:AddEventListener(handler(self, self.Close))
    self:InitSlotGrid()
end

function XUiTeamRecommendWeaponResonanceDetailPopup:OnStart(recommendCharData, selectSlot)
    self.RecommendCharData = recommendCharData
    self.CurSlot = selectSlot
    if not XTool.IsNumberValid(self.CurSlot) or self.CurSlot > SlotCount then
        self.CurSlot = 1
    end

    self.EquipId = self:GetTargetWeaponEquipId()
    self:RefreshSlotGrid()
    self:RefreshSkillList()
    self.PanelWeaponResnance:SelectIndex(self.CurSlot)
end

function XUiTeamRecommendWeaponResonanceDetailPopup:InitSlotGrid()
    local slotTransforms = { self.UIWeaponResonanceSkill01, self.UIWeaponResonanceSkill02, self.UIWeaponResonanceSkill03 }
    local slotButtons = {}
    for slot = 1, SlotCount do
        local transform = slotTransforms[slot]
        local grid = { Transform = transform, GameObject = transform.gameObject }
        XTool.InitUiObject(grid)
        self.SlotGridList[slot] = grid
        slotButtons[slot] = grid.BtnClick
    end

    self.PanelWeaponResnance:Init(slotButtons, function(slot) self:OnSlotClick(slot) end)
end

-- 刷新三个推荐武器共鸣槽及当前达成状态
function XUiTeamRecommendWeaponResonanceDetailPopup:RefreshSlotGrid()
    local resonanceList = self.RecommendCharData.WeaponResonanceList or {}
    local equip = XTool.IsNumberValid(self.EquipId) and XMVCA.XEquip:GetEquip(self.EquipId) or nil
    local isFiveStar = equip and XMVCA.XEquip:GetEquipStar(equip.TemplateId) == XEnumConst.EQUIP.FIVE_STAR
    for slot, grid in ipairs(self.SlotGridList) do
        local targetData = resonanceList[slot]
        local targetSkillInfo = GetTargetSkillInfo(targetData)
        local actualSkillInfo = GetActualSkillInfo(self.EquipId, slot)
        local bindCharacterId = XTool.IsNumberValid(self.EquipId) and XMVCA.XEquip:GetResonanceBindCharacterId(self.EquipId, slot)
        local isBindCurrentCharacter = not XTool.IsNumberValid(bindCharacterId) or bindCharacterId == self.RecommendCharData.CharacterId
        local isAchieved = targetSkillInfo and actualSkillInfo and isBindCurrentCharacter and (isFiveStar or actualSkillInfo:IsSame(targetSkillInfo))

        grid.RImgEmpty.gameObject:SetActiveEx(not targetSkillInfo)
        grid.BgEmpty.gameObject:SetActiveEx(not targetSkillInfo)
        grid.RImgResonance.gameObject:SetActiveEx(targetSkillInfo ~= nil)
        if targetSkillInfo then
            grid.RImgResonance:SetRawImage(targetSkillInfo.Icon)
        else
            grid.BtnClick:SetButtonState(CS.UiButtonState.Disable)
        end
        grid.BgNotAchieveDark.gameObject:SetActiveEx(targetSkillInfo ~= nil and not isAchieved)
        grid.BgEffectLight.gameObject:SetActiveEx(slot == self.CurSlot)
    end
end

-- 刷新当前槽位标题与技能列表
function XUiTeamRecommendWeaponResonanceDetailPopup:RefreshSkillList()
    self.TxtAwareness.text = CS.XTextManager.GetText("EquipResonanceSlotTitle", self.CurSlot)
    self.SkillDataList = self:BuildSkillDataList()
    XTool.UpdateDynamicItem(self.SkillGridList, self.SkillDataList, self.GridResonanceSkill, XUiGridTRWeaponResonanceDetailSkill, self)
end

-- 构造目标置顶并包含当前实际共鸣状态的技能列表
function XUiTeamRecommendWeaponResonanceDetailPopup:BuildSkillDataList()
    local characterId = self.RecommendCharData.CharacterId
    local previewList = XMVCA.XEquip:GetResonancePreviewSkillInfoListByTemplateId(self.RecommendCharData.WeaponId, characterId, self.CurSlot)
    local targetData = self.RecommendCharData.WeaponResonanceList[self.CurSlot]
    local targetInfo = GetTargetSkillInfo(targetData)
    local actualSkillInfo = GetActualSkillInfo(self.EquipId, self.CurSlot)
    local bindCharacterId = XTool.IsNumberValid(self.EquipId) and XMVCA.XEquip:GetResonanceBindCharacterId(self.EquipId, self.CurSlot)
    local isBindCurrentCharacter = not XTool.IsNumberValid(bindCharacterId) or bindCharacterId == characterId
    local targetSkillInfo
    local otherSkillInfoList = {}

    for _, skillInfo in ipairs(previewList) do
        if targetInfo and skillInfo:IsSame(targetInfo) then
            targetSkillInfo = skillInfo
        else
            table.insert(otherSkillInfoList, skillInfo)
        end
    end
    table.sort(otherSkillInfoList, function(a, b) return a.Id < b.Id end)

    local result = {}
    if targetSkillInfo then
        table.insert(result, BuildSkillGridData(targetSkillInfo, true, actualSkillInfo, isBindCurrentCharacter))
    end
    for _, skillInfo in ipairs(otherSkillInfoList) do
        table.insert(result, BuildSkillGridData(skillInfo, false, actualSkillInfo, isBindCurrentCharacter))
    end
    if actualSkillInfo and not isBindCurrentCharacter then
        table.insert(result, {
            SkillInfo = actualSkillInfo,
            IsTarget = false,
            IsResonanced = false,
            IsNotResonanceCharacter = true,
            CharacterId = bindCharacterId,
        })
    end
    return result
end

-- 只比较当前穿戴的目标模板武器
function XUiTeamRecommendWeaponResonanceDetailPopup:GetTargetWeaponEquipId()
    local equipId = XMVCA.XEquip:GetCharacterWeaponId(self.RecommendCharData.CharacterId)
    local equip = XTool.IsNumberValid(equipId) and XMVCA.XEquip:GetEquip(equipId) or nil
    return equip and equip.TemplateId == self.RecommendCharData.WeaponId and equipId or 0
end

function XUiTeamRecommendWeaponResonanceDetailPopup:OnSlotClick(slot)
    if self.CurSlot == slot then
        return
    end
	
	-- 没技能不给点击
    local resonanceList = self.RecommendCharData.WeaponResonanceList or {}
    if not GetTargetSkillInfo(resonanceList[slot]) then
        return
    end

    self.CurSlot = slot
    self:RefreshSlotGrid()
    self:RefreshSkillList()
end

return XUiTeamRecommendWeaponResonanceDetailPopup
