--- 辅助机一键培养专属子 Agency，对外提供养成状态查询等接口
---@class XPartnerOneKeyCultureAgency : XAgency
---@field private _Model XPartnerModel
---@field private _MainAgency XPartnerAgency
local XPartnerOneKeyCultureAgency = XClass(XAgency, "XPartnerOneKeyCultureAgency")


--region ----------public start----------

--- 辅助机养成是否已全部养满
--- 传入 cultureType 时只判断该养成类型；不传则判断升级/升星/技能全部养满
---@param partnerId number 辅助机实例 Id
---@param cultureType XPartnerEnum.CultureType|nil 养成类型，可空
---@return boolean
function XPartnerOneKeyCultureAgency:IsPartnerAllCultureMax(partnerId)
    local XPartnerEnum = XMVCA.XPartner.Enum
    return self:IsCultureTypeMax(partnerId, XPartnerEnum.CultureType.LevelUp)
        and self:IsCultureTypeMax(partnerId, XPartnerEnum.CultureType.StarUp)
        and self:IsCultureTypeMax(partnerId, XPartnerEnum.CultureType.SkillLevelUp)
end


---@param partnerId number 辅助机实例 Id
---@param cultureType XPartnerEnum.CultureType
---@return boolean
function XPartnerOneKeyCultureAgency:IsCultureTypeMax(partnerId, cultureType)
    if not XTool.IsNumberValid(partnerId) then
        return false
    end
    local partner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
    if not partner then
        return false
    end

    local XPartnerEnum = XMVCA.XPartner.Enum
    if cultureType == XPartnerEnum.CultureType.LevelUp then
        return partner:GetIsMaxBreakthrough() and partner:GetIsLevelMax()
    elseif cultureType == XPartnerEnum.CultureType.StarUp then
        return partner:GetIsMaxQuality()
    elseif cultureType == XPartnerEnum.CultureType.SkillLevelUp then
        return self:_IsSkillCultureMax(partner)
    end
    return false
end



-- 技能是否已养满：槽位必须选满（主动技 1 + 被动技满槽），且所有已装配技能均满级
---@param partner XPartner
---@return boolean
function XPartnerOneKeyCultureAgency:_IsSkillCultureMax(partner)
    local carryMainList = partner:GetCarryMainSkillGroupList()
    if not carryMainList or #carryMainList < 1 then
        return false
    end

    local carryPassiveList = partner:GetCarryPassiveSkillGroupList()
    local maxPassiveCount = partner:GetQualitySkillColumnCount()
    if not carryPassiveList or #carryPassiveList < maxPassiveCount then
        return false
    end

    for _, entity in ipairs(carryMainList) do
        if entity:GetLevel() < entity:GetLevelLimit() then
            return false
        end
    end
    for _, entity in ipairs(carryPassiveList) do
        if entity:GetLevel() < entity:GetLevelLimit() then
            return false
        end
    end
    return true
end


return XPartnerOneKeyCultureAgency
