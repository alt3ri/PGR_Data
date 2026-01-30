local CSXUiPlayTimelineAnimation = CS.XUiPlayTimelineAnimation
local DefaultScale = CS.UnityEngine.Vector3(1, 1, 1)
local DefaultColor = CS.UnityEngine.Color.white
local FrontScale = CS.UnityEngine.Vector3(1.02, 1.02, 1)
local BackColor = CS.UnityEngine.Color(0.39, 0.39, 0.39, 1)
local DefaultRotation = CS.UnityEngine.Vector3(0, 0, 0)
local DefaultReverseRotation = CS.UnityEngine.Vector3(0, 180, 0)

local AnimNameHead = "PanelActor"
local AnimNames = {
    Enable = "Enable",
    Disable = "Disable",
    NormalToFront = "BlowUpNor",
    NormalToBack = "DarkNor",
    BackToFront = "BlowUp",
    FrontToBack = "Dark",
}

local ShowStatus = {
    Normal = 0,
    Back = 1,
    Front = 2,
    Hide = 3,
}

---@class XUiGridMovieActor
---@field UiMovie XUiMovie
local XUiGridMovieActor = XClass(nil, "XUiGridMovieActor")

function XUiGridMovieActor:Ctor(uiMovie, link, actorIndex)
    self.UiMovie = uiMovie
    self.Link = link -- 挂点
    self.ActorIndex = actorIndex
    self.Status = ShowStatus.Hide
    self.IsReverse = false
end

function XUiGridMovieActor:OnDestroy()
    self.UiMovie = nil
end

function XUiGridMovieActor:LoadPrefab()
    if not self.GameObject then
        local actorGo = self.UiMovie:GetUiMoviePanelActor()
        self.GameObject = XUiHelper.Instantiate(actorGo, self.Link)
        self.Transform = self.GameObject.transform
        self.GameObject.gameObject:SetActiveEx(true)
        XTool.InitUiObject(self)
        
        -- 设置XUiEffectLayer的TargetCanvas
        local canvas = self:GetComponentCanvas()
        local components = self.Transform:GetComponentsInChildren(typeof(CS.XUiEffectLayer), false)
        for i = 0, components.Length - 1, 1 do
            components[i]:SetTargetCanvas(canvas)
        end
    end
end

function XUiGridMovieActor:IsLoaded()
    return self.GameObject ~= nil
end

function XUiGridMovieActor:GetComponentCanvas()
    local current = self.Transform
    local canvas
    while not canvas or canvas:Equals(nil) do
        canvas = current:GetComponent(typeof(CS.UnityEngine.Canvas))
        if not canvas or canvas:Equals(nil) then
            current = current.parent
        end
    end
    return canvas
end

function XUiGridMovieActor:UpdateActor(actorId)
    if self.ActorId == actorId then return end
    self.ActorId = actorId

    self:LoadPrefab()
    self:SetImage()
    self.Link.gameObject:SetActiveEx(true)
end

function XUiGridMovieActor:SetImage()
    local rImgActor = self.RImgActor
    if not rImgActor then return end

    local actorId = self.ActorId
    local path = XMovieConfigs.GetActorImgPath(actorId)
    rImgActor:SetRawImage(path, function()
        rImgActor:SetNativeSize()
    end)
end

function XUiGridMovieActor:SetImagePos(pos)
    if self.Pos == pos then return end
    local actorRoot = self.PanelActorRoot
    self.Pos = pos
    actorRoot.anchoredPosition3D = pos
end

function XUiGridMovieActor:Reverse(isReverse)
    self.IsReverse = isReverse
end

function XUiGridMovieActor:GetImagePos()
    return self.Pos
end

function XUiGridMovieActor:GetEffectGo()
    self:LoadPrefab()
    return self.EffctActor
end

function XUiGridMovieActor:GetEffectParentGo()
    self:LoadPrefab()
    return self.RImgActor.transform
end

function XUiGridMovieActor:GetActorId()
    return self.ActorId or 0
end

function XUiGridMovieActor:GetFaceId()
    return self.FaceId or 0
end

function XUiGridMovieActor:IsHide()
    return self.Status == ShowStatus.Hide
end

function XUiGridMovieActor:IsBack()
    return self.Status == ShowStatus.Back
end

function XUiGridMovieActor:IsFront()
    return self.Status == ShowStatus.Front
end

function XUiGridMovieActor:SetFace(faceId)
    if not self.ActorId then return end

    local rImgFace = self.RImgFace

    local actorId = self.ActorId
    if faceId ~= 0 then
        self.FaceId = faceId
        local path = XMovieConfigs.GetActorFaceImgPath(actorId, faceId)
        rImgFace:SetRawImage(path, function()
            rImgFace:SetNativeSize()
        end)
        rImgFace.rectTransform.anchoredPosition = XMovieConfigs.GetActorFacePosVector2(actorId)
        rImgFace.gameObject:SetActiveEx(true)
    else
        rImgFace.gameObject:SetActiveEx(false)
    end
end

function XUiGridMovieActor:SetGrayScale(value, time)
    if not self:IsLoaded() then return end

    if self.GrayValue == value then return end
    self.GrayValue = value
    self.MetearialActor:SetGrayScale(value, time)
    self.MeterialFace:SetGrayScale(value, time)
end

function XUiGridMovieActor:RevertActorPanel()
    local rImgActor = self.RImgActor
    local rImgFace = self.RImgFace
    if XTool.UObjIsNil(rImgActor) then return end

    local alpha = self.CanvasGroup.alpha
    local color = DefaultColor
    local scale = DefaultScale
    local angle = self.IsReverse and DefaultReverseRotation or DefaultRotation
    local status = self.Status
    if status == ShowStatus.Back then
        color = BackColor
    elseif status == ShowStatus.Front then
        self.Link.transform:SetAsLastSibling()
        scale = FrontScale
    elseif status == ShowStatus.Hide then
        alpha = 0
        self.Link.gameObject:SetActiveEx(false)
    elseif status == ShowStatus.Normal then
        alpha = 1    
    end

    self.CanvasGroup.alpha = alpha
    rImgActor.color = color
    rImgFace.color = color
    rImgActor.rectTransform.localScale = scale
    rImgActor.rectTransform.eulerAngles = angle
end

function XUiGridMovieActor:PlayAnimEnable(skipAnim)
    if self.IsUsing then return end
    self.IsUsing = true

    if self.Status == ShowStatus.Normal then return end
    self.Status = ShowStatus.Normal
    self.Link.gameObject:SetActiveEx(true)

    if skipAnim then
        self.CanvasGroup.alpha = 1
        self:RevertActorPanel()
        return
    end

    local anim = self:GetAnim(AnimNames.Enable)
    if not anim then return end

    -- 停止播放Disable动画，避免复用actor时Enable和Disable动画同时播放
    self:StopAnimtion(AnimNames.Enable)
    self:StopAnimtion(AnimNames.Disable)
    anim.gameObject:SetActiveEx(true)
    anim:PlayTimelineAnimation(function()
        XLuaUiManager.SetMask(false)
        self.IsPlayingEnable = nil
        self:StopAnimtion(AnimNames.Enable)

        local tmpAnim = self.DelayAnim
        if tmpAnim then
            tmpAnim.gameObject:SetActiveEx(true)
            tmpAnim:PlayTimelineAnimation(function()
                XLuaUiManager.SetMask(false)
                self:StopAnimtion(AnimNames.NormalToFront)
                self:StopAnimtion(AnimNames.NormalToBack)
                self:RevertActorPanel()
            end, function()
                XLuaUiManager.SetMask(true)
            end)
            self.DelayAnim = nil
        else
            self:RevertActorPanel()
        end
    end, function()
        XLuaUiManager.SetMask(true)
        self.IsPlayingEnable = true
    end,CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiGridMovieActor:PlayAnimDisable(skipAnim, cb)
    if not self.IsUsing then return end
    self.IsUsing = nil

    if self.Status == ShowStatus.Hide then return end
    self.Status = ShowStatus.Hide

    if skipAnim then
        self:RevertActorPanel()
        return
    end

    local anim = self:GetAnim(AnimNames.Disable)
    if not anim then return end
    
    -- 停止播放Disable动画，避免复用actor时Enable和Disable动画同时播放
    self:StopAnimtion(AnimNames.Enable)
    self:StopAnimtion(AnimNames.Disable)
    anim.gameObject:SetActiveEx(true)
    anim:PlayTimelineAnimation(function()
        XLuaUiManager.SetMask(false)
        self:StopAnimtion(AnimNames.Disable)
        if cb then
            cb()
        end
    end, function()
        XLuaUiManager.SetMask(true)
    end,CS.UnityEngine.Playables.DirectorWrapMode.None)
end

function XUiGridMovieActor:PlayAnimBack(skipAnim)
    if not self.IsUsing then return end

    if self.Status == ShowStatus.Back then return end

    local anim = self:GetStatusAnim(ShowStatus.Back)
    if not anim then return end

    self.Status = ShowStatus.Back

    if skipAnim then
        self:RevertActorPanel()
        return
    end

    if self.IsPlayingEnable then
        self.DelayAnim = anim
        return
    end
    
        anim.gameObject:SetActiveEx(true)
        anim:PlayTimelineAnimation(function()
            XLuaUiManager.SetMask(false)
            self:StopAnimtion(AnimNames.NormalToBack)
            self:StopAnimtion(AnimNames.FrontToBack)
            self:RevertActorPanel()
        end, function()
            XLuaUiManager.SetMask(true)
        end,CS.UnityEngine.Playables.DirectorWrapMode.None)    
end

function XUiGridMovieActor:PlayAnimFront(skipAnim)
    if not self.IsUsing then return end

    if self.Status == ShowStatus.Front then return end

    local anim = self:GetStatusAnim(ShowStatus.Front)
    if not anim then return end

    self.Status = ShowStatus.Front

    if skipAnim then
        self:RevertActorPanel()
        return
    end

    if self.IsPlayingEnable then
        self.DelayAnim = anim
        return
    end

        anim.gameObject:SetActiveEx(true)
        anim:PlayTimelineAnimation(function()
            XLuaUiManager.SetMask(false)
            self:StopAnimtion(AnimNames.NormalToFront)
            self:StopAnimtion(AnimNames.BackToFront)
            self:RevertActorPanel()
        end, function()
            XLuaUiManager.SetMask(true)
        end,CS.UnityEngine.Playables.DirectorWrapMode.None)    
end

function XUiGridMovieActor:GetStatusAnim(toStatus)
    local anim
    local status = self.Status
    if toStatus == ShowStatus.Back then
        if status == ShowStatus.Normal then
            anim = self:GetAnim(AnimNames.NormalToBack)
        elseif status == ShowStatus.Front then
            anim = self:GetAnim(AnimNames.FrontToBack)
        end
    elseif toStatus == ShowStatus.Front then
        if status == ShowStatus.Normal then
            anim = self:GetAnim(AnimNames.NormalToFront)
        elseif status == ShowStatus.Back then
            anim = self:GetAnim(AnimNames.BackToFront)
        end
    end

    return anim
end

function XUiGridMovieActor:PlayFadeAnimation(beginAlpha,endAlpha,duration)
    self.CanvasGroup.alpha = beginAlpha
    self.CanvasGroup:DOFade(endAlpha, duration)
end

function XUiGridMovieActor:StopAnimtion(animShortName)
    local anim = self:GetAnim(animShortName)
    if anim then
        local timelineAnimation = anim.transform:GetComponent(typeof(CSXUiPlayTimelineAnimation))
        if timelineAnimation then
            timelineAnimation:Stop(false)
        end
    end
end

-- 根据动画名称获取动画
function XUiGridMovieActor:GetAnim(animShortName)
    self:LoadPrefab()
    local animName = AnimNameHead .. animShortName
    local anim = self[animName]
    if anim then
        return anim
    end
    return
end

return XUiGridMovieActor