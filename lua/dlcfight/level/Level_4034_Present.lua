local XLevel4034Present = XDlcScriptManager.RegLevelPresentScript(4034)

---@param proxy XDlcCSharpFuncs
function XLevel4034Present:Ctor(proxy)
    --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy
end

function XLevel4034Present:Init()
    --初始化逻辑
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectMoveStop)
    --军备区小电梯
    self:InitElevator()

    for i, info in pairs(self._elevatorTrigger2Info) do
        self:TriggerElevatorMove(info)
    end
end

---@param dt number @ delta time
function XLevel4034Present:Update(dt)
    --每帧更新逻辑
end

---@param eventType number
---@param eventArgs userdata
function XLevel4034Present:HandleEvent(eventType, eventArgs)
    --是玩家发起的Trigger
    if eventType == EWorldEvent.ActorTrigger and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
        if eventArgs.TriggerState == ETriggerState.Enter then
            --军备区小电梯呼叫
            self:OnElevatorActorTriggerEnter(eventType, eventArgs)
        end
    end

    --是玩家发起的交互
    if eventType == EWorldEvent.NpcInteractStart and self._proxy:IsPlayerNpc(eventArgs.LauncherId) then
        self:OnElevatorNpcInteractStart(eventType, eventArgs)
    end
    --移动机关停止
    if eventType == EWorldEvent.SceneObjectMoveStop then
        ---小电梯移动解除
        self:OnElevatorSceneObjectMoveStop(eventType, eventArgs)
    end
end

function XLevel4034Present:Terminate()
    --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）
end

--region 军备区小电梯
local ElevatorState = {
    Down = 0,
    Up = 1,
}

function XLevel4034Present:InitElevator()
    ---@type table<number, XElevatorInfo>
    self._elevatorTrigger2Info = {}
    ---@type table<number, XElevatorInfo>
    self._elevatorUpFloorCall2Info = {}
    ---@type table<number, XElevatorInfo>
    self._elevatorDownFloorCall2Info = {}

    self:CreateElevatorInfo(ElevatorState.Down, 1100006, 1100008, 1100009, 4, 1, 2, 2, 1, 1100007)
end

---@return XElevatorInfo
function XLevel4034Present:CreateElevatorInfo(defaultState, triggerPlaceId, callDownPlaceId, callUpPlaceId, moveSpeed, upNodeId, downNodeId, UpOptionId, DownOptionId, AirWallPlaceId)
    ---@type XElevatorInfo
    local info = {}
    info.State = defaultState
    info.ElevatorPlaceId = triggerPlaceId
    info.CallDownPlaceId = callDownPlaceId
    info.CallUpPlaceId = callUpPlaceId
    info.HavePlayerEnterCount = 0
    info.MoveSpeed = moveSpeed
    info.UpNodeId = upNodeId
    info.DownNodeId = downNodeId
    info.UpOptionId = UpOptionId
    info.DownOptionId = DownOptionId
    info.AirWallPlaceId = AirWallPlaceId
    info.Moving = false
    info.CurMoveTargetNodeId = 0

    -- 注册进入字典表
    self._elevatorTrigger2Info[info.ElevatorPlaceId] = info
    self._elevatorUpFloorCall2Info[info.CallDownPlaceId] = info
    self._elevatorDownFloorCall2Info[info.CallUpPlaceId] = info
    self:RefreshElevatorOption(info)
    return info
end

---@param elevatorInfo XElevatorInfo
function XLevel4034Present:RefreshElevatorOption(elevatorInfo)
    if elevatorInfo.State == ElevatorState.Down then
        self._proxy:SetSceneObjectInteractOneOptionActive(elevatorInfo.ElevatorPlaceId, elevatorInfo.DownOptionId)
    end
    if elevatorInfo.State == ElevatorState.Up then
        self._proxy:SetSceneObjectInteractOneOptionActive(elevatorInfo.ElevatorPlaceId, elevatorInfo.UpOptionId)
    end
end

---@param elevatorInfo XElevatorInfo
function XLevel4034Present:TriggerElevatorMove(elevatorInfo)
    if elevatorInfo.State == ElevatorState.Down then
        self:StartElevatorMove(elevatorInfo, elevatorInfo.UpNodeId)
    elseif elevatorInfo.State == ElevatorState.Up then
        self:StartElevatorMove(elevatorInfo, elevatorInfo.DownNodeId)
    end
end

---@param elevatorInfo XElevatorInfo
function XLevel4034Present:StartElevatorMove(elevatorInfo, targetMoveNodeId)
    if elevatorInfo.Moving then
        return
    end
    self._proxy:LoadSceneObject(elevatorInfo.AirWallPlaceId)
    self._proxy:MoveSceneObjectToNode(elevatorInfo.ElevatorPlaceId, targetMoveNodeId, elevatorInfo.MoveSpeed)
    self._proxy:PlaySound(5500112, ETargetActorType.SceneObject, self._proxy:GetSceneObjectUUID(elevatorInfo.ElevatorPlaceId))
    -- 关闭交互
    self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, elevatorInfo.ElevatorPlaceId, false)
    --播放特效
    self._proxy:UnBindSceneObjectEffect(elevatorInfo.ElevatorPlaceId,"FxSkyGardenDianti03")
    self._proxy:UnBindSceneObjectEffect(elevatorInfo.ElevatorPlaceId,"FxSkyGardenDianti06")
    self:ElevatorEffect(elevatorInfo.ElevatorPlaceId,2)

    elevatorInfo.CurMoveTargetNodeId = targetMoveNodeId
    elevatorInfo.Moving = true
end

---@param elevatorInfo XElevatorInfo
function XLevel4034Present:OnElevatorMoveStop(elevatorInfo)
    if not elevatorInfo.Moving then
        return
    end
    if elevatorInfo.CurMoveTargetNodeId ==  elevatorInfo.UpNodeId then
        elevatorInfo.State = ElevatorState.Up
    elseif elevatorInfo.CurMoveTargetNodeId ==  elevatorInfo.DownNodeId then
        elevatorInfo.State = ElevatorState.Down
    end
    self:RefreshElevatorOption(elevatorInfo)
    self._proxy:UnloadSceneObject(elevatorInfo.AirWallPlaceId)
    -- 打开交互
    self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, elevatorInfo.ElevatorPlaceId, true)
    self._proxy:UnBindSceneObjectEffect(elevatorInfo.ElevatorPlaceId,"FxSkyGardenDianti04")
    self:ElevatorEffect(elevatorInfo.ElevatorPlaceId,4)
    elevatorInfo.Moving = false
end

---@param elevatorInfo XElevatorInfo
function XLevel4034Present:CallElevator(elevatorInfo, placeId)
    -- 从上层叫回电梯
    if placeId == elevatorInfo.CallUpPlaceId and elevatorInfo.State == ElevatorState.Down then
        self:StartElevatorMove(elevatorInfo, elevatorInfo.UpNodeId)
    end
    -- 从下层叫回电梯
    if placeId == elevatorInfo.CallDownPlaceId and elevatorInfo.State == ElevatorState.Up then
        self:StartElevatorMove(elevatorInfo, elevatorInfo.DownNodeId)
    end
end

---电梯特效
function XLevel4034Present:ElevatorEffect(ElevatorPlaceId, EffectState)
    if EffectState == 1 then
        self._proxy:BindSceneObjectEffect(ElevatorPlaceId,"FxSkyGardenDianti03",{ x = 0, y = 0, z = 0 },{ x = 0, y = 0, z = 0 },{ x = 1, y = 1, z = 1 })
    end
    if EffectState == 2 then
        self._proxy:BindSceneObjectEffect(ElevatorPlaceId,"FxSkyGardenDianti04",{ x = 0, y = 0, z = 0 },{ x = 0, y = 0, z = 0 },{ x = 1, y = 1, z = 1 })
    end
    if EffectState == 3 then
        self._proxy:BindSceneObjectEffect(ElevatorPlaceId,"FxSkyGardenDianti05",{ x = 0, y = 0, z = 0 },{ x = 0, y = 0, z = 0 },{ x = 1, y = 1, z = 1 })
    end
    if EffectState == 4 then
        self._proxy:BindSceneObjectEffect(ElevatorPlaceId,"FxSkyGardenDianti06",{ x = 0, y = 0, z = 0 },{ x = 0, y = 0, z = 0 },{ x = 1, y = 1, z = 1 })
    end
end

function XLevel4034Present:OnElevatorActorTriggerEnter(eventType, eventArgs)
    if self._elevatorUpFloorCall2Info[eventArgs.HostSceneObjectPlaceId] then
        self:CallElevator(self._elevatorUpFloorCall2Info[eventArgs.HostSceneObjectPlaceId], eventArgs.HostSceneObjectPlaceId)
    end
    if self._elevatorDownFloorCall2Info[eventArgs.HostSceneObjectPlaceId] then
        self:CallElevator(self._elevatorDownFloorCall2Info[eventArgs.HostSceneObjectPlaceId], eventArgs.HostSceneObjectPlaceId)
    end
end

function XLevel4034Present:OnElevatorNpcInteractStart(eventType, eventArgs)
    if self._elevatorTrigger2Info[eventArgs.TargetPlaceId] then
        self:TriggerElevatorMove(self._elevatorTrigger2Info[eventArgs.TargetPlaceId])
    end
end

function XLevel4034Present:OnElevatorSceneObjectMoveStop(eventType, eventArgs)
    if self._elevatorTrigger2Info[eventArgs.SceneObjectId] then
        self:OnElevatorMoveStop(self._elevatorTrigger2Info[eventArgs.SceneObjectId])
    end
end
--endregion

return XLevel4034Present

