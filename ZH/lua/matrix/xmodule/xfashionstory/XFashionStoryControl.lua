---@class XFashionStoryControl : XControl
---@field private _Model XFashionStoryModel
local XFashionStoryControl = XClass(XControl, "XFashionStoryControl")
function XFashionStoryControl:OnInit()
    --初始化内部变量
end

function XFashionStoryControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XFashionStoryControl:RemoveAgencyEvent()

end

function XFashionStoryControl:OnRelease()
    XLog.Error("这里执行Control的释放")
end

return XFashionStoryControl