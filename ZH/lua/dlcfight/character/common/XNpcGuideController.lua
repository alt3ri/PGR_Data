---@class XNpcGuideController @Npc寻路跟随组件
---@field _targetPosition UnityEngine.Vector3 带路目标点
---@field _outOfRouteDistance number 带路时判断玩家脱离路径的距离
---@field _isUseNavMesh boolean 是否使用NavMesh寻路
---@field _isFirstOutOfRoute boolean 是否第一次超出路径
local XNpcGuideController = XClass(nil, "XNpcGuideController")

---寻路跟随状态
local GuideState = {
    None = 0,
    Idle = 1,   -- 到达目标点
    Guide = 2,  -- 向导中
    Wait = 3,   -- 玩家偏离路线, 原地等待玩家
}

---@param proxy XDlcCSharpFuncs
function XNpcGuideController:Ctor(proxy, uuid)
    ---@type XDlcCSharpFuncs
    self._proxy = proxy
    self._uuid = uuid
    
    self._curState = GuideState.None
    self._lastState = GuideState.None
    self._isUseNavMesh = true
    self._isFirstOutOfRoute = false
    self:InitParam()
end

function XNpcGuideController:Update(dt)
    if not self:IsHaveTarget() then
        return
    end
    self:UpdateState(dt)
end

function XNpcGuideController:Terminate()
    self._proxy = nil
    self._uuid = nil
    self._curState = GuideState.None
    self._lastState = GuideState.None
    self._isUseNavMesh = false
    self._isFirstOutOfRoute = false
    self:InitParam()
end

--region API
---设置目标坐标
---@param targetPosition UnityEngine.Vector3 目标坐标
---@param isUseNavMesh boolean 是否使用NavMesh寻路
function XNpcGuideController:SetTargetPosition(targetPosition, isUseNavMesh)
    self._targetPosition = targetPosition
    self._isUseNavMesh = isUseNavMesh
    self:SetState(GuideState.Guide)
end

---设置带路时判断玩家脱离路径的距离
---@param outOfRouteDistance number 带路时判断玩家脱离路径的距离(单位/m)
function XNpcGuideController:SetOutOfRouteDistance(outOfRouteDistance)
    if not outOfRouteDistance or outOfRouteDistance <= 0 then
        return
    end
    self._outOfRouteDistance = outOfRouteDistance
end

function XNpcGuideController:GetTargetPosition()
    return self._targetPosition
end

function XNpcGuideController:GetOutOfRouteDistance()
    return self._outOfRouteDistance
end

function XNpcGuideController:ClearFirstOutOfRoute()
    self._isFirstOutOfRoute = false
end

function XNpcGuideController:IsHaveTarget()
    return self._targetPosition ~= nil
end

function XNpcGuideController:IsFirstOutOfRoute()
    return self._isFirstOutOfRoute
end

function XNpcGuideController:CancelGuide()
    self:StopGuide()
    self:SetState(GuideState.None)
end

---@protected
function XNpcGuideController:GuideToTargetPosition()
    if self._isInGuide then
        return
    end
    if self._isUseNavMesh then
        self._proxy:NpcNavigateTo(self._uuid, self._targetPosition)
    else
        self._proxy:NpcMoveTo(self._uuid, self._targetPosition)
    end
    self._isInGuide = true
end

---@protected
function XNpcGuideController:StopGuide()
    self._isInGuide = false
    self._proxy:NpcStopMove(self._uuid)
end
--endregion

--region Check
---@protected
function XNpcGuideController:InitParam()
    self._isInGuide = false
    self._targetPosition = nil
    self._outOfRouteDistance = 5
end

---@protected
function XNpcGuideController:CheckIsOutOfRoute()
    -- 判断逻辑：玩家与目标点的距离大于向导与目标点的距离且玩家距离目标点超过outOfRoute距离, 视为偏离路线
    local playerUid = self._proxy:GetLocalPlayerNpcId()
    local player2TargetDistance = self._proxy:CalcNpcDistanceWitchPos(playerUid, self._targetPosition.x, self._targetPosition.y, self._targetPosition.z)
    local guide2TargetDistance = self._proxy:CalcNpcDistanceWitchPos(self._uuid, self._targetPosition.x, self._targetPosition.y, self._targetPosition.z)
    local guide2playerDistance = self._proxy:CalcNpcDistance(self._uuid, playerUid)
    if guide2playerDistance > self._outOfRouteDistance and player2TargetDistance > guide2TargetDistance then
        return true
    end
    return false
end

---@protected
function XNpcGuideController:CheckIsArriveTarget()
    return self._proxy:CheckNpcDistanceWithPos(self._uuid, self._guideTargetPosition.x, self._guideTargetPosition.y, self._guideTargetPosition.z, 2)
end
--endregion

--region State
---@protected
function XNpcGuideController:UpdateState(dt)
    if self._curState == GuideState.None then
        return
    end
    -- 状态转移判断
    if self:CheckIsOutOfRoute() then
        self:SetState(GuideState.Wait)
    elseif self:CheckIsArriveTarget() then
        self:SetState(GuideState.Idle)
    elseif self:IsHaveTarget() then
        self:SetState(GuideState.Guide)
    end
end

---@protected
function XNpcGuideController:SetState(nextState)
    if self._curState == nextState then
        return
    end
    self:OnEnterState(nextState)

    self._lastState = self._curState
    self._curState = nextState
    XLog.Debug("XNpcGuideController 进入状态"..self._curState)
end

---@protected
function XNpcGuideController:OnEnterState(nextState)
    if nextState == GuideState.Idle then
        self:StopGuide()
        self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(self._proxy:GetLocalPlayerNpcId()))
    elseif nextState == GuideState.Guide then
        self:GuideToTargetPosition()
    elseif nextState == GuideState.Wait then
        if not self._isFirstOutOfRoute then
            self._isFirstOutOfRoute = true
        end
        self:StopGuide()
        self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(self._proxy:GetLocalPlayerNpcId()))
    elseif nextState == GuideState.None then
        self:InitParam()
    end
end
--endregion

return XNpcGuideController