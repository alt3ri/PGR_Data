---@class XBigWorldLoadingControl : XControl
---@field private _Model XBigWorldLoadingModel
local XBigWorldLoadingControl = XClass(XControl, "XBigWorldLoadingControl")

function XBigWorldLoadingControl:OnInit()
    -- 初始化内部变量
end

function XBigWorldLoadingControl:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XBigWorldLoadingControl:RemoveAgencyEvent()

end

function XBigWorldLoadingControl:OnRelease()
    -- XLog.Error("这里执行Control的释放")
end

return XBigWorldLoadingControl
