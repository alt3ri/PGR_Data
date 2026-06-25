local XUiFightAchievementGrid = XClass(nil, "XUiFightAchievementGrid")
local ToInt = XMath.ToInt

function XUiFightAchievementGrid:Ctor(parent, achievementId, config)
    self.Id = achievementId
    self.Parent = parent
    self.StageId = CS.XFight.Instance.FightData.StageId
    self.Agency = XMVCA:GetAgency(ModuleId.XMainLine2)
    self.Config = config
    
    local prefabPath = config.AssetPath
    if not prefabPath then
        return
    end
    
    self.ParentRoot = nil
    local pivot
    if config.LayoutType == 1 then
        pivot = CS.UnityEngine.Vector2(0.5, 1)
        self.ParentRoot = parent.UpperMiddle
    elseif config.LayoutType == 2 then
        pivot = CS.UnityEngine.Vector2(0.5, 0)
        self.ParentRoot = parent.LowerMiddle
    elseif config.LayoutType == 3 then
        pivot = CS.UnityEngine.Vector2(0, 1)
        self.ParentRoot = parent.UpperLeft
    elseif config.LayoutType == 4 then
        pivot = CS.UnityEngine.Vector2(0, 0)
        self.ParentRoot = parent.LowerLeft
    elseif config.LayoutType == 5 then
        pivot = CS.UnityEngine.Vector2(1, 1)
        self.ParentRoot = parent.UpperRight
    else
        pivot = CS.UnityEngine.Vector2(1, 0)
        self.ParentRoot = parent.LowerRight
    end

    local prefabGameObj = self.ParentRoot.transform:LoadPrefabEx(prefabPath)
    if not prefabGameObj then
        return
    end

    self.Prefab = prefabGameObj
    local rectTransform = prefabGameObj:GetComponent(typeof(CS.UnityEngine.RectTransform))
    rectTransform.anchorMax = pivot
    rectTransform.anchorMin = pivot
    rectTransform.anchoredPosition = CS.UnityEngine.Vector2.zero

    self.Transform = prefabGameObj.transform
    XTool.InitUiObject(self)
    
    -- 设置数据
    self.RImgIcon:SetRawImage(self.Agency:GetStageChapterAchievementIcon(self.StageId))
    self.Txt01.text = self.Agency:GetStageAchievementName(self.StageId , self.Id)
    self.Txt02.text = self.Agency:GetStageAchievementBriefDesc(self.StageId , self.Id)
    
    -- 播放音效
    local soundCueId = tonumber(config.CueId)
    if XTool.IsNumberValid(soundCueId) and soundCueId ~= 0 then
        XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, soundCueId)
    end
    
    -- 播放开场动画
    self:StartAnime()
end

function XUiFightAchievementGrid:PlayAnim(playableDirector, directorWrapMode)
    if not playableDirector then
        return
    end

    if not directorWrapMode then
        directorWrapMode = CS.UnityEngine.Playables.DirectorWrapMode.Hold
    end
    if playableDirector.extrapolationMode ~= directorWrapMode then
        playableDirector.extrapolationMode = directorWrapMode
    end

    playableDirector:Stop()
    playableDirector.time = 0
    playableDirector:Evaluate()
    playableDirector:Play()
end

function XUiFightAchievementGrid:ResetAnim(playableDirector)
    if not playableDirector then
        return
    end

    playableDirector.time = 0
    playableDirector:Evaluate()
    playableDirector:Stop()
end

function XUiFightAchievementGrid:StartAnime()
    self:PlayAnim(self.Enable)
    
    self.ScheduleId = XScheduleManager.ScheduleOnce(function()
        self:LoopAnime()
    end, ToInt(self.Enable.playableAsset.duration * 1000))
end

function XUiFightAchievementGrid:LoopAnime()
    self:PlayAnim(self.Loop)
    
    self.ScheduleId = XScheduleManager.ScheduleOnce(function()
        self:EndAnime()
    end, ToInt(self.Config.LoopTime * 1000))
end

function XUiFightAchievementGrid:EndAnime()
    self:ResetAnim(self.Loop)
    self:PlayAnim(self.Disable)

    self.ScheduleId = XScheduleManager.ScheduleOnce(function()
        self.Parent:Complete(self.Id)
    end, ToInt(self.Disable.playableAsset.duration * 1000))
end

function XUiFightAchievementGrid:StopTimer()
    if self.ScheduleId ~= nil then
        XScheduleManager.UnSchedule(self.ScheduleId)
        self.ScheduleId = nil
    end
end

function XUiFightAchievementGrid:Dispose()
    self:StopTimer()

    if self.Prefab then
        XUiHelper.Destroy(self.Prefab.gameObject)
        self.Prefab = nil
    end

    local prefabPath = self.Config.AssetPath
    if self.ParentRoot and prefabPath then
        self.ParentRoot:UnloadPrefabEx(prefabPath)
        self.ParentRoot = nil
    end
end

return XUiFightAchievementGrid
