local XRedPointConditionArchiveMonsterRed = {}
local Events = nil

function XRedPointConditionArchiveMonsterRed.GetSubEvents()
    Events = Events or
    {
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTER),
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERINFO),
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSKILL),
        XRedPointEventElement.New(XEventId.EVNET_ARCHIVE_MONSTER_UNLOCKMONSTERSETTING),
    }
    return Events
end

function XRedPointConditionArchiveMonsterRed.Check(monsterId)
    return XMVCA.XArchive.MonsterArchiveAgency:IsMonsterHaveRedPointById(monsterId) and
    not XMVCA.XArchive.MonsterArchiveAgency:IsMonsterHaveNewTagById(monsterId)
end

return XRedPointConditionArchiveMonsterRed