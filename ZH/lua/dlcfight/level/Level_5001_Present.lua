local XLevel5001Present = XDlcScriptManager.RegLevelPresentScript(5001)

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

    --军备区小电梯
    self:InitElevator()
    --军备区入口电梯
    self:InitZoneElevator()
    ---军备区玻璃门
    self:InitArmamentGlassDoor()
    ---军备区入口大门
    self:InitArmamentDoor()
    --电影院门
    self:InitMovieDoor()
    --电影区广告
    self:InitMovieAdvertise()
    --电影放映机
    self:InitMoviePlay()
    --花园全息特效
    self:InitGardenMessage()
    self:ElevatorEffect(1100029,1)
    self:ElevatorEffect(1100005,1)
    self:ElevatorEffect(1100028,1)
    self:ElevatorEffect(1100030,1)
    --随机电影海报
    self._MovieObjR = { 2200023, 2200038 }
    self._MovieObjL = { 2200035, 2200026 }
    self:RandomMovie(self._MovieObjR)
    self:RandomMovie(self._MovieObjL)
    --鲸鱼
    self._WhalePlay = 2200050
    self._WhalePlayCD = 34
    self._WhalePlayTimer = 0
    self._WhalePlaying = false
    self:WhalePlay(self._WhalePlay, 9010)
end

---@param dt number @ delta time
function XLevel5001Present:Update(dt)
    --每帧更新逻辑
    self:UpdateDoorInfo(dt)
    self:UpdateWhalePlay(dt)
end

---@param eventType number
---@param eventArgs userdata
function XLevel5001Present:HandleEvent(eventType, eventArgs)
    --是玩家发起的Trigger
    if eventType == EWorldEvent.ActorTrigger and self._proxy:IsPlayerNpc(eventArgs.EnteredActorUUID) then
        if eventArgs.TriggerState == ETriggerState.Enter then
            --军备区小电梯呼叫
            self:OnElevatorActorTriggerEnter(eventType, eventArgs)
            --军备区入口电梯
            self:OnZoneElevatorActorTriggerEnter(eventType, eventArgs)
            --电影区广告
            self:OnMovieAdvertiseActorTriggerEnter(eventType, eventArgs)
            --军备区玻璃门开门
            self:OnArmamentGlassDoorActorTriggerEnter(eventType, eventArgs)
            --军备区入口开门
            self:OnArmamentDoorActorTriggerEnter(eventType, eventArgs)
            --开启花园全息
            self:OnGardenMessageActorTriggerEnter(eventType, eventArgs)
        elseif eventArgs.TriggerState == ETriggerState.Exit then
            --军备区入口电梯
            self:OnZoneElevatorActorTriggerExit(eventType, eventArgs)
            --军备区入口大门关门
            self:OnArmamentDoorActorTriggerExit(eventType, eventArgs)
            --军备区内部玻璃门关门
            self:OnArmamentGlassDoorActorTriggerExit(eventType, eventArgs)
            --关闭花园全息
            self:OnGardenMessageActorTriggerExit(eventType, eventArgs)
        end
    end
    if eventType == EWorldEvent.ActorTrigger then
        if eventArgs.TriggerState == ETriggerState.Enter then
            self:OnMovieDoorTriggerEnter(eventType, eventArgs)
        elseif eventArgs.TriggerState == ETriggerState.Exit then
            self:OnMovieDoorTriggerExit(eventType, eventArgs)
        end
    end

    --是玩家发起的交互
    if eventType == EWorldEvent.NpcInteractStart and self._proxy:IsPlayerNpc(eventArgs.LauncherId) then
        self:OnElevatorNpcInteractStart(eventType, eventArgs)
        self:OnZoneElevatorInteractStart(eventType, eventArgs)
        self:OnMovieAdvertiseNpcInteractStart(eventType, eventArgs)
        self:OnMoviePlayerNpcInteractStart(eventType, eventArgs)
    end
    --移动机关停止
    if eventType == EWorldEvent.SceneObjectMoveStop then
        ---小电梯移动解除
        self:OnElevatorSceneObjectMoveStop(eventType, eventArgs)
        ---检测门停止时的状态
        self:OnArmamentGlassDoorSceneObjectMoveStop(eventType, eventArgs)
    end
    --机关动作停止
    if eventType == EWorldEvent.SceneObjectActionFinish then
        self:OnZoneElevatorEndMove(eventType, eventArgs)
        self:OnArmamentDoorSceneObjectActionFinish(eventType, eventArgs)
        self:OnWhalePlaySceneObjectActionFinish(eventType, eventArgs)
        self:OnMoviePlayerSceneObjectActionFinish(eventType, eventArgs)
    end
end

function XLevel5001Present:Terminate()
    self:OnZoneElevatorLeaveLevel()
end

--region 军备区电梯
local EZoneElevatorStandType = {
    Down = 0,
    Up = 1,
}

local EZoneElevatorState = {
    Stand = 0,
    Moving = 1,
    Calling = 2,
}

function XLevel5001Present:InitZoneElevator()
    self._ArmamentElevator = {
        PlaceId = 1100069,
        State = EZoneElevatorState.Stand,
        StandType = EZoneElevatorStandType.Down,
        UpAirWall = 1100072,        --上层电梯空气墙
        DownAirWall = 1100071,      --下层电梯空气墙
        UpTrigger = 1100061,        --离开军备区触发点
        DownTrigger = 1100062,      --前往军备区触发点
        Up2DownCaller = 1100002,    --从军备区呼叫电梯触发点
        Down2UpCaller = 1100001,    --从广场呼叫电梯触发点
        GoDownActionId = 8004,      --离开军备区动画
        GoUpActionId = 8003,        --前往军备区动画
        PlayerInElevator = false,   --玩家在电梯中
        Moving = false,             --电梯启动中
    }
    ---保底传送区域
    self.TpTrigger = {
        PlaceId_1 = 1100082,
        PlaceId_2 = 1100083,
        tpPos = { x = 525.6624, y = 189.4084, z = 910.9258 },
        tpRot = { x = 0, y = -94.552, z = 0 },
    }

    self._proxy:SetSceneObjectNodesActive(self._ArmamentElevator.PlaceId,"Wall_02",false)
    self._proxy:LoadSceneObject(self._ArmamentElevator.UpAirWall)
    self:RefreshZoneElevatorTriggerInteract()
end

function XLevel5001Present:OnZoneElevatorInteractStart(eventType, eventArgs)
    if eventArgs.TargetPlaceId == self._ArmamentElevator.DownTrigger then
        self:TriggerZoneElevator(EZoneElevatorStandType.Down, EZoneElevatorStandType.Up)
    end
    if eventArgs.TargetPlaceId == self._ArmamentElevator.UpTrigger then
        self:TriggerZoneElevator(EZoneElevatorStandType.Up, EZoneElevatorStandType.Down)
    end
    if eventArgs.TargetPlaceId == self._ArmamentElevator.Up2DownCaller then
        self:CallZoneElevator(EZoneElevatorStandType.Up, EZoneElevatorStandType.Down)
    end
    if eventArgs.TargetPlaceId == self._ArmamentElevator.Down2UpCaller then
        self:CallZoneElevator(EZoneElevatorStandType.Down, EZoneElevatorStandType.Up)
    end
end

function XLevel5001Present:OnZoneElevatorActorTriggerEnter(eventType, eventArgs)
    ---进入区域传送
    if eventArgs.HostSceneObjectPlaceId == self.TpTrigger.PlaceId_1 then
        self._proxy:TeleportWithBlackUi(eventArgs.EnteredActorUUID, self.TpTrigger.tpPos, self.TpTrigger.tpRot)
    end
    if eventArgs.HostSceneObjectPlaceId == self.TpTrigger.PlaceId_2 then
        self._proxy:TeleportWithBlackUi(eventArgs.EnteredActorUUID, self.TpTrigger.tpPos, self.TpTrigger.tpRot)
    end

    if eventArgs.HostSceneObjectPlaceId == self._ArmamentElevator.PlaceId then
        if not self._ArmamentElevator.PlayerInElevator then
            self._ArmamentElevator.PlayerInElevator = true
            if self._ArmamentElevator.State == EZoneElevatorState.Moving then
                self:ZoneElevatorClosePhoto()
            end
        end
    end
end

function XLevel5001Present:OnZoneElevatorActorTriggerExit(eventType, eventArgs)
    -- 防止在电梯过程中从地图传送出去拍照功能没有开启
    if eventArgs.HostSceneObjectPlaceId == self._ArmamentElevator.PlaceId then
        if self._ArmamentElevator.PlayerInElevator then
            self._ArmamentElevator.PlayerInElevator = false
            if self._ArmamentElevator.State == EZoneElevatorState.Moving then
                self:ZoneElevatorOpenPhoto()
            end
        end
    end
end

---启动军备区电梯
function XLevel5001Present:TriggerZoneElevator(fromStandType, toStandType)
    if self._ArmamentElevator.StandType == toStandType then
        return
    end

    if self._ArmamentElevator.StandType == EZoneElevatorStandType.Down then
        self._proxy:UnloadSceneObject(self._ArmamentElevator.UpAirWall)
        self._proxy:DoSceneObjectAction(self._ArmamentElevator.PlaceId, self._ArmamentElevator.GoUpActionId)
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentElevator.DownTrigger, false)
    else
        self._proxy:UnloadSceneObject(self._ArmamentElevator.DownAirWall)
        self._proxy:DoSceneObjectAction(self._ArmamentElevator.PlaceId, self._ArmamentElevator.GoDownActionId)
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentElevator.UpTrigger, false)
    end

    self:SwitchZoneElevatorState(EZoneElevatorState.Moving)
end

---呼叫军备区电梯
function XLevel5001Present:CallZoneElevator(fromStandType, toStandType)
    if self._ArmamentElevator.StandType == toStandType then
        return
    end

    if self._ArmamentElevator.StandType == EZoneElevatorStandType.Down then
        self._proxy:DoSceneObjectAction(self._ArmamentElevator.PlaceId, self._ArmamentElevator.GoUpActionId)
    else
        self._proxy:DoSceneObjectAction(self._ArmamentElevator.PlaceId, self._ArmamentElevator.GoDownActionId)
    end
    self:SwitchZoneElevatorState(EZoneElevatorState.Calling)
end

function XLevel5001Present:OnZoneElevatorEndMove(eventType, eventArgs)
    if self._ArmamentElevator.PlaceId ~= eventArgs.SceneObjectId then
        return
    end

    self:SwitchZoneElevatorState(EZoneElevatorState.Stand)
end

---刷新电梯选项显示
function XLevel5001Present:RefreshZoneElevatorTriggerInteract()
    if self._ArmamentElevator.State ~= EZoneElevatorState.Stand then
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentElevator.DownTrigger, false)
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentElevator.DownTrigger, false)
        return
    end
    if self._ArmamentElevator.StandType == EZoneElevatorStandType.Down then
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentElevator.DownTrigger, true)
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentElevator.UpTrigger, false)
    else
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentElevator.DownTrigger, false)
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._ArmamentElevator.UpTrigger, true)
    end
end

function XLevel5001Present:SwitchZoneElevatorState(state)
    if self._ArmamentElevator.State == state then
        return
    end
    local lastState = self._ArmamentElevator.State
    self._ArmamentElevator.State = state

    -- 状态切换时
    if state == EZoneElevatorState.Stand then
        -- 由Moving到Stand 且 玩家在电梯 时刷新拍照功能
        if lastState == EZoneElevatorState.Moving and self._ArmamentElevator.PlayerInElevator then
            self:ZoneElevatorOpenPhoto()
        end
        -- 设置
        local down2Up = self._ArmamentElevator.StandType == EZoneElevatorStandType.Down
        self._proxy:SetSceneObjectNodesActive(self._ArmamentElevator.PlaceId,"Wall_01",not down2Up)
        self._proxy:SetSceneObjectNodesActive(self._ArmamentElevator.PlaceId,"Wall_02",down2Up)
        if down2Up then
            self._ArmamentElevator.StandType = EZoneElevatorStandType.Up
            self._proxy:UnloadSceneObject(self._ArmamentElevator.UpAirWall)
            self._proxy:LoadSceneObject(self._ArmamentElevator.DownAirWall)
        else
            self._ArmamentElevator.StandType = EZoneElevatorStandType.Down
            self._proxy:UnloadSceneObject(self._ArmamentElevator.DownAirWall)
            self._proxy:LoadSceneObject(self._ArmamentElevator.UpAirWall)
        end
    elseif state == EZoneElevatorState.Moving then
        self._proxy:SetSceneObjectNodesActive(self._ArmamentElevator.PlaceId,"Wall_01",true)
        self._proxy:SetSceneObjectNodesActive(self._ArmamentElevator.PlaceId,"Wall_02",true)
        if self._ArmamentElevator.PlayerInElevator then
            self:ZoneElevatorClosePhoto()
        end
    elseif state == EZoneElevatorState.Calling then
        self._proxy:SetSceneObjectNodesActive(self._ArmamentElevator.PlaceId,"Wall_01",true)
        self._proxy:SetSceneObjectNodesActive(self._ArmamentElevator.PlaceId,"Wall_02",true)
    end
    -- 刷新电梯选项
    self:RefreshZoneElevatorTriggerInteract()
end

function XLevel5001Present:OnZoneElevatorLeaveLevel()
    -- 离开Level之后如果是在电梯中恢复拍照功能
    if self._ArmamentElevator.State == EZoneElevatorState.Moving then
        self:ZoneElevatorOpenPhoto()
    end
end

function XLevel5001Present:ZoneElevatorClosePhoto()
    self._proxy:SetSystemFuncEntryEnable(ESystemFunctionType.Photo, false)
end

function XLevel5001Present:ZoneElevatorOpenPhoto()
    self._proxy:SetSystemFuncEntryEnable(ESystemFunctionType.Photo, true)
end
--endregion

--region 军备区入口大门
local ArmamentDoorState = {
    off = 0,
    on = 1,
}

local ArmamentDoorTriggerState = {
    out = 0,
    enter = 1,
}

function XLevel5001Present:InitArmamentDoor()
    self._ArmamentDoor = {
        PlaceId = 1100070,
        ArmamentDoorState = ArmamentDoorState.on,
        ArmamentDoorTriggerState = ArmamentDoorTriggerState.out,
    }
    --军备区扫描
    self._ScanningTrigger =  2200005
    self._ScanningStart = 2200036
    self._ScanningFx = 2200037
end

function XLevel5001Present:OnArmamentDoorActorTriggerEnter(eventType, eventArgs)
    if eventArgs.HostSceneObjectPlaceId == self._ArmamentDoor.PlaceId then
        self._ArmamentDoor.ArmamentDoorTriggerState = ArmamentDoorTriggerState.enter
        self._proxy:DoSceneObjectAction(self._ArmamentDoor.PlaceId, 9002)
    end
    if eventArgs.HostSceneObjectPlaceId == self._ScanningTrigger then
        self._proxy:LoadSceneObject(self._ScanningStart)
        self._proxy:SetSceneObjectActive(self._ScanningTrigger, false)
        self._proxy:AddTimerTask(12, function()
            self._proxy:SetSceneObjectActive(self._ScanningTrigger, true)
            self._proxy:UnloadSceneObject(self._ScanningStart)
        end)
    end
end

function XLevel5001Present:OnArmamentDoorActorTriggerExit(eventType, eventArgs)
    if eventArgs.HostSceneObjectPlaceId == self._ArmamentDoor.PlaceId then
        self._ArmamentDoor.ArmamentDoorTriggerState = ArmamentDoorTriggerState.out
        self._proxy:DoSceneObjectAction(self._ArmamentDoor.PlaceId, 9004)
        self._ArmamentDoor.ArmamentDoorState = ArmamentDoorState.on
    end
    if eventArgs.HostSceneObjectPlaceId == self._ScanningStart then
        self._proxy:LoadSceneObject(self._ScanningFx)
        self._proxy:AddTimerTask(12, function() --爱回收
            self._proxy:LoadSceneObject(self._ScanningFx)
        end)
    end
end

function XLevel5001Present:OnArmamentDoorSceneObjectActionFinish(eventType, eventArgs)
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
end
--endregion

--region 军备区玻璃门
local DoorState = {
    off = 0,
    on = 1,
}
local UserTriggerState = {
    out = 0,
    enter = 1,
}

function XLevel5001Present:InitArmamentGlassDoor()
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
end

function XLevel5001Present:OnArmamentGlassDoorActorTriggerEnter(eventType, eventArgs)
    if eventArgs.HostSceneObjectPlaceId == self.DoorTriggerPlaceId then
        self.UserTriggerState = UserTriggerState.enter
        if self.DoorState == DoorState.off then
            self._proxy:MoveSceneObjectToNode(self._doorInfo1.DoorPlaceId, self._doorInfo1.OnNodeID, self._doorInfo1.MoveSpeed)
            self._proxy:MoveSceneObjectToNode(self._doorInfo2.DoorPlaceId, self._doorInfo2.OnNodeID, self._doorInfo2.MoveSpeed)
            self._proxy:PlaySound(5500114,ETargetActorType.SceneObject,self._proxy:GetSceneObjectUUID(self._doorInfo1.DoorPlaceId))
        end
    end
end

function XLevel5001Present:OnArmamentGlassDoorActorTriggerExit(eventType, eventArgs)
    if eventArgs.HostSceneObjectPlaceId == self.DoorTriggerPlaceId then
        self.UserTriggerState = UserTriggerState.out
        if self.DoorState == DoorState.on then
            self._proxy:MoveSceneObjectToNode(self._doorInfo1.DoorPlaceId, self._doorInfo1.OffNodeID, self._doorInfo1.MoveSpeed)
            self._proxy:MoveSceneObjectToNode(self._doorInfo2.DoorPlaceId, self._doorInfo2.OffNodeID, self._doorInfo2.MoveSpeed)
            self._proxy:PlaySound(5500113,ETargetActorType.SceneObject,self._proxy:GetSceneObjectUUID(self._doorInfo1.DoorPlaceId))
        end
    end
end

function XLevel5001Present:OnArmamentGlassDoorSceneObjectMoveStop(eventType, eventArgs)
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
--endregion

--region 军备区小电梯
---@class XElevatorInfo 电梯对象
---@field State number 电梯状态，取值：ElevatorState
---@field ElevatorPlaceId number 电梯的PlaceId
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

local ElevatorState = {
    Down = 0,
    Up = 1,
}

function XLevel5001Present:InitElevator()
    ---@type table<number, XElevatorInfo>
    self._elevatorTrigger2Info = {}
    ---@type table<number, XElevatorInfo>
    self._elevatorUpFloorCall2Info = {}
    ---@type table<number, XElevatorInfo>
    self._elevatorDownFloorCall2Info = {}

    self:CreateElevatorInfo(ElevatorState.Down, 1100029, 1100031, 1100032, 4, 1, 2, 2, 1, 1100055)
    self:CreateElevatorInfo(ElevatorState.Down, 1100005, 1100033, 1100034, 4, 1, 2, 2, 1, 1100056)
    self:CreateElevatorInfo(ElevatorState.Down, 1100030, 1100035, 1100036, 4, 1, 2, 2, 1, 1100057)
    self:CreateElevatorInfo(ElevatorState.Down, 1100028, 1100037, 1100038, 4, 1, 2, 2, 1, 1100058)
end

---@return XElevatorInfo
function XLevel5001Present:CreateElevatorInfo(defaultState, triggerPlaceId, callDownPlaceId, callUpPlaceId, moveSpeed, upNodeId, downNodeId, UpOptionId, DownOptionId, AirWallPlaceId)
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
function XLevel5001Present:RefreshElevatorOption(elevatorInfo)
    if elevatorInfo.State == ElevatorState.Down then
        self._proxy:SetSceneObjectInteractOneOptionActive(elevatorInfo.ElevatorPlaceId, elevatorInfo.DownOptionId)
    end
    if elevatorInfo.State == ElevatorState.Up then
        self._proxy:SetSceneObjectInteractOneOptionActive(elevatorInfo.ElevatorPlaceId, elevatorInfo.UpOptionId)
    end
end

---@param elevatorInfo XElevatorInfo
function XLevel5001Present:TriggerElevatorMove(elevatorInfo)
    if elevatorInfo.State == ElevatorState.Down then
        self:StartElevatorMove(elevatorInfo, elevatorInfo.UpNodeId)
    elseif elevatorInfo.State == ElevatorState.Up then
        self:StartElevatorMove(elevatorInfo, elevatorInfo.DownNodeId)
    end
end

---@param elevatorInfo XElevatorInfo
function XLevel5001Present:StartElevatorMove(elevatorInfo, targetMoveNodeId)
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
function XLevel5001Present:OnElevatorMoveStop(elevatorInfo)
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
function XLevel5001Present:CallElevator(elevatorInfo, placeId)
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
function XLevel5001Present:ElevatorEffect(ElevatorPlaceId, EffectState)
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

function XLevel5001Present:OnElevatorActorTriggerEnter(eventType, eventArgs)
    if self._elevatorUpFloorCall2Info[eventArgs.HostSceneObjectPlaceId] then
        self:CallElevator(self._elevatorUpFloorCall2Info[eventArgs.HostSceneObjectPlaceId], eventArgs.HostSceneObjectPlaceId)
    end
    if self._elevatorDownFloorCall2Info[eventArgs.HostSceneObjectPlaceId] then
        self:CallElevator(self._elevatorDownFloorCall2Info[eventArgs.HostSceneObjectPlaceId], eventArgs.HostSceneObjectPlaceId)
    end
end

function XLevel5001Present:OnElevatorNpcInteractStart(eventType, eventArgs)
    if self._elevatorTrigger2Info[eventArgs.TargetPlaceId] then
        self:TriggerElevatorMove(self._elevatorTrigger2Info[eventArgs.TargetPlaceId])
    end
end

function XLevel5001Present:OnElevatorSceneObjectMoveStop(eventType, eventArgs)
    if self._elevatorTrigger2Info[eventArgs.SceneObjectId] then
        self:OnElevatorMoveStop(self._elevatorTrigger2Info[eventArgs.SceneObjectId])
    end
end
--endregion

--region 电影区广告
function XLevel5001Present:InitMovieAdvertise()
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
end

---VR广告随机台词
function XLevel5001Present:OnMovieAdvertiseActorTriggerEnter(eventType, eventArgs)
    if eventArgs.HostSceneObjectPlaceId == self._MovieTrigger1 then
        self._proxy:PlayDramaCaption(self._MovieDramaCaption1[self._proxy:Random(1, 7)])
    end
end

function XLevel5001Present:OnMovieAdvertiseNpcInteractStart(eventType, eventArgs)
    if eventArgs.TargetActorType == ETargetActorType.SceneObject and self._MovieTrigger3[eventArgs.TargetPlaceId] then
        --饮料机随机台词
        self._proxy:PlayDramaCaption(self._MovieDramaCaption2[self._proxy:Random(1, 2)])
    end
end
--endregion

--region 电影放映机
local EMoviePlayerState = {
    Play = 1,
    Stop = 2,
    Changed = 3,
}

function XLevel5001Present:InitMoviePlay()
    self._MoviePlayer = {}
    self._MoviePlayer.PlaceId = 2200025
    self._MoviePlayer.State = EMoviePlayerState.Play
    self._MoviePlayer.InAnim = false
    self._MoviePlayer.StateAction = { 
        [EMoviePlayerState.Play] = 9006,
        [EMoviePlayerState.Stop] = 9008,
        [EMoviePlayerState.Changed] = 9007,
    }
end

function XLevel5001Present:OnMoviePlayerNpcInteractStart(eventType, eventArgs)
    if eventArgs.TargetActorType == ETargetActorType.SceneObject 
        and eventArgs.TargetPlaceId == self._MoviePlayer.PlaceId
        and not self._MoviePlayer.InAnim
    then
        self._MoviePlayer.InAnim = true
        if self._MoviePlayer.State == EMoviePlayerState.Play then
            self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._MoviePlayer.PlaceId, false)
            self._proxy:DoSceneObjectAction(self._MoviePlayer.PlaceId, self._MoviePlayer.StateAction[self._MoviePlayer.State])
            self._MoviePlayer.State = EMoviePlayerState.Stop
        elseif self._MoviePlayer.State == EMoviePlayerState.Stop then
            self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._MoviePlayer.PlaceId, false)
            self._proxy:DoSceneObjectAction(self._MoviePlayer.PlaceId, self._MoviePlayer.StateAction[self._MoviePlayer.State])
            self._MoviePlayer.State = EMoviePlayerState.Changed
            self._proxy:AddTimerTask(4, function()
                self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._MoviePlayer.PlaceId, true)
                self._proxy:DoSceneObjectAction(self._MoviePlayer.PlaceId, self._MoviePlayer.StateAction[self._MoviePlayer.State])
                self._MoviePlayer.InAnim = false
                self._MoviePlayer.State = EMoviePlayerState.Play
            end)
        end
    end
end

function XLevel5001Present:OnMoviePlayerSceneObjectActionFinish(eventType, eventArgs)    --鲸鱼自动播放结束事件响应
    if eventArgs.SceneObjectId == self._MoviePlayer.PlaceId then
        if not self._MoviePlayer.InAnim then
            return
        end
        self._MoviePlayer.InAnim = false
        self._proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.SceneObject, self._MoviePlayer.PlaceId, true)
    end
end
--endregion

--region 电影自动门
---@class XMoveDoorInfo 电影自动门
---@field State number 门状态，取值：EMovieDoorState
---@field RightDoorPlaceId number 左门
---@field LeftDoorPlaceId number 右门
---@field FrontTriggerPlaceId number 前触发器
---@field BackTriggerPlaceId number 后触发器
---@field OpenTime number 开门时间
---@field CloseTime number 关门时间
---@field DelayTime number 延时时间
---@field IsFrontTrigger bool 延时时间
---@field TriggerCD number 触发CD

local EMovieDoorState = {
    Open = 1,
    Close = 2,
    Delay = 3,
}

function XLevel5001Present:InitMovieDoor()
    ---@type XMoveDoorInfo
    self._MovieDoorInfo = {}
    self._MovieDoorInfo.State = EMovieDoorState.Close
    self._MovieDoorInfo.RightDoorPlaceId = 2200020
    self._MovieDoorInfo.LeftDoorPlaceId = 2200019
    self._MovieDoorInfo.FrontTriggerPlaceId = 2200021
    self._MovieDoorInfo.BackTriggerPlaceId = 2200022
    self._MovieDoorInfo.OpenTime = 1
    self._MovieDoorInfo.CloseTime = 0.5
    self._MovieDoorInfo.DelayTime = 0
end

---@param doorInfo XMoveDoorInfo
function XLevel5001Present:SetMovieDoorOpen(doorInfo, state, isFrontTrigger, openAngle)
    if state == doorInfo.State then
        return
    end

    doorInfo.State = state
    doorInfo.IsFrontTrigger = isFrontTrigger
    local isOpen = doorInfo.State == EMovieDoorState.Open
    local rotateTime = 1
    if isOpen then
        rotateTime = doorInfo.OpenTime
    else
        rotateTime = doorInfo.CloseTime
    end
    self._proxy:RotateSceneObject(doorInfo.RightDoorPlaceId, rotateTime, openAngle, 1, true)
    self._proxy:RotateSceneObject(doorInfo.LeftDoorPlaceId, rotateTime, -openAngle, 1, true)
    if isFrontTrigger then
        self._proxy:SetSceneObjectActive(doorInfo.BackTriggerPlaceId, not isOpen)
    else
        self._proxy:SetSceneObjectActive(doorInfo.FrontTriggerPlaceId, not isOpen)
    end
end

---@param doorInfo XMoveDoorInfo
function XLevel5001Present:SetMovieDoorDelay(doorInfo, isFrontTrigger, delayTime)
    if EMovieDoorState.Delay == doorInfo.State then
        return
    end
    doorInfo.State = EMovieDoorState.Delay
    doorInfo.DelayTime = delayTime
    doorInfo.IsFrontTrigger = isFrontTrigger
end

function XLevel5001Present:UpdateDoorInfo(dt)
    if not self._MovieDoorInfo then
        return
    end
    if self._MovieDoorInfo.DelayTime > 0 then
        self._MovieDoorInfo.DelayTime = self._MovieDoorInfo.DelayTime - dt
    end
    if self._MovieDoorInfo.DelayTime <= 0 then
        if self._MovieDoorInfo.State == EMovieDoorState.Delay then
            local openAngle = 80
            if self._MovieDoorInfo.IsFrontTrigger then
                openAngle = -80
            end
            self:SetMovieDoorOpen(self._MovieDoorInfo, EMovieDoorState.Close, self._MovieDoorInfo.IsFrontTrigger, openAngle)
        end
    end
end

function XLevel5001Present:OnMovieDoorTriggerEnter(eventType, eventArgs)
    if self._MovieDoorInfo.State == EMovieDoorState.Delay then
        return
    end
    if eventArgs.HostSceneObjectPlaceId == self._MovieDoorInfo.FrontTriggerPlaceId then
        self:SetMovieDoorOpen(self._MovieDoorInfo, EMovieDoorState.Open, true, 80)
    elseif eventArgs.HostSceneObjectPlaceId == self._MovieDoorInfo.BackTriggerPlaceId then
        self:SetMovieDoorOpen(self._MovieDoorInfo, EMovieDoorState.Open, false, -80)
    end
end

function XLevel5001Present:OnMovieDoorTriggerExit(eventType, eventArgs)
    if self._MovieDoorInfo.State ~= EMovieDoorState.Open then
        return
    end
    if eventArgs.HostSceneObjectPlaceId == self._MovieDoorInfo.FrontTriggerPlaceId then
        self:SetMovieDoorDelay(self._MovieDoorInfo, true, 2.5)
    elseif eventArgs.HostSceneObjectPlaceId == self._MovieDoorInfo.BackTriggerPlaceId then
        self:SetMovieDoorDelay(self._MovieDoorInfo, false, 2.5)
    end
end
--endregion

--region 花园全息特效
function XLevel5001Present:InitGardenMessage()
    self._GardenTrigger1 = 2200033
    self._GardenTrigger2 = 2200034
    self._GardenMessage1 = { 2200028, 2200029, 2200030 }
    self._GardenMessage2 = { 2200031, 2200032}
end


function XLevel5001Present:OnGardenMessageActorTriggerEnter(eventType, eventArgs)
    if eventArgs.HostSceneObjectPlaceId == self._GardenTrigger1 then
        for _, HideObj in pairs(self._GardenMessage1) do
            self._proxy:LoadSceneObject(HideObj)
        end
    end
    if eventArgs.HostSceneObjectPlaceId == self._GardenTrigger2 then
        for _, HideObj in pairs(self._GardenMessage2) do
            self._proxy:LoadSceneObject(HideObj)
        end
    end
end

function XLevel5001Present:OnGardenMessageActorTriggerExit(eventType, eventArgs)
    if eventArgs.HostSceneObjectPlaceId == self._GardenTrigger1 then
        for _, HideObj in pairs(self._GardenMessage1) do
            self._proxy:UnloadSceneObject(HideObj)
        end
    end
    if eventArgs.HostSceneObjectPlaceId == self._GardenTrigger2 then
        for _, HideObj in pairs(self._GardenMessage2) do
            self._proxy:UnloadSceneObject(HideObj)
        end
    end
end

function XLevel5001Present:RandomMovie(list)
    self._proxy:LoadSceneObject(list[self._proxy:Random(1, #list)])
end

function XLevel5001Present:WhalePlay(ObjPlaceId, Action1) --鲸鱼自动播放器
    self._WhalePlaying = true
    self._proxy:DoSceneObjectAction(ObjPlaceId, Action1)
    self._proxy:BindSceneObjectEffect(ObjPlaceId, "FxSkyGardenArtDR02", { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, { x = 1, y = 1, z = 1 })
end
 

function XLevel5001Present:UpdateWhalePlay(dt)    --鲸鱼自动播放器
    if not self._WhalePlaying then
        self._WhalePlayTimer = self._WhalePlayTimer + dt
        if self._WhalePlayTimer >= self._WhalePlayCD then
            self:WhalePlay(self._WhalePlay, 9010)
        end
    end
end

function XLevel5001Present:OnWhalePlaySceneObjectActionFinish(eventType, eventArgs)    --鲸鱼自动播放结束事件响应
    if eventArgs.SceneObjectId == self._WhalePlay then
        if eventArgs.ActionId == 9010 then
            self._proxy:DoSceneObjectAction(self._WhalePlay, 9009)
        elseif eventArgs.ActionId == 9009 then
            self._WhalePlayTimer = 0
            self._WhalePlaying = false
        end
    end
end
--endregion

return XLevel5001Present
