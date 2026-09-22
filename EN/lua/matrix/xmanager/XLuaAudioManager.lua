local XAudioManager = CS.XAudioManager
XLuaAudioManager = XLuaAudioManager or {}

XLuaAudioManager.SoundType = {
    Music = 1 << 0,
    SFX = 1 << 1,
    Voice = 1 << 2,
}

XLuaAudioManager.Sound2PlayType = {
    [XLuaAudioManager.SoundType.Music] = XAudioManager.PlayType.Music,
    [XLuaAudioManager.SoundType.SFX] = XAudioManager.PlayType.SFX,
    [XLuaAudioManager.SoundType.Voice] = XAudioManager.PlayType.Voice,
}

XLuaAudioManager.PlayFunc = {
    [XLuaAudioManager.SoundType.Music] = XAudioManager.PlayMusic,
    [XLuaAudioManager.SoundType.SFX] = XAudioManager.PlayAudio,
    [XLuaAudioManager.SoundType.Voice] = XAudioManager.PlayCv,
}

XLuaAudioManager.SetCategoriesVolumeFunc = {
    [XLuaAudioManager.SoundType.Music] = XAudioManager.ChangeMusicVolume,
    [XLuaAudioManager.SoundType.SFX] = XAudioManager.ChangeSFXVolume,
    [XLuaAudioManager.SoundType.Voice] = XAudioManager.ChangeVoiceVolume,
}

XLuaAudioManager.SetAisacVolumeSecondFunc = {
    [XLuaAudioManager.SoundType.Music] = XAudioManager.ChangeMusicVolumeSecond,
    [XLuaAudioManager.SoundType.SFX] = XAudioManager.ChangeSFXVolumeSecond,
    [XLuaAudioManager.SoundType.Voice] = XAudioManager.ChangeVoiceVolumeSecond,
}

XLuaAudioManager.GetAisacVolumeSecondFunc = {
    [XLuaAudioManager.SoundType.Music] = function ()
        return XAudioManager.SecondMusicVolume
    end,
    [XLuaAudioManager.SoundType.SFX] = function ()
        return XAudioManager.SecondSFXVolume
    end,
    [XLuaAudioManager.SoundType.Voice] = function ()
        return XAudioManager.SecondVoiceVolume
    end,
}

XLuaAudioManager.GetCategoriesVolumeFunc = {
    [XLuaAudioManager.SoundType.Music] = XAudioManager.GetMusicVolume,
    [XLuaAudioManager.SoundType.SFX] = XAudioManager.GetSFXVolume,
    [XLuaAudioManager.SoundType.Voice] = XAudioManager.GetCvVolume,
}

local onValueTime = true
local soundTime = 0

XLuaAudioManager.GetSoundTime = function(time)
    if onValueTime == false then
        if soundTime == 0 then
            soundTime = math.ceil(time) * 1000
            XScheduleManager.ScheduleOnce(function()
                onValueTime = true
                soundTime = 0
            end, math.ceil(time) * 1000)
        end
    end
end

-- 已废弃禁用：禁止新增字段/新代码引用，改用 XAudioObjectPlayer 组件
require("XModule/XAudio/XUiBasicsMusic")
XLuaAudioManager.UiBasicsMusic = XUiBasicsMusic
-- 已废弃禁用（内部使用 UiBasicsMusic.ClickOn）：禁止新增调用，改用 XAudioObjectPlayer 组件
function XLuaAudioManager.PlayBtnMusic(value, type)
    if type == "onClick" then
        if value == 0 then
            return
        end
    end
    if type == "onValueChanged" then
        if onValueTime == true then
            --onValueTime = false
            if value then
                if value == 0 then
                    onValueTime = true
                    return
                end
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, value)
            end
        end
    end
    if type == "onEndEdit" then
        if value == nil then
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.ClickOn)
        else
            if value == 0 then
                return
            end
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, value)
        end
    end
end

-- 延迟播放BGM（临时解决）
function XLuaAudioManager.PlaySoundDoNotInterrupt(cueId)
    XScheduleManager.ScheduleOnce(function()
        XAudioManager.PlayMusic(cueId)
    end, 100)
end

function XLuaAudioManager.PlayAudioByType(soundType, cueId, ...)
    if not cueId then
        XLog.Error("XLuaAudioManager.PlaySoundByType函数错误，参数cueId不能为空")
        return
    end

    local func = XLuaAudioManager.PlayFunc[soundType]
    if not func then
        XLog.Error("XLuaAudioManager.PlayAudioByType 函数错误, 不存在此声音类型, 类型是：" .. soundType .. "cueId是：", cueId)
        return
    end

    -- 拦截配 0 屏蔽的语音，避免 cueId<=0 传入 C# 报错
    if soundType == XLuaAudioManager.SoundType.Voice then
        local ok, realCueId = XAudioManager.GetCueId(cueId)
        if not ok or not XTool.IsNumberValid(realCueId) then
            return
        end
    end

    if XLuaAudioManager.IsLuaAudioPlayLogInConsole then
        XLog.Debug(string.format("[AIFLua播放]：cueId=%s, soundType=%s\n%s", tostring(cueId), tostring(soundType), debug.traceback()))
    end

    return func(cueId, ...)
end

function XLuaAudioManager.SetAisacVolumeSecondByType(volume, soundType)
    if not volume then
        XLog.Error("XLuaAudioManager.SetAisacVolumeSecondByType 函数错误: 参数volume不能为空")
        return
    end

    local func = XLuaAudioManager.SetAisacVolumeSecondFunc[soundType]
    if not func then
        XLog.Error("XLuaAudioManager.SetAisacVolumeSecondByType 函数错误, 不存在此声音类型, 类型是: " .. soundType)
        return
    end

    func(volume)
end

function XLuaAudioManager.GetAisacVolumeSecondByType(soundType)
    local func = XLuaAudioManager.GetAisacVolumeSecondFunc[soundType]
    if not func then
        XLog.Error("XLuaAudioManager.GetAisacVolumeSecondFunc 函数错误, 不存在此声音类型, 类型是: " .. soundType)
        return
    end

    return func()
end

function XLuaAudioManager.GetCategoriesVolumeByType(soundType)
    local func = XLuaAudioManager.GetCategoriesVolumeFunc[soundType]
    if not func then
        XLog.Error("XLuaAudioManager.GetCategoriesVolumeFunc 函数错误, 不存在此声音类型, 类型是: " .. soundType)
        return
    end
    
    return func()
end

--- func desc
---@param cvId number
---@param cvType number 
---@param finishCb fun 选传
---@param source3D CriAtomSource 选传
function XLuaAudioManager.PlayCvWithCvType(cvId, cvType, finishCb, source3D)
    -- 拦截配 0 屏蔽的语音，避免 cueId<=0 传入 C# 报错
    if not XTool.IsNumberValid(cvId) then
        return
    end
    local ok, realCueId = XAudioManager.GetCueId(cvId, cvType)
    if not ok or not XTool.IsNumberValid(realCueId) then
        return
    end
    return XAudioManager.PlayCvWithCvType(cvId, cvType, finishCb, source3D)
end

function XLuaAudioManager.PrintVolumeInfo()
    XAudioManager.PrintVolumeInfo()
end

function XLuaAudioManager.PlayMusicInOut2(cueId, stopDuration, startTime, endTime, lastFor, attack, release, finishCb, isIgnoreSameMusic)
    return XAudioManager.PlayMusicInOut2(cueId, stopDuration, startTime, endTime, lastFor, attack, release, finishCb, isIgnoreSameMusic == true)
end

function XLuaAudioManager.PauseMusic()
    XAudioManager.PauseMusic()
end

function XLuaAudioManager.ResumeMusic()
    XAudioManager.ResumeMusic()
end

function XLuaAudioManager.GetCurrentMusicId()
    return XAudioManager.CurrentMusicId
end

function XLuaAudioManager.GetCurrentMusicAudioInfo()
    return XAudioManager.CurrentMusicAudioInfo1
end

function XLuaAudioManager.StartAnalyzer()
    XAudioManager.StartAnalyzer()
end

---获取 cue 真实播放时长(ms)
function XLuaAudioManager.GetCueWavRealDuration(cueId)
    return XAudioManager.GetCueWavRealDuration(cueId)
end

function XLuaAudioManager.StopAudioByCueId(cueId)
    XAudioManager.StopAudioByCueId(cueId)
end

function XLuaAudioManager.DoStopAudioInfo(info)
    XAudioManager.DoStopAudioInfo(info)
end

function XLuaAudioManager.StopAll()
    XAudioManager.StopAll()
end

function XLuaAudioManager.StopCurrentBGM()
    XAudioManager.StopMusic()
end

function XLuaAudioManager.StopAudioByType(type)
    XAudioManager.StopAudioByType(type)
end

function XLuaAudioManager.SetWholeSelector(selectorName, labelName)
    XAudioManager.SetWholeSelector(selectorName, labelName)
end

function XLuaAudioManager.MuteAisacByPlayType(type, isMute, cruveTime)
    cruveTime = cruveTime or 0
    local curType = XLuaAudioManager.Sound2PlayType[type]
    XAudioManager.MuteAisacByPlayType(curType, isMute, cruveTime)
end

function XLuaAudioManager.SetMusicSourceFirstBlockIndex(index)
    XAudioManager.SetMusicSourceFirstBlockIndex(index)
end

---恢复回系统音声设置(用于恢复被滤镜型cri音频调整后的cri音频系统配置)
function XLuaAudioManager.ResetSystemAudioVolume()
    XAudioManager.ResetSystemAudioVolume()
end

---查找当前播放的Cue中是否存在指定cueId声效
---@param cueId number
---@return XAudioManager.AudioInfo|nil
function XLuaAudioManager.FindByCueId(cueId)
    return XAudioManager.FindByCueId(cueId)
end