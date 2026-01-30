---@class XFunctionControl : XControl
---@field _Model XFunctionModel
local XFunctionControl = XClass(XControl, "XFunctionControl")
function XFunctionControl:OnInit()
    --初始化内部变量
end

function XFunctionControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XFunctionControl:RemoveAgencyEvent()

end

function XFunctionControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
end

return XFunctionControl