---@class XDlcMember
local XDlcMember = XClass(nil, "XDlcMember")
local XDlcPlayerData = require("XModule/XDlcRoom/XEntity/Data/XDlcPlayerData")

function XDlcMember:Ctor(playerData)
    ---@type XDlcPlayerData
    self._PlayerData = nil
    self:SetDataWithPlayerData(playerData)
end

function XDlcMember:SetDataWithPlayerData(playerData)
    if playerData then
        self._PlayerData = playerData
    end
end

function XDlcMember:Clone(other)
    if other and not other:IsEmpty() then
        if self:IsEmpty() then
            self._PlayerData = XDlcPlayerData.New()
        end
        self._PlayerData:Clone(other._PlayerData)
    else
        self:Clear()
    end
end

function XDlcMember:IsEmpty()
    return not self._PlayerData or self._PlayerData:IsEmpty() or self._PlayerData:IsClear()
end

function XDlcMember:IsLeader()
    if not self:IsEmpty() then
        return self._PlayerData:IsLeader()
    end

    return false
end

function XDlcMember:IsSelf()
    return self:GetPlayerId() == XPlayer.Id
end

function XDlcMember:IsReady()
    return self:GetState() == XEnumConst.DlcRoom.PlayerState.Ready
end

function XDlcMember:IsSelecting()
    return self:GetState() == XEnumConst.DlcRoom.PlayerState.Select
end

function XDlcMember:GetPlayerId()
    if not self:IsEmpty() then
        return self._PlayerData:GetPlayerId()
    end

    return 0
end

function XDlcMember:GetLevel()
    if not self:IsEmpty() then
        return self._PlayerData:GetLevel()
    end

    return 0
end

function XDlcMember:GetState()
    if not self:IsEmpty() then
        return self._PlayerData:GetState()
    end

    return XEnumConst.DlcRoom.PlayerState.None
end

function XDlcMember:GetCharacterId(pos)
    if not self:IsEmpty() then
        return self._PlayerData:GetCharacterId(pos)
    end

    return 0
end

function XDlcMember:GetOccupationType(pos)
    if not self:IsEmpty() then
        return self._PlayerData:GetOccupationType(pos)
    end
    return 0
end

function XDlcMember:GetName()
    if not self:IsEmpty() then
        return self._PlayerData:GetName()
    end

    return "???"
end

function XDlcMember:GetNickname()
    if not self:IsEmpty() then
        return self._PlayerData:GetNickname()
    end

    return "???"
end

function XDlcMember:GetHeadPortraitId()
    if not self:IsEmpty() then
        return self._PlayerData:GetHeadPortraitId()
    end

    return 0
end

function XDlcMember:GetHeadFrameId()
    if not self:IsEmpty() then
        return self._PlayerData:GetHeadFrameId()
    end

    return 0
end

function XDlcMember:GetCustomData()
    if not self:IsEmpty() then
        return self._PlayerData:GetCustomData()
    end

    return nil
end

function XDlcMember:HasCustomData()
    if not self:IsEmpty() then
        return self._PlayerData:HasCustomData()
    end

    return false
end

function XDlcMember:Clear()
    self._PlayerData = nil
end

---@param member XDlcMember
function XDlcMember:Equals(member)
    return member and member:GetPlayerId() == self:GetPlayerId()
end

function XDlcMember:EqualsPlayerId(playerId)
    return playerId == self:GetPlayerId()
end

--region DlcRelink相关

-- 获取Relink研发等级
function XDlcMember:GetRelinkPlayerLevel()
    if not self:IsEmpty() then
        return self._PlayerData:GetRelinkPlayerLevel()
    end
    return 0
end

-- 获取Relink装备列表
function XDlcMember:GetRelinkEquips()
    if not self:IsEmpty() then
        return self._PlayerData:GetRelinkEquips()
    end
    return {}
end

-- 根据装备栏位获取Relink装备
function XDlcMember:GetRelinkEquipBySlot(slot)
    if not XTool.IsNumberValid(slot) then
        return nil
    end

    if not self:IsEmpty() then
        return self._PlayerData:GetRelinkEquipBySlot(slot)
    end
    return nil
end

-- 根据装备Uid获取Relink装备
function XDlcMember:GetRelinkEquipByEquipUid(equipUid)
    if not XTool.IsNumberValid(equipUid) then
        return nil
    end

    if not self:IsEmpty() then
        return self._PlayerData:GetRelinkEquipByEquipUid(equipUid)
    end
    return nil
end

-- 获取Relink装备总战力
function XDlcMember:GetRelinkEquipTotalAbility()
    if not self:IsEmpty() then
        return self._PlayerData:GetRelinkEquLevel()
    end
    return 0
end

--endregion

return XDlcMember
