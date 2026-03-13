--- 试玩角色主界面专用的角色限时送面板
--- BtnSelf常驻显示，点击跳转好感剧情
---@class XUiPanelCharacterFileMainCharacter: XUiNode
local XUiPanelCharacterFileMainCharacter = XClass(XUiNode, "XUiPanelCharacterFileMainCharacter")

function XUiPanelCharacterFileMainCharacter:OnStart()
    if self.BtnSelf then
        self.BtnSelf.CallBack = handler(self, self.OnBtnClick)
    end
end

function XUiPanelCharacterFileMainCharacter:SetCharacterId(characterId)
    self.CharacterId = characterId
end

function XUiPanelCharacterFileMainCharacter:CheckShow()
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

function XUiPanelCharacterFileMainCharacter:Refresh()
    if not self.Config then return end

    local taskLimitId = self.Config.TaskTimeLimitId
    local taskLimitConfig = XTaskConfig.GetTimeLimitTaskCfg(taskLimitId)
    if not taskLimitConfig then return end

    local taskId = taskLimitConfig.TaskId[1]

    local task = XDataCenter.TaskManager.GetTaskDataById(taskId)
    local isAchieved = task and task.State == XDataCenter.TaskManager.TaskState.Achieved
    local isFinish = task and task.State == XDataCenter.TaskManager.TaskState.Finish

    -- BtnSelf 常驻显示，仅控制红点
    if self.BtnSelf then
        self.BtnSelf:ShowReddot(isAchieved)
        self.BtnSelf.gameObject:SetActiveEx(true)
    end

    if self.TxtReceive then
        self.TxtReceive.gameObject:SetActiveEx(isFinish)
    end

    if self.TxtTime then
        local now = XTime.GetServerNowTimestamp()
        local endTime = XFunctionManager.GetEndTimeByTimeId(self.Config.TimeId)
        local leftTime = endTime - now
        self.TxtTime.text = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
        self.TxtTips.gameObject:SetActiveEx(not isFinish)
    end

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

--- 与 XUiPanelCharacterFileMain:OnBtnStoryClick 完全一致
function XUiPanelCharacterFileMainCharacter:OnBtnClick()
    local result = XMVCA.XFavorability:OpenUiStory(self.CharacterId, XEnumConst.Favorability.FavorabilityStoryEntranceType.CharacterFile)

    if result == -2 then
        XLog.Error('配置的角色Id无效, TeachingActivity配置 Id:'..tostring(self.Parent.ActivityCfg.Id))
    end
end

return XUiPanelCharacterFileMainCharacter
