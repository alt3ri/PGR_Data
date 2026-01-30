---@class XItemRestrictControl : XControl
---@field private _Model XItemRestrictModel
local XItemRestrictControl = XClass(XControl, "XItemRestrictControl")
function XItemRestrictControl:OnInit()
    --初始化内部变量
end

function XItemRestrictControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XItemRestrictControl:RemoveAgencyEvent()

end

function XItemRestrictControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XItemRestrictControl