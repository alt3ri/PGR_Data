---@class XDlcRelinkEquipData
local XDlcRelinkEquipData = XClass(nil, "XDlcRelinkEquipData")

function XDlcRelinkEquipData:Ctor()
    self.Uid = 0 -- 装备唯一Id
    self.IsLocked = false -- 是否被锁定保护
    self.IsDiscarded = false -- 是否标记为自动弃置
    self.TemplateId = 0 -- 配置表Id
    self.FactorRemoveNum = 0 -- 当前词条已删除次数
    self.EquipAbility = 0 -- 装备战力
    ---@type XDlcRelinkEquipAttribute[]
    self.MainFactors = {} -- 主词条
    ---@type table<number, XDlcRelinkEquipAttributeSlot> -- 副词缀组 key SlotId
    self.AttributeSlots = {} -- 副词缀组
end

function XDlcRelinkEquipData:NotifyEquipData(data)
    self.Uid = data.Uid or 0
    self.IsLocked = data.IsLocked or false
    self.IsDiscarded = data.IsDiscarded or false
    self.TemplateId = data.TemplateId or 0
    self.FactorRemoveNum = data.FactorRemoveNum or 0
    self.EquipAbility = data.EquipAbility or 0
    self.MainFactors = data.MainFactors or {}
    self.AttributeSlots = data.AttributeSlots or {}
end

function XDlcRelinkEquipData:SetIsLocked(isLocked)
    self.IsLocked = isLocked
end

function XDlcRelinkEquipData:SetIsDiscarded(isDiscarded)
    self.IsDiscarded = isDiscarded
end

function XDlcRelinkEquipData:GetUid()
    return self.Uid
end

function XDlcRelinkEquipData:GetIsLocked()
    return self.IsLocked
end

function XDlcRelinkEquipData:GetIsDiscarded()
    return self.IsDiscarded
end

function XDlcRelinkEquipData:GetTemplateId()
    return self.TemplateId
end

function XDlcRelinkEquipData:GetFactorRemoveNum()
    return self.FactorRemoveNum
end

function XDlcRelinkEquipData:GetEquipAbility()
    return self.EquipAbility
end

function XDlcRelinkEquipData:GetMainFactors()
    return self.MainFactors
end

function XDlcRelinkEquipData:GetAttributeSlots()
    return self.AttributeSlots
end

function XDlcRelinkEquipData:GetAttributeSlotByIndex(slotIndex)
    return self.AttributeSlots[slotIndex]
end

-- 获取副词条槽位数量
function XDlcRelinkEquipData:GetAttributeSlotCount()
    return table.nums(self.AttributeSlots)
end

-- 获取副词条总数量
function XDlcRelinkEquipData:GetAttributeTotalCount()
    local count = 0
    for _, slot in pairs(self.AttributeSlots) do
        if slot and slot.Attributes then
            count = count + #slot.Attributes
        end
    end
    return count
end

-- 装备是否已改造过 (副词缀组大于0)
---@return number 1 已改造 2 未改造
function XDlcRelinkEquipData:IsEquipReformed()
    if self:GetAttributeSlotCount() > 0 then
        return 1
    end
    return 2
end

-- 装备是否已删除过词条 (已删除次数大于0)
---@return number 1 已删除过词条，2 未删除过词条
function XDlcRelinkEquipData:IsEquipFactorRemoved()
    if self.FactorRemoveNum > 0 then
        return 1
    end
    return 2
end

-- 装备是否已弃置 (标记为自动弃置)
---@return number 1 已弃置，2 未弃置
function XDlcRelinkEquipData:IsEquipDiscarded()
    if self.IsDiscarded then
        return 1
    end
    return 2
end

return XDlcRelinkEquipData

---@class XDlcRelinkEquipAttribute
---@field FactorId number 词条Id
---@field Level number 词条等级
---@field EquipTemplate number 首次生成时的装备Id
---@field IsActive boolean 词条是否生效（比如条件词条在不满足生效条件时，则该词条不会生效），会在穿脱装备时计算赋值 未穿戴装备的词条一律认为不生效
---@field SecondFactors XDlcRelinkEquipAttribute[] 该词条如果为复合词条时，其拥有的子词条

---@class XDlcRelinkEquipAttributeSlot
---@field Attributes XDlcRelinkEquipAttribute[] 词条列表
