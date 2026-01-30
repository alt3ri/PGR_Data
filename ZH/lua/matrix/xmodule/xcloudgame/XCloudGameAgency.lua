---@class XCloudGameAgency : XAgency
---@field private _Model XCloudGameModel
local XCloudGameAgency = XClass(XAgency, "XCloudGameAgency")
function XCloudGameAgency:OnInit()
    --初始化一些变量
end

function XCloudGameAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XCloudGameAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

return XCloudGameAgency