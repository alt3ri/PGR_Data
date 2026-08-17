---@class XMusicPlayerNetWorkControl : XControl
---@field private _Model XMusicPlayerModel
---@field private _MainControl XMusicPlayerControl
---@field private _AllLikeSetBgmExistSet table<number, boolean> SendAllLickSetBGMRequest 用的"已在 BGM 列表"集合,提到字段上 table.clear 复用,避免每次 new 表
local XMusicPlayerNetWorkControl = XClass(XControl, "XMusicPlayerNetWorkControl")


-- 是否走本地假数据。正式接入时改为 false。
local isInDebug = false

function XMusicPlayerNetWorkControl:OnInit()
    self._AllLikeSetBgmExistSet = {}
    local XTriggerFrequencyBlock = require("XCommon/XTriggerFrequencyBlock")
    self._SendRateBlock = XTriggerFrequencyBlock.New(1, 3)
end

---退出音乐播放器模块时,由 MainControl 在 ExitMusicMainUI 流程中调用,清理临时缓存
function XMusicPlayerNetWorkControl:ExitMusicMainUI()
    if self._AllLikeSetBgmExistSet then
        table.clear(self._AllLikeSetBgmExistSet)
    end
    self._SendRateBlock:Clear()
end

function XMusicPlayerNetWorkControl:AddAgencyEvent()
    local agency = self:GetAgency()
    agency:AddEventListener(XAgencyEventId.EVENT_NOTIFY_MUSIC_LIST_BGM_CHANGE,  self._OnNotifyBgmListChange,      self)
    agency:AddEventListener(XAgencyEventId.EVENT_NOTIFY_MUSIC_LIST_LICK_CHANGE, self._OnNotifyFavoriteListChange, self)
end

function XMusicPlayerNetWorkControl:RemoveAgencyEvent()
    local agency = self:GetAgency()
    agency:RemoveEventListener(XAgencyEventId.EVENT_NOTIFY_MUSIC_LIST_BGM_CHANGE,  self._OnNotifyBgmListChange,      self)
    agency:RemoveEventListener(XAgencyEventId.EVENT_NOTIFY_MUSIC_LIST_LICK_CHANGE, self._OnNotifyFavoriteListChange, self)
end


function XMusicPlayerNetWorkControl:OnRelease()
    self._SendRateBlock = nil
end

--- 发送协议前频率检查：1秒内最多3次，超出则弹提示并返回false
---@return boolean
function XMusicPlayerNetWorkControl:_CheckCanSendAndTipWhenFaild()
    if not self._SendRateBlock:CheckCanTrigger() then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerOperationTooFrequentTip"))
        return false
    end
    self._SendRateBlock:TriggerRecord()
    return true
end
 

function XMusicPlayerNetWorkControl:SendAllLickSetBGMRequest()
    if not self:_CheckCanSendAndTipWhenFaild() then return end

    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local musicListModel = self._Model:GetMusicListModel()
    local favoriteList = musicListModel:GetMusicListByListType(XMusicPlayerEnum.MusicListType.Favorite) or table.empty
    local bgmList = musicListModel:GetMusicListByListType(XMusicPlayerEnum.MusicListType.BGM) or table.empty

    local existSet = self._AllLikeSetBgmExistSet
    table.clear(existSet)
    local toAddMusicIDList = {}

    for _, id in ipairs(bgmList) do existSet[id] = true end
    for _, id in ipairs(favoriteList) do
        if not existSet[id] then
            existSet[id] = true
            table.insert(toAddMusicIDList, id)
        end
    end
    
    if #toAddMusicIDList <= 0 then
        XUiManager.TipError( CS.XTextManager.GetText("MusicPlayerErrorTipLikeAddBgmNoNeed"))
        return
    end

    local maxCount = self:_GetConfigControl():GetFavoriteSongMaxCount()
    if maxCount > 0 and (#bgmList + #toAddMusicIDList) > maxCount then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipLikeAddAllBgm"))
        return
    end

    if isInDebug then
        XTool.CallFunctionOnNextFrame(function()  self:OnAllLickSetBGMReply(toAddMusicIDList)  end)
    else
        XNetwork.Call("AddAudioPlayerBackgroundSongRequest", { SongIds = toAddMusicIDList }, function(res)
            if res.Code ~= XCode.Success then XLog.Error("AddAudioPlayerBackgroundSongRequest fail, code = " .. tostring(res.Code))  return end
            self:OnAllLickSetBGMReply(toAddMusicIDList)
        end)
    end
end

function XMusicPlayerNetWorkControl:OnAllLickSetBGMReply(toAddMusicIDList)
    if not toAddMusicIDList or #toAddMusicIDList <= 0 then return end

    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local musicListModel = self._Model:GetMusicListModel()
    local bgmList = musicListModel:GetAndModifyMusicListByListType(XMusicPlayerEnum.MusicListType.BGM)

    for _, musicID in ipairs(toAddMusicIDList) do
        table.insert(bgmList, 1, musicID)
    end
    self._Model:GetCommonSystemBgmModel():MarkChangedAndReset()
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE, XMusicPlayerEnum.MusicListType.BGM)

    for _, musicID in ipairs(toAddMusicIDList) do
        self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGM_ADD_TO_LIST, XMusicPlayerEnum.MusicListType.BGM, musicID)
    end

    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_LIKE_ALL_SET_BGM)
end


--- 还原背景音乐歌单
function XMusicPlayerNetWorkControl:SendBGMListResetRequest()
    if not self:_CheckCanSendAndTipWhenFaild() then return end

    if isInDebug then
        XTool.CallFunctionOnNextFrame(function()  self:OnBGMListResetReply()  end)
    else
        XNetwork.Call("ResetAudioPlayerBackgroundSongRequest", nil, function(res)
            if res.Code ~= XCode.Success then XLog.Error("ResetAudioPlayerBackgroundSongRequest fail, code = " .. tostring(res.Code))  return end
            self:OnBGMListResetReply()
        end)
    end
end

function XMusicPlayerNetWorkControl:OnBGMListResetReply(musicList)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local musicListModel = self._Model:GetMusicListModel()
    local bgmList = musicListModel:GetAndModifyMusicListByListType(XMusicPlayerEnum.MusicListType.BGM)
    table.clear(bgmList)

    local defaultSongId = self:_GetConfigControl():GetDefaultBackgroundSongId()
    if XTool.IsNumberValid(defaultSongId) then
        table.insert(bgmList, defaultSongId)
    end

    self._Model:GetCommonSystemBgmModel():MarkChangedAndReset()
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE, XMusicPlayerEnum.MusicListType.BGM)
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGMLIST_RESET, XMusicPlayerEnum.MusicListType.BGM, defaultSongId)
end


--- 加入心选歌单
function XMusicPlayerNetWorkControl:SendAddLikeMusicRequest(musicID)
    if not musicID then return end
    if not self:_CheckCanSendAndTipWhenFaild() then return end

    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local favoriteList = self._Model:GetMusicListModel():GetMusicListByListType(XMusicPlayerEnum.MusicListType.Favorite) or table.empty
    local maxCount = self:_GetConfigControl():GetFavoriteSongMaxCount()
    if maxCount > 0 and #favoriteList >= maxCount then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipLikeAddLimitMax"))
        return
    end
    if table.contains(favoriteList, musicID) then
        return  
    end

    if isInDebug then
        XTool.CallFunctionOnNextFrame(function()  self:OnAddLikeMusicReply(musicID)  end)
    else
        XNetwork.Call("AddAudioPlayerFavoriteSongRequest", { SongId = musicID }, function(res)
            if res.Code ~= XCode.Success then XLog.Error("AddAudioPlayerFavoriteSongRequest fail, code = " .. tostring(res.Code))  return end
            self:OnAddLikeMusicReply(musicID)
        end)
    end
end

function XMusicPlayerNetWorkControl:OnAddLikeMusicReply(musicID)
    local musicListModel = self._Model:GetMusicListModel()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local favoriteLit = musicListModel:GetAndModifyMusicListByListType(XMusicPlayerEnum.MusicListType.Favorite)
    if not table.contains(favoriteLit, musicID) then
        table.insert(favoriteLit, 1, musicID) 
    end
    XUiManager.PopupLeftTip(nil, CS.XTextManager.GetText("MusicPlayerTipLikeAddSuccess"),nil)
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE, XMusicPlayerEnum.MusicListType.Favorite)
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGM_ADD_TO_LIST, XMusicPlayerEnum.MusicListType.Favorite, musicID)
end



function XMusicPlayerNetWorkControl:SendRemoveLikeMusicRequest(musicID)
    if not musicID then return end
    if not self:_CheckCanSendAndTipWhenFaild() then return end

    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local favoriteList = self._Model:GetMusicListModel():GetMusicListByListType(XMusicPlayerEnum.MusicListType.Favorite) or table.empty
    if not table.contains(favoriteList, musicID) then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipLikeRemove"))
        return
    end

    if isInDebug then
        XTool.CallFunctionOnNextFrame(function()  self:OnRemoveLikeMusicReply(musicID)  end)
    else
        XNetwork.Call("RemoveAudioPlayerFavoriteSongRequest", { SongId = musicID }, function(res)
            if res.Code ~= XCode.Success then XLog.Error("RemoveAudioPlayerFavoriteSongRequest fail, code = " .. tostring(res.Code))  return end
            self:OnRemoveLikeMusicReply(musicID)
        end)
    end
end

function XMusicPlayerNetWorkControl:OnRemoveLikeMusicReply(musicID)
    local musicListModel = self._Model:GetMusicListModel()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local favoriteLit = musicListModel:GetAndModifyMusicListByListType(XMusicPlayerEnum.MusicListType.Favorite)
    XTool.TableRemove(favoriteLit, musicID)
    XUiManager.PopupLeftTip(nil, CS.XTextManager.GetText("MusicPlayerTipLikeRemoveSuccess"),nil)

    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE, XMusicPlayerEnum.MusicListType.Favorite)
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_MUISC_REMOVE_FROM_LIST, XMusicPlayerEnum.MusicListType.Favorite, musicID)
end


function XMusicPlayerNetWorkControl:SendAddBGMMusicRequest(musicID)
    if not musicID then return end
    if not self:_CheckCanSendAndTipWhenFaild() then return end

    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local bgmList = self._Model:GetMusicListModel():GetMusicListByListType(XMusicPlayerEnum.MusicListType.BGM) or table.empty
    if table.contains(bgmList, musicID) then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipBgmAddRepeat")  )
        return  
    end
    local maxCount = self:_GetConfigControl():GetFavoriteSongMaxCount()
    if maxCount > 0 and #bgmList >= maxCount then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipBgmAddLimit") )
        return
    end

    if isInDebug then
        XTool.CallFunctionOnNextFrame(function()  self:OnAddBgmMusicReply(musicID)  end)
    else
        XNetwork.Call("AddAudioPlayerBackgroundSongRequest", { SongIds = { musicID } }, function(res)
            if res.Code ~= XCode.Success then XLog.Error("AddAudioPlayerBackgroundSongRequest fail, code = " .. tostring(res.Code))  return end
            self:OnAddBgmMusicReply(musicID)
        end)
    end
end

function XMusicPlayerNetWorkControl:OnAddBgmMusicReply(musicID)
    local musicListModel = self._Model:GetMusicListModel()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local favoriteLit = musicListModel:GetAndModifyMusicListByListType(XMusicPlayerEnum.MusicListType.BGM)
    if not table.contains(favoriteLit, musicID) then
        table.insert(favoriteLit, 1, musicID) 
    end

    XUiManager.PopupLeftTip(nil, CS.XTextManager.GetText("MusicPlayerTipBgmAddSuccess"),nil)
    self._Model:GetCommonSystemBgmModel():MarkChangedAndReset()
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE, XMusicPlayerEnum.MusicListType.BGM)
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGM_ADD_TO_LIST,XMusicPlayerEnum.MusicListType.BGM, musicID)
end


--- 删除背景音乐歌单
function XMusicPlayerNetWorkControl:SendRemoveBgmMusicRequest(musicID)
    if not musicID then return end
    if not self:_CheckCanSendAndTipWhenFaild() then return end

    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local bgmList = self._Model:GetMusicListModel():GetMusicListByListType(XMusicPlayerEnum.MusicListType.BGM)
    if #bgmList <= 1 then 
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipBgmRemoveNeedOne"))
        return
    end
    if not table.contains(bgmList, musicID) then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipBgmRemoveNoExit" ))
        return 
    end

    if isInDebug then
        XTool.CallFunctionOnNextFrame(function()  self:OnRemoveBgmMusicReply(musicID)  end)
    else
        XNetwork.Call("RemoveAudioPlayerBackgroundSongRequest", { SongId = musicID }, function(res)
            if res.Code ~= XCode.Success then XLog.Error("RemoveAudioPlayerBackgroundSongRequest fail, code = " .. tostring(res.Code))  return end
            self:OnRemoveBgmMusicReply(musicID)
        end)
    end
end

function XMusicPlayerNetWorkControl:OnRemoveBgmMusicReply(musicID)
    local musicListModel = self._Model:GetMusicListModel()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local bgmLit = musicListModel:GetAndModifyMusicListByListType(XMusicPlayerEnum.MusicListType.BGM)
    XTool.TableRemove(bgmLit, musicID)

    XUiManager.PopupLeftTip(nil, CS.XTextManager.GetText("MusicPlayerTipBgmRemoveSuccess"),nil)
    self._Model:GetCommonSystemBgmModel():MarkChangedAndReset()
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE, XMusicPlayerEnum.MusicListType.BGM)
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_MUISC_REMOVE_FROM_LIST, XMusicPlayerEnum.MusicListType.BGM, musicID)
end







---@param index number Lua/客户端 1-based 索引
---@param isUp  boolean true=置顶，头插；false=向下移动
function XMusicPlayerNetWorkControl:SendBgmMusicIndexChangeRequest(index, isUp)
    if not self:_CheckCanSendAndTipWhenFaild() then return end

    -- 边界校验：列表内 + 不在端点反方向越界
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local bgmList = self._Model:GetMusicListModel():GetMusicListByListType(XMusicPlayerEnum.MusicListType.BGM) or table.empty
    local count = #bgmList

    if isUp and index == 1 then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipIndex2TopFaild" ))
        return
    end
    if not isUp and index == count then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipIndex2NextFaild"))
        return
    end


    if isInDebug then
        XTool.CallFunctionOnNextFrame(function()  self:OnBgmMusicIndexChangeReply(index, isUp)  end)
    else
        local serverIndex = self:_LuaIndex2ServerIndex(index, count)
        local req = { Index = serverIndex, MoveType = isUp and 1 or 2 }
        XNetwork.Call("MoveAudioPlayerBackgroundSongRequest", req, function(res)
            if res.Code ~= XCode.Success then XLog.Error("MoveAudioPlayerBackgroundSongRequest fail, code = " .. tostring(res.Code))  return end
            self:OnBgmMusicIndexChangeReply(index, isUp)
        end)
    end
end

function XMusicPlayerNetWorkControl:OnBgmMusicIndexChangeReply(index, isUp)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local bgmList = self._Model:GetMusicListModel():GetAndModifyMusicListByListType(XMusicPlayerEnum.MusicListType.BGM)

    if isUp then
        local songId = table.remove(bgmList, index)
        if songId then
            table.insert(bgmList, 1, songId)
        end
    else
        local targetIndex = index + 1
        bgmList[index], bgmList[targetIndex] = bgmList[targetIndex], bgmList[index]
    end

    self._Model:GetCommonSystemBgmModel():MarkChangedAndReset()
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE, XMusicPlayerEnum.MusicListType.BGM)
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGMMUSIC_INDEX_CHANGE, XMusicPlayerEnum.MusicListType.BGM)
end



function XMusicPlayerNetWorkControl:_OnNotifyBgmListChange()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    self._Model:GetCommonSystemBgmModel():MarkChangedAndReset()
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE, XMusicPlayerEnum.MusicListType.BGM)
end

function XMusicPlayerNetWorkControl:_OnNotifyFavoriteListChange()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_MUSICLIST_UPDATE, XMusicPlayerEnum.MusicListType.Favorite)
end


---@param luaIndex number Lua/客户端展示用的 1-based 索引
---@param count    number 当前 BGM 列表长度(可选，不传则取最新长度)
---@return number serverIndex 服务端使用的 0-based 索引
function XMusicPlayerNetWorkControl:_LuaIndex2ServerIndex(luaIndex, count)
    if not count then
        local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
        local bgmList = self._Model:GetMusicListModel():GetMusicListByListType(XMusicPlayerEnum.MusicListType.BGM) or table.empty
        count = #bgmList
    end
    return count - luaIndex
end

---@return XMusicPlayerConfigControl
function XMusicPlayerNetWorkControl:_GetConfigControl()
    return self._MainControl:GetMusicPlayerconfigControl()
end


return XMusicPlayerNetWorkControl
