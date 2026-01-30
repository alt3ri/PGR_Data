--- pvp 任务详情页
---@class XUiTheatre5GridTaskDetail: XUiNode
---@field _Control XTheatre5Control
local XUiTheatre5GridTaskDetail = XClass(XUiNode, 'XUiTheatre5GridTaskDetail')

function XUiTheatre5GridTaskDetail:OnStart()
    self:InitBtns()
end

function XUiTheatre5GridTaskDetail:InitBtns()
    if self.BtnChoose then
        self.BtnChoose:AddEventListener(handler(self, self.OnBtnChooseClick))
    end

    if self.BtnRefresh then
        self.BtnRefresh:AddEventListener(handler(self, self.OnBtnRefreshClick))
    end
end

function XUiTheatre5GridTaskDetail:SetPosInChoose(pos)
    self.Pos = pos
end

---@param mission Theatre5Mission
function XUiTheatre5GridTaskDetail:Refresh(showType, mission, showItemId)
    self.ShowType = showType
    self.Mission = mission
    self.ShowItemId = showItemId
    self:RefreshBtnsShow()
    self:RefreshDetail()
end

function XUiTheatre5GridTaskDetail:RefreshBtnsShow()
    local isInChoose = self.ShowType == XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InChoose

    if self.BtnChoose then
        self.BtnChoose.gameObject:SetActiveEx(isInChoose)
    end

    if self.BtnRefresh then
        local canRefresh = XTool.IsNumberValidEx(self.Pos) and self._Control.MissionControl:CheckMissionCanRefreshByPos(self.Pos)
        
        self.BtnRefresh.gameObject:SetActiveEx(isInChoose and canRefresh)
    end
end

function XUiTheatre5GridTaskDetail:RefreshDetail()
    self.TxtActivate.transform.parent.gameObject:SetActiveEx(false)
    
    -- 任务条件描述
    local conditionId = self.Mission.MissionCondition.ConditionId

    if XTool.IsNumberValidEx(conditionId) then
        local desc = self._Control.MissionControl:GetTableMissionConditionDescById(conditionId)

        if not string.IsNilOrEmpty(desc) then
            desc = XUiHelper.ReplaceTextNewLine(desc)
        end

        self.TxtTaskDes.text = desc
    end
    
    local isMaxLevel = self._Control.MissionControl:CheckMissionIsMaxLevel(self.Mission.MissionBounty.Bounty, self.Mission.MissionBounty.BountyLevel)
    local isComplete = false

    -- 结算弹窗只要完成了就显示结算后的表现
    if self.ShowType == XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InComplete then
        isComplete = self.Mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasFinish or self.Mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasReward
    else
        -- 其他弹窗只有领取了奖励才显示结算后的表现
        isComplete = self.Mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasReward
    end
    
    local curLevel = (self.ShowType == XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InProgress or self.ShowType == XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InComplete)and self.Mission.MissionBounty.BountyLevel or nil

    -- 领取任务时默认按1级显示
    if self.ShowType == XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InChoose then
        curLevel = 1 
    end
    
    local name = ''
    local level = self.Mission.MissionBounty.BountyLevel
    local iconRes = ''
    local rewardDecs = ''

    -- 如果指定了道具，则直接取
    if XTool.IsNumberValidEx(self.ShowItemId) then
        local itemCfg = self._Control:GetTheatre5ItemCfgById(self.ShowItemId)

        if itemCfg then
            name = itemCfg.Name
            iconRes = itemCfg.IconRes
            rewardDecs = self._Control:GetItemDesc(itemCfg)
        end
    else
        name = self._Control.MissionControl:GetTableMissionRewardNameById(self.Mission.MissionId)
        iconRes = self._Control.MissionControl:GetMissionRewardIcon(self.Mission.MissionBounty.Bounty, self.Mission.MissionBounty.BountyLevel)

        local isSingleShow = XTool.IsNumberValidEx(curLevel) and isComplete
        rewardDecs = self._Control.MissionControl:GetMissionRewardDesc(self.Mission.MissionBounty.Bounty, curLevel, isSingleShow)
    end
    
    -- 奖励名称
    self.TxtName.text = name
    
    -- 奖励图标
    if not string.IsNilOrEmpty(iconRes) then
        self.RImgTaskIcon:SetRawImage(iconRes)
    end

    -- 奖励等级
    if self.TxtLv then
        self.TxtLv.text = self._Control.MissionControl:GetClientConfigMissionLvFormat(level, isMaxLevel)
    end
    
    -- 显示链接的花费描述
    if isMaxLevel or isComplete then
        self.PanelConsume.gameObject:SetActiveEx(false)

        self.TxtActivate.transform.parent.gameObject:SetActiveEx(true)

        if isComplete then
            self.TxtActivate.text = XMVCA.XTheatre5:GetClientConfig('MissionCompleteLabel')
            
            -- 任务完成后隐藏任务条件
            if self.TaskDetail then
                self.TaskDetail.gameObject:SetActiveEx(false)
            end
        else
            self.TxtActivate.text = XMVCA.XTheatre5:GetClientConfig('MissionMaxLevelLabel')
        end
    else
        self.PanelConsume.gameObject:SetActiveEx(true)
        
        self.TxtConsume.text = self._Control.MissionControl:GetMissionLevelUpCostDesc(self.Mission.MissionBounty.Bounty, curLevel)
    end
    
    -- 显示奖励描述
    self.TxtRewardDes.text = rewardDecs
end

function XUiTheatre5GridTaskDetail:ShowTaskDetail()
    if self.TaskDetail then
        self.TaskDetail.gameObject:SetActiveEx(true)
    end
end

function XUiTheatre5GridTaskDetail:OnBtnChooseClick()
    XMVCA.XTheatre5:RequestTheatre5MissionChoose(self.Pos, function() 
        self.Parent:Close()
    end)
end

function XUiTheatre5GridTaskDetail:OnBtnRefreshClick()
    XMVCA.XTheatre5:RequestTheatre5MissionFresh(self.Pos, function()
        self.Mission = self._Control.MissionControl:GetChooseMissionByPos(self.Pos)
        
        self:RefreshDetail()
        self:RefreshBtnsShow()
    end)
end

function XUiTheatre5GridTaskDetail:CloseWithAnimation(cb)
    local isAnimaStart = false
    
    self:PlayAnimationWithMask('Disable', function() 
        self:Close()

        if cb then
            cb()
        end
    end, function() 
        isAnimaStart = true
    end)

    if not isAnimaStart then
        self:Close()

        if cb then
            cb()
        end
    end
end

return XUiTheatre5GridTaskDetail