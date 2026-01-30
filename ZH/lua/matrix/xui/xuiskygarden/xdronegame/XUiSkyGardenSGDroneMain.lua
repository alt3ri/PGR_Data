local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiBWPanelAsset = require("XUi/XUiBigWorld/XCommon/XPanelAsset/XUiBWPanelAsset")

---@class XUiSkyGardenSGDroneMain : XBigWorldUi
---@field PanelSpecialTool UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButtonExt
---@field BtnMainUi XUiComponent.XUiButtonExt
---@field BtnHelp XUiComponent.XUiButtonExt
---@field BtnStore XUiComponent.XUiButtonExt
---@field BtnContinue XUiComponent.XUiButtonExt
---@field TxtName UnityEngine.UI.Text
---@field TxtNormalTitle UnityEngine.UI.Text
---@field TxtNormalNum UnityEngine.UI.Text
---@field TxtDifficultTitle UnityEngine.UI.Text
---@field TxtDifficultNum UnityEngine.UI.Text
---@field BtnConfirm XUiComponent.XUiButtonExt
---@field BtnCancel XUiComponent.XUiButtonExt
---@field ListPreviewReward UnityEngine.RectTransform
---@field RewardGrid UnityEngine.RectTransform
---@field ScrollRect UnityEngine.RectTransform
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDroneMain = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDroneMain")

function XUiSkyGardenSGDroneMain:OnAwake()
    ---@type XUiGridBWItem[]
    self._RewardGrids = {}

    ---@type XUiBWPanelAsset
    self._PanelAsset = XUiBWPanelAsset.New(self.PanelSpecialTool, self, self._Control:GetShopItemIds())
    self._PanelAsset:Open()

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneMain:OnStart()
end

function XUiSkyGardenSGDroneMain:OnEnable()
    self._Control:SendSwitchMainViewCmd()
    self:_RefreshButtonState()
    self:_RefreshShopRewards()
    self:_RefreshProgress()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneMain:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneMain:OnDestroy()
end

function XUiSkyGardenSGDroneMain:OnBtnConfirmClick()
    if not self._Control:CheckHaveArchive() then
        XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneChapter")
    end
end

function XUiSkyGardenSGDroneMain:OnBtnContinueClick()
    if self._Control:CheckHaveArchive() then
        local storageStageData = self._Control:GetStorageStageData()
        local stageId = storageStageData.CurStageId
        local isHardMode = storageStageData.IsHardMode
        local stageEntity = self._Control:GetStageEntity(stageId)

        self._Control:RequestStageStart(stageId, isHardMode, function(stageData)
            XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneLoading")
            XMVCA.XBigWorldUI:Open("UiSkyGardenSGDroneGame", stageId, stageEntity:GetMapId(), stageData, isHardMode,
                stageEntity:GetEasyDroneHp(), stageEntity:IsEnableAssistance())
        end)
    end
end

function XUiSkyGardenSGDroneMain:OnBtnCancelClick()
    local confirmData = XMVCA.XBigWorldCommon:GetPopupConfirmData()

    confirmData:InitInfo(nil, self._Control:GetGiveUpFightText()):InitSureClick(nil, function()
        self._Control:RequestStageGiveUp(function()
            self:_RefreshButtonState()
        end)
    end, true):InitToggleActive(false)

    XMVCA.XBigWorldUI:OpenConfirmPopup(confirmData)
end

function XUiSkyGardenSGDroneMain:OnBtnStoreClick()
    self._Control:OpenShopUi()
end

function XUiSkyGardenSGDroneMain:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnBack:AddEventListener(Handler(self, self.Close))
    self.BtnConfirm:AddEventListener(Handler(self, self.OnBtnConfirmClick))
    self.BtnCancel:AddEventListener(Handler(self, self.OnBtnCancelClick))
    self.BtnStore:AddEventListener(Handler(self, self.OnBtnStoreClick))
    self.BtnContinue:AddEventListener(Handler(self, self.OnBtnContinueClick))
end

function XUiSkyGardenSGDroneMain:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneMain:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneMain:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneMain:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneMain:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDroneMain:_InitUi()
    self.RewardGrid.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnStore:ShowReddot(false)
end

function XUiSkyGardenSGDroneMain:_RefreshProgress()
    self.TxtDifficultNum.text = self._Control:GetChapterStarProgressText(XMVCA.XSkyGardenDroneGame.ChapterType.Hard)
    self.TxtNormalNum.text = self._Control:GetChapterStarProgressText(XMVCA.XSkyGardenDroneGame.ChapterType.Normal)
end

function XUiSkyGardenSGDroneMain:_RefreshButtonState()
    if self._Control:CheckHaveArchive() then
        local storageStageData = self._Control:GetStorageStageData()
        local stageId = storageStageData.CurStageId

        self.BtnCancel.gameObject:SetActiveEx(true)
        self.BtnContinue.gameObject:SetActiveEx(true)
        self.BtnConfirm.gameObject:SetActiveEx(false)

        self.BtnContinue:SetNameByGroup(1, self._Control:GetCurrentStagaTips(stageId))
    else
        self.BtnCancel.gameObject:SetActiveEx(false)
        self.BtnContinue.gameObject:SetActiveEx(false)
        self.BtnConfirm.gameObject:SetActiveEx(true)
    end
end

function XUiSkyGardenSGDroneMain:_RefreshShopRewards()
    local goodId = self._Control:GetShopRewardGoodId()

    if XTool.IsNumberValid(goodId) then
        local rewardGoods = XMVCA.XBigWorldGamePlay:GetBigWorldGoodsByGroupId(goodId)

        if not XTool.IsTableEmpty(rewardGoods) then
            local index = 1

            self.ScrollRect.gameObject:SetActiveEx(true)
            for _, rewardGood in pairs(rewardGoods) do
                local grid = self._RewardGrids[index]

                if not grid then
                    local gridUi = XUiHelper.Instantiate(self.RewardGrid, self.ListPreviewReward)

                    grid = XUiGridBWItem.New(gridUi, self)
                    self._RewardGrids[index] = grid
                end

                grid:Open()
                grid:Refresh(rewardGood)

                index = index + 1
            end

            for i = index, #self._RewardGrids do
                self._RewardGrids[i]:Close()
            end

            return
        end
    end

    for _, grid in pairs(self._RewardGrids) do
        grid:Close()
    end

    self.ScrollRect.gameObject:SetActiveEx(false)
end

return XUiSkyGardenSGDroneMain
