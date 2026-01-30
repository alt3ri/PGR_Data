--- UI功能显示控制节点基类
--- 用于根据functionId、condition控制节点的显示、锁定状态、红点等
---@class XUiFunctionShowNode: XUiNode
local XUiFunctionShowNode = XClass(XUiNode, 'XUiFunctionShowNode')

--region XUiNode-Override

---子节点状态标记
local XUiNodeState = {
    None = 0,
    Start = 1,
    Enable = 2,
    Disable = 3,
    Destroy = 4,
    Release = 5
}

--- 重写Open方法，阻断Start流程
--- Start是初次显示时调用，如果父节点不显示，也不让它跑Start流程
function XUiFunctionShowNode:CallStart()
    if self:CheckParentIsShow() then
        XUiNode.CallStart(self)
    end
end

--- 重写Enable方法，在内部阻断流程，而非正常执行但检查实际显示
--- 这是因为功能控制为了通用化希望能减少对系统自身逻辑的干涉，因此会存在父节点被隐藏，但子节点没法判断相应变化的情况，反之亦然
--- 因此直接子节点被各种逻辑调用Open时，父节点没显示，就不让它进入Enable状态
function XUiFunctionShowNode:OnEnableUi()
    if self:CheckParentIsShow() then
        XUiNode.OnEnableUi(self)
    end
end

--endregion

function XUiFunctionShowNode:CheckParentIsShow()
    if self.Parent ~= nil then
        if self.Parent._StateFlag ~= nil then
            -- 父节点是XUiNode, 如果不是已经显示（Enable）或者首次显示（Start）
            if self.Parent._StateFlag ~= XUiNodeState.Enable and self.Parent._StateFlag ~= XUiNodeState.Start then
                return false
            end
        else
            -- 父节点是其他类型，则判断GameObject
            if self.Parent.GameObject and self.Parent.GameObject.activeSelf == false then
                return false
            end
        end
    end
    
    return true
end

return XUiFunctionShowNode