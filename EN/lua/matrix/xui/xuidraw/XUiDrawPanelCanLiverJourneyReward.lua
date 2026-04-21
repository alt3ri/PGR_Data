---@class XUiDrawPanelCanLiverJourneyReward
local XUiDrawPanelCanLiverJourneyReward = XClass(XUiNode, "XUiDrawPanelCanLiverJourneyReward")

function XUiDrawPanelCanLiverJourneyReward:OnStart()
end

function XUiDrawPanelCanLiverJourneyReward:CheckToShow(drawInfo)
    self.DrawInfo = drawInfo
    local drawId = drawInfo.Id
    local canLiverActivityId = XDataCenter.DrawManager.GetCanLiverActivityId()
    if not canLiverActivityId then
        self:Close()
        return
    end

    local config = XDrawConfigs.GetDrawCanLiverActivityCfgById(canLiverActivityId)
    if not XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
        self:Close()
        return
    end

    local isShow = false
    for k, v in pairs(config.DrawIds) do
        if v == drawId then
            isShow = true
            break
        end
    end

    if isShow then
        self:InitJourneyRewardDynamicTable()
        self:RefreshJourneyRewardDynamicTable(true)
        self:RefreshJourneyRewardProgressBar()
        self:Open()
    else
        self:Close()
    end
end

function XUiDrawPanelCanLiverJourneyReward:InitJourneyRewardDynamicTable()
    if not self.ListReward then
        return
    end

    -- 只初始化一次
    if self.DynamicTableReward then
        return
    end

    local XUiGridJourneyReward = require("XUi/XUiDraw/XUiGridJourneyReward")
    self.DynamicTableReward = XUiHelper.DynamicTableNormal(self, self.ListReward, XUiGridJourneyReward)
end

function XUiDrawPanelCanLiverJourneyReward:RefreshJourneyRewardDynamicTable(autoToCanGetIndex)
    if not self.DynamicTableReward then
        return
    end

    local canLiverActivityId = XDataCenter.DrawManager.GetCanLiverActivityId()
    if not canLiverActivityId then
        return
    end

    local drawInfo = self.DrawInfo
    local drawId = drawInfo.Id
    local config = XDrawConfigs.GetDrawCanLiverActivityCfgById(canLiverActivityId)
    local rewardIds = config.RewardIds
    self.CurCanLiverRewardCfg = config
    self.DynamicTableReward:SetDataSource(rewardIds)
    -- 优先定位到可领取的奖励，否则定位到第一个未领取的奖励
    local index = (autoToCanGetIndex and XDataCenter.DrawManager.GetFirstCanJourneyRewardIndex(drawId))
            or XDataCenter.DrawManager.GetFirstUnGetJourneyRewardIndex(drawId)
    self.DynamicTableReward:ReloadDataSync(index)
end

function XUiDrawPanelCanLiverJourneyReward:RefreshJourneyRewardProgressBar()
    -- 进度条
    local curProgressCount = XDataCenter.DrawManager.GetCanLiverDrawCount()
    local maxCount = self.CurCanLiverRewardCfg.Schedules[#self.CurCanLiverRewardCfg.Schedules]
    local progressPercent = curProgressCount / maxCount
    progressPercent = (progressPercent > 1) and 1 or progressPercent
    self.TxtDrawCount.text = curProgressCount
    self.ImgProgress.fillAmount = progressPercent
    
    -- 获取进度条 RectTransform
    local rt = self.ImgProgress:GetComponent(typeof(CS.UnityEngine.RectTransform))
    local rectHeight = rt.rect.height
    
    -- 计算新的 anchoredPosition
    local anchoredPos = self.PanelNow.anchoredPosition
    anchoredPos.y = progressPercent * rectHeight
    self.PanelNow.anchoredPosition = anchoredPos
end

function XUiDrawPanelCanLiverJourneyReward:OnlyRefreshJourneyRewardDynamicTableData()
    local allGrids = self.DynamicTableReward:GetGrids()
    for index, grid in pairs(allGrids) do
        local rewardId = self.DynamicTableReward.DataSource[index]
        grid:Refresh(rewardId, index)
    end
    self:RefreshJourneyRewardProgressBar()
end

---@param grid XUiGridJourneyReward
function XUiDrawPanelCanLiverJourneyReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local rewardId = self.DynamicTableReward.DataSource[index]
        if rewardId then
            grid:Refresh(rewardId, index)
            self:RefreshJourneyRewardProgressBar()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

return XUiDrawPanelCanLiverJourneyReward