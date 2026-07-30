local CSXUiPlayTimelineAnimation = CS.XUiPlayTimelineAnimation
local DefaultColor = CS.UnityEngine.Color.white
local FRONT_SCALE_FACTOR = 1.02 -- Front 状态在基准缩放上叠加的放大系数
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
    self:RemoveBlurTimer()
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

        if self.GrayValue ~= nil then
            self:UpdateGrayScale()
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
    self.CustomScale = nil -- 换角色时重置自定义缩放，避免残留到不同角色

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

-- RImgActor控制位置，程序实现的振动动画控制的是PanelActorRoot，美术老师实现的动画是控制self.GameObject
function XUiGridMovieActor:SetImagePos(pos)
    if self.Pos == pos then return end
    self.Pos = pos
    self.RImgActor.transform.anchoredPosition3D = pos
end

-- RImgActor控制位置，程序实现的振动动画控制的是PanelActorRoot，美术老师实现的动画是控制self.GameObject
function XUiGridMovieActor:SetActorRootLocalPosition(pos)
    self.PanelActorRoot.localPosition = pos
end

function XUiGridMovieActor:Reverse(isReverse)
    self.IsReverse = isReverse
end

function XUiGridMovieActor:GetImagePos()
    return self.Pos
end

-- 立绘缩放：CustomScale 是策划设置的基准缩放（持久），实际 localScale = CustomScale × 状态系数
function XUiGridMovieActor:GetImageScale()
    return self.CustomScale or 1
end

function XUiGridMovieActor:SetImageScale(scale)
    self.CustomScale = scale
    if XTool.UObjIsNil(self.RImgActor) then return end
    local factor = self.Status == ShowStatus.Front and FRONT_SCALE_FACTOR or 1
    local s = scale * factor
    self.RImgActor.rectTransform.localScale = CS.UnityEngine.Vector3(s, s, 1)
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
    if self.GrayValue == value and self.GrayTime == time then return end
    self.GrayValue = value
    self.GrayTime = time

    self:UpdateGrayScale()
end

function XUiGridMovieActor:UpdateGrayScale()
    if not self:IsLoaded() then return end

    self.MetearialActor:SetGrayScale(self.GrayValue, self.GrayTime)
    self.MeterialFace:SetGrayScale(self.GrayValue, self.GrayTime)
end

-- 在指定 image 上获取/挂载 XUiBlurController
local function _GetOrAddBlur(image)
    if XTool.UObjIsNil(image) then return nil end
    local go = image.gameObject
    local controller = go:GetComponent(typeof(CS.XUiBlurController))
    if not controller then
        controller = go:AddComponent(typeof(CS.XUiBlurController))
    end
    return controller
end

-- 按 blurType 应用模糊配置（不含关闭分支，供逐帧插值调用；setter 内部会 SetGraphicDirty）
local function _ApplyBlurSettings(controller, blurType, strength, extra)
    if not controller then return end
    controller.enabled = true
    if blurType == 1 then
        controller:SetDirectionalBlur(strength, extra and extra.angle or 0)
    elseif blurType == 2 then
        local fx = (extra and extra.focusX) or 0.5
        local fy = (extra and extra.focusY) or 0.5
        controller:SetRadialBlur(
            strength,
            CS.UnityEngine.Vector2(fx, fy),
            (extra and extra.radius) or 0.2,
            (extra and extra.gradient) or 0.5,
            (extra and extra.noiseScale) or 0.7
        )
    elseif blurType == 3 then
        -- 临时处理, 仅限v4.6 后续由C#侧更新默认值
        controller.gaussian.remapStrengthValue = 1
        controller:SetGaussianBlur(strength)
    end
end

local function _CloseBlur(controller)
    if not controller then return end
    controller.activeBlur = CS.XUiBlurController.BlurType.None
    controller.enabled = false
end

function XUiGridMovieActor:RemoveBlurTimer()
    if self.BlurTimer then
        XScheduleManager.UnSchedule(self.BlurTimer)
        self.BlurTimer = nil
    end
end

-- 设置模糊（同时作用于立绘本体和表情）
-- blurType: 0=关闭, 1=Directional, 2=Radial, 3=Gaussian
-- strength: 0~1
-- duration: 秒，>0 时对 strength 做插值（开启渐入/关闭渐出），<=0 为瞬时
-- extra: 类型相关参数表（angle / focusX/focusY / radius / gradient / noiseScale）
function XUiGridMovieActor:SetBlur(blurType, strength, duration, extra)
    if not self:IsLoaded() then return end

    local actorImg = self.RImgActor
    local faceImg = self.RImgFace
    local ctrlActor = _GetOrAddBlur(actorImg)
    local ctrlFace = _GetOrAddBlur(faceImg)

    self:RemoveBlurTimer()

    local BlurTypeNone = CS.XUiBlurController.BlurType.None
    local isClose = blurType == 0 or strength <= 0

    -- 瞬时
    if not duration or duration <= 0 then
        if isClose then
            _CloseBlur(ctrlActor)
            _CloseBlur(ctrlFace)
        else
            _ApplyBlurSettings(ctrlActor, blurType, strength, extra)
            _ApplyBlurSettings(ctrlFace, blurType, strength, extra)
        end
        return
    end

    -- 以本体 controller 为基准取当前强度
    local baseCtrl = ctrlActor or ctrlFace
    if not baseCtrl then return end

    if isClose then
        -- 当前没有模糊则无需渐出
        if baseCtrl.activeBlur == BlurTypeNone or baseCtrl.strength <= 0 then
            _CloseBlur(ctrlActor)
            _CloseBlur(ctrlFace)
            return
        end
        if ctrlActor then ctrlActor.enabled = true end
        if ctrlFace then ctrlFace.enabled = true end
        local startStrength = baseCtrl.strength
        self.BlurTimer = XUiHelper.Tween(duration, function(t)
            local cur = startStrength * (1 - t)
            if ctrlActor then ctrlActor.strength = cur; actorImg:SetMaterialDirty() end
            if ctrlFace then ctrlFace.strength = cur; faceImg:SetMaterialDirty() end
        end, function()
            _CloseBlur(ctrlActor)
            _CloseBlur(ctrlFace)
            self.BlurTimer = nil
        end)
    else
        -- 之前是关闭状态则从 0 渐入，否则从当前强度过渡
        local startStrength = baseCtrl.activeBlur == BlurTypeNone and 0 or baseCtrl.strength
        self.BlurTimer = XUiHelper.Tween(duration, function(t)
            local cur = startStrength + (strength - startStrength) * t
            _ApplyBlurSettings(ctrlActor, blurType, cur, extra)
            _ApplyBlurSettings(ctrlFace, blurType, cur, extra)
        end, function()
            self.BlurTimer = nil
        end)
    end
end

function XUiGridMovieActor:RevertActorPanel()
    local rImgActor = self.RImgActor
    local rImgFace = self.RImgFace
    if XTool.UObjIsNil(rImgActor) then return end

    local alpha = self.CanvasGroup.alpha
    local color = DefaultColor
    local scaleFactor = 1
    local angle = self.IsReverse and DefaultReverseRotation or DefaultRotation
    local status = self.Status
    if status == ShowStatus.Back then
        color = BackColor
    elseif status == ShowStatus.Front then
        self.Link.transform:SetAsLastSibling()
        scaleFactor = FRONT_SCALE_FACTOR
    elseif status == ShowStatus.Hide then
        alpha = 0
        self.Link.gameObject:SetActiveEx(false)
    elseif status == ShowStatus.Normal then
        alpha = 1
    end

    self.CanvasGroup.alpha = alpha
    rImgActor.color = color
    rImgFace.color = color
    local s = (self.CustomScale or 1) * scaleFactor
    rImgActor.rectTransform.localScale = CS.UnityEngine.Vector3(s, s, 1)
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
    anim:PlayTimelineAnimation(function(success)
        XLuaUiManager.SetMask(false)
        self.IsPlayingEnable = nil
        self:StopAnimtion(AnimNames.Enable)

        if not success then return end

        local tmpAnim = self.DelayAnim
        if tmpAnim then
            tmpAnim.gameObject:SetActiveEx(true)
            tmpAnim:PlayTimelineAnimation(function(success)
                XLuaUiManager.SetMask(false)
                self:StopAnimtion(AnimNames.NormalToFront)
                self:StopAnimtion(AnimNames.NormalToBack)
                if not success then return end
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
        anim:PlayTimelineAnimation(function(success)
            XLuaUiManager.SetMask(false)
            self:StopAnimtion(AnimNames.NormalToBack)
            self:StopAnimtion(AnimNames.FrontToBack)
            if not success then return end
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
        anim:PlayTimelineAnimation(function(success)
            XLuaUiManager.SetMask(false)
            self:StopAnimtion(AnimNames.NormalToFront)
            self:StopAnimtion(AnimNames.BackToFront)
            if not success then return end
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

function XUiGridMovieActor:PlayFadeAnimation(beginAlpha, endAlpha, duration, ease)
    self:LoadPrefab()
    self.CanvasGroup.alpha = beginAlpha
    local tween = self.CanvasGroup:DOFade(endAlpha, duration)
    if ease and tween then
        tween:SetEase(ease)
    end
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