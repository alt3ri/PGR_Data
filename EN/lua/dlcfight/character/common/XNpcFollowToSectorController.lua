---@class XNpcFollowToSectorController @Npc寻路跟随组件，目标点从一个扇形中取点（警告：已停止维护，请不要使用！）
-- 警告：已停止维护，请不要使用！
-- 警告：已停止维护，请不要使用！
-- 警告：已停止维护，请不要使用！
local XNpcFollowToSectorController = XClass(nil, "XNpcFollowToSectorController")

---寻路跟随状态
local FollowState = {
    None = 0,
    Idle = 1,
    Follow = 2,
    ChaseFollow = 3,
}


---@param proxy XDlcCSharpFuncs
function XNpcFollowToSectorController:Ctor(proxy, uuid, isCloseIdleLookAt)
    ---@type XDlcCSharpFuncs
    self._proxy = proxy
    self._uuid = uuid
    -- 目标相关
    self._targetNpcUUID = 0
    self._targetAngle = 0
    self._targetRadius = 0
    self._targetPos = { x = 0, y = 0, z = 0 }
    self._raycastOffset = { x = 0, y = 0.75, z = 0 } -- 用步高做一次偏移
    -- 跟随状态相关
    self._curState = FollowState.None
    self._lastState = FollowState.None
    self._idleLookAtTargetSwitch = not isCloseIdleLookAt
    -- 跟随状态切换范围
    self._maxIdleRange = 0
    self._startFollowRange = 0
    self._chaseFollowDelayTime = 0
    self._curFollowTime = 0
    -- 停止状态注视目标延迟
    self._idleLookAtTargetDelayTime = 0
    self._lastIdleTime = 0
    self._curIdleTime = 0
    -- 跟随寻路配置
    self._findPathTimeCD = 0.1
    self._curFindPathCDTime = 0
    self._tryFindPath = true
    self._findTargetPosCD = 0.1
    self._curFindTargetPosCDTime = 0
    self._tryFindTargetPos = true
    -- 旋转面向相关
    self._canRotate = false
    -- 目标点参数
    self._finalEuler = { x = 0, y = 0, z = 0}
    -- 是否使用NavMesh寻路
    self._isUseNavMesh = true
    -- 是否超出范围时强制传送
    self._isOutOfRangeThenTeleport = false
    self._teleportRange = 0
end

function XNpcFollowToSectorController:Update(dt)
    if not self:IsHaveTarget() then
        return
    end

    -- 超出范围则传送判断
    self:UpdateOutOfFollowRangeThenTeleport()
    -- 跟随状态切换
    self:UpdateState(dt)
    -- 尝试向玩家位置旋转
    self:TryRotate()
    -- 更新目标点
    self:TryFindTargetPos()
    -- 寻路跟随
    self:TryFindPath()
    -- 寻路跟随CD
    self:UpdateCD(dt)
end

function XNpcFollowToSectorController:Terminate()
    self._proxy = nil
    self._uuid = nil
    self._targetNpcUUID = nil
    self._targetRadius = nil
    self._targetAngle = nil

    self._lastState = nil
    self._curState = nil

    self._maxIdleRange = nil
    self._chaseFollowDelayTime = nil
    self._curFollowTime = nil

    self._curFindPathCDTime = nil
    self._tryFindPath = nil
    self._curFindTargetPosTime = nil

    self._finalEuler = nil

    self._isUseNavMesh = nil
end

--region API
---设置跟随目标（使用NavMesh寻路）
---@param targetNpcUUID number 目标NpcId
---@param targetAngle number 目标点扇形角度
---@param targetRadius number 目标点扇形半径
---@param maxIdleRange number 待机距离阈值(单位/m)
---@param startFollowRange number 跟随距离阈值(单位/m)
---@param chaseFollowDelayTime number 追逐跟随延迟时间(单位/s)
---@param idleLookAtTargetDelayTime number 待机状态开始注视目标前的延迟时间(单位/s)
function XNpcFollowToSectorController:SetFollowTargetNpc(targetNpcUUID, targetAngle, targetRadius, maxIdleRange, startFollowRange, chaseFollowDelayTime, idleLookAtTargetDelayTime)
    self:SetTargetNpc(targetNpcUUID, targetAngle, targetRadius, maxIdleRange, startFollowRange, chaseFollowDelayTime, idleLookAtTargetDelayTime, true)
    self:StartFindPath()
end

---设置跟随目标（不使用NavMesh寻路）
---@param targetNpcUUID number 目标NpcId
---@param targetAngle number 目标点扇形角度
---@param targetRadius number 目标点扇形半径
---@param maxIdleRange number 待机距离阈值(单位/m)
---@param startFollowRange number 跟随距离阈值(单位/m)
---@param chaseFollowDelayTime number 追逐跟随延迟时间(单位/s)
---@param idleLookAtTargetDelayTime number 待机状态开始注视目标前的延迟时间(单位/s)
function XNpcFollowToSectorController:SetFollowTargetNpcNoNavMesh(targetNpcUUID, targetAngle, targetRadius, maxIdleRange, startFollowRange, chaseFollowDelayTime, idleLookAtTargetDelayTime)
    self:SetTargetNpc(targetNpcUUID, targetAngle, targetRadius, maxIdleRange, startFollowRange, chaseFollowDelayTime, idleLookAtTargetDelayTime, false)
    self:StartFindPath()
end

---@param targetNpcUUID number 目标NpcId
---@param targetAngle number 目标点扇形角度
---@param targetRadius number 目标点扇形半径
function XNpcFollowToSectorController:SetTargetParam(targetNpcUUID, targetAngle, targetRadius)
    self._targetNpcUUID = targetNpcUUID
    self._targetAngle = targetAngle
    self._targetRadius = targetRadius
end

---@param maxIdleRange number 待机距离阈值(单位/m)
function XNpcFollowToSectorController:SetMaxIdleRange(maxIdleRange)
    if maxIdleRange <= 0 or self._maxIdleRange == maxIdleRange then
        return
    end
    self._maxIdleRange = maxIdleRange
end

---@param startFollowRange number 跟随距离阈值(单位/m)
function XNpcFollowToSectorController:SetStartFollowRange(startFollowRange)
    if startFollowRange <= 0 or self._maxIdleRange == startFollowRange then
        return
    end
    self._startFollowRange = startFollowRange
end

---@param delayTime number 进入追赶跟随前的延迟时间
function XNpcFollowToSectorController:SetChaseFollowDelayTime(delayTime)
    if delayTime < 0 then
        return
    end

    self._chaseFollowDelayTime = delayTime
end

---@param delayTime number 待机状态开始注视目标前的延迟时间
function XNpcFollowToSectorController:SetIdleLookAtTargetDelayTime(delayTime)
    if delayTime < 0 then
        return
    end

    self._idleLookAtTargetDelayTime = delayTime
end

---开启超出跟随范围则强制传送到目标附近功能
---@param followRange number 跟随范围(单位/m)
function XNpcFollowToSectorController:OpenOutOfRangeThenTeleport(followRange)
    self._isOutOfRangeThenTeleport = true
    self._teleportRange = followRange
end

---关闭超出跟随范围则强制传送到目标附近功能
function XNpcFollowToSectorController:CloseOutOfRangeThenTeleport()
    self._isOutOfRangeThenTeleport = false
end

---取消目标跟随
function XNpcFollowToSectorController:CancelFollow()
    self._targetNpcUUID = 0
    self._curState = FollowState.Idle

    self:StopFindPath()
end

---是否存在跟随目标
function XNpcFollowToSectorController:IsHaveTarget()
    return self._targetNpcUUID > 0
end

---是否在待机状态
function XNpcFollowToSectorController:IsIdle()
    return self:IsHaveTarget() and self._curState == FollowState.Idle
end

---是否在跟随状态
function XNpcFollowToSectorController:IsFollow()
    return self:IsHaveTarget() and
            (self._curState == FollowState.Follow or self._curState == FollowState.ChaseFollow)
end
--endregion

--region SetTarget
---设置跟随目标
---@protected
---@param targetNpcUUID number 目标NpcId
---@param targetAngle number 目标点扇形角度
---@param targetRadius number 目标点扇形半径
---@param maxIdleRange number 待机距离阈值(单位/m)
---@param startFollowRange number 跟随距离阈值(单位/m)
---@param chaseFollowDelayTime number 追逐跟随延迟时间(单位/m)
---@param idleLookAtTargetDelayTime number 待机状态开始注视目标前的延迟时间(单位/s)
function XNpcFollowToSectorController:SetTargetNpc(targetNpcUUID, targetAngle, targetRadius, maxIdleRange, startFollowRange, chaseFollowDelayTime, idleLookAtTargetDelayTime, isUseNavMesh)
    self:SetTargetParam(targetNpcUUID, targetAngle, targetRadius)
    self:SetIdleLookAtTargetDelayTime(idleLookAtTargetDelayTime)
    self:SetMaxIdleRange(maxIdleRange)
    self:SetStartFollowRange(startFollowRange)
    self:SetChaseFollowDelayTime(chaseFollowDelayTime)
    self._isUseNavMesh = isUseNavMesh
    self._curFollowTime = 0
    self._curFindTargetPosTime = 0
end
--endregion

--region FollowRangeTeleport
---@protected
function XNpcFollowToSectorController:UpdateOutOfFollowRangeThenTeleport()
    if not self._isOutOfRangeThenTeleport then
        return
    end
    local distance = self:GetTargetNpcDistance()
    if distance > self._teleportRange and distance > self._chaseFollowDelayTime then
        local randX = self._proxy:Random(50, 100)
        local randZ = self._proxy:Random(50, 100)
        local pos = self:GetTargetNpcPos()
        pos.x = pos.x + randX / 100
        pos.z = pos.z + randZ / 100
        XScriptTool.DoTeleportNpcPos(self._proxy, self._uuid, pos)
    end
end
--endregion

--region FindPath
---@protected
function XNpcFollowToSectorController:StopFindPath()
    self._curFindPathCDTime = 0
    self._tryFindPath = false
    self._proxy:NpcStopMove(self._uuid)
end

---@protected
function XNpcFollowToSectorController:StartFindPath()
    self._curFindPathCDTime = 0
    self._tryFindPath = true
end

---@protected
function XNpcFollowToSectorController:UpdateCD(dt)
    self._curFindTargetPosCDTime = self._curFindTargetPosCDTime + dt
    if self._curFindTargetPosCDTime >= self._findTargetPosCD then
        self._tryFindTargetPos = true
        self._curFindTargetPosCDTime = 0
    end

    if self:IsIdle() then
        return
    end

    self._curFindPathCDTime = self._curFindPathCDTime + dt
    if self._curFindPathCDTime >= self._findPathTimeCD then
        self._tryFindPath = true
        self._curFindPathCDTime = 0
    end
end

---@protected
function XNpcFollowToSectorController:TryFindTargetPos()
    if not self:IsHaveTarget() or not self._tryFindTargetPos then
        return
    end

    local selfPos = self._proxy:GetNpcPosition(self._uuid)
    local selfPosInLocalSpace = self._proxy:GetLocalPosInNpcLocalSpace(selfPos, self._targetNpcUUID)
    local isSelfOnTargetRight = selfPosInLocalSpace.x > 0
    local finalAngle = self._targetAngle
    local finalRadius = self._targetRadius

    -- 保持目标点在当前与跟随目标的同一手侧
    if not isSelfOnTargetRight then
        finalAngle = -1 * finalAngle
    end

    -- 射线检测跟随目标到预定目标点之间是否有碰撞
    self._finalEuler.y = finalAngle
    local hitObstacle, hitPos = self._proxy:CheckNpcRayCastStaticCollider(self._targetNpcUUID, self._raycastOffset, self._finalEuler, finalRadius)
    if hitObstacle then
        self._targetPos = hitPos
    else
        self._targetPos = self._proxy:GetNpcOffsetPositionByFacing(self._targetNpcUUID, self._finalEuler, finalRadius)
    end

    self._tryFindTargetPos = false
end

---@protected
function XNpcFollowToSectorController:TryRotate()
    if self._canRotate then
        -- 扭头超过最大角度时根节点转向玩家
        if self._proxy:IsNpcAngleReachMaxLookAtAngleOnHorizontal(self._uuid, self._targetNpcUUID) then
            self._proxy:TurnNpcOnce(self._uuid, self._targetNpcUUID)
        end
    end
end

---@protected
function XNpcFollowToSectorController:TryFindPath()
    if not self._tryFindPath then
        return
    end

    -- 确定移动方式
    local npcMoveType = ENpcMoveType.Run
    if self._curState == FollowState.ChaseFollow then
        npcMoveType = ENpcMoveType.Sprint
    end

    -- 移动
    if self._isUseNavMesh then
        self._proxy:NpcNavigateTo(self._uuid, self._targetPos, npcMoveType)
    else
        self._proxy:NpcMoveTo(self._uuid, self._targetPos, npcMoveType)
    end
    self._tryFindPath = false
end
--endregion

--region State
---@protected
function XNpcFollowToSectorController:UpdateState(dt)
    -- 距离检测切换跟随状态
    local disToTargetPoint = self:GetTargetPointDistance()
    local disToTargetNpc = self:GetTargetNpcDistance()
    if disToTargetPoint <= self._maxIdleRange  then
        if self:IsFollow() then
            if not self._proxy:IsNpcMoving(self._targetNpcUUID) then
                self:SetState(FollowState.Idle)
            end
        else
            self:SetState(FollowState.Idle)
        end
    elseif disToTargetNpc > self._startFollowRange and self._curFollowTime <= self._chaseFollowDelayTime then
        self:SetState(FollowState.Follow)
    elseif self._curFollowTime > self._chaseFollowDelayTime then
        self:SetState(FollowState.ChaseFollow)
    end

    if self:IsIdle() then  -- 待机时保持注视目标
        self._curFollowTime = 0
        self._lastIdleTime = self._curIdleTime
        self._curIdleTime = self._curIdleTime + dt
        if self._idleLookAtTargetSwitch
                and self._lastIdleTime < self._idleLookAtTargetDelayTime
                and self._curIdleTime >= self._idleLookAtTargetDelayTime
        then
            self._canRotate = true
            self._proxy:EnableNpcLookAt(self._uuid, self._targetNpcUUID)
        end
    else
        self._curFollowTime = self._curFollowTime + dt
        self._curIdleTime = 0
        self._canRotate = false
        self._proxy:DisableNpcLookAt(self._uuid)
    end
end

---@protected
function XNpcFollowToSectorController:SetState(nextState, dt)
    self._lastState = self._curState

    if self._curState == nextState then
        return
    end
    self:OnExitState(self._curState, nextState)
    self:OnEnterState(self._curState, nextState)
    
    self._curState = nextState
    XLog.Debug("XNpcFollowToSectorController 进入状态"..self._curState)
end

---@protected
function XNpcFollowToSectorController:OnExitState(curState, nextState)
    if curState == FollowState.Idle then
    elseif curState == FollowState.Follow then
    elseif curState == FollowState.ChaseFollow then
    end
end

---@protected
function XNpcFollowToSectorController:OnEnterState(curState, nextState)
    if nextState == FollowState.Idle then
        self:StopFindPath()
    elseif nextState == FollowState.Follow then
        self:StartFindPath()
    elseif nextState == FollowState.ChaseFollow then
        self:StartFindPath()
    end
end
--endregion

--region Target
---@protected
function XNpcFollowToSectorController:GetTargetNpcDistance()
    local selfPos = self._proxy:GetNpcPosition(self._uuid)
    local targetPos = self:GetTargetNpcPos()
    return XScriptTool.Distance(selfPos, targetPos)
end

---@protected
function XNpcFollowToSectorController:GetTargetPointDistance()
    local selfPos = self._proxy:GetNpcPosition(self._uuid)
    return XScriptTool.Distance(selfPos, self._targetPos)
end

---@protected
function XNpcFollowToSectorController:GetTargetNpcPos()
    return self._proxy:GetNpcPosition(self._targetNpcUUID)
end
--endregion

return XNpcFollowToSectorController