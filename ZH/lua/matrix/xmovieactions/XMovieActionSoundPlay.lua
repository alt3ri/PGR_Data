local UiInited, LastBgmCueId
local PlayingCvInfo
local OldVolume = {}

local CSXAudioManager = CS.XAudioManager

local XMovieActionSoundPlay = XClass(XMovieActionBase, "XMovieActionSoundPlay")

function XMovieActionSoundPlay:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.SoundType = paramToNumber(params[1])
    self.CueId = paramToNumber(params[2])
    self.Volume = params[3] and tonumber(params[3]) or nil
    self.BlockIndex = paramToNumber(params[4]) -- Cue播放部分

    -- v3.5版本之后，建议不填参数1，通过音频接口获取对应类型
    if self.SoundType == 0 then
        local cfg = CSXAudioManager.GetCueTemplate(self.CueId)
        self.SoundType = cfg.PlayType
    end
end

function XMovieActionSoundPlay:GetCueId()
    return self.CueId
end

function XMovieActionSoundPlay:GetSoundType()
    return self.SoundType
end

function XMovieActionSoundPlay:OnUiRootInit()
    if UiInited then return end
    UiInited = true

	OldVolume[XLuaAudioManager.SoundType.Voice] = XLuaAudioManager.GetAisacVolumeSecondByType(XLuaAudioManager.SoundType.Voice)
	OldVolume[XLuaAudioManager.SoundType.Music] = XLuaAudioManager.GetAisacVolumeSecondByType(XLuaAudioManager.SoundType.Music)
	OldVolume[XLuaAudioManager.SoundType.SFX] = XLuaAudioManager.GetAisacVolumeSecondByType(XLuaAudioManager.SoundType.SFX)

    LastBgmCueId = XLuaAudioManager.GetCurrentMusicId()
    CSXAudioManager.StopMusic()
end

function XMovieActionSoundPlay:OnUiRootDestroy()
    if not UiInited then return end
    UiInited = nil
    if OldVolume[XLuaAudioManager.SoundType.Voice] then
        XLuaAudioManager.SetAisacVolumeSecondByType(OldVolume[XLuaAudioManager.SoundType.Voice], XLuaAudioManager.SoundType.Voice)
    end
    if OldVolume[XLuaAudioManager.SoundType.Music] then
        XLuaAudioManager.SetAisacVolumeSecondByType(OldVolume[XLuaAudioManager.SoundType.Music], XLuaAudioManager.SoundType.Music)
    end
    if OldVolume[XLuaAudioManager.SoundType.SFX] then
        XLuaAudioManager.SetAisacVolumeSecondByType(OldVolume[XLuaAudioManager.SoundType.SFX], XLuaAudioManager.SoundType.SFX)
    end
    OldVolume = {}
    self:StopLastCv()

    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, LastBgmCueId)
end

function XMovieActionSoundPlay:OnRunning()

    CS.XTool.WaitForEndOfFrame(function()
        local soundType = self.SoundType

        -- 加速播放时，BGM以外的音效均不播放
        if XDataCenter.MovieManager.IsSpeedUp() and soundType ~= XLuaAudioManager.SoundType.Music then
            return
        end

        local cueId = self.CueId
        if soundType == XLuaAudioManager.SoundType.Music then
            XLuaAudioManager.SetMusicSourceFirstBlockIndex(self.BlockIndex)
            local defaultValue = -1
            local info = XLuaAudioManager.PlayMusicInOut2(cueId, defaultValue, defaultValue, defaultValue, defaultValue, 1, 1)
            -- 切换到副歌部分
            if self.BlockIndex ~= 0 then
                info:SetNextBlockIndex(self.BlockIndex)
            end
        elseif soundType == XLuaAudioManager.SoundType.Voice then
            self:StopLastCv()
            PlayingCvInfo = XLuaAudioManager.PlayAudioByType( soundType, cueId)
        else
            XLuaAudioManager.PlayAudioByType( soundType, cueId)
        end

        local volume = self.Volume
        if volume and CSXAudioManager.Control == 1 then
            XLuaAudioManager.SetAisacVolumeSecondByType(volume, soundType)
        end
    end)
end

function XMovieActionSoundPlay:StopLastCv()
    if PlayingCvInfo then
        if PlayingCvInfo.Playing then
            PlayingCvInfo:Stop()
        end
        PlayingCvInfo = nil
    end
end

function XMovieActionSoundPlay:IsPassedActionRun(index)
    if self.SoundType ~= XLuaAudioManager.SoundType.Music then
        return false
    end
    
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionSoundPlay:IsPassedActionCovered(action)
    if action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.AUDIO_PLAY then
        return action:GetSoundType() == self:GetSoundType() and action:GetSoundType() == XLuaAudioManager.SoundType.Music
    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.AUDIO_INTERRUPT then
        return self:GetCueId() == action:GetCueId()
    end
    return false
end

function XMovieActionSoundPlay:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionSoundPlay