--- 关卡开始聚焦圈：从池中取出后定位并播放 GridCircleEnable，播完自动回池
---@class XUiGridDyeMergeCircle: XUiNode
---@field Parent XUiDyeMergeGameGridPools
local XUiGridDyeMergeCircle = XClass(XUiNode, "XUiGridDyeMergeCircle")

function XUiGridDyeMergeCircle:OnStart()
    self._RecycleCb = function()
        self:_ReturnToPool()
    end
end

function XUiGridDyeMergeCircle:PlayAndRecycle()
    self:Open()
    if self:GetTimelineTransform("GridCircleEnable") then
        self:PlayAnimation("GridCircleEnable", self._RecycleCb)
    else
        self:_ReturnToPool()
    end
end

function XUiGridDyeMergeCircle:_ReturnToPool()
    local board = self.Parent.Parent
    if board and board.OnCircleRecycled then
        board:OnCircleRecycled(self)
    end
    self.Parent:ReturnCircle(self)
end

return XUiGridDyeMergeCircle
