local XUiPanelBWNewsBase = require("XUi/XUiBigWorld/XNews/Panel/XUiPanelBWNewsBase")

---@class XUiPanelBWNewsQuest : XUiPanelBWNewsBase
---@field Parent XUiBigWorldPopupNews
---@field _GridRewards XUiGridBWItem[]
---@field UiBigWorldCommonBtnBigConfirm XUiComponent.XUiButton
local XUiPanelBWNewsQuest = XClass(XUiPanelBWNewsBase, "XUiPanelBWNewsQuest")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

function XUiPanelBWNewsQuest:OnStart()
    ---@type XUiGridBWItem[]
    self._GridRewards = {}
    ---@type XUiGridBWItem
    self._TimeRewardGrid = false
    self.GridCommon.gameObject:SetActiveEx(false)
    self.LockTips = self.LockTips or self.Transform:Find("PanelContent/LockTips")

    self:RegisterButtonClick()
end

function XUiPanelBWNewsQuest:RegisterButtonClick()
    self.Super.RegisterButtonClick(self)
    self.UiBigWorldCommonBtnBigConfirm:AddEventListener(Handler(self, self.OnBtnConfirmClick))
    self.BtnTimeDetail:AddEventListener(Handler(self, self.OnBtnTimeDetailClick))
    self.BtnDetail:AddEventListener(Handler(self, self.OnBtnDetailClick))
end

function XUiPanelBWNewsQuest:RefreshContent(newsId)
    local spineBanner = XMVCA.XBigWorldNews:GetNewsSpineBanner(newsId)

    self.TxtTitle.text = XMVCA.XBigWorldNews:GetNewsTitle(newsId)
    self.TxtDetail.text = XMVCA.XBigWorldNews:GetNewsContent(newsId)
    self._FirstNotPassConditionIndex = XMVCA.XBigWorldNews:GetNewsFirstLockCondition(newsId)
    self._CustomParamId = XMVCA.XBigWorldNews:GetNewsCustomParamId(newsId)
    self._EarlyAccessSkipIds = XMVCA.XBigWorldNews:GetNewsEarlyAccessSkipIds(newsId)

    if not string.IsNilOrEmpty(spineBanner) then
        self.SpineBanner.gameObject:SetActiveEx(true)
        self.RImgPoster.gameObject:SetActiveEx(false)
        self.SpineBanner:LoadPrefab(spineBanner)
    else
        self.SpineBanner.gameObject:SetActiveEx(false)
        self.RImgPoster.gameObject:SetActiveEx(true)
        self.RImgPoster:SetImage(XMVCA.XBigWorldNews:GetNewsBgPic(newsId))
    end
end

function XUiPanelBWNewsQuest:RefreshReward(rewardId)
    if not rewardId or rewardId <= 0 then
        for _, grid in pairs(self._GridRewards) do
            grid:Close()
        end
        return
    end

    local rewards = XMVCA.XBigWorldGamePlay:GetBigWorldGoodsByGroupId(rewardId)

    XTool.UpdateDynamicItem(self._GridRewards, rewards, self.GridCommon, XUiGridBWItem, self)
end

function XUiPanelBWNewsQuest:RefreshTask(taskGroupId)
    if XTool.IsNumberValid(taskGroupId) then
        local taskDatas = XMVCA.XBigWorldService:GetTimeLimitTaskListByGroupId(taskGroupId)

        if not XTool.IsTableEmpty(taskDatas) then
            local taskId = taskDatas[1].Id
            local rewardId = XMVCA.XBigWorldService:GetTaskRewardIdByTaskId(taskId)
            local rewards = XMVCA.XBigWorldService:GetRewardDataList(rewardId)

            self:RefreshTime()
            if not XTool.IsTableEmpty(rewards) then
                self.PanelRewardTime.gameObject:SetActiveEx(true)
                self.TxtRewardTitle.text = XMVCA.XBigWorldNews:GetNewsShowTimeRewardTitle(self._NewsId)
                self.TxtRewardContentTitle.text = XMVCA.XBigWorldNews:GetNewsShowTimeRewardContent(self._NewsId)
                if self.TxtRewardTip then
                    self.TxtRewardTip.text = XMVCA.XBigWorldNews:GetNewsShowTimeRewardTip(self._NewsId)
                end

                if not self._TimeRewardGrid then
                    ---@type XUiGridBWItem
                    self._TimeRewardGrid = XUiGridBWItem.New(self.TimeRewardGrid, self,
                        Handler(self, self.OnTimeRewardClick))
                end

                local isReceive = true
                local isFinish = true

                self._Reward = rewards[1]
                self._TimeRewardGrid:Open()
                self._TimeRewardGrid:Refresh(self._Reward)

                for _, taskData in pairs(taskDatas) do
                    if not XMVCA.XBigWorldService:CheckTaskAchieved(taskData.Id) then
                        isReceive = false
                    end
                    if not XMVCA.XBigWorldService:CheckTaskFinish(taskData.Id) then
                        isFinish = false
                    end
                end
                self.ImgCanReceive.gameObject:SetActiveEx(isReceive)
                self.ImgReceived.gameObject:SetActiveEx(isFinish)

                return
            end
        end
    end

    if self._TimeRewardGrid then
        self._TimeRewardGrid:Close()
    end

    self.PanelRewardTime.gameObject:SetActiveEx(false)
end

function XUiPanelBWNewsQuest:RefreshOther()
    local isPassed = self._FirstNotPassConditionIndex <= 0
    local finish = self:IsFinish()
    local isUnlock = true

    if finish then
        self.LockTips.gameObject:SetActiveEx(false)
        self.UiBigWorldCommonBtnBigConfirm:ShowTag(false)
    elseif isPassed then
        self.LockTips.gameObject:SetActiveEx(false)
        self.UiBigWorldCommonBtnBigConfirm:ShowTag(false)
        self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(0, XMVCA.XBigWorldService:GetText("SkipTo"))
    else
        local textDialogId = XMVCA.XBigWorldNews:GetNewsEarlyAccessTextDialogId(self._NewsId)

        if XTool.IsNumberValid(self._CustomParamId) and not XTool.IsTableEmpty(self._EarlyAccessSkipIds) then
            local isUnlockEarlyAccess, desc = XMVCA.XBigWorldNews:CheckEarlyAccessCondition(self._NewsId)

            self.LockTips.gameObject:SetActiveEx(true)
            self.BtnDetail.gameObject:SetActiveEx(XTool.IsNumberValid(textDialogId))
            if isUnlockEarlyAccess then
                self.UiBigWorldCommonBtnBigConfirm:ShowTag(XMVCA.XBigWorldNews:CheckQuestNewsHasNew(self._NewsId))
                self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(0, XMVCA.XBigWorldService:GetText("EarlyAccessText"))
                self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(1, XMVCA.XBigWorldService:GetText("EarlyAccessDesc"))
            else
                isUnlock = false
                self.UiBigWorldCommonBtnBigConfirm:ShowTag(false)
                self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(1, desc)
            end
        else
            local preConditions = XMVCA.XBigWorldNews:GetNewsPreConditions(self._NewsId)

            self.LockTips.gameObject:SetActiveEx(true)
            self.BtnDetail.gameObject:SetActiveEx(false)
            self.UiBigWorldCommonBtnBigConfirm:ShowTag(XMVCA.XBigWorldNews:CheckQuestNewsHasNew(self._NewsId))
            self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(0,
                XMVCA.XBigWorldService:GetText("SkipToFinshPreCondition"))
            self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(1,
                XMVCA.XBigWorldService:GetDlcConditionDesc(preConditions[self._FirstNotPassConditionIndex]))
        end
    end
    self.UiBigWorldCommonBtnBigConfirm:SetDisable(finish or not isUnlock, not finish and isUnlock)

    if not isUnlock then
        self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(2, XMVCA.XBigWorldService:GetText("EarlyAccessLock"))
    else
        self.UiBigWorldCommonBtnBigConfirm:SetNameByGroup(2, XMVCA.XBigWorldService:GetText("Complete"))
    end
end

function XUiPanelBWNewsQuest:RefreshTime()
    local countDownTime = XMVCA.XBigWorldNews:GetNewsRemainingTime(self._NewsId)

    if countDownTime > 0 then
        self.ImgTimeBg.gameObject:SetActiveEx(true)
        self.TxtTime.text = XMVCA.XBigWorldCommon:GetCoolTimeStr(countDownTime,
            XMVCA.XBigWorldCommon.CoolTimeFormat.NewsReward)
    else
        self.ImgTimeBg.gameObject:SetActiveEx(false)
    end
end

function XUiPanelBWNewsQuest:OnBtnConfirmClick()
    local isPassed = self._FirstNotPassConditionIndex <= 0

    if isPassed then
        local skipId = XMVCA.XBigWorldNews:GetNewsSkipId(self._NewsId)

        XMVCA.XBigWorldSkipFunction:SkipTo(skipId)
    elseif XTool.IsNumberValid(self._CustomParamId) and not XTool.IsTableEmpty(self._EarlyAccessSkipIds) then
        XMVCA.XBigWorldUI:Open("UiBigWorldPopupAdvance", self._EarlyAccessSkipIds, self._CustomParamId)
    else
        local preSkipIds = XMVCA.XBigWorldNews:GetNewsPreSkipIds(self._NewsId)
        local skipId = preSkipIds[self._FirstNotPassConditionIndex]

        XMVCA.XBigWorldSkipFunction:SkipTo(skipId)
    end
    XMVCA.XBigWorldNews:MarkQuestNewsPreConditionTag(self._NewsId, self._FirstNotPassConditionIndex)
end

function XUiPanelBWNewsQuest:OnBtnTimeDetailClick()
    XMVCA.XBigWorldSkipFunction:SkipTo(XMVCA.XBigWorldNews:GetNewsRewardShowSkipId(self._NewsId))
end

function XUiPanelBWNewsQuest:OnBtnDetailClick()
    local textDialogId = XMVCA.XBigWorldNews:GetNewsEarlyAccessTextDialogId(self._NewsId)

    if XTool.IsNumberValid(textDialogId) then
        XMVCA.XBigWorldUI:OpenTextDialog(textDialogId)
    end
end

function XUiPanelBWNewsQuest:OnTimeRewardClick()
    local taskGroupId = XMVCA.XBigWorldNews:GetNewsTaskGroupId(self._NewsId)

    if XTool.IsNumberValid(taskGroupId) then
        local taskDatas = XMVCA.XBigWorldService:GetTimeLimitTaskListByGroupId(taskGroupId)
        local finishTask = {}

        for _, taskData in pairs(taskDatas) do
            if XMVCA.XBigWorldService:CheckTaskAchieved(taskData.Id) then
                table.insert(finishTask, taskData.Id)
            end
        end

        if not XTool.IsTableEmpty(finishTask) then
            XMVCA.XBigWorldService:FinishMultiTasks(finishTask, function(reward)
                XMVCA.XBigWorldUI:OpenBigWorldObtain(reward)
                self.Parent:RefreshCurrentTabSelect()
                self.Parent:RefreshCurrentPanel()
                self.Parent:RefreshFinish()
            end)
        elseif self._Reward then
            XMVCA.XBigWorldUI:Open("UiBigWorldTip", self._Reward)
        end
    end
end

function XUiPanelBWNewsQuest:IsFinish()
    if not XTool.IsNumberValid(self._NewsId) then
        return false
    end

    local params = XMVCA.XBigWorldNews:GetNewsParams(self._NewsId)
    local questId = params and params[1] or 0

    if not questId or questId <= 0 then
        return false
    end

    if XMVCA.XBigWorldQuest:CheckQuestFinish(questId) then
        local taskGroupId = XMVCA.XBigWorldNews:GetNewsTaskGroupId(self._NewsId)

        if XTool.IsNumberValid(taskGroupId) then
            local taskDatas = XMVCA.XBigWorldService:GetTimeLimitTaskListByGroupId(taskGroupId)

            for _, taskData in pairs(taskDatas) do
                if not (XMVCA.XBigWorldService:CheckTaskFinish(taskData.Id) or XMVCA.XBigWorldService:CheckTaskAchieved(taskData.Id)) then
                    return false
                end
            end
        end

        return true
    end

    return false
end

function XUiPanelBWNewsQuest:IsTime()
    return XMVCA.XBigWorldNews:CheckNewsIsTime(self._NewsId)
end

function XUiPanelBWNewsQuest:SecondUpdate()
    self:RefreshTime()
end

return XUiPanelBWNewsQuest
