---@class XUiReCallActivity : XLuaUi
---@field _Control XReCallActivityControl
local XUiReCallActivity = XLuaUiManager.Register(XLuaUi, "UiReCallActivity")
local XUiPanelAuthentication = require("XUi/XReCall/XUiPanelAuthentication")
local XUiPanelRecallTask = require("XUi/XReCall/XUiPanelRecallTask")
local XUiPanelBack = require("XUi/XReCall/XUiPanelBack")
local CSXTextManagerGetText = CS.XTextManager

function XUiReCallActivity:OnAwake()
    self.PanelType = { RecallTask = 1, Authentication = 2, BackOnly = 3, }
    self:InitUiAfterAuto()
end

function XUiReCallActivity:OnStart()
    local endTime = self._Control:GetEndTime()
    self:SetAutoCloseInfo(endTime, Handler(self._Control, self._Control.AutoCloseHandler))
    self.LastSelectIndex = 1
end

function XUiReCallActivity:OnEnable()
    self.TabGroup:SelectIndex(self.LastSelectIndex)
    self:AddEventListener()
end

function XUiReCallActivity:OnDisable()
    self:RemoveEventListener()
    XRedPointManager.RemoveRedPointEvent(self.RewardRedPoint)
    XRedPointManager.RemoveRedPointEvent(self.InvitedRedPoint)
end

function XUiReCallActivity:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_RECALL_TASK_UPDATE, self.OnTaskUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_RECALL_OPEN_STATUS_UPDATE, self.OnStatusUpdate, self)
end

function XUiReCallActivity:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_RECALL_TASK_UPDATE, self.OnTaskUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RECALL_OPEN_STATUS_UPDATE, self.OnStatusUpdate, self)
end

function XUiReCallActivity:OnTaskUpdate()
    if self.RewardRedPoint then
        XRedPointManager.Check(self.RewardRedPoint)
    end
    if self.LastSelectIndex == self.PanelType.RecallTask then
        self.PanelRecallTask:Refresh()
    end
end

function XUiReCallActivity:OnStatusUpdate()
    if self.InvitedRedPoint then
        XRedPointManager.Check(self.InvitedRedPoint)
    end
    if self.LastSelectIndex == self.PanelType.Authentication then
        self.PanelAuthentication:Refresh()
    end
end

function XUiReCallActivity:OnBtnBackClick()
    self:Close()
end

function XUiReCallActivity:InitUiAfterAuto()
    self.PanelCertified.gameObject:SetActiveEx(false)
    self.PanelTask.gameObject:SetActiveEx(false)
    if self.PanelBack then
        self.PanelBack.gameObject:SetActiveEx(false)
    end
    
    self.PanelAuthentication = XUiPanelAuthentication.New(self.PanelCertified, self)
    self.PanelRecallTask = XUiPanelRecallTask.New(self.PanelTask, self)

    if self.PanelBack then
        self.PanelBackCtrl = XUiPanelBack.New(self.PanelBack, self)
    end
    
    self:InitTabGroup()
    self:UpdateButton()

    self.RewardRedPoint = self:AddRedPointEvent(self.PanelTask, self.TaskRewardRedPoint, self, { XRedPointConditions.Types.CONDITION_RECALL_REWARD })
    self.InvitedRedPoint = self:AddRedPointEvent(self.PanelCertified, self.InviteRedPoint, self, { XRedPointConditions.Types.CONDITION_RECALL_INVITE })
    self:RefreshBackOnlyReddot()
    
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self:BindHelpBtn(self.BtnHelp, "UiReCallActivity")
end

function XUiReCallActivity:UpdateButton()
    local activityId = self._Control:GetActivityId()
    local config = self._Control:GetActivityConfigById(activityId)
    self.BtnTabPrefab1:SetName(CSXTextManagerGetText.GetText("HoldRegressiontab2"))
    self.BtnTabPrefab2:SetName(CSXTextManagerGetText.GetText("HoldRegressiontab1"))
    if config then
        if self._Control:GetIsRegression() and self._Control:GetInviteId() == 0 then
            self.ReturnTxt.gameObject:SetActiveEx(true)
            self.ReturnImg.gameObject:SetActiveEx(false)
            self.ReturnTxt.text = config.Text[1]
            --可以填写邀请码时邀请页签靠左
            self.PanelType = { Authentication = 1, RecallTask = 2, BackOnly = 3, }
            self.BtnTabPrefab1:SetName(CSXTextManagerGetText.GetText("HoldRegressiontab1"))
            self.BtnTabPrefab2:SetName(CSXTextManagerGetText.GetText("HoldRegressiontab2"))
        else
            self.ReturnTxt.gameObject:SetActiveEx(false)
            self.ReturnImg.gameObject:SetActiveEx(true)
        end
        self.BgCommon:SetRawImage(config.BgIcon)
    end
end

function XUiReCallActivity:InitTabGroup()
    self.TabList = {
        self.BtnTabPrefab1,
        self.BtnTabPrefab2,
        self.BtnTabPrefab3,
    }
    self.TabGroup:Init(self.TabList, function(index)
        self:OnTaskPanelSelect(index)
    end)
    
    -- 第三个页签固定为回归专属
    if self.BtnTabPrefab3 then
        self._IsOpenBackOnlyTag = XMVCA.XReCallActivity:CheckIsRegressionPlayer()
        self.BtnTabPrefab3.gameObject:SetActiveEx(self._IsOpenBackOnlyTag)
    end
end

function XUiReCallActivity:OnTaskPanelSelect(index)
    self:PlayAnimation("QieHuan")
    self.LastSelectIndex = index
    if index == self.PanelType.Authentication then
        self.PanelRecallTask:Close()
        self.PanelBackCtrl:Close()

        self.PanelAuthentication:Open()
        self.PanelAuthentication:Refresh()
    elseif index == self.PanelType.RecallTask then
        self.PanelAuthentication:Close()
        self.PanelBackCtrl:Close()
        
        self.PanelRecallTask:Open()
        self.PanelRecallTask:Refresh()
    elseif index == self.PanelType.BackOnly then
        self.PanelAuthentication:Close()
        self.PanelRecallTask:Close()

        self.PanelBackCtrl:Open()
        self.PanelBackCtrl:Refresh()
        
        self._Control:SetBackOnlyTagMark()
        self:RefreshBackOnlyReddot()
    end
end

function XUiReCallActivity:TaskRewardRedPoint(result)
    local button = self.TabGroup:GetButtonByIndex(self.PanelType.RecallTask)
    button:ShowReddot(result >= 0)
end

function XUiReCallActivity:InviteRedPoint(result)
    local button = self.TabGroup:GetButtonByIndex(self.PanelType.Authentication)
    button:ShowReddot(result >= 0)
end

--- 刷新回归专属页签的红点
function XUiReCallActivity:RefreshBackOnlyReddot()
    if self._IsOpenBackOnlyTag then
        local button = self.TabGroup:GetButtonByIndex(self.PanelType.BackOnly)

        if button then
            button:ShowReddot(not XMVCA.XReCallActivity:GetBackOnlyTagIsMark())
        end
    end
end

function XUiReCallActivity:GetTaskReward(id)
    self._Control:TaskRewardRequest(id)
end