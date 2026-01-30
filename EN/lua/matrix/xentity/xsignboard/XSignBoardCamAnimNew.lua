---@class XSignBoardCamAnimNew 新的看板镜头动画，镜头预制与卡池一样，支持在播放动画时控制昼夜
local XSignBoardCamAnimNew = XClass(nil, "XSignBoardCamAnimNew")

local DateStartTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeStr")
local DateEndTime = CS.XGame.ClientConfig:GetString("BackgroundChangeTimeEnd")
local UiModeAnim = "UiModeAnim"

function XSignBoardCamAnimNew:Ctor()
    self._UiAnimTimerIds = {}
    self:_Init()
end

function XSignBoardCamAnimNew:Exist()
    return self.AnimPlayer and self.AnimPlayer:Exist()
end

---@param ui XLuaUi
function XSignBoardCamAnimNew:UpdateData(sceneId, signBoardId, ui)
    self.SceneId = sceneId
    self.SignBoardId = signBoardId
    self.UiRoot = ui
    self.IsControlTime = XMVCA.XFavorability:CheckIsControlTime(signBoardId)
    self.RoleModelName = XMVCA.XFavorability:GetAnimPrefabRoleModelName(signBoardId)
    self.IsCloseRoleShadow = XMVCA.XFavorability:IsCloseRoleShadow(signBoardId)
    self:_InitModelRoot(self.UiRoot)
    self:_RecordSceneObjectsState()
end

function XSignBoardCamAnimNew:UpdateAnim(animRootNode, animNode, uiFarCam, uiNearCam)
    self.UiSrcFarCam = uiFarCam
    self.UiSrcNearCam = uiNearCam

    self:_InitNode(animRootNode, animNode)
    self:_InitEffect()
    self:_InitUiAnim()
end

-- 卸载动画
function XSignBoardCamAnimNew:UnloadAnim()
    self:_Init()
end

function XSignBoardCamAnimNew:Play()
    self:_ResetSceneAnim()
    self:_ResetPlayingUiAnim()
    if self:Exist() then
        self:_CheckCloseRoleShadow()
        self:_ReBindAnimRoleTrack()
        --self:_UpdateCameraNode(true)
        self:_ControlTime(true)
        self:_ShowOrHideCharacter(false)
        self.AnimPlayer:Play()          -- 播放镜头动画
        self:_SetAnimPlayableSpeed(1)
        self:_SetEffectAnim(1)          -- 播放镜头动画上的特效
        self:OnScenePlayStart()         -- 播放Ui动画(如果有)
        self.IsPlaying = true
    end
end

function XSignBoardCamAnimNew:Pause()
    if self:Exist() then
        self:_SetAnimPlayableSpeed(0)
        self:_SetEffectAnim(0)          -- 暂停镜头动画上的特效
        if not XTool.IsTableEmpty(self.CurPlayingUiAnim) then
            -- 暂停Ui动画(如果Ui动画还在继续)
            for _, anim in pairs(self.CurPlayingUiAnim) do
                anim:Pause()
            end
        end
    end
end

function XSignBoardCamAnimNew:Resume()
    if self:Exist() then
        if not self:IsFinish() then
            self:_SetAnimPlayableSpeed(1)
        end
        self:_SetEffectAnim(1)          -- 继续播放镜头动画上的特效
        if not XTool.IsTableEmpty(self.CurPlayingUiAnim) then
            -- 继续播放Ui动画(若动画已完成则不继续)
            for _, anim in pairs(self.CurPlayingUiAnim) do
                if anim.time < anim.duration then
                    anim:Play()
                end
            end
        end
    end
end

function XSignBoardCamAnimNew:Close()
    self:_ResetPlayingUiAnim()
    if self:Exist() then
        self:_CheckResumeRoleShadow()
        --self:_UpdateCameraNode(false)
        self:_ControlTime(false)
        self:_ShowOrHideCharacter(true)
        self:_SetSceneObjectsState()
        if self.IsPlaying then
            self:OnScenePlayStop()      -- 播放Ui恢复动画
        end
        self.AnimPlayer.time = self.AnimPlayer.duration
        if self.DarkCanvasGroupList and self.DarkCanvasGroupList.Length > 0 then
            for i = 0, self.DarkCanvasGroupList.Length - 1 do
                self.DarkCanvasGroupList[i].alpha = 0
            end
        end
        self.IsPlaying = false
    end
end

function XSignBoardCamAnimNew:IsFinish()
    if self:Exist() then
        return self.AnimPlayer.time >= self.AnimPlayer.duration
    end
    return true
end

function XSignBoardCamAnimNew:IsAnimPlaying()
    return self.IsPlaying
end

function XSignBoardCamAnimNew:CheckIsSameAnim(sceneId, signBoardId, rootNode)
    return self:Exist() and sceneId == self.SceneId and self.SignBoardId == signBoardId and self.AnimPlayer.transform.parent == rootNode
end

function XSignBoardCamAnimNew:GetNodeTransform()
    if self.AnimPlayer then
        return self.AnimPlayer.transform
    end
end

function XSignBoardCamAnimNew:OnScenePlayStart()
    if not self.UiAnimNodeRoot then
        return
    end
    if XMVCA.XFavorability:CheckIsUseSelfUiAnim(self.SignBoardId, self.UiAnimNodeRoot.name) then
        self:_PlayUiAnim("UiDisable")
    end
    self:_PlayUiAnim(UiModeAnim)
end

function XSignBoardCamAnimNew:OnScenePlayStop()
    if not self.UiAnimNodeRoot then
        return
    end
    if XMVCA.XFavorability:CheckIsUseSelfUiAnim(self.SignBoardId, self.UiAnimNodeRoot.name) then
        XLuaUiManager.SetMask(true)
        self:_PlayUiAnim("UiEnable", function()
            XLuaUiManager.SetMask(false)
        end)
    end
end


-- private
--===============================================================================

function XSignBoardCamAnimNew:_Init()
    ---@type UnityEngine.Playables.PlayableDirector
    self.AnimPlayer = nil       -- 场景动画控制器：Playable Director
    self.IsPlaying = false      -- 播发状态
    ---@type XUiPanelRoleModel
    self._ModelPanel = nil       -- 角色模型根节点
    ---@type UnityEngine.Transform[]
    self.EffectDic = {}         -- 特效动画控制器字典
    ---@type UnityEngine.Transform
    self.UiAnimNodeRoot = nil   -- 预制体里用的Ui动画根节点
    ---@type UnityEngine.Playables.PlayableDirector[]
    self.UiAnim = {}            -- Ui动画字典
    ---@type UnityEngine.Playables.PlayableDirector[]
    self.CurPlayingUiAnim = {} -- 正在播放的Ui动画
    self.DarkCanvasGroupList = nil -- 黑色背景
    ---@type UnityEngine.Transform 
    self.UiFarCamera = nil      -- 加载出来的镜头
    ---@type UnityEngine.Transform
    self.UiNearCamera = nil
    ---@type UnityEngine.Transform
    self.UiSrcFarCam = nil      -- 界面固有镜头
    ---@type UnityEngine.Transform
    self.UiSrcNearCam = nil
    ---@type UnityEngine.Transform
    self.ToChargeTimeLine = nil -- 白变黑
    ---@type UnityEngine.Transform
    self.ToFullTimeLine = nil   -- 黑变白
    ---@type UnityEngine.Transform
    self.FullTimeLine = nil     -- 白天场景
    ---@type UnityEngine.Transform
    self.ChargeTimeLine = nil   -- 黑夜场景
    ---@type UnityEngine.Playables.PlayableDirector
    self.AnimEnableLong = nil   -- 控制昼夜变化
    ---@type UnityEngine.Transform
    self.SceneObjects = nil    -- 场景显示相关
    ---@type UnityEngine.Transform
    self.CameraRoleModel = nil   -- 镜头角色节点
    ---@type UnityEngine.Transform
    self.SceneUiModelParent = nil -- 场景UiModelParent

    self.SceneId = nil
    self.SignBoardId = nil
    ---@type XLuaUi
    self.UiRoot = nil           -- Ui动画控制的Ui对象根节点
    self._TrackBindMap = {}
end

---关闭场景镜头 使用动画自带的镜头
--function XSignBoardCamAnimNew:_UpdateCameraNode(isPlay)
--    self.UiFarCamera.transform.gameObject:SetActiveEx(isPlay)
--    self.UiNearCamera.transform.gameObject:SetActiveEx(isPlay)
--    self.UiSrcFarCam.transform.gameObject:SetActiveEx(not isPlay)
--    self.UiSrcNearCam.transform.gameObject:SetActiveEx(not isPlay)
--end

---关闭场景昼夜变化 在动画动画结束时再启用
function XSignBoardCamAnimNew:_ControlTime(isPlay)
    if not self.IsControlTime then
        return
    end

    if not XTool.UObjIsNil(self.ToChargeTimeLine) then
        self.ToChargeTimeLine.gameObject:SetActiveEx(false)
    end
    if not XTool.UObjIsNil(self.ToFullTimeLine) then
        self.ToFullTimeLine.gameObject:SetActiveEx(false)
    end

    if isPlay then
        if not XTool.UObjIsNil(self.FullTimeLine) then
            self.FullTimeLine.gameObject:SetActiveEx(false)
        end
        if not XTool.UObjIsNil(self.ChargeTimeLine) then
            self.ChargeTimeLine.gameObject:SetActiveEx(false)
        end
        
        if not XTool.UObjIsNil(self.AnimEnableLong) then
            self.AnimEnableLong.gameObject:SetActiveEx(true)
        end

        if not XTool.UObjIsNil(self.AnimEnableLoop) then
            self.AnimEnableLoop.gameObject:StopTimelineAnimation()
        end
    else
        if not XTool.UObjIsNil(self.AnimEnableLong) then
            self.AnimEnableLong.transform:StopTimelineAnimation()
            self.AnimEnableLong.gameObject:SetActiveEx(false)
        end
        XScheduleManager.ScheduleNextFrame(function()
            if not XTool.UObjIsNil(self.AnimEnableLoop) then
                self.AnimEnableLoop.gameObject:SetActiveEx(true)
                self.AnimEnableLoop.gameObject:PlayTimelineAnimation()
            end
            
            if XTool.UObjIsNil(self.FullTimeLine) or XTool.UObjIsNil(self.ChargeTimeLine) then
                return
            end
            local startTime = XTime.ParseToTimestamp(DateStartTime)
            local endTime = XTime.ParseToTimestamp(DateEndTime)
            local nowTime = XTime.ParseToTimestamp(CS.System.DateTime.Now:ToLocalTime():ToString())
            if startTime > nowTime and nowTime > endTime then
                self.FullTimeLine.gameObject:SetActiveEx(true)
                self.ChargeTimeLine.gameObject:SetActiveEx(false)
            else
                self.FullTimeLine.gameObject:SetActiveEx(false)
                self.ChargeTimeLine.gameObject:SetActiveEx(true)
            end
        end)
    end
end

---记录场景节点的状态，用于在打断演出后恢复场景节点状态
function XSignBoardCamAnimNew:_RecordSceneObjectsState()
    ---@type table<UnityEngine.Transform,boolean>
    self._SceneObjectsStateDict = {}
    if XTool.UObjIsNil(self.SceneObjects) then
        return
    end
    for i = 0, self.SceneObjects.childCount - 1, 1 do
        local sceneObj = self.SceneObjects:GetChild(i)
        self._SceneObjectsStateDict[sceneObj] = sceneObj.gameObject.activeSelf
    end
end

function XSignBoardCamAnimNew:_SetSceneObjectsState()
    for sceneObj, isActive in pairs(self._SceneObjectsStateDict) do
        sceneObj.gameObject:SetActiveEx(isActive)
    end
end

---隐藏角色 动画里自己带了个角色
function XSignBoardCamAnimNew:_ShowOrHideCharacter(isShow)
    if not self._ModelPanel then
        return
    end
    if string.IsNilOrEmpty(self.RoleModelName) then
        -- 镜头没有自带角色 无需隐藏场景中的角色
        return
    end
    self._ModelPanel:GetTransform().gameObject:SetActiveEx(isShow)
end

--region ModelRoot
---@param ui XLuaUi
function XSignBoardCamAnimNew:_InitModelRoot(ui)
    if not ui.GetRoleModel then
        return
    end
    self._ModelPanel = ui:GetRoleModel()

    local sceneModel = self._ModelPanel.Transform.root
    self.SceneObjects = sceneModel:Find("GroupBase/Sceneobjects")

    if self.IsControlTime then
        self.ToChargeTimeLine = sceneModel:Find("Animations/ToChargeTimeLine")
        self.ToFullTimeLine = sceneModel:Find("Animations/ToFullTimeLine")
        self.FullTimeLine = sceneModel:Find("Animations/FullTimeLine")
        self.ChargeTimeLine = sceneModel:Find("Animations/ChargeTimeLine")
        self.AnimEnableLong = sceneModel:Find("Animations/AnimEnableLong"):GetComponent("PlayableDirector")
        local animLoop = sceneModel:Find("Animations/AnimEnableLoop")
        if animLoop then
            self.AnimEnableLoop = animLoop:GetComponent("PlayableDirector")
        end
    end
end
--endregion

--region SceneAnim
function XSignBoardCamAnimNew:_InitNode(animRootNode, animNode)
    self.AnimPlayer = animNode.gameObject:GetComponent("PlayableDirector")
    self.DarkCanvasGroupList = animNode.transform:GetComponentsInChildren(typeof(CS.UnityEngine.CanvasGroup), true)
    self:_ResetSceneAnim()

    self.UiFarCamera = self.AnimPlayer.transform:Find("UiFarRoot/UiFarCamera")
    self.UiNearCamera = self.AnimPlayer.transform:Find("UiNearRoot/UiNearCamera")
    self.CameraRoleModel = self.AnimPlayer.transform:Find(string.format("UiNearRoot/UiModelParent/%s", self.RoleModelName))
    self.SceneUiModelParent = animRootNode:Find("UiNearRoot/UiModelParent")
end

function XSignBoardCamAnimNew:_SetAnimPlayableSpeed(speed)
    local setSpeed_generic = xlua.get_generic_method(CS.UnityEngine.Playables.PlayableExtensions, 'SetSpeed')
    local setSpeed = setSpeed_generic(CS.UnityEngine.Playables.Playable)
    for i = 0, self.AnimPlayer.playableGraph:GetRootPlayableCount() - 1 do
        setSpeed(self.AnimPlayer.playableGraph:GetRootPlayable(i), speed)
    end

    local graph = self.AnimEnableLong.playableGraph
    if not graph or not graph:IsValid() then
        XLog.Warning("XSignBoardCamAnimNew: playableGraph is invalid, skip SetSpeed")
        return
    end

    if not XTool.UObjIsNil(self.AnimEnableLong) then
        for i = 0, self.AnimEnableLong.playableGraph:GetRootPlayableCount() - 1 do
            setSpeed(self.AnimEnableLong.playableGraph:GetRootPlayable(i), speed)
        end
    end
end

-- 重置动画进度
function XSignBoardCamAnimNew:_ResetSceneAnim()
    if self:Exist() then
        self.AnimPlayer.gameObject:SetActiveEx(true)
        self.AnimPlayer.time = 0
        self.AnimPlayer:Evaluate()
    end
end

---@type UnityEngine.Transform
function XSignBoardCamAnimNew:CheckCamRootIsHaveCam(camRoot)
    if not camRoot then
        return
    end
    ---@type Cinemachine.CinemachineVirtualCamera
    local cam = camRoot:GetComponentInChildren(typeof(CS.Cinemachine.CinemachineVirtualCamera))
    if cam then
        return cam.transform
    end
end
--endregion

--region SceneAnimEffect
function XSignBoardCamAnimNew:_InitEffect()
    self.EffectDic = {}
    local node = self:GetNodeTransform()
    if not XTool.UObjIsNil(node) then
        local list = node:GetComponentsInChildren(typeof(CS.XUiEffectLayer), true)
        for i = 0, list.Length - 1 do
            local tran = list[i].transform
            table.insert(self.EffectDic, tran)
        end
    end
end

function XSignBoardCamAnimNew:_SetEffectAnim(speed)
    local animater
    for _, effect in pairs(self.EffectDic) do
        animater = effect.childCount > 0 and effect:GetChild(0):GetComponent("Animator") or nil
        if not XTool.UObjIsNil(animater) then
            animater.speed = speed
        end
    end
end
--endregion

--region UiAnim
function XSignBoardCamAnimNew:_InitUiAnim()
    local uiAnimRoot = self.AnimPlayer.transform:FindTransform("Animation")
    if not self.UiRoot or not uiAnimRoot then
        return
    end
    self.UiAnimNodeRoot = uiAnimRoot:FindTransform(self.UiRoot.Name)
    if not self.UiAnimNodeRoot then
        return
    end
    for i = 0, self.UiAnimNodeRoot.childCount - 1, 1 do
        local anim = self.UiAnimNodeRoot:GetChild(i)
        local playableDirector = anim:GetComponent("PlayableDirector")

        if not playableDirector or not playableDirector.playableAsset then
            goto CONTINUE
        end
        local tracks = playableDirector.playableAsset:GetOutputTracks()

        for j = 0, tracks.Length - 1, 1 do
            if anim.name == UiModeAnim then
                -- 特殊动画 用来控制场景角色
                playableDirector:SetGenericBinding(tracks[j], self.SceneUiModelParent:GetComponent("Animator"))
            else
                playableDirector:SetGenericBinding(tracks[j], self.UiRoot.GameObject:GetComponent("Animator"))
            end
        end
        self.UiAnim[anim.name] = playableDirector
        self.UiAnim[anim.name].gameObject:SetActiveEx(false)
        :: CONTINUE ::
    end
end

function XSignBoardCamAnimNew:_PlayUiAnim(animName, cbFunc)
    if not self.UiAnim[animName] then
        if cbFunc then
            cbFunc()
        end
        return
    end

    local anim = self.UiAnim[animName]
    self.CurPlayingUiAnim[animName] = anim
    anim.gameObject:SetActiveEx(true)
    anim.initialTime = 0
    anim:Evaluate()
    anim:Play()
    -- 部分动画时间很短 可能还没1帧 所以这里需要延迟到下一帧播放
    XScheduleManager.ScheduleNextFrame(function()
        if XTool.UObjIsNil(anim) then
            return
        end
        local playTimer = XScheduleManager.ScheduleOnce(function()
            if cbFunc then
                cbFunc()
            end
        end, math.ceil(anim.duration * 1000))
        self:_AddUiAnimTimer(animName, playTimer)
    end)
end

function XSignBoardCamAnimNew:_AddUiAnimTimer(animName, timerId)
    local oldTimerId = self._UiAnimTimerIds[animName]
    if oldTimerId then
        XScheduleManager.UnSchedule(oldTimerId)
    end
    self._UiAnimTimerIds[animName] = timerId
end

function XSignBoardCamAnimNew:_RemoveUiAnimTimer()
    for _, timerId in pairs(self._UiAnimTimerIds) do
        XScheduleManager.UnSchedule(timerId)
    end
    self._UiAnimTimerIds = {}
end

-- 停止所有动画
function XSignBoardCamAnimNew:_ResetPlayingUiAnim()
    self:_RemoveUiAnimTimer()
    if not self:Exist() then
        return
    end
    if XTool.IsTableEmpty(self.CurPlayingUiAnim) then
        return
    end
    for animName, anim in pairs(self.CurPlayingUiAnim) do
        if animName == UiModeAnim then
            -- 跳到最后一帧
            anim:Stop()
            anim.time = anim.duration
        end
        anim:Evaluate()
        anim.gameObject:SetActiveEx(false)
    end
    self.CurPlayingUiAnim = {}
end

-- 如果有轨道没绑定Animator 则把镜头预制体里面的角色的Animator赋值给它
function XSignBoardCamAnimNew:_ReBindAnimRoleTrack()
    if not self._ModelPanel then
        return
    end
    --重新绑定
    local tracks = self.AnimPlayer.playableAsset:GetOutputTracks()
    for i = 0, tracks.Length - 1, 1 do
        local binding = self.AnimPlayer:GetGenericBinding(tracks[i])
        local trackId = tracks[i]:GetInstanceID()
        local curRoleName = self._ModelPanel.CurRoleName
        -- 绑定模型需要跟着刷新
        if not binding or (self._TrackBindMap[trackId] and self._TrackBindMap[trackId] ~= curRoleName) then
            self._TrackBindMap[trackId] = curRoleName
            self.AnimPlayer:ClearGenericBinding(tracks[i])
            self.AnimPlayer:SetGenericBinding(tracks[i], self._ModelPanel:GetTransform().gameObject:GetComponent("Animator"))
        end
    end
end

function XSignBoardCamAnimNew:_CheckCloseRoleShadow()
    if not self.IsCloseRoleShadow then
        return
    end
    self._ModelPanel:RemoveRoleShadow()
end

function XSignBoardCamAnimNew:_CheckResumeRoleShadow()
    if not self.IsCloseRoleShadow then
        return
    end
    self._ModelPanel:AddRoleShadow()
end
--endregion

--===============================================================================

return XSignBoardCamAnimNew