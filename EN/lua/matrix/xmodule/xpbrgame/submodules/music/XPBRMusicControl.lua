--- 负责业务层Bgm相关的子控制器
---@class XPBRMusicControl : XControl
---@field _MainControl XPBRGameControl
---@field private _Model
local XPBRMusicControl = XClass(XControl, "XPBRMusicControl", true)

XClassPartialRequire("XModule/XPBRGame/SubModules/Music/XPBRMusicControlConfig", "XPBRMusicControl")

function XPBRMusicControl:OnInit()
    self:InitConfigs()
    self._IsPlaying = false
    self._CurrentBgmId = nil
end

function XPBRMusicControl:AddAgencyEvent()

end

function XPBRMusicControl:RemoveAgencyEvent()

end

function XPBRMusicControl:OnRelease()
    self:StopPreview()
end

--region 播放管理

--- 开始预览播放（同曲短路，避免重复加载）
function XPBRMusicControl:PlayPreview(bgmId)
    if self._IsPlaying and self._CurrentBgmId == bgmId then
        return
    end
    self:StopPreview()
    local bgmCfg = self:GetTablePBRBgmCfgById(bgmId)
    if not bgmCfg then
        return
    end
    
    self._AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, bgmCfg.CueId)
    self._CurrentBgmId = bgmId
    self._IsPlaying = true
end

--- 停止预览播放（幂等）
function XPBRMusicControl:StopPreview()
    if self._IsPlaying then
        --CS.XAudioManager.StopBGM()
        self._IsPlaying = false
        self._CurrentBgmId = nil
    end
    
    self:_StopAudio()
end

--- 停止音效播放
function XPBRMusicControl:_StopAudio()
    if self._AudioInfo then
        self._AudioInfo:Stop()
        self._AudioInfo = nil
    end
end

function XPBRMusicControl:IsPlaying()
    return self._IsPlaying
end

--- 获取音频系统当前正在播放的曲目 CueId（与 MusicControl 托管状态无关，
--- 用于快照非托管 BGM，例如选人界面 prefab 组件播放的默认 BGM）
function XPBRMusicControl:GetCurrentSystemMusicCueId()
    return XLuaAudioManager.GetCurrentMusicId()
end

--- 停止 PBR 预览并按 CueId 还原外部 BGM（用于关闭 BGM 弹窗时恢复选人界面默认 BGM）
function XPBRMusicControl:StopPreviewAndRestoreByCueId(cueId)
    self:StopPreview()
    if XTool.IsNumberValidEx(cueId) then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, cueId)
    end
end

--- 获取已播放毫秒数（基于音频实际输出位置）
function XPBRMusicControl:GetPlayElapsedMs()
    if not self._IsPlaying then
        return 0
    end
    if self._AudioInfo then
        local t = self._AudioInfo.Time
        if t >= 0 then
            return t
        end
    end
    return 0
end

--- 获取当前播放的 BGM 配置
function XPBRMusicControl:GetCurrentBgmCfg()
    if not self._CurrentBgmId then
        return nil
    end
    return self:GetTablePBRBgmCfgById(self._CurrentBgmId)
end

--- 获取当前播放的BGM名称
function XPBRMusicControl:GetCurrentSelectBgmName(stageId)
    local bgmId = self:GetSelectedBgmIdByStageId(stageId)

    if not XTool.IsNumberValidEx(bgmId) then
        return ''
    end
    
    local cfg = self:GetTablePBRBgmCfgById(bgmId)

    if cfg then
        return cfg.Name
    end
    
    return ''
end

--- 播放 BGM（若系统已在播同一 cueId 则不打断）
function XPBRMusicControl:PlayBgmIfNotCurrent(bgmId)
    if self._IsPlaying and self._CurrentBgmId == bgmId then
        return
    end
    local bgmCfg = self:GetTablePBRBgmCfgById(bgmId)
    if not bgmCfg then
        return
    end

    -- 仅当存在活跃音频会话（_AudioInfo 非 nil）时才信任音频管理器的当前曲目状态。
    -- 若 _AudioInfo 为 nil（音频已被 StopPreview 显式停止），GetCurrentMusicId 可能仍
    -- 残留刚停止曲目的 CueId，此时接管 GetCurrentMusicAudioInfo 会拿到已停止的死实例，
    -- 导致 _IsPlaying 标真但 BGM 无声、_AudioInfo.Time 冻结、节奏圆点静止。
    if self._AudioInfo ~= nil and XLuaAudioManager.GetCurrentMusicId() == bgmCfg.CueId then
        self._AudioInfo = XLuaAudioManager.GetCurrentMusicAudioInfo()
        self._CurrentBgmId = bgmId
        self._IsPlaying = true
        return
    end

    self:StopPreview()
    self._AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Music, bgmCfg.CueId)
    self._CurrentBgmId = bgmId
    self._IsPlaying = true
end

--- 从战斗场景接管 BGM：若系统层正在播同一 CueId 则直接接管不重播，否则正常播放。
--- 仅用于商店首次打开（OnStart），此时 _AudioInfo 为 nil 但战斗 BGM 可能仍在播，
--- 不受 PlayBgmIfNotCurrent 的 _AudioInfo 守卫限制。
function XPBRMusicControl:TakeoverBgmOrPlay(bgmId)
    local bgmCfg = self:GetTablePBRBgmCfgById(bgmId)
    if not bgmCfg then
        return
    end
    if XLuaAudioManager.GetCurrentMusicId() == bgmCfg.CueId then
        self._AudioInfo = XLuaAudioManager.GetCurrentMusicAudioInfo()
        self._CurrentBgmId = bgmId
        self._IsPlaying = true
        return
    end
    self:PlayBgmIfNotCurrent(bgmId)
end

--endregion

--region BGM 选择缓存

--- 获取关卡选用的 BgmId（读缓存或返回默认）
function XPBRMusicControl:GetSelectedBgmIdByStageId(stageId)
    local saved = self._Model:GetSelectedBgmId(stageId)
    if saved then
        return saved
    end
    local stageCfg = self._MainControl:GetStageCfgById(stageId)
    if stageCfg and stageCfg.BgmIds then
        return stageCfg.BgmIds[1]
    end
    return nil
end

--- 设置关卡选用的 BgmId
function XPBRMusicControl:SetSelectedBgmIdByStageId(stageId, bgmId)
    self._Model:SetSelectedBgmId(stageId, bgmId)
end

--endregion

return XPBRMusicControl