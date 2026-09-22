---@class XPartnerOneKeyCultureBaseCostItemMO
--- 一个消费原子：记录养成类型、材料需求列表（含螺母）、以及该原子可达成的目标
---@field private _CultureType XPartnerEnum.CultureType 养成类型
---@field private _NeedList table<{Id: number, Count: number}> 材料需求列表（含螺母）
---@field private _TargetData table 目标数据（各类型不同）
local XPartnerOneKeyCultureBaseCostItemMO = XClass(nil, "XPartnerOneKeyCultureBaseCostItemMO")

function XPartnerOneKeyCultureBaseCostItemMO:Ctor()
    self._CultureType = nil
    self._NeedList = {}
    self._TargetData = nil
end

--- 复用时重置数据
---@param cultureType XPartnerEnum.CultureType
function XPartnerOneKeyCultureBaseCostItemMO:Reset(cultureType)
    self._CultureType = cultureType
    table.clear(self._NeedList)
    self._TargetData = nil
end

---@return XPartnerEnum.CultureType
function XPartnerOneKeyCultureBaseCostItemMO:GetCultureType()
    return self._CultureType
end

---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureBaseCostItemMO:GetNeedList()
    return self._NeedList
end

--- 追加材料需求（含螺母，统一进 NeedList）
---@param id number
---@param count number
function XPartnerOneKeyCultureBaseCostItemMO:AppendItem(id, count)
    table.insert(self._NeedList, { Id = id, Count = count })
end

--region 目标数据 - 描述该原子消费后能达成什么

--- 升级原子：从 fromLevel 升到 toLevel
---@param fromLevel number 起始等级
---@param toLevel number 目标等级（该阶段等级上限）
function XPartnerOneKeyCultureBaseCostItemMO:SetTargetLevelupData(fromLevel, toLevel)
    self._TargetData = {
        fromLevel = fromLevel,
        toLevel = toLevel,
    }
end

--- 突破原子：突破到指定阶段
---@param targetBreakthrough number 目标突破阶段
function XPartnerOneKeyCultureBaseCostItemMO:SetTargetBreakUpData(targetBreakthrough)
    self._TargetData = {
        targetBreakthrough = targetBreakthrough,
    }
end

--- 技能升级原子：将指定技能升到指定等级
---@param skillId number 技能组 Id
---@param targetLevel number 目标等级
function XPartnerOneKeyCultureBaseCostItemMO:SetTargetSkillUpData(skillId, targetLevel)
    self._TargetData = {
        skillId = skillId,
        targetLevel = targetLevel,
    }
end

--- 升星原子：进化到指定品质
---@param targetQuality number 目标品质
function XPartnerOneKeyCultureBaseCostItemMO:SetTargetStarUpData(targetQuality)
    self._TargetData = {
        targetQuality = targetQuality,
    }
end


---@return number fromLevel, number toLevel
function XPartnerOneKeyCultureBaseCostItemMO:GetTargetLevelupData()
    return self._TargetData.fromLevel or 0, self._TargetData.toLevel or 0
end

---@return number targetBreakthrough
function XPartnerOneKeyCultureBaseCostItemMO:GetTargetBreakUpData()
    return self._TargetData.targetBreakthrough or 0
end

---@return number skillId, number targetLevel
function XPartnerOneKeyCultureBaseCostItemMO:GetTargetSkillUpData()
    return self._TargetData.skillId or 0, self._TargetData.targetLevel or 0
end

---@return number targetQuality
function XPartnerOneKeyCultureBaseCostItemMO:GetTargetStarUpData()
    return self._TargetData.targetQuality or 0
end

--endregion

return XPartnerOneKeyCultureBaseCostItemMO
