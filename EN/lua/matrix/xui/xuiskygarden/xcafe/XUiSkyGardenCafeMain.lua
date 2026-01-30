
---@class XUiSkyGardenCafeMain : XBigWorldUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
---@field _PanelHistory XUiPanelSGStageList
---@field _PanelChallenge XUiPanelSGStageList
local XUiSkyGardenCafeMain = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenCafeMain")

local XUiPanelSGStageList = require("XUi/XUiSkyGarden/XCafe/Panel/XUiPanelSGStageList")
local XUiGridSGStageReward = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGStageReward")
local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

local PanelState = {
    None = 0,
    Main = 1,
    History = 2,
    Challenge = 3,
}

function XUiSkyGardenCafeMain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafeMain:OnStart()
    self:InitView()
end

function XUiSkyGardenCafeMain:OnEnable()
    self:ChangePanel(self._DefaultState)
    if self._DefaultState == PanelState.Main then
        --self:PlayAnimation("DarkEnable")
        self:PlayAnimationWithMask("PanelMainEnable", self._OnAnimationCb)
    else
        self._OnAnimationCb()
    end
    self:RefreshRedPoint()
end

function XUiSkyGardenCafeMain:OnDisable()
    self._DefaultState = self._PanelState
    self:ChangePanel(PanelState.None)
end

function XUiSkyGardenCafeMain:OnDestroy()
    self._IsPrepareQuit = false
end

function XUiSkyGardenCafeMain:InitUi()
    self._Rewards = {}
    self._PreRewards = {}
    self.TxtName.text = XMVCA.XSkyGardenCafe:GetName()
    self._PanelHistory = XUiPanelSGStageList.New(self.PanelHistory, self, false)
    self._PanelChallenge = XUiPanelSGStageList.New(self.PanelChallenge, self, true)

    self.GridReward.gameObject:SetActiveEx(false)
    self.TxtHistoryLockTips.gameObject:SetActiveEx(false)

    self._DefaultState = PanelState.Main

end

function XUiSkyGardenCafeMain:InitCb()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    
    self.BtnStart:AddEventListener(handler(self, self.OnBtnStartClick))
    
    self.BtnChallenge:AddEventListener(handler(self, self.OnBtnChallengeClick))
    
    self.BtnHistory:AddEventListener(handler(self, self.OnBtnHistoryClick))
    
    self.BtnHelp:AddEventListener(function() 
        XMVCA.XBigWorldTeach:OpenTeachTipUi(XMVCA.XSkyGardenCafe:GetTeachId())
    end)
    
    local function onAnimationCb()
        local isMain = self._PanelState == PanelState.Main
        self.BtnStart.gameObject:SetActiveEx(isMain)
        self.BtnChallenge.gameObject:SetActiveEx(isMain)
        self.BtnHistory.gameObject:SetActiveEx(isMain)
    end
    self._OnAnimationCb = onAnimationCb
end

function XUiSkyGardenCafeMain:InitView()
    self:RefreshPreviewReward()
end

function XUiSkyGardenCafeMain:ChangePanel(state)
    if self._PanelState == state then
        return
    end
    local isMain = state == PanelState.Main
    self.BtnStart.gameObject:SetActiveEx(true)
    self.BtnChallenge.gameObject:SetActiveEx(true)
    self.BtnHistory.gameObject:SetActiveEx(true)
    if isMain then
        self.PanelMain.gameObject:SetActiveEx(true)
        self._PanelHistory:Close()
        self._PanelChallenge:Close()
        self:RefreshMain()
    elseif state == PanelState.History then
        self.PanelMain.gameObject:SetActiveEx(false)
        --避免XUiNode的生命周期异常
        --self:RefreshReward(0, nil)
        self._PanelChallenge:Close()
        self._PanelHistory:Open()
    elseif state == PanelState.Challenge then
        self.PanelMain.gameObject:SetActiveEx(false)
        --避免XUiNode的生命周期异常
        --self:RefreshReward(0, nil)
        self._PanelHistory:Close()
        self._PanelChallenge:Open()
    else
        self.PanelMain.gameObject:SetActiveEx(false)
        --self:RefreshReward(0, nil)
        self._PanelHistory:Close()
        self._PanelChallenge:Close()
    end
    self._PanelState = state
end

function XUiSkyGardenCafeMain:RefreshMain()
    local curStageId = self._Control:GetFirstNotPassStoryStage()
    local stageName
    if XTool.IsNumberValid(curStageId) then
        self.BtnStart:ShowTag(false)
        self.RImgTitleBg.gameObject:SetActiveEx(true)
        local rewardIds = self._Control:GetStageReward(curStageId)
        self:RefreshReward(curStageId, rewardIds)
        stageName = self._Control:GetStageName(curStageId)
        local passed, desc = self._Control:CheckStageCondition(curStageId)
        self.PanelLock.gameObject:SetActiveEx(not passed)
        if not passed then
            self.TxtStartLockTips.text = desc
        end
    else
        self.BtnStart:ShowTag(true)
        self.RImgTitleBg.gameObject:SetActiveEx(false)
        local cur, total = self._Control:GetHistoryProgress()
        self:RefreshReward(0, nil)
        stageName = string.format("%d/%d", cur, total)
        self.PanelLock.gameObject:SetActiveEx(false)
    end
    self.BtnStart:SetNameByGroup(0, stageName)
    local openChallenge = self._Control:IsChallengeOpen()
    self.BtnChallenge:ShowTag(not openChallenge)
    self.PanelChallengeStar.gameObject:SetActiveEx(openChallenge)
    if openChallenge then
        local cur, total = self._Control:GetChallengeProgress()
        self.BtnChallenge:SetNameByGroup(0, string.format("%d/%d", cur, total))
    end

    local openHistory = self._Control:IsHistoryOpen()
    self.BtnHistory:ShowTag(not openHistory)
    self.PanelHistoryStar.gameObject:SetActiveEx(openHistory)
    if openHistory then
        local cur, total = self._Control:GetHistoryProgress()
        self.BtnHistory:SetNameByGroup(0, string.format("%d/%d", cur, total))
    --else
    --    self.TxtHistoryLockTips.text = self._Control:GetHistoryLockText()
    end
end

function XUiSkyGardenCafeMain:RefreshReward(stageId, rewardIds)
    local rewards = {}
    if not XTool.IsTableEmpty(rewardIds) then
        local targets = self._Control:GetStageTarget(stageId)
        local star = self._Control:GetStageInfo(stageId):GetStar()
        for index, rewardId in pairs(rewardIds) do
            local list = XRewardManager.GetRewardList(rewardId)
            local reward, target = nil, 0
            if list then
                --只显示第一个
                reward = list[1]
            end
            if targets then
                target = targets[index]
            end
            rewards[#rewards + 1] = {
                Reward = reward,
                Target = target,
                IsReceive = star >= index
            }
        end
    end
    
    XTool.UpdateDynamicItem(self._Rewards, rewards, self.GridReward, XUiGridSGStageReward, self)
end

function XUiSkyGardenCafeMain:RefreshPreviewReward()
    local rewards = XMVCA.XSkyGardenCafe:GetRewards()
    if not XTool.IsTableEmpty(rewards) then
        XTool.UpdateDynamicItem(self._PreRewards, rewards, self.UiBigWorldItemGrid, XUiGridBWItem, self)
    end
end
 
function XUiSkyGardenCafeMain:OnBtnStartClick()
    local curStageId = self._Control:GetFirstNotPassStoryStage()
    if not curStageId or curStageId <= 0 then
        XUiManager.TipMsg(self._Control:GetAllStoryStagePassedTip())
        return
    end
    local passed, desc = self._Control:CheckStageCondition(curStageId)
    if not passed then
        XUiManager.TipMsg(desc)
        return
    end
    --self:PlayAnimation("DarkDisable", function() 
    --    --self._Control:EnterFight(curStageId)
    --    self._Control:SetFightData(curStageId, 0)
    --    XMVCA.XSkyGardenCafe:EnterGameLevel()
    --end)

    self._Control:SetFightData(curStageId, 0)
    XMVCA.XSkyGardenCafe:EnterGameLevel()
end

function XUiSkyGardenCafeMain:OnBtnChallengeClick()
    if not self._Control:IsChallengeOpen() then
        return
    end
    self:PlayAnimationWithMask("PanelChallengeEnable", self._OnAnimationCb)
    self:ChangePanel(PanelState.Challenge)
end

function XUiSkyGardenCafeMain:OnBtnHistoryClick()
    if not self._Control:IsHistoryOpen() then
        XUiManager.TipMsg(self._Control:GetHistoryLockText())
        return
    end
    self:PlayAnimationWithMask("PanelHistoryEnable", self._OnAnimationCb)
    self:ChangePanel(PanelState.History)
end

function XUiSkyGardenCafeMain:OnBtnCloseClick()
    if self._PanelState == PanelState.Challenge then
        self:PlayAnimationWithMask("PanelChallengeDisable", function()
            self:ChangePanel(PanelState.Main)
        end, function()
            self.BtnStart.gameObject:SetActiveEx(true)
            self.BtnChallenge.gameObject:SetActiveEx(true)
            self.BtnHistory.gameObject:SetActiveEx(true)
        end)
        return
    elseif self._PanelState == PanelState.History then
        self:PlayAnimationWithMask("PanelHistoryDisable", function()
            self:ChangePanel(PanelState.Main)
        end, function()
            self.BtnStart.gameObject:SetActiveEx(true)
            self.BtnChallenge.gameObject:SetActiveEx(true)
            self.BtnHistory.gameObject:SetActiveEx(true)
        end)
        return
    end

    if not XMVCA.XSkyGardenCafe:IsEnterLevel() then
        self:PlayAnimation("PanelMainDisable", function()
            XMVCA.XSkyGardenCafe:DoLevelLevel()
        end)
        return
    end
    if self._IsPrepareQuit then
        return
    end
    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()
    confirmData:InitInfo(self._Control:GetTipTitle(), self._Control:GetQuitText())
    confirmData:InitToggleActive(false):InitSureClick(nil, function()
        self._IsPrepareQuit = true
        self:PlayAnimationWithMask("PanelMainDisable", function()
            XMVCA.XSkyGardenCafe:ExitGameLevel()
        end)
    end)

    XMVCA.XBigWorldUI:Open("UiSkyGardenCafePopupDetail", confirmData)
end

function XUiSkyGardenCafeMain:RefreshRedPoint()
    local showMainRed = false
    local curStageId = self._Control:GetFirstNotPassStoryStage()
    if curStageId and curStageId > 0 then
        showMainRed = self._Control:CheckStageNewMark(curStageId)
    end
    self.BtnStart:ShowReddot(showMainRed)
    
    self.BtnChallenge:ShowReddot(self._Control:CheckStageNewMarkByType(XMVCA.XSkyGardenCafe.StageType.Challenge))
end