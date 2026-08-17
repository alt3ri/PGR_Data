---@class XMusicPlayerCommonSystemBgmModel : XModelBase
--- 外部场景背景音乐(CommonSystemBgm)独立播放状态
local XMusicPlayerCommonSystemBgmModel = XClass(XModelBase, "XMusicPlayerCommonSystemBgmModel")

function XMusicPlayerCommonSystemBgmModel:OnInit()
end

function XMusicPlayerCommonSystemBgmModel:ClearPrivate()
end

function XMusicPlayerCommonSystemBgmModel:ResetAll()
end

function XMusicPlayerCommonSystemBgmModel:SetMusicCycleType(mode)
    if mode ~= self:GetMusicCycleType() then
        local playingList = self:GetPlayingMusicList()
        self._CurPlayingMusicID = playingList and playingList[self:GetPlayIndex()] or self._CurPlayingMusicID
        self._PlayingMusicList = nil
        self._PlayIndex = 1
    end
    self._SaveUtil:SaveData("PlayerMode", mode)
end

function XMusicPlayerCommonSystemBgmModel:GetMusicCycleType()
    local XMusicPlayerEnum = XMVCA.XMusicPlayer.Enum
    return self._SaveUtil:GetData("PlayerMode") or XMusicPlayerEnum.LoopType.ListLoop
end

function XMusicPlayerCommonSystemBgmModel:SetPlayingMusicList(musicList)
    self._PlayingMusicList = musicList
end

function XMusicPlayerCommonSystemBgmModel:GetPlayingMusicList()
    return self._PlayingMusicList
end

function XMusicPlayerCommonSystemBgmModel:SetCurPlayingMusicID(musicID)
    self._CurPlayingMusicID = musicID
end

function XMusicPlayerCommonSystemBgmModel:GetCurPlayingMusicID()
    return self._CurPlayingMusicID
end

-- 外部背景音乐独立维护的当前播放索引（内存态，重启游戏即丢失 -> 从第一首开始）
function XMusicPlayerCommonSystemBgmModel:SetPlayIndex(index)
    self._PlayIndex = index
end

function XMusicPlayerCommonSystemBgmModel:GetPlayIndex()
    return self._PlayIndex or 1
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
    self._PlayIndex = 1
    self._CurPlayingMusicID = nil
    self._CurBgmCueId = nil
    self._InterruptTime = 0
end



return XMusicPlayerCommonSystemBgmModel
