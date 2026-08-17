---@class XMusicPlayerCDViewModel: XModelBase
local XMusicPlayerCDViewModel = XClass(XModelBase, 'XMusicPlayerCDViewModel')

 
function XMusicPlayerCDViewModel:OnInit()
    self._PrivateWillClear = {}
end

function XMusicPlayerCDViewModel:ClearPrivate()
    table.clear(self._PrivateWillClear)
end

function XMusicPlayerCDViewModel:ResetAll()

end


function XMusicPlayerCDViewModel:SetMusicCycleType(mode)
    self._MainModel:GetCommonSystemBgmModel():SetMusicCycleType(mode)
end

function XMusicPlayerCDViewModel:GetMusicCycleType()
    return self._MainModel:GetCommonSystemBgmModel():GetMusicCycleType()
end

-- 仅用于"当前播放歌曲被删除"时的重定位 fallback,不参与正常播放决策(正常一律以 CurPlayingMusicID 为准)
function XMusicPlayerCDViewModel:SetCurPlayMusicCacheIndex(index)
    self:_SetPrivate("CurPlayMusicCacheIndex", index)
end

function XMusicPlayerCDViewModel:GetCurPlayMusicCacheIndex()
    return self:_GetPrivate("CurPlayMusicCacheIndex") or 1
end

function XMusicPlayerCDViewModel:SetCurMusicListType(musicListType)
    self:_SetPrivate("CurMusicListType", musicListType)
end

function XMusicPlayerCDViewModel:GetCurMusicListType()
    return self:_GetPrivate("CurMusicListType")
end

-- 是否正在播放


function XMusicPlayerCDViewModel:SetCurPlayingMusicList(musicList)
    local curList = self:_GetPrivate("CurPlayingMusicList")

    if curList == nil then
        curList = {}
    else
        table.clear(curList)
    end
    for i = 1, #musicList do
        curList[i] = musicList[i]
    end
    self:_SetPrivate("CurPlayingMusicList", curList)
end

function XMusicPlayerCDViewModel:GetCurPlayingMusicList()
    local musicList = self:_GetPrivate("CurPlayingMusicList")
    if musicList == nil then
        musicList = {}
        self:_SetPrivate("CurPlayingMusicList", musicList)
    end
    return musicList
end

function XMusicPlayerCDViewModel:GetCurPlayingMusicListAndModify()
    return self:GetCurPlayingMusicList()
end

function XMusicPlayerCDViewModel:SetCurPlayingMusicID(musicID)
    self:_SetPrivate("CurPlayingMusicID", musicID)
end

function XMusicPlayerCDViewModel:GetCurPlayingMusicID()
    return self:_GetPrivate("CurPlayingMusicID")
end

function XMusicPlayerCDViewModel:GetIsPlaying()
    return self:_GetPrivate("isPlaying") and true or false
end

function XMusicPlayerCDViewModel:SetIsPlaying(isPlaying)
    self:_SetPrivate("isPlaying", isPlaying)
end


function XMusicPlayerCDViewModel:_SetPrivate(key, value)
    self._PrivateWillClear[key] = value
end

function XMusicPlayerCDViewModel:_GetPrivate(key)
    return self._PrivateWillClear[key]
end

return XMusicPlayerCDViewModel
