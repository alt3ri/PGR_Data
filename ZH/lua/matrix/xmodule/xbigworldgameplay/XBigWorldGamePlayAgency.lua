---@class XBigWorldGamePlayAgency : XAgency
---@field private _Model XBigWorldGamePlayModel
---@field private _Camera UnityEngine.Camera
---@field private _ActivityAgency table<number, XBigWorldActivityAgency> 活动Id -> 活动Agency
---@field private _Level2Agency table<number, XBigWorldActivityAgency> LevelId -> 活动Agency
local XBigWorldGamePlayAgency = XClass(XAgency, "XBigWorldGamePlayAgency", true)

-- 法奥斯关卡 LevelId
XBigWorldGamePlayAgency.FAOS_LEVEL_ID = 6001

--region 部分类
XClassPartialRequire("XModule/XBigWorldGamePlay/Partial/XBigWorldGamePlayProcess", "XBigWorldGamePlayAgency") --流程相关放这里
--endregion

local XBigWorldActivityAgency = require("XModule/XBase/XBigWorldActivityAgency")
local IsWindowsEditor = XMain.IsWindowsEditor

local CsSetViewPosToTransformLocalPosition = CS.XUiHelper.SetViewPosToTransformLocalPosition
local DisableOpenGuide = false
local LocalKey = "BIG_WORLD_OPEN_GUIDE_ENABLE"

local LastRequestSavePerspectiveTime = 0
local SavePerspectiveInterval = 1.2

function XBigWorldGamePlayAgency:OnInit()
    -- 初始化一些变量
    self._ClientArgs = false
    self._CurrentModuleId = false
    -- 场景相机
    self._Camera = false

    self._ActivityAgency = {}
    self._Level2Agency = {}
    self._MarkUiName = {}

    self.PerspectiveType = {
        FirstPerson = 1, --第一人称
        ThirdPerson = 2, --第三人称
    }

    self.BigWorldGamePlayState = {
        None = 1,       --不在大世界中
        InBigWorld = 2, --在大世界中
        InFight = 4,    --在主线战斗中
    }

    self._GamePlayState = self.BigWorldGamePlayState.None
    XMVCA.XBigWorldGamePlay.CheckOpenGuideDisable()
end

function XBigWorldGamePlayAgency:ResetAll()
    self._GamePlayState = self.BigWorldGamePlayState.None
end

function XBigWorldGamePlayAgency:InitRpc()
    self:AddRpc("NotifyBigWorldMainRedPoint", handler(self, self.NotifyBigWorldMainRedPoint))
    self:AddRpc("NotifyExternalRequiredBigWorldPlayerData", handler(self, self.NotifyExternalRequiredBigWorldPlayerData))
    self:AddRpc("NotifyNewEnteredBigWorldId", handler(self, self.NotifyNewEnteredBigWorldId))
end

function XBigWorldGamePlayAgency:InitEvent()
    self._OnEnterWorldResponse = handler(self, self.OnEnterWorldResponse)
    self._OnModuleLoadComplete = handler(self, self.OnModuleLoadComplete)
    self._OnEnterWorldFailure = handler(self, self.DoEnterWorldFailure)
    self._OnReceivedWorldSaveData = handler(self, self.OnReceivedWorldSaveData)
    self._OnEnterFight = Handler(self, self.OnEventEnterFight)
    self._OnExitFight = Handler(self, self.OnEventExitFight)
    self._OnRefreshStreamingOnLevelEnter = handler(self, self._RefreshStreamingOnLevelEnter)

    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DLC_FIGHT_ENTER, self._OnEnterFight)
    CS.XGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFight)

    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_OPEN_GUIDE_FINISH,
        self.OnOpenGuideFinished, self)
    -- 大世界内关卡切换（如传送出/入法奥斯）时同步流式纹理 / LOD mesh 状态
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_ENTER_LEVEL,
        self._OnRefreshStreamingOnLevelEnter)
end

function XBigWorldGamePlayAgency:RemoveEvent()
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_DLC_FIGHT_ENTER, self._OnEnterFight)
    CS.XGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_DLC_FIGHT_EXIT, self._OnExitFight)

    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_OPEN_GUIDE_FINISH,
        self.OnOpenGuideFinished, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_ENTER_LEVEL,
        self._OnRefreshStreamingOnLevelEnter)
end

function XBigWorldGamePlayAgency:SetCurrentGameAgency(worldId)
    local moduleId = self._Model:GetModuleIdByWorldId(worldId)

    if string.IsNilOrEmpty(moduleId) then
        XLog.Error("当前世界ID没有对应的模块ID! 请检查配置表BigWorldGamePlay.tab WorldId: " .. worldId)
        return
    end

    self._CurrentModuleId = moduleId
    XEventManager.DispatchEvent(XEventId.EVENT_BIG_WORLD_GAME_PLAY_CHANGED, moduleId)
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

    -- 纯查询：注册职责归 _InitMVCA / DoRegisterMVCA，避免懒注册副作用绕过 _IsMVCARegistered 状态机
    if not XMVCA:IsRegisterAgency(moduleId) then
        return nil
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
    return self._CurrentModuleId
end

function XBigWorldGamePlayAgency:IsInstLevel()
    local levelId = self:GetCurrentLevelId()
    if not levelId or levelId <= 0 then
        return false
    end

    return CS.StatusSyncFight.XLevelConfig.IsInstLevel(levelId)
end

--- 是否在法奥斯场景
---@return boolean
function XBigWorldGamePlayAgency:IsInFaos()
    if not self:IsInGame() then
        return false
    end
    if not CS.XBigWorldHelper.IsInsideSkyGarden() then
        return false
    end
    return self:GetCurrentLevelId() == self.FAOS_LEVEL_ID
end

--- 大世界玩法是否开启
---@return boolean
function XBigWorldGamePlayAgency:IsBigWorldOpen()
    return true
end

function XBigWorldGamePlayAgency:TryActiveGuide()
    XDataCenter.GuideManager.CheckGuideOpen()
end

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

function XBigWorldGamePlayAgency:IsCurrentNpcSit()
    return CS.StatusSyncFight.XFightClient.IsCurrentNpcSit()
end

--region 进入大世界流程

function XBigWorldGamePlayAgency:ExitGameAsync(cb)
    CS.StatusSyncFight.XFightClient.RequestExitFight()
    local gameAgency = self:GetCurrentAgency()
    if gameAgency then
        gameAgency:Exit()
    end
    local value = true
    while value do
        asynWaitSecond(0.1)
        if not self:IsInGame() then
            value = false
            if cb then cb() end
        end
    end
end

--endregion

--region 玩家数据

--- 更新玩家数据
function XBigWorldGamePlayAgency:UpdatePlayerData(res)
    if not self:IsInGame() then
        return
    end

    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:UpdatePlayerData(res)
end

--- 更新世界数据
---@param res Protocol.Protocol.Frontend.DlcWorldSaveDataResponse
function XBigWorldGamePlayAgency:UpdateWorldData(res)
    if not self:IsInGame() then
        return
    end
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:UpdateWorldData(res)
end

--endregion

--region 关卡切换事件

-- 设置虚拟摄像机
function XBigWorldGamePlayAgency:ActivateVCamera(vCameraName, duration, deactivateAllPreVCam, depthOfFieldId)
    if string.IsNilOrEmpty(vCameraName) then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_ACTIVATE_VIRTUAL_CAMERA, {
        VCameraName = vCameraName,
        Duration = duration or 0,
        DeactivateAllPreVCam = deactivateAllPreVCam or false,
        DepthOfFieldId = depthOfFieldId or 0,
    })
end

-- 取消设置虚拟摄像机（看看后面玩法是不是通用的，玩法主界面关闭后设置回去）
function XBigWorldGamePlayAgency:DeactivateVCamera(vCameraName, isIgnoreBlendOut)
    if string.IsNilOrEmpty(vCameraName) then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_DEACTIVATE_VIRTUAL_CAMERA, {
        VCameraName = vCameraName,
        IsIgnoreBlendOut = isIgnoreBlendOut or false,
    })
end

-- 设置相机投影模式
function XBigWorldGamePlayAgency:SetCameraProjection(isOrthographic)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_SET_CAMERA_PROJECTION_MODE, {
        IsOrthographic = isOrthographic,
    })
end

--设置相机物理模式
function XBigWorldGamePlayAgency:SetCameraPhysicalMode(isPhysical, gateFitMode)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CAMERA_SET_CAMERA_PHYSICAL_MODE, {
        IsPhysical = isPhysical,
        GateFitMode = gateFitMode,
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
---@param isActive boolean 显示/隐藏
function XBigWorldGamePlayAgency:SetNpcActiveExcludePlayerNpc(isActive)
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SET_NPC_ACTIVE_EXCLUDE_PLAYER_NPC, {
        IsActive = isActive,
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
    local gameAgency = self:GetCurrentAgency()
    if gameAgency then
        gameAgency:EnterLevel(levelId)
    end
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
    local gameAgency = self:GetCurrentAgency()
    if gameAgency then
        gameAgency:LeaveLevel(levelId)
    end

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEAVE_LEVEL, levelId)
end

--- DLC战斗开始更新关卡 (C# => Lua)
function XBigWorldGamePlayAgency:OnLevelBeginUpdate()
    local levelId = self._Model:GetCurrentLevelId()
    local agency = self:GetActivityAgencyByLevelId(levelId, true)
    if agency then
        agency:OnLevelBeginUpdate()
    end
    local gameAgency = self:GetCurrentAgency()
    if gameAgency then
        gameAgency:LevelBeginUpdate(levelId)
        self:SetFightPerspective(gameAgency:GetPerspective(self:GetCurrentLevelId()), false)
    end
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
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:OnInputMapResume()
    self:TrySetControlCameraByDrag(false)
end

function XBigWorldGamePlayAgency:ChangeSystemInput()
    if not self:IsInGame() then
        return
    end
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:OnInputMapChanged(CS.XInputMapId.SkyGardenSystem)
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
    local gameAgency = self:GetCurrentAgency()
    if gameAgency then
        gameAgency:SetHudActive(false)
    end
end

function XBigWorldGamePlayAgency:OnFightUiEnable(data)
    if not data then
        return
    end

    local name = data.UiName
    self._MarkUiName[name] = nil
    if XTool.IsTableEmpty(self._MarkUiName) then
        local gameAgency = self:GetCurrentAgency()
        if gameAgency then
            gameAgency:SetHudActive(true)
        end
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
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return {
            IsFirstPersonMode = false,
            HasData = false,
        }
    end
    if not data then
        XLog.Error("OnFightGetPerspectiveState data is nil")
        levelId = self:GetCurrentLevelId()
        return {
            IsFirstPersonMode = gameAgency:GetPerspective(levelId)
                == XMVCA.XBigWorldGamePlay.PerspectiveType.FirstPerson,
            HasData = gameAgency:IsSavePerspective(levelId),
        }
    else
        levelId = data.LevelId
    end
    local isFirstPersonMode = gameAgency:GetPerspective(levelId) == first

    return {
        IsFirstPersonMode = isFirstPersonMode,
        HasData = gameAgency:IsSavePerspective(levelId),
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
        local perspective = isFirst and XMVCA.XBigWorldGamePlay.PerspectiveType.FirstPerson or
        XMVCA.XBigWorldGamePlay.PerspectiveType.ThirdPerson
        self:SavePerspectiveRequest(levelId, perspective)
    end
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
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    local groupId = gameAgency:GetPerspectiveGroupId(levelId)
    local req = {
        FovType = perspectiveId,
        FovGroupId = groupId
    }
    local now = XTime.GetServerNowTimestamp()
    --只管发，不管返回
    gameAgency:UpdatePerspective(groupId, perspectiveId)
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

---@return XBigWorldActivityAgency
function XBigWorldGamePlayAgency:GetActivityAgencyById(id)
    local agency = self._ActivityAgency[id]
    if not agency then
        XLog.Error("尚未注册活动Agency!, Id = " .. id)
        return
    end
    return agency
end

---@return XBigWorldActivityAgency
function XBigWorldGamePlayAgency:GetActivityAgencyByLevelId(levelId, noTips)
    local agency = self._Level2Agency[levelId]
    if not agency and not noTips then
        XLog.Error("尚未注册活动Agency!, LevelId = " .. levelId)
        return
    end
    return agency
end

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

--endregion

--region 红点

function XBigWorldGamePlayAgency:NotifyBigWorldMainRedPoint(data)
    self._Model:UpdateEntranceRedPoint(data)
end

function XBigWorldGamePlayAgency:NotifyExternalRequiredBigWorldPlayerData(data)
    local worldIds
    if data then
        worldIds = data.EnteredBigWorldIds
    end
    self._Model:UpdateEntranceWorldMark(worldIds)

    if data.Gender then
        XMVCA.XBigWorldCommanderDIY:SetCurrentGender(data.Gender)
    end
    if data.CommanderFashionBags then
        XMVCA.XBigWorldCommanderDIY:UpdateUnlockParts(data.CommanderFashionBags)
    end
end

function XBigWorldGamePlayAgency:NotifyNewEnteredBigWorldId(data)
    if not data then
        return
    end
    self._Model:AddEntranceWorldMark(data.WorldId)
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

--- 检车空花入口蓝点, 由于未进入空花，所以没有对应的Module初始化，只能封装到对应世界里
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

function XBigWorldGamePlayAgency:CheckEntryWorld(worldId)
    return self._Model:CheckEntryWorld(worldId)
end

--endregion

--region 开场引导
function XBigWorldGamePlayAgency:GetSkyGardenOpenGuideIdList()
    return self._Model:GetSkyGardenOpenGuideIdList()
end

--endregion

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

function XBigWorldGamePlayAgency:LaunchWorldDebug()
    self._IsInDebugGame = true
    self:_InitWorld()
end

function XBigWorldGamePlayAgency:EnterDebugGame(worldId, levelId)
    self._IsInDebugGame = true
    self._DebugWorldId = worldId
    self._DebugLevelId = levelId
    self._CurrentModuleId = ModuleId.XBigWorld
    XEventManager.DispatchEvent(XEventId.EVENT_BIG_WORLD_GAME_PLAY_CHANGED, ModuleId.XBigWorld)
    self:_InitMVCA()
    self:_LoadGuide()

    self:_InitX3C()
    self:_InitConfig()
    self:_InitWorld()
    local gameAgency = self:GetCurrentAgency()
    if gameAgency then
        gameAgency:BeforeEnterGame()
    end
    XMVCA.XDlcWorld:OnEnterFight(self:GetCurrentWorldId())
    if gameAgency then
        gameAgency:AfterEnterGame()
    end
end

function XBigWorldGamePlayAgency:ClearDebugState()
    self._DebugLevelId = nil
    self._DebugWorldId = nil
    self._IsInDebugGame = nil
end

function XBigWorldGamePlayAgency.DebugEnter(worldId, levelId)
    XMVCA.XBigWorldGamePlay:EnterDebugGame(worldId, levelId)
end

function XBigWorldGamePlayAgency.DebugLaunchWorld()
    XMVCA.XBigWorldGamePlay:LaunchWorldDebug()
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
