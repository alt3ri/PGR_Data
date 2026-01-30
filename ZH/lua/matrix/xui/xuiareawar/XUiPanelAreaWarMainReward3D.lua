---@class XUiPanelAreaWarMainReward3D 区块攻破奖励榜3D的UI
---@field
local XUiPanelAreaWarMainReward3D = XClass(nil, "XUiPanelAreaWarMainReward3D")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
function XUiPanelAreaWarMainReward3D:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RewardGrids = {}
    XTool.InitUiObject(self)
end

function XUiPanelAreaWarMainReward3D:Refresh(blockId)
    blockId = blockId or self.BlockId
    if not XTool.IsNumberValid(blockId) then
        return
    end

    -- self.RewardGrid = self.RewardGrid or require("XUi/XUiObtain/XUiGridCommon").New(self.Parent, self.Grid128)
    -- self.RewardGrid:Refresh(dispatchList[1])

    local rewardItems = {}
    local rewardId = XAreaWarConfigs.GetBlockShowRewardId(blockId)
    if XTool.IsNumberValid(rewardId) then
        rewardItems = XRewardManager.GetRewardList(rewardId)
    end
    local dispatchList = XRewardManager.MergeAndSortRewardGoodsList(rewardItems)

    for index, item in ipairs(dispatchList) do
        if not self.RewardGrids[index] then
            local go = index == 1 and self.Grid128 or CSObjectInstantiate(self.Grid128, self.Grid128.transform.parent)
            local grid = XUiGridCommon.New(self.Parent, go)
            self.RewardGrids[index] = grid
        end
        self.RewardGrids[index]:Refresh(item)
        self.RewardGrids[index].GameObject:SetActiveEx(true)
    end
end

function XUiPanelAreaWarMainReward3D:RefreshQuest(questId)
    if not XTool.IsNumberValid(questId) then
        return
    end
    local data = XDataCenter.AreaWarManager.GetAreaWarQuest(questId)
    local rewardId = data:GetRewardId()
    if not XTool.IsNumberValid(rewardId) then
        return
    end
end

function XUiPanelAreaWarMainReward3D:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelAreaWarMainReward3D:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelAreaWarMainReward3D
