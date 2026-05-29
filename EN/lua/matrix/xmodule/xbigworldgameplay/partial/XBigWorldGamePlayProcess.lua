---@type XBigWorldHelper
local CsHelper = CS.XBigWorldHelper

local XMipStreamingManager = require("XManager/XMipStreamingManager")

---@type XBigWorldGamePlayAgency 战斗流程管理
local XBigWorldGamePlayAgency = XClassPartial("XBigWorldGamePlayAgency")


--- 进入世界
---@param worldId number 世界id
---@param levelId number 关卡id
---@param enterOp number 进入操作
---@param enterParam number 进入操作的参数
--------------------------
function XBigWorldGamePlayAgency:EnterWorld(worldId, levelId, enterOp, enterParam)
    worldId = worldId or 0
    levelId = levelId or 0
    if self:IsInGame() then
        if self:GetCurrentWorldId() == worldId and self:GetCurrentLevelId() == levelId then
            XLog.Warning(string.format("当前已经在世界[%d]关卡[%d]中", worldId, levelId))
            return
        end
    end
    self._EnterOperate = enterOp
    self._EnterOpParam = enterParam
    XNetwork.Call("BigWorldEnterWorldRequest", {
        WorldId = worldId,
        LevelId = levelId,
    }, self._OnEnterWorldResponse)
end

--- 进入大世界协议回调
---@param response --Protocol.Protocol.Frontend.BigWorldEnterWorldResponse
--------------------------
function XBigWorldGamePlayAgency:OnEnterWorldResponse(response)
    if response.Code ~= XCode.Success then
        XUiManager.TipCode(response.Code)
        return
    end
    
    local enterResultData = response.EnterResultData
    if not enterResultData then
        XLog.Error("EnterResultData is nil, 进入大世界失败!")
        return
    end
    local worldData = enterResultData.WorldData
    if not worldData then
        XLog.Error("WorldData is nil, 进入大世界失败!")
        return
    end
    self._EnterWorldResponseData = response
    --初始化世界id和关卡id
    local worldId, levelId = worldData.WorldId, worldData.LevelId
    self:_InitWorldId(worldId)
    self:_InitLevelId(levelId)
    self:_InitMVCA()
    self:_InitConfig()
    self:_InitWorld()
    self:_InitBigWorldType()
    self:_InitGamePlayState()
    self:RequestOnModuleLoadComplete()
end

--- 模块加载完成后再请求系统数据
--------------------------
function XBigWorldGamePlayAgency:RequestOnModuleLoadComplete()
    XNetwork.Call("BigWorldOnModuleLoadCompleteRequest", nil, 
            self._OnModuleLoadComplete, nil, self._OnEnterWorldFailure)
end

--- 模块加载完成后再请求系统数据回调
---@param response --Protocol.Protocol.Frontend.BigWorldOnModuleLoadCompleteResponse
--------------------------
function XBigWorldGamePlayAgency:OnModuleLoadComplete(response)
    if response.Code ~= XCode.Success then
        XUiManager.TipCode(response.Code)
        self:DoEnterWorldFailure()
        return
    end
    --更新玩家数据
    self:UpdatePlayerData(self._EnterWorldResponseData.PlayerData)
    -- 加载大世界引导数据，第一次进入DIY时还未进入战斗，所以提前加载
    self:_LoadGuide()
    XMVCA.XBigWorldService:InitQuestItemMap(self._EnterWorldResponseData.DlcQuestBag)
    --初始化战斗
    CS.StatusSyncFight.XFight.Init()
    --触发当前大世界开场引导
    self:GetCurrentAgency():BeginOpenGuide()
    --添加进入操作
    XMVCA.XBigWorldFunction:AddEnterOperate(self._EnterOperate, self._EnterOpParam)
    self._EnterOperate = nil
    self._EnterOpParam = nil
end

--- 退出大世界
--------------------------
function XBigWorldGamePlayAgency:ExitWorld()
    if not self:IsInGame() then
        return
    end
    self:_DisposeX3C()

    XMVCA.XBigWorldUI:ClearBigWorldUI()
    --退出战斗
    CS.StatusSyncFight.XFightClient.RequestExitFight()
    --退出当前大世界
    self:GetCurrentAgency():Exit()
    CS.XProfilingLuaUtils.PerfSightRegionExit()
end

--- 更新进入大世界玩法数据
---@param callback function 协议回调
--------------------------
function XBigWorldGamePlayAgency:RequestGetEnterBigWorldData(callback)
    if not self:IsInGame() then
        XLog.Error("请先进入玩法，再请求更新数据！")
        return
    end
    XNetwork.Call("BigWorldGetEnterWorldDataRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._EnterWorldResponseData = res
        if callback then
            callback()
        end
    end)
end

---进入大世界失败
--------------------------
function XBigWorldGamePlayAgency:DoEnterWorldFailure()
    if not self:IsInGame() then
        return
    end
    --销毁配置
    self:_DisposeConfig()
    --取消注册MVCA
    self:_DisposeMVCA()
    --卸载世界
    self:_DisposeWorld()
    --退出世界
    self:ExitWorld()
end

--- 进入战斗
--------------------------
function XBigWorldGamePlayAgency:EnterFight()
    local response = self._EnterWorldResponseData
    local enterResultData = response.EnterResultData
    if not enterResultData then
        XLog.Error("enterResultData is nil, 进入大世界失败!")
        return
    end
    CS.XProfilingLuaUtils.PerfSightRegionEnter("SkyGardenProcess")
    
    local worldData, fightData, levelData = enterResultData.WorldData, enterResultData.FightData, enterResultData.LevelData
    -- 对应大世界执行进入战斗前逻辑
    self:GetCurrentAgency():BeforeEnterGame()
    -- 通知进入战斗前
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BEFORE_ENTER_GAME)
    -- 实际进入战斗
    local args = self:CreateClientArgs()
    CS.StatusSyncFight.XFightClient.EnterFight(worldData, fightData, levelData, XPlayer.Id, args)
    -- 进入战斗前会清理掉系统行为树数据
    XMVCA.XDlcWorld:OnEnterFight(self:GetCurrentWorldId())
    --首次进入战斗会有黑幕进行开场引导，这里尝试关闭
    XMVCA.XBigWorldUI:SafeClose("UiBigWorldBlackMaskNormal")
    -- 对应大世界执行进入战斗后逻辑
    self:GetCurrentAgency():AfterEnterGame()
    --置空数据
    self._EnterWorldResponseData = nil
end

--- 退出战斗
--------------------------
function XBigWorldGamePlayAgency:ExitFight()
    if not self:IsInGame() then
        return
    end
    self:GetCurrentAgency():ExitFight()
    --退出前请求红点
    self:RequestRefreshBigWorldMainRedPoint()
    self:_DisposeBigWorldType()
    self:_DisposeGamePlayState()
    self:_DisposeX3C()
    CS.StatusSyncFight.XWorldSaveSystem.Cleanup()
    self:_UnloadGuide()
    self:_DisposeOpenGuide()
    self:_DisposeConfig()
    self:_DisposeWorld()
    self:_DisposeMVCA()
    --清理掉数据
    self:_DisposeTempVar()
    --关闭流式纹理
    XMipStreamingManager.ExitBigWorld()
end

--- 登出/强制清理：无论当前是否 InGame，都把大世界相关标记位复位、卸载相关资源
--- 由 XLoginManager.ClearGame 调用
--------------------------
function XBigWorldGamePlayAgency:ClearGame()
    if self:IsInGame() then
        self:ExitFight()
    else
        self:_DisposeMVCA()
        XMipStreamingManager.ExitBigWorld()
    end
end

function XBigWorldGamePlayAgency:ExitDlcFightAndEnterFubenFight()
    self:GetCurrentAgency():ExitFight()
    --退出前请求红点
    self:RequestRefreshBigWorldMainRedPoint()
    self:_DisposeBigWorldType()
    self:_DisposeX3C()
    CS.StatusSyncFight.XWorldSaveSystem.Cleanup()
    self:_UnloadGuide()
    self:_DisposeOpenGuide()
    self:_DisposeConfig()
    self:_DisposeWorld()
    --因为打开fuben战斗的时候会卸载空花，但是Control还在被持有，不可以卸载
    -- self:_DisposeMVCA()
    --清理掉数据
    self:_DisposeTempVar()

    --关闭流式纹理
    XMipStreamingManager.ExitBigWorld()
end

--- 战斗事件通知，进入战斗（已经进入）
function XBigWorldGamePlayAgency:OnEventEnterFight()
    if not self:IsInGame() then
        return
    end
    self:GetCurrentAgency():EnterFight()
    -- 通知进入大世界
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_AFTER_ENTER_GAME)
    --开启流式纹理
    XMipStreamingManager.EnterBigWorld()
end

--- 大世界内关卡切换（如传送出/入法奥斯）时同步流式纹理 / LOD mesh 状态
--- 由 EVENT_FIGHT_ENTER_LEVEL 触发；levelId 已写入 Model，IsInFaos() 返回新值
function XBigWorldGamePlayAgency:_RefreshStreamingOnLevelEnter()
    XMipStreamingManager.Refresh()
end

--- 战斗事件通知，退出战斗
function XBigWorldGamePlayAgency:OnEventExitFight()
    --战斗事件通知的退出战斗，如果此时已经登出了，则不通过事件去清除数据
    --会在登出时调用 OnExitFight
    --否则会出现，界面还引用control,但是已经去释放Agency了
    if not XLoginManager.IsLogin() then
        return
    end
    if self:_HasGamePlayState(self.BigWorldGamePlayState.InFight) then
        self:ExitDlcFightAndEnterFubenFight()
    else
        self:ExitFight()
    end
end

--- 创建进入战斗的回调参数 
--------------------------
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

--- 战斗打开loading
---@param worldId number 世界Id
---@param levelId number 关卡Id
---@param groupId number 界面组Id
function XBigWorldGamePlayAgency:OnOpenLoadingUi(worldId, levelId, groupId)
    XMVCA.XBigWorldLoading:OpenLoadingByGroupId(groupId)
end

--- 战斗关闭loading
--------------------------
function XBigWorldGamePlayAgency:OnCloseLoadingUi()
    if self:_HasGamePlayState(self.BigWorldGamePlayState.InFight) then
        self:_RemoveGamePlayState(self.BigWorldGamePlayState.InFight)
    end
    XMVCA.XBigWorldLoading:CloseCurrentLoading()
end

--- 开场引导完成
--------------------------
function XBigWorldGamePlayAgency:OnOpenGuideFinished()
    self:RequestFightWorldSave()
    self:_InitX3C()
    self:_InitActivityAgency()
    self:_DisposeOpenGuide()
end

--- 异步退出Dlc战斗
---@param cb function 执行完成时，该协程才算完成 
--------------------------
function XBigWorldGamePlayAgency:DoExitDlcFightAsync(cb)
    if not self:IsInGame() then
        if cb then cb() end
        return
    end
    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_FINISH_SETTLE, self.OnExitFubenFightAndEnterDlcFight, self)
    self:_AddGamePlayState(self.BigWorldGamePlayState.InFight)
    --退出战斗
    CS.StatusSyncFight.XFightClient.RequestExitFight(true)
    while self:IsInGame() do
        asynWaitSecond(0.1)
    end
    if cb then cb() end
end

--- 获取退出Dlc战斗的异步函数
---@return function
--------------------------
function XBigWorldGamePlayAgency:GetExitDlcFightAsyncFunc()
    if not self:IsInGame() then
        return
    end
    return asynTask(function(cb)
        self:DoExitDlcFightAsync(cb)
    end)
end

--- 退出副本战斗，恢复Dlc战斗，策划需要在结算界面关闭时从新进入dlc战斗
--------------------------
function XBigWorldGamePlayAgency:OnExitFubenFightAndEnterDlcFight()
    XEventManager.RemoveEventListener(XEventId.EVENT_FIGHT_FINISH_SETTLE, self.OnExitFubenFightAndEnterDlcFight, self)
    if not self:_HasGamePlayState(self.BigWorldGamePlayState.InFight) then
        return
    end
    --锁住UI自动恢复
    CsXUiManager.Instance:SetRevertAndReleaseLock(true)
    self:EnterWorld()
end

--- 组装数据，发送战斗侧，战斗同步服务器
--------------------------
function XBigWorldGamePlayAgency:RequestFightWorldSave()
    local worldId = self:GetCurrentWorldId()
    
    local worldSystem = CS.StatusSyncFight.XWorldSaveSystem

    if worldSystem.ReceivedWorldSaveDataCb == nil then
        worldSystem.ReceivedWorldSaveDataCb = self._OnReceivedWorldSaveData
    else
        worldSystem.ReceivedWorldSaveDataCb = worldSystem.ReceivedWorldSaveDataCb + self._OnReceivedWorldSaveData
    end
    
    CS.StatusSyncFight.XWorldSaveSystem.RequestWorldSave(worldId)
end 

--- 玩家进入DlcWorld时，服务器返回消息的回调
---@param worldSaveData Protocol.Protocol.Frontend.DlcWorldSaveDataResponse
---@return 
--------------------------
function XBigWorldGamePlayAgency:OnReceivedWorldSaveData(worldSaveData)
    self:UpdateWorldData(worldSaveData)
    self:EnterFight()
    --收到数据后，取消注册
    local worldSystem = CS.StatusSyncFight.XWorldSaveSystem
    if worldSystem.ReceivedWorldSaveDataCb == nil then
        return
    end
    if not self._OnReceivedWorldSaveData then
        return
    end
    worldSystem.ReceivedWorldSaveDataCb = worldSystem.ReceivedWorldSaveDataCb - self._OnReceivedWorldSaveData
end


--region 初始化-销毁

function XBigWorldGamePlayAgency:_InitWorldId(worldId)
    self._Model:SetCurrentWorldId(worldId)
    self:SetCurrentGameAgency(worldId)
end

function XBigWorldGamePlayAgency:_InitLevelId(levelId)
    self._Model:SetCurrentLevelId(levelId)
end

function XBigWorldGamePlayAgency:_InitX3C()
    if not self:IsInGame() then
        return
    end

    self:_DisposeX3C()
    self:GetCurrentAgency():InitX3C()
end

function XBigWorldGamePlayAgency:_DisposeX3C()
    XMVCA.X3CProxy:ClearHandlers()
end

function XBigWorldGamePlayAgency:_InitWorld()
    CS.XWorldEngine.Launch()
end

function XBigWorldGamePlayAgency:_DisposeWorld()
    CS.XWorldEngine.Exit()
end

function XBigWorldGamePlayAgency:_InitConfig()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:InitConfig()
end

function XBigWorldGamePlayAgency:_DisposeConfig()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:DisposeConfig()
end

function XBigWorldGamePlayAgency:_InitMVCA()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:DoRegisterMVCA()
end

function XBigWorldGamePlayAgency:_DisposeMVCA()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:DoUnRegisterMVCA()
end

function XBigWorldGamePlayAgency:_LoadGuide()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:LoadGuide()
end

function XBigWorldGamePlayAgency:_UnloadGuide()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:UnloadGuide()
end

function XBigWorldGamePlayAgency:_DisposeOpenGuide()
    local gameAgency = self:GetCurrentAgency()
    if not gameAgency then
        return
    end
    gameAgency:TryExitOpenGuide()
end

--- 初始化大世界类型
function XBigWorldGamePlayAgency:_InitBigWorldType()
    local worldId = self:GetCurrentWorldId()
    local worldType = XMVCA.XDlcWorld:GetWorldTypeById(worldId)

    if XTool.IsNumberValid(worldType) then
        CsHelper.SetBigWorldType(worldType)
    else
        XLog.Error("当前WorldId = " .. tostring(worldId) .. "未配置WorldType!")
    end
end
function XBigWorldGamePlayAgency:_DisposeBigWorldType()
    CsHelper.SetBigWorldType(CsHelper.BigWorldType.None)
end

function XBigWorldGamePlayAgency:_InitGamePlayState()
    --从战斗切换
    if self:_HasGamePlayState(self.BigWorldGamePlayState.InFight) then
        return
    end
    --进入大世界后切换状态
    self._GamePlayState = self.BigWorldGamePlayState.InBigWorld
end

function XBigWorldGamePlayAgency:_DisposeGamePlayState()
    --退出大世界后切换状态
    self._GamePlayState = self.BigWorldGamePlayState.None
end

function XBigWorldGamePlayAgency:_AddGamePlayState(state)
    --添加大世界游玩状态
    self._GamePlayState = self._GamePlayState | state
end

function XBigWorldGamePlayAgency:_RemoveGamePlayState(state)
    --移除大世界游玩状态
    self._GamePlayState = self._GamePlayState & (~state)
end

function XBigWorldGamePlayAgency:_HasGamePlayState(state)
    return (self._GamePlayState & state) ~= 0
end

function XBigWorldGamePlayAgency:_InitActivityAgency()
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

function XBigWorldGamePlayAgency:_DisposeActivityAgency()
    self._ActivityAgency = {}
    self._Level2Agency = {}
end

function XBigWorldGamePlayAgency:_DisposeTempVar()
    if self:IsInGame() then
        XMVCA:ReleaseModule(self._CurrentModuleId)
    end
    self._Camera = false
    self._CurrentModuleId = false
    self._Model:Clear()
    self:ClearDebugState()

    CS.XTableManager.ReleaseTable()
end

--endregion