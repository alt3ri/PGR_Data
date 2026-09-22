--- 武器共鸣技能详情弹窗：展示某槽位的可选共鸣技能列表，纯展示不能选择
---@class XUiEquipGridWeaponResonanceDetailPopup : XLuaUi
---@field _Control XEquipControl
local XUiEquipGridWeaponResonanceDetailPopup = XLuaUiManager.Register(XLuaUi, "UiEquipGridWeaponResonanceDetailPopup")

local XUiGridWeaponResonanceDetailSkill = require("XUi/XUiEquip/XUiEquipGridWeaponResonanceDetailPopup/XUiGridWeaponResonanceDetailSkill")

local SLOT_COUNT = 3

function XUiEquipGridWeaponResonanceDetailPopup:OnAwake()
    self.SlotGrids = {}
    self.GridSkillList = {}
    self:RegisterButtonEvent()
    self:InitSlotGrids()
end

function XUiEquipGridWeaponResonanceDetailPopup:RegisterButtonEvent()
    self.BtnTanchuangCloseBig:AddEventListener(handler(self, self.Close))
    self.BtnCloseMask:AddEventListener(handler(self, self.Close))
end

--- params = { EquipId, TemplateId, CharacterId, TargetSkillIds={id1,id2,id3}, InitSlot=1~3 }
function XUiEquipGridWeaponResonanceDetailPopup:OnStart(params)
    self.EquipId = params.EquipId or 0
    self.TemplateId = params.TemplateId or 0
    self.CharacterId = params.CharacterId or 0
    self.TargetSkillIds = params.TargetSkillIds or {}
    self.TargetResonanceTypes = params.TargetResonanceTypes or {}
    self.CurSlot = params.InitSlot or 1
    if self.CurSlot < 1 or self.CurSlot > SLOT_COUNT then
        self.CurSlot = 1
    end
    if not XTool.IsNumberValid(self.TemplateId) then
        local equip = XMVCA.XEquip:GetEquip(self.EquipId)
        self.TemplateId = equip and equip.TemplateId or 0
    end
    local quality = XMVCA.XEquip:GetEquipQuality(self.TemplateId)
    self.IsFiveStar = quality ~= nil and quality <= XEnumConst.EQUIP.MIN_RESONANCE_EQUIP_STAR_COUNT

    self:RefreshSlotGrids()
    self:RefreshSkillList()
    self.PanelWeaponResnance:SelectIndex(self.CurSlot)
end

--region 顶部 3 槽

function XUiEquipGridWeaponResonanceDetailPopup:InitSlotGrids()
    local slotTransforms = { self.UIWeaponResonanceSkill01, self.UIWeaponResonanceSkill02, self.UIWeaponResonanceSkill03 }
    for i = 1, SLOT_COUNT do
        local tf = slotTransforms[i]
        if tf then
            local slot = { Transform = tf, GameObject = tf.gameObject }
            XTool.InitUiObject(slot)
            self.SlotGrids[i] = slot
        end
    end

    self.PanelWeaponResnance:Init(slotTransforms, function(index)
        self:OnSlotClick(index)
    end)
end

function XUiEquipGridWeaponResonanceDetailPopup:OnSlotClick(slot)
    if self.CurSlot == slot then
        return
    end
    self.CurSlot = slot
    self:RefreshSlotGrids()
    self:RefreshSkillList()
end

function XUiEquipGridWeaponResonanceDetailPopup:RefreshSlotGrids()
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)
    local resonanceDic = (not self.IsFiveStar and equip) and XMVCA.XEquip:GetResonanceSkillDic(self.EquipId) or nil
    for i = 1, SLOT_COUNT do
        local slot = self.SlotGrids[i]
        local targetSkillId = self.TargetSkillIds[i]
        local hasTarget = XTool.IsNumberValid(targetSkillId)
        local hasResonance = equip and equip:GetResonanceInfo(i) ~= nil
        -- 五星：槽上有共鸣即达成
        local achieved
        if self.IsFiveStar then
            achieved = hasTarget and hasResonance
        else
            local curSkillId = (resonanceDic and resonanceDic[i]) or 0
            achieved = hasTarget and curSkillId == targetSkillId
        end

        if hasTarget then
            local skillInfo = self:CreateTargetSkillInfo(targetSkillId, i)
            slot.RImgResonance:SetRawImage(skillInfo and skillInfo.Icon)
            slot.RImgResonance.gameObject:SetActiveEx(true)
            slot.RImgEmpty.gameObject:SetActiveEx(false)
            slot.BgSkill.gameObject:SetActiveEx(true)
            slot.BgEmpty.gameObject:SetActiveEx(false)
        else
            slot.RImgResonance.gameObject:SetActiveEx(false)
            slot.RImgEmpty.gameObject:SetActiveEx(true)
            slot.BgEmpty.gameObject:SetActiveEx(true)
            slot.BgSkill.gameObject:SetActiveEx(false)
        end

        slot.BgNotAchieveDark.gameObject:SetActiveEx(not achieved)
        slot.BgEffectLight.gameObject:SetActiveEx(i == self.CurSlot)
    end
end

--endregion

--region 滑动列表

function XUiEquipGridWeaponResonanceDetailPopup:RefreshSkillList()
    self.TxtAwareness.text = CS.XTextManager.GetText("EquipResonanceSlotTitle", self.CurSlot)
    self.SkillDataList = self:BuildSkillDataList(self.CurSlot)
    XTool.UpdateDynamicItem(self.GridSkillList, self.SkillDataList, self.GridResonanceSkill, XUiGridWeaponResonanceDetailSkill, self)
end

--- 构建该槽位的技能列表数据：可选技能（目标技能排前）+ 末尾非当前角色共鸣卡片
function XUiEquipGridWeaponResonanceDetailPopup:BuildSkillDataList(slot)
    local equip = XMVCA.XEquip:GetEquip(self.EquipId)

    local previewList = XMVCA.XEquip:GetResonancePreviewSkillInfoListByTemplateId(self.TemplateId, self.CharacterId, slot)
    local resonanceDic = equip and XMVCA.XEquip:GetResonanceSkillDic(self.EquipId) or {}
    local curSkillId = resonanceDic[slot] or 0
    local curBindCharId = self:GetResonanceBindCharacterId(slot, equip)
    -- 五星武器不绑角色
    local hasBindChar = XTool.IsNumberValid(curBindCharId)
    local isCurCharResonance = not hasBindChar or curBindCharId == self.CharacterId
    local slotHasResonance = equip and equip:GetResonanceInfo(slot) ~= nil

    local targetSkillId = self.TargetSkillIds[slot]
    local hasTarget = XTool.IsNumberValid(targetSkillId)

    -- 拆分：目标技能 / 非目标技能（非目标按 id 升序）
    local targetInfo, others = nil, {}
    for _, skillInfo in ipairs(previewList) do
        if hasTarget and skillInfo.Id == targetSkillId then
            targetInfo = skillInfo
        else
            table.insert(others, skillInfo)
        end
    end
    table.sort(others, function(a, b) return a.Id < b.Id end)
    if hasTarget and not targetInfo then
        targetInfo = self:CreateTargetSkillInfo(targetSkillId, slot)
    end

    -- 组装
    local list = {}
    if targetInfo then
        table.insert(list, {
            SkillInfo = targetInfo,
            IsTarget = true,
            -- 五星：槽上有共鸣即算目标已达成
            IsResonanced = self.IsFiveStar and slotHasResonance
                or (not self.IsFiveStar and isCurCharResonance and curSkillId == targetInfo.Id),
            IsNotResonanceCharacter = false,
        })
    end
    for _, skillInfo in ipairs(others) do
        table.insert(list, {
            SkillInfo = skillInfo,
            IsTarget = false,
            IsResonanced = (not self.IsFiveStar) and isCurCharResonance and curSkillId == skillInfo.Id,
            IsNotResonanceCharacter = false,
        })
    end

    -- 末尾：非当前角色共鸣的技能（该槽共鸣了但绑定角色≠方案角色）
    if XTool.IsNumberValid(curSkillId) and hasBindChar and not isCurCharResonance then
        local notResonanceInfo = XMVCA.XEquip:GetResonanceSkillInfo(self.EquipId, slot)
        if notResonanceInfo then
            table.insert(list, {
                SkillInfo = notResonanceInfo,
                IsTarget = false,
                IsResonanced = false,
                IsNotResonanceCharacter = true,
                CharacterId = curBindCharId,
            })
        end
    end

    return list
end

--- 用目标自带类型建技能信息；缺失时按 武器技能 → 属性 → 角色技能尝试
function XUiEquipGridWeaponResonanceDetailPopup:CreateTargetSkillInfo(skillId, slot)
    if not XTool.IsNumberValid(skillId) then
        return nil
    end
    local preferType = self.TargetResonanceTypes and self.TargetResonanceTypes[slot]
    if XTool.IsNumberValid(preferType) then
        local info = XMVCA.XEquip:CreateResonanceSkillInfo(preferType, skillId)
        if info then
            return info
        end
    end
    local typeEnum = XEnumConst.EQUIP.RESONANCE_TYPE
    local order = { typeEnum.WEAPON_SKILL, typeEnum.ATTRIB, typeEnum.CHARACTER_SKILL }
    for i = 1, #order do
        if order[i] ~= preferType then
            local info = XMVCA.XEquip:CreateResonanceSkillInfo(order[i], skillId)
            if info then
                return info
            end
        end
    end
    return nil
end

--- 该槽位共鸣绑定的角色 id（未共鸣返回 0）
function XUiEquipGridWeaponResonanceDetailPopup:GetResonanceBindCharacterId(slot, equip)
    equip = equip or XMVCA.XEquip:GetEquip(self.EquipId)
    if not equip or not equip.ResonanceInfo then
        return 0
    end
    for _, v in pairs(equip.ResonanceInfo) do
        if v.Slot == slot then
            return v.CharacterId or 0
        end
    end
    return 0
end

--endregion

return XUiEquipGridWeaponResonanceDetailPopup
