---@class XCharKuroro
local XCharKuroro = XDlcScriptManager.RegCharScript(6004, "XCharKuroro")
local Vector3 = XMain.IsClient and CS.UnityEngine.Vector3 or CS.HaruMath.Vector3

---@param proxy XDlcCSharpFuncs
function XCharKuroro:Ctor(proxy)
    self._proxy = proxy

    self._interactTargetUUID = 0
    self._interactOptionId = 0
    self._movingToInteractSpot = false
    self._executingInteractBehavior = false
    self._interactSpot = Vector3.zero
    self._deltaMove = { x = 0, y = 0, z = 0 }
    self._maxSpeedRun = 5.5                                                --辅助机最大移动速度（玩家跑时）
    self._maxSpeedWalk = 1.1                                               --辅助机最大移动速度(玩家行走时)
    self._maxSpeedSprint = 6.5                                             --辅助机最大移动速度（玩家疾跑时）
    self._maxSpeedJump = 6.5                                               --辅助机最大移动速度（玩家跳跃时）
    self._nowSpeed = 0                                                     --辅助机当前移动速度
    self._moveAccelerationRun = 25.0                                       --跑移动加速度（m/s^2)
    self._moveAccelerationWalk = 5.5                                       --走移动加速度（m/s^2）
    self._moveAccelerationSprint = 30.0                                    --疾跑移动加速度（m/s^2）
    self._moveAccelerationJump = 29.0                                      --跳跃移动加速度（m/s^2）
    self._stopAccelerationRun = 5.5                                        --跑停止加速度（m/s^2）
    self._stopAccelerationWalk = 1.1                                       --走停止加速度（m/s^2）
    self._stopAccelerationSprint = 6.5                                     --疾跑停止加速度（m/s^2）
    self._stopAccelerationJump = 6.5                                       --跳跃停止加速度（m/s^2）
    self._moveAcceleration = self._moveAccelerationRun                     --移动加速度（赋值用）
    self._stopAcceleration = self._stopAccelerationRun                     --停止加速度（赋值用）
    self._maxSpeed = self._maxSpeedRun                                     --最大速度（赋值用）
    self._moveMode = {
        None = 0,
        Walk = 1,
        Run = 2,
        Sprint = 3,
        Jump = 4
    }
    self._time = 0          --记录时间
    self._previousTime1 = 0 --上次时间记录用变量1
    self._previousTime2 = 0 --上次时间记录用变量1
    self._destination = nil --记录目标点
    self._followStep = 0    --跟随逻辑的步骤记录
end

function XCharKuroro:Init()
    self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId() --玩家
    self._uuid = self._proxy:GetSelfNpcId() ---@type number
    --库洛洛始终是漂浮在空中的，故禁止库洛洛的地空检测逻辑，使其状态保持在idle，现阶段不增加额外的fly状态
    self._proxy:AddNpcFlag(self._uuid, ENpcFlag.ForbidCheckOnAir)
    --self._proxy:RegisterEvent(EWorldEvent.NpcActionStateChange)
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractComplete)
    --self._proxy:RegisterEvent(EWorldEvent.NpcMoveTypeChange)
    self._proxy:SetNpcGravity(self._uuid, 0, 0)                        --库洛洛无重力
    self._proxy:SetNpcIgnoreOtherNpcAllCollisions(self._uuid, true) --库洛洛不碰其它npc
    self._proxy:SetNpcActive(self._uuid, false)     --常规状态隐藏库洛洛
end

---@param dt number @ delta time
function XCharKuroro:Update(dt)
    self._time = self._time + dt
    if self._executingInteractBehavior then
        local selfPos = self._proxy:GetNpcPosition(self._uuid)
        local distance = Vector3.Distance(selfPos, self._interactSpot)
        if self._movingToInteractSpot then
            local moveDirection = (self._interactSpot - selfPos).normalized
            self._deltaMove = moveDirection * self._maxSpeedRun * dt
            self._proxy:MoveNpc(self._uuid, self._deltaMove)
            self._proxy:SetNpcRotation(self._uuid, moveDirection)
        end
        if distance <= 0.15 then
            XLog.Debug("库洛洛停止移动，开始与目标交互")
            self._proxy:NpcStartInteractWith(self._uuid, self._interactTargetUUID, self._interactOptionId)
            self._movingToInteractSpot = false
            self._executingInteractBehavior = false
        end
        return
    end

    --时刻监测的内容
    self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId() --拿到玩家npc
    self:JudgeState(dt)
    if self._followStep == 1 then
        self:StartFollow(dt)
    elseif self._followStep == 2 then
        self:FollowType2(self._destination)
    end
    if not self._proxy:CheckNpcDistance(self._uuid, self._playerNpcUUID, 10) then
        XScriptTool.DoTeleportNpcPos(self._proxy, self._uuid, self._proxy:TransformPointByActor(self._playerNpcUUID, Vector3(0.9, 0.5, 0)))
    end
    --[[
    --库洛洛rotation始终和主角一致
    local rotationPlayerNpc = self._proxy:GetNpcRotation(self._playerNpcUUID)                         --获取玩家旋转
    self._proxy:SetNpcRotation(self._uuid, rotationPlayerNpc)                                         --设置辅助机旋转
    ]]
    --

    --[[self.destination = self._proxy:TransformPointByActor(self._playerNpcUUID, Vector3(0.9, 0.5, -0.2)) --计算要移动到的坐标
    local distance = Vector3.Distance(self._proxy:GetNpcPosition(self._uuid), self.destination)        --距需要到达的终点距离
    self:FollowType1(distance, dt, self.destination)
    --]]

    --self:FollowType2(distance) --type2:紧紧跟随
end

---@param eventType number
---@param eventArgs userdata
function XCharKuroro:HandleEvent(eventType, eventArgs)
    --XLog.Debug(string.format("库洛洛脚本，UUID:%d，HandleEvent：eventType:%d", self._uuid, eventType))
    if eventType == EWorldEvent.NpcInteractComplete then
        if self._executingInteractBehavior
            and eventArgs.LauncherId == self._uuid
            and eventArgs.TargetId == self._interactTargetUUID
            and eventArgs.OptionId == self._interactOptionId
        then
            XLog.Debug("库洛洛交互完成！")
            self._executingInteractBehavior = false
        end
    end
end

function XCharKuroro:Terminate()
    self._proxy = nil
end

function XCharKuroro:GoToInteractWith(targetUUID, interactOptionId, spotIndex)
    self._interactTargetUUID = targetUUID
    self._interactOptionId = interactOptionId

    self._interactSpot = self._proxy:GetActorInteractionLauncherSpot(targetUUID)
    self._movingToInteractSpot = true
    self._executingInteractBehavior = true
    XLog.Debug(string.format("库洛洛开始去和目标交互:目标UUID:%d,交互选项ID:%d", targetUUID, interactOptionId))
end

---@param targetUUID number @目标npc
---@param position Vector3 @局部坐标
--计算到某个npc某局部坐标的方向（单位向量）
function XCharKuroro:CalDirection(targetUUID, position)
    local selfPos = self._proxy:GetNpcPosition(self._uuid)                      --辅助机位置
    local destination = self._proxy:TransformPointByActor(targetUUID, position) --计算要移动到的坐标
    --XLog.Error("目标位置" .. destination.x, destination.y, destination.z)
    local moveDirection = (destination - selfPos).normalized               --计算方向
    return moveDirection
end

--npc是否处于移动中（有些子状态虽属于move，但其实位移很小，所以要去除），用于决定库洛洛是否位移跟随
function XCharKuroro:IsMoving(npc)
    if self._proxy:CheckNpcFullActionState(npc, ENpcAction.Move, ENpcMoveState.Walk) or
        self._proxy:CheckNpcFullActionState(npc, ENpcAction.Move, ENpcMoveState.Run) or
        self._proxy:CheckNpcFullActionState(npc, ENpcAction.Move, ENpcMoveState.Sprint) or (
            self._proxy:CheckNpcAction(npc, ENpcAction.Jump) and
            (not (self._proxy:CheckNpcFullActionState(npc, ENpcAction.Jump, ENpcJumpState.IdleJumpToStand) or
                self._proxy:CheckNpcFullActionState(npc, ENpcAction.Jump, ENpcJumpState.MoveJumpToStand))))
    then
        return true
    else
        return false
    end
end

--npc是否处于move或jump，具体处于哪种，每种情况下库洛洛赋予不同的加速度
function XCharKuroro:GetMoveMode(npc)
    if self._proxy:CheckNpcAction(npc, ENpcAction.Move) then
        --XLog.Error("=====player is moving=====")
        local moveType = self._proxy:GetNpcMoveType(self._playerNpcUUID)
        if moveType == ENpcMoveType.Walk then
            --XLog.Error("===player is walking===")
            return self._moveMode.Walk
        elseif moveType == ENpcMoveType.Run then
            --XLog.Error("===player is running===")
            return self._moveMode.Run
        elseif moveType == ENpcMoveType.Sprint then
            --XLog.Error("===player is sprinting===")
            return self._moveMode.Sprint
        end
    elseif self._proxy:CheckNpcAction(npc, ENpcAction.Jump) then
        --XLog.Error("===player is jumping===")
        return self._moveMode.Jump
    else
        return self._moveMode.None
    end
end

--过渡跟随
function XCharKuroro:FollowType1(distance, dt, destination)
    local isMoving = self:IsMoving(self._playerNpcUUID) --玩家是否处于移动的动作中
    local moveMode = self:GetMoveMode(self._playerNpcUUID)
    local needMove = false
    if moveMode == self._moveMode.Run then
        self._moveAcceleration = self._moveAccelerationRun
        self._stopAcceleration = self._stopAccelerationRun
        self._maxSpeed = self._maxSpeedRun
    elseif moveMode == self._moveMode.Walk then
        self._moveAcceleration = self._moveAccelerationWalk
        self._stopAcceleration = self._stopAccelerationWalk
        self._maxSpeed = self._maxSpeedWalk
    elseif moveMode == self._moveMode.Sprint then
        self._moveAcceleration = self._moveAccelerationSprint
        self._stopAcceleration = self._stopAccelerationSprint
        self._maxSpeed = self._maxSpeedSprint
    elseif moveMode == self._moveMode.Jump then
        self._moveAcceleration = self._moveAccelerationJump
        self._stopAcceleration = self._stopAccelerationJump
        self._maxSpeed = self._maxSpeedJump
    end

    if distance > 10 then
        XScriptTool.DoTeleportNpcPos(self._proxy, self._uuid, destination)
        --XLog.Debug("距离超过10,执行传送")
    elseif distance > 0.2 and isMoving == false then
        if self._nowSpeed >= 0.0 then
            self._nowSpeed = self._nowSpeed - self._stopAcceleration * dt
            self._nowSpeed = math.max(self._nowSpeed, 1.0)
        end
        needMove = true
        --XLog.Debug("距离小于xx,执行跟随并逐渐减速，目前速度" .. self._nowSpeed)
    elseif distance > 0.2 and isMoving == true then
        if self._nowSpeed < self._maxSpeed then
            self._nowSpeed = self._nowSpeed + self._moveAcceleration * dt --加速
            self._nowSpeed = math.min(self._nowSpeed, self._maxSpeed)
        else
            self._nowSpeed = self._maxSpeed
        end
        needMove = true
        -- 距离<=xx，计算此帧的速度（上一帧速度-加速度）
        --XLog.Debug("距离超过xx,执行跟随并逐渐加速，目前速度" .. self._nowSpeed)
    else
        needMove = false
        --XLog.Debug("距离小于xx,停止移动")
    end
    if needMove then
        local speed = self._nowSpeed * dt                                                           --本帧的移动速度
        --XLog.Error("移动长度计算结果为" .. speed .. "距离为" .. distance)
        speed = math.min(speed, distance)                                                           --移动长度超过距离时，将其降为距离，以便正好到达目标点，避免超过后再回头移动
        local deltaMove = self:CalDirection(self._playerNpcUUID, Vector3(0.9, 0.5, -0.2)) * speed --本帧的三维移动量
        self._proxy:MoveNpc(self._uuid, deltaMove)
    end
end

--紧紧跟随
function XCharKuroro:FollowType2(destination)
    local selfPosition = self._proxy:GetNpcPosition(self._uuid)
    local deltaMove = self._proxy:TransformPointByActor(self._playerNpcUUID, destination) - selfPosition
    self._proxy:SetNpcFaceToPosition(self._uuid, selfPosition + deltaMove) --调整面朝像
    self._proxy:MoveNpc(self._uuid, deltaMove)
end

--跟随状态判断，阶段切换
function XCharKuroro:JudgeState(dt)
    if (self._time - self._previousTime1) >= 0.2 then                                                          --每0.5秒检测一次，防止那种在临界值上抖动的情况
        self._previousTime1 = self._time
        if self._followStep == 0 and not self._proxy:CheckNpcDistance(self._uuid, self._playerNpcUUID, 2) then --【开始跟随】距离达到一定值启动
            self._followStep = 1
        elseif self._followStep == 1 and self._proxy:CheckNpcDistance(self._uuid, self._playerNpcUUID, 1.5) then--到这个距离则算追上，转状态
            if self:IsMoving(self._playerNpcUUID) then
                self._destination = self._proxy:InverseTransformPointByActor(self._playerNpcUUID, self._proxy:GetNpcPosition(self._uuid)) --记录此刻局部坐标（相对位置）
                self._followStep = 2
            else
                self._followStep = 0
            end
        elseif self._followStep == 2 and not self:IsMoving(self._playerNpcUUID) then
            self._followStep = 0
        end
    end
end

--根据与目标距离决定是否开始跟随
function XCharKuroro:StartFollow(dt)
    local destination = nil
    local selfPosition = self._proxy:GetNpcPosition(self._uuid)
    --判断离目标左右哪点更近
    local leftPosition = self._proxy:TransformPointByActor(self._playerNpcUUID, Vector3(0.9, 0.5, 0.0))
    local rightPosition = self._proxy:TransformPointByActor(self._playerNpcUUID, Vector3(-0.9, 0.5, 0.0))
    if Vector3.Distance(selfPosition, leftPosition) >
        Vector3.Distance(selfPosition, rightPosition) then
        destination = rightPosition
    else
        destination = leftPosition
    end
    if Vector3.Distance(self._proxy:GetNpcPosition(self._uuid), destination) > 0.3 then --距离0.3以上才移动
        local deltaMove = (destination - selfPosition).normalized * 5.9 * dt      --这里定义库洛洛的速度
        self._proxy:SetNpcFaceToPosition(self._uuid, selfPosition + deltaMove) --调整面朝像
        self._proxy:MoveNpc(self._uuid, deltaMove)
    end
end

return XCharKuroro
