---@class XDlcRelinkCharacter
local XDlcRelinkCharacter = XClass(nil, "XDlcRelinkCharacter")

function XDlcRelinkCharacter:Ctor()
    self.CharacterId = 0
    -- 风格
    self.StyleType = 0
    -- 角色风格的通关信息
    ---@type table<number, XDlcRelinkCharacterPassInfo> -- StyleType -> XDlcRelinkCharacterPassInfo
    self.CharacterStyleTypePassInfoDict = {}
    -- 已安装的装备
    ---@type table<number, number> -- 装备栏位 -> EquipUid
    self.Equip = {}
end

function XDlcRelinkCharacter:NotifyCharacterData(data)
    self.CharacterId = data.CharacterId or 0
    self.StyleType = data.StyleType or 0
    self.CharacterStyleTypePassInfoDict = data.CharacterStyleTypePassInfoDict or {}
    self.Equip = data.Equip or {}
end

function XDlcRelinkCharacter:SetStyleType(StyleType)
    self.StyleType = StyleType
end

function XDlcRelinkCharacter:GetCharacterId()
    return self.CharacterId
end

function XDlcRelinkCharacter:GetStyleType()
    return self.StyleType
end

function XDlcRelinkCharacter:GetCharacterStyleTypePassInfoDict()
    return self.CharacterStyleTypePassInfoDict
end

function XDlcRelinkCharacter:GetEquip()
    return self.Equip
end

function XDlcRelinkCharacter:GetEquipBySlot(slotId)
    return self.Equip[slotId] or 0
end

-- 根据装备Uid获取装备栏位
function XDlcRelinkCharacter:GetEquipSlotId(equipUid)
    for k, v in pairs(self.Equip) do
        if v == equipUid then
            return k
        end
    end
    return 0
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

-- 卸下装备
function XDlcRelinkCharacter:UnWearEquip(equipSlotIndex)
    self.Equip[equipSlotIndex] = nil
end

---装备已穿戴在其他角色身上，自己需要卸下该装备
---@param data XDlcRelinkCharacter
function XDlcRelinkCharacter:UnWearRepeatEquip(data)
    if data.CharacterId == self.CharacterId then
        return
    end
    for _, uid in pairs(data.Equip) do
        local result, slot = table.contains(self.Equip, uid)
        if result then
            self:UnWearEquip(slot)
        end
    end
end

return XDlcRelinkCharacter

---@class XDlcRelinkCharacterPassInfo
---@field CharacterId number -- 角色Id
---@field StyleType number -- 风格类型
---@field LevelAndPassCountDict table<number, number> -- key:levelId value:passCount
