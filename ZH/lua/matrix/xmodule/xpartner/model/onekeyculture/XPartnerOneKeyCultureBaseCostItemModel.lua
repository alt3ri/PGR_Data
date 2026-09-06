---@class XPartnerOneKeyCultureBaseCostItemModel : XModelBase
---@field private _LevelUpMOList XPartnerOneKeyCultureBaseCostItemMO[]
---@field private _StarUpMOList XPartnerOneKeyCultureBaseCostItemMO[]
---@field private _SkillMOList XPartnerOneKeyCultureBaseCostItemMO[]
---@field private _MOPool XPartnerOneKeyCultureBaseCostItemMO[]
---@field private _LevelUpAllList table<{Id: number, Count: number}> 升级+突破材料汇总
---@field private _StarUpAllList table<{Id: number, Count: number}> 升阶材料汇总
---@field private _SkillAllList table<{Id: number, Count: number}> 技能材料汇总
local XPartnerOneKeyCultureBaseCostItemModel = XClass(XModelBase, "XPartnerOneKeyCultureBaseCostItemModel")

local XPartnerOneKeyCultureBaseCostItemMO = require("XModule/XPartner/Model/OneKeyCulture/XPartnerOneKeyCultureBaseCostItemMO")

function XPartnerOneKeyCultureBaseCostItemModel:OnInit()
    self._LevelUpMOList = {}
    self._StarUpMOList = {}
    self._SkillMOList = {}
    self._MOPool = {}
    self._LevelUpAllList = {}
    self._StarUpAllList = {}
    self._SkillAllList = {}
end

function XPartnerOneKeyCultureBaseCostItemModel:ClearPrivate()
    self:ClearAll()
end

function XPartnerOneKeyCultureBaseCostItemModel:ResetAll()
    self:ClearAll()
end

---region ----------public start----------

--- 获取升级原子列表
---@return XPartnerOneKeyCultureBaseCostItemMO[]
function XPartnerOneKeyCultureBaseCostItemModel:GetLevelUpMOList()
    return self._LevelUpMOList
end

--- 获取升阶原子列表
---@return XPartnerOneKeyCultureBaseCostItemMO[]
function XPartnerOneKeyCultureBaseCostItemModel:GetStarUpMOList()
    return self._StarUpMOList
end

--- 获取技能原子列表
---@return XPartnerOneKeyCultureBaseCostItemMO[]
function XPartnerOneKeyCultureBaseCostItemModel:GetSkillMOList()
    return self._SkillMOList
end

--- 获取升级材料总汇（合并所有原子，按 Id 累加）
---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureBaseCostItemModel:GetLevelUpAllCostList()
    return self._LevelUpAllList
end

--- 获取升阶材料总汇
---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureBaseCostItemModel:GetStarUpAllCostList()
    return self._StarUpAllList
end

--- 获取技能材料总汇
---@return table<{Id: number, Count: number}>
function XPartnerOneKeyCultureBaseCostItemModel:GetSkillAllCostList()
    return self._SkillAllList
end

--- 清空全部原子（MO 回收到池），清空汇总列表
function XPartnerOneKeyCultureBaseCostItemModel:ClearAll()
    self:_RecycleMOList(self._LevelUpMOList)
    self:_RecycleMOList(self._StarUpMOList)
    self:_RecycleMOList(self._SkillMOList)
    table.clear(self._LevelUpAllList)
    table.clear(self._StarUpAllList)
    table.clear(self._SkillAllList)
end

--- 从池中获取（或创建）一个 MO，加入对应列表并返回
---@param cultureType XPartnerEnum.CultureType
---@return XPartnerOneKeyCultureBaseCostItemMO
function XPartnerOneKeyCultureBaseCostItemModel:CreateMO(cultureType)
    local mo = table.remove(self._MOPool)
    if not mo then
        mo = XPartnerOneKeyCultureBaseCostItemMO.New()
    end
    mo:Reset(cultureType)
    table.insert(self:_GetMOList(cultureType), mo)
    return mo
end

--- 构建全部 All 汇总列表（在填充完 MO 后调用）
function XPartnerOneKeyCultureBaseCostItemModel:BuildAllCostLists()
    self:_BuildAllList(self._LevelUpMOList, self._LevelUpAllList)
    self:_BuildAllList(self._StarUpMOList, self._StarUpAllList)
    self:_BuildAllList(self._SkillMOList, self._SkillAllList)
end

---endregion ----------public end----------

---region ----------private start----------

--- 根据 CultureType 获取对应的 MOList
---@param cultureType XPartnerEnum.CultureType
---@return XPartnerOneKeyCultureBaseCostItemMO[]
function XPartnerOneKeyCultureBaseCostItemModel:_GetMOList(cultureType)
    local XPartnerEnum = XMVCA.XPartner.Enum
    if cultureType == XPartnerEnum.CultureType.LevelUp or  cultureType == XPartnerEnum.CultureType.BreakUp then
        return self._LevelUpMOList
    elseif cultureType == XPartnerEnum.CultureType.StarUp then
        return self._StarUpMOList
    end
    return self._SkillMOList
end

--- 回收 MOList 中的 MO 到池
---@param list XPartnerOneKeyCultureBaseCostItemMO[]
function XPartnerOneKeyCultureBaseCostItemModel:_RecycleMOList(list)
    for _, mo in ipairs(list) do
        table.insert(self._MOPool, mo)
    end
    table.clear(list)
end
 
--- 将 MO 列表合并为 {Id, Count} 汇总列表（按 Id 累加）
---@param moList XPartnerOneKeyCultureBaseCostItemMO[]
---@param outList table<{Id: number, Count: number}>
function XPartnerOneKeyCultureBaseCostItemModel:_BuildAllList(moList, outList)
    table.clear(outList)
    local mergedDic = {}
    for _, mo in ipairs(moList) do
        for _, item in ipairs(mo:GetNeedList()) do
            mergedDic[item.Id] = (mergedDic[item.Id] or 0) + item.Count
        end
    end
    for id, count in pairs(mergedDic) do
        if count > 0 then
            table.insert(outList, { Id = id, Count = count })
        end
    end
end

---endregion ----------private end----------

return XPartnerOneKeyCultureBaseCostItemModel
