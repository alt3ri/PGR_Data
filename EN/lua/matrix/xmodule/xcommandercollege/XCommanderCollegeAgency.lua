---@class XCommanderCollegeAgency : XAgency
---@field private _Model XCommanderCollegeModel
local XCommanderCollegeAgency = XClass(XAgency, "XCommanderCollegeAgency")
function XCommanderCollegeAgency:OnInit()
    --初始化一些变量
end

function XCommanderCollegeAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XCommanderCollegeAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------
function XCommanderCollegeAgency:GetBigWorldOpenFunctionMainConfigByKey(functionKey)
    return self._Model:GetBigWorldOpenFunctionMainConfigByKey(functionKey)
end


----------public end----------

----------private start----------

----------private end----------

return XCommanderCollegeAgency