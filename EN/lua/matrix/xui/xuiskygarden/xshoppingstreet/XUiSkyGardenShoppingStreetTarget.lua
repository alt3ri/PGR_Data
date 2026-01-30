local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiSkyGardenShoppingStreetTargetGridTarget = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetTargetGridTarget")
---@class XUiSkyGardenShoppingStreetTarget : XLuaUi
---@field BtnStart XUiComponent.XUiButton
---@field UiBigWorldItemGrid UnityEngine.RectTransform
---@field GridTarget UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetTarget = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetTarget")

--region 生命周期
function XUiSkyGardenShoppingStreetTarget:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenShoppingStreetTarget:OnEnable()
    self._Control:X3CSetStageStatus(XMVCA.XSkyGardenShoppingStreet.X3CStageStatus.Normal)
end

function XUiSkyGardenShoppingStreetTarget:OnStart(stageId, isConfigOnly)
    self._Control:X3CSetVirtualCameraByCameraIndex(1)
    self._stageId = stageId
    self.IsConfigOnly = isConfigOnly
    if isConfigOnly then
        self.BtnStart.gameObject:SetActive(true)
        self.BtnBack.gameObject:SetActive(false)
        self.BtnYes.gameObject:SetActive(false)
        self.BtnHelp.gameObject:SetActive(false)
    else
        self.BtnStart.gameObject:SetActive(false)
        self.BtnBack.gameObject:SetActive(true)
        self.BtnYes.gameObject:SetActive(true)
        self.BtnHelp.gameObject:SetActive(true)
    end
    
    local stageId = self._stageId
    local config = self._Control:GetStageConfigsByStageId(stageId)

    local historyStageIdList = self._Control:GetPassedStageIds() or {}
    local finishCount = historyStageIdList and #historyStageIdList or 0

    if self.GridTargetFirst then
        self.GridTargetFirstUi = XUiSkyGardenShoppingStreetTargetGridTarget.New(self.GridTargetFirst, self)
        self.GridTargetFirstUi:Update({
            RewardId = config.RewardId,
            ConditionDesc = XMVCA.XBigWorldService:GetText("SG_SS_FirstReward"),
            ConditionDetailDesc = XMVCA.XBigWorldService:GetText("SG_SS_FirstRewardDesc", config.MaxTurn),
            IsGet = finishCount >= stageId,
        }, 0)
    end

    local taskIds = {}
    for taskIndex, taskConfigId in ipairs(config.TargetTaskIds) do
        local taskCfg = self._Control:GetStageTaskConfigsById(taskConfigId)
        table.insert(taskIds, {
            TaskId = taskConfigId,
            RewardId = config.TargetTaskRewards[taskIndex],
            ConditionDesc = taskCfg.ConditionDesc,
            IsGet = self._Control:GetRewardIndexRecordAndIndex(stageId, taskIndex),
        })
    end

    self._Targets = {}
    XTool.UpdateDynamicItem(self._Targets, taskIds, self.GridTarget, XUiSkyGardenShoppingStreetTargetGridTarget, self)
end

function XUiSkyGardenShoppingStreetTarget:GetStageId(...)
    return self._stageId
end
--endregion

--region 按钮事件
function XUiSkyGardenShoppingStreetTarget:OnBtnStartClick()
    self._Control:EnterStreetShopGame(self._stageId)
end

function XUiSkyGardenShoppingStreetTarget:OnBtnBackClick()
    self:Close()
end

function XUiSkyGardenShoppingStreetTarget:OnBtnYesClick()
    self:Close()
end

function XUiSkyGardenShoppingStreetTarget:OnBtnHelpClick()
    self._Control:ShowTeachInfo()
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetTarget:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnStart:AddEventListener(handler(self, self.OnBtnStartClick))
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnYes:AddEventListener(handler(self, self.OnBtnYesClick))
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
end
--endregion

return XUiSkyGardenShoppingStreetTarget
