---@type XMusicPlayerAgency 配置部分类
local XMusicPlayerAgency = XClassPartial("XMusicPlayerAgency")

local TableKey = {
    MusicPlayerAlbum = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
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


return XMusicPlayerAgency
