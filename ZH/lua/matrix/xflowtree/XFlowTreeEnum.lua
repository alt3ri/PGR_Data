---@class XFlowTreeEnum 行为树枚举集合
local XFlowTreeEnum = {}

-- 执行结果
XFlowTreeEnum.Result = {
    Unknown = 0,
    Succeed = 1,
    Fail = 2,
    Interrupt = 3,
}

-- 节点状态
XFlowTreeEnum.Status = {
    Init = 0,
    Running = 1,
    Stopped = 2,
}
XFlowTreeEnum.NodeType = {
    UnKnown = 0,
    Action = 1,
    Condition = 2,
    Composite = 3,
    Root = 4,
}

return XFlowTreeEnum
