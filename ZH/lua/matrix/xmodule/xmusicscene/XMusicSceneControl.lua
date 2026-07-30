---@class XMusicSceneControl : XControl
---@field private _Model XMusicSceneModel
local XMusicSceneControl = XClass(XControl, "XMusicSceneControl", false)

function XMusicSceneControl:OnInit()
    --初始化内部变量
    self:InitConfig()
end

function XMusicSceneControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XMusicSceneControl:RemoveAgencyEvent()

end

function XMusicSceneControl:OnRelease()
    
end

function XMusicSceneControl:InitConfig()
    --初始化配置表
end


return XMusicSceneControl