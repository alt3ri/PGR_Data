---@class XDlcRelinkCharacter
local XDlcRelinkCharacter = XClass(nil, "XDlcRelinkCharacter")

function XDlcRelinkCharacter:Ctor()
    self.CharacterId = 0
    self.OccupationType = 0 -- 职业
    ---@type table<number, number> -- 装备栏位 -> EquipUid
    self.Equip = {} -- 已安装的装备
end

function XDlcRelinkCharacter:NotifyCharacterData(data)
    self.CharacterId = data.CharacterId or 0
    self.OccupationType = data.OccupationType or 0
    self.Equip = data.Equip or {}
end

function XDlcRelinkCharacter:GetCharacterId()
    return self.CharacterId
end

function XDlcRelinkCharacter:GetOccupationType()
    return self.OccupationType
end

function XDlcRelinkCharacter:GetEquip()
    return self.Equip
end

function XDlcRelinkCharacter:GetEquipBySlot(slotId)
    return self.Equip[slotId] or 0
end

-- 检查装备是否已穿戴
function XDlcRelinkCharacter:IsEquipWorn(equipUid)
    for _, v in pairs(self.Equip) do
        if v == equipUid then
            return true
        end
    end
    return false
end

return XDlcRelinkCharacter
