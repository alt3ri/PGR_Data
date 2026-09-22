---@class XPartnerSkillSelectViewControl : XControl
---@field private _Model XPartnerModel
---@field private _MainControl XPartnerControl
local XPartnerSkillSelectViewControl = XClass(XControl, "XPartnerSkillSelectViewControl")

function XPartnerSkillSelectViewControl:OnInit()
    self._PartnerId = nil
    self._IsRequesting = false
end

function XPartnerSkillSelectViewControl:AddAgencyEvent()
    local eventId = XMVCA.XPartner.EventIds
    self._MainControl:AddEventListener(eventId.EVENT_REPLY_PARTNER_SKILL_WEAR, self._OnSkillWearReply, self)
end

function XPartnerSkillSelectViewControl:RemoveAgencyEvent()
    local eventId = XMVCA.XPartner.EventIds
    self._MainControl:RemoveEventListener(eventId.EVENT_REPLY_PARTNER_SKILL_WEAR, self._OnSkillWearReply, self)
end

function XPartnerSkillSelectViewControl:OnRelease()
    self._PartnerId = nil
    self._IsRequesting = false
end

---region event

---@param isSuccess boolean
function XPartnerSkillSelectViewControl:_OnSkillWearReply(isSuccess)
    self._IsRequesting = false
end

---endregion

--- 设置当前技能选择界面的辅助机
---@param partnerId number
---@return boolean
function XPartnerSkillSelectViewControl:SetPartnerId(partnerId)
    local partner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
    if not partner then
        return false
    end

    self._PartnerId = partnerId
    return true
end

---@return number|nil
function XPartnerSkillSelectViewControl:GetPartnerId()
    return self._PartnerId
end

---@return XPartner|nil
function XPartnerSkillSelectViewControl:GetPartnerEntity()
    if not self._PartnerId then
        return nil
    end

    return XDataCenter.PartnerManager.GetPartnerEntityById(self._PartnerId)
end

---@return boolean
function XPartnerSkillSelectViewControl:IsRequesting()
    return self._IsRequesting
end

---@return XPartnerMainSkillGroup[]
function XPartnerSkillSelectViewControl:GetMainSkillGroupList()
    local partner = self:GetPartnerEntity()
    return partner and partner:GetMainSkillGroupList() or table.empty
end

---@return XPartnerMainSkillGroup|nil
function XPartnerSkillSelectViewControl:GetCarryMainSkillGroup()
    local partner = self:GetPartnerEntity()
    local carryList = partner and partner:GetCarryMainSkillGroupList()
    return carryList and carryList[1]
end

---@return XPartnerPassiveSkillGroup[]
function XPartnerSkillSelectViewControl:GetPassiveSkillGroupList()
    local partner = self:GetPartnerEntity()
    return partner and partner:GetPassiveSkillGroupList() or table.empty
end

---@return XPartnerPassiveSkillGroup[]
function XPartnerSkillSelectViewControl:GetCarryPassiveSkillGroupList()
    local partner = self:GetPartnerEntity()
    return partner and partner:GetCarryPassiveSkillGroupList() or table.empty
end

---@return number
function XPartnerSkillSelectViewControl:GetPassiveSkillLimit()
    local partner = self:GetPartnerEntity()
    return partner and partner:GetQualitySkillColumnCount() or 0
end

---@return number
function XPartnerSkillSelectViewControl:GetCarryPassiveSkillCount()
    return #self:GetCarryPassiveSkillGroupList()
end

---@param skillGroupId number
---@return boolean
function XPartnerSkillSelectViewControl:IsPassiveSkillCarry(skillGroupId)
    for _, skillGroup in ipairs(self:GetCarryPassiveSkillGroupList()) do
        if skillGroup:GetId() == skillGroupId then
            return true
        end
    end

    return false
end

--- 选择主动技能并立即提交穿戴协议
---@param skillGroup XPartnerMainSkillGroup
---@return boolean
function XPartnerSkillSelectViewControl:SelectMainSkill(skillGroup)
    local partner = self:GetPartnerEntity()
    if not partner or not skillGroup or self._IsRequesting then
        return false
    end

    if partner:GetIsComposePreview() then
        return false
    end

    if skillGroup:GetIsLock() then
        XUiManager.TipMsg(skillGroup:GetConditionDesc())
        return false
    end

    local carrySkillGroup = self:GetCarryMainSkillGroup()
    if carrySkillGroup and carrySkillGroup:GetId() == skillGroup:GetId() then
        return false
    end

    local skillType = self._MainControl:GetConfigControl():GetSkillType()
    self:_SendSkillWearRequest({ [skillGroup:GetActiveSkillId()] = true }, skillType.MainSkill)
    return true
end

--- 设置被动技能穿戴状态并立即提交协议
---@param skillGroup XPartnerPassiveSkillGroup
---@param isWear boolean
---@return boolean
function XPartnerSkillSelectViewControl:SetPassiveSkillWear(skillGroup, isWear)
    local partner = self:GetPartnerEntity()
    if not partner or not skillGroup or self._IsRequesting then
        return false
    end

    if partner:GetIsComposePreview() then
        return false
    end

    local isCarry = self:IsPassiveSkillCarry(skillGroup:GetId())
    if isCarry == isWear then
        return false
    end

    if isWear and self:GetCarryPassiveSkillCount() >= self:GetPassiveSkillLimit() then
        XUiManager.TipText("PartnerSelectSkillFull")
        return false
    end

    local skillType = self._MainControl:GetConfigControl():GetSkillType()
    self:_SendSkillWearRequest({ [skillGroup:GetActiveSkillId()] = isWear }, skillType.PassiveSkill)
    return true
end

---@param skillDic table<number, boolean>
---@param skillType number
function XPartnerSkillSelectViewControl:_SendSkillWearRequest(skillDic, skillType)
    self._IsRequesting = true
    self._MainControl:GetNetWorkControl():SendSkillWearRequest(self._PartnerId, skillDic, skillType)
end

return XPartnerSkillSelectViewControl
