---@class XUiPaintingExperiencePassV4P2 : XUiPaintingExperiencePassV4P2Partial

local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiPaintingExperiencePassV4P2 = XLuaUiManager.Register(XLuaUi, "UiPaintingExperiencePassV4P2")

function XUiPaintingExperiencePassV4P2:OnAwake()
    self:AddListener()
end

function XUiPaintingExperiencePassV4P2:OnStart(trialLevelId)
    self.RewardPanelList = {}
    self.TrialLevelInfo =  XDataCenter.FubenExperimentManager.GetFashionTrailLevelById(trialLevelId)
    self.TxtTitle.text = self.TrialLevelInfo.Name
    if self.TrialLevelInfo.DetailBackGroundIco then
        self.ImgFullScreen.gameObject:SetActiveEx(true)
        self.ImgFullScreen:SetRawImage(self.TrialLevelInfo.DetailBackGroundIco)
    end
    if self.TrialLevelInfo.HeadIcon then
        self.RImgNandu:SetRawImage(self.TrialLevelInfo.HeadIcon)
    end

    local skipids = XDataCenter.FashionManager.GetFashionSkipIdParams(self.TrialLevelInfo.FashionId)
    self.SkipIds = {}
    if skipids then
        for _, v in pairs(skipids) do
            if XFunctionManager.CheckSkipInDuration(v, false) then
                table.insert(self.SkipIds, v)
            end
        end
    end
    self.BtnPurchase.gameObject:SetActiveEx(#self.SkipIds > 0)
    self:UpdateFirstReward()
    self:UpdateDes()
end

function XUiPaintingExperiencePassV4P2:AddListener()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnMainUi:AddEventListener(handler(self, XLuaUiManager.RunMain))
    self.BtnStory:AddEventListener(handler(self, self.ShowDesc))
    self.BtnCloseTips:AddEventListener(handler(self, self.HideDesc))
    self.BtnSingleEnter:AddEventListener(handler(self, self.OnBtnSingleEnterClick))
    self.BtnPurchase:AddEventListener(handler(self, self.OnBtnPurchase))
end

function XUiPaintingExperiencePassV4P2:UpdateFirstReward()
    self.GridCommon.gameObject:SetActiveEx(false)
    local stage = XDataCenter.FubenManager.GetStageCfg(self.TrialLevelInfo.SingStageId)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(self.TrialLevelInfo.SingStageId)
    local rewardId = 0
    local IsFirst = false
    for i = 1, #self.RewardPanelList do
        self.RewardPanelList[i]:Refresh()
    end
    rewardId = stage.FirstRewardShow
    if not stageInfo.Passed then
        IsFirst = true
    end

    if not rewardId or rewardId == 0 then
        return
    end

    local rewardsList = XRewardManager.GetRewardList(rewardId)
    if not rewardsList then return end

    for i = 1, #rewardsList do
        local panel = self.RewardPanelList[i]
        if not panel then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            ui.gameObject:SetActiveEx(true)
            ui.transform:SetParent(self.PanelDropContent, false)
            panel = XUiGridCommon.New(self, ui)
            table.insert(self.RewardPanelList, panel)
        end
        local temp = {
            ShowReceived = not IsFirst
        }
        panel:Refresh(rewardsList[i], temp)
    end
end

function XUiPaintingExperiencePassV4P2:UpdateDes()
    self.TxtDes.text = string.gsub(self.TrialLevelInfo.SingleDescription, "\\n", "\n")
end

function XUiPaintingExperiencePassV4P2:ShowDesc()
    self.PanelNor.gameObject:SetActiveEx(true)
end

function XUiPaintingExperiencePassV4P2:HideDesc()
    self.PanelNor.gameObject:SetActiveEx(false)
end

function XUiPaintingExperiencePassV4P2:OnBtnSingleEnterClick()
    if self.TrialLevelInfo.TimeId and self.TrialLevelInfo.TimeId ~= 0 then
        if XFunctionManager.CheckInTimeByTimeId(self.TrialLevelInfo.TimeId) then
            XLuaUiManager.Open("UiBattleRoleRoom", self.TrialLevelInfo.SingStageId)
        else
            XUiManager.TipText("ActivityBranchNotOpen")
        end
    else
        XLuaUiManager.Open("UiBattleRoleRoom", self.TrialLevelInfo.SingStageId)
    end
end

function XUiPaintingExperiencePassV4P2:OnBtnPurchase()
    if XLuaUiManager.IsUiLoad("UiFashionDetail") or XLuaUiManager.IsUiLoad("UiFashionSuitDetail") then
        self:Close()
    else
        XFunctionManager.SkipInterface(self.SkipIds[1], "UiPaintingExperiencePassV4P2")
    end
end

return XUiPaintingExperiencePassV4P2
