---@class XBigWorldAgency : XAgency
---@field private _Model XBigWorldModel
---@field private _InputMapIdStack XStack
---@field private _OpenGuide XBigWorldOpenGuide
local XBigWorldAgency = XClass(XAgency, "XBigWorldAgency")

---@type X3CCommand
local X3C_CMD = CS.X3CCommand

local CsBigWorldConfig = CS.XBigWorldConfig

function XBigWorldAgency:OnInit()
    --大世界通用
    self._MVCAList = {
        --基础组件
        ModuleId.XBigWorldFunction,
        ModuleId.XBigWorldCommon,
        ModuleId.XBigWorldQuest,
        ModuleId.XBigWorldNews,
        ModuleId.XBigWorldResource,
        ModuleId.XBigWorldInstance,
        ModuleId.XBigWorldSkipFunction,
        ModuleId.XBigWorldMemory,
        ModuleId.XLowMemory,
        --具体玩法
        ModuleId.XBigWorldAlbum,
        ModuleId.XCommanderCollege,
        ModuleId.XBigWorldBackpack,
        ModuleId.XBigWorldMessage,
        ModuleId.XBigWorldTeach,
        ModuleId.XBigWorldSet,
        ModuleId.XBigWorldLoading,
        ModuleId.XBigWorldMap,
        --ModuleId.XBigWorldCourse,
       
    }

    self._InputMapIdStack = XStack.New()

    self._IsDisablePerspective = false
end

function XBigWorldAgency:InitRpc()
    self:AddRpc("BigWorldNotifyReward", handler(self, self.BigWorldNotifyReward))
end

function XBigWorldAgency:InitEvent()
    XMVCA.XDlcHelper:AddDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.BigWorld, self)

    XMVCA.XBigWorldUI:AddFightUiCb("UiBigWorldFirstPerson", handler(self, self.OnFightOpenFirstPerson))

    self:InitConditionCheck()
end

function XBigWorldAgency:RemoveEvent()
    XMVCA.XDlcHelper:RemoveDlcModelIdGetterWithWorldType(XEnumConst.DlcWorld.WorldType.BigWorld, self)
    self:ReleaseConditionCheck()
end

function XBigWorldAgency:InitConditionCheck()
    XMVCA.XBigWorldService:RegisterConditionFunc(10101008, handler(self, self.CheckParamMarkedCondition))

    self:OnInitConditionCheck()
end

function XBigWorldAgency:ReleaseConditionCheck()
    if not XMVCA:IsRegisterAgency(ModuleId.XBigWorldService) then
        return
    end
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10101008)
    self:OnReleaseConditionCheck()
end

function XBigWorldAgency:OnInitConditionCheck()
end

function XBigWorldAgency:OnReleaseConditionCheck()
end

--- 初始化X3C注册,
function XBigWorldAgency:InitX3C()
    local register = function(cmd, func, obj)
        XMVCA.X3CProxy:RegisterHandler(cmd, func, obj)
    end

    -- 大世界任务
    register(X3C_CMD.CMD_QUEST_ALL_STATES_INIT, XMVCA.XBigWorldQuest.InitQuest, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_ACTIVATED, XMVCA.XBigWorldQuest.OnQuestActivated, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_UNDERTAKEN, XMVCA.XBigWorldQuest.OnQuestUndertaken, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_REMOVE, XMVCA.XBigWorldQuest.OnQuestRemove, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_RELAUNCH, XMVCA.XBigWorldQuest.OnQuestRelaunch, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_FINISH_NOTIFY, XMVCA.XBigWorldQuest.OnQuestFinished, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_STEP_STATE_CHANGED, XMVCA.XBigWorldQuest.OnStepChanged, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_STEP_OBJECTIVE_CHANGED, XMVCA.XBigWorldQuest.OnObjectiveChanged, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_NOTIFY_OPEN_QUEST_DELIVERY, XMVCA.XBigWorldQuest.OpenPopupDelivery, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_OPEN_QUEST_PROCESS_POP, XMVCA.XBigWorldQuest.PopupTaskObtainByFight, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_NOTIFY_QUEST_MISSED_OCCUPATION_INFO, XMVCA.XBigWorldQuest.OnQuestOccupied, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_QUEST_AUTO_GO_TARGET, XMVCA.XBigWorldQuest.OnAutoGoToQuestTarget, XMVCA.XBigWorldQuest)
    register(X3C_CMD.CMD_ECOLOGY_CONSTRUCT_LOAD_COMPLETE, XMVCA.XBigWorldQuest.OnEnvironmentGroupChangeComplete, XMVCA.XBigWorldQuest)

    register(X3C_CMD.CMD_OPEN_MAINLINE_SKIP_TIP, XMVCA.XBigWorldQuest.OnOpenMainlineSkipTip, XMVCA.XBigWorldQuest)
    
    -- 大世界角色
    -- 大世界角色加载完毕
    register(X3C_CMD.CMD_TRIAL_NPC_JOIN_TEAM, XMVCA.XBigWorldCharacter.OnTrialNpcJoinTeam,
        XMVCA.XBigWorldCharacter)
    register(X3C_CMD.CMD_TRIAL_NPC_LEAVE_TEAM, XMVCA.XBigWorldCharacter.OnTrialNpcLeaveTeam,
        XMVCA.XBigWorldCharacter)

    -- 指挥官DIY
    register(X3C_CMD.CMD_SHOW_PLAYER_DIY_UI, XMVCA.XBigWorldCommanderDIY.OpenMainUi, XMVCA.XBigWorldCommanderDIY)

    -- 短信系统
    register(X3C_CMD.CMD_BIG_WORLD_MESSAGE_RECEIVE, XMVCA.XBigWorldMessage.OnReceiveMessage, XMVCA.XBigWorldMessage)
    -- 地图系统
    register(X3C_CMD.CMD_SET_MAP_PIN_VISIBLE, XMVCA.XBigWorldMap.OnDisplayMapPins, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_AUTO_STOP_TRACK_MAP_PIN, XMVCA.XBigWorldMap.OnCancelTrackMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_PLAYER_ENTER_SCENE_REGION, XMVCA.XBigWorldMap.OnPlayerEnterArea, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_PLAYER_EXIT_SCENE_REGION, XMVCA.XBigWorldMap.OnPlayerExitArea, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_ADD_QUEST_MAP_PIN, XMVCA.XBigWorldMap.OnAddQuestMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_SET_MAP_PIN_SHOW_TYPE, XMVCA.XBigWorldMap.OnMapPinShowTypeChange, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_REMOVE_QUEST_MAP_PIN, XMVCA.XBigWorldMap.OnRemoveQuestMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_REMOVE_QUEST_ALL_MAP_PIN, XMVCA.XBigWorldMap.OnRemoveQuestAllMapPins, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_START_TRACK_QUEST_MAP_PIN, XMVCA.XBigWorldMap.OnTrackQuestMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_STOP_TRACK_QUEST_MAP_PIN, XMVCA.XBigWorldMap.OnCancelTrackQuestMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_TELEPORT_PLAYER_COMPLETE, XMVCA.XBigWorldMap.OnTeleportComplete, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_SET_MAP_PIN_ASSISTED_TRACK, XMVCA.XBigWorldMap.OnAssistedTrackMapPin, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_UPDATE_MAP_PIN_POSITION, XMVCA.XBigWorldMap.OnUpdateMapPinPosition, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_GET_LITTLE_MAP_RADIUS, XMVCA.XBigWorldMap.OnGetLittleMapRadius, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_FIGHT_OPEN_BIG_MAP, XMVCA.XBigWorldMap.OnOpenBigMap, XMVCA.XBigWorldMap)
    register(X3C_CMD.CMD_MAP_PIN_OUT_OF_LITTLE_MAP_RANGE, XMVCA.XBigWorldMap.OnLittleMapPinRemove, XMVCA.XBigWorldMap)

    -- 通用功能
    register(X3C_CMD.CMD_OPEN_CONFIRM_POPUP_UI, XMVCA.XBigWorldUI.OpenConfirmPopupUiWithCmd, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_FIGHT_OPEN_UI_NOTIFY, XMVCA.XBigWorldUI.OnFightOpenUi, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_FIGHT_CLOSE_UI_NOTIFY, XMVCA.XBigWorldUI.OnFightCloseUi, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_SHOW_BIG_WORLD_OBTAIN, XMVCA.XBigWorldUI.OpenBigWorldObtainWithCmd, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_SHOW_BIG_WORLD_REWARD_SIDEBAR, XMVCA.XBigWorldUI.OpenBigWorldRewardSidebarWithCmd, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_SHOW_BIG_WORLD_REWARD_GOODS, XMVCA.XBigWorldUI.OpenBigWorldRewardGoodsWithCmd, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_OPEN_DRAMA_SKIP_POPUP_UI, XMVCA.XBigWorldUI.OpenDramaSkipPopupWithCmd, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_OPEN_QUIT_CONFIRM_POPUP_UI, XMVCA.XBigWorldUI.OpenQuitConfirmPopupWithCmd, XMVCA.XBigWorldUI)
    register(X3C_CMD.CMD_CAMERA_PHOTOGRAPH_NOTIFY_CUR_SCALE_RANGE, XMVCA.XBigWorldAlbum.NotifyCurScaleRange, XMVCA.XBigWorldAlbum)
    register(X3C_CMD.CMD_CAMERA_PHOTOGRAPH_DETECTED_ACTORS_CHANGED, XMVCA.XBigWorldAlbum.NotifyActorChange, XMVCA.XBigWorldAlbum)
    register(X3C_CMD.CMD_CAMERA_OPEN_PHOTOGRAPH_UI, XMVCA.XBigWorldAlbum.OpenPhotoGraphUi, XMVCA.XBigWorldAlbum)
    register(X3C_CMD.CMD_CAMERA_TAKE_PHOTOGRAPH_SILENT, XMVCA.XBigWorldAlbum.TakePhotoSilent, XMVCA.XBigWorldAlbum)
    register(X3C_CMD.CMD_REQUEST_SKIP_INTERFACE, XMVCA.XBigWorldFunction.OnSkipInterface, XMVCA.XBigWorldFunction)
    register(X3C_CMD.CMD_TRY_ACTIVE_GUIDE, XMVCA.XBigWorldGamePlay.TryActiveGuide, XMVCA.XBigWorldGamePlay)

    -- 实例关卡相关功能(InstanceLevel)
    register(X3C_CMD.CMD_OPEN_LEAVE_INST_LEVEL_POPUP, XMVCA.XBigWorldInstance.ShowExitLevelPopup, XMVCA.XBigWorldCommon)

    -- 加载Level
    register(X3C_CMD.CMD_DLC_FIGHT_ENTER_LEVEL, XMVCA.XBigWorldGamePlay.OnEnterLevel, XMVCA.XBigWorldGamePlay)
    register(X3C_CMD.CMD_DLC_FIGHT_LEAVE_LEVEL, XMVCA.XBigWorldGamePlay.OnLeaveLevel, XMVCA.XBigWorldGamePlay)
    register(X3C_CMD.CMD_DLC_FIGHT_BEGIN_UPDATE_LEVEL, XMVCA.XBigWorldGamePlay.OnLevelBeginUpdate, XMVCA.XBigWorldGamePlay)

    -- 切换实例关卡
    register(X3C_CMD.CMD_REQUEST_ENTER_INST_LEVEL, XMVCA.XBigWorldGamePlay.CmdRequestEnterInstLevel, XMVCA.XBigWorldGamePlay)
    register(X3C_CMD.CMD_REQUEST_LEAVE_INST_LEVEL, XMVCA.XBigWorldGamePlay.CmdRequestLeaveInstLevel, XMVCA.XBigWorldGamePlay)

    -- 打开玩法主入口
    register(X3C_CMD.CMD_BIG_WORLD_MAIN_OPEN_GAMEPLAY_MAIN_ENTRANCE, XMVCA.XBigWorldGamePlay.OnOpenMainUi, XMVCA.XBigWorldGamePlay)

    -- 图文教程
    register(X3C_CMD.CMD_BIG_WORLD_SHOW_TEACH, XMVCA.XBigWorldTeach.OnShowTeach, XMVCA.XBigWorldTeach)
    register(X3C_CMD.CMD_BIG_WORLD_OPEN_TEACH_POPUP, XMVCA.XBigWorldTeach.OnOpenTeachPopup, XMVCA.XBigWorldTeach)

    -- Loading
    register(X3C_CMD.CMD_FIGHT_OPEN_LOADING, XMVCA.XBigWorldLoading.OnCmdOpenLoading, XMVCA.XBigWorldLoading)
    register(X3C_CMD.CMD_FIGHT_CLOSE_LOADING, XMVCA.XBigWorldLoading.OnCmdCloseLoading, XMVCA.XBigWorldLoading)

    -- 功能屏蔽
    register(X3C_CMD.CMD_SYSTEM_FUNCTION_ENABLE_CHANGED, XMVCA.XBigWorldFunction.OnFunctionsShieldChanged, XMVCA.XBigWorldFunction)
    register(X3C_CMD.CMD_CONTROL_SYSTEM_FUNCTION, XMVCA.XBigWorldFunction.OnControlFunctionShield, XMVCA.XBigWorldFunction)
    register(X3C_CMD.CMD_CHECK_FUNCTION_UNLOCK, XMVCA.XBigWorldFunction.CheckFunctionOpenWithCmd, XMVCA.XBigWorldFunction)

    --结算
    register(X3C_CMD.CMD_OPEN_INSTANCE_SETTLEMENT, XMVCA.XBigWorldInstance.OpenSettle, XMVCA.XBigWorldInstance)

    --战斗界面显隐
    register(X3C_CMD.CMD_FIGHT_UI_ON_ENABLED_NOTIFY, XMVCA.XBigWorldGamePlay.OnFightUiEnable, XMVCA.XBigWorldGamePlay)
    register(X3C_CMD.CMD_FIGHT_UI_ON_DISABLED_NOTIFY, XMVCA.XBigWorldGamePlay.OnFightUiDisable, XMVCA.XBigWorldGamePlay)

    -- 第一人称
    register(X3C_CMD.CMD_SEND_SET_PLAYER_FIRST_PERSON_MODE_EVENT, XMVCA.XBigWorldGamePlay.OnPerspectiveModeChanged, XMVCA.XBigWorldGamePlay)
    register(X3C_CMD.CMD_GET_SYSTEM_SAVED_FIRST_PERSON_MODE, XMVCA.XBigWorldGamePlay.OnFightGetPerspectiveState, XMVCA.XBigWorldGamePlay)

    self:OnInitX3C()
end

function XBigWorldAgency:OnInitX3C()
end

function XBigWorldAgency:InitConfig()
    CsBigWorldConfig.Instance:Init()
    XMVCA.XBigWorldUI:OnEnterBigWorld()
end

function XBigWorldAgency:DisposeConfig()
    XMVCA.XBigWorldUI:OnExitBigWorld()
    CsBigWorldConfig.Instance:Dispose()
end

function XBigWorldAgency:BeforeEnterGame()
    self:OnBeforeEnter()
end

function XBigWorldAgency:OnBeforeEnter()
end

function XBigWorldAgency:AfterEnterGame()
    self:OnAfterEnterGame()
end

function XBigWorldAgency:OnAfterEnterGame()
end

function XBigWorldAgency:EnterFight()
    self:InitInputMapStack()
    self:OpenHud()
    XMVCA.XBigWorldMap:InitMapPinData(XMVCA.XBigWorldGamePlay:GetCurrentWorldId())
    XMVCA.XBigWorldFunction:RegisterFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Perspective, self,
            self.OnPerspectiveChangeControlState)
    self:OnEnterFight()
end

function XBigWorldAgency:OnEnterFight()
end

function XBigWorldAgency:ExitFight()
    XMVCA.XBigWorldNews:SaveAllLocalData()
    XMVCA.XBigWorldFunction:RemoveFunctionControllerByMethod(XMVCA.XBigWorldFunction.FunctionType.Perspective, self,
            self.OnPerspectiveChangeControlState)
    self:CloseHud()
    self:OnExitFight()
end

function XBigWorldAgency:OnExitFight()
end

function XBigWorldAgency:EnterLevel(levelId)
    self:OnEnterLevel(levelId)
end

function XBigWorldAgency:OnEnterLevel(levelId)
end

function XBigWorldAgency:LeaveLevel(levelId)
    XMVCA.XBigWorldMap:ClearCurrentAreaGroupData()
    self:OnLeaveLevel(levelId)
end

function XBigWorldAgency:OnLeaveLevel(levelId)
end

function XBigWorldAgency:LevelBeginUpdate(levelId)
    XMVCA.XBigWorldMap:SendCurrentTrackCommand()
    XMVCA.XBigWorldTeach:TryShowTeach()
    self:OnLevelBeginUpdate()
end

function XBigWorldAgency:OnLevelBeginUpdate()
end

function XBigWorldAgency:UpdatePlayerData(res)
    if not res then
        return
    end
    self._Model:UpdateFinishGuideDict(res.BigWorldGuideData)
    self._Model:InitCustomParam(res.CustomParamMarkData)
    self:InitPerspective(res.FovData)
    XMVCA.XBigWorldInstance:InitLevelPlayData(res.LevelPlayDatas)
    XMVCA.XBigWorldCommanderDIY:UpdateData(res)
    XMVCA.XBigWorldCharacter:UpdateTeam(res.CurrentTeamId, res.TeamDict)
    XMVCA.XBigWorldCharacter:UpdateCharacter(res.CharacterWearFashionDict)
    XMVCA.XBigWorldQuest:UpdateData(res.TraceQuestIds, res.TraceQuestData ,res.InviteQuestInfo)
    XMVCA.XBigWorldQuest:UpdateEnvironmentOnDuty(res.EnvironmentQuestData)
    XMVCA.XBigWorldMessage:UpdateAllMessageData(res.BigWorldMessageDict)
    XMVCA.XBigWorldMap:UpdateTrackMapPin(res.MapTrackPinData)
    XMVCA.XBigWorldMap:UpdateTrackReadyQuestMapPin(res.TraceQuestData)
    XMVCA.XBigWorldMap:UpdateAllActivateTeleporter(res.TeleporterData)
    XMVCA.XBigWorldMap:UpdateUnlockLevelMap(res.EnteredLevelIds)
    XMVCA.XBigWorldTeach:UpdateTeachUnlockServerData(res.BigWorldHelpCourseList)
    XMVCA.XBigWorldNews:InitPopupNews(res.NewsPopupData)
    XMVCA.XBigWorldAlbum:UpdateBigWorldPhotographData(res.BigWorldPhotographData, true)
    self:OnUpdatePlayerData(res)
end

function XBigWorldAgency:OnUpdatePlayerData(res)
end

--- 更新世界数据
---@param res Protocol.Protocol.Frontend.DlcWorldSaveDataResponse
function XBigWorldAgency:UpdateWorldData(res)
    self:OnUpdateWorldData(res)
end

function XBigWorldAgency:OnUpdateWorldData(res)
end

function XBigWorldAgency:Exit()
    --- 清理试用角色
    XMVCA.XBigWorldCharacter:ClearTrialCharacterIds()
    self:OnExit()
end

function XBigWorldAgency:OnExit()
end

function XBigWorldAgency:DoRegisterMVCA()
    if self._IsMVCARegistered then
        return
    end
    self._IsMVCARegistered = true
    --先注册BigWorld
    for _, moduleId in pairs(self._MVCAList) do
        if not XMVCA:IsRegisterAgency(moduleId) then
            XMVCA:RegisterAgency(moduleId)
        end
    end
    --再初始化，为了不影响Agency顺序
    for _, moduleId in pairs(self._MVCAList) do
        local agency = XMVCA:GetAgency(moduleId)
        if agency then
            agency:InitDynamicRegister()
        end
    end
    --在注册子类
    self:OnRegisterMVCA()
end

function XBigWorldAgency:OnRegisterMVCA()
end

function XBigWorldAgency:DoUnRegisterMVCA()
    self._IsMVCARegistered = false
    --先注销子类
    self:OnUnRegisterMVCA()
    --再注销BigWorld
    for i = #self._MVCAList, 1, -1 do
        local moduleId = self._MVCAList[i]
        if XMVCA:IsRegisterAgency(moduleId) then
            XMVCA:ReleaseModule(moduleId)
        end
    end
end

function XBigWorldAgency:OnUnRegisterMVCA()
end

function XBigWorldAgency:OnRelease()
    self._IsMVCARegistered = nil
end

function XBigWorldAgency:InitPerspective(perspectiveData)
    self._Model:InitPerspective(perspectiveData)
end

function XBigWorldAgency:UpdatePerspective(groupId, perspectiveId)
    self._Model:UpdatePerspective(groupId, perspectiveId)
end

function XBigWorldAgency:IsSavePerspective(levelId)
    return self._Model:IsSavePerspective(levelId)
end

function XBigWorldAgency:GetPerspective(levelId)
    return self._Model:GetPerspective(levelId)
end

function XBigWorldAgency:GetPerspectiveGroupId(levelId)
    return self._Model:GetPerspectiveGroupId(levelId)
end

---@param controlData XBWFunctionControlData
function XBigWorldAgency:OnPerspectiveChangeControlState(controlData)
    local disable = controlData:GetArgByIndex(1)

    self._IsDisablePerspective = disable

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_PERSPECTIVE_DISABLE)
end

function XBigWorldAgency:IsDisablePerspective()
    return self._IsDisablePerspective
end

--region BigWorldConfig

function XBigWorldAgency:GetInt(key)
    return CsBigWorldConfig.Instance:GetInt(key)
end

function XBigWorldAgency:GetFloat(key)
    return CsBigWorldConfig.Instance:GetFloat(key)
end

function XBigWorldAgency:GetBool(key)
    return CsBigWorldConfig.Instance:GetBool(key)
end

function XBigWorldAgency:GetString(key)
    return CsBigWorldConfig.Instance:GetString(key)
end

function XBigWorldAgency:GetCookieKey(key)
    return self._Model:GetCookieKey(key)
end

--endregion BigWorldConfig

--region 主界面跳转

function XBigWorldAgency:OpenMenu()
    XMVCA.XBigWorldUI:Open("UiBigWorldMenu")
end

function XBigWorldAgency:OpenQuest(index, questId)
    index = index or 1
    questId = questId or XMVCA.XBigWorldQuest:GetTrackQuestId()
    XMVCA.XBigWorldQuest:OpenQuestMain(index, questId)
end

function XBigWorldAgency:OpenBackpack()
    XMVCA.XBigWorldUI:Open("UiBigWorldBackpack")
end

function XBigWorldAgency:OpenMessage()
    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldMessage) then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldMessage")
end

function XBigWorldAgency:OpenTeam()
    if XMVCA.XBigWorldGamePlay:IsCurrentNpcSit() then
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("CurStatusCannotOpen"))
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldRoleRoom")
end

function XBigWorldAgency:OpenExplore()
    XMVCA.XBigWorldCourse:OpenMainUi(nil, true)
end

function XBigWorldAgency:OpenPhoto(isSequence, ...)
    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldAlbum) then
        return
    end

    local t = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_PHOTOGRAPH_CAN_OPEN)
    if t.CanOpen then
        XMVCA.XBigWorldUI:OpenWithFightSequence("UiBigWorldPhotographControl", not isSequence, ...)
    else
        XUiManager.TipMsg(XMVCA.XBigWorldService:GetText("CurStatusCannotOpen"))
    end
end

function XBigWorldAgency:OpenTeaching()
    XMVCA.XBigWorldTeach:OpenTeachMainUi()
end

function XBigWorldAgency:OpenSetting()
    XMVCA.XBigWorldSet:OpenSettingUi()
end

function XBigWorldAgency:OpenMap()
    XMVCA.XBigWorldMap:OpenBigWorldMapUi()
end

function XBigWorldAgency:OpenFashion(characterId, typeIndex)
    XMVCA.XBigWorldUI:Open("UiBigWorldCoating", characterId, typeIndex)
end

function XBigWorldAgency:OpenHud()
    if XLuaUiManager.IsUiLoad("UiBigWorldHud") then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldHud")
end

function XBigWorldAgency:CloseHud()
    XMVCA.XBigWorldUI:Close("UiBigWorldHud")
end

function XBigWorldAgency:SetHudActive(value)
    if not XLuaUiManager.IsUiLoad("UiBigWorldHud") then
        return
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_SET_UI_HUD_ACTIVE, value)
end

function XBigWorldAgency:OnFightOpenFirstPerson(data)
    if not data then
        XLog.Error("OnFightOpenFirstPerson data is nil")
        return
    end
    XMVCA.XBigWorldUI:OpenPerspectiveUi(data.LevelId, data.IsShowClose, data.TxtExplain, data.ConfirmCb)
end

function XBigWorldAgency:RecordHudClick(btnIndex)
end

--endregion 主界面跳转


--region 引导配置

function XBigWorldAgency:LoadGuide()
end

function XBigWorldAgency:UnloadGuide()
end

---@return table<number, XTableBigworldGuideGroup>
function XBigWorldAgency:GetBigWorldGuideGroupTemplates()
    return self._Model:GetBigWorldGuideGroupTemplates()
end

---@return XTableBigworldGuideGroup
function XBigWorldAgency:GetBigWorldGuideGroupTemplateById(guideId)
    return self._Model:GetBigWorldGuideGroupTemplateById(guideId)
end

---@return table<number, XTableGuideComplete>
function XBigWorldAgency:GetBigWorldGuideCompleteTemplates()
    return self._Model:GetBigWorldGuideCompleteTemplates()
end

---@return XTableGuideComplete
function XBigWorldAgency:GetBigWorldGuideCompleteTemplateById(completeId)
    return self._Model:GetBigWorldGuideCompleteTemplateById(completeId)
end

---@return XTableGuideText
function XBigWorldAgency:GetBigWorldGuideTextTemplate(textId)
end

---@return string
function XBigWorldAgency:GetBigWorldGuideIcon(iconId)
end

--endregion


--region 通用奖励弹窗
function XBigWorldAgency:BigWorldNotifyReward(data)
    if not data then
        return
    end
    XMVCA.XBigWorldUI:OpenBigWorldRewardGoods(data.RewardGoodsList)
end

function XBigWorldAgency:RequestBigWorldMarkParam(paramId, isUnmark, cb)
    if not paramId or paramId <= 0 then
        XLog.Warning("RequestBigWorldMarkParam paramId is invalid")
        return
    end
    if self:CheckParamMarked(paramId) then
        XLog.Error("RequestBigWorldMarkParam paramId is already marked")
        return
    end
    XNetwork.Call("BigWorldMarkCustomParamRequest", { Id = paramId, IsUnmark = isUnmark }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if isUnmark then
            self._Model:RemoveCustomParam(paramId)
        else
            self._Model:AddCustomParam(paramId)
        end
        if cb then
            cb()
        end
    end)
end

--endregion

function XBigWorldAgency:BeginOpenGuide()
    if XMVCA.XBigWorldGamePlay.IsDisableOpenGuide() then
        return XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_OPEN_GUIDE_FINISH)
    end
    local openGuideActionList = self:GetOpenGuideActionList()
    if XTool.IsTableEmpty(openGuideActionList) then
        return XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_OPEN_GUIDE_FINISH)
    end
    ---@type XBigWorldOpenGuide
    local beginGuide = require("XModule/XBigWorldGamePlay/OpeningGuide/XBigWorldOpenGuide").New()
    for _, template in ipairs(openGuideActionList) do
        if not self:CheckOpenGuideFinish(template.Id) then
            beginGuide:AddAction(template)
        end
    end
    self._OpenGuide = beginGuide

    beginGuide:Start()
end

--- 退出开场引导
function XBigWorldAgency:TryExitOpenGuide()
    if not self._OpenGuide then
        return
    end
    self._OpenGuide:PreExit()
    self._OpenGuide = nil
end

function XBigWorldAgency:IsInOpenGuide()
    return self._OpenGuide ~= nil
end

---@return XTableBigWorldOpenGuide[]
function XBigWorldAgency:GetOpenGuideActionList()
end

function XBigWorldAgency:CheckOpenGuideFinish(guideId)
    return self._Model:CheckOpenGuideFinish(guideId)
end

function XBigWorldAgency:AddFinishGuideDict(guideId)
    self._Model:AddFinishGuideDict(guideId)
end

function XBigWorldAgency:GetDefaultInputMapId()
    return CS.XInputMapId.System
end

function XBigWorldAgency:InitInputMapStack()
    self._EnterInputMapId = self:GetDefaultInputMapId()
    self:OnInputMapChanged(self._EnterInputMapId)
end

function XBigWorldAgency:OnInputMapChanged(inputMapId)
    local current = CS.XInputManager.CurInputMapID
    --将当前操作类型压栈
    self._InputMapIdStack:Push(inputMapId)
    --类型一致，则不设置
    if current == inputMapId then
        return
    end
    CS.XInputManager.SetCurInputMap(inputMapId)
end

function XBigWorldAgency:OnInputMapResume()
    --不应该出现这种情况
    if self._InputMapIdStack:Count() <= 0 then
        CS.XInputManager.SetCurInputMap(self._EnterInputMapId)
        return
    end
    --栈内只剩一个元素
    if self._InputMapIdStack:Count() == 1 then
        CS.XInputManager.SetCurInputMap(self._InputMapIdStack:Peek())
        return
    end
    --出栈
    self._InputMapIdStack:Pop()
    local current = CS.XInputManager.CurInputMapID
    local peek = self._InputMapIdStack:Peek()
    if current == peek then
        return
    end
    --设置为栈顶类型
    CS.XInputManager.SetCurInputMap(peek)
end

function XBigWorldAgency:CheckParamMarked(paramId)
    return self._Model:CheckParamMarked(paramId)
end

---@param template XTableCondition
function XBigWorldAgency:CheckParamMarkedCondition(template)
    local paramId = template.Params[1]
    local isMarked = template.Params[2] == 1
    if not paramId or paramId <= 0 then
        XLog.Error("CheckParamMarkedCondition paramId is invalid", template.Id)
        return true, ""
    end
    return self:CheckParamMarked(paramId) == isMarked, template.Desc
end

--region DLC区分 - 大世界

function XBigWorldAgency:ExGetDlcModelIdByCharacterData(characterData)
    return XMVCA.XBigWorldCharacter:ExGetDlcModelIdByCharacterData(characterData)
end

function XBigWorldAgency:ExGetDlcModelIdByFashionId(characterId, fashionId)
    local uiModelId = XMVCA.XBigWorldCharacter:GetUiModelIdByFashionId(fashionId)

    return XMVCA.XBigWorldResource:GetDlcModelId(uiModelId)
end

function XBigWorldAgency:GetFightCharHeadIcon(worldNpcData)
    return XMVCA.XBigWorldCharacter:GetFightCharHeadIcon(worldNpcData)
end

function XBigWorldAgency:CheckLevelPlayFullCleared(levelPlayId)
    return XMVCA.XBigWorldInstance:CheckLevelPlayFullCleared(levelPlayId)
end

function XBigWorldAgency:CheckLevelPlayCleared(levelPlayId)
    return XMVCA.XBigWorldInstance:CheckLevelPlayCleared(levelPlayId)
end

function XBigWorldAgency:GetAnimExpressionSOGroupId(fashionId)
    return XMVCA.XBigWorldCharacter:GetAnimExpressionSOGroupId(fashionId)
end

--endregion

return XBigWorldAgency
