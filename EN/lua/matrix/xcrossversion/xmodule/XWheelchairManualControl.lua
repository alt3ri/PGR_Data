local super = require("XModule/XWheelchairManual/XWheelchairManualControl")
---@type XWheelchairManualControl
local XWheelchairManualControl = XClassPartial('XWheelchairManualControl')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XWheelchairManualControl
end

function XWheelchairManualControl:GetWeekActivityTemplatesAndCount(viewData)
    local rewardCfgId = viewData:GetMainId() * 100 + viewData:GetSubId()
    local cfgSpecial = self._Model:GetWheelchairManualGuideWeekRewardSpecialCfg(rewardCfgId)
    if cfgSpecial and XFunctionManager.CheckInTimeByTimeId(cfgSpecial.TimeId) then
        return cfgSpecial.MainTemplateId, cfgSpecial.MainTemplateCount
    end
    local cfg = self._Model:GetWheelchairManualGuideWeekRewardCfg(rewardCfgId)

    if cfg then
        return cfg.MainTemplateId, cfg.MainTemplateCount
    else
        XLog.Error('活动找不到对应的奖励显示配置,请检查是否是配置表配置错误，或下发数据存在异常 mainId:'..tostring(viewData:GetMainId())..' subId:'..tostring(viewData:GetSubId()))
    end
end

return XWheelchairManualControl