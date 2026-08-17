---@class XMusicPlayerConfigControl : XControl
local XMusicPlayerConfigControl = XClass(XControl, "XMusicPlayerConfigControl")

local TableKey = {
    MusicPlayerColorStyleRes = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = 'ColorType' },
    MusicPlayerConfig = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.String, Identifier = 'Key' },
    MusicPlayerAlbumDetail = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
}

function XMusicPlayerConfigControl:OnInit()
    self:InitConfigByTabKey("MusicPlayer", TableKey)
end


function XMusicPlayerConfigControl:OnRelease()
end


function XMusicPlayerConfigControl:GetMusicPlayerAlbumCOList()
    return self:GetAgency():COGetMusicPlayerAlbumCOList()
end

function XMusicPlayerConfigControl:GetMusicPlayerAlbumCOByid(idKey)
    return self:GetAgency():COGetMusicPlayerAlbumCOByid(idKey)
end

---@return XTableMusicPlayerColorStyleRes
function XMusicPlayerConfigControl:GetMusicPlayerColorStyleCO(colorType)
    return self:GetConfigByTabKeyAndIdKey(TableKey.MusicPlayerColorStyleRes, colorType)
end

---@param albumId number
---@return string|nil
function XMusicPlayerConfigControl:GetBakedColorStyle(albumId)
    local config = self:GetConfigByTabKeyAndIdKey(TableKey.MusicPlayerAlbumDetail, albumId)
    return config and config.ColorStyle
end

---region Share/Config/Config.tab 全局常量读取

---@return number
function XMusicPlayerConfigControl:GetDefaultBackgroundSongId()
    return CS.XGame.Config:GetInt("AudioPlayerDefaultBackgroundSongId")
end

---@return number
function XMusicPlayerConfigControl:GetFavoriteSongMaxCount()
    local config = self:GetConfigByTabKeyAndIdKey(TableKey.MusicPlayerConfig, "FavoriteSongMaxCount")
    return tonumber(config and config.Values and config.Values[1]) or 200
end

function XMusicPlayerConfigControl:GetRandomPlayIngListMaxCount()
    local config = self:GetConfigByTabKeyAndIdKey(TableKey.MusicPlayerConfig, "BackgroundSongMaxCount")
    return tonumber(config and config.Values and config.Values[1]) or 200
end
---endregion


return XMusicPlayerConfigControl
