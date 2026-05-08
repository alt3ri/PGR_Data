---@class XUiGridTheatre6BossReward : XUiNode Boss奖励Grid（资源/buff/技能/属性通用）
---@field _Control XTheatre6Control
---@field _GridResource XUiGridTheatre6BossRewardResource
local XUiGridTheatre6BossReward = XClass(XUiNode, "XUiGridTheatre6BossReward")

-- 奖励类型枚举
local RewardType = XEnumConst.Theatre6.EventRewardType

function XUiGridTheatre6BossReward:OnStart()
    self._GridResource = require("XUi/XUiTheatre6/Boss/Grid/XUiGridTheatre6BossRewardResource").New(self.GridResource, self)
    self.GridBuff.gameObject:SetActiveEx(false)
    self.GridRelic.gameObject:SetActiveEx(false)
    self.GridSkill.gameObject:SetActiveEx(false)
end

---XTool.UpdateDynamicItem调用
---@param rewardData table 奖励数据 {Type, Id} 或 {Type, Count} (资源类型)
function XUiGridTheatre6BossReward:Update(rewardData)
    self._GridResource:ShowPool(rewardData[1], rewardData[2])
end

return XUiGridTheatre6BossReward
