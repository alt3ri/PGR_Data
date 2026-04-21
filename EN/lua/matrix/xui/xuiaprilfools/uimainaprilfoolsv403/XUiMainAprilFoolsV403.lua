local XUiMainLeftTop = require("XUi/XUiMain/XUiMainLeftTop")
local XUiMainAprilFoolsOther = require("XUi/XUiAprilFools/UiMainAprilFoolsV403/XUiMainAprilFoolsOther")
local XUiMainBoardEffect = require("XUi/XUiMain/XUiMainBoardEffect")

--- 愚人节假看板界面
---@class XUiMainAprilFoolsV403: XLuaUi
---@field _Control XAprilFoolDayControl
local XUiMainAprilFoolsV403 = XLuaUiManager.Register(XLuaUi, 'UiMainAprilFoolsV403')

local CameraIndex = {
    Main = 1,
    MainEnter = 2,
    MainChatEnter = 3,
    MainRightMidSecondEnter = 4,
    MainLeftCalendarEnter = 5,
}

local RecordBtnIndex = {
    Expel = 1,
    Quit = 2,
}

function XUiMainAprilFoolsV403:OnAwake()
    XDataCenter.FunctionEventManager.SetMainEventIsEnd(false)
    -- 设置修复-设置关掉空花高帧（开启游戏调用一次）
    XDataCenter.XQualityManager.CloseBigWorldHighFrameSettings()
    
    self._IsClose = false
    self._IsPlayingEnterAnima = false
end

function XUiMainAprilFoolsV403:OnStart(...)
    self:InitPanel()
    self.PanelQuit.gameObject:SetActiveEx(false)
    self:SetBtnExpelActive(true)
    self:SetBtnExpelActiveEnable(true)
    
    self.BtnQuit:AddEventListener(function()
        self:StopActivityCheckTimer()
        XMVCA.XAprilFoolDay:RequestFoolsDayClearOutComplete()
        XLuaUiManager.RunMain()
        self._Control:RecordAprilFoolDayMainUiBtnClick(RecordBtnIndex.Quit)
    end)
    self.BtnExpel:AddEventListener(handler(self, self.OnBtnExpelClick))
    
    -- 播放入场动画
    self:PlayAnimationWithMask('AnimEnter', function() 
        self:PlayAnimationWithMask('AnimEnter2')
    end)
    
    self:StartActivityCheckTimer()
end

function XUiMainAprilFoolsV403:OnEnable()
    XMVCA.XMainLine2:ClearCacheDatasUiFubenMainLineChapter()
    XRedPointManager.AutoReleaseRedPointEvent()
    XLoginManager.ResetHearbeatInterval()

    self:InitUiScene()


    self.MainBoardEffect:OnEnable()
    self:SetScreenAdaptorCache()

    XUiHelper.SetSceneAnimHandler(self)
    XMVCA.XSwitchableScene:CheckShowGyroTip()
    
    XMVCA.XAprilFoolDay:OnUiMainEnableEventCheckTips()
end

function XUiMainAprilFoolsV403:OnDisable()
    self.MainBoardEffect:OnDisable()
    self:ClearSceneReference()
    
    -- 防止ui动画被打断没人开启射线检测
    if not XTool.UObjIsNil(self.SafeAreaContentPane) then
        local cvgp = self.SafeAreaContentPane.transform:GetComponent("CanvasGroup")
        if not XTool.UObjIsNil(cvgp) then
            cvgp.blocksRaycasts = true
        end
    end

    self.SwitchableScene:Stop()
    
    XDataCenter.FunctionEventManager.SetMainEventIsEnd(false)
    
    XMVCA.XAprilFoolDay:OnUiMainDisableEventCloseTip()
end

function XUiMainAprilFoolsV403:OnDestroy()
    self.Other:OnDestroy()
    self.LeftTop:OnDestroy()
    self.SwitchableScene:OnDestory()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_RIGHTMIDTYPE_CHANGE, self.ForceChangeUiMainRightMidType, self)
    self._IsClose = true
    
    self:StopActivityCheckTimer()
end


function XUiMainAprilFoolsV403:InitPanel()
    ---@type XUiMainLeftTop
    self.LeftTop = XUiMainLeftTop.New(self.PanelLeftTop, self, self)            --左上角组件（玩家信息……）
    ---@type XUiMainAprilFoolsOther
    self.Other = XUiMainAprilFoolsOther.New(self.PanelOther.transform, self, self)              --其他组件（角色触摸、截图……）
    ---@type XUiMainBoardEffect
    self.MainBoardEffect = XUiMainBoardEffect.New(self)
    ---@type XUiPanelSwitchableSceneAnim
    self.SwitchableScene = require("XUi/XUiSwitchableScene/Panel/XUiPanelSwitchableSceneAnim").New()
end

function XUiMainAprilFoolsV403:SetScreenAdaptorCache()
    if XDataCenter.SetManager.IsAdaptorScreen() and not XTool.UObjIsNil(self.SafeAreaContentPane) then
        self.SafeAreaContentPane:UpdateSpecialScreenOff()
    end
end

--region 场景加载相关

function XUiMainAprilFoolsV403:InitUiScene()
    local curSceneId = self._Control:GetCurFoolsDaySceneUrl()

    -- 保底至少有场景
    if not XTool.IsNumberValidEx(curSceneId) then
        curSceneId = XDataCenter.PhotographManager.GetCurSceneId()
    end

    local curSceneTemplate = XDataCenter.PhotographManager.GetSceneTemplateById(curSceneId)
    local curSceneUrl, _ = XSceneModelConfigs.GetSceneAndModelPathById(curSceneTemplate.SceneModelId)
    local modelUrl = self:GetDefaultUiModelUrl()
    self.CurSceneId = curSceneId

    XDataCenter.SetManager.SetSceneUIType()
    self:LoadUiScene(curSceneUrl, modelUrl, function() self:OnUiSceneLoaded(curSceneTemplate.ParticleGroupName) end, false)
end

function XUiMainAprilFoolsV403:OnUiSceneLoaded(particleGroupName)
    self:InitSceneRoot(particleGroupName)

    self.Other:SafeCreateSignBoard()
    if XLoginManager.IsFirstOpenMainUi() then
        self:UpdateCamera(CameraIndex.MainEnter)
    else
        local camera = CameraIndex.Main

        self:UpdateCamera(camera)
    end
    self.SwitchableScene:Play(self.CurSceneId, self.UiSceneInfo.Transform)
end

--初始化摄像机
function XUiMainAprilFoolsV403:InitSceneRoot(particleGroupName)
    self.CameraFar = {
        [CameraIndex.Main] = self:FindVirtualCamera("CamFarMain"),
        [CameraIndex.MainEnter] = self:FindVirtualCamera("CamFarMainEnter"),
        [CameraIndex.MainChatEnter] = self:FindVirtualCamera("CamFarMainChatEnter"),
        [CameraIndex.MainRightMidSecondEnter] = self:FindVirtualCamera("CamFarMainRightMidSecondEnter"),
        [CameraIndex.MainLeftCalendarEnter] = self:FindVirtualCamera("CamFarTolist"),
    }
    self.CameraNear = {
        [CameraIndex.Main] = self:FindVirtualCamera("CamNearMain"),
        [CameraIndex.MainEnter] = self:FindVirtualCamera("CamNearMainEnter"),
        [CameraIndex.MainChatEnter] = self:FindVirtualCamera("CamNearMainChatEnter"),
        [CameraIndex.MainRightMidSecondEnter] = self:FindVirtualCamera("CamNearMainRightMidSecondEnter"),
        [CameraIndex.MainLeftCalendarEnter] = self:FindVirtualCamera("CamNearTolist"),
    }

    --主页面电量特效相关
    local sceneRoot = self.UiSceneInfo.Transform
    local animationRoot = self.UiSceneInfo.Transform:Find("Animations")
    if XTool.UObjIsNil(animationRoot) then return end

    if particleGroupName and particleGroupName ~= "" then
        self.ChargeAnimator = sceneRoot:FindTransform(particleGroupName):GetComponent("Animator")
    else
        self.ChargeAnimator = nil
    end

end

function XUiMainAprilFoolsV403:UpdateCamera(camera)
    if not self.CameraFar or not self.CameraNear then
        return
    end
    for _, cameraIndex in pairs(CameraIndex) do
        local nearCamera = self.CameraNear[cameraIndex]
        if not XTool.UObjIsNil(nearCamera) then
            nearCamera.gameObject:SetActive(cameraIndex == camera)
        end
        local farCamera = self.CameraFar[cameraIndex]
        if not XTool.UObjIsNil(farCamera) then
            farCamera.gameObject:SetActive(cameraIndex == camera)
        end
    end
end

--endregion

---@return XUiPanelRoleModel
function XUiMainAprilFoolsV403:GetRoleModel()
    return self.Other:GetRoleModel()
end

--- 清除场景引用，避免场景加载前使用
---@return void
--------------------------
function XUiMainAprilFoolsV403:ClearSceneReference()
    self.CameraFar = nil
    self.CameraNear = nil
    self.ChargeAnimator = nil
end


--region BoardEffect

-- 获取角色模型Transform
---@return UnityEngine.Transform
function XUiMainAprilFoolsV403:GetRoleModelTransform()
    return self.Other:GetRoleModelTransform()
end

-- 刷新角色之前
function XUiMainAprilFoolsV403:OnRefreshRoleBefore()
    self:HideBoardEffect()
end

-- 隐藏特效
function XUiMainAprilFoolsV403:HideBoardEffect()
    if self.MainBoardEffect then
        self.MainBoardEffect:HideEffect()
    end
end

--endregion

function XUiMainAprilFoolsV403:SetBtnExpelActive(active)
    self.BtnExpel.gameObject:SetActiveEx(active)
end

function XUiMainAprilFoolsV403:SetBtnExpelActiveEnable(enable)
    self.BtnExpel:SetButtonState(enable and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self._BtnExpelEnable = enable
end

function XUiMainAprilFoolsV403:SetPanelQuitActive(active)
    self.PanelQuit.gameObject:SetActiveEx(active)
end

function XUiMainAprilFoolsV403:OnBtnExpelClick()
    if not self._BtnExpelEnable then
        return
    end
    -- 暂停当前动画
    self.Other:Stop()
    
    -- 踢飞计数+1
    local newTimes = self._Control:AddPlayerTickOutTimes()
    
    self.Other:OnTickOutShow(newTimes)
    
    self:SetBtnExpelActiveEnable(false)
    self:SetPanelQuitActive(true)
    
    -- 记录埋点
    self._Control:RecordAprilFoolDayMainUiBtnClick(RecordBtnIndex.Expel)
end

--region 给非XUiNode的子节点访问

function XUiMainAprilFoolsV403:GetDisplayRoleId()
    return self._Control:GetCurFoolsDayRoleId()
end

function XUiMainAprilFoolsV403:UpdateRoleModel(...)
    return self._Control:UpdateRoleModel(...)
end

--endregion

--region 假界面定时器检查活动

function XUiMainAprilFoolsV403:StopActivityCheckTimer()
    if self._ActivityCheckTimerId then
        XScheduleManager.UnSchedule(self._ActivityCheckTimerId)
        self._ActivityCheckTimerId = nil
    end
end

function XUiMainAprilFoolsV403:StartActivityCheckTimer()
    self:StopActivityCheckTimer()
    
    self:UpdateActivityCheckTimer()
    self._ActivityCheckTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateActivityCheckTimer), XScheduleManager.SECOND)
end


function XUiMainAprilFoolsV403:UpdateActivityCheckTimer()
    if not XMVCA.XAprilFoolDay:CheckCanEnterFailureMain() then
        self:StopActivityCheckTimer()
        XLuaUiManager.RunMain()
    end
end
--endregion

return XUiMainAprilFoolsV403