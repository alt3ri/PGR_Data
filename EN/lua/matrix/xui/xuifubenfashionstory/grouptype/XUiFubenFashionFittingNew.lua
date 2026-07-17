local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridFashionStoryTrialStage = require("XUi/XUiFubenFashionStory/GroupType/XUiGridFashionStoryTrialStage")
local XUiFubenFashionFittingNew = XLuaUiManager.Register(XLuaUi, "UiFubenFashionFittingNew")

--region 生命周期
function XUiFubenFashionFittingNew:OnAwake()
    self:Init()
    self:InitStagesList()
end

function XUiFubenFashionFittingNew:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local _, endTime = XMVCA.XFashionStory:GetActivityTime(XMVCA.XFashionStory:GetCurrentActivityId())
    self:SetAutoCloseInfo(endTime, function(isClose) self:UpdateLeftTime(isClose) end)
end

function XUiFubenFashionFittingNew:OnEnable()
    self:RefreshStageList()
    self:UpdateLeftTime(XMVCA.XFashionStory:GetLeftTimeStamp(XMVCA.XFashionStory:GetCurrentActivityId()) <= 0)
end
--endregion

--region 初始化
function XUiFubenFashionFittingNew:Init()
    self.BtnBack:AddEventListener(Handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(Handler(self, self.OnBtnMainUiClick))
    self.BtnSkipShop:AddEventListener(Handler(self, self.OnBtnSkipShopClick))
end

function XUiFubenFashionFittingNew:InitStagesList()
    self.StagesList = {}
    for i = 1, 4 do
        local panel = self["GridFitting" .. tostring(i)]
        if panel then
            self.StagesList[i] = XUiGridFashionStoryTrialStage.New(self, panel)
        end
    end
end
--endregion

--region 事件处理
function XUiFubenFashionFittingNew:OnBtnBackClick()
    self:Close()
end

function XUiFubenFashionFittingNew:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 前往商店界面
function XUiFubenFashionFittingNew:OnBtnSkipShopClick()
    XFunctionManager.SkipInterface(XMVCA.XFashionStory:GetFashionStorySkipId(XMVCA.XFashionStory:GetCurrentActivityId(), XMVCA.XFashionStory.FashionStorySkip.SkipToStore))
end
--endregion

--region 数据更新
function XUiFubenFashionFittingNew:RefreshStageList()
    local activityId = XMVCA.XFashionStory:GetCurrentActivityId()
    local stageIds = XMVCA.XFashionStory:GetFashionStoryTrialStages(activityId) or {}

    for i, stageCtrl in ipairs(self.StagesList) do
        local stageId = stageIds[i]
        if stageId then
            stageCtrl:RefreshData(stageId)
        else
            XLog.Error(string.format("[XUiFubenFashionFittingNew] 第 %d 个试玩关槽位未配置 StageId，activityId=%s", i, tostring(activityId)))
        end
    end
end

function XUiFubenFashionFittingNew:UpdateLeftTime(isClose)
    if isClose then
        XUiManager.TipText("FashionStoryActivityEnd")
        XLuaUiManager.RunMain()
    else
        for _, ctrl in ipairs(self.StagesList) do
            ctrl:RefreshLockCountDown()
        end
    end
end
--endregion

return XUiFubenFashionFittingNew
