---@class XBigWorldGamePlayAgency : XAgency
---@field private _Model XBigWorldGamePlayModel
---@field private _Camera UnityEngine.Camera
---@field private _ActivityAgency table<number, XBigWorldActivityAgency> 活动Id -> 活动Agency
---@field private _Level2Agency table<number, XBigWorldActivityAgency> LevelId -> 活动Agency
local XBigWorldGamePlayAgency = XClass(XAgency, "XBigWorldGamePlayAgency")

local XBigWorldActivityAgency = require("XModule/XBase/XBigWorldActivityAgency")
local IsWindowsEditor = XMain.IsWindowsEditor

---@type XBigWorldHelper
local CsHelper = CS.XBigWorldHelper
local CsSetViewPosToTransformLocalPosition = CS.XUiHelper.SetViewPosToTransformLocalPosition
local DisableOpenGuide = false
local LocalKey = "BIG_WORLD_OPEN_GUIDE_ENABLE"

local ExitIgnoreCloseUiName = {
    ["UiDialogCanvasDialog"] = true,
    ["UiDialog"] = true,
    ["UiSuperWaterMarks"] = true,
    ["UiWaterMask"] = true,
}

local LastRequestSavePerspectiveTime = 0
local SavePerspectiveInterval = 1.2

function XBigWorldGamePlayAgency:OnInit()
    -- 初始化一些变量
    self._ClientArgs = false
    self._CurrentModuleId = 0
    -- 场景相机
    self._Camera = false

    self._ActivityAgency = {}
    self._Level2Agency = {}
    self._MarkUiName = {}

    self.PerspectiveType = {
        FirstPerson = 1, --第一人称
        ThirdPerson = 2, --第三人称
    }
    XMVCA.XBigWorldGamePlay.CheckOpenGuideDisable()
end

function XBigWorldGamePlayAgency:InitRpc()
    self:AddRpc("NotifyBigWorldMainRedPoint", handler(self, self.NotifyBigWorldMainRedPoint))
end

function XBigWorldGamePlayAgency:InitEvent()
    self._OnEnterFight = Handler(self, self.OnEventEnterFight)
    self._OnExitFight = Handler(self, self.OnEventExitFight)
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DLC_FIGHT_ENTER, self._OnEnterFight)
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFight)

    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_OPEN_GUIDE_FINISH, self.InitAfterOpenGuide, self)
end

function XBigWorldGamePlayAgency:RemoveEvent()
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_DLC_FIGHT_ENTER, self._OnEnterFight)
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFight)

    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_OPEN_GUIDE_FINISH, self.InitAfterOpenGuide, self)
end

function XBigWorldGamePlayAgency:SetCurrentGameAgency(worldId)
    local moduleId = self._Model:GetModuleIdByWorldId(worldId)

    if string.IsNilOrEmpty(moduleId) then
        XLog.Error("当前世界ID没有对应的模块ID! 请检查配置表BigWorldGamePlay.tab WorldId: " .. worldId)
        return
    end

    self._CurrentModuleId = moduleId
end

---@return XBigWorldAgency
function XBigWorldGamePlayAgency:GetCurrentAgency()
    local moduleId
    if self:IsInGame() then
        moduleId = self._CurrentModuleId
    else
        moduleId = ModuleId.XBigWorld
        XLog.Warning("当前不在进入大世界玩法中!")
    end

    if not XMVCA:IsRegisterAgency(moduleId) then
        XMVCA:RegisterAgency(moduleId)
        XMVCA:GetAgency(moduleId):InitDynamicRegister()
    end
    return XMVCA:GetAgency(moduleId)
end

function XBigWorldGamePlayAgency:GetCurrentWorldId()
    if self:IsInGame() then
        if XMVCA.XBigWorldGamePlay:IsInDebugGame() then
            return XMVCA.XBigWorldGamePlay:GetDebugWorldId()
        else
            return self._Model:GetCurrentWorldId()
        end
    end

    XLog.Error("当前不在进入大世界玩法中!")

    return 0
end

function XBigWorldGamePlayAgency:GetCurrentLevelId()
    if self:IsInGame() then
        if XMVCA.XBigWorldGamePlay:IsInDebugGame() then
            return XMVCA.XBigWorldGamePlay:GetDebugLevelId()
        else
            return self._Model:GetCurrentLevelId()
        end
    end

    XLog.Error("当前不在进入大世界玩法中!")

    return 0
end

function XBigWorldGamePlayAgency:IsInGame()
    return XTool.IsNumberValid(self._CurrentModuleId)
end

function XBigWorldGamePlayAgency:IsInstLevel()
    local levelId = self:GetCurrentLevelId()
    if not levelId or levelId <= 0 then
        return false
    end
    
    return CS.StatusSyncFight.XLevelConfig.IsInstLevel(levelId)
end

--- 大世界玩法是否开启
---@return boolean
function XBigWorldGamePlayAgency:IsBigWorldOpen()
    return true
end

--region 进入大世界流程

--- 发送进入大世界入口协议
function XBigWorldGamePlayAgency:EnterGame()
    if not self:IsBigWorldOpen() then
        XUiManager.TipText("CommonNotOpen")
        return
    end
    XNetwork.Call("BigWorldEnterWorldRequest", {
        WorldId = 0,
        LevelId = 0,
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local enterData = res.EnterResultData

        if not enterData then
            XLog.Error("EnterResultData is nil, 进入大世界失败!")
            return
        end
        if not enterData.WorldData then
            XLog.Error("WorldData is nil, 进入大世界失败!")
            return
        end

        local worldData = enterData.WorldData
        self:_InitWorldId(worldData.WorldId)
        self:_InitLevelId(worldData.LevelId)
        self:RegisterMVCA()
        self:InitConfig()
        self:LaunchWorld()
        self:PullModuleData(res)
    end)
end

function XBigWorldGamePlayAgency:PullModuleData(response)
    XNetwork.Call("BigWorldOnModuleLoadCompleteRequest", nil, function(res)
        --错误代码
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            self:EnterGameError()
            return
        end
        self._EnterResponse = response
        self:UpdatePlayerData(response.PlayerData)
        self:CsStatusSyncFightInit()

        self:GetCurrentAgency():BeginOpenGuide()
    end, nil, function()
        self:EnterGameError()
    end)
end

function XBigWorldGamePlayAgency:RequestGetEnterBigWorldData(callback)
    if not self:IsInGame() then
        XLog.Error("尚未进入大世界，无法获取玩法数据!")
        return
    end
    XNetwork.Call("BigWorldGetEnterWorldDataRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._EnterResponse = res
        if callback then
            callback()
        end
    end)
end

function XBigWorldGamePlayAgency:EnterGameError()
    --函数异常
    self:DisposeConfig()
    --移除掉MVCA
    self:UnRegisterMVCA()
    self:UnLaunchWorld()
    self:ExitGame()
end

function XBigWorldGamePlayAgency:InitAfterOpenGuide()
    local response = self._EnterResponse

    local enterData = response.EnterResultData
    self:DoWorldSaveRequest(enterData.WorldData, enterData.FightData, enterData.LevelData)
    XMVCA.XBigWorldService:InitQuestItemMap(response.DlcQuestBag)
    self:InitX3C()
    self:InitActivityAgency()
    self:TryExitOpenGuide()
    self._EnterResponse = nil
end

function XBigWorldGamePlayAgency:DoPlayerDataRequest()
    XNetwork.Call("BigWorldPlayerDataRequest", nil, function(res)
        self:UpdatePlayerData(res)
    end)
end

--- 大世界总协议返回后的请求
function XBigWorldGamePlayAgency:DoWorldSaveRequest(worldData, fightData, levelData)
    local worldId = self:GetCurrentWorldId()

    self:RegisterWorldSaveDataRequest(worldData, fightData, levelData)
    CS.StatusSyncFight.XWorldSaveSystem.RequestWorldSave(worldId)
end

function XBigWorldGamePlayAgency:DoQuestBagRequest()
    -- 背包数据
    XNetwork.Call("DlcQuestBagRequest", nil, function(res)
        XMVCA.XBigWorldService:InitQuestItemMap(res.DlcQuestBag)
    end)
end

--- 正式进入到大世界
function XBigWorldGamePlayAgency:DoEnterGame(worldData, fightData, levelData)
    if not fightData or not levelData then
        XLog.Error("fightData or levelData is nil, 进入大世界失败!")
        return
    end

    -- 初始化战斗
    --self:CsStatusSyncFightInit()
    -- 设置当前大世界类型
    self:InitCurrentBigWorldType()
    -- 对应大世界执行进入战斗前逻辑
    self:GetCurrentAgency():BeforeEnterGame()
    -- 进入战斗
    self:CsStatusSyncEnterFight(worldData, fightData, levelData, XPlayer.Id)
    -- 进入战斗前会清理掉系统行为树数据
    XMVCA.XDlcWorld:OnEnterFight(self:GetCurrentWorldId())
    -- 在这里加载大世界引导数据
    self:LoadGuide()
    --首次进入战斗会有黑幕进行开场引导，这里尝试关闭
    XMVCA.XBigWorldUI:SafeClose("UiBigWorldBlackMaskNormal")
    -- 对应大世界执行进入战斗后逻辑
    self:GetCurrentAgency():AfterEnterGame()
end

--- 退出大世界
function XBigWorldGamePlayAgency:ExitGame()
    if not self:IsInGame() then
        return
    end

    --退出玩法前，先将相关界面全部关闭
    self:ClearBigWorldUI(function()
        self:CsStatusSyncExitFight()
        self:GetCurrentAgency():Exit()
    end)
end

--- 战斗事件通知，进入战斗（已经进入）
function XBigWorldGamePlayAgency:OnEventEnterFight()
    if not self:IsInGame() then
        return
    end
    self:GetCurrentAgency():EnterFight()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_ENTER_GAME)
end

--- 战斗事件通知，退出战斗
function XBigWorldGamePlayAgency:OnEventExitFight()
    --战斗事件通知的退出战斗，如果此时已经登出了，则不通过事件去清除数据
    --会在登出时调用 OnExitFight
    --否则会出现，界面还引用control,但是已经去释放Agency了
    if not XLoginManager.IsLogin() then
        return
    end
    self:OnExitFight()
end

function XBigWorldGamePlayAgency:OnExitFight()
    if not self:IsInGame() then
        return
    end
    self:GetCurrentAgency():ExitFight()
end

function XBigWorldGamePlayAgency:CompletelyExit()
    if not self:IsInGame() then
        return
    end
    self:RequestRefreshBigWorldMainRedPoint()
    self._Camera = false
    self:DeinitCurrentBigWorldType()
    self:ClearX3C()
    self:ClearActivityAgency()
    self:ClearDebugState()
    self._Model:Clear()
    CS.StatusSyncFight.XWorldSaveSystem.Cleanup()
    self:UnloadGuide()
    self:TryExitOpenGuide()
    self:DisposeConfig()
    self:UnLaunchWorld()
    self:UnRegisterMVCA()
    XMVCA:ReleaseModule(self._CurrentModuleId)
    self._CurrentModuleId = 0
end

--- 注册玩家进入DlcWorld时，服务器返回消息的回调
function XBigWorldGamePlayAgency:RegisterWorldSaveDataRequest(worldData, fightData, levelData)
    self._OnReceivedWorldSaveDataCb = function(worldSaveData)
        self:UpdateWorldData(worldSaveData)
        self:DoEnterGame(worldData, fightData, levelData)
        self:UnRegisterWorldSaveDataRequest()
    end

    local CsWorldSystem = CS.StatusSyncFight.XWorldSaveSystem

    if CsWorldSystem.ReceivedWorldSaveDataCb == nil then
        CsWorldSystem.ReceivedWorldSaveDataCb = self._OnReceivedWorldSaveDataCb
    else
        CsWorldSystem.ReceivedWorldSaveDataCb = CsWorldSystem.ReceivedWorldSaveDataCb + self._OnReceivedWorldSaveDataCb
    end
end

--- 取消注册玩家进入DlcWorld时，服务器返回消息的回调
function XBigWorldGamePlayAgency:UnRegisterWorldSaveDataRequest()
    local CsWorldSystem = CS.StatusSyncFight.XWorldSaveSystem
    if CsWorldSystem.ReceivedWorldSaveDataCb == nil then
        return
    end
    if not self._OnReceivedWorldSaveDataCb then
        return
    end
    CsWorldSystem.ReceivedWorldSaveDataCb = CsWorldSystem.ReceivedWorldSaveDataCb - self._OnReceivedWorldSaveDataCb
end

--- 初始化X3C，服务器DlcWorldSaveDataResponse协议返回时调用
function XBigWorldGamePlayAgency:InitX3C()
    if not self:IsInGame() then
        return
    end

    self:ClearX3C()
    self:GetCurrentAgency():InitX3C()
end

function XBigWorldGamePlayAgency:ClearX3C()
    XMVCA.X3CProxy:ClearHandlers()
end

function XBigWorldGamePlayAgency:ClearBigWorldUI(allCloseCb)
    local index = 0
    local runCount = 0
    local onCloseCb
    onCloseCb = function()
        local uiName = CS.XUiManager.Instance:GetTopXUiName(index)
        runCount = runCount + 1
        --正常来说不会超过100个界面，加一层保底
        if string.IsNilOrEmpty(uiName) or runCount > 100 then
            return allCloseCb and allCloseCb()
        end
        ---@type XUiData
        local uiData = CS.XUiManager.Instance:FindUiData(uiName)
        --子界面直接通过关掉父界面处理
        if uiData and uiData.IsChildUi then
            index = index + 1
            return onCloseCb()
        end
        --此界面不关闭
        if ExitIgnoreCloseUiName[uiName] then
            index = index + 1
            return onCloseCb()
        end
        --战斗界面不关闭，交由战斗管理
        if XUiManager.IsFightUi(uiName) then
            index = index + 1
            return onCloseCb()
        end
        XMVCA.XBigWorldUI:Close(uiName, onCloseCb)
    end
    onCloseCb()
end

--- 初始化大世界类型
function XBigWorldGamePlayAgency:InitCurrentBigWorldType()
    local worldId = self:GetCurrentWorldId()
    local worldType = XMVCA.XDlcWorld:GetWorldTypeById(worldId)

    if XTool.IsNumberValid(worldType) then
        CsHelper.SetBigWorldType(worldType)
    else
        XLog.Error("当前WroldId = " .. tostring(worldId) .. "未配置WorldType!")
    end
end

function XBigWorldGamePlayAgency:DeinitCurrentBigWorldType()
    CsHelper.SetBigWorldType(CsHelper.BigWorldType.None)
end

--- 初始化战斗
function XBigWorldGamePlayAgency:CsStatusSyncFightInit()
    CS.StatusSyncFight.XFight.Init()
end

function XBigWorldGamePlayAgency:CsStatusSyncEnterFight(worldData, fightData, levelData, playerId)
    local args = self:CreateClientArgs()
    CS.StatusSyncFight.XFightClient.EnterFight(worldData, fightData, levelData, playerId, args)
end

function XBigWorldGamePlayAgency:CsStatusSyncExitFight()
    CS.StatusSyncFight.XFightClient.RequestExitFight()
end

function XBigWorldGamePlayAgency:IsCurrentNpcSit()
    return CS.StatusSyncFight.XFightClient.IsCurrentNpcSit()
end

function XBigWorldGamePlayAgency:CreateClientArgs()
    if not self._ClientArgs then
        self._ClientArgs = CS.StatusSyncFight.XFightClientArgs()
    end

    self._ClientArgs.LoadProgressCb = Handler(self, self.OnLoadingProgress)
    self._ClientArgs.OpenLoadingUiCb = Handler(self, self.OnOpenLoadingUi)
    self._ClientArgs.CloseLoadingUiCb = Handler(self, self.OnCloseLoadingUi)

    return self._ClientArgs
end

-- 进大世界加载进度
---@param progress number
function XBigWorldGamePlayAgency:OnLoadingProgress(progress)
end

function XBigWorldGamePlayAgency:OnOpenLoadingUi(worldId, levelId, groupId)
    XMVCA.XBigWorldLoading:OpenLoadingByGroupId(groupId)
end

function XBigWorldGamePlayAgency:OnCloseLoadingUi()
    XMVCA.XBigWorldLoading:CloseCurrentLoading()
end

--endregion

--region 玩家数据

--- 更新玩家数据
function XBigWorldGamePlayAgency:UpdatePlayerData(res)
    if not self:IsInGame() then
        return
    end

    self:GetCurrentAgency():UpdatePlayerData(res)
end

--- 更新世界数据
---@param res Protocol.Protocol.Frontend.DlcWorldSaveDataResponse
function XBigWorldGamePlayAgency:UpdateWorldData(res)
    if not self:IsInGame() then
        return
    end
    self:GetCurrentAgency():UpdateWorldData(res)
end

--endregion

--region 关卡切换事件

-- 设置虚拟摄像机
function XBigWorldGamePlayAgency:ActivateVCamera(VCameraName, Duration, DeactivateAllPreVCam, DepthOfFieldId)
    if string.IsNilOrEmpty(VCameraName) then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_ACTIVATE_VIRTUAL_CAMERA, {
        VCameraName = VCameraName,
        Duration = Duration or 0,
        DeactivateAllPreVCam = DeactivateAllPreVCam or false,
        DepthOfFieldId = DepthOfFieldId or 0,
    })
end

-- 取消设置虚拟摄像机（看看后面玩法是不是通用的，玩法主界面关闭后设置回去）
function XBigWorldGamePlayAgency:DeactivateVCamera(VCameraName, IsIgnoreBlendOut)
    if string.IsNilOrEmpty(VCameraName) then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_DEACTIVATE_VIRTUAL_CAMERA, {
        VCameraName = VCameraName,
        IsIgnoreBlendOut = IsIgnoreBlendOut or false,
    })
end

-- 设置相机投影模式
function XBigWorldGamePlayAgency:SetCameraProjection(isOrthographic)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_SET_CAMERA_PROJECTION_MODE, {
        IsOrthographic = isOrthographic,
    })
end

--设置相机物理模式
function XBigWorldGamePlayAgency:SetCameraPhysicalMode(IsPhysical, GateFitMode)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_SET_CAMERA_PHYSICAL_MODE, {
        IsPhysical = IsPhysical,
        GateFitMode = GateFitMode,
    })
end

--- 设置当前NPC的显隐
---@param npcActive boolean 显示/隐藏
---@param includeAssist boolean 是否包含跟随物体
function XBigWorldGamePlayAgency:SetCurNpcActive(npcActive)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SET_CUR_NPC_ACTIVE, { IsActive = npcActive, })
end

--- 获取当前NPC的显隐
function XBigWorldGamePlayAgency:GetCurNpcActive()
    local t = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_CUR_NPC_ACTIVE)
    return t.IsActive
end

--- 设置除了当前编队NPC和跟随的Npc之外的显隐
---@param IsActive boolean 显示/隐藏
function XBigWorldGamePlayAgency:SetNpcActiveExcludePlayerNpc(IsActive)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SET_NPC_ACTIVE_EXCLUDE_PLAYER_NPC, {
        IsActive = IsActive,
    })
end

-- 玩法主界面打开 (C# => Lua)
function XBigWorldGamePlayAgency:OnOpenMainUi(data)
    local id = data and data.BigWorldActivityId or 0
    if id and id > 0 then
        local agency = self:GetActivityAgencyById(id)
        if agency and agency:CheckFunctionOpen() then
            local config = agency:GetConfig()
            self:ActivateVCamera(config.VirtureCamera, config.CameraDuration, false, config.CamDepthOfFieldId)
            agency:OpenMainUi(id, data.Args)
        end
    end
end

--- DLC战斗进入关卡 (C# => Lua)
function XBigWorldGamePlayAgency:OnEnterLevel(data)
    local levelId = data.LevelId
    local agency = self:GetActivityAgencyByLevelId(levelId, true)
    if agency and agency:CheckFunctionOpen() then
        agency:OnEnterLevel()
    end
    self._Model:SetCurrentLevelId(levelId)
    self:GetCurrentAgency():EnterLevel(levelId)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_ENTER_LEVEL, levelId)
end

--- DLC战斗离开关卡 (C# => Lua)
function XBigWorldGamePlayAgency:OnLeaveLevel(data)
    local levelId = data.LevelId
    local agency = self:GetActivityAgencyByLevelId(levelId, true)
    if agency then
        agency:OnLeaveLevel()
    end

    self._Camera = false
    self:GetCurrentAgency():LeaveLevel(levelId)

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEAVE_LEVEL, levelId)
end

--- DLC战斗开始更新关卡 (C# => Lua)
function XBigWorldGamePlayAgency:OnLevelBeginUpdate()
    local levelId = self._Model:GetCurrentLevelId()
    local agency = self:GetActivityAgencyByLevelId(levelId, true)
    if agency then
        agency:OnLevelBeginUpdate()
    end
    self:GetCurrentAgency():LevelBeginUpdate(levelId)
    self:SetFightPerspective(self:GetCurrentAgency():GetPerspective(self:GetCurrentLevelId()), false)
    XMVCA.XBigWorldQuest:DoLevelChangeComplete()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, levelId)
end

--endregion

--region 战斗暂停&输入&战斗UI隐藏 相关

function XBigWorldGamePlayAgency:PauseFight()
    if CS.StatusSyncFight.XFightClient.FightInstance then
        -- 战斗端有引用计数，只需要保持成对调用即可！
        CS.StatusSyncFight.XFightClient.FightInstance:OnPauseForClient()
    end
end

function XBigWorldGamePlayAgency:ResumeFight()
    if CS.StatusSyncFight.XFightClient.FightInstance then
        -- 战斗端有引用计数，只需要保持成对调用即可！
        CS.StatusSyncFight.XFightClient.FightInstance:OnResumeForClient()
    end
end

function XBigWorldGamePlayAgency:ChangeFightInput()
    if not self:IsInGame() then
        return
    end
    self:GetCurrentAgency():OnInputMapResume()
    self:TrySetControlCameraByDrag(false)
end

function XBigWorldGamePlayAgency:ChangeSystemInput()
    if not self:IsInGame() then
        return
    end
    self:GetCurrentAgency():OnInputMapChanged(CS.XInputMapId.SkyGardenSystem)
    self:TrySetControlCameraByDrag(true)
end

function XBigWorldGamePlayAgency:TrySetControlCameraByDrag(value)
    if CS.StatusSyncFight.XFightClient.FightInstance == nil then
        return
    end
    CS.StatusSyncFight.XFightClient.SetControlCameraByDrag(value)
end

function XBigWorldGamePlayAgency:SetFightUiActive(isActive)
    XLuaUiManager.SetUiActive("UiFightDLC", isActive)
end

function XBigWorldGamePlayAgency:OnFightUiDisable(data)
    if not data then
        return
    end
    local name = data.UiName
    self._MarkUiName[name] = true
    self:GetCurrentAgency():SetHudActive(false)
end

function XBigWorldGamePlayAgency:OnFightUiEnable(data)
    if not data then
        return
    end

    local name = data.UiName
    self._MarkUiName[name] = nil
    if XTool.IsTableEmpty(self._MarkUiName) then
        self:GetCurrentAgency():SetHudActive(true)
    end
end

--- 获取战斗的相机
---@return UnityEngine.Camera
function XBigWorldGamePlayAgency:GetCamera()
    if self._Camera then
        return self._Camera
    end
    -- 获取到相机
    local transform = CS.StatusSyncFight.XFightClient.GetCameraTransform()
    if not transform then
        XLog.Error("获取相机时机错误，请在关卡初始化完成后再获取！")
        return
    end
    self._Camera = transform:GetComponent("Camera")
    if not self._Camera then
        XLog.Error("节点不存在相机组件! " .. transform.gameObject.name)
        return
    end

    return self._Camera
end

--- 设置UiObj映射3DObj
---@param uiTransform UnityEngine.RectTransform ui节点
---@param objTransform UnityEngine.Transform 场景节点
---@param offset UnityEngine.Vector2 偏移量
---@param pivot UnityEngine.Vector2 ui父节点的锚点
function XBigWorldGamePlayAgency:SetViewPosToTransformLocalPosition(uiTransform, objTransform, offset, pivot)
    local camera = self._Camera
    if not camera then
        camera = self:GetCamera()
        if not camera then
            return
        end
    end
    if XTool.UObjIsNil(uiTransform) or XTool.UObjIsNil(objTransform) then
        return
    end
    CsSetViewPosToTransformLocalPosition(camera, uiTransform, objTransform, offset, pivot, 120, true)
end

function XBigWorldGamePlayAgency:SetFightPerspective(perspective, needTips)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SET_PLAYER_FIRST_PERSON_MODE, {
        IsFirstPersonMode = perspective == XMVCA.XBigWorldGamePlay.PerspectiveType.FirstPerson,
        NeedTips = needTips or false,
    })
end

--- 获取战斗视角状态
---@return boolean, boolean 是否第一人称, 当前第一人称状态
function XBigWorldGamePlayAgency:GetFightPerspectiveState()
    local result = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_PLAYER_FIRST_PERSON_MODE_AND_STATE)
    if not result then
        return false, false
    end
    return result.IsFirstPersonMode, result.CurFirstPersonState
end

function XBigWorldGamePlayAgency:OnFightGetPerspectiveState(data)
    local first = XMVCA.XBigWorldGamePlay.PerspectiveType.FirstPerson
    local levelId
    if not data then
        XLog.Error("OnFightGetPerspectiveState data is nil")
        levelId = self:GetCurrentLevelId()
        return {
            IsFirstPersonMode = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetPerspective(levelId)
                    == XMVCA.XBigWorldGamePlay.PerspectiveType.FirstPerson,
            HasData = self:GetCurrentAgency():IsSavePerspective(levelId),
        }
    else
        levelId = data.LevelId
    end
    local isFirstPersonMode = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetPerspective(levelId) == first
    
    return {
        IsFirstPersonMode = isFirstPersonMode,
        HasData = self:GetCurrentAgency():IsSavePerspective(levelId),
    }
end

function XBigWorldGamePlayAgency:OnPerspectiveModeChanged(data)
    if not data then
        XLog.Error("OnSetFirstPersonMode data is nil")
        return
    end
    local success, isFirst, levelId = data.IsSuccess, data.IsFirstPersonMode, data.LevelId
    
    if not levelId or levelId <= 0 then
        XLog.Error("OnSetFirstPersonMode levelId is invalid: " .. tostring(levelId))
        return
    end
    if success then
        local perspective = isFirst and XMVCA.XBigWorldGamePlay.PerspectiveType.FirstPerson or XMVCA.XBigWorldGamePlay.PerspectiveType.ThirdPerson
        self:SavePerspectiveRequest(levelId, perspective)
    end
end

--endregion

--region Private

function XBigWorldGamePlayAgency:_InitWorldId(worldId)
    self._Model:SetCurrentWorldId(worldId)
    self:SetCurrentGameAgency(worldId)
end

function XBigWorldGamePlayAgency:_InitLevelId(levelId)
    self._Model:SetCurrentLevelId(levelId)
end

function XBigWorldGamePlayAgency:LaunchWorld()
    CS.XWorldEngine.Launch()
end

function XBigWorldGamePlayAgency:UnLaunchWorld()
    CS.XWorldEngine.Exit()
end

function XBigWorldGamePlayAgency:InitConfig()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:InitConfig()
end

function XBigWorldGamePlayAgency:DisposeConfig()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:DisposeConfig()
end

function XBigWorldGamePlayAgency:RegisterMVCA()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:DoRegisterMVCA()
end

function XBigWorldGamePlayAgency:UnRegisterMVCA()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:DoUnRegisterMVCA()
end

function XBigWorldGamePlayAgency:LoadGuide()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:LoadGuide()
end

function XBigWorldGamePlayAgency:UnloadGuide()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:UnloadGuide()
end

function XBigWorldGamePlayAgency:TryExitOpenGuide()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:TryExitOpenGuide()
end

function XBigWorldGamePlayAgency:TryActiveGuide()
    XDataCenter.GuideManager.CheckGuideOpen()
end

--endregion

--region 协议请求

function XBigWorldGamePlayAgency:RequestEnterInstLevel(worldId, levelId, team, targetPos, targetRot, resultHandle)
    XNetwork.Call("EnterInstLevelRequest", {
        WorldId = worldId,
        InstLevelId = levelId,
        Team = team,
        TargetPos = targetPos,
        TargetRot = targetRot,
    }, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XBigWorldUI:TipCode(res.Code)
            return
        end

        if resultHandle then
            resultHandle(res.EnterResultData)
        end
    end)
end

function XBigWorldGamePlayAgency:RequestLeaveInstLevel(saveOption, callback)
    XNetwork.Call("LeaveInstLevelRequest", {
        InstSaveOption = saveOption or XMVCA.XBigWorldInstance.LevelSaveOption.None,
    }, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XBigWorldUI:TipCode(res.Code)
            return
        end

        if callback then
            callback()
        end
    end)
end

function XBigWorldGamePlayAgency:RequestAgainChallengeInst(callback)
    XNetwork.Call("DlcReChallengeInstRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XBigWorldUI:TipCode(res.Code)
            return
        end

        if callback then
            callback()
        end
    end)
end

function XBigWorldGamePlayAgency:SavePerspectiveRequest(levelId, perspectiveId, func)
    local groupId = self:GetCurrentAgency():GetPerspectiveGroupId(levelId)
    local req = {
        FovType = perspectiveId,
        FovGroupId = groupId
    }
    local now = XTime.GetServerNowTimestamp()
    --只管发，不管返回
    self:GetCurrentAgency():UpdatePerspective(groupId, perspectiveId)
    --增加CD，避免频繁请求，如果多次请求，取最后一次，如果最后一次没有请求成功，则不更新（策划接受）
    if now - LastRequestSavePerspectiveTime < SavePerspectiveInterval then
        return
    end

    XNetwork.Call("BigWorldSaveFovDataRequest", req, function(res)
        LastRequestSavePerspectiveTime = now
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        if func then
            func()
        end
    end, nil, nil, nil, true)
end

--endregion

--region 活动数据

--- 注册活动Agency
---@param agency XBigWorldActivityAgency
--------------------------
function XBigWorldGamePlayAgency:RegisterActivityAgency(agency)
    if IsWindowsEditor then
        if not CheckClassSuper(agency, XBigWorldActivityAgency) then
            XLog.Error(string.format("%s Agency 需要继承 XBigWorldActivityAgency", agency:GetId()))
            return
        end
    end
    local id = agency:GetActivityId()
    if id and id > 0 then
        self._ActivityAgency[id] = agency
    end
    local levelId = agency:GetLevelId()
    if levelId and levelId > 0 then
        self._Level2Agency[levelId] = agency
    end
end

function XBigWorldGamePlayAgency:InitActivityAgency()
    local templates = self._Model:GetAllActivityTemplates()
    for _, t in pairs(templates) do
        local moduleId = t.ModuleId
        if moduleId then
            ---@type XBigWorldActivityAgency
            local agency = XMVCA:GetAgency(moduleId)
            agency:SetConfig(t)
            agency:RegisterActivityAgency()
        else
            XLog.Error(string.format("活动：%s 未找到对应模块", t.Id))
        end
    end
end

function XBigWorldGamePlayAgency:ClearActivityAgency()
    self._ActivityAgency = {}
    self._Level2Agency = {}
end

---@return XBigWorldActivityAgency
function XBigWorldGamePlayAgency:GetActivityAgencyById(id)
    local agency = self._ActivityAgency[id]
    if not agency then
        XLog.Error("尚未注册活动Agency!, Id = " .. id)
        return
    end
    return agency
end

function XBigWorldGamePlayAgency:GetActivityAgencyByLevelId(levelId, noTips)
    local agency = self._Level2Agency[levelId]
    if not agency and not noTips then
        XLog.Error("尚未注册活动Agency!, LevelId = " .. levelId)
        return
    end
    return agency
end

--endregion

--region X3C

function XBigWorldGamePlayAgency:CmdRequestEnterInstLevel(data)
    local worldId = data.WorldId or 0
    local levelId = data.InstLevelId
    local team = data.Team
    local targetPos = data.TargetPos
    local targetRot = data.TargetRot

    if not team then
        local currentTeam = XMVCA.XBigWorldCharacter:GetCurrentTeam()

        team = currentTeam:ToServerTeam()
    end

    self:RequestEnterInstLevel(worldId, levelId, team, targetPos, targetRot)
end

function XBigWorldGamePlayAgency:CmdRequestLeaveInstLevel(data)
    self:RequestLeaveInstLevel(data.ResetSaveDataExit or false)
end

--endregion

--region 红点

function XBigWorldGamePlayAgency:NotifyBigWorldMainRedPoint(data)
    self._Model:UpdateEntranceRedPoint(data)
end

function XBigWorldGamePlayAgency:RequestRefreshBigWorldMainRedPoint()
    if not XLoginManager.IsLogin() then
        return
    end
    local worldId = self:GetCurrentWorldId()
    if not worldId or worldId <= 0 then
        return
    end
    local sysModuleId = self._Model:GetSystemModuleId(worldId)
    if not sysModuleId or sysModuleId <= 0 then
        XLog.Error("红点更新失败!!!")
        return
    end
    XNetwork.Call("BigWorldCheckIsShowMainRedPointRequest", { SysModuleId = sysModuleId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
    end)
end

--- 检车空花入口蓝点, 由于未进入空花，所以没有对应的Module初始化，只能封装到不同接口里
---@return boolean
function XBigWorldGamePlayAgency:CheckSkyGardenEntranceRedPoint()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SkyGarden, false, true) then
        return false
    end
    return self._Model:CheckSkyGardenEntranceRedPoint()
end

function XBigWorldGamePlayAgency:MarkSkyGardenEntryRedPoint()
    self._Model:MarkSkyGardenEntryRedPoint()
end

--endregion

--region 开场引导
function XBigWorldGamePlayAgency:GetSkyGardenOpenGuideIdList()
    return self._Model:GetSkyGardenOpenGuideIdList()
end
--endregion

--- 获取大世界活动物品通过活动id
---@param activityId number
---@return table
function XBigWorldGamePlayAgency:GetBigWorldActivityGoodsByActivityId(activityId)
    return self._Model:GetBigWorldActivityGoodsByActivityId(activityId)
end

--- 获取活动物品通过展示组id
---@param groupId number
---@return table
function XBigWorldGamePlayAgency:GetBigWorldGoodsByGroupId(groupId)
    return self._Model:GetBigWorldGoodsByGroupId(groupId)
end

--region Debug/黑幕进战斗

function XBigWorldGamePlayAgency:IsInDebugGame()
    return self._IsInDebugGame
end

function XBigWorldGamePlayAgency:GetDebugWorldId()
    return self._DebugWorldId
end

function XBigWorldGamePlayAgency:GetDebugLevelId()
    return self._DebugLevelId
end

function XBigWorldGamePlayAgency:EnterDebugGame(worldId, levelId)
    self._IsInDebugGame = true
    self._DebugWorldId = worldId
    self._DebugLevelId = levelId
    self._CurrentModuleId = ModuleId.XBigWorld
    self:RegisterMVCA()
    self:LoadGuide()

    self:InitX3C()
    self:InitConfig()
    self:LaunchWorld()
    self:GetCurrentAgency():BeforeEnterGame()
    XMVCA.XDlcWorld:OnEnterFight(self:GetCurrentWorldId())
    self:GetCurrentAgency():AfterEnterGame()
end

function XBigWorldGamePlayAgency:ClearDebugState()
    self._DebugLevelId = nil
    self._DebugWorldId = nil
    self._IsInDebugGame = nil
end

function XBigWorldGamePlayAgency.DebugEnter(worldId, levelId)
    XMVCA.XBigWorldGamePlay:EnterDebugGame(worldId, levelId)
end

function XBigWorldGamePlayAgency.InDebugGame()
    return XMVCA.XBigWorldGamePlay:IsInDebugGame()
end

function XBigWorldGamePlayAgency.SetDisableOpenGuide(value)
    if not XMain.IsEditorDebug then
        return
    end
    DisableOpenGuide = value
    XSaveTool.SaveData(LocalKey, value)
end

function XBigWorldGamePlayAgency.IsDisableOpenGuide()
    return DisableOpenGuide
end

function XBigWorldGamePlayAgency.CheckOpenGuideDisable()
    if not XMain.IsEditorDebug then
        DisableOpenGuide = false
    else
        DisableOpenGuide = XSaveTool.GetData(LocalKey)
    end
end

--endregion

return XBigWorldGamePlayAgency
