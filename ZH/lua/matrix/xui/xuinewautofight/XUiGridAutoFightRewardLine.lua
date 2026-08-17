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

-- 记录存在多倍奖励的TemplateId（合并前）
function XUiGridAutoFightRewardLine:RecordGiftTemplateIds(rewardGoodsList)
    -- 回归双倍与多倍奖励活动共用RewardMulti字段，统一按服务端实际下发的倍率记录
    local giftTemplateIds = {}

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
        -- 检查合并后的奖励是否有对应的多倍记录
        local rewardMulti = self._GiftTemplateIdRecord and self._GiftTemplateIdRecord[reward.TemplateId] or 0

        -- 服务端只对实际消耗了双倍次数的场次下发RewardMulti，未翻倍的场次不能显示翻倍角标
        if rewardMulti > 1 then
            grid.PanelDouble.gameObject:SetActiveEx(true)
            return
        end

        grid.PanelDouble.gameObject:SetActiveEx(false)
    end
end

return XUiGridAutoFightRewardLine