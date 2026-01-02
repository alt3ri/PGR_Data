local XLevel4034Present = XDlcScriptManager.RegLevelPresentScript(4034)

local EvevatorState = {
    Disable = 0,
    Enable = 1,
}

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
    self:InitEvevator()

    for i, info in pairs(self._evevatorTrigger2Info) do
        self:TriggerEvevator(info)
    end
end

---@param dt number @ delta time
function XLevel4034Present:Update(dt)
    --每帧更新逻辑
end

---@param eventType number
---@param eventArgs userdata
function XLevel4034Present:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerState == ETriggerState.Enter and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
        if self._evevatorFirstFloorCall2Info[eventArgs.HostSceneObjectPlaceId] then
            self:CallEvevator(self._evevatorFirstFloorCall2Info[eventArgs.HostSceneObjectPlaceId], eventArgs.HostSceneObjectPlaceId)
        end

        if self._evevatorSecondFloorCall2Info[eventArgs.HostSceneObjectPlaceId] then
            self:CallEvevator(self._evevatorSecondFloorCall2Info[eventArgs.HostSceneObjectPlaceId], eventArgs.HostSceneObjectPlaceId)
        end
    end

    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then --是玩家发起的交互
            if self._evevatorTrigger2Info[eventArgs.TargetPlaceId] then
                self._proxy:LoadSceneObject(self._evevatorTrigger2Info[eventArgs.TargetPlaceId].AirWallPlaceId)
                self:TriggerEvevator(self._evevatorTrigger2Info[eventArgs.TargetPlaceId])
                self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, eventArgs.TargetPlaceId, false)
            end
        end
    end

    if eventType == EWorldEvent.SceneObjectMoveStop then
        if self._evevatorTrigger2Info[eventArgs.SceneObjectId] then
            self:OptionEvevator(self._evevatorTrigger2Info[eventArgs.SceneObjectId])
            self._proxy:UnloadSceneObject(self._evevatorTrigger2Info[eventArgs.SceneObjectId].AirWallPlaceId)
            self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, eventArgs.SceneObjectId, true)
        end
    end
end

function XLevel4034Present:Terminate()
    --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

--region 电梯
function XLevel4034Present:InitEvevator()
    ---@type table<number, XEvevatorInfo>
    self._evevatorTrigger2Info = {}
    ---@type table<number, XEvevatorInfo>
    self._evevatorFirstFloorCall2Info = {}
    ---@type table<number, XEvevatorInfo>
    self._evevatorSecondFloorCall2Info = {}

    --self._evevatorInfo1 = self:CreateEvevatorInfo(1100029, 1100031, 1100032, -1, 1, 2,1,2,1100055)
    --self._evevatorInfo2 = self:CreateEvevatorInfo(1100005, 1100033, 1100034, -1, 1, 2,1,2,1100056)
    --（第一个电梯的ID，第一个触发器的ID，第二个触发器的ID）
    ---self._evevatorInfo1 = self:CreateEvevatorInfo(1000008, 1000017, 1000018, -1, 1, 2,1,2,1000014)
    self._evevatorInfo2 = self:CreateEvevatorInfo(1100006, 1100008, 1100009, -1, 1, 2,1,2,1100007)
end

---@return XEvevatorInfo
function XLevel4034Present:CreateEvevatorInfo(triggerPlaceId, firstFloor, secondFloor, moveSpeed, targetNodeId, defaultNodeId, OptionUpId, OptionDownId,AirWallPlaceId)
    ---@type XEvevatorInfo
    local info = {}
    info.EvevatorState = EvevatorState.Disable
    info.TriggerPlaceId = triggerPlaceId
    info.FirstFloor = firstFloor
    info.SecondFloor = secondFloor
    info.HavePlayerEnterCount = 0
    info.MoveSpeed = moveSpeed
    info.TargetNodeId = targetNodeId
    info.DefaultNodeId = defaultNodeId
    info.OptionUpId = OptionUpId
    info.OptionDownId = OptionDownId
    info.AirWallPlaceId = AirWallPlaceId

    -- 注册进入字典表
    self._evevatorTrigger2Info[info.TriggerPlaceId] = info
    self._evevatorFirstFloorCall2Info[info.FirstFloor] = info
    self._evevatorSecondFloorCall2Info[info.SecondFloor] = info
    return info
end

function XLevel4034Present:OptionEvevator(evevatorInfo)
    if evevatorInfo.EvevatorState == EvevatorState.Disable then
        self._proxy:SetSceneObjectInteractOneOptionActive(evevatorInfo.TriggerPlaceId,1)
    end
    if evevatorInfo.EvevatorState == EvevatorState.Enable then
        self._proxy:SetSceneObjectInteractOneOptionActive(evevatorInfo.TriggerPlaceId,2)
    end
end

function XLevel4034Present:TriggerEvevator(evevatorInfo)
    if evevatorInfo.EvevatorState == EvevatorState.Disable then
        self._proxy:MoveSceneObjectToNode(evevatorInfo.TriggerPlaceId, evevatorInfo.TargetNodeId, 2)
    end

    if evevatorInfo.EvevatorState == EvevatorState.Enable then
        self._proxy:MoveSceneObjectToNode(evevatorInfo.TriggerPlaceId, evevatorInfo.DefaultNodeId, 2)
    end
end

function XLevel4034Present:CallEvevator(evevatorInfo, placeId)
    -- 从一楼叫回电梯
    if placeId == evevatorInfo.FirstFloor then
        evevatorInfo.EvevatorState = EvevatorState.Disable
        self._proxy:LoadSceneObject(evevatorInfo.AirWallPlaceId)
        self._proxy:MoveSceneObjectToNode(evevatorInfo.TriggerPlaceId, evevatorInfo.DefaultNodeId, evevatorInfo.MoveSpeed)
    end
    -- 从二楼叫回电梯
    if placeId == evevatorInfo.SecondFloor then
        evevatorInfo.EvevatorState = EvevatorState.Enable
        self._proxy:LoadSceneObject(evevatorInfo.AirWallPlaceId)
        self._proxy:MoveSceneObjectToNode(evevatorInfo.TriggerPlaceId, evevatorInfo.TargetNodeId, evevatorInfo.MoveSpeed)
    end
    self:OptionEvevator(evevatorInfo)
end
--endregion

return XLevel4034Present

