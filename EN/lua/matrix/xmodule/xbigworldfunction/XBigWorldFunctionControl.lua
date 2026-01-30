---@class XBigWorldFunctionControl : XControl
---@field private _Model XBigWorldFunctionModel
local XBigWorldFunctionControl = XClass(XControl, "XBigWorldFunctionControl")

function XBigWorldFunctionControl:OnInit()
    --初始化内部变量
end

function XBigWorldFunctionControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldFunctionControl:RemoveAgencyEvent()

end

function XBigWorldFunctionControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

return XBigWorldFunctionControl