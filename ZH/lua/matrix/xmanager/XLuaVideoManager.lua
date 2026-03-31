---@class XLuaVideoManager
XLuaVideoManager = XLuaVideoManager or {}

function XLuaVideoManager.PlayUiVideo(id, callback, needAuto, needSkip, defaultHideButtons)
    if not id then
        return
    end

    local config = XLuaVideoManager.GetVideoConfigById(id)
    if not XDataCenter.UiPcManager.IsPc() and not CS.XResourceManager.HasFile(config.VideoUrl, true) then
        if callback then
            callback()
        end
        return
    end

    if XDataCenter.UiPcManager.IsPc() and not CS.XResourceManager.HasFile(config.VideoUrlPc, true) then
        if callback then
            callback()
        end
        return
    end

    XLuaVideoManager.RecordVideoStart(id)
    
    XLuaUiManager.Open("UiVideoPlayer", id, callback, needAuto, needSkip, defaultHideButtons)
end

function XLuaVideoManager.LoadVideoPlayerUguiWithPrefab(parentTransform)
    if not parentTransform then
        return
    end

    return CS.XVideoManager.LoadVideoPlayerUguiWithPrefab(parentTransform)
end

-- 注意pv资源需要放在launch目录下，和下载pv使用同一份
function XLuaVideoManager.CheckCgUrl()
    local needCGBtn = false
    local videoUrl = CS.XAudioManager.LaunchVideoAsset
    local videoUrlPc = CS.XAudioManager.LaunchVideoAssetPc
    local width = CS.XLaunchManager.LaunchConfig:GetInt("LaunchVideoWidth")
    local height = CS.XLaunchManager.LaunchConfig:GetInt("LaunchVideoHeight")
    local hasVideo = (videoUrl and videoUrl ~= "" and videoUrl ~= "null")
    if hasVideo then
        local bundleName = CS.XResourceManager.GetBundleUrl(videoUrl)
        videoUrl = CS.XBundleManager.GetFile(bundleName)
        local bundleNamePc = CS.XResourceManager.GetBundleUrl(videoUrlPc)
        videoUrlPc = CS.XBundleManager.GetFile(bundleNamePc)
        needCGBtn = true
        if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.Android then
            local streamingAssetPath = CS.UnityEngine.Application.streamingAssetsPath
            local len = string.len(streamingAssetPath)

            local prefix = string.sub(videoUrl, 0, len)
            if prefix == streamingAssetPath then
                videoUrl = string.sub(videoUrl, len + 2)
            end

            local prefixPc = string.sub(videoUrlPc, 0, len)
            if prefixPc == streamingAssetPath then
                prefixPc = string.sub(videoUrlPc, len + 2)
            end
        end
    end
    return needCGBtn, videoUrl, videoUrlPc, width, height
end

function XLuaVideoManager.GetIsSkipAllCG()
    if not CS.XApplication.Debug then
        return false
    end

    return CS.XUiFightVideoPlayer.SkipAllCG
end

---@return XTableVideoConfig
function XLuaVideoManager.GetVideoConfigById(id)
    return CS.XVideoManager.GetVideoConfig(id)
end

--region 埋点相关

function XLuaVideoManager.RecordVideoStart(id)
    XDataCenter.MovieManager.RecordStorylineStart(id)
end

function XLuaVideoManager.RecordVideoEnd(id)
    XDataCenter.MovieManager.RecordStorylineEnd(id)
end

function XLuaVideoManager.RecordVideoSkip(id)
    XDataCenter.MovieManager.RecordStorylineSkip(id)
end


--endregion