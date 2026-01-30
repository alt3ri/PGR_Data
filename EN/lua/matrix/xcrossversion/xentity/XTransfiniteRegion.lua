local super = require("XEntity/XTransfinite/XTransfiniteRegion")
---@type XTransfiniteRegion
local XTransfiniteRegion = XClassPartial('XTransfiniteRegion')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XTransfiniteRegion
end

function XTransfiniteRegion:GetSpecialScoreAndRewardArray()
    local scoreArray, rewardArray = XTransfiniteConfigs.GetSpecialScoreArray(self:GetId())
    return scoreArray, rewardArray
end

return XTransfiniteRegion