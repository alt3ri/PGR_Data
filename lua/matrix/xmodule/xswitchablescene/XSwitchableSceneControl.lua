---@class XSwitchableSceneControl : XControl
---@field private _Model XSwitchableSceneModel
local XSwitchableSceneControl = XClass(XControl, "XSwitchableSceneControl")

function XSwitchableSceneControl:OnInit()
    --初始化内部变量
end

function XSwitchableSceneControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XSwitchableSceneControl:RemoveAgencyEvent()

end

function XSwitchableSceneControl:OnRelease()
    
end

return XSwitchableSceneControl