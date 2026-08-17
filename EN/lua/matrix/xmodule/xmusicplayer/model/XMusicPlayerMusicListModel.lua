---@class XMusicPlayerMusicListModel: XModelBase
local XMusicPlayerMusicListModel = XClass(XModelBase, 'XMusicPlayerMusicListModel')


function XMusicPlayerMusicListModel:OnInit()
    self._PrivateWillClear = {}
end

function XMusicPlayerMusicListModel:ClearPrivate()
    table.clear(self._PrivateWillClear)
end

function XMusicPlayerMusicListModel:ResetAll()

end
 



--region ----------public start----------
function XMusicPlayerMusicListModel:_SetBGMMusicList(list)
    self._BgmMusicList = list
end

function XMusicPlayerMusicListModel:_GetBGMMusicList()
    return self._BgmMusicList
end

  
function XMusicPlayerMusicListModel:_SetFavoriteMusicList(list)
    self._FavoriteMusicList = list
end

function XMusicPlayerMusicListModel:_GetFavoriteMusicList()
    return self._FavoriteMusicList
end

function XMusicPlayerMusicListModel:_SetNormalMusicList(list)
    self._NormalMusicList = list
end 

function XMusicPlayerMusicListModel:_GetNormalMusicList()
    return self._NormalMusicList
end

function XMusicPlayerMusicListModel:GetMusicListByListType(listType)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    if XMusicPlayerEnum.MusicListType.BGM == listType then
        return self._BgmMusicList or table.empty
    elseif XMusicPlayerEnum.MusicListType.Favorite == listType then
        return self._FavoriteMusicList or table.empty
    elseif XMusicPlayerEnum.MusicListType.Normal == listType then
        return self._NormalMusicList or table.empty
    end
end

function XMusicPlayerMusicListModel:GetAndModifyMusicListByListType(listType)
    local toBeModifyList = self:GetMusicListByListType(listType)
    if toBeModifyList == table.empty then
        toBeModifyList = {}
        self:SetMusicListByListType(listType,toBeModifyList)
    end
    return toBeModifyList
end

function XMusicPlayerMusicListModel:SetMusicListByListType(listType, list)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    if XMusicPlayerEnum.MusicListType.BGM == listType then
        self._BgmMusicList = list
    elseif XMusicPlayerEnum.MusicListType.Favorite == listType then
        self._FavoriteMusicList = list
    elseif XMusicPlayerEnum.MusicListType.Normal == listType then
        self._NormalMusicList = list
    end
end

function XMusicPlayerMusicListModel:CheckMusicIsInListByListType(listType, musicId)
    return table.contains(self:GetMusicListByListType(listType), musicId)
end

function XMusicPlayerMusicListModel:SetDefaultMusicListSortType(ascending )
    self._SaveUtil:SaveData("DefaultMusicListSort", ascending )
end

function XMusicPlayerMusicListModel:GetDefaultMusicListSortType()
    local value = self._SaveUtil:GetData("DefaultMusicListSort")
    if value == nil then
        return true
    end
    return value
end 

function XMusicPlayerMusicListModel:_SetPrivate(key, value)
    self._PrivateWillClear[key] = value
end

function XMusicPlayerMusicListModel:_GetPrivate(key)
    return self._PrivateWillClear[key]
end

return XMusicPlayerMusicListModel
