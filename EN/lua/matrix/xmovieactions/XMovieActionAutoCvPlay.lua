-- 配音节点：按玩家当前配音语种(CvType)自动切换 CV
local PlayingCv

local XMovieActionAutoCvPlay = XClass(XMovieActionBase, "XMovieActionAutoCvPlay")

function XMovieActionAutoCvPlay:OnInit(actionData)
    local params = actionData.Params
    self.CueId = XDataCenter.MovieManager.ParamToNumber(params[1])
    local movieId = XDataCenter.MovieManager.GetCurPlayingMovieId()
    self.IsVoiceMuted = XMovieConfigs.IsMovieVoiceMuted(movieId)
end

function XMovieActionAutoCvPlay:GetCueId()
    return self.CueId
end

function XMovieActionAutoCvPlay:OnRunning()
    if self.IsVoiceMuted then
        return
    end

    CS.XTool.WaitForEndOfFrame(function()
        -- 加速播放时不播 CV
        if XDataCenter.MovieManager.IsSpeedUp() then
            return
        end

        self:StopLastCv()
        -- 按玩家当前配音语种播放（其他模块同样直接读 CS.XAudioManager.CvType）
        PlayingCv = XLuaAudioManager.PlayCvWithCvType(self.CueId, CS.XAudioManager.CvType)
    end)
end

function XMovieActionAutoCvPlay:StopLastCv()
    if PlayingCv then
        if PlayingCv.Playing then
            PlayingCv:Stop()
        end
        PlayingCv = nil
    end
end

function XMovieActionAutoCvPlay:OnUiRootDestroy()
    self:StopLastCv()
end

function XMovieActionAutoCvPlay:IsPassedActionRun(index)
    -- CV 是听觉表现，无视觉残留，快进时不需要重放
    return false
end

---@param action XMovieActionBase
function XMovieActionAutoCvPlay:IsPassedActionCovered(action)
    -- 配音以 CvId 标识，对应音频中断节点的参数2(CvId)，同 id 时会覆盖本节点
    if action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.AUDIO_INTERRUPT then
        return self:GetCueId() == action:GetCvId()
    end
    return false
end

function XMovieActionAutoCvPlay:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionAutoCvPlay
