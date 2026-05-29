---@class XUiGridMovieSpineActor
local XUiGridMovieSpineActor = XClass(nil, "XUiGridMovieSpineActor")
local DEFAULT_KOU_SPEED = 1
local ANIM_TIME = 4
local ANIM_TIME2 = 1
local DEFAULT_GRAY_SCALE = 0 -- 默认灰度值

function XUiGridMovieSpineActor:Ctor(uiRoot, obj, actorIndex)
    self.UiRoot = uiRoot
    self.GameObject = obj.gameObject
    self.Transform = obj.transform
    self.ActorIndex = actorIndex
    self.ActorId = nil -- 角色id
    self.AnimIndex = 0 -- 角色动画的下标
    self.TransIndex = 0 -- 转换动画的下标
    self.TalkSpeed = 1 -- 讲话的速度
    self.IsTalking = false -- 是否在讲话状态
    self.GrayValue = 0 -- 灰度值
    XTool.InitUiObject(self)

    self.GameObject.gameObject:SetActiveEx(false)
end

function XUiGridMovieSpineActor:OnDestroy()
    self.UiRoot = nil
end

function XUiGridMovieSpineActor:UpdateSpineActor(actorId, animIndex)
    if self.ActorId == actorId then 
        -- 播放动画
        self:PlayAnim(animIndex)

        -- 更新灰度值
        self:UpdateGrayScale(true)
    else
        self.ActorId = actorId
        self.AnimIndex = animIndex
        self.LastUiAnimation = nil
        self.LastAnimType = nil
        self:LoadSpine()
    end
end

function XUiGridMovieSpineActor:LoadSpine()
    self.SpinePath = XMovieConfigs.GetSpineActorSpinePath(self.ActorId)
    if not string.IsNilOrEmpty(self.SpinePath) then
        self:OnSpineRelease()

        local spine = self.SpineLink:LoadPrefab(self.SpinePath)
        self.SpineUiObject = spine:GetComponent("UiObject")
        self.RoleComponent = self.SpineUiObject:GetObject("Role", false)
        self.BodyComponent = self.SpineUiObject:GetObject("Body", false)
        self.KouComponent = self.SpineUiObject:GetObject("Kou", false)

        -- 播放动画
        self:PlayAnim(self.AnimIndex)

        -- 更新灰度值
        self:UpdateGrayScale(true)
    end
end

function XUiGridMovieSpineActor:OnSpineRelease()
    self:StopRoleAnimationsLoop()
    self:StopBodyAnimationsLoop()
    self.LipSyncAnimator = nil
    self.RoleComponent = nil
    self.BodyComponent = nil
    self.KouComponent = nil
end

function XUiGridMovieSpineActor:SetPos(pos)
    if self.Pos == pos then return end

    self.Pos = pos
    self.SpineLink.anchoredPosition3D = pos
end

function XUiGridMovieSpineActor:GetPos()
    return self.Pos
end

function XUiGridMovieSpineActor:SetShow(isShow)
    self.GameObject.gameObject:SetActiveEx(isShow)
end

function XUiGridMovieSpineActor:IsShow()
    return self.GameObject.gameObject.activeInHierarchy
end

--region 口动画
-- 播放口动画
function XUiGridMovieSpineActor:PlayKouAnim(animName, speed)
    local kouComponent = self.KouComponent
    if not kouComponent or not kouComponent.AnimationState then return end
    
    local curAnimName = kouComponent.AnimationState:ToString()
    if animName and animName ~= curAnimName then
        kouComponent.AnimationState:SetAnimation(0, animName, true)
        kouComponent.timeScale = XTool.IsNumberValidEx(speed) and speed / 1000 or DEFAULT_KOU_SPEED
    end
end

-- 播放讲话动画
function XUiGridMovieSpineActor:PlayKouTalkAnim(speed)
    self.IsTalking = true
    self.TalkSpeed = speed

    local talkAnim = XMovieConfigs.GetSpineActorKouTalkAnim(self.ActorId, self.AnimIndex)
    self:PlayKouAnim(talkAnim, speed)
end

-- 播放待机动画
function XUiGridMovieSpineActor:PlayKouIdleAnim()
    self.IsTalking = false

    local idleAnim = XMovieConfigs.GetSpineActorKouIdleAnim(self.ActorId, self.AnimIndex)
    self:PlayKouAnim(idleAnim)
end

-- 更新当前口的动画
function XUiGridMovieSpineActor:UpdateKouAnim()
    if self.IsTalking then
        self:PlayKouTalkAnim(self.TalkSpeed)
    else
        self:PlayKouIdleAnim()
    end
end

-- 播放口型动画
function XUiGridMovieSpineActor:PlayLipAnim(folderName, cvId)
    if not self.LipSyncAnimator then
        self.LipSyncAnimator = self.SpineUiObject.gameObject:AddComponent(typeof(CS.XLipSyncAnimator))
    end

    local movieId = XDataCenter.MovieManager.GetCurPlayingMovieId()
    self.LipSyncAnimator:PlayLipAnim(folderName, movieId, cvId)
end

-- 停止嘴型动画
function XUiGridMovieSpineActor:StopLipAnim()
    if self.LipSyncAnimator then
        self.LipSyncAnimator:Stop()
    end
end
--endregion

-- region 身体和脸动画
-- 播放spine角色动画
function XUiGridMovieSpineActor:PlayAnim(animIndex, transIndex)
    self.AnimIndex = animIndex
    self.TransIndex = transIndex

    local animName = XMovieConfigs.GetSpineActorRoleAnim(self.ActorId, self.AnimIndex)
    local animName2 = XMovieConfigs.GetSpineActorRoleAnim2(self.ActorId, self.AnimIndex)
    local transAnimName = XTool.IsNumberValidEx(transIndex) and XMovieConfigs.GetSpineActorTransitionAnim(self.ActorId, transIndex) or nil
    self:PlayRoleAnimationsLoop(animName, animName2, transAnimName)
    self:PlayBodyAnimationsLoop(animName, animName2, transAnimName)
    self:UpdateKouAnim()
end

-- 播放Role循环动画
function XUiGridMovieSpineActor:PlayRoleAnimationsLoop(animName, animName2, transAnimName)
    local roleComponent = self.RoleComponent
    if not roleComponent or not roleComponent.gameObject.activeInHierarchy then return end

    self:StopRoleAnimationsLoop()

    -- 过渡动画：播完后进入循环
    if transAnimName then
        roleComponent.AnimationState:SetAnimation(0, transAnimName, false)
        self.RoleTransCompleteCb = function()
            self:PlayRoleAnimationsLoop(animName, animName2)
            roleComponent.AnimationState:Complete('-', self.RoleTransCompleteCb)
        end
        roleComponent.AnimationState:Complete('+', self.RoleTransCompleteCb)
        return
    end

    -- 单动画：直接循环播放
    if not animName2 then
        roleComponent.AnimationState:SetAnimation(0, animName, true)
        return
    end

    -- 双动画循环：animName播ANIM_TIME次后切animName2，播ANIM_TIME2次后切回
    self.PlayRoleAnim = function()
        self.RoleAnimPlayTime = 0
        roleComponent.AnimationState:SetAnimation(0, animName, true)
        roleComponent.AnimationState:Complete('+', self.OnPlayRoleAnimComplete)
    end

    self.OnPlayRoleAnimComplete = function()
        self.RoleAnimPlayTime = self.RoleAnimPlayTime + 1
        if self.RoleAnimPlayTime == ANIM_TIME then
            self:PlayRoleAnim2()
            roleComponent.AnimationState:Complete('-', self.OnPlayRoleAnimComplete)
            self.RoleAnimPlayTime = 0
        end
    end

    self.PlayRoleAnim2 = function()
        self.RoleAnimPlayTime2 = 0
        roleComponent.AnimationState:SetAnimation(0, animName2, true)
        roleComponent.AnimationState:Complete('+', self.OnPlayRoleAnim2Complete)
    end

    self.OnPlayRoleAnim2Complete = function()
        self.RoleAnimPlayTime2 = self.RoleAnimPlayTime2 + 1
        if self.RoleAnimPlayTime2 == ANIM_TIME2 then
            self:PlayRoleAnim()
            roleComponent.AnimationState:Complete('-', self.OnPlayRoleAnim2Complete)
            self.RoleAnimPlayTime2 = 0
        end
    end

    self.PlayRoleAnim()
end

-- 播放Body的循环动画
function XUiGridMovieSpineActor:PlayBodyAnimationsLoop(animName, animName2, transAnimName)
    local bodyComponent = self.BodyComponent
    if not bodyComponent or not bodyComponent.gameObject.activeInHierarchy then return end

    self:StopBodyAnimationsLoop()

    -- 过渡动画：播完后进入循环
    if transAnimName then
        bodyComponent.AnimationState:SetAnimation(0, transAnimName, false)
        self.BodyTransCompleteCb = function()
            self:PlayBodyAnimationsLoop(animName, animName2)
            bodyComponent.AnimationState:Complete('-', self.BodyTransCompleteCb)
        end
        bodyComponent.AnimationState:Complete('+', self.BodyTransCompleteCb)
        return
    end

    -- 单动画：直接循环播放
    if not animName2 then
        bodyComponent.AnimationState:SetAnimation(0, animName, true)
        return
    end

    -- 双动画循环：animName播ANIM_TIME次后切animName2，播ANIM_TIME2次后切回
    self.PlayBodyAnim = function()
        self.BodyAnimPlayTime = 0
        bodyComponent.AnimationState:SetAnimation(0, animName, true)
        bodyComponent.AnimationState:Complete('+', self.OnPlayBodyAnimComplete)
    end

    self.OnPlayBodyAnimComplete = function()
        self.BodyAnimPlayTime = self.BodyAnimPlayTime + 1
        if self.BodyAnimPlayTime == ANIM_TIME then
            self:PlayBodyAnim2()
            bodyComponent.AnimationState:Complete('-', self.OnPlayBodyAnimComplete)
            self.BodyAnimPlayTime = 0
        end
    end

    self.PlayBodyAnim2 = function()
        self.BodyAnimPlayTime2 = 0
        bodyComponent.AnimationState:SetAnimation(0, animName2, true)
        bodyComponent.AnimationState:Complete('+', self.OnPlayBodyAnim2Complete)
    end

    self.OnPlayBodyAnim2Complete = function()
        self.BodyAnimPlayTime2 = self.BodyAnimPlayTime2 + 1
        if self.BodyAnimPlayTime2 == ANIM_TIME2 then
            self:PlayBodyAnim()
            bodyComponent.AnimationState:Complete('-', self.OnPlayBodyAnim2Complete)
            self.BodyAnimPlayTime2 = 0
        end
    end

    self.PlayBodyAnim()
end

-- 停止角色动画的循环播放回调
function XUiGridMovieSpineActor:StopRoleAnimationsLoop()
    if not self.SpineUiObject or not self.RoleComponent then
        return
    end

    if self.RoleAnimPlayTime and self.RoleComponent.gameObject.activeInHierarchy then
        self.RoleComponent.AnimationState:Complete('-', self.OnPlayRoleAnimComplete)
    end
    if self.RoleAnimPlayTime2 and self.RoleComponent.gameObject.activeInHierarchy then
        self.RoleComponent.AnimationState:Complete('-', self.OnPlayRoleAnim2Complete)
    end
end

-- 停止身体动画的循环播放回调
function XUiGridMovieSpineActor:StopBodyAnimationsLoop()
    if not self.SpineUiObject or not self.BodyComponent then
        return
    end

    if self.BodyAnimPlayTime and self.BodyComponent.gameObject.activeInHierarchy then
        self.BodyComponent.AnimationState:Complete('-', self.OnPlayBodyAnimComplete)
    end
    if self.BodyAnimPlayTime2 and self.BodyComponent.gameObject.activeInHierarchy then
        self.BodyComponent.AnimationState:Complete('-', self.OnPlayBodyAnim2Complete)
    end
end
--endregion

--#region UI动画
-- 播放ui动画
-- isOnce为只播一次，再次触发时，则跳过不播
-- isSkipAnim为跳过播放过程，直接到最后一帧
function XUiGridMovieSpineActor:PlayUiAnimation(animName, finishCb, isOnce, isSkipAnim)
    if not self.SpineUiObject or not self:IsShow() then
        return
    end

    if isOnce then
        if self.LastUiAnimation == animName then
            return
        end

        -- 相同亮暗分类的动画跳过（如当前已是亮状态，再播变亮动画则跳过）
        local curAnimType = XMVCA.XMovie.EnumConst.SPINE_ACTOR_ANIM_TYPE_MAP[animName]
        if curAnimType and self.LastAnimType == curAnimType then
            return
        end
    end

    self.LastUiAnimation = animName
    local animType = XMVCA.XMovie.EnumConst.SPINE_ACTOR_ANIM_TYPE_MAP[animName]
    if animType then
        self.LastAnimType = animType
    end
    local anim = self.SpineUiObject:GetObject(animName)

    -- 跳到动画最后一帧
    if isSkipAnim then
        anim.gameObject:PlayTimelineAnimation()
        local timelineAnimation = anim.transform:GetComponent(typeof(CS.XUiPlayTimelineAnimation))
        timelineAnimation:Finish()
        if finishCb then
            finishCb()
        end
        return
    end

    if anim then
        anim.gameObject:PlayTimelineAnimation(finishCb)
    elseif finishCb then
        finishCb()
    end
end

-- 播放spine变亮动画，skipAnim为true时，直接设置最终的颜色，不播动画
function XUiGridMovieSpineActor:PlayAnimFront(skipAnim)
    self:PlayUiAnimation(XMovieConfigs.SpineActorAnim.PanelActorDarkDisable, nil, true, skipAnim)
end

-- 播放spine变暗动画，skipAnim为true时，直接设置最终的颜色，不播动画
function XUiGridMovieSpineActor:PlayAnimBack(skipAnim)
    self:PlayUiAnimation(XMovieConfigs.SpineActorAnim.PanelActorDarkNor, nil, true, skipAnim)
end
--#endregion

--#region 灰度相关
-- 设置灰度值
function XUiGridMovieSpineActor:SetGrayScale(value, time)
    if self.GrayValue == value then return end
    self.GrayValue = value
    self.GrayTime = time

    self:UpdateGrayScale()
end

-- 更新灰度值
-- ignoreDefault忽略默认灰度值
function XUiGridMovieSpineActor:UpdateGrayScale(ignoreDefault)
    if not self:IsShow() then return end
    if not self.SpineUiObject then return end
    if ignoreDefault and self.GrayValue == DEFAULT_GRAY_SCALE then return end

    for _, partName in pairs(XMVCA.XMovie.EnumConst.SPINE_PART_NAME) do
        local part = self.SpineUiObject:GetObject(partName, false)
        if part then 
            local matController = part.gameObject:GetComponent("XUiMaterialController")
            if not matController then 
                matController = part.gameObject:AddComponent(typeof(CS.XUiMaterialController))
            end
            matController:SetGrayScale(self.GrayValue, self.GrayTime)
        end
    end
end
--#endregion

return XUiGridMovieSpineActor