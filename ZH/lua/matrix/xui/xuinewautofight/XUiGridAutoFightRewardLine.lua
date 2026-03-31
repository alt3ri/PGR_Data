local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridAutoFightRewardLine = XClass(nil, "XUiGridAutoFightRewardLine")

function XUiGridAutoFightRewardLine:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.GridReward.gameObject:SetActiveEx(false)
    self.RewardGrids = {}
end

function XUiGridAutoFightRewardLine:InitRootUi(rootUi)
    self.RootUi = rootUi
end

function XUiGridAutoFightRewardLine:Refresh(sweepRewards, index, isShow, stageId)
    self.TxtOrder.text = index < 10 and string.format("%02d", index) or index
    local rewardGoodsList = sweepRewards.RewardGoods or {}

    self.StageId = stageId

    -- 合并前记录存在额外奖励(Gift)的TemplateId
    self._GiftTemplateIdRecord = self:RecordGiftTemplateIds(rewardGoodsList)

    local rewards = XRewardManager.MergeAndSortRewardGoodsList(rewardGoodsList)
    for idx, item in ipairs(rewards) do
        local grid = self.RewardGrids[idx]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridReward)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelRewardContent, false)
            grid.GameObject:SetActiveEx(true)
            self.RewardGrids[idx] = grid
        end

        grid:Refresh(item, nil, nil, true)
        
        self:RewardShowEx(grid, item)
    end

    for i = #rewards + 1, #self.RewardGrids do
        self.RewardGrids[i].GameObject:SetActiveEx(false)
    end
    if isShow then
        self:Show()
    end
end

function XUiGridAutoFightRewardLine:Show()
    self.Root.gameObject:SetActiveEx(true)
end

-- 记录存在额外奖励的TemplateId（合并前）
function XUiGridAutoFightRewardLine:RecordGiftTemplateIds(rewardGoodsList)
    local giftTemplateIds = nil

    -- 先判断玩家是否是回归玩家且拥有双倍奖励次数
    if not XMVCA.XReCallActivity:CheckIsRegressionPlayer() then
        return giftTemplateIds
    end
    
    -- 这里只要玩家是回归玩家，那么复刷关这里的IsGift就是双倍奖励送的
    -- 如果存在其他活动也会有额外奖励，则需要额外加字段来比较

    giftTemplateIds = {}

    -- 遍历记录哪些TemplateId存在IsGift标记的奖励
    for _, item in ipairs(rewardGoodsList) do
        if XTool.IsNumberValidEx(item.RewardMulti) then
            giftTemplateIds[item.TemplateId] = item.RewardMulti
        end
    end

    return giftTemplateIds
end

---@param grid XUiGridCommon
---@param reward XRewardGoods
function XUiGridAutoFightRewardLine:RewardShowEx(grid, reward)
    if grid.PanelDouble then
        -- 检查合并后的奖励是否有对应的Gift记录
        local rewardMulti = self._GiftTemplateIdRecord and self._GiftTemplateIdRecord[reward.TemplateId] or 0
        
        -- 使用传入的hasGift参数判断，而非reward.IsGift
        if rewardMulti == 2 then
            grid.PanelDouble.gameObject:SetActiveEx(true)
            return
        end

        grid.PanelDouble.gameObject:SetActiveEx(false)
    end
end

return XUiGridAutoFightRewardLine