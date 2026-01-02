local XLevelNpcState = require("Common/StateMachine/State/XLevelNpcState")

---@class XFindPathState: XLevelNpcState @寻路过程状态
---@field StartPos Vector3 启始点
---@field TargetPos Vector3 目标点
---@field Path Vector3[] 寻路路径
---@field CheckDistance number 到达路径点判定距离
---@field _curPathPointIndex number 当前所处路径点索引
---@field _curTargetPathPoint number 当前目标路径点
---@field _pathPointCount number 路径点数量
---@field _isMove boolean 是否在移动
---@field _curCheckPathTime boolean 自动检查寻路
local XFindPathState = XClass(XLevelNpcState, "XFindPathState")

---@overload
function XFindPathState:OnStateEnter(lastStateEnum)
    if self._curTargetPathPoint then
        self._proxy:NpcNavigateTo(self._uuid, self._curTargetPathPoint, ENpcMoveType.Walk)
    end
end

---@overload
function XFindPathState:OnStateLeave(nextStateEnum)
    self._proxy:NpcStopMove(self._uuid)
end

---@overload
function XFindPathState:OnStateUpdate(dt)
    if not self.Path then
        return
    end
    if self._isMove then
        self._curCheckPathTime = self._curCheckPathTime - dt
        if self._curCheckPathTime <= 0 then
            self:ContinueMove()
            self._curCheckPathTime = 4
        end
    end
    if self._proxy:CheckNpcDistanceWithPos(self._uuid, self._curTargetPathPoint.x, self._curTargetPathPoint.y, self._curTargetPathPoint.z, self.CheckDistance) then
        self:MoveNext()
    end
end

---@overload
function XFindPathState:OnMoveNext()
end

---移动到下一个路近点
---@private
function XFindPathState:MoveNext()
    self._curPathPointIndex = self._curPathPointIndex + 1
    if self._curPathPointIndex > self._pathPointCount then
        self._curPathPointIndex = self._pathPointCount
    end

    self:OnMoveNext()
    self:StartMove()
    --XLog.Debug("[脚本: "..self._proxy.Id.."]寻路状态路径前往路径第:"..self._curPathPointIndex.."个路径点", self._curTargetPathPoint)
end

---@protected
function XFindPathState:SetMoveState(value)
    self._isMove = value
end

--region API
---设置路径点
function XFindPathState:SetPath(path, checkDistance)
    self._pathPointCount = #path
    if self._pathPointCount < 2 then
        self.Path = nil
        return
    end
    self.Path = path
    if checkDistance ~= nil and checkDistance > 0 then
        self.CheckDistance = checkDistance
    else
        self.CheckDistance = 1
    end
    self.StartPos = self.Path[1]
    self.TargetPos = self.Path[self._pathPointCount]
    self._curPathPointIndex = 1
    self._curCheckPathTime = 4
    --XLog.Debug("[脚本: "..self._proxy.Id.."]寻路状态路径起始点: "..self.CheckDistance)
end

---继续移动
function XFindPathState:ContinueMove()
    self:SetMoveState(true)
    self._proxy:NpcNavigateTo(self._uuid, self._curTargetPathPoint, ENpcMoveType.Walk)
    --if self._curCheckPathTime > 0 then
    --    XLog.Debug("[脚本: "..self._proxy.Id.."]寻路状态Start 当前坐标:", self._proxy:GetNpcPosition(self._uuid),
    --            "路径目标点:", self._curTargetPathPoint,
    --            "最终目标点:", self.TargetPos,
    --            "当前路径:", self.Path)
    --else
    --    XLog.Debug("[脚本: "..self._proxy.Id.."]寻路状态重新寻路 当前坐标:", self._proxy:GetNpcPosition(self._uuid),
    --            "路径目标点:", self._curTargetPathPoint,
    --            "最终目标点:", self.TargetPos,
    --            "当前路径:", self.Path)
    --end
end

---开始移动
function XFindPathState:StartMove()
    local nextIndex = self._curPathPointIndex + 1
    if nextIndex > self._pathPointCount then
        nextIndex = self._pathPointCount
    end
    self._curTargetPathPoint = self.Path[nextIndex]
    self:ContinueMove()
end

---停止移动
function XFindPathState:StopMove()
    self._proxy:NpcStopMove(self._uuid)
    self._proxy:EnableNpcLookAt(self._uuid, self._proxy:GetLocalPlayerNpcId())
    self:SetMoveState(false)
    --XLog.Debug("[脚本: "..self._proxy.Id.."]寻路状态Stop 当前坐标:", self._proxy:GetNpcPosition(self._uuid),
    --        "路径目标点:", self._curTargetPathPoint,
    --        "最终目标点:", self.TargetPos,
    --        "当前路径:", self.Path)
end

---更新当前寻路路径点
function XFindPathState:UpdateCurPathPointIndex(index)
    self._curPathPointIndex = index
    --XLog.Debug("[脚本: "..self._proxy.Id.."]寻路状态路径设置当前目标点: "..self.CheckDistance)
end
--endregion

return XFindPathState