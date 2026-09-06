---@type XMusicPlayerAgency 配置部分类
local XMusicPlayerAgency = XClassPartial("XMusicPlayerAgency")

local TableKey = {
    MusicPlayerAlbum = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    MusicPlayerEggConfig = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id', TableDefinedName = 'XTableMusicPlayerEasterEggActivity' },
}

function XMusicPlayerAgency:InitConfig()
    self:InitConfigByTabKey("MusicPlayer", TableKey)
end

function XMusicPlayerAgency:COGetMusicPlayerAlbumCOList()
    return self:GetAllConfigByTabKey(TableKey.MusicPlayerAlbum)
end

---@return XTableMusicPlayerAlbum
function XMusicPlayerAgency:COGetMusicPlayerAlbumCOByid(idKey)
    return self:GetConfigByTabKeyAndIdKey(TableKey.MusicPlayerAlbum, idKey)
end

function XMusicPlayerAgency:CheckMainUiEasterEggOpen()
    local config = self:GetConfigByTabKeyAndIdKey(TableKey.MusicPlayerEggConfig, 1)
    return config and XFunctionManager.CheckInTimeByTimeId(config.TimeCtrlId) or false
end

return XMusicPlayerAgency
