---@class XUiPanelGachaBiankaScene : XUiNode
---@field Parent XUiGachaBiankaMain|XUiGachaBiankaStageLine
local XUiPanelGachaBiankaScene = XClass(XUiNode, "XUiPanelGachaBiankaScene")

function XUiPanelGachaBiankaScene:OnStart()
    self:Init3DSceneInfo()
end

function XUiPanelGachaBiankaScene:OnDisable()
    if self._CamLongAnimTimer then
        XScheduleManager.UnSchedule(self._CamLongAnimTimer)
        self._CamLongAnimTimer = nil
    end
    if self._SceneLongAnimTimer then
        XScheduleManager.UnSchedule(self._SceneLongAnimTimer)
        self._SceneLongAnimTimer = nil
    end
end

-- 战斗回来后场景会被销毁，需要判空再加载1次
function XUiPanelGachaBiankaScene:Init3DSceneInfo()
    if self.Panel3D and not XTool.UObjIsNil(self.Panel3D.GameObject) then
        return
    end
    
    self.Panel3D = {}
    XTool.InitUiObjectByUi(self.Panel3D, self.Parent.UiSceneInfo.Transform) -- 将场景的内容和镜头的内容加到1个table里
    XTool.InitUiObjectByUi(self.Panel3D, self.Parent.UiModelGo.transform) -- 3d镜头的ui

    --- 阴影要放在武器模型加载完之后
    if not XTool.UObjIsNil(self.Panel3D.ModelBianka) then
        CS.XShadowHelper.AddShadow(self.Panel3D.ModelBianka.gameObject, true)
    end

    --- 卡池场景为白昼 不受电量和实际时间的影响
    local animationRoot = self.Parent.UiSceneInfo.Transform:Find("Animations")
    if not XTool.UObjIsNil(animationRoot) then
        local fullTimeLine = animationRoot:Find("FullTimeLine")
        if fullTimeLine then
            fullTimeLine.gameObject:SetActiveEx(true)
        end
    end
    self._ChoukaAudioDisable = self.Parent.UiModelGo.transform:FindTransform("ChoukaAudioDisable")
end

--region 动画

function XUiPanelGachaBiankaScene:PlayStart1()
    self.Panel3D.AnimStart1:PlayTimelineAnimation()
end

function XUiPanelGachaBiankaScene:PlayEnableStory()
    self.Panel3D.AnimDisableStory.gameObject:SetActiveEx(false)
    self.Panel3D.AnimEnableStory.gameObject:SetActiveEx(true)
    self.Panel3D.AnimEnableStory:PlayTimelineAnimation()
end

---[镜头]AnimEnableLong和[场景]AnimEnableLong一起播放，场景[AnimEnableLong]播放完后播场景的[AnimEnableGyro]
function XUiPanelGachaBiankaScene:PlayEnableLong(camAnimCb, sceneAnimCb)
    local timeEnableLong = self.Parent.UiSceneInfo.Transform:Find("Animations/AnimEnableLong")
    local animEnableLong = self.Panel3D.AnimEnableLong:GetComponent("PlayableDirector")
    self.Panel3D.AnimStart1:StopTimelineAnimation()
    self:_PlayAnimNextFrame(function()
        self.Panel3D.AnimEnableLong.gameObject:SetActiveEx(true)
        if not XTool.UObjIsNil(timeEnableLong) then
            timeEnableLong.gameObject:SetActiveEx(true)
        end
        self:_PlayTimeLineAnim(self.Panel3D.AnimEnableLong)
    end)
    --镜头长入场回调
    self._CamLongAnimTimer = XScheduleManager.ScheduleOnce(function()
        self.Panel3D.AnimEnableLong.gameObject:SetActiveEx(false)
        camAnimCb()
    end, math.ceil(animEnableLong.duration * XScheduleManager.SECOND))
    --场景长入场回调
    if XTool.UObjIsNil(timeEnableLong) then
        sceneAnimCb()
    else
        local pb = timeEnableLong:GetComponent("PlayableDirector")
        self._SceneLongAnimTimer = XScheduleManager.ScheduleOnce(function()
            timeEnableLong.gameObject:SetActiveEx(false)
            sceneAnimCb()
        end, math.ceil(pb.duration * XScheduleManager.SECOND))
    end
end

function XUiPanelGachaBiankaScene:PlayEnableShort()
    self.Panel3D.AnimEnableShort:PlayTimelineAnimation(function()
        self:SetXPostFaicalControllerActive(true)
    end)
end

function XUiPanelGachaBiankaScene:PlayEnterStageLine()
    self:SetXPostFaicalControllerActive(false)
    self.Panel3D.UiFarCamStory.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCamStory.gameObject:SetActiveEx(false)
end

function XUiPanelGachaBiankaScene:PlayExitStageLine()
    self:SetXPostFaicalControllerActive(true)
    self.Panel3D.AnimEnableStory.gameObject:SetActiveEx(false)
    self.Panel3D.AnimDisableStory.gameObject:SetActiveEx(true)
    self.Panel3D.AnimDisableStory:PlayTimelineAnimation()
    self.Panel3D.UiFarCamStory.gameObject:SetActiveEx(false)
    self.Panel3D.UiNearCamStory.gameObject:SetActiveEx(false)
end

function XUiPanelGachaBiankaScene:PlayChoukaAudioDisable(cb)
    self._ChoukaAudioDisable:PlayTimelineAnimation(cb)
end

function XUiPanelGachaBiankaScene:GetGachaAnime(quality)
    if quality == 4 then
        return self.Panel3D.ChoukaVioletEnable.transform
    elseif quality == 5 then
        return self.Panel3D.ChoukaYellowEnable.transform
    elseif quality == 6 then
        return self.Panel3D.ChoukaRedEnable.transform
    end
    return nil
end

--endregion

---开启/关闭角色的视线跟随
function XUiPanelGachaBiankaScene:SetXPostFaicalControllerActive(flag)
    if XTool.UObjIsNil(self.Panel3D.ModelBianka) then
        return
    end
    local targetComponent = self.Panel3D.ModelBianka:GetComponent(typeof(CS.XPostFaicalController))
    if not targetComponent then
        return
    end
    if flag and not targetComponent.enabled then
        targetComponent.enabled = true
    end
    targetComponent:ActiveInput(flag)
end

---配合_PlayTimeLineAnim
---延迟一帧是因为_PlayTimeLineAnim自己控制了timeline播放
---ui动画还是走XUiPlayTimelineAnimation会延迟两帧
---所以延迟一帧播放尽量对齐场景动画和Ui动画
function XUiPanelGachaBiankaScene:_PlayAnimNextFrame(playAnimFunc)
    if not playAnimFunc then
        return
    end
    local timerId = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        playAnimFunc()
    end, 0)
    self.Parent:_AddTimerId(timerId)
end

---PlayAnimationWithMask该接口最终使用的是C# XUiPlayTimelineAnimation
---XUiPlayTimelineAnimation的Play接口会因为WaitFrame等两帧
---由于角色动作切换是用【timeLine帧事件】实现的
---所以如果帧事件处于第一帧会导致场景演出对齐上有2帧时间误差,因此不用之,自己另写
---@param tran UnityEngine.Transform
---@param directorWrapMode number UnityEngine.Playables.DirectorWrapMode
function XUiPanelGachaBiankaScene:_PlayTimeLineAnim(tran, time, directorWrapMode, finishCallBack)
    if not tran then
        return
    end
    ---@type UnityEngine.Playables.PlayableDirector
    local anim = tran:GetComponent("PlayableDirector")
    anim.initialTime = time or 0
    if directorWrapMode then
        anim.extrapolationMode = directorWrapMode
    end
    anim:Evaluate()
    anim:Play()
    if finishCallBack then
        local playTimer = XScheduleManager.ScheduleOnce(finishCallBack, math.ceil(anim.duration * 1000))
        self.Parent:_AddTimerId(playTimer)
    end
end

return XUiPanelGachaBiankaScene
