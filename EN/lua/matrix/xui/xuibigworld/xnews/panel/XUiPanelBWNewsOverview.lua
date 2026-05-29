local XUiPanelBWNewsBase = require("XUi/XUiBigWorld/XNews/Panel/XUiPanelBWNewsBase")
local XUiGridBWQuestSmall = require("XUi/XUiBigWorld/XQuest/Grid/XUiGridBWQuestSmall")

---@class XUiPanelBWNewsOverview : XUiPanelBWNewsBase
---@field Parent XUiBigWorldPopupNews
local XUiPanelBWNewsOverview = XClass(XUiPanelBWNewsBase, "XUiPanelBWNewsOverview")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

function XUiPanelBWNewsOverview:OnStart()
    self._GridRewards = {}
    self.QuestStateSortDict = {
        [XMVCA.XBigWorldQuest.QuestState.InActive] = 1,
        [XMVCA.XBigWorldQuest.QuestState.Ready] = 2,
        [XMVCA.XBigWorldQuest.QuestState.InProgress] = 2,
        [XMVCA.XBigWorldQuest.QuestState.Finished] = 0,
    }
    self.GridCommon.gameObject:SetActiveEx(false)
    self.GridTask.gameObject:SetActiveEx(false)

    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListTask, XUiGridBWQuestSmall)

    self:RegisterButtonClick()
end

function XUiPanelBWNewsOverview:RefreshContent(newsId)
    self.TxtTitle.text = XMVCA.XBigWorldNews:GetNewsTitle(newsId)
    self.RImgPoster:SetRawImage(XMVCA.XBigWorldNews:GetNewsBgPic(newsId))
end

function XUiPanelBWNewsOverview:RefreshReward(rewardId)
    if not rewardId or rewardId <= 0 then
        for _, grid in pairs(self._GridRewards) do
            grid:Close()
        end
        return
    end
    local rewards = XMVCA.XBigWorldGamePlay:GetBigWorldGoodsByGroupId(rewardId)
    XTool.UpdateDynamicItem(self._GridRewards, rewards, self.GridCommon, XUiGridBWItem, self)
end

function XUiPanelBWNewsOverview:RefreshParams(questIds)
    local isEmpty = XTool.IsTableEmpty(questIds)

    self.PanelTask.gameObject:SetActiveEx(not isEmpty)

    if isEmpty then
        return
    end

    self.TxtTaskTitle.text = XMVCA.XBigWorldNews:GetNewsContent(self._NewsId)

    questIds = self:SortQuestIds(questIds)

    self._DataList = questIds
    self._DynamicTable:SetDataSource(questIds)
    self._DynamicTable:ReloadDataSync()
end

---@param grid XUiGridBWQuestSmall
function XUiPanelBWNewsOverview:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self._DataList[index])
    end
end

function XUiPanelBWNewsOverview:SortQuestIds(questIds)
    local dict = self.QuestStateSortDict
    self:SortIndexCache(questIds)
    local sortDict = self._SortIndexCache
    table.sort(questIds, function(a, b)
        local isFinishA = XMVCA.XBigWorldQuest:CheckQuestFinish(a)
        local isFinishB = XMVCA.XBigWorldQuest:CheckQuestFinish(b)
        if isFinishA ~= isFinishB then
            return isFinishB
        end
        local stateA = XMVCA.XBigWorldQuest:GetQuestData(a):GetState()
        local stateB = XMVCA.XBigWorldQuest:GetQuestData(b):GetState()
        local sortStateA = dict[stateA]
        local sortStateB = dict[stateB]
        if sortStateA ~= sortStateA then
            return sortStateA > sortStateB
        end
        local indexA = sortDict[a]
        local indexB = sortDict[b]
        if indexA ~= indexB then
            return indexA < indexB
        end
        return a < b
    end)

    return questIds
end

function XUiPanelBWNewsOverview:SortIndexCache(questIds)
    if self._SortIndexCache then
        for k, _ in pairs(self._SortIndexCache) do
            self._SortIndexCache[k] = nil
        end
    else
        self._SortIndexCache = {}
    end
    for i, questId in pairs(questIds) do
        self._SortIndexCache[questId] = i
    end
end

function XUiPanelBWNewsOverview:IsFinish()
    if not XTool.IsNumberValid(self._NewsId) then
        return false
    end

    local questIds = XMVCA.XBigWorldNews:GetNewsParams(self._NewsId)

    if XTool.IsTableEmpty(questIds) then
        return true
    end

    for _, questId in ipairs(questIds) do
        if not XMVCA.XBigWorldQuest:CheckQuestFinish(questId) then
            return false
        end
    end

    return true
end

return XUiPanelBWNewsOverview
