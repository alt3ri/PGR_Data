local XLevelNpcStateTransition = require("Common/StateMachine/Transition/XLevelNpcStateTransition")

---@class XFindPath2OtherTransition: XLevelNpcStateTransition 寻路到其他状态
---@field _fromState XFindPathState
---@field _targetPos Vector3 目标点
---@field _checkDistance number 到达距离判断
---@field _placeId number
---@field _uuid number
local XFindPath2OtherTransition = XClass(XLevelNpcStateTransition, "XFindPath2OtherTransition")

---@overload
function XFindPath2OtherTransition:InitOther(targetPos, checkDistance)
    self._targetPos = targetPos
    if checkDistance ~= nil and checkDistance > 0 then
        self._checkDistance = checkDistance
    else
        self._checkDistance = 5
    end
end

---@overload
---@return boolean
function XFindPath2OtherTransition:Condition(dt)
    if not self._proxy:GetNpcActive(self._uuid) 
            or self._proxy:CheckNpcIsInInteract(self._placeId)
            or (self._fromState.StartPos and XScriptTool.EqualVector3(self._fromState.StartPos, self._targetPos))
    then
        return false
    end
    if self._proxy:CheckNpcDistanceWithPos(self._uuid, self._targetPos.x, self._targetPos.y, self._targetPos.z, self._checkDistance) then
        return true
    end
    return false
end

return XFindPath2OtherTransition