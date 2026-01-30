local XUiSkyGardenShoppingStreetMainHistory = require("XUi/XUiSkyGarden/XShoppingStreet/XUiSkyGardenShoppingStreetMainHistory")

---@class XUiSkyGardenShoppingStreetMain : XLuaUi
---@field TxtName UnityEngine.UI.Text
---@field BtnStart XUiComponent.XUiButton
---@field BtnChallenge XUiComponent.XUiButton
---@field BtnHistory XUiComponent.XUiButton
---@field PanelHistory UnityEngine.RectTransform
---@field ListReward UnityEngine.RectTransform
---@field PanelMain UnityEngine.RectTransform
---@field PanelNone UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetMain = XMVCA.XBigWorldUI:Register(nil,  "UiSkyGardenShoppingStreetMain")
local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiSkyGardenShoppingStreetMainGridTarget = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetMainGridTarget")

local XShoppingStreetMainPageType = {
    Main = 1,
    History = 2,
}

--region 生命周期
function XUiSkyGardenShoppingStreetMain:OnStart()
    self:_RegisterButtonClicks()

    ---@type XUiSkyGardenShoppingStreetMainHistory
    self.PanelHistoryUi = XUiSkyGardenShoppingStreetMainHistory.New(self.PanelHistory, self)
    self.ListReward.gameObject:SetActive(true)
    self.BtnChallenge.gameObject:SetActive(false)

    self._TargetTaskUI = {}
    self._RewardUIs = {}
    -- local rewardId = tonumber(self._Control:GetGlobalConfigByKey("MainRewardShowId")) or 0
    self._Rewards = XMVCA.XSkyGardenShoppingStreet:GetRewards()--XRewardManager.GetRewardList(rewardId)

    self:ChangePage(XShoppingStreetMainPageType.Main)
    self._Control:X3CSetStageStatus(XMVCA.XSkyGardenShoppingStreet.X3CStageStatus.Normal)
end

function XUiSkyGardenShoppingStreetMain:OnEnable()
    self:RefreshPage()
end

function XUiSkyGardenShoppingStreetMain:OnGetLuaEvents()
    return { XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_STAGE_REFRESH }
end

function XUiSkyGardenShoppingStreetMain:OnNotify(event, ...)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_STAGE_REFRESH then
        self:RefreshPage()
    end
end
--endregion

--region 按钮事件

function XUiSkyGardenShoppingStreetMain:OnBtnHelpClick()
    self._Control:ShowTeachInfo()
end

function XUiSkyGardenShoppingStreetMain:OnBtnStartClick()
    local stageId = self._Control:GetCurrentStageId(true)
    local stageCfg = self._Control:GetStageConfigsByStageId(stageId)
    local conditionId = stageCfg.Condition
    if conditionId and conditionId ~= 0 then
        local result, desc = XMVCA.XBigWorldService:CheckCondition(stageCfg.Condition)
        if not result then
            XMVCA.XSkyGardenShoppingStreet:Toast(desc)
            return
        end
    end
    XMVCA.XSkyGardenShoppingStreet:StartStage(self._Control:GetCurrentStageId(true))
end

function XUiSkyGardenShoppingStreetMain:OnBtnChallengeClick()
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetAchieve")
end

function XUiSkyGardenShoppingStreetMain:OnBtnHistoryClick()
    self:ChangePage(XShoppingStreetMainPageType.History)
end

function XUiSkyGardenShoppingStreetMain:OnBtnReturnClick()
    self:ChangePage(XShoppingStreetMainPageType.Main)
end

function XUiSkyGardenShoppingStreetMain:OnBtnGiveupClick()
    self._Control:GiveupStage()
end

function XUiSkyGardenShoppingStreetMain:OnBtnLeaveClick()
    if self.PageIndex == XShoppingStreetMainPageType.History then
        self:ChangePage(XShoppingStreetMainPageType.Main)
        return
    end
    XMVCA.XSkyGardenShoppingStreet:ExitGameLevel()
end

--endregion

--region 共有方法
-- 切换页
function XUiSkyGardenShoppingStreetMain:ChangePage(pageIndex)
    if self.PageIndex ~= pageIndex then
        self.PageIndex = pageIndex
        self.PanelMain.gameObject:SetActive(pageIndex == XShoppingStreetMainPageType.Main)
        if pageIndex == XShoppingStreetMainPageType.History then
            self.PanelHistoryUi:Open()
        else
            self.PanelHistoryUi:Close()
        end
    end
    self:RefreshPage(pageIndex)
end

-- 刷新
function XUiSkyGardenShoppingStreetMain:RefreshPage(pageIndex)
    pageIndex = pageIndex or self.PageIndex
    if pageIndex == XShoppingStreetMainPageType.Main then
        self._Control:X3CSetVirtualCameraByCameraIndex(4)
        self:RefreshMainPage()
        XTool.UpdateDynamicItem(self._RewardUIs, self._Rewards, self.UiBigWorldItemGrid, XUiGridBWItem, self)
    elseif pageIndex == XShoppingStreetMainPageType.History then
        self._Control:X3CSetVirtualCameraByCameraIndex(4)
        XTool.UpdateDynamicItem(self._RewardUIs, nil, self.UiBigWorldItemGrid, XUiGridBWItem, self)
        XTool.UpdateDynamicItemByUiCache(self._TargetTaskUI, nil, self.GridTarget.transform.parent)
        self.PanelHistoryUi:Refresh()
    end
    local isRunningStage = self._Control:IsStageRunning()
    self.BtnGiveup.gameObject:SetActive(isRunningStage)
    self.BtnContinue.gameObject:SetActive(isRunningStage)
    self.BtnStart.gameObject:SetActive(not isRunningStage)
end

function XUiSkyGardenShoppingStreetMain:RefreshMainPage()
    local isRunningStage = self._Control:IsStageRunning()
    local historyStageIdList = self._Control:GetPassedStageIds() or {}
    -- local currentStageId = self._Control:GetCurrentStageId()
    -- local targetStageId = self._Control:GetTargetStageId()

    local maxStageId = self._Control:GetMaxStageId()
    local finishCount = historyStageIdList and #historyStageIdList or 0
    local isFinishAllStage = finishCount >= maxStageId
    local isShowTarget = not isFinishAllStage or isRunningStage
    self.BtnHistory.gameObject:SetActive(finishCount > 0)

    local key = not isRunningStage and "SG_SS_RunStart" or "SG_SS_RunContinue"
    self.TxtTitle.text = XMVCA.XBigWorldService:GetText(key)
    
    self.PanelComplete.gameObject:SetActive(not isShowTarget)
    self.PanelNone.gameObject:SetActive(false)
    self.ListTarget.gameObject:SetActive(true)
    if isShowTarget then
        local stageId = self._Control:GetCurrentStageId(true)
        local config = self._Control:GetStageConfigsByStageId(stageId)

        self.TxtStageName.text = config.Name
        local taskIds = {
            {
                RewardId = config.RewardId,
                IsGet = finishCount >= stageId,
                -- ConditionDesc = XMVCA.XBigWorldService:GetText("SG_SS_FirstReward"),
                ConditionDesc = XMVCA.XBigWorldService:GetText("SG_SS_FirstRewardDesc", config.MaxTurn),
            }
        }
        
        for taskIndex, taskConfigId in ipairs(config.TargetTaskIds) do
            local taskCfg = self._Control:GetStageTaskConfigsById(taskConfigId)
            table.insert(taskIds, {
                RewardId = config.TargetTaskRewards[taskIndex],
                ConditionDesc = taskCfg.ConditionDesc,
                IsGet = self._Control:GetRewardIndexRecordAndIndex(stageId, taskIndex),
            })
        end
        
        XTool.UpdateDynamicItemByUiCache(self._TargetTaskUI, taskIds, self.GridTarget.transform.parent, XUiSkyGardenShoppingStreetMainGridTarget, self)
    else
        self.TxtStageName.text = ""
        self.TxtTargetStarCountNum.text = string.format("%d/%d", self._Control:GetCurrentStarNum(), self._Control:GetTotalStarNum())
        XTool.UpdateDynamicItemByUiCache(self._TargetTaskUI, nil, self.GridTarget.transform.parent)
    end
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetMain:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
    self.BtnStart:AddEventListener(handler(self, self.OnBtnStartClick))
    self.BtnContinue:AddEventListener(handler(self, self.OnBtnStartClick))
    self.BtnChallenge:AddEventListener(handler(self, self.OnBtnChallengeClick))
    self.BtnHistory:AddEventListener(handler(self, self.OnBtnHistoryClick))
    self.BtnReturn:AddEventListener(handler(self, self.OnBtnReturnClick))
    self.BtnGiveup:AddEventListener(handler(self, self.OnBtnGiveupClick))
    self.BtnBack:AddEventListener(handler(self, self.OnBtnLeaveClick))
end
--endregion

return XUiSkyGardenShoppingStreetMain
