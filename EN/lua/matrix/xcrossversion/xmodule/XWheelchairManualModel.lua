local super = require("XModule/XWheelchairManual/XWheelchairManualModel")
---@type XWheelchairManualModel
local XWheelchairManualModel = XClassPartial('XWheelchairManualModel')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XWheelchairManualModel
end

---@return XTableWheelchairManualGuideWeekRewardSpecialDeal
function XWheelchairManualModel:GetWheelchairManualGuideWeekRewardSpecialCfg(id)
    local TableNormal = self:GetNormalTableKey()
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableNormal.WheelchairManualGuideWeekRewardSpecialDeal, id)
end

return XWheelchairManualModel