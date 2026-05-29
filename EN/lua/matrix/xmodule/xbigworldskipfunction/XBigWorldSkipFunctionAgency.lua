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

function XBigWorldSkipFunctionAgency:GetSkipFinishConditionIdBySkipId(skipId)
    return self._Model:GetBigWorldSkipFunctionFinishConditionIdById(skipId)
end

function XBigWorldSkipFunctionAgency:GetSkipNameBySkipId(skipId)
    return self._Model:GetBigWorldSkipFunctionNameById(skipId)
end

function XBigWorldSkipFunctionAgency:GetSkipTimeIdBySkipId(skipId)
    return self._Model:GetBigWorldSkipFunctionTimeIdById(skipId)
end

function XBigWorldSkipFunctionAgency:CheckUnlock(skipId)
    local conditionId = self._Model:GetBigWorldSkipFunctionConditionIdById(skipId)
    if not conditionId or conditionId <= 0 then
        return true
    end
    --4.5版本 加了一个TimeId控制按钮显隐，按照道理来说应该是要拓展此接口，但是担心已实现功能并不需要这种逻辑。
    --需求==>系统规则==>2.空花-DIY界面新增获取跳转支持==>第3点
    --需求链接：https://kurogame.feishu.cn/wiki/O19GwwpgPirHo5kSlzSc4lvEnqe?sheet=3R4Vkh
    --修改建议：如果需要修改的话，最好Unlock放在XBWSkipBase里，这样不会同一个判断多处实现
    return XMVCA.XBigWorldService:CheckCondition(conditionId)
end

function XBigWorldSkipFunctionAgency:IsAllowSkip(skipId,isNoTips)
    if not XTool.IsNumberValid(skipId) then
        return false
    end
    
    local skip = self._Model:GetSkipBySkipId(skipId)
    if skip then
        return skip:IsAllowSkip(isNoTips)
    end
    return false
end

function XBigWorldSkipFunctionAgency:CheckFinish(skipId)
    local conditionId = self._Model:GetBigWorldSkipFunctionFinishConditionIdById(skipId)
    if not conditionId or conditionId <= 0 then
        return false
    end
    return XMVCA.XBigWorldService:CheckCondition(conditionId)
end

function XBigWorldSkipFunctionAgency:SkipTo(skipId, isNoTips, params)
    if not XTool.IsNumberValid(skipId) then
        return false
    end
    
    local skip = self._Model:GetSkipBySkipId(skipId)

    if skip then
        return skip:SkipTo(isNoTips, params)
    end

    return false
end

return XBigWorldSkipFunctionAgency