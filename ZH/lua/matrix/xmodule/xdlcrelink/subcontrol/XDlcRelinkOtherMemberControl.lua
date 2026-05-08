---@class XDlcRelinkOtherMemberControl : XControl
---@field private _Model XDlcRelinkModel
---@field _MainControl XDlcRelinkControl
local XDlcRelinkOtherMemberControl = XClass(XControl, "XDlcRelinkOtherMemberControl")
function XDlcRelinkOtherMemberControl:OnInit()
    self._memberData = nil
end

function XDlcRelinkOtherMemberControl:OnRelease()
    self._memberData = nil
end

--region 数据管理

--- 设置其他成员数据
---@param memberData XDlcMember
function XDlcRelinkOtherMemberControl:SetMemberData(memberData)
    self._memberData = memberData
end

--- 清除其他成员数据
function XDlcRelinkOtherMemberControl:ClearMemberData()
    self._memberData = nil
end

--- 检查是否有有效的成员数据
---@return boolean
function XDlcRelinkOtherMemberControl:HasValidMemberData()
    return self._memberData ~= nil
end

--- 获取成员数据
---@return XDlcMember|nil
function XDlcRelinkOtherMemberControl:GetMemberData()
    return self._memberData
end

--endregion

--region 基础信息获取

--- 获取其他成员研发等级
---@return number
function XDlcRelinkOtherMemberControl:GetPlayerLevel()
    if not self:HasValidMemberData() then
        return 0
    end
    return self._memberData:GetRelinkPlayerLevel()
end

--- 获取其他成员风格类型
---@return number
function XDlcRelinkOtherMemberControl:GetStyleType()
    if not self:HasValidMemberData() then
        return 0
    end
    return self._memberData:GetStyleType()
end

--endregion

--region 装备相关

--- 获取其他成员装备Uid列表
---@return table<number, number>
function XDlcRelinkOtherMemberControl:GetWearEquipUids()
    if not self:HasValidMemberData() then
        return {}
    end

    local equips = self._memberData:GetRelinkEquips()
    local equipUids = {}
    for index, equip in pairs(equips) do
        local uid = equip and equip.Uid
        if XTool.IsNumberValid(uid) then
            equipUids[index] = uid
        end
    end
    return equipUids
end

--- 获取其他成员装备的槽位索引
---@param equipUid number
---@return number
function XDlcRelinkOtherMemberControl:GetEquipWearSlotIndexByEquipUid(equipUid)
    if not XTool.IsNumberValid(equipUid) or not self:HasValidMemberData() then
        return 0
    end

    local equips = self._memberData:GetRelinkEquips()
    for index, equip in pairs(equips) do
        if equip and equip.Uid == equipUid then
            return index
        end
    end
    return 0
end

--- 通过装备Uid获取装备数据
---@param equipUid number
---@return table|nil
function XDlcRelinkOtherMemberControl:GetEquipByEquipUid(equipUid)
    if not XTool.IsNumberValid(equipUid) or not self:HasValidMemberData() then
        return nil
    end
    return self._memberData:GetRelinkEquipByEquipUid(equipUid)
end

--- 通过槽位索引获取装备数据
---@param slotIndex number
---@return table|nil
function XDlcRelinkOtherMemberControl:GetEquipBySlot(slotIndex)
    if not XTool.IsNumberValid(slotIndex) or not self:HasValidMemberData() then
        return nil
    end
    return self._memberData:GetRelinkEquipBySlot(slotIndex)
end

function XDlcRelinkOtherMemberControl:GetEquipWearEquipUidBySlot(slotIndex)
    local equip = self:GetEquipBySlot(slotIndex)
    return equip and equip.Uid or 0
end

--- 获取其他成员装备模板Id
---@param equipUid number
---@return number
function XDlcRelinkOtherMemberControl:GetEquipTemplateIdByEquipUid(equipUid)
    local equip = self:GetEquipByEquipUid(equipUid)
    return equip and equip.TemplateId or 0
end

--- 获取其他成员装备战力
---@param equipUid number
---@return number
function XDlcRelinkOtherMemberControl:GetEquipAbilityByEquipUid(equipUid)
    local equip = self:GetEquipByEquipUid(equipUid)
    return equip and equip.EquipAbility or 0
end

--- 获取其他成员装备是否锁定
---@param equipUid number
---@return boolean
function XDlcRelinkOtherMemberControl:GetEquipIsLockedByEquipUid(equipUid)
    local equip = self:GetEquipByEquipUid(equipUid)
    return equip and equip.IsLocked or false
end

--- 获取其他成员装备是否被弃置
---@param equipUid number
---@return boolean
function XDlcRelinkOtherMemberControl:GetEquipIsDiscardedByEquipUid(equipUid)
    local equip = self:GetEquipByEquipUid(equipUid)
    return equip and equip.IsDiscarded or false
end

--- 获取其他成员装备所有主属性
---@param equipUid number
---@return table
function XDlcRelinkOtherMemberControl:GetEquipAllMainFactorByEquipUid(equipUid)
    local equip = self:GetEquipByEquipUid(equipUid)
    return equip and equip.MainFactors or {}
end

--- 获取其他成员装备所有副属性
---@param equipUid number
---@return table
function XDlcRelinkOtherMemberControl:GetEquipAllDeputyFactorByEquipUid(equipUid)
    local equip = self:GetEquipByEquipUid(equipUid)
    return equip and equip.AttributeSlots or {}
end

--- 获取其他成员装备指定栏位副属性
---@param equipUid number
---@param slotIndex number
---@return table|nil
function XDlcRelinkOtherMemberControl:GetEquipDeputyFactorByEquipUid(equipUid, slotIndex)
    if not XTool.IsNumberValid(slotIndex) then
        return nil
    end

    local equip = self:GetEquipByEquipUid(equipUid)
    if not equip then
        return nil
    end

    return equip.AttributeSlots and equip.AttributeSlots[slotIndex] or nil
end

--- 获取其他成员装备主属性
---@param equipUid number
---@param isSkillFactor boolean
---@return table|nil
function XDlcRelinkOtherMemberControl:GetEquipMainFactorByEquipUid(equipUid, isSkillFactor)
    local equip = self:GetEquipByEquipUid(equipUid)
    if not equip then
        return nil
    end

    local mainSkillFactorId = self._MainControl:GetEquipMainSkillFactorId(equip.TemplateId)
    for _, attribute in pairs(equip.MainFactors or {}) do
        if isSkillFactor == (attribute.FactorId == mainSkillFactorId) then
            return attribute
        end
    end
    return nil
end

--- 获取其他成员装备最大战力
---@param equipUid number
---@return number
function XDlcRelinkOtherMemberControl:GetEquipMaxAbilityByEquipUid(equipUid)
    local equip = self:GetEquipByEquipUid(equipUid)
    if not equip then
        return 0
    end

    local templateId = equip.TemplateId
    local ability = self._MainControl:GetEquipAbility(templateId)

    -- 主属性战力
    for _, attribute in pairs(equip.MainFactors or {}) do
        ability = ability + self._MainControl:GetAttributeAbilityInternal(attribute)
    end

    -- 副属性战力
    for _, slotsValue in pairs(equip.AttributeSlots or {}) do
        for _, attribute in pairs(slotsValue.Attributes) do
            ability = ability + self._MainControl:GetAttributeAbilityInternal(attribute)
        end
    end

    return ability
end

--- 检测其他成员装备栏位职业类型是否相同
---@param mainSlotIndex number
---@param extendSlotIndex number
---@return boolean
function XDlcRelinkOtherMemberControl:CheckEquipSlotOccupationTypeSame(mainSlotIndex, extendSlotIndex)
    if not XTool.IsNumberValid(mainSlotIndex) or not XTool.IsNumberValid(extendSlotIndex) then
        return false
    end

    local mainEquip = self:GetEquipBySlot(mainSlotIndex)
    local extendEquip = self:GetEquipBySlot(extendSlotIndex)
    if not mainEquip or not extendEquip then
        return false
    end

    local mainOccupationType = self._MainControl:GetEquipOccupationType(mainEquip.TemplateId)
    local extendOccupationType = self._MainControl:GetEquipOccupationType(extendEquip.TemplateId)
    return mainOccupationType == extendOccupationType
end

--- 通过角色Id和风格类型获取其他成员角色技能Id列表
---@param characterId number 角色Id
---@param styleType number 风格类型
---@return table<number> 技能Id列表
function XDlcRelinkOtherMemberControl:GetCharacterSkillIdsByCharacterId(characterId, styleType)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(styleType) then
        return {}
    end

    local skillIds = self._MainControl:GetCharacterSkillIds(characterId, styleType)
    if XTool.IsTableEmpty(skillIds) then
        return {}
    end

    local mainEquipUid = self:GetEquipWearEquipUidBySlot(XEnumConst.DlcRelink.EquipSlotIndex.MainSlot)
    if not XTool.IsNumberValid(mainEquipUid) then
        return skillIds
    end

    local attribute = self:GetEquipMainFactorByEquipUid(mainEquipUid, true)
    if not attribute or not XTool.IsNumberValid(attribute.FactorId) or not XTool.IsNumberValid(attribute.Level) then
        return skillIds
    end

    local affectedSkillIds = self._MainControl:GetFactorAffectedSkillIds(attribute.FactorId, attribute.Level)
    local newSkillIds = self._MainControl:GetFactorNewSkillIds(attribute.FactorId, attribute.Level)
    if XTool.IsTableEmpty(affectedSkillIds) or XTool.IsTableEmpty(newSkillIds) then
        return skillIds
    end

    local skillReplaceMap = {}
    for i, affectedSkillId in ipairs(affectedSkillIds) do
        local newSkillId = newSkillIds[i]
        if XTool.IsNumberValid(affectedSkillId) and XTool.IsNumberValid(newSkillId) then
            skillReplaceMap[affectedSkillId] = newSkillId
        end
    end

    for index, skillId in ipairs(skillIds) do
        local newSkillId = skillReplaceMap[skillId]
        if XTool.IsNumberValid(newSkillId) then
            skillIds[index] = newSkillId
        end
    end
    return skillIds
end

--- 检查装备的副属性槽位是否已满
function XDlcRelinkOtherMemberControl:CheckEquipDeputyFactorSlotsIsFull(equipUid)
    local equip = self:GetEquipByEquipUid(equipUid)
    if not equip then
        return false
    end

    local quality = self._MainControl:GetEquipQuality(equip.TemplateId)
    local maxSlotsNum = self._MainControl:GetEquipQualityDeputyFactorNum(quality)
    local curSlotsNum = equip.AttributeSlots and table.nums(equip.AttributeSlots) or 0
    return curSlotsNum >= maxSlotsNum
end

--endregion

return XDlcRelinkOtherMemberControl
