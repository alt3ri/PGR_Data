---@class XMusicPlayerMusicListControl : XControl
---@field private _Model XMusicPlayerModel
---@field private _Agency XMusicPlayerAgency
---@field private _MainControl  XMusicPlayerControl
local XMusicPlayerMusicListControl = XClass(XControl, "XMusicPlayerMusicListControl")


--部分类require

function XMusicPlayerMusicListControl:OnInit()
end

function XMusicPlayerMusicListControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XMusicPlayerMusicListControl:RemoveAgencyEvent()

end

function XMusicPlayerMusicListControl:OnRelease()
end

function XMusicPlayerMusicListControl:GetSeverMusicListByListType(type)
    local result = self._Model:GetMusicListModel():GetMusicListByListType(type) 
    return result or table.empty
end

function XMusicPlayerMusicListControl:SetMusicListByListType(type, list)
    local musicListModel = self._Model:GetMusicListModel()
    musicListModel:SetMusicListByListType(type, list)
end

function XMusicPlayerMusicListControl:CheckMusicIsInListByListType(type, musicID)
    local musicListModel = self._Model:GetMusicListModel()
    return  musicListModel:CheckMusicIsInListByListType(type,musicID)
end 

function XMusicPlayerMusicListControl:InitNormalMusicList()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
 
    local musicListModel = self._Model:GetMusicListModel()
    local result = musicListModel:GetAndModifyMusicListByListType(XMusicPlayerEnum.MusicListType.Normal)
    table.clear(result)

    local coList = self._MainControl:GetMusicPlayerconfigControl():GetMusicPlayerAlbumCOList()
    for k, co in pairs(coList) do
        if not co.IsDisable then
            table.insert(result, co.Id)
        end
    end

    local isAscending = musicListModel:GetDefaultMusicListSortType()
    if isAscending then
        table.sort(result, function(a, b) return a < b end)
    else
        table.sort(result, function(a, b) return a > b end)
    end
end

function XMusicPlayerMusicListControl:SetDefaultMusicListSortType(isAscending )
    local musicListModel = self._Model:GetMusicListModel()
    local lastFlag = self:GetDefaultMusicListIsAscending()
    musicListModel:SetDefaultMusicListSortType(isAscending)
    if lastFlag ~= isAscending then
        self:InitNormalMusicList()
        local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
        self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_NORMAL_MUSICLIST_SORT_CHANGE)
        self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE,XMusicPlayerEnum.MusicListType.Normal )
    end
end

function XMusicPlayerMusicListControl:GetDefaultMusicListIsAscending()
    local musicListModel = self._Model:GetMusicListModel()
    return musicListModel:GetDefaultMusicListSortType()
end

return XMusicPlayerMusicListControl
