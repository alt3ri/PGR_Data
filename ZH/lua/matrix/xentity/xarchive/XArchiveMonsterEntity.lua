---@class XArchiveMonsterEntity
local XArchiveMonsterEntity = XClass(nil, "XArchiveMonsterEntity")

function XArchiveMonsterEntity:Ctor(id)
    self.Id = id
    self:Init()
end

function XArchiveMonsterEntity:Init()
    self.IsLockMain = true
    self.Kill = {}
    self.RealName = {}
    for _,npcid in pairs(self:GetNpcId() or {}) do
        self.Kill[npcid] = 0
        self.RealName[npcid] = XMVCA.XArchive.MonsterArchiveAgency:GetMonsterRealName(npcid)
    end
end

function XArchiveMonsterEntity:Reset()
    self:Init()
end

function XArchiveMonsterEntity:UpdateData(playerData)
    for key, value in pairs(playerData) do
        self[key] = value
    end
end

function XArchiveMonsterEntity:GetCfg()
    return XMVCA.XArchive.MonsterArchiveAgency:GetArchiveMonsterConfigById(self.Id)
end

function XArchiveMonsterEntity:GetInnerCfg()
    return XMVCA.XArchive.MonsterArchiveAgency:GetArchiveMonsterInnerConfigById(self.Id)
end

function XArchiveMonsterEntity:GetId()
    return self.Id
end

function XArchiveMonsterEntity:GetIsLockMain()
    return self.IsLockMain
end

function XArchiveMonsterEntity:GetKill(npcId)
    if npcId then
        return self.Kill[npcId]
    else
        return self.Kill
    end
end

function XArchiveMonsterEntity:GetRealName(npcId)
    if npcId then
        return self.RealName[npcId]
    else
        return self.RealName
    end
end

function XArchiveMonsterEntity:GetOrder()
    return self:GetCfg().Order
end

function XArchiveMonsterEntity:GetNpcId(index)
    if index then
        return self:GetCfg().NpcId[index]
    else
        return self:GetCfg().NpcId
    end
end

function XArchiveMonsterEntity:GetName()
    return self:GetInnerCfg().Name
end

function XArchiveMonsterEntity:GetIcon()
    return self:GetInnerCfg().Icon
end

function XArchiveMonsterEntity:GetPic()
    return self:GetInnerCfg().Pic
end

function XArchiveMonsterEntity:GetLockPic()
    return self:GetInnerCfg().LockPic
end

function XArchiveMonsterEntity:GetType()
    return self:GetCfg().Type
end

function XArchiveMonsterEntity:GetTagIds()
    return self:GetInnerCfg().TagIds
end

function XArchiveMonsterEntity:GetTagGroupId()
    return self:GetInnerCfg().TagGroupId
end

return XArchiveMonsterEntity