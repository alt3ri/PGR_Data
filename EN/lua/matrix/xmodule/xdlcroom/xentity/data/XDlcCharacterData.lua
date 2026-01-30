---@class XDlcCharacterData
local XDlcCharacterData = XClass(nil, "XDlcCharacterData")

function XDlcCharacterData:Ctor(data)
    -- NpcId
    self._Id = nil
    self._CharacterId = nil
    -- dlc-relink 职业
    self._OccupationType = nil
    self._Level = nil

    --region Relink数据
    -- 已装备的装备
    self._RelinkEquips = nil
    -- 装备总等级
    self._RelinkEquLevel = nil
    --endregion

    self:SetData(data)
end

function XDlcCharacterData:SetData(data)
    self:_Init(data)
end

---@param other XDlcCharacterData
function XDlcCharacterData:Clone(other)
    self._Id = other._Id
    self._CharacterId = other._CharacterId
    self._OccupationType = other._OccupationType
    self._Level = other._Level
    self._RelinkEquips = other._RelinkEquips and XTool.Clone(other._RelinkEquips) or nil
    self._RelinkEquLevel = other._RelinkEquLevel
end

function XDlcCharacterData:GetCharacterId()
    return self._CharacterId
end

function XDlcCharacterData:GetId()
    return self._Id
end

function XDlcCharacterData:GetOccupationType()
    return self._OccupationType
end

function XDlcCharacterData:GetLevel()
    return self._Level
end

function XDlcCharacterData:GetRelinkEquips()
    return self._RelinkEquips
end

function XDlcCharacterData:GetRelinkEquipBySlot(slot)
    if not XTool.IsNumberValid(slot) then
        return nil
    end
    return self._RelinkEquips and self._RelinkEquips[slot] or nil
end

function XDlcCharacterData:GetRelinkEquipByEquipUid(equipUid)
    if not XTool.IsNumberValid(equipUid) or not self._RelinkEquips then
        return nil
    end
    for _, equip in pairs(self._RelinkEquips) do
        if equip.Uid == equipUid then
            return equip
        end
    end
    return nil
end

function XDlcCharacterData:GetRelinkEquLevel()
    return self._RelinkEquLevel or 0
end

function XDlcCharacterData:_Init(data)
    if data then
        self._Id = data.Id
        self._CharacterId = data.Character.Id
        self._OccupationType = data.Character.OccupationType
        self._Level = data.Level
        self._RelinkEquips = data.RelinkEquips
        self._RelinkEquLevel = data.RelinkEquLevel
    end
end

return XDlcCharacterData