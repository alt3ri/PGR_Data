---@class XBigWorldSkipFunctionControl : XControl
---@field private _Model XBigWorldSkipFunctionModel
local XBigWorldSkipFunctionControl = XClass(XControl, "XBigWorldSkipFunctionControl")

function XBigWorldSkipFunctionControl:OnInit()
    --初始化内部变量
end

function XBigWorldSkipFunctionControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldSkipFunctionControl:RemoveAgencyEvent()

end

function XBigWorldSkipFunctionControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

return XBigWorldSkipFunctionControl