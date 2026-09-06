local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGridWheelchairManualStepRewardPlan: XUiNode
---@field _Control XWheelchairManualControl
local XUiGridWheelchairManualStepRewardPlan = XClass(XUiNode, 'XUiGridWheelchairManualStepRewardPlan')

---@param rootUi XLuaUi
function XUiGridWheelchairManualStepRewardPlan:OnStart(rootUi)
    self.Grid256New.gameObject:SetActiveEx(false)
    self.RootUi = rootUi
end

function XUiGridWheelchairManualStepRewardPlan:RefreshData(planId, index)
    self.PlanId = planId
    self.Index= index
    local isSpecial = self._Control:GetManualPlanIsSpecial(self.PlanId)
    local isCurrent = self.PlanId == self._Control:GetCurActivityCurrentPlanId()
    self.ImgBg.gameObject:SetActiveEx(not isSpecial)
    self.ImgSpecialBg.gameObject:SetActiveEx(isSpecial)

    -- 判断当前进度
    local passCount, allCount = XMVCA.XWheelchairManual:GetPlanProcess(self.PlanId)
    local isProcessValid = XTool.IsNumberValid(allCount)
    
    
    -- 奖励领取情况
    local isFinish = true
    local isAchieved = false
    if isProcessValid then
        isFinish = passCount == allCount
        isAchieved = self._Control:CheckPlanIsGetReward(self.PlanId)
    end

    self.PanelReceive.gameObject:SetActiveEx(false)
    self.Collect.gameObject:SetActiveEx(false)

    self._CanReceive = isFinish and not isAchieved
    self.BtnClick:ShowReddot(self._CanReceive)

    -- 进度显示控制
    if isCurrent and not isAchieved then
        if isProcessValid then
            self.TxtProcess.text = XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('CommonProcessLabel'), passCount, allCount)
        end
    end
    self.TxtProcess.gameObject:SetActiveEx(isProcessValid and isCurrent and not isAchieved)
    self.PanelOngoing.gameObject:SetActiveEx(isCurrent and not isFinish)
    self.Normal.gameObject:SetActiveEx(not isCurrent or isFinish)
    -- 刷新奖励道具
    self:RefreshRewardGrids(isAchieved)
    
    self.BtnClick:SetNameByGroup(0, XUiHelper.FormatText(XMVCA.XWheelchairManual:GetWheelchairManualConfigString('PlanTitle'), self.Index))
    self.BtnClick:SetRawImage(self._Control:GetManualPlanTitleIcon(self.PlanId))
end

function XUiGridWheelchairManualStepRewardPlan:RefreshRewardGrids(isAchieved)
    if self._RewardGrids == nil then
        self._RewardGrids = {}
    end

    -- 隐藏旧格子
    for _, grid in pairs(self._RewardGrids) do
        grid.GameObject:SetActiveEx(false)
    end

    local rewardGoodsList = {}

    -- 按顺序追加奖励
    local function appendRewardList(rewardId)
        if not XTool.IsNumberValid(rewardId) then
            return
        end

        local rewards = XRewardManager.GetRewardList(rewardId)
        if XTool.IsTableEmpty(rewards) then
            return
        end

        for _, reward in ipairs(rewards) do
            table.insert(rewardGoodsList, reward)
        end
    end

    -- 原奖励在前，新增奖励在后
    appendRewardList(self._Control:GetManualPlanRewardId(self.PlanId))
    appendRewardList(self._Control:GetManualPlanExtRewardId(self.PlanId))

    for index, reward in ipairs(rewardGoodsList) do
        ---@type XUiGridCommon
        local grid = self._RewardGrids[index]

        if not grid then
            local go = CS.UnityEngine.GameObject.Instantiate(
                self.Grid256New,
                self.Grid256New.transform.parent
            )
            grid = XUiGridCommon.New(self.RootUi, go)
            table.insert(self._RewardGrids, grid)
        end

        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)
        grid.PanelEffect.gameObject:SetActiveEx(self._CanReceive)
        grid:SetReceived(isAchieved)

        grid:SetProxyClickFunc(function()
            if self._CanReceive then
                self:OnClickEvent()
                return false
            end

            return true
        end)
    end
end

function XUiGridWheelchairManualStepRewardPlan:OnClickEvent()
    if not self._CanReceive then
        return
    end

    self.Parent:RequestPlanReward()
end

return XUiGridWheelchairManualStepRewardPlan