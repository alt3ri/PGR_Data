local super = require("XModule/XNewActivityCalendar/XNewActivityCalendarModel")
---@type XNewActivityCalendarModel
local XNewActivityCalendarModel = XClassPartial('XNewActivityCalendarModel')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XNewActivityCalendarModel
end

function XNewActivityCalendarModel:GetCalendarWeekRewardSpecialConfig(id)
    local TableKey = self:GetTableKey()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.NewActivityCalendarWeekRewardSpecialDeal, id)
end

function XNewActivityCalendarModel:GetWeekMainTemplateId(id)
    local config = self:GetCalendarWeekRewardSpecialConfig(id)
    if not config or not XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
        config = self:GetCalendarWeekRewardConfig(id)
    end
    return config and config.MainTemplateId or {}
end

function XNewActivityCalendarModel:GetWeekMainTemplateCount(id)
    local config = self:GetCalendarWeekRewardSpecialConfig(id)
    if not config or not XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
        config = self:GetCalendarWeekRewardConfig(id)
    end
    return config and config.MainTemplateCount or {}
end

return XNewActivityCalendarModel