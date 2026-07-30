---@class XMusicPlayerConfigControl : XControl
local XMusicPlayerConfigControl = XClass(XControl, "XMusicPlayerConfigControl")

local TableKey = {
    MusicPlayerColorStyleRes = { DirPath = XConfigUtil.DirectoryType.Client, ReadFunc = XConfigUtil.ReadType.String, Identifier = 'ColorType' },
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

---region Share/Config/Config.tab 全局常量读取

---@return number
function XMusicPlayerConfigControl:GetDefaultBackgroundSongId()
    return CS.XGame.Config:GetInt("AudioPlayerDefaultBackgroundSongId")
end

---@return number
function XMusicPlayerConfigControl:GetFavoriteSongMaxCount()
    return CS.XGame.Config:GetInt("AudioPlayerFavoriteSongMaxCount")
end

function XMusicPlayerConfigControl:GetRandomPlayIngListMaxCount()
    return  CS.XGame.ClientConfig:GetInt("MusicPlayerRandomPlayListMaxCount")
end
---endregion


return XMusicPlayerConfigControl
