---@class XNpcFollowController @Npc寻路跟随组件
local XNpcFollowController = XClass(nil, "XNpcFollowController")

---寻路跟随状态
local FollowState = {
    None = 0,
    Idle = 1,
    Follow = 2,
    RunFollow = 3,
}

---@param proxy XDlcCSharpFuncs
function XNpcFollowController:Ctor(proxy, uuid, isCloseIdleLookAt)
    ---@type XDlcCSharpFuncs
    self._proxy = proxy
    self._uuid = uuid
    self._targetNpcUUID = 0
    -- 跟随状态相关
    self._curState = FollowState.None
    self._lastState = FollowState.None
    self._idleLookAtTargetSwitch = not isCloseIdleLookAt
    -- 跟随状态切换范围
    self._idleLimit = 0
    self._runLimit = 0
    -- 跟随寻路配置
    self._findPathTimeCD = 1
    self._curFindCDTime = 0
    self._tryFindPath = true
    -- 是否使用NavMesh寻路
    self._isUseNavMesh = true
    -- 是否超出范围时强制传送
    self._isOutOfRangeThenTeleport = false
    self._followRange = 0
end

function XNpcFollowController:Update(dt)
    if not self:IsHaveTarget() then
        return
    end
    
    -- 超出范围则传送判断
    self:UpdateOutOfFollowRangeThenTeleport()
    -- 跟随状态切换
    self:UpdateState(dt)
    -- 寻路跟随
    self:TryFindPath()
    -- 寻路跟随CD
    self:UpdateFindPathCD(dt)
end

function XNpcFollowController:Terminate()
    self._proxy = nil
    self._uuid = nil
    self._targetNpcUUID = nil

    self._curState = nil

    self._idleLimit = nil
    self._runLimit = nil

    self._findPathTimeCD = nil
    self._curFindCDTime = nil
    self._tryFindPath = nil
    
    self._isUseNavMesh = nil
end

--region API
---设置跟随目标（使用NavMesh寻路）
---@param targetNpcUUID number 目标NpcId
---@param idleLimit number 待机距离阈值(单位/m)
---@param runLimit number 奔跑跟随距离阈值(单位/m)
---@param findPathCd number 寻路频率(单位/s)
function XNpcFollowController:SetFollowTargetNpc(targetNpcUUID, idleLimit, runLimit, findPathCd)
    self:SetTargetNpc(targetNpcUUID, idleLimit, runLimit, findPathCd, true)
    self:StartFindPath()
end

---设置跟随目标（不使用NavMesh寻路）
---@param targetNpcUUID number 目标NpcId
---@param idleLimit number 待机距离阈值(单位/m)
---@param runLimit number 奔跑跟随距离阈值(单位/m)
---@param findPathCd number 寻路频率(单位/s)
function XNpcFollowController:SetFollowTargetNpcNoNavMesh(targetNpcUUID, idleLimit, runLimit, findPathCd)
    self:SetTargetNpc(targetNpcUUID, idleLimit, runLimit, findPathCd, false)
    self:StartFindPath()
end

---@param idleLimit number 待机距离阈值(单位/m)
function XNpcFollowController:SetIdleLimit(idleLimit)
    if idleLimit <= 0 or self._idleLimit == idleLimit then
        return
    end
    self._idleLimit = idleLimit
end

---@param runLimit number 奔跑跟随距离阈值(单位/m)
function XNpcFollowController:SetRunLimit(runLimit)
    if runLimit <= 0 or self._runLimit == runLimit then
        return
    end
    if runLimit < self._idleLimit then
        self._runLimit = self._idleLimit
        return
    end
    self._runLimit = runLimit
end

---开启超出跟随范围则强制传送到目标附近功能
---@param followRange number 跟随范围(单位/m)
function XNpcFollowController:OpenOutOfRangeThenTeleport(followRange)
    self._isOutOfRangeThenTeleport = true
    self._followRange = followRange
end

---关闭超出跟随范围则强制传送到目标附近功能
function XNpcFollowController:CloseOutOfRangeThenTeleport()
    self._isOutOfRangeThenTeleport = false
end

---取消目标跟随
function XNpcFollowController:CancelFollow()
    self._targetNpcUUID = 0
    self._curState = FollowState.Idle

    self:StopFindPath()
end

---是否存在跟随目标
function XNpcFollowController:IsHaveTarget()
    return self._targetNpcUUID > 0
end

---是否在待机状态
function XNpcFollowController:IsIdle()
    return self:IsHaveTarget() and self._curState == FollowState.Idle
end

---是否在跟随状态
function XNpcFollowController:IsFollow()
    return self:IsHaveTarget() and
            (self._curState == FollowState.Follow or self._curState == FollowState.RunFollow)
end
--endregion

--region SetTarget
---设置跟随目标
---@protected
---@param targetNpcUUID number 目标NpcId
---@param idleLimit number 待机距离阈值(单位/m)
---@param runLimit number 奔跑跟随距离阈值(单位/m)
---@param findPathCd number 寻路频率(单位/s)
function XNpcFollowController:SetTargetNpc(targetNpcUUID, idleLimit, runLimit, findPathCd, isUseNavMesh)
    self._targetNpcUUID = targetNpcUUID
    self:SetIdleLimit(idleLimit)
    self:SetRunLimit(runLimit)
    if findPathCd then
        self._findPathTimeCD = findPathCd
    end
    self._isUseNavMesh = isUseNavMesh
end
--endregion

--region FollowRangeTeleport
---@protected
function XNpcFollowController:UpdateOutOfFollowRangeThenTeleport()
    if not self._isOutOfRangeThenTeleport then
        return
    end
    local distance = self:GetTargetDistance()
    if distance > self._followRange and distance > self._runLimit then
        local randX = self._proxy:Random(50, 100)
        local randZ = self._proxy:Random(50, 100)
        local pos = self:GetTargetPos()
        pos.x = pos.x + randX / 100
        pos.z = pos.z + randZ / 100
        XScriptTool.DoTeleportNpcPos(self._proxy, self._uuid, pos)
    end
end
--endregion

--region FindPath
---@protected
function XNpcFollowController:StopFindPath()
    self._curFindCDTime = 0
    self._tryFindPath = false
    self._proxy:NpcStopMove(self._uuid)
end

---@protected
function XNpcFollowController:StartFindPath()
    self._curFindCDTime = 0
    self._tryFindPath = true
end

---@protected
function XNpcFollowController:UpdateFindPathCD(dt)
    if self:IsIdle() then
        return
    end
    self._curFindCDTime = self._curFindCDTime + dt
    if self._curFindCDTime >= self._findPathTimeCD then
        self._tryFindPath = true
        self._curFindCDTime = 0
    end
end

---@protected
function XNpcFollowController:TryFindPath()
    if not self._tryFindPath then
        return
    end
    local npcMoveType = ENpcMoveType.Run
    if self._curState == FollowState.Follow then
        npcMoveType = self._proxy:GetNpcMoveType(self._targetNpcUUID)
    end
    local targetPos = self:GetTargetPos()
    if self._isUseNavMesh then
        self._proxy:NpcNavigateTo(self._uuid, targetPos, npcMoveType)
    else
        self._proxy:NpcMoveTo(self._uuid, targetPos, npcMoveType)
    end
    self._tryFindPath = false
end
--endregion

--region State
---@protected
function XNpcFollowController:UpdateState(dt)
    -- 距离检测切换跟随状态
    local distance = self:GetTargetDistance()
    if distance <= self._idleLimit then
        self:SetState(FollowState.Idle)
    elseif self._idleLimit < distance and distance <= self._runLimit then
        self:SetState(FollowState.Follow)
    elseif self._runLimit < distance then
        self:SetState(FollowState.RunFollow)
    end

    if self._curState == FollowState.Idle then  -- 待机时保持注视目标
        if self._idleLookAtTargetSwitch then
            self._proxy:SetNpcFaceToPosition(self._uuid, self:GetTargetPos())
        end
    elseif self._curState == FollowState.Follow then    -- 保持和目标相同移动方式
        local selfMoveType = self._proxy:GetNpcMoveType(self._uuid)
        local targetMoveType = self._proxy:GetNpcMoveType(self._uuid)
        if selfMoveType == targetMoveType then
            return
        end
        self._proxy:SetNpcMoveType(self._uuid, targetMoveType)
    elseif self._curState == FollowState.RunFollow then
        
    end
end

---@protected
function XNpcFollowController:SetState(nextState)
    if self._curState == nextState then
        return
    end
    self:OnExitState(self._curState, nextState)
    self:OnEnterState(self._curState, nextState)
    
    self._lastState = self._curState
    self._curState = nextState
    XLog.Debug("XNpcFollowController 进入状态"..self._curState)
end

---@protected
function XNpcFollowController:OnExitState(curState, nextState)
    if curState == FollowState.Idle then
    elseif curState == FollowState.Follow then
    elseif curState == FollowState.RunFollow then
    end
end

---@protected
function XNpcFollowController:OnEnterState(curState, nextState)
    if nextState == FollowState.Idle then
        self:StopFindPath()
    elseif nextState == FollowState.Follow then
        self:StartFindPath()
    elseif nextState == FollowState.RunFollow then
        self:StartFindPath()
    end
end
--endregion

--region Target
---@protected
function XNpcFollowController:GetTargetDistance()
    local selfPos = self._proxy:GetNpcPosition(self._uuid)
    local targetPos = self:GetTargetPos()
    return XScriptTool.Distance(selfPos, targetPos)
end

---@protected
function XNpcFollowController:GetTargetPos()
    return self._proxy:GetNpcPosition(self._targetNpcUUID)
end
--endregion

return XNpcFollowController