---@class XMusicPlayerCommonSystemBgmModel : XModelBase
--- 外部场景背景音乐(CommonSystemBgm)独立播放状态
local XMusicPlayerCommonSystemBgmModel = XClass(XModelBase, "XMusicPlayerCommonSystemBgmModel")

function XMusicPlayerCommonSystemBgmModel:OnInit()
end

function XMusicPlayerCommonSystemBgmModel:ClearPrivate()
end

function XMusicPlayerCommonSystemBgmModel:ResetAll()
    self._PlayingMusicList = nil
    self._CurBgmCueId = nil
    self._InterruptTime = nil
end

function XMusicPlayerCommonSystemBgmModel:_GetSaveKey(key)
    return string.format("%s_%s", key, tostring(XPlayer.Id))
end

function XMusicPlayerCommonSystemBgmModel:SetMusicCycleType(mode)
    if mode ~= self:GetMusicCycleType() then
        local playingList = self:GetPlayingMusicList()
        local curMusicID = playingList and playingList[self:GetPlayIndex()] or self:GetCurPlayingMusicID()
        self:SetCurPlayingMusicID(curMusicID)
        self._PlayingMusicList = nil
        self:SetPlayIndex(1)
    end
    self._SaveUtil:SaveData(self:_GetSaveKey("PlayerMode"), mode)
end

function XMusicPlayerCommonSystemBgmModel:GetMusicCycleType()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    return self._SaveUtil:GetData(self:_GetSaveKey("PlayerMode")) or XMusicPlayerEnum.LoopType.ListLoop
end

function XMusicPlayerCommonSystemBgmModel:SetPlayingMusicList(musicList)
    self._PlayingMusicList = musicList
end

function XMusicPlayerCommonSystemBgmModel:GetPlayingMusicList()
    return self._PlayingMusicList
end

function XMusicPlayerCommonSystemBgmModel:SetCurPlayingMusicID(musicID)
    self._SaveUtil:SaveData(self:_GetSaveKey("CurBgmMusicID"), musicID)
end

function XMusicPlayerCommonSystemBgmModel:GetCurPlayingMusicID()
    local value = self._SaveUtil:GetData(self:_GetSaveKey("CurBgmMusicID"))
    return value
end

-- 外部背景音乐独立维护的当前播放索引（持久化，重启游戏后从记录位置续播）
function XMusicPlayerCommonSystemBgmModel:SetPlayIndex(index)
    self._SaveUtil:SaveData(self:_GetSaveKey("CurBgmPlayIndex"), index)
end

function XMusicPlayerCommonSystemBgmModel:GetPlayIndex()
    local value = self._SaveUtil:GetData(self:_GetSaveKey("CurBgmPlayIndex")) or 1
    return value
end

-- 当前正在播放的外部背景音乐 CueId（内存态，供续播判定/打断记录使用）
function XMusicPlayerCommonSystemBgmModel:SetCurBgmCueId(cueId)
    self._CurBgmCueId = cueId
end

function XMusicPlayerCommonSystemBgmModel:GetCurBgmCueId()
    return self._CurBgmCueId
end

function XMusicPlayerCommonSystemBgmModel:SetInterruptTime(time)
    self._InterruptTime = time
end

function XMusicPlayerCommonSystemBgmModel:GetInterruptTime()
    return self._InterruptTime or 0
end



-- 玩家主动调整过BGM列表后调用：直接把独立播放索引重置为第一首
function XMusicPlayerCommonSystemBgmModel:MarkChangedAndReset()
    self._PlayingMusicList = nil
    self._CurBgmCueId = nil
    self._InterruptTime = 0
    self._SaveUtil:SaveData(self:_GetSaveKey("CurBgmPlayIndex"), nil)
    self._SaveUtil:SaveData(self:_GetSaveKey("CurBgmMusicID"), nil)
end



return XMusicPlayerCommonSystemBgmModel
