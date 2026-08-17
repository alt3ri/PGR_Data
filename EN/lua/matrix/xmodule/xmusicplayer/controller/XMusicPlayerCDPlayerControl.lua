---@class XMusicPlayerCDPlayerControl : XControl
---@field private _Model XMusicPlayerModel
---@field private _MainControl XMusicPlayerControl
---@field private _CdViewModel XMusicPlayerCDViewModel
local XMusicPlayerCDPlayerControl = XClass(XControl, "XMusicPlayerCDPlayerControl")

function XMusicPlayerCDPlayerControl:OnInit()
    self._CdViewModel = self._Model:GetCDViewModel()
    self._TempListBatch = {}
    self._AudioInfoUpdateCb = handler(self, self._OnAudioInfoUpdate)
end  

function XMusicPlayerCDPlayerControl:AddAgencyEvent()
    self._MainControl:AddEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_MUISC_REMOVE_FROM_LIST, self._OnMusicRemoveFromList, self)
    self._MainControl:AddEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGM_ADD_TO_LIST,      self._OnMusicAddToList,      self)
    self._MainControl:AddEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGMMUSIC_INDEX_CHANGE,   self._OnBgmMusicIndexChange, self)
    self._MainControl:AddEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGMLIST_RESET,           self._OnBgmListReset,        self)
    self._MainControl:AddEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_NORMAL_MUSICLIST_SORT_CHANGE,  self._OnNormalMusicListSortChange, self)
end

function XMusicPlayerCDPlayerControl:RemoveAgencyEvent()
    self._MainControl:RemoveEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_MUISC_REMOVE_FROM_LIST, self._OnMusicRemoveFromList, self)
    self._MainControl:RemoveEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGM_ADD_TO_LIST,      self._OnMusicAddToList,      self)
    self._MainControl:RemoveEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGMMUSIC_INDEX_CHANGE,   self._OnBgmMusicIndexChange, self)
    self._MainControl:RemoveEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_REPLY_BGMLIST_RESET,           self._OnBgmListReset,        self)
    self._MainControl:RemoveEventListener(XMVCA.XMusicPlayer.EventIds.EVENT_NORMAL_MUSICLIST_SORT_CHANGE,  self._OnNormalMusicListSortChange, self)
end

function XMusicPlayerCDPlayerControl:OnRelease()
    self._TempListBatch = nil
    self._LastBgmMusicID = nil
end

---region 兄弟Control的获取（统一从主Control取，避免初始化顺序问题）
---@return XMusicPlayerMusicListControl
function XMusicPlayerCDPlayerControl:_GetMusicListControl()
    return self._MainControl:GetMusicmusicListControl()
end

---@return XMusicPlayerConfigControl
function XMusicPlayerCDPlayerControl:_GetConfigControl()
    return self._MainControl:GetMusicPlayerconfigControl()
end
---endregion


function XMusicPlayerCDPlayerControl:EnterMusicMainUI()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local prevListType = self._CdViewModel:GetCurMusicListType()
    self._CdViewModel:SetCurMusicListType(XMusicPlayerEnum.MusicListType.unInit)
    self._CdViewModel:SetIsPlaying(true)
    self:_GetMusicListControl():InitNormalMusicList()

    local audioInfo = XLuaAudioManager.GetCurrentMusicAudioInfo()
    XMVCA.XMusicPlayer:RecordAndRemoveCueInfoEvent(audioInfo)

    local outerBgmMusicID = XMVCA.XMusicPlayer:GetCurCommonSystemBgmMusicID()
    if XTool.IsNumberValid(outerBgmMusicID) then
        self._LastBgmMusicID = outerBgmMusicID 
        if prevListType == XMusicPlayerEnum.MusicListType.BGM then
            -- 当前歌单是BGM(非默认): 跳转到普通列表
            self:JumpPlayByMusicIDWithNotify(XMusicPlayerEnum.MusicListType.Normal, outerBgmMusicID)
        else
            -- 当前歌单是默认(Normal/unInit): 展示BGM歌单, 队列保持BGM, 播放歌曲不变
            self:JumpPlayByMusicIDWithNotify(XMusicPlayerEnum.MusicListType.BGM, outerBgmMusicID)
        end
    else
        -- BGM歌单默认(空): 展示全部歌曲, 队列切到全部歌曲
        local normalList = self:_GetMusicListControl():GetSeverMusicListByListType(XMusicPlayerEnum.MusicListType.Normal)
        self:JumpPlayByMusicIDWithNotify(XMusicPlayerEnum.MusicListType.Normal, normalList and normalList[1])
    end
    self:_StartCurMusicTick(audioInfo)
end

function XMusicPlayerCDPlayerControl:EnterMusicFirstPlayerMusicNotify()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_CURRENT_PLAY_MUSICLISTTYPE_CHANGE, self:GetCurMusicListType())
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_PLAYER_MUSIC_CHANGE, XMusicPlayerEnum.MusicSwitchDirection.Jump)
end

function XMusicPlayerCDPlayerControl:ExitMusicMainUI()
    local audioInfo = XLuaAudioManager.GetCurrentMusicAudioInfo()
    self:_RemoveCurMusicTick(audioInfo)
    XMVCA.XMusicPlayer:SyncCommonSystemBgmFromCdPlayer(self._LastBgmMusicID)
    self._LastBgmMusicID = nil
end


---region 播放模式切换
function XMusicPlayerCDPlayerControl:SwitchMusicCycleType(loopType)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local curtype = self._CdViewModel:GetMusicCycleType()
    if loopType == curtype then
        return
    end
    self._CdViewModel:SetMusicCycleType(loopType)

    if loopType == XMusicPlayerEnum.LoopType.RandomLoop then
        self:_RebuildRandomPlayingMusicList(true)
    else
        self:_SyncRawListToPlayingList()
    end
end

function XMusicPlayerCDPlayerControl:_SyncRawListToPlayingList()
    local curMusicID = self._CdViewModel:GetCurPlayingMusicID()
    local rawList = self:GetCurRawMusicIdList()
    self._TempListBatch = self:_CopyPlayableMusicList(rawList, self._TempListBatch)
    self._CdViewModel:SetCurPlayingMusicList(self._TempListBatch)
    self._CdViewModel:SetCurPlayMusicCacheIndex(table.indexof(self._TempListBatch, curMusicID) or 1)
end

function XMusicPlayerCDPlayerControl:_IsMusicPlayable(musicID)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    return XMVCA.XMusicPlayer.Util.GetMusicUseStatus(musicID) ~= XMusicPlayerEnum.MusicUseStatus.unlock
end

function XMusicPlayerCDPlayerControl:_CopyPlayableMusicList(srcList, destList)
    table.clear(destList)
    if srcList then
        for i = 1, #srcList do
            local musicID = srcList[i]
            if self:_IsMusicPlayable(musicID) then
                destList[#destList + 1] = musicID
            end
        end
    end
    return destList
end

function XMusicPlayerCDPlayerControl:_CreateRandomMusicSlice()
    local rawList = self:GetCurRawMusicIdList()
    self._TempListBatch = self:_CopyPlayableMusicList(rawList, self._TempListBatch)
    XTool.Shuffle(self._TempListBatch)
    return self._TempListBatch
end

function XMusicPlayerCDPlayerControl:_RebuildRandomPlayingMusicList(keepCurrentFirst)
    local batch = self:_CreateRandomMusicSlice()

    local curMusicList = self._CdViewModel:GetCurPlayingMusicListAndModify()
    table.clear(curMusicList)
    for i = 1, #batch do
        curMusicList[i] = batch[i]
    end
    
    if keepCurrentFirst then
        local curMusicID = self._CdViewModel:GetCurPlayingMusicID()
        XTool.TableRemove(curMusicList, curMusicID)
        table.insert(curMusicList, 1, curMusicID)
    end
    local index = 1
    self._CdViewModel:SetCurPlayMusicCacheIndex(index)
end
---endregion


---region 上一首 / 下一首 (基于当前播放队列curPlayingMusicList)
function XMusicPlayerCDPlayerControl:_LocateCurIndexByMusicID()
    local playingList = self._CdViewModel:GetCurPlayingMusicList()
    local count = playingList and #playingList or 0
    if count <= 0 then 
        XLog.Error("播放列表: count <= 0")
        return nil, 0
    end

    if self:GetMusicCycleType() == XMVCA.XMusicPlayer.Enum.LoopType.RandomLoop then
        local index = self._CdViewModel:GetCurPlayMusicCacheIndex()
        return index, count
    end

    local curMusicID = self._CdViewModel:GetCurPlayingMusicID()
    local index = table.indexof(playingList, curMusicID) or nil
    if not index then
        -- 走到这里说明 curMusicID 已不在播放队列里(= 当前播放歌被删除),用缓存 index 定位到原来的下一首
        index = self._CdViewModel:GetCurPlayMusicCacheIndex()
        if index < 1 or index > count then --删多了 那就寄了 从第一首开始吧
            index = 1 
        end
    end
    return index, count
end


function XMusicPlayerCDPlayerControl:_ExtendRandomListAndAutoRelocationIndex(toTail, curIndex)
    local playingList = self._CdViewModel:GetCurPlayingMusicListAndModify()
    local batch = self:_CreateRandomMusicSlice ()

    local insertCount = #batch
    if toTail then
        local oldCount = #playingList
        for i = 1, insertCount do
            playingList[oldCount + i] = batch[i]
        end
    else
        for i = insertCount, 1, -1 do
            table.insert(playingList, 1, batch[i])
        end
        curIndex = curIndex + insertCount
    end

    local maxCount = self:_GetConfigControl():GetRandomPlayIngListMaxCount()
    local total = #playingList
    if total > maxCount then
        if toTail then
            for i = 1, total - insertCount do
                playingList[i] = playingList[i + insertCount]
            end
            for i = total, total - insertCount + 1, -1 do
                playingList[i] = nil
            end
            curIndex = curIndex - insertCount
        else
            for i = total, total - insertCount + 1, -1 do
                playingList[i] = nil
            end
        end
    end

    return curIndex
end

-- 播放下一首(用于手动下一首与自动续播)
function XMusicPlayerCDPlayerControl:PlayNextMusic()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local curIndex, count = self:_LocateCurIndexByMusicID()
    if not curIndex then return end

    if self:GetMusicCycleType() == XMusicPlayerEnum.LoopType.RandomLoop and curIndex >= count then
        curIndex = self:_ExtendRandomListAndAutoRelocationIndex(true, curIndex)
    end

    self:_PlayByPlayingListIndex(curIndex + 1, XMusicPlayerEnum.MusicSwitchDirection.Next)
end



-- 播放上一首
function XMusicPlayerCDPlayerControl:PlayPrevMusic()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local curIndex = self:_LocateCurIndexByMusicID()
    if not curIndex  then return end

    if self:GetMusicCycleType() == XMusicPlayerEnum.LoopType.RandomLoop and curIndex <= 1 then
        curIndex = self:_ExtendRandomListAndAutoRelocationIndex(false, curIndex)
    end

    self:_PlayByPlayingListIndex(curIndex - 1, XMusicPlayerEnum.MusicSwitchDirection.Prev)
end


-- 按当前播放队列(curPlayingMusicList)的索引播放，索引越界自动循环回绕
function XMusicPlayerCDPlayerControl:_PlayByPlayingListIndex(index, direction)
    local playingList = self._CdViewModel:GetCurPlayingMusicList()
    local count = playingList and #playingList or 0
    if count <= 0 then
        return
    end

    if index <= 0 then
        index = ((index - 1) % count + count) % count + 1
    elseif index > count then
        index = ((index - 1) % count) + 1
    end

    local isSame = index == self._CdViewModel:GetCurPlayMusicCacheIndex()
    self._CdViewModel:SetCurPlayMusicCacheIndex(index)
    self._CdViewModel:SetCurPlayingMusicID(playingList[index])
    self:PlayCurrentMusic(isSame)
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_PLAYER_MUSIC_CHANGE, direction)
end



function XMusicPlayerCDPlayerControl:GetMusicCycleType()
    return self._CdViewModel:GetMusicCycleType()
end

-- 随机模式下,跳转后以该歌为起点重建随机序列(播放队列)
function XMusicPlayerCDPlayerControl:JumpPlayByMusicIDWithNotify(switchMusicType, musicID)
    if not XTool.IsNumberValid(musicID) then
        return
    end

    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local lastMusicID = self._CdViewModel:GetCurPlayingMusicID()

    if switchMusicType ~= self._CdViewModel:GetCurMusicListType() then
        self._CdViewModel:SetCurMusicListType(switchMusicType)
        self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_CURRENT_PLAY_MUSICLISTTYPE_CHANGE, switchMusicType)
    end
    self._CdViewModel:SetCurPlayingMusicID(musicID)

    if lastMusicID ~= musicID then
        self:PlayCurrentMusic()
        self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_PLAYER_MUSIC_CHANGE, XMusicPlayerEnum.MusicSwitchDirection.Jump)
    end

    -- 随机模式:以当前歌为起点重建随机序列;列表模式:播放队列同步为服务器原始列表(只含可播放歌)
    if self:GetMusicCycleType() == XMusicPlayerEnum.LoopType.RandomLoop then
        self:_RebuildRandomPlayingMusicList(false)
    else
        self:_SyncRawListToPlayingList()
    end
end


function XMusicPlayerCDPlayerControl:GetCurMusicListType()
    return self._CdViewModel:GetCurMusicListType()
end

function XMusicPlayerCDPlayerControl:GetCurRawMusicIdList()
    local musicListType = self:GetCurMusicListType()
    return self:_GetMusicListControl():GetSeverMusicListByListType(musicListType)
end
---endregion



---region 当前歌曲配置信息
function XMusicPlayerCDPlayerControl:GetCurPlayingMusicID()
    return  self._CdViewModel:GetCurPlayingMusicID()
end

function XMusicPlayerCDPlayerControl:GetCurPlayingMusicCO()
    local musicID = self._CdViewModel:GetCurPlayingMusicID()
    if not XTool.IsNumberValid(musicID) then
        return nil
    end
    return self:_GetConfigControl():GetMusicPlayerAlbumCOByid(musicID)
end

function XMusicPlayerCDPlayerControl:IsCurMusicOpen()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local musicID = self:GetCurPlayingMusicID()
    local useStatus = self:GetMusicUseStatusAndConditionDesc(musicID)
    return useStatus ~= XMusicPlayerEnum.MusicUseStatus.unlock
end


---@param musicId number
---@return number useStatus    
---@return string conditionDesc 
function XMusicPlayerCDPlayerControl:GetMusicUseStatusAndConditionDesc(musicId)
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local musicStatus = XMVCA.XMusicPlayer.Util.GetMusicUseStatus(musicId)

    if musicStatus ~= XMusicPlayerEnum.MusicUseStatus.unlock then
        return musicStatus
    end

    local co = self:_GetConfigControl():GetMusicPlayerAlbumCOByid(musicId)
    local conditionDesc = ""
    if co and XTool.IsNumberValid(co.ConditionId) then
        conditionDesc = XConditionManager.GetConditionDescById(co.ConditionId) or ""
    end
    return musicStatus, conditionDesc
end
---endregion







function XMusicPlayerCDPlayerControl:SetIsPlaying(isPlaying)
    self._CdViewModel:SetIsPlaying(isPlaying)
    self._MainControl:DispatchEvent(XMVCA.XMusicPlayer.EventIds.EVENT_PLAYER_PLAY_STATE_CHANGE, isPlaying)
end

function XMusicPlayerCDPlayerControl:IsPlaying()
    return self._CdViewModel:GetIsPlaying()
end



---region BGM 列表细粒度变更响应
function XMusicPlayerCDPlayerControl:_OnMusicRemoveFromList(listType, removedMusicID)
    if listType ~= self:GetCurMusicListType() then
        return
    end

    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local rawList = self:GetCurRawMusicIdList() -- 心选可能被删到 0此时切回 Normal 列表,以当前歌定位继续播,找不到则第一首
    if XTool.IsTableEmpty(rawList) then
        local curMusicID = self._CdViewModel:GetCurPlayingMusicID()
        local normalList = self:_GetMusicListControl():GetSeverMusicListByListType(XMusicPlayerEnum.MusicListType.Normal)
        --跳去播normal
        local targetMusicID = table.contains(normalList, curMusicID) and curMusicID or (normalList and normalList[1])
        self:JumpPlayByMusicIDWithNotify(XMusicPlayerEnum.MusicListType.Normal, targetMusicID)
        return
    end

    local curMusicID = self._CdViewModel:GetCurPlayingMusicID()
    if curMusicID ~= removedMusicID then --删除的不是当前歌,直接同步新结果写入就行
        self:_ResyncSeverListToPlayingList()
    else
        -- 删的就是当前播放的:
        if self:GetMusicCycleType() == XMusicPlayerEnum.LoopType.RandomLoop then
            self:_RebuildRandomPlayingMusicList(true) 
            self:_PlayByPlayingListIndex(1, XMusicPlayerEnum.MusicSwitchDirection.Jump) 
        else
            -- 重建后用 fallback 拿到的 index(就是原来的下一首位置)直接播,不能再 +1
            self:_ResyncSeverListToPlayingList()
            local nextIndex = self:_LocateCurIndexByMusicID()
            self:_PlayByPlayingListIndex(nextIndex, XMusicPlayerEnum.MusicSwitchDirection.Jump)
        end
    end
end

function XMusicPlayerCDPlayerControl:_OnMusicAddToList(listType, addedMusicID)
    if listType ~= self:GetCurMusicListType() then
        return
    end
    self:_ResyncSeverListToPlayingList()
end

function XMusicPlayerCDPlayerControl:_OnNormalMusicListSortChange()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    if self:GetCurMusicListType() ~= XMusicPlayerEnum.MusicListType.Normal
            or self:GetMusicCycleType() == XMusicPlayerEnum.LoopType.RandomLoop then
        return
    end
    self:_SyncRawListToPlayingList()
end

-- BGM 列表顺序变化:不打断播放,只按最新顺序重定位
function XMusicPlayerCDPlayerControl:_OnBgmMusicIndexChange(listType)
    if listType ~= self:GetCurMusicListType() then
        return
    end
    self:_ResyncSeverListToPlayingList()
end

function XMusicPlayerCDPlayerControl:_OnBgmListReset(listType, defaultSongId)
    if listType ~= self:GetCurMusicListType() then
        return
    end

    local curMusicID = self._CdViewModel:GetCurPlayingMusicID()
    if curMusicID == defaultSongId then
        self:_ResyncSeverListToPlayingList()
        self._CdViewModel:SetCurPlayMusicCacheIndex(self:_LocateCurIndexByMusicID())
        return
    end
    self:JumpPlayByMusicIDWithNotify(listType, defaultSongId)
end

--同步服务的的新序列，不需要更新索引。因为用的是musicid去定位
function XMusicPlayerCDPlayerControl:_ResyncSeverListToPlayingList()

    if self:GetMusicCycleType() == XMVCA.XMusicPlayer.Enum.LoopType.RandomLoop then
        -- 随机模式:增删查改后旧随机队列已失效,以当前歌为起点重建随机序列(清理旧队列)
        self:_RebuildRandomPlayingMusicList(true)
    else
        self:_SyncRawListToPlayingList()
    end
end
---endregion


---region 音乐播放相关的接口
function XMusicPlayerCDPlayerControl:_MusicFinishAutoNext()
    if self:GetMusicCycleType() == XMVCA.XMusicPlayer.Enum.LoopType.SingleLoop then
        self:PlayCurrentMusic(true)
        return
    end

    self:PlayNextMusic()
end

-- 播放当前歌曲；返回是否播放成功
function XMusicPlayerCDPlayerControl:PlayCurrentMusic(isIgnoreSameMusic)
    if not self:IsCurMusicOpen() then
        XUiManager.TipError(CS.XTextManager.GetText("MusicPlayerErrorTipUnlockPlay" ))
        return false
    end

    local cueId = self:GetCurPlayingMusicCO().CueId
    if not XTool.IsNumberValid(cueId) then
        return false
    end

    local audioInfo = XLuaAudioManager.GetCurrentMusicAudioInfo()
    self:_RemoveCurMusicTick(audioInfo)
    XLuaAudioManager.StartAnalyzer()
    local audioInfo = XLuaAudioManager.PlayMusicInOut2(cueId, -1, -1, -1, -1, 1, 1, nil, isIgnoreSameMusic)
    self:_StartCurMusicTick(audioInfo)
    self:SetIsPlaying(true)

    if self:GetCurMusicListType() == XMVCA.XMusicPlayer.Enum.MusicListType.BGM then
        self._LastBgmMusicID = self._CdViewModel:GetCurPlayingMusicID()
    end
    return true
end


--region 自动轮播相关
function XMusicPlayerCDPlayerControl:_StartCurMusicTick(audioInfo)
    if not audioInfo then return end
    audioInfo:RemoveUpdateCallback(self._AudioInfoUpdateCb)
    audioInfo:AddUpdateCallback(self._AudioInfoUpdateCb)
end

function XMusicPlayerCDPlayerControl:_RemoveCurMusicTick(audioInfo)
    if not audioInfo then return end
    audioInfo:RemoveUpdateCallback(self._AudioInfoUpdateCb)
end

function XMusicPlayerCDPlayerControl:_OnAudioInfoUpdate()
    local audioInfo = XLuaAudioManager.GetCurrentMusicAudioInfo()
    local co = self:GetCurPlayingMusicCO()
    if not audioInfo or not co or not XTool.IsNumberValid(co.CueId) then
        return
    end

    local durationMs = XLuaAudioManager.GetCueWavRealDuration(co.CueId)
    if durationMs <= 0 then
        return
    end

    -- 播完:先移除当前 tick,再自动续播(续播会重新 PlayCurrentMusic 注册新 tick)
    if (audioInfo.Time or 0) >= durationMs then
        self:_MusicFinishAutoNext()
    end
end
--endregion

-- 恢复播放
function XMusicPlayerCDPlayerControl:ResumeMusic()
    XLuaAudioManager.ResumeMusic()
    self:SetIsPlaying(true)
end

-- 暂停播放
function XMusicPlayerCDPlayerControl:PauseMusic()
    XLuaAudioManager.PauseMusic()
    self:SetIsPlaying(false)
end
---endregion

function XMusicPlayerCDPlayerControl:GetTimeIdLeftStr(timeId)
    if not XTool.IsNumberValid(timeId) then
        return "00:00:00"
    end
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    if endTime <= 0 then
        return "00:00:00"
    end
    local left = math.max(0, endTime - XTime.GetServerNowTimestamp())
    return XUiHelper.GetTime(left, XUiHelper.TimeFormatType.DEFAULT)
end

-- 是否需要显示彩蛋标记:歌曲已获取(gain) 且 配置了彩蛋文本
function XMusicPlayerCDPlayerControl:NeedShowEggTag(musicId)
    if not XTool.IsNumberValid(musicId) then
        return false
    end
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    local useStatus = self:GetMusicUseStatusAndConditionDesc(musicId)
    if useStatus ~= XMusicPlayerEnum.MusicUseStatus.gain then
        return false
    end
    local co = self:_GetConfigControl():GetMusicPlayerAlbumCOByid(musicId)
    return co ~= nil and not string.IsNilOrEmpty(co.EggText)
end

return XMusicPlayerCDPlayerControl




