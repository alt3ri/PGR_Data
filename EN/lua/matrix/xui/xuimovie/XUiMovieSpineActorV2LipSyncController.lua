---@class XUiMovieSpineActorV2LipSyncController
local XUiMovieSpineActorV2LipSyncController = XClass(nil, "XUiMovieSpineActorV2LipSyncController")

local CSUnityTime = CS.UnityEngine.Time
local CSXAudioManager = CS.XAudioManager

local LANGUAGE_NAMES = { "ja", "zh", "ca", "en" }
local TABLE_PATH_FORMAT = "Client/Movie/MovieAudioLip/%s/%s/Movie%s.tab"

function XUiMovieSpineActorV2LipSyncController:Ctor(owner, v2Controller)
    self.Owner = owner
    self.V2Controller = v2Controller
    self.IsLipSyncPlaying = false
    self.AudioLip = nil
    self.PassTime = 0
    self.NextIndex = 1
    self.Timer = nil
end

function XUiMovieSpineActorV2LipSyncController:Destroy()
    self:Stop(true)
    self.Owner = nil
    self.V2Controller = nil
end

function XUiMovieSpineActorV2LipSyncController:IsPlaying()
    return self.IsLipSyncPlaying
end

function XUiMovieSpineActorV2LipSyncController:PlayLipAnim(folderName, movieId, cvId)
    self:Stop(true)

    local audioLip = self:GetAudioLipConfig(folderName, movieId, cvId)
    if not audioLip or not self:HasPlayableLip(audioLip) then
        self:PlayFallbackTalk()
        return
    end

    self.AudioLip = audioLip
    self.IsLipSyncPlaying = true
    self.PassTime = 0
    self.NextIndex = 1
    self:StartTimer()
end

function XUiMovieSpineActorV2LipSyncController:Stop(isDestroy)
    self:RemoveTimer()

    if not self.IsLipSyncPlaying then
        return
    end

    self.AudioLip = nil
    self.IsLipSyncPlaying = false
    self.PassTime = 0
    self.NextIndex = 1

    if not isDestroy and self.V2Controller then
        self.V2Controller:PlayKouIdleAnim()
    end
end

function XUiMovieSpineActorV2LipSyncController:StartTimer()
    if self.Timer then
        return
    end

    self.Timer = XScheduleManager.ScheduleForever(function()
        self:OnUpdate()
    end, 0)
end

function XUiMovieSpineActorV2LipSyncController:RemoveTimer()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiMovieSpineActorV2LipSyncController:OnUpdate()
    if not self.IsLipSyncPlaying or not self.AudioLip then
        return
    end

    local times = self.AudioLip.Times
    if self.NextIndex <= #times then
        local nextTime = times[self.NextIndex]
        if self.PassTime >= nextTime then
            self:SetLip(self.AudioLip.Lips[self.NextIndex])
            self.NextIndex = self.NextIndex + 1
        end
        self.PassTime = self.PassTime + CSUnityTime.deltaTime
    else
        self:Stop()
    end
end

function XUiMovieSpineActorV2LipSyncController:SetLip(lipName)
    if not self.V2Controller or string.IsNilOrEmpty(lipName) then
        return
    end

    if lipName == "X" and not self.V2Controller:HasLipSyncAnim(lipName) then
        self.V2Controller:PlayKouIdleAnim()
        return
    end

    if not self.V2Controller:PlayLipSyncAnim(lipName) then
        self:PlayFallbackTalk()
    end
end

function XUiMovieSpineActorV2LipSyncController:GetAudioLipConfig(folderName, movieId, cvId)
    local cueId = self:GetCueId(cvId)
    if not cueId then
        return nil
    end

    local language = LANGUAGE_NAMES[CSXAudioManager.CvType]
    if string.IsNilOrEmpty(language) then
        XLog.Error("XUiMovieSpineActorV2LipSyncController:GetAudioLipConfig error: language not found, cvType is " .. tostring(CSXAudioManager.CvType))
        return nil
    end

    local path = string.format(TABLE_PATH_FORMAT, language, folderName, movieId)
    if not XTableManager.CheckTableExist(path) then
        XLog.Error("XUiMovieSpineActorV2LipSyncController:GetAudioLipConfig error: table not found, path is " .. tostring(path))
        return nil
    end

    local configs = XTableManager.ReadByIntKey(path, XTable.XTableMovieAudioLip, "CueId")
    local audioLip = configs and configs[cueId]
    if not audioLip then
        XLog.Error("XUiMovieSpineActorV2LipSyncController:GetAudioLipConfig error: cueId not found, path is " .. tostring(path) .. ", cueId is " .. tostring(cueId))
    end
    return audioLip
end

function XUiMovieSpineActorV2LipSyncController:GetCueId(cvId)
    local success, cueId = CSXAudioManager.GetCueId(cvId)
    if success then
        return cueId
    end

    XLog.Error("XUiMovieSpineActorV2LipSyncController:GetCueId error: cvId is " .. tostring(cvId))
    return nil
end

function XUiMovieSpineActorV2LipSyncController:HasPlayableLip(audioLip)
    local lips = audioLip and audioLip.Lips
    if not lips then
        return false
    end

    for _, lipName in pairs(lips) do
        if lipName ~= "X" and self.V2Controller and self.V2Controller:HasLipSyncAnim(lipName) then
            return true
        end
    end
    return false
end

function XUiMovieSpineActorV2LipSyncController:PlayFallbackTalk()
    self.AudioLip = nil
    self.IsLipSyncPlaying = true
    self.PassTime = 0
    self.NextIndex = 1
    self:RemoveTimer()

    if self.V2Controller then
        local speed = self.Owner and self.Owner.TalkSpeed or nil
        self.V2Controller:PlayKouTalkAnim(speed)
    end
end

return XUiMovieSpineActorV2LipSyncController
