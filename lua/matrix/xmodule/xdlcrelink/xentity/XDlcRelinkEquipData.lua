---@class XDlcRelinkEquipData
local XDlcRelinkEquipData = XClass(nil, "XDlcRelinkEquipData")

function XDlcRelinkEquipData:Ctor()
    self.Uid = 0 -- 装备唯一Id
    self.IsLocked = false -- 是否被锁定保护
    self.TemplateId = 0 -- 配置表Id
    self.FactorRemoveNum = 0 -- 当前词条已删除次数
    self.EquipAbility = 0 -- 装备等级
    ---@type XDlcRelinkEquipAttribute[]
    self.MainFactors = {} -- 主词条
    ---@type table<number, XDlcRelinkEquipAttributeSlot> -- 副词缀组 key SlotId
    self.AttributeSlots = {} -- 副词缀组
end

function XDlcRelinkEquipData:NotifyEquipData(data)
    self.Uid = data.Uid or 0
    self.IsLocked = data.IsLocked or false
    self.TemplateId = data.TemplateId or 0
    self.FactorRemoveNum = data.FactorRemoveNum or 0
    self.MainFactors = data.MainFactors or {}
    self.AttributeSlots = data.AttributeSlots or {}
end

function XDlcRelinkEquipData:GetUid()
    return self.Uid
end

function XDlcRelinkEquipData:GetIsLocked()
    return self.IsLocked
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

return XDlcRelinkEquipData

---@class XDlcRelinkEquipAttribute
---@field FactorId number 词条Id
---@field Level number 词条等级
---@field EquipTemplate number 首次生成时的装备Id

---@class XDlcRelinkEquipAttributeSlot
---@field Attributes XDlcRelinkEquipAttribute[] 词条列表
