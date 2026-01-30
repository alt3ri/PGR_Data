---@class XBigWorldSkipFunctionAgency : XAgency
---@field private _Model XBigWorldSkipFunctionModel
local XBigWorldSkipFunctionAgency = XClass(XAgency, "XBigWorldSkipFunctionAgency")

function XBigWorldSkipFunctionAgency:OnInit()
    --初始化一些变量
end

function XBigWorldSkipFunctionAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XBigWorldSkipFunctionAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XBigWorldSkipFunctionAgency:GetSkipParamsBySkipId(skipId)
    return self._Model:GetBigWorldSkipFunctionParamsById(skipId)
end

function XBigWorldSkipFunctionAgency:GetSkipConditionIdBySkipId(skipId)
    return self._Model:GetBigWorldSkipFunctionConditionIdById(skipId)
end

function XBigWorldSkipFunctionAgency:SkipTo(skipId, ...)
    if not XTool.IsNumberValid(skipId) then
        return false
    end

    local skip = self._Model:GetSkipBySkipId(skipId)

    if skip then
        return skip:SkipTo(...)
    end

    return false
end

return XBigWorldSkipFunctionAgency