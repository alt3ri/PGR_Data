---@class XUiPanelCultureConsume : XUiNode
local XUiPanelCultureConsume = XClass(XUiNode, "XUiPanelCultureConsume")
local XUiGridCultureConsumeItem = require("XUi/XUiRole/XUiRoleCulture/XUiGridCultureConsumeItem")

function XUiPanelCultureConsume:OnStart()
    self.GridCostItem.gameObject:SetActiveEx(false)
    self.PanelBreachNeed.gameObject:SetActiveEx(false)

    self.Grids = {}
    self.CostList = {}
    self.ExchangeGainMap = {}
    self.BtnPreview:AddEventListener(handler(self, self.OnBtnPreviewClick))
end

function XUiPanelCultureConsume:Refresh(result)
    self.Result = result
    local coinId = XDataCenter.ItemManager.ItemId.Coin
    local skillPointId = XDataCenter.ItemManager.ItemId.SkillPoint

    -- 聚合自动兑换可补足量：ExchangePlan 每项 {ShopId, GoodsId, ItemId, Count=购买次数}
    -- 到手量 = RewardCount * 购买次数
    local exchangeGainMap = self.ExchangeGainMap
    for k in pairs(exchangeGainMap) do
        exchangeGainMap[k] = nil
    end
    for _, plan in ipairs(result.ExchangePlan or table.empty) do
        local info = XShopManager.GetGoodsExchangeInfo(plan.ItemId, plan.ShopId, plan.GoodsId)
        if info and info.RewardCount then
            local gain = info.RewardCount * plan.Count
            exchangeGainMap[plan.ItemId] = (exchangeGainMap[plan.ItemId] or 0) + gain
        end
    end

    -- 组装 grid 数据（屏蔽金币/技能点）：每项 { ItemId, NeedCount, ExchangeGain }
    local costList = self.CostList
    for i = #costList, 1, -1 do
        costList[i] = nil
    end
    for itemId, count in pairs(result.FinalCostMap) do
        if itemId ~= coinId and itemId ~= skillPointId then
            table.insert(costList, { ItemId = itemId, NeedCount = count, ExchangeGain = exchangeGainMap[itemId] or 0 })
        end
    end
    table.sort(costList, function(a, b)
        return a.ItemId < b.ItemId
    end)

    local hasCost = #costList > 0
    self.PanelChooseTargetTip.gameObject:SetActiveEx(not hasCost)
    self.PanelBreakthroughConsume.gameObject:SetActiveEx(hasCost)

    local hasExchange = #result.ExchangePlan > 0
    -- 兑换后仍缺材料时不显示兑换标签（兑换补不齐）
    local hasLackAfter = next(result.LackMap or table.empty) ~= nil
    self.BtnPreview.gameObject:SetActiveEx(next(result.FinalCostMap or table.empty) ~= nil)
    self.TagExchange.gameObject:SetActiveEx(hasCost and hasExchange and not hasLackAfter)
    self.TagNotEnough.gameObject:SetActiveEx(hasLackAfter)

    self:RefreshCostGrids(costList)
end

--- 特训态：消耗栏固定显示特训道具 ×1，不可预览、无兑换
function XUiPanelCultureConsume:RefreshSpecialTraining(itemId, count)
    self.Result = nil
    self.PanelChooseTargetTip.gameObject:SetActiveEx(false)
    self.PanelBreakthroughConsume.gameObject:SetActiveEx(true)
    self.BtnPreview.gameObject:SetActiveEx(false)
    self.TagExchange.gameObject:SetActiveEx(false)

    self:RefreshCostGrids({ { ItemId = itemId, NeedCount = count, ExchangeGain = 0 } })
end

--- 用通用动态列表工具刷新消耗格子（复用/回收由 XUiNode 生命周期管理）
function XUiPanelCultureConsume:RefreshCostGrids(costList)
    XTool.UpdateDynamicItem(self.Grids, costList, self.GridCostItem, XUiGridCultureConsumeItem, self)
end

function XUiPanelCultureConsume:OnBtnPreviewClick()
    if not self.Result then
        return
    end
    local data = self.Parent._Control:BuildCultureCostPreviewData(self.Result)
    XLuaUiManager.Open("UiRoleCostPreviewPopup", data)
end

return XUiPanelCultureConsume
