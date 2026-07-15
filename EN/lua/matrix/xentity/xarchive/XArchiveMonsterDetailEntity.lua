---@class XArchiveMonsterDetailEntity
local XArchiveMonsterDetailEntity = XClass(nil, "XArchiveMonsterDetailEntity")

local EntityType = {
    Info = 1,
    Setting = 2,
    Skill = 3,
}

function XArchiveMonsterDetailEntity:Ctor(type,id)
    self.Id = id
    self.IsLock = true
    self.LockDesc = ""
    self.Type = type
end

function XArchiveMonsterDetailEntity:SetIsLock(isLock)
    self.IsLock = isLock
end

function XArchiveMonsterDetailEntity:SetLockDesc(lockDesc)
    self.LockDesc = lockDesc
end

function XArchiveMonsterDetailEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchiveMonsterDetailEntity:GetCfg()
    if self.Type == EntityType.Info then
        return XMVCA.XArchive.MonsterArchiveAgency:GetArchiveMonsterInfoConfigById(self.Id)
    elseif self.Type == EntityType.Setting then
        return XMVCA.XArchive.MonsterArchiveAgency:GetArchiveMonsterSettingConfigById(self.Id)
    elseif self.Type == EntityType.Skill then
        return XMVCA.XArchive.MonsterArchiveAgency:GetArchiveMonsterSkillConfigById(self.Id)
    end
end

function XArchiveMonsterDetailEntity:GetInnerCfg()
    if self.Type == EntityType.Info then
        return XMVCA.XArchive.MonsterArchiveAgency:GetArchiveMonsterInfoInnerConfigById(self.Id)
    elseif self.Type == EntityType.Setting then
        return XMVCA.XArchive.MonsterArchiveAgency:GetArchiveMonsterSettingInnerConfigById(self.Id)
    end
    return self:GetCfg()
end

function XArchiveMonsterDetailEntity:GetId()
    return self.Id
end

function XArchiveMonsterDetailEntity:GetIsLock()
    return self.IsLock
end

function XArchiveMonsterDetailEntity:GetLockDesc()
    return self.LockDesc
end

function XArchiveMonsterDetailEntity:GetGroupId()
    return self:GetCfg().GroupId
end

function XArchiveMonsterDetailEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchiveMonsterDetailEntity:GetTitle()
    return self:GetInnerCfg().Title
end

function XArchiveMonsterDetailEntity:GetText()
    return self:GetInnerCfg().Text
end

function XArchiveMonsterDetailEntity:GetType()
    return self:GetCfg().Type
end

function XArchiveMonsterDetailEntity:GetCondition()
    return self:GetCfg().Condition
end

return XArchiveMonsterDetailEntity