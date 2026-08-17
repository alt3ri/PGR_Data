---@class XMusicPlayerAgency : XAgency
---@field private _Model XMusicPlayerModel
---@field public EventIds XMusicPlayerEventId
---@field public Enum XMusicPlayerEnum
local XMusicPlayerAgency = XClass(XAgency, "XMusicPlayerAgency", true)
--部分类require
--部分类require
XClassPartialRequire("XModule/XMusicPlayer/XMusicPlayerConfigAgency", "XMusicPlayerAgency")

function XMusicPlayerAgency:OnInit()
    --初始化一些变量
    self:InitConfig()


    self.EventIds = require('XModule/XMusicPlayer/XMusicPlayerEventId')
    self.Enum     = require('XModule/XMusicPlayer/XMusicPlayerEnum')
    self.Util     = require('XModule/XMusicPlayer/XMusicPlayerUtil')
    self._BgmUpdateCb = handler(self, self._OnBgmUpdateCb)
    self._BgmFinishCb = handler(self, self._OnBgmFinishCb)
end

function XMusicPlayerAgency:InitRpc()
    self:AddRpc("NotifyAudioPlayerFavoriteSongsChange",   handler(self, self._OnNotifyAudioPlayerFavoriteSongsChange))
    self:AddRpc("NotifyAudioPlayerBackgroundSongsChange", handler(self, self._OnNotifyAudioPlayerBackgroundSongsChange))
end



function XMusicPlayerAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--region ----------播放和停止接口----------

function XMusicPlayerAgency:PlayCommonSystemBgm()
    if self:IsLock() then
        return
    end
    local bgmList = self:_GetCommonSystemBgmPlayingList()
    if #bgmList == 0 then
        return
    end
    local bgmModel = self._Model:GetCommonSystemBgmModel()
    local index = bgmModel:GetPlayIndex()
    local interruptTime = bgmModel:GetInterruptTime()
    bgmModel:SetInterruptTime(0)
    self:_PlayCommonSystemBgmByIndex(index, interruptTime)
end

---进入资源卸载期间的fallback播放模式
---@return boolean
function XMusicPlayerAgency:TryEnterFallbackForUninstall()
end

---设置Cd机失能
function XMusicPlayerAgency:SetLock(isLock)
    self._Model.IsLock = isLock
end

---Cd机是否失能
function XMusicPlayerAgency:IsLock()
    return self._Model.IsLock
end

function XMusicPlayerAgency:StopCommonSystemBgmAndRecord()
    local audioInfo = XLuaAudioManager.GetCurrentMusicAudioInfo()
    if not audioInfo then
        return
    end

    self:RecordAndRemoveCueInfoEvent(audioInfo)
    audioInfo.CustomStrParam = self.Enum.BgmMuiscTag.Shutdown
    XLuaAudioManager.StopCurrentBGM()

end


function XMusicPlayerAgency:RecordAndRemoveCueInfoEvent(audioInfo)
    self:_RemoveCueInfoEvent(audioInfo)
    self:_RecordInterruptInfo(audioInfo) 
end


function XMusicPlayerAgency:SyncCommonSystemBgmFromCdPlayer(musicID)
    local bgmModel = self._Model:GetCommonSystemBgmModel()
    local bgmList = self._Model:GetMusicListModel():GetMusicListByListType(self.Enum.MusicListType.BGM)

    local targetMusicID
    if bgmList and table.indexof(bgmList, musicID) then
        targetMusicID = musicID
    elseif bgmList and #bgmList > 0 then
        targetMusicID = bgmList[1]
    end
    bgmModel:SetCurPlayingMusicID(targetMusicID)
    bgmModel:SetPlayingMusicList(nil)
    bgmModel:SetInterruptTime(0)
end
--endregion ----------播放和停止接口----------

--region ----------Get----------

function XMusicPlayerAgency:GetCurCommonSystemBgmMusicID()
    local bgmList = self:_GetCommonSystemBgmPlayingList()
    local count = bgmList and #bgmList or 0
    if count <= 0 then
        return nil
    end
    local index = self._Model:GetCommonSystemBgmModel():GetPlayIndex()
    index = ((index - 1) % count) + 1
    return bgmList[index]
end

function XMusicPlayerAgency:GetCurCommonBgnCO()
    local musicID = self:GetCurCommonSystemBgmMusicID()
    if not XTool.IsNumberValid(musicID) then
        return nil
    end
    return self:COGetMusicPlayerAlbumCOByid(musicID)
end
--endregion ----------public end----------




local DEFAULT_BGM_CUE_ID = 1
function XMusicPlayerAgency:_GetCommonSystemBgmCueIdByIndex(index)
    local bgmList = self:_GetCommonSystemBgmPlayingList()
    local count = #bgmList

    if count <= 0 then
        XLog.Error("[XMusicPlayerAgency] bgm列表是空，有可能是后端数据问题")
    end
    
    index = ((index - 1) % count) + 1
    local musicID = bgmList[index]
    local co = musicID and self:COGetMusicPlayerAlbumCOByid(musicID)
    if co == nil then
        XLog.Error("[XMusicPlayerAgency] PlayCommonSystemBgm use default cueId fallback, index = " .. tostring(index))
        return DEFAULT_BGM_CUE_ID, nil, musicID
    end    
    return co.CueId, index, musicID
end

function XMusicPlayerAgency:_GetCommonSystemBgmPlayingList()
    local bgmModel = self._Model:GetCommonSystemBgmModel()
    local playingList = bgmModel:GetPlayingMusicList()
    if playingList then
        return playingList
    end
    return self:_RebuildCommonSystemBgmPlayingList(true)
end

function XMusicPlayerAgency:_RebuildCommonSystemBgmPlayingList(keepCurrentMusic)
    local bgmModel = self._Model:GetCommonSystemBgmModel()
    local sourceList = self._Model:GetMusicListModel():GetMusicListByListType(self.Enum.MusicListType.BGM)
    local playingList = {}
    for i = 1, #sourceList do
        playingList[i] = sourceList[i]
    end

    local loopType = bgmModel:GetMusicCycleType()
    local curMusicID = keepCurrentMusic and bgmModel:GetCurPlayingMusicID() or nil
    local playIndex = 1
    if loopType == self.Enum.LoopType.SingleLoop then
        local musicID = table.contains(playingList, curMusicID) and curMusicID or playingList[1]
        table.clear(playingList)
        if musicID then
            playingList[1] = musicID
        end
    elseif loopType == self.Enum.LoopType.RandomLoop then
        XTool.Shuffle(playingList)
        if curMusicID and table.contains(playingList, curMusicID) then
            XTool.TableRemove(playingList, curMusicID)
            table.insert(playingList, 1, curMusicID)
        end
    elseif curMusicID then
        playIndex = table.indexof(playingList, curMusicID) or 1
    end

    bgmModel:SetPlayingMusicList(playingList)
    bgmModel:SetPlayIndex(playIndex)
    return playingList
end

function XMusicPlayerAgency:_PlayCommonSystemBgmByIndex(index,startTime,isLoopPlay)
    if startTime == nil then startTime = 0 end

    local cueId, normalizedIndex, musicID = self:_GetCommonSystemBgmCueIdByIndex(index)
    local bgmModel = self._Model:GetCommonSystemBgmModel()
    bgmModel:SetPlayIndex(normalizedIndex or index)
    bgmModel:SetCurPlayingMusicID(musicID)
    bgmModel:SetCurBgmCueId(cueId)

    local audioInfo = XLuaAudioManager.PlayMusicInOut2(cueId, -1, startTime, -1, -1, 0, 0, nil, isLoopPlay)
    self:_AddCueInfoEvent(audioInfo)
    XEventManager.DispatchEvent(XEventId.EVENT_MUSIC_PLAYER_CHANGE, cueId)
end

--region cueInfo 事件
function XMusicPlayerAgency:_AddCueInfoEvent(audioInfo)
    if not audioInfo then
        return
    end
    audioInfo:RemoveUpdateCallback(self._BgmUpdateCb)
    audioInfo:RemoveFinishCallback(self._BgmFinishCb)
    audioInfo:AddUpdateCallback(self._BgmUpdateCb)
    audioInfo:AddFinishCallback(self._BgmFinishCb)
end

function XMusicPlayerAgency:_RemoveCueInfoEvent(audioInfo)
    -- 弃用：AudioInfo 回收时统一清理回调。
end

function XMusicPlayerAgency:_OnBgmUpdateCb()
    local audioInfo = XLuaAudioManager.GetCurrentMusicAudioInfo()
    local curBgmCueId = self._Model:GetCommonSystemBgmModel():GetCurBgmCueId()
    if not audioInfo or not XTool.IsNumberValid(curBgmCueId) then
        return
    end

    local durationMs = CS.XAudioManager.GetCueWavRealDuration(curBgmCueId)
    
    if audioInfo.Time >  self._Model:GetCommonSystemBgmModel():GetInterruptTime() then
        self._Model:GetCommonSystemBgmModel():SetInterruptTime(audioInfo.Time )
    end
    if durationMs <= 0 then
        return
    end

    if (audioInfo.Time or 0) >= durationMs then
        audioInfo.CustomStrParam = self.Enum.BgmMuiscTag.AutoFinish

        self:_RemoveCueInfoEvent(audioInfo)
        local bgmModel = self._Model:GetCommonSystemBgmModel()
        bgmModel:SetInterruptTime(0)
        local playingList = self:_GetCommonSystemBgmPlayingList()
        local loopType = bgmModel:GetMusicCycleType()

        local curIndex = bgmModel:GetPlayIndex()
        local nextIndex = curIndex + 1
        if loopType == self.Enum.LoopType.SingleLoop then
            nextIndex = curIndex
        elseif loopType == self.Enum.LoopType.RandomLoop and nextIndex > #playingList then
            self:_RebuildCommonSystemBgmPlayingList(false)
            nextIndex = 1
        end

        local cueId, normalizedNextIndex, musicID = self:_GetCommonSystemBgmCueIdByIndex(nextIndex)
        local isLoopPlay = normalizedNextIndex ==  curIndex
        self:_PlayCommonSystemBgmByIndex(nextIndex, 0, isLoopPlay)
    end
end


function XMusicPlayerAgency:_OnBgmFinishCb(audioInfo)
    local  customStrParam = audioInfo.CustomStrParam
    self:_RemoveCueInfoEvent(audioInfo)
    if customStrParam == self.Enum.BgmMuiscTag.AutoFinish or customStrParam == self.Enum.BgmMuiscTag.Shutdown then

    
    else
        self:RecordAndRemoveCueInfoEvent(audioInfo)
    end
end

function XMusicPlayerAgency:_RecordInterruptInfo(audioInfo)
    if not audioInfo then
        return
    end
    -- self._Model:GetCommonSystemBgmModel():SetInterruptTime(audioInfo.Time )
end

--endregion




---region 后端事件 
function XMusicPlayerAgency:OnNotifyAudioPlayerLoginData(data)
    if not data then return end
    local bgmModel = self._Model:GetCommonSystemBgmModel()    
    local isEmpty = #bgmModel  == 0 

    self:_ReplaceMusicListReversed(self.Enum.MusicListType.Favorite, data.FavoriteSongs)
    self:_ReplaceMusicListReversed(self.Enum.MusicListType.BGM,      data.BackgroundSongs)
    self._Model:GetCommonSystemBgmModel():MarkChangedAndReset()
    self:DispatchEvent(XAgencyEventId.EVENT_NOTIFY_MUSIC_LIST_LICK_CHANGE)
    self:DispatchEvent(XAgencyEventId.EVENT_NOTIFY_MUSIC_LIST_BGM_CHANGE)
end

function XMusicPlayerAgency:_OnNotifyAudioPlayerFavoriteSongsChange(data)
    if not data then return end
    self:_ReplaceMusicListReversed(self.Enum.MusicListType.Favorite, data.FavoriteSongs)
    self:DispatchEvent(XAgencyEventId.EVENT_NOTIFY_MUSIC_LIST_LICK_CHANGE)
end

function XMusicPlayerAgency:_OnNotifyAudioPlayerBackgroundSongsChange(data)
    if not data then return end
    self:_ReplaceMusicListReversed(self.Enum.MusicListType.BGM, data.BackgroundSongs)
    self._Model:GetCommonSystemBgmModel():MarkChangedAndReset()
    self:DispatchEvent(XAgencyEventId.EVENT_NOTIFY_MUSIC_LIST_BGM_CHANGE)

end

function XMusicPlayerAgency:_ReplaceMusicListReversed(listType, srcList)
    local dst = self._Model:GetMusicListModel():GetAndModifyMusicListByListType(listType)
    table.clear(dst)
    if srcList then
        for i = #srcList, 1, -1 do 
            table.insert(dst, srcList[i])
        end
    end
end
---endregion 


return XMusicPlayerAgency