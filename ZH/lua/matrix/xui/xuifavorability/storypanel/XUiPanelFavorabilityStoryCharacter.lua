--- 好感剧情界面专用的角色限时送面板
---@class XUiPanelFavorabilityStoryCharacter: XUiNode
local XUiPanelFavorabilityStoryCharacter = XClass(XUiNode, "XUiPanelFavorabilityStoryCharacter")

function XUiPanelFavorabilityStoryCharacter:OnStart()
    if self.BtnSelf then
        self.BtnSelf.CallBack = function() self:OnBtnClick() end
    end
end

function XUiPanelFavorabilityStoryCharacter:SetCharacterId(characterId)
    self.CharacterId = characterId
end

function XUiPanelFavorabilityStoryCharacter:CheckShow()
    local config = XMVCA.XFavorability:GetCharacterStoryActivityConfig(self.CharacterId)
    if not config then
        self:Close()
        return
    end

    local timeId = config.TimeId
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        self:Close()
        return
    end

    self.Config = config
    self:Open()
    self:Refresh()
end

function XUiPanelFavorabilityStoryCharacter:Refresh()
    if not self.Config then return end

    local taskLimitId = self.Config.TaskTimeLimitId
    local taskLimitConfig = XTaskConfig.GetTimeLimitTaskCfg(taskLimitId)
    if not taskLimitConfig then return end

    local taskId = taskLimitConfig.TaskId[1]

    -- Check red point
    local task = XDataCenter.TaskManager.GetTaskDataById(taskId)
    local isAchieved = task and task.State == XDataCenter.TaskManager.TaskState.Achieved
    local isFinish = task and task.State == XDataCenter.TaskManager.TaskState.Finish

    if self.BtnSelf then
        self.BtnSelf:ShowReddot(isAchieved)
        self.BtnSelf.gameObject:SetActiveEx(isAchieved)
    end

    if self.TxtReceive then
        self.TxtReceive.gameObject:SetActiveEx(isFinish)
    end

    -- Update Time
    if self.TxtTime then
        local now = XTime.GetServerNowTimestamp()
        local endTime = XFunctionManager.GetEndTimeByTimeId(self.Config.TimeId)
        local leftTime = endTime - now
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
        self.TxtTips.gameObject:SetActiveEx(not isFinish)
    end

    -- Update Reward
    if self.Grid256New and self.Config.RewardId then
        local rewardList = XRewardManager.GetRewardList(self.Config.RewardId)
        if rewardList and #rewardList > 0 then
            local root = self.Parent
            if root and not root.SetUiSprite and root.Parent and root.Parent.SetUiSprite then
                root = root.Parent
            end
            local grid = XUiHelper.XUiGridCommon(root, self.Grid256New)
            grid:Refresh(rewardList[1])
            if grid.SetReceived then
                grid:SetReceived(isFinish)
            end
        end
    end
end

function XUiPanelFavorabilityStoryCharacter:SetClickEnable(enable)
    self.IsClickEnable = enable
end

function XUiPanelFavorabilityStoryCharacter:OnBtnClick()
    if self.IsClickEnable == false then
        return
    end

    if not self.Config then return end
    local taskLimitId = self.Config.TaskTimeLimitId
    local taskLimitConfig = XTaskConfig.GetTimeLimitTaskCfg(taskLimitId)
    if not taskLimitConfig then return end

    local taskId = taskLimitConfig.TaskId[1]
    local task = XDataCenter.TaskManager.GetTaskDataById(taskId)

    if not task then return end

    if task.State == XDataCenter.TaskManager.TaskState.Achieved then
        local isOwnCharacter = XMVCA.XCharacter:IsOwnCharacter(self.CharacterId)
        XDataCenter.TaskManager.FinishTask(taskId, function(rewardGoodsList)
            XLuaUiManager.OpenWithCloseCallback("UiCommonPopupGetCharacter", function()
                if isOwnCharacter then
                    XUiManager.OpenUiObtain(rewardGoodsList)
                end
            end, self.CharacterId)
            self:Refresh()
        end)
    elseif task.State ~= XDataCenter.TaskManager.TaskState.Finish then
        -- Jump to task or show tip
    end
end

return XUiPanelFavorabilityStoryCharacter
