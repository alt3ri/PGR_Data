local XLevel5001Present = XDlcScriptManager.RegLevelPresentScript(5001)

local EvevatorState = {
    Down = 0,
    Up = 1,
}

local DoorState = {
    off = 0,
    on = 1,
}
local UserTriggerState = {
    out = 0,
    enter = 1,
}
local EnterEvatorState = {
    EnterStand = 0,
    EnterLoop = 1,
    LeaveStand = 2,
    LeaveLoop = 3,
}
local ArmamentDoorState = {
    off = 0,
    on = 1,
}
local ArmamentDoorTriggerState = {
    out = 0,
    enter = 1,
}

---@param proxy XDlcCSharpFuncs
function XLevel5001Present:Ctor(proxy)
    --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy
end

function XLevel5001Present:Init()
    --初始化逻辑
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectMoveStop)
    self._proxy:RegisterEvent(EWorldEvent.SceneObjectActionFinish)
    self._proxy:RegisterEvent(EWorldEvent.SetSceneObjectNodesActive)
    self._proxy:RegisterEvent(EWorldEvent.PlaySound)
    self:InitEvevator()
    self._MovieTrigger1 = 2200008
    self._MovieDramaCaption1 = {
        "Caption500101",
        "Caption500102",
        "Caption500103",
        "Caption500104",
        "Caption500105",
        "Caption500106",
        "Caption500107",
    }
    self._MovieTrigger2 = 2200014
    self._MovieTrigger3 = { [2200015] = 2200015, [2200016] = 2200016, [2200017] = 2200017, [2200018] = 2200018 }
    self._MovieDramaCaption2 = {
        "Caption500108",
        "Caption500109",
    }
    ---军备区门的参数
    self._doorInfo1 = {
        DoorPlaceId = 1100066,
        MoveSpeed = -1,
        OnNodeID = 1,
        OffNodeID = 2,
    }
    self._doorInfo2 = {
        DoorPlaceId = 1100067,
        MoveSpeed = -1,
        OnNodeID = 1,
        OffNodeID = 2,
    }
    ---军备区玻璃门触发器and状态
    self.DoorTriggerPlaceId = 1100068
    self.DoorState = DoorState.off
    self.UserTriggerState = UserTriggerState.out
    self._MovieTriggerin = 2200021
    self._MovieTriggerout = 2200022
    self._MovieDoor1 = 2200019    --正
    self._MovieDoor2 = 2200020   --负
    self._MovieDoorin = { 0, 80, 0 }
    self._MovieDoorout = { 0, -80, 0 }

    ---军备区入口电梯
    self._ArmamentEvator = {
        PlaceId = 1100069,
        EnterelevatorState = EnterEvatorState.EnterStand,
        AirWall_01 = 1100071,
        AirWall_02 = 1100072,
        CallEvator_01 = 1100001,
        CallEvator_02 = 1100002,
        InteractTrigger_01 = 1100061, ---离开军备区
        InteractTrigger_02 = 1100062, ---进入军备区
        PlayerInEvator = false, ---玩家在电梯中
    }
    ---军备区入口大门
    self._ArmamentDoor = {
        PlaceId = 1100070,
        ArmamentDoorState = ArmamentDoorState.on,
        ArmamentDoorTriggerState = ArmamentDoorTriggerState.out,
    }
    self._proxy:SetSceneObjectNodesActive(self._ArmamentEvator.PlaceId,"Wall_02",false)
    self._proxy:LoadSceneObject(self._ArmamentEvator.AirWall_02)
    ---保底传送区域
    self.TpTrigger = {
        PlaceId_1 = 1100082,
        PlaceId_2 = 1100083,
        tpPos = { x = 525.6624, y = 189.4084, z = 910.9258 },
        tpRot = { x = 0, y = -94.552, z = 0 },
    }

end

---@param dt number @ delta time
function XLevel5001Present:Update(dt)
    --每帧更新逻辑
end

---@param eventType number
---@param eventArgs userdata
function XLevel5001Present:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerState == ETriggerState.Enter and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
        if self._evevatorUpFloorCall2Info[eventArgs.HostSceneObjectPlaceId] then
            self:CallEvevator(self._evevatorUpFloorCall2Info[eventArgs.HostSceneObjectPlaceId], eventArgs.HostSceneObjectPlaceId)
        end
        if self._evevatorDownFloorCall2Info[eventArgs.HostSceneObjectPlaceId] then
            self:CallEvevator(self._evevatorDownFloorCall2Info[eventArgs.HostSceneObjectPlaceId], eventArgs.HostSceneObjectPlaceId)
        end
        if eventArgs.HostSceneObjectPlaceId == self._MovieTrigger1 then
            --VR广告随机台词
            self._proxy:PlayDramaCaption(self._MovieDramaCaption1[self._proxy:Random(1, 7)])
        end

        ---军备区入口电梯
        if eventArgs.HostSceneObjectPlaceId == self._ArmamentEvator.InteractTrigger_02 then
            if self._ArmamentEvator.EnterelevatorState == EnterEvatorState.EnterStand then
                self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentEvator.InteractTrigger_02, true)
            end
        end
        if eventArgs.HostSceneObjectPlaceId == self._ArmamentEvator.InteractTrigger_01 then
            if self._ArmamentEvator.EnterelevatorState == EnterEvatorState.LeaveStand then
                self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentEvator.InteractTrigger_01, true)
            end
        end
        ---军备区开门
        if eventArgs.HostSceneObjectPlaceId == self.DoorTriggerPlaceId then
            self.UserTriggerState = UserTriggerState.enter
            if self.DoorState == DoorState.off then
                self._proxy:MoveSceneObjectToNode(self._doorInfo1.DoorPlaceId, self._doorInfo1.OnNodeID, self._doorInfo1.MoveSpeed)
                self._proxy:MoveSceneObjectToNode(self._doorInfo2.DoorPlaceId, self._doorInfo2.OnNodeID, self._doorInfo2.MoveSpeed)
                self._proxy:PlaySound(5500114,ETargetActorType.SceneObject,self._proxy:GetSceneObjectUUID(self._doorInfo1.DoorPlaceId))
            end
        end
        if eventArgs.HostSceneObjectPlaceId == self._ArmamentDoor.PlaceId then
            self._ArmamentDoor.ArmamentDoorTriggerState = ArmamentDoorTriggerState.enter
            self._proxy:DoSceneObjectAction(self._ArmamentDoor.PlaceId, 9002)
        end
        ---进入区域传送
        if eventArgs.HostSceneObjectPlaceId == self.TpTrigger.PlaceId_1 then
            self._proxy:TeleportWithBlackUi(eventArgs.EnteredActorUUID, self.TpTrigger.tpPos, self.TpTrigger.tpRot)
        end
        if eventArgs.HostSceneObjectPlaceId == self.TpTrigger.PlaceId_2 then
            self._proxy:TeleportWithBlackUi(eventArgs.EnteredActorUUID, self.TpTrigger.tpPos, self.TpTrigger.tpRot)
        end
    end
    if eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerState == ETriggerState.Exit and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
        ---军备区内部玻璃门关门
        if eventArgs.HostSceneObjectPlaceId == self.DoorTriggerPlaceId then
            self.UserTriggerState = UserTriggerState.out
            if self.DoorState == DoorState.on then
                self._proxy:MoveSceneObjectToNode(self._doorInfo1.DoorPlaceId, self._doorInfo1.OffNodeID, self._doorInfo1.MoveSpeed)
                self._proxy:MoveSceneObjectToNode(self._doorInfo2.DoorPlaceId, self._doorInfo2.OffNodeID, self._doorInfo2.MoveSpeed)
                self._proxy:PlaySound(5500113,ETargetActorType.SceneObject,self._proxy:GetSceneObjectUUID(self._doorInfo1.DoorPlaceId))
            end
        end
        ---军备区入口大门关门
        if eventArgs.HostSceneObjectPlaceId == self._ArmamentDoor.PlaceId then
            self._ArmamentDoor.ArmamentDoorTriggerState = ArmamentDoorTriggerState.out
            self._proxy:DoSceneObjectAction(self._ArmamentDoor.PlaceId, 9004)
            self._ArmamentDoor.ArmamentDoorState = ArmamentDoorState.on
        end
    end
    if eventType == EWorldEvent.ActorTrigger then
        if eventArgs.TriggerState == ETriggerState.Enter and eventArgs.HostSceneObjectPlaceId == self._MovieTriggerin then
            --电影院小门
            self:DoorMovieTriggerEnter(self._MovieTriggerout, -80, 80)
        elseif eventArgs.TriggerState == ETriggerState.Exit and eventArgs.HostSceneObjectPlaceId == self._MovieTriggerin then
            self:DoorMovieTriggerExit(self._MovieTriggerout, 80, -80)
        elseif eventArgs.TriggerState == ETriggerState.Enter and eventArgs.HostSceneObjectPlaceId == self._MovieTriggerout then
            self:DoorMovieTriggerEnter(self._MovieTriggerin, 80, -80)
        elseif eventArgs.TriggerState == ETriggerState.Exit and eventArgs.HostSceneObjectPlaceId == self._MovieTriggerout then
            self:DoorMovieTriggerExit(self._MovieTriggerin, -80, 80)
        end
    end

    if eventType == EWorldEvent.ActorTrigger and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
        if eventArgs.TriggerState == ETriggerState.Exit and eventArgs.HostSceneObjectPlaceId == self._ArmamentEvator.PlaceId then
            self:OnZoneElevatorEnd()
        end
    end
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then
            --是玩家发起的交互
            if self._evevatorTrigger2Info[eventArgs.TargetPlaceId] then
                self:TriggerEvevatorMove(self._evevatorTrigger2Info[eventArgs.TargetPlaceId])
            end
            if eventArgs.TargetPlaceId == self._ArmamentEvator.InteractTrigger_02 then
                self._proxy:SetSceneObjectNodesActive(self._ArmamentEvator.PlaceId,"Wall_01",true)
                self._proxy:SetSceneObjectNodesActive(self._ArmamentEvator.PlaceId,"Wall_02",true)
                self._ArmamentEvator.EnterelevatorState = EnterEvatorState.EnterLoop
                self._proxy:UnloadSceneObject(self._ArmamentEvator.AirWall_02)
                self._proxy:DoSceneObjectAction(self._ArmamentEvator.PlaceId, 8003)
                self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentEvator.InteractTrigger_02, false)

                self:OnZoneElevatorStart()
            end
            if eventArgs.TargetPlaceId == self._ArmamentEvator.InteractTrigger_01 then
                self._proxy:SetSceneObjectNodesActive(self._ArmamentEvator.PlaceId,"Wall_01",true)
                self._proxy:SetSceneObjectNodesActive(self._ArmamentEvator.PlaceId,"Wall_02",true)
                self._ArmamentEvator.EnterelevatorState = EnterEvatorState.LeaveLoop
                self._proxy:UnloadSceneObject(self._ArmamentEvator.AirWall_01)
                self._proxy:DoSceneObjectAction(self._ArmamentEvator.PlaceId, 8004)
                self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentEvator.InteractTrigger_01, false)

                self:OnZoneElevatorStart()
            end

            if eventArgs.TargetPlaceId == self._ArmamentEvator.CallEvator_02 then
                if self._ArmamentEvator.EnterelevatorState == EnterEvatorState.LeaveStand then
                    self._ArmamentEvator.EnterelevatorState = EnterEvatorState.LeaveLoop
                    self._proxy:DoSceneObjectAction(self._ArmamentEvator.PlaceId, 8004)
                end
            end
            if eventArgs.TargetPlaceId == self._ArmamentEvator.CallEvator_01 then
                if self._ArmamentEvator.EnterelevatorState == EnterEvatorState.EnterStand then
                    self._ArmamentEvator.EnterelevatorState = EnterEvatorState.EnterLoop
                    self._proxy:DoSceneObjectAction(self._ArmamentEvator.PlaceId, 8003)
                end
            end
            if self._MovieTrigger3[eventArgs.TargetPlaceId] then
                --饮料机随机台词
                self._proxy:PlayDramaCaption(self._MovieDramaCaption2[self._proxy:Random(1, 2)])
            end
        end
    end
    if eventType == EWorldEvent.SceneObjectMoveStop then
        ---小电梯移动解除
        if self._evevatorTrigger2Info[eventArgs.SceneObjectId] then
            self:OnEvevatorMoveStop(self._evevatorTrigger2Info[eventArgs.SceneObjectId])
        end
        ---检测门停止时的状态
        if self._doorInfo2.DoorPlaceId == eventArgs.SceneObjectId then
            if self.DoorState == DoorState.on then
                self.DoorState = DoorState.off
            elseif self.DoorState == DoorState.off then
                self.DoorState = DoorState.on
                if self.UserTriggerState == UserTriggerState.out then
                    self._proxy:MoveSceneObjectToNode(self._doorInfo1.DoorPlaceId, self._doorInfo1.OffNodeID, self._doorInfo1.MoveSpeed)
                    self._proxy:MoveSceneObjectToNode(self._doorInfo2.DoorPlaceId, self._doorInfo2.OffNodeID, self._doorInfo2.MoveSpeed)
                end
            end
        end
    end
    if eventType == EWorldEvent.SceneObjectActionFinish then
        if self._ArmamentDoor.PlaceId == eventArgs.SceneObjectId then
            if self._ArmamentDoor.ArmamentDoorTriggerState == ArmamentDoorTriggerState.out then
                if self._ArmamentDoor.ArmamentDoorState == ArmamentDoorState.off then
                    self._proxy:DoSceneObjectAction(self._ArmamentDoor.PlaceId, 9004)
                    self._ArmamentDoor.ArmamentDoorState = ArmamentDoorState.on
                end
                if self._ArmamentDoor.ArmamentDoorState == ArmamentDoorState.on then
                    self._proxy:DoSceneObjectAction(self._ArmamentDoor.PlaceId, 9001)
                end
            end

            if self._ArmamentDoor.ArmamentDoorTriggerState == ArmamentDoorTriggerState.enter then
                if self._ArmamentDoor.ArmamentDoorState == ArmamentDoorState.off then
                    self._proxy:DoSceneObjectAction(self._ArmamentDoor.PlaceId, 9002)
                    self._ArmamentDoor.ArmamentDoorState = ArmamentDoorState.on
                end
                if self._ArmamentDoor.ArmamentDoorState == ArmamentDoorState.on then
                    self._proxy:DoSceneObjectAction(self._ArmamentDoor.PlaceId, 9003)
                end
            end
        end
        if self._ArmamentEvator.PlaceId == eventArgs.SceneObjectId then
            if self._ArmamentEvator.EnterelevatorState == EnterEvatorState.EnterLoop then
                self._proxy:SetSceneObjectNodesActive(self._ArmamentEvator.PlaceId,"Wall_01",false)
                self._proxy:SetSceneObjectNodesActive(self._ArmamentEvator.PlaceId,"Wall_02",true)
                self._proxy:UnloadSceneObject(self._ArmamentEvator.AirWall_02)
                self._ArmamentEvator.EnterelevatorState = EnterEvatorState.LeaveStand
                self._proxy:LoadSceneObject(self._ArmamentEvator.AirWall_01)
            end
            if self._ArmamentEvator.EnterelevatorState == EnterEvatorState.LeaveLoop then
                self._proxy:SetSceneObjectNodesActive(self._ArmamentEvator.PlaceId,"Wall_01",true)
                self._proxy:SetSceneObjectNodesActive(self._ArmamentEvator.PlaceId,"Wall_02",false)
                self._proxy:UnloadSceneObject(self._ArmamentEvator.AirWall_01)
                self._ArmamentEvator.EnterelevatorState = EnterEvatorState.EnterStand
                self._proxy:LoadSceneObject(self._ArmamentEvator.AirWall_02)
            end
            self:OnZoneElevatorEnd()
        end
    end
end

function XLevel5001Present:Terminate()
    self:OnZoneElevatorEnd()
    --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）
end

--region 军备区电梯
function XLevel5001Present:OnZoneElevatorStart()
    if not self._ArmamentEvator.PlayerInEvator then
        self._ArmamentEvator.PlayerInEvator = true
        self._proxy:SetSystemFuncEntryEnable(ESystemFunctionType.Photo, false)
    end
end

function XLevel5001Present:OnZoneElevatorEnd()
    if self._ArmamentEvator.PlayerInEvator then
        self._ArmamentEvator.PlayerInEvator = false
        self._proxy:SetSystemFuncEntryEnable(ESystemFunctionType.Photo, true)
    end
end
--endregion

--region 小电梯
---@class XEvevatorInfo 电梯对象
---@field State number 电梯状态，取值：EvevatorState
---@field EvevatorPlaceId number 电梯的PlaceId
---@field CallDownPlaceId number 上层触发呼叫的PlaceId，取值：placeId
---@field CallUpPlaceId number 下层触发呼叫的PlaceId，取值：placeId
---@field HavePlayerEnterCount number 电梯区域进入玩家数量（着重需要测试原地切换玩家自机角色）
---@field MoveSpeed number 电梯移速
---@field UpNodeId number 电梯上层坐标点
---@field DownNodeId number 电梯下层坐标点
---@field UpOptionId number 电梯上层选项ID
---@field DownOptionId number 电梯下层选项ID
---@field AirWallPlaceId number 电梯对应空气墙ID
---@field Moving boolean 是否移动中
---@field CurMoveTargetNodeId number 当前移动目标点
function XLevel5001Present:InitEvevator()
    ---@type table<number, XEvevatorInfo>
    self._evevatorTrigger2Info = {}
    ---@type table<number, XEvevatorInfo>
    self._evevatorUpFloorCall2Info = {}
    ---@type table<number, XEvevatorInfo>
    self._evevatorDownFloorCall2Info = {}

    self:CreateEvevatorInfo(EvevatorState.Down, 1100029, 1100031, 1100032, 4, 1, 2, 2, 1, 1100055)
    self:CreateEvevatorInfo(EvevatorState.Down, 1100005, 1100033, 1100034, 4, 1, 2, 2, 1, 1100056)
    self:CreateEvevatorInfo(EvevatorState.Down, 1100030, 1100035, 1100036, 4, 1, 2, 2, 1, 1100057)
    self:CreateEvevatorInfo(EvevatorState.Down, 1100028, 1100037, 1100038, 4, 1, 2, 2, 1, 1100058)
end

---@return XEvevatorInfo
function XLevel5001Present:CreateEvevatorInfo(defaultState, triggerPlaceId, callDownPlaceId, callUpPlaceId, moveSpeed, upNodeId, downNodeId, UpOptionId, DownOptionId, AirWallPlaceId)
    ---@type XEvevatorInfo
    local info = {}
    info.State = defaultState
    info.EvevatorPlaceId = triggerPlaceId
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
    self._evevatorTrigger2Info[info.EvevatorPlaceId] = info
    self._evevatorUpFloorCall2Info[info.CallDownPlaceId] = info
    self._evevatorDownFloorCall2Info[info.CallUpPlaceId] = info
    self:RefreshEvevatorOption(info)
    return info
end

---@param evevatorInfo XEvevatorInfo
function XLevel5001Present:RefreshEvevatorOption(evevatorInfo)
    if evevatorInfo.State == EvevatorState.Down then
        self._proxy:SetSceneObjectInteractOneOptionActive(evevatorInfo.EvevatorPlaceId, evevatorInfo.DownOptionId)
    end
    if evevatorInfo.State == EvevatorState.Up then
        self._proxy:SetSceneObjectInteractOneOptionActive(evevatorInfo.EvevatorPlaceId, evevatorInfo.UpOptionId)
    end
end

---@param evevatorInfo XEvevatorInfo
function XLevel5001Present:TriggerEvevatorMove(evevatorInfo)
    if evevatorInfo.State == EvevatorState.Down then
        self:StartEvevatorMove(evevatorInfo, evevatorInfo.UpNodeId)
    elseif evevatorInfo.State == EvevatorState.Up then
        self:StartEvevatorMove(evevatorInfo, evevatorInfo.DownNodeId)
    end
end

---@param evevatorInfo XEvevatorInfo
function XLevel5001Present:StartEvevatorMove(evevatorInfo, targetMoveNodeId)
    if evevatorInfo.Moving then
        return
    end
    self._proxy:LoadSceneObject(evevatorInfo.AirWallPlaceId)
    self._proxy:MoveSceneObjectToNode(evevatorInfo.EvevatorPlaceId, targetMoveNodeId, evevatorInfo.MoveSpeed)
    self._proxy:PlaySound(5500112, ETargetActorType.SceneObject, self._proxy:GetSceneObjectUUID(evevatorInfo.EvevatorPlaceId))
    -- 关闭交互
    self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, evevatorInfo.EvevatorPlaceId, false)
    evevatorInfo.CurMoveTargetNodeId = targetMoveNodeId
    evevatorInfo.Moving = true
end

---@param evevatorInfo XEvevatorInfo
function XLevel5001Present:OnEvevatorMoveStop(evevatorInfo)
    if not evevatorInfo.Moving then
        return
    end
    if evevatorInfo.CurMoveTargetNodeId ==  evevatorInfo.UpNodeId then
        evevatorInfo.State = EvevatorState.Up
    elseif evevatorInfo.CurMoveTargetNodeId ==  evevatorInfo.DownNodeId then
        evevatorInfo.State = EvevatorState.Down
    end
    self:RefreshEvevatorOption(evevatorInfo)
    self._proxy:UnloadSceneObject(evevatorInfo.AirWallPlaceId)
    -- 打开交互
    self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, evevatorInfo.EvevatorPlaceId, true)
    evevatorInfo.Moving = false
end

---@param evevatorInfo XEvevatorInfo
function XLevel5001Present:CallEvevator(evevatorInfo, placeId)
    -- 从上层叫回电梯
    if placeId == evevatorInfo.CallUpPlaceId and evevatorInfo.State == EvevatorState.Down then
        self:StartEvevatorMove(evevatorInfo, evevatorInfo.UpNodeId)
    end
    -- 从下层叫回电梯
    if placeId == evevatorInfo.CallDownPlaceId and evevatorInfo.State == EvevatorState.Up then
        self:StartEvevatorMove(evevatorInfo, evevatorInfo.DownNodeId)
    end
end
--endregion

--region 电影门
function XLevel5001Present:DoorMovieTriggerEnter(LimitTrigger, Rotate1, Rotate2)
    self._proxy:SetSceneObjectActive(LimitTrigger, false)
    self._proxy:RotateSceneObject(self._MovieDoor1, 1, Rotate1, 1, true)
    self._proxy:RotateSceneObject(self._MovieDoor2, 1, Rotate2, 1, true)
end

function XLevel5001Present:DoorMovieTriggerExit(LimitTrigger, Rotate1, Rotate2)
    self._proxy:AddTimerTask(2.5, function()
        self._proxy:RotateSceneObject(self._MovieDoor1, 0.5, Rotate1, 1, true)
        self._proxy:RotateSceneObject(self._MovieDoor2, 0.5, Rotate2, 1, true)
        self._proxy:SetSceneObjectActive(LimitTrigger, true)
    end)
end
--endregion

return XLevel5001Present
