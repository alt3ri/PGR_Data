local XTheatre5PVEModel = XClass(nil, "XTheatre5PVEModel")

local TableKey = {
    PveEventLevel = {},
    PveChapter = {CacheType = XConfigUtil.CacheType.Normal},
    PveChapterLevel = {},
    PveEvent = {},
    PveEventGroup = {},
    PveEventOption = {},
    PveFight = {},
    PveMonster = {},
    PveStoryEntrance = {CacheType = XConfigUtil.CacheType.Normal},
    PveStroryLine = {},
    PveStroryLineContent = {},
}

function XTheatre5PVEModel:InitConfigs()
    self._ConfigUtil:InitConfigByTableKey('Theatre5/Pve', TableKey)
end

function XTheatre5PVEModel:GetChapterCfgs()
    return self._ConfigUtil:GetByTableKey(TableKey.PveChapter)
end

function XTheatre5PVEModel:GetPveEventCfgById(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.PveEvent, id)
end

return XTheatre5PVEModel