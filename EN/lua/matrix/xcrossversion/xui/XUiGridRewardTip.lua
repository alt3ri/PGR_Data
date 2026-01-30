local super = require("XUi/XUiStronghold/XUiStrongholdReward/XUiGridRewardTip")
---@type XUiGridRewardTip 分类
local XUiGridRewardTip = XClassPartial('XUiGridRewardTip')

if not XDataCenter.CrossVersionManager.GetEnable() then
    return XUiGridRewardTip
end

function XUiGridRewardTip:GetRewardGoodsId(rewardId)
    local maxId = XStrongholdConfigs.GetSpecialMaxId()
    local _ActivityId = XDataCenter.StrongholdManager:GetActivityId()
    local rewardGoodsId
    if _ActivityId > maxId then
        rewardGoodsId = XStrongholdConfigs.GetRewardGoodsId(rewardId)  
    else
        rewardGoodsId = XStrongholdConfigs.GetSpecialRewardId(rewardId, maxId)   
    end
    return rewardGoodsId
end

return XUiGridRewardTip