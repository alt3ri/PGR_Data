local tableInsert = table.insert
local XUiGridMovieActor = require("XUi/XUiMovie/XUiGridMovieActor")
local XUiGridMovieSpineActor = require("XUi/XUiMovie/XUiGridMovieSpineActor")
local XUiPanelMovie3D = require("XUi/XUiMovie/XUiPanelMovie3D")
---@field UiPanelText XUiPanelText
---@field UiMovieBg XUiMovieBg
---@field _Control XMovieControl
---@field Actors XUiGridMovieActor[]
---@field SpineActors XUiGridMovieSpineActor[]
---@class XUiMovie
local XUiMovie = XLuaUiManager.Register(XLuaUi, "UiMovie")

local InsertDirection = {
    Left = 1,
    Right = 2
}

local InsertPanelEnableAnimationDic = {
    [InsertDirection.Left] = "PanelinsertLeftEnable",
    [InsertDirection.Right] = "PanelinsertRightEnable"
}

local InsertPanelDisableAnimationDic = {
    [InsertDirection.Left] = "PanelinsertLeftDisable",
    [InsertDirection.Right] = "PanelinsertRightDisable"
}

function XUiMovie:OnAwake()
    self.UiMovieRImgBg.gameObject:SetActiveEx(false)
    self.UiMoviePanelActor.gameObject:SetActiveEx(false)
    self.BtnAutoing.gameObject:SetActiveEx(false)
    self.RImgBg1.gameObject:SetActiveEx(false)
    self.UiMovieBg = require("XUi/XUiMovie/XUiMovieBg").New(self)
    self:AddListener()
end

function XUiMovie:OnStart(hideSkipBtn)
    self:InitView()
    self:OnInitScene()
    self.BtnSkip.gameObject:SetActiveEx(not hideSkipBtn)
    local isShowBookmark = XDataCenter.MovieManager.IsShowBookmark()
    self.BtnBookmark.gameObject:SetActiveEx(isShowBookmark)
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_UI_OPEN, self)
end

function XUiMovie:OnEnable()
    self.LastOperationType = CS.XInputManager.CurInputMapID
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)

    local isExitPassedAction = XDataCenter.MovieManager.IsExitPassedActions()
    if isExitPassedAction then
        XDataCenter.MovieManager.StartPassedActions()
        local isStartAfterLoading = XDataCenter.MovieManager.IsStartActionAfterLoading()
        if not isStartAfterLoading then
            XDataCenter.MovieManager.StartActions()
        end

        self:RemoveLoadingTimer()
        local LOADING_TIME = 1000
        self.PanelLoading.gameObject:SetActiveEx(true)
        self.LoadingTimer = XScheduleManager.ScheduleOnce(function()
            self.LoadingTimer = nil
            self.PanelLoading.gameObject:SetActiveEx(false)
            if isStartAfterLoading then
                XDataCenter.MovieManager.StartActions()
            end
        end, LOADING_TIME)
    else
        XDataCenter.MovieManager.StartActions()
    end
end

function XUiMovie:RemoveLoadingTimer()
    if self.LoadingTimer then
        XScheduleManager.UnSchedule(self.LoadingTimer)
        self.LoadingTimer = nil
    end
end

function XUiMovie:SelectPanelShowing()
    return self.PanelSelectRight.gameObject.activeSelf or self.PanelSelectLeft.gameObject.activeSelf
end

function XUiMovie:OnDisable()
    CS.XInputManager.SetCurInputMap(self.LastOperationType)
end

function XUiMovie:OnDestroy()
    self:RemoveLoadingTimer()
    XLuaAudioManager.StopAudioByType(XLuaAudioManager.SoundType.SFX | XLuaAudioManager.SoundType.Voice | XLuaAudioManager.SoundType.Music)
    self.UiMovieBg:OnDestroy()
    XLuaAudioManager.SetMusicSourceFirstBlockIndex(0)
    self:ClearAutoTimer()

    for _, actor in pairs(self.Actors) do
        actor:OnDestroy()
    end
    self.Actors = nil

    for _, actor in pairs(self.SpineActors) do
        actor:OnDestroy()
    end
    self.SpineActors = nil

    if not XTool.IsTableEmpty(self.ActorDic) then
        for _, actor in pairs(self.ActorDic) do
            if not XTool.UObjIsNil(actor) then
                actor:Destroy()
            end
        end
    end
    self.ActorDic = {}

    if not XTool.IsTableEmpty(self.CameraDic) then
        for _, camera in pairs(self.CameraDic) do
            if not XTool.UObjIsNil(camera) then
                CS.UnityEngine.GameObject.Destroy(camera.gameObject)
            end
        end
    end
    self.CameraDic = {}

    if not XTool.IsTableEmpty(self.TimelineDic) then
        for _, timeline in pairs(self.TimelineDic) do
            if not XTool.UObjIsNil(timeline) then
                CS.UnityEngine.GameObject.Destroy(timeline.gameObject)
            end
        end
    end
    self.TimelineDic = {}

    self:RemoveBtnNextCallback()
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_UI_DESTROY)
    XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_UI_CLOSED)
end

function XUiMovie:InitView()
    self.FullScreenDialogUsingIndex = 1
    self.FullScreenDialogGrids = {}
    self.AnimPrefabDic = {}
    self.EffectGoDic = {}
    self.PanelEffects = {
        self.EffectBg,
        self.EffectCha,
        self.EffectFull,
    }
    self.Actors = {}
    for actorIndex = 1, XMovieConfigs.MAX_ACTOR_NUM do
        local panelActor = self["PanelActor" .. actorIndex]
        if panelActor then
            tableInsert(self.Actors, XUiGridMovieActor.New(self, panelActor, actorIndex))
        end
    end
    self.SpineActors = {}
    for actorIndex = 1, XMovieConfigs.MAX_SPINE_ACTOR_NUM do
        tableInsert(self.SpineActors, XUiGridMovieSpineActor.New(self, self["PanelSpineActor" .. actorIndex], actorIndex))
    end
    
    self.PanelRole.gameObject:SetActiveEx(true)
    self.PanelRole2.gameObject:SetActiveEx(true)
    self.PanelDialogRole.gameObject:SetActiveEx(true)
    self.PanelSpineRole.gameObject:SetActiveEx(true)
    self.PanelDialog.gameObject:SetActiveEx(false)
    self.PanelFullScreenDialog.gameObject:SetActiveEx(false)
    self.PanelSelectLeft.gameObject:SetActiveEx(false)
    self.PanelSelectRight.gameObject:SetActiveEx(false)
    self.PanelTheme.gameObject:SetActiveEx(false)
    self.PanelSummer.gameObject:SetActiveEx(false)
    self.PanelMask.gameObject:SetActiveEx(false)
    self.BtnScreenSpeed.gameObject:SetActiveEx(false)
    self.BtnScreenSpeed.ExitCheck = false
    self.PanelStaff.gameObject:SetActiveEx(false)
    self.PanelCenterTip.gameObject:SetActiveEx(false)
    self.Panel3D = XUiPanelMovie3D.New(self.Panel3d, self)
    self.PanelText.gameObject:SetActiveEx(false)
    self:InitSpeedGroup()
end

function XUiMovie:OnInitScene()
    self.CameraDic = {}
    self.ActorDic = {}
    self.TimelineDic = {}

    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    self.CameraRoot = root:FindTransform("CameraRoot")
    self.ActorRoot = root:FindTransform("ActorRoot")
    ---@type Cinemachine.CinemachineBrain
    self.CineMachineBrain = root:FindTransform("UiNearCamera"):GetComponent(typeof(CS.Cinemachine.CinemachineBrain))
    self.DefaultBlendDefine = self.CineMachineBrain.m_DefaultBlend
    self.CutBlendDefine = CS.Cinemachine.CinemachineBlendDefinition()
    
    self.TimelineRoot = root:FindTransform("TimelineRoot")
    self.MixRoot = root.parent.parent:FindTransform("MixRoot")
    self.MixActorRoot = self.MixRoot:FindTransform("MixActorRoot")
    ---@type UnityEngine.UI.RawImage
    self.MixBg = self.MixRoot:FindTransform("Bg"):GetComponent(typeof(CS.UnityEngine.UI.RawImage))
    ---@type UnityEngine.Camera
    self.MixUiCamera = self.MixRoot:FindTransform("MixUiCamera"):GetComponent(typeof(CS.UnityEngine.Camera))
    self.MixCanvas = self.MixRoot:FindTransform("MixCanvas")
    self:AutoResizeMixCanvas()
end

function XUiMovie:AddListener()
    self:RegisterClickEvent(self.BtnSkip, self.OnClickBtnSkip)
    self.BtnReview.CallBack = function() self:OnClickBtnReview() end
    self.BtnAuto.CallBack = function() self:OnClickBtnAuto() end
    self.BtnAutoing.CallBack = function() self:OnClickBtnAutoing() end
    self.BtnTurn.CallBack = function() self:OnClickBtnTurn() end
    self.BtnHide.CallBack = function() self:OnClickBtnHide() end
    XUiHelper.RegisterClickEvent(self, self.BtnScreenSpeed, self.OnClickBtnScreenSpeed)
    self.PanelMaskInputHandler:AddPointerClickListener(handler(self, self.OnClickBtnPause))
    self.PanelHideMaskInputHandler:AddPointerClickListener(handler(self, self.OnClickHideMask))
    self.TxtWords.onClick = function() self:OnBtnNextClick() end
    self.TxtWords.onLinkClick = function(arg) self:OnClickTxtWords(arg) end
    self.BtnNextInputHandler:AddPointerClickListener(function() self:OnBtnNextClick() end)
    self.BtnNextInputHandler:AddPressListener(function(pressTime) self:OnBtnNextPress(pressTime) end)
    self.BtnNextInputHandler:AddPointerUpListener(function() self:OnBtnNextPointerUp() end)
    self:RegisterClickEvent(self.BtnBookmark, self.OnBtnBookmarkClick)
end

function XUiMovie:OnClickBtnSkip()
    if self:SelectPanelShowing() then
        return
    end
    local skipSummaryCfg = XDataCenter.MovieManager.TryGetMovieSkipSummaryCfg()
    local openTime = XTime.GetServerNowTimestamp()
    local closeCb = function()
        XLuaUiManager.Remove("UiVideoPlayer")
        local stayTime = math.max(0, XTime.GetServerNowTimestamp() - openTime)
        
        XDataCenter.MovieManager.RecordStorylineSkip(XDataCenter.MovieManager.GetCurPlayingMovieId(), XPlayer.GetLevel(), XPlayer.Gender, stayTime, XDataCenter.MovieManager.GetCurPlayingActionId())
        
        XDataCenter.MovieManager.StopMovie()
    end
    
    if not XTool.IsTableEmpty(skipSummaryCfg) then
        XLuaUiManager.Open("UiMovieSummary", XMVCA.XMovie.EnumConst.SkipType.Summary, skipSummaryCfg, nil, closeCb)
    else
        XLuaUiManager.Open("UiMovieSummary", XMVCA.XMovie.EnumConst.SkipType.OnlyTips, nil, nil, closeCb)
    end
end

function XUiMovie:OnClickBtnReview()
    if self:SelectPanelShowing() then
        return
    end
    self:OpenChildUi("UiMovieReview")
    self:ResetAutoPlay()
end

function XUiMovie:OnClickHideMask()
    self.PanelHideMask.gameObject:SetActiveEx(false)
    self.PanelDialogCanvasGroup.alpha = 1
    self.TopBtnCanvasGroup.alpha = 1
end

function XUiMovie:OnClickBtnHide()
    self.PanelHideMask.gameObject:SetActiveEx(true)
    self.PanelDialogCanvasGroup.alpha = 0
    self.TopBtnCanvasGroup.alpha = 0
    self:ResetAutoPlay()
end

function XUiMovie:OnClickBtnPause()
    if self:SelectPanelShowing() then
        return
    end
    if not XDataCenter.MovieManager.GetIsAutoPlay() then
        return
    end
    XDataCenter.MovieManager.SwitchMovieState()
    local isMoviePause = XDataCenter.MovieManager.IsMoviePause()
    if isMoviePause then
        self:PlayAnimation("ImgPauseIconEnable")
    else
        self:PlayAnimation("ImgPauseIconDisable")
    end
    self.ImgPauseIcon.gameObject:SetActiveEx(isMoviePause)
    self:RefreshTextPause()
end

function XUiMovie:OnClickBtnTurn()
    XDataCenter.MovieManager.BackToLastAction()
end

function XUiMovie:OnClickBtnScreenSpeed()
    local isShow = not self.IsShowSpeedList
    self:ShowSpeedList(isShow)
end

---@return XUiGridMovieSpineActor
function XUiMovie:GetSpineActor(actorIndex)
    local actor = self.SpineActors[actorIndex]
    if not actor then
        XLog.Error("XUiMovie:GetSpineActor error:ActorIndex is not match, actorIndex is " .. actorIndex)
    end
    return actor
end

function XUiMovie:GetTipActor(actorIndex)
    local actor = self.InsertActors[actorIndex]
    if not actor then
        XLog.Error("XUiMovie:GetTipActor error:ActorIndex is not match, actorIndex is " .. actorIndex)
    end
    return actor
end

function XUiMovie:GetModelActor(roleId)
    local actor = self.ActorDic[roleId]
    if not actor then
        XLog.Debug("XUiMovie:GetModelActor error:ActorIndex is not match, actorIndex is " .. roleId)
    end
    return actor
end

function XUiMovie:AddModelActor(roleId, transform, isShow)
    --todo  aafasou 加载角色模型
    if self.ActorDic[roleId] then
        XLog.Error("XUiMovie:LoadModelActor,重复载入角色,roleId", roleId)
        return
    end
    local proxy = CS.Movie.XMovie3DManager.Get3DRoleProxy(roleId)
    proxy:Show(transform.Position, transform.Rotation)
    proxy.transform.parent = self.ActorRoot
    self.ActorDic[roleId] = proxy
end

function XUiMovie:AddTimeline(path, name, position, rotation)
    if self.TimelineDic[name] then
        return
    end
    local timelineObj = CS.LoadHelper.InstantiateGameObject(path)
    timelineObj.transform.parent = self.TimelineRoot
    timelineObj.transform.position = position
    timelineObj.transform.localEulerAngles = rotation
    ---@type UnityEngine.Playables.PlayableDirector
    local timelineHelper = timelineObj:GetTimelineHelper()
    if timelineHelper then
        self.TimelineDic[name] = timelineHelper
    else
        XLog.Error(" XUiMovie:AddTimeline 添加的资源不带有PlayableDirector，请检查对应预制体,Path:", path)
    end
end

function XUiMovie:GetTimeline(name)
    if self.TimelineDic[name] then
        return self.TimelineDic[name]
    else
        XLog.Error("XUiMovie:GetTimeline 对应Timeline资源尚未加载 name:", name)
    end
end

function XUiMovie:AddCamera(name,cameraPath,transform)
    if not cameraPath then
        return
    end
    if self.CameraDic[name] then
        return
    end
    local container = CS.UnityEngine.GameObject()
    container.name = name
    container.transform.parent = self.CameraRoot
    
    local obj = container:LoadPrefab(cameraPath)
    obj.transform.localPosition = transform.Position
    obj.transform.localEulerAngles = transform.Rotation
    self.CameraDic[name] = container
    container.gameObject:SetActiveEx(false)
end

function XUiMovie:SwitchCamera(name,time)
    ---@type UnityEngine.GameObject
    local camera = self.CameraDic[name]
    if not camera then
        XLog.Error("XUiMovie:PlayCameraAnimation:没有加载对应的Camera动画,name:", name)
        return
    end
    for _, obj in pairs(self.CameraDic) do
        obj.gameObject:SetActiveEx(false)
    end
    local define = self.CineMachineBrain.m_DefaultBlend
    define.m_Time = time
    self.CineMachineBrain.m_DefaultBlend = define
    camera.gameObject:SetActiveEx(true)
end

function XUiMovie:Switch3DMovie()
    self.Bg.gameObject:SetActiveEx(false)
    self.UiMovieBg:GetBg(1):Hide()
    self.TopBtn.gameObject:SetActiveEx(false)
    self.Panel3d.gameObject:SetActiveEx(true)
end

function XUiMovie:Hide()
    self.GameObject:SetActiveEx(false)
end

function XUiMovie:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiMovie:SetMixBg(path)
    if not string.IsNilOrEmpty(path) then
        self.MixBg:SetRawImage(path)
        self.MixBg.gameObject:SetActiveEx(true)
    end
end

function XUiMovie:AutoResizeMixCanvas()
    local v = self.MixCanvas.transform.position - self.MixUiCamera.transform.position
    local offset = CS.UnityEngine.Vector3.Project(v, self.MixUiCamera.transform.position)
    self.MixCanvas.transform.position = self.MixCanvas.transform.position + offset
    
    local height = self.MixUiCamera.orthographicSize * 2
    local width = height * self.MixUiCamera.aspect
    ---@type UnityEngine.RectTransform
    local rectTransform = self.MixCanvas:GetComponent(typeof(CS.UnityEngine.RectTransform))
    rectTransform.sizeDelta = CS.UnityEngine.Vector2(width, height)
end

function XUiMovie:SwitchMixPanel()
    self.MixRoot.gameObject:SetActiveEx(true)
    self:Switch3DMovie()
end

function XUiMovie:ShowInsertTips()
    self.Panelinsert02.gameObject:SetActiveEx(true)
    self:PlayAnimation("Panelinsert02Enable")
end 

function XUiMovie:HideInsertTips()
    self:PlayAnimation("Panelinsert02Disable",function()
        self.Panelinsert02.gameObject:SetActiveEx(false)
    end)
end

function XUiMovie:SetInsertBg(bgPath)
    if not string.IsNilOrEmpty(bgPath) then
        self.InsertBg:SetRawImage(bgPath)
    end
end

function XUiMovie:GetInsertBgActor(direction)
    local actor = self.InsertBgActor[direction]
    if not actor then
        XLog.Error("XUiMovie:GetInsertBgActor error:ActorIndex is not match, actorIndex is " .. direction)
        return
    end
    return actor
end

function XUiMovie:SetInsertPanelBg(bgPath,direction)
    if not string.IsNilOrEmpty(bgPath) then
        if direction == InsertDirection.Left then
            self.RImgLeftBg:SetRawImage(bgPath)
        elseif direction == InsertDirection.Right then
            self.RImgRightBg:SetRawImage(bgPath)    
        end
    end
end

function XUiMovie:PlayInsertPanelEnableAnimation(direction)
    self:PlayAnimation(InsertPanelEnableAnimationDic[direction])
end 

function XUiMovie:PlayInsertPanelDisableAnimation(direction)
    self:PlayAnimation(InsertPanelDisableAnimationDic[direction])
end

-- 初始化倍速选项
function XUiMovie:InitSpeedGroup()
    self.SpeedBtns = {}
    local configs = XMovieConfigs.GetMovieSpeedConfig()
    for i, config in ipairs(configs) do
        local go = self.BtnSpeed.gameObject
        if i > 1 then
            go = CS.UnityEngine.Object.Instantiate(self.BtnSpeed.gameObject, self.PanelSpeedGroup.transform)
        end

        local uiButton = go:GetComponent("XUiButton")
        uiButton:SetName(config.Name)
        table.insert(self.SpeedBtns, uiButton)
    end

    self.PanelSpeedGroup:Init(self.SpeedBtns, function(tabIndex) self:OnClickSpeedButtonCallBack(tabIndex) end)
    local defaultIndex = #configs
    self.PanelSpeedGroup:SelectIndex(defaultIndex)
end

-- 选中速度按钮回调
function XUiMovie:OnClickSpeedButtonCallBack(index)
    XDataCenter.MovieManager.SetLongPressAutoPlay(false)
    
    -- 关闭倍速列表
    self:ShowSpeedList(false)

    if self.SpeedIndex == index then 
        return
    end

    self.SpeedIndex = index
    local curSpeed = XDataCenter.MovieManager.GetSpeed()
    local config = XMovieConfigs.GetMovieSpeedConfig(self.SpeedIndex)
    local selectSpeed = config.Speed / 1000
    if selectSpeed ~= curSpeed then 
        XDataCenter.MovieManager.SetSpeed(selectSpeed)
    end

    local desc = XUiHelper.GetText("MovieSpeed", config.Name)
    self.BtnScreenSpeed:SetName(desc)
end

-- 加载资源，所有action均走这个接口
function XUiMovie:LoadResource(path)
    self.Loader = self.Loader or self.Transform:GetLoader()
    if not self.ResourceDic then
        self.ResourceDic = {}
    end

    local resource = self.ResourceDic[path]
    if not resource then
        resource = self.Loader:Load(path)
        self.ResourceDic[path] = resource
    end
    return resource
end

--============================================================== #region Animtion ==============================================================
-- 获取UI动画
function XUiMovie:GetUiAnimation(animName)
    if string.sub(animName, 1, 6) == "RImgBg" then
        local bgIndexStr, shortAnimName = string.match(animName, "^RImgBg(%d+)(%a+%d*%a*)$")
        local bgIndex = tonumber(bgIndexStr)
        local bgAnimName = "RImgBg" .. tostring(shortAnimName)
        local bg = self.UiMovieBg:GetBg(bgIndex)
        bg:Show() -- 需要节点显示才能播放动画，否则动画的activeInHierarchy为false
        return bg:GetAnim(bgAnimName)
        
    elseif string.sub(animName, 1, 10) == "PanelActor" then
        local actorIndexStr, shortAnimName = string.match(animName, "^PanelActor(%d+)(%a+%d*%a*)$")
        local actorIndex = tonumber(actorIndexStr)
        local actor = self:GetActor(actorIndex)
        return actor:GetAnim(shortAnimName)
        
    else
        return self[animName]
    end
end
--============================================================== #endregion Animtion ==============================================================


--============================================================== #region BtnAuto ==============================================================
function XUiMovie:OnClickBtnAuto()
    local isAutoPlay = not XDataCenter.MovieManager.GetIsAutoPlay()
    XDataCenter.MovieManager.SetMoviePause(false)
    XDataCenter.MovieManager.SetAutoPlay(isAutoPlay)
    
    self.BtnTurn:SetDisable(isAutoPlay, not isAutoPlay)
    self.PanelMask.gameObject:SetActiveEx(isAutoPlay)
    self.ImgPauseIcon.gameObject:SetActiveEx(false)

    -- 显示倍速
    self.BtnScreenSpeed.gameObject:SetActiveEx(isAutoPlay)
    self.BtnAuto.gameObject:SetActiveEx(not isAutoPlay)
    self.BtnAutoing.gameObject:SetActiveEx(isAutoPlay)
    if isAutoPlay then
        self:StartAutoTimer()
        
        -- 按钮显示当前倍速
        local curSpeed = XDataCenter.MovieManager.GetSpeed()
        local configSpeed = math.floor(curSpeed * 1000)
        local index, config = XMovieConfigs.GetMovieSpeedConfigBySpeed(configSpeed)
        self.PanelSpeedGroup:SelectIndex(index)

        -- 自动播放和暂停文本
        self:RefreshTextPause()
    end
end

function XUiMovie:OnClickBtnAutoing()
    XDataCenter.MovieManager.SetLongPressAutoPlay(false)
    XDataCenter.MovieManager.SetMoviePause(false)
    XDataCenter.MovieManager.SetAutoPlay(false)
    
    self.BtnTurn:SetDisable(false, true)
    self.PanelMask.gameObject:SetActiveEx(false)
    self.ImgPauseIcon.gameObject:SetActiveEx(false)
    
    self.BtnScreenSpeed.gameObject:SetActiveEx(false)
    self.BtnAuto.gameObject:SetActiveEx(true)
    self.BtnAutoing.gameObject:SetActiveEx(false)
    
    self:ClearAutoTimer()
end

-- 刷新暂停文本
function XUiMovie:RefreshTextPause()
    local isMoviePause = XDataCenter.MovieManager.IsMoviePause()
    self.BtnAutoTextPlayingNormal.gameObject:SetActiveEx(not isMoviePause)
    self.BtnAutoTextPlayingPress.gameObject:SetActiveEx(not isMoviePause)
    self.BtnAutoTextStopNormal.gameObject:SetActiveEx(isMoviePause)
    self.BtnAutoTextStopPress.gameObject:SetActiveEx(isMoviePause)
end

-- 关闭自动播放
function XUiMovie:ResetAutoPlay()
    if XDataCenter.MovieManager.GetIsAutoPlay() then
        self.BtnAuto:SetButtonState(XUiButtonState.Normal)
        self:OnClickBtnAuto()
    end
end

-- 显示自动播放速度列表
function XUiMovie:ShowSpeedList(isShow)
    self.IsShowSpeedList = isShow
    self.PanelSpeedGroup.gameObject:SetActiveEx(isShow)
    local state = isShow and XUiButtonState.Select or XUiButtonState.Normal
    self.BtnScreenSpeed:SetButtonState(state)
end

function XUiMovie:StartAutoTimer()
    self:ClearAutoTimer()
    self.AutoTimer = XScheduleManager.ScheduleForever(function()
        if not self.GameObject.activeInHierarchy then return end

        local actionIndex = XDataCenter.MovieManager.GetCurPlayingActionIndex()
        local nowTime = CS.UnityEngine.Time.realtimeSinceStartup
        if self.LastActionIndex ~= actionIndex then
            self.LastActionIndex = actionIndex
            self.LastActionTime = nowTime
        else
            local actionType = XDataCenter.MovieManager.GetCurPlayingActionType()
            local AUTO_PLAY_CLICK_ACTION = XMVCA.XMovie.EnumConst.AUTO_PLAY_CLICK_ACTION
            local offset = AUTO_PLAY_CLICK_ACTION[actionType] or AUTO_PLAY_CLICK_ACTION.DEFAULT
            if type(offset) == "number" and (nowTime - self.LastActionTime) >= (offset / 1000) then
                self:OnBtnNextClick()
            end
        end
    end, XScheduleManager.SECOND, 0)
end

function XUiMovie:UpdateLastActionTime()
    local nowTime = CS.UnityEngine.Time.realtimeSinceStartup
    self.LastActionTime = nowTime
end

function XUiMovie:ClearAutoTimer()
    if self.AutoTimer then
        XScheduleManager.UnSchedule(self.AutoTimer)
        self.AutoTimer = nil
    end
end
--============================================================== #endregion PanelDialog ==============================================================


--============================================================== #region PanelDialog ==============================================================
function XUiMovie:OnClickTxtWords(arg)
    XLuaUiManager.Open("UiMovieKeywordTips", arg)
end

--============================================================== #endregion PanelDialog ==============================================================



--region Actor

---@return XUiGridMovieActor
function XUiMovie:GetActor(actorIndex)
    local actor = self.Actors[actorIndex]
    if not actor then
        XLog.Error("XUiMovie:GetActor error:ActorIndex is not match, actorIndex is " .. actorIndex)
    end
    return actor
end

-- 获取Actor预制体模版
function XUiMovie:GetUiMoviePanelActor()
    return self.UiMoviePanelActor
end
--endregion

--region PanelText
-- 显示文本
function XUiMovie:AppearText(layer, id, content, posX, posY, scale, rotation, isAnim, anchorType)
    if not self.UiPanelText then
        local XUiPanelText = require("XUi/XUiMovie/XUiPanelText")
        self.UiPanelText = XUiPanelText.New(self.PanelText, self)
        self.UiPanelText:Open()
    end
    return self.UiPanelText:AppearText(layer, id, content, posX, posY, scale, rotation, isAnim, anchorType)
end

-- 隐藏指定id的文本
function XUiMovie:DisAppearText(id, isAnim)
    self.UiPanelText:DisAppearText(id, isAnim)
end

-- 隐藏所有文本
function XUiMovie:DisAppearAllText()
    if self.UiPanelText then
        self.UiPanelText:DisAppearAllText()
    end
end

-- 播放文本动画
function XUiMovie:TextPlayAnim(id, time, pos, rotation, scale)
    return self.UiPanelText:TextPlayAnim(id, time, pos, rotation, scale)
end

function XUiMovie:GetText(id)
    return self.UiPanelText:GetText(id)
end
--endregion

--region BtnNext
-- 设置BtnNext回调函数
function XUiMovie:SetBtnNextCallback(cb)
    self.BtnNextCb = cb
end

-- 移除BtnNext回调函数
function XUiMovie:RemoveBtnNextCallback()
    self.BtnNextCb = nil
end

-- 点击BtnNext回调
function XUiMovie:OnBtnNextClick()
    local INTERVAL = 0.3 -- 间隔时间
    local curTime = CS.UnityEngine.Time.time
    self.LastDoNextTime = self.LastDoNextTime or 0
    if curTime - self.LastDoNextTime < INTERVAL then
        return
    end
    self.LastDoNextTime = curTime

    if self.BtnNextCb then 
        self.BtnNextCb()
    else
        -- 播放下一个MovieAction
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
    end
end

-- BtnNext长按回调
function XUiMovie:OnBtnNextPress(pressTime)
    -- 进入自动播放
    if pressTime > XMVCA.XMovie.EnumConst.LONG_PRESS_ENTER_AUTO_PLAY_TIME and not XDataCenter.MovieManager.GetIsAutoPlay() then
        XDataCenter.MovieManager.SetLongPressAutoPlay(true)
        self:OnClickBtnAuto()
    end
end

-- BtnNext抬起
function XUiMovie:OnBtnNextPointerUp()
    -- 暂停自动播放
    if XDataCenter.MovieManager.GetIsAutoPlay() then
        XDataCenter.MovieManager.SetLongPressAutoPlay(false)
        self:OnClickBtnAuto()
    end
end
--endregion

--region BtnBookmark
-- 点击书签按钮
function XUiMovie:OnBtnBookmarkClick()
    -- 自动播放时，暂停自动播放
    if XDataCenter.MovieManager.GetIsAutoPlay() then
        local isMoviePause = XDataCenter.MovieManager.IsMoviePause()
        if not isMoviePause then
            self:OnClickBtnPause()
        end
    end

    XMVCA.XMovie:RequestGetStageBookmark(function(bookmarkData)
        if bookmarkData ~= nil then
            local bookmarkName = XMVCA.XMovie:GetBookmarkName()
            local params = XMVCA.XMovie:GetClientConfigParams("BookmarkCoverTips")
            local tipTitle = params[1]
            local contentFormat = params[2]
            local content = string.format(contentFormat, bookmarkName)
            content = XUiHelper.ConvertLineBreakSymbol(content)
            local confirmCb = function()
                self:RequestAddStageBookmark()
            end
            XLuaUiManager.Open("UiSystemDialog", tipTitle, content, XUiManager.DialogType.Normal, nil, confirmCb)
        else
            self:RequestAddStageBookmark()
        end
    end)
end

-- 请求添加书签
function XUiMovie:RequestAddStageBookmark()
    XMVCA.XMovie:RequestAddStageBookmark(function()
        local content = self._Control:GetClientConfig("BookmarkSuccessTips")
        XLuaUiManager.Open("UiLeftTip", content)
    end)
end
--endregion

return XUiMovie