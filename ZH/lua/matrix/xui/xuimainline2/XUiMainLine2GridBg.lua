---@class XUiMainLine2GridBg : XUiNode
---@field private _Control XMainLine2Control
local XUiMainLine2GridBg = XClass(XUiNode, "XUiMainLine2GridBg")

function XUiMainLine2GridBg:Refresh(bgPath, isUnlock, isStart, isEnd)
    self.RImgBg:SetRawImage(bgPath)
    self.Normal.gameObject:SetActiveEx(isUnlock)
    self.BgStart.gameObject:SetActive(isStart)
    self.BgEnd.gameObject:SetActive(isEnd)
end

function XUiMainLine2GridBg:OnDestroy()
    self:ClearTimer()
end

-- 播放解锁动画
function XUiMainLine2GridBg:PlayUnlockAnim(cueId, cueDelay)
    self:ClearTimer()
    local effectGo = self.Effect.transform:GetChild(0)
    local anim = XUiHelper.TryGetComponent(effectGo, "Animation/Enable", typeof(CS.UnityEngine.Playables.PlayableDirector))
    if anim then
        local waitTime = 200
        self.Normal.gameObject:SetActiveEx(false)
        self.UnlockTimer = XScheduleManager.ScheduleOnce(function()
            self.Normal.gameObject:SetActiveEx(true)
            anim:Play()
        end, waitTime)
        if cueId then
            self.CueTimer = XScheduleManager.ScheduleOnce(function()
                XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, tonumber(cueId))
            end, waitTime + tonumber(cueDelay))
        end
    end
end

function XUiMainLine2GridBg:ClearTimer()
    if self.UnlockTimer then
        XScheduleManager.UnSchedule(self.UnlockTimer)
        self.UnlockTimer = nil
    end
    if self.CueTimer then
        XScheduleManager.UnSchedule(self.CueTimer)
        self.CueTimer = nil
    end
end

return XUiMainLine2GridBg