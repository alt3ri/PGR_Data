--- 当前任务的界面(商店、角色信息）
---@class XUiTheatre5MissionPanel: XUiNode
---@field _Control XTheatre5Control
---@field BtnRewardStateCtrl XUiComponent.XUiStateControl
local XUiTheatre5MissionPanel = XClass(XUiNode, 'XUiTheatre5MissionPanel')
local XUiTheatre5GridTaskDetail = require('XUi/XUiTheatre5/XUiTheatre5ChooseTask/XUiTheatre5GridTaskDetail')

local RewardStateEnum = {
    InProgress = 'InProgress',
    Complete = 'Complete',
}

local UpgradeStateEnum = {
    CanLevelUp = 'CanLevelUp',
    NoTimes = 'NoTimes',
    GoldNotEnough = 'GoldNotEnough',
}

function XUiTheatre5MissionPanel:OnStart()
    self.BtnReward:AddEventListener(handler(self, self.OnBtnRewardClick))
    self.BtnUpgrade:AddEventListener(handler(self, self.OnBtnUpgradeClick))
    self.BtnDetailClose:AddEventListener(handler(self, self.OnBtnDetailCloseClick))
    
    self.UiTheatre5GridTaskDetail.gameObject:SetActiveEx(false)
    self.DetailRoot.gameObject:SetActiveEx(false)
    self.BtnDetailClose.gameObject:SetActiveEx(false)
    
    self._IsDetailShow = false

    ---@type XUiTheatre5GridTaskDetail
    self.TaskDetail = XUiTheatre5GridTaskDetail.New(self.UiTheatre5GridTaskDetail, self)
end

function XUiTheatre5MissionPanel:OnEnable()
    self:Refresh()
    XMVCA.XTheatre5:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_CUR_MISSION, self.Refresh, self)
    XEventManager.AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW, self.Refresh, self)
end

function XUiTheatre5MissionPanel:OnDisable()
    XMVCA.XTheatre5:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_CUR_MISSION, self.Refresh, self)
    XEventManager.RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_GOLD_SHOW, self.Refresh, self)
end

function XUiTheatre5MissionPanel:Refresh()
    local mission = self._Control.MissionControl:GetCurMission()

    if mission then
        local bountyId = mission.MissionBounty.Bounty
        local level = mission.MissionBounty.BountyLevel
        local getBountyItem = mission.MissionRelicId
        
        local isMaxLevel = self._Control.MissionControl:CheckMissionIsMaxLevel(bountyId, level)
        local isRewardGot = mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasReward
        local isComplete = mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasFinish or isRewardGot

        self.BtnUpgrade.gameObject:SetActiveEx(not isMaxLevel and not isComplete)
        self.BtnReward:SetButtonState(CS.UiButtonState.Normal)
        
        self.BtnRewardStateCtrl:ChangeState(isComplete and RewardStateEnum.Complete or RewardStateEnum.InProgress)
        
        
        -- 奖励图标
        local iconRes = ''

        if XTool.IsNumberValidEx(getBountyItem) then
            -- 已领取时显示实际领取的
            local itemCfg = self._Control:GetTheatre5ItemCfgById(getBountyItem)

            if itemCfg then
                iconRes = itemCfg.IconRes
            end
        else
            iconRes = self._Control.MissionControl:GetMissionRewardIcon(bountyId, level)
        end

        if not string.IsNilOrEmpty(iconRes) then
            self.BtnReward:SetRawImage(iconRes)
        end
        
        -- 等级
        self.BtnReward:SetNameByGroup(0, self._Control.MissionControl:GetMissionGridLevelShow(bountyId, level))
        
        -- 升级花费
        local cost = self._Control.MissionControl:GetMissionLevelUpCost(bountyId, level)
        
        self.BtnUpgrade:SetNameByGroup(0, cost)
        
        local goldEnough = self._Control.ShopControl:GetGoldNum() >= cost
        local hasTimes = self._Control.MissionControl:CheckHasMissionLevelUpTimes()
        
        local canLevelUp = goldEnough and hasTimes

        if self.BtnUpgradeStateCtrl then
            if canLevelUp then
                self.BtnUpgradeStateCtrl:ChangeState(UpgradeStateEnum.CanLevelUp)
            elseif not hasTimes then
                self.BtnUpgradeStateCtrl:ChangeState(UpgradeStateEnum.NoTimes)
            elseif not goldEnough then
                self.BtnUpgradeStateCtrl:ChangeState(UpgradeStateEnum.GoldNotEnough)
            end
        else
            self.BtnUpgrade:SetButtonState(canLevelUp and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        end
        
        -- 任务进度
        local targetCount = math.max(self._Control.MissionControl:GetMissionTargetCount(mission.MissionCondition.ConditionId), 1)
        local percent = math.min(mission.MissionCondition.ConditionCounter / targetCount, 1)
        
        self.ImgBar.fillAmount = percent
        
        -- 标题文本
        if self.TxtTitle then
            local isFinishState = mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasFinish
            self.TxtTitle.text = self._Control.MissionControl:GetMissionGridTitle(isFinishState)
        end

        if self.TxtComplete then
            self.TxtComplete.gameObject:SetActiveEx(isRewardGot)
        end
    else
        -- 没有接任务
        self.ImgBar.fillAmount = 0
        self.BtnReward:SetButtonState(CS.UiButtonState.Disable)
        self.BtnUpgrade.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre5MissionPanel:OnBtnDetailCloseClick()
    self.TaskDetail:Close()
    self.DetailRoot.gameObject:SetActiveEx(false)
    self.BtnDetailClose.gameObject:SetActiveEx(false)
    self._IsDetailShow = false
end

function XUiTheatre5MissionPanel:OnBtnRewardClick()
    if self._Control.MissionControl:CheckHasMission() then
        if self._IsDetailShow then
            self:OnBtnDetailCloseClick()
            return
        end

        local mission = self._Control.MissionControl:GetCurMission()

        if mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasFinish then
            XUiManager.TipMsg(self._Control.MissionControl:GetClientConfigMissionFinishTipsInSkillChoicePart())
        end

        self.DetailRoot.gameObject:SetActiveEx(true)
        self.BtnDetailClose.gameObject:SetActiveEx(true)
        self.TaskDetail:Open()
        self.TaskDetail:Refresh(XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InProgress, self._Control.MissionControl:GetCurMission(), mission.MissionRelicId)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
        self._IsDetailShow = true
    else
        XUiManager.TipMsg(XMVCA.XTheatre5:GetClientConfig('NoMissionTips', self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP and 1 or 2))
    end
end

function XUiTheatre5MissionPanel:OnBtnUpgradeClick()
    -- 判断是不是在商店里
    if self._Control:GetCurPlayStatus() == XMVCA.XTheatre5.EnumConst.PlayStatus.ChoiceSkill then
        XUiManager.TipMsg(self._Control.MissionControl:GetClientConfigMissionLevelUpInSkillSelectionPart())
        return
    end
    
    -- 先判断有没有升级次数
    if not self._Control.MissionControl:CheckHasMissionLevelUpTimes() then
        XUiManager.TipMsg(XMVCA.XTheatre5:GetClientConfig('MissionLevelUpNoTimes'))
        return
    end
    
    local mission = self._Control.MissionControl:GetCurMission()
    
    local bountyId = mission.MissionBounty.Bounty
    local level = mission.MissionBounty.BountyLevel
    
    local cost = self._Control.MissionControl:GetMissionLevelUpCost(bountyId, level)
    local canLevelUp = self._Control.ShopControl:GetGoldNum() >= cost
    
    if canLevelUp then
        XMVCA.XTheatre5:RequestTheatre5MissionLevelUp(level, function() 
            self:OnBtnDetailCloseClick()
            self:Refresh()
        end)
    else
        XUiManager.TipMsg(XMVCA.XTheatre5:GetClientConfig('MissionLevelUpNoEnoughGold'))
    end
end

return XUiTheatre5MissionPanel