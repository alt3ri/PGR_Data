---@class XUiPacMan2MoveTo
local XUiPacMan2MoveTo = XClass(nil, "XUiPacMan2MoveTo")

function XUiPacMan2MoveTo:Ctor(transform, speed)
    self._Timer = false
    self._TargetPosition = false
    self._Transform = transform or false
    self._Speed = speed or false
end

function XUiPacMan2MoveTo:SetSpeed(speed)
    self._Speed = speed
end

function XUiPacMan2MoveTo:SetTargetPosition(position)
    self._TargetPosition = position
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:_Move()
        end, 0)
    end
end

function XUiPacMan2MoveTo:_Move()
    if self._Transform and self._TargetPosition then
        local deltaTime = CS.UnityEngine.Time.deltaTime
        local direction = self._TargetPosition - self._Transform.position
        local distanceSquared = direction.sqrMagnitude
        local moveDistance = self._Speed * deltaTime
        
        -- 如果剩余距离小于等于这帧应该移动的距离，则直接到达目标并停止
        if distanceSquared <= moveDistance * moveDistance then
            self._Transform.position = self._TargetPosition
            self:Stop()
            return
        end
        
        -- 否则按方向和速度移动
        self._Transform.position = self._Transform.position + direction.normalized * moveDistance
        
        -- 检查是否已经接近目标位置
        if (self._Transform.position - self._TargetPosition).sqrMagnitude < 0.1 then
            self._Transform.position = self._TargetPosition
            self:Stop()
        end
    else
        XLog.Error("XUiPacMan2MoveTo:SetTargetPosition() _Transform or _TargetPosition is nil")
        self:Stop()
    end
end

function XUiPacMan2MoveTo:Stop()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
    self._TargetPosition = false
end

-- 必须destroy，否则会内存泄漏，持有transform，来自unity
function XUiPacMan2MoveTo:Destroy()
    self:Stop()
    self._Transform = false
    self._Speed = false
end

return XUiPacMan2MoveTo