---@class XDlcHelperControl : XControl
---@field private _Model XDlcHelperModel
local XDlcHelperControl = XClass(XControl, "XDlcHelperControl")
function XDlcHelperControl:OnInit()
    --初始化内部变量
end

function XDlcHelperControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XDlcHelperControl:RemoveAgencyEvent()

end

function XDlcHelperControl:OnRelease()

end

return XDlcHelperControl