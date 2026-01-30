---@class XUiSkyGardenShoppingStreetPopupRoundEnd : XLuaUi
---@field GridFeedback UnityEngine.RectTransform
---@field PanelAsset UnityEngine.RectTransform
---@field BtnClose XUiComponent.XUiButton
---@field BtnYes XUiComponent.XUiButton
---@field ListAsset UnityEngine.RectTransform
---@field ListBuild UnityEngine.RectTransform
---@field GridInsideBuild UnityEngine.RectTransform
---@field GridOutsideBuild UnityEngine.RectTransform
---@field TxtEventNum UnityEngine.UI.Text
---@field TxtConflictNum UnityEngine.UI.Text
---@field PanelDetail UnityEngine.RectTransform
---@field ListDetail UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetPopupRoundEnd = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetPopupRoundEnd")

local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetPopupRoundEndGridShop = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetPopupRoundEndGridShop")
local XUiSkyGardenShoppingStreetInsideBuildGridFeedback = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetInsideBuildGridFeedback")
local XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList")

--region 生命周期
function XUiSkyGardenShoppingStreetPopupRoundEnd:OnStart()
    self:_RegisterButtonClicks()

    self._baseSize = self.ImgBarNow.transform.sizeDelta
    self._stageResType = XMVCA.XSkyGardenShoppingStreet.StageResType
    -- self:Switch2Detail(self._IsDetail)

    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelAsset, self)

    local settleData = self._Control:GetSettleResultData()
    local insidesList = {}
    local outsidesList = {}
    local allAreaShops = self._Control:GetAllShopAreas()
    for i = 1, #allAreaShops do
        local shopArea = allAreaShops[i]
        if shopArea:HasShop() then
            local isInside = shopArea:IsInside()
            if isInside then
                table.insert(insidesList, shopArea)
            else
                table.insert(outsidesList, shopArea)
            end
        end
    end

    self._InsidesList = {}
    self._OutsidesList = {}
    XTool.UpdateDynamicItem(self._InsidesList, insidesList, self.GridInsideBuild, XUiSkyGardenShoppingStreetPopupRoundEndGridShop, self)
    XTool.UpdateDynamicItem(self._OutsidesList, outsidesList, self.GridOutsideBuild, XUiSkyGardenShoppingStreetPopupRoundEndGridShop, self)

    local count = 2
    for i = 1, #self._InsidesList do
        count = count + 1
        self._InsidesList[i]:PlayEnableAnimation(count)
    end
    for i = 1, #self._OutsidesList do
        count = count + 1
        self._OutsidesList[i]:PlayEnableAnimation(count)
    end

    if self.GridFeedback then
        self._SuggestionsUiA = {}
        local reviewIds = {}
        for i = 1, #settleData.Reviews do
            local reviewId = settleData.Reviews[i]
            table.insert(reviewIds, reviewId)
        end
        XTool.UpdateDynamicItemByUiCache(self._SuggestionsUiA, reviewIds, self.GridFeedback.transform.parent, XUiSkyGardenShoppingStreetInsideBuildGridFeedback, self)
    end

    if settleData.EventSettles then
        local eventMap = {}
        for _, StreetStageOperatingEventSettle in pairs(settleData.EventSettles) do
            eventMap[StreetStageOperatingEventSettle.EventType] = StreetStageOperatingEventSettle
        end
        local XSgStreetCustomerEventType = XMVCA.XSkyGardenShoppingStreet.XSgStreetCustomerEventType
        local eventData = eventMap[XSgStreetCustomerEventType.Discontent]
        if eventData then
            self.TxtEventNum.text = string.format("%s/%s", eventData.HandledCount, eventData.TotalCount)
        else
            self.TxtEventNum.text = "-/-"
        end

        eventData = eventMap[XSgStreetCustomerEventType.Emergency]
        if eventData then
            self.TxtConflictNum.text = string.format("%s/%s", eventData.HandledCount, eventData.TotalCount)
        else
            self.TxtConflictNum.text = "-/-"
        end
    else
        self.TxtEventNum.text = "-/-"
        self.TxtConflictNum.text = "-/-"
    end

    local settleData = self._Control:GetSettleResultData()
    local curTotal = settleData.CurrentSettleStatisticData
    local lastTotal = settleData.LastSettleStatisticData or {}
    local lastSatisfactionNum = lastTotal.Satisfaction or 0
    local curSatisfactionNum = curTotal.Satisfaction or 0
    local totalGap = curSatisfactionNum - lastSatisfactionNum

    local accumulativeGold = self._Control:GetAccumulativeGold()
    self.TxtIncomeNum1.text = settleData.AwardGold > 0 and "+" .. settleData.AwardGold or settleData.AwardGold
    self.TxtIncomeNum2.text = accumulativeGold
    local gapStr = totalGap .. "%"
    self.TxtFavorability1.text = totalGap > 0 and "+" .. gapStr or gapStr
    self.TxtFavorability2.text = curSatisfactionNum .. "%"

    -- self.ImgBarNow.fillAmount = lastSatisfactionNum / 100
    -- self.ImgBarAdd.fillAmount = curSatisfactionNum / 100
    -- self.ImgBarMinus.fillAmount = curSatisfactionNum / 100

    self.ImgBarNow.transform.sizeDelta = CS.UnityEngine.Vector2(lastSatisfactionNum / 100 * self._baseSize.x, self._baseSize.y)
    local modifySize = CS.UnityEngine.Vector2(curSatisfactionNum / 100 * self._baseSize.x, self._baseSize.y)
    self.ImgBarAdd.transform.sizeDelta = modifySize
    self.ImgBarMinus.transform.sizeDelta = modifySize

    self.ImgBarAdd.gameObject:SetActive(curSatisfactionNum > lastSatisfactionNum)
    self.ImgBarMinus.gameObject:SetActive(curSatisfactionNum < lastSatisfactionNum)
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:Switch2Detail(isDetail)
    if not self._GoldInfos then
        self._DetailUi1 = {}
        self._DetailUi2 = {}
        local settleData = self._Control:GetSettleResultData()
        local curTotal = settleData.CurrentSettleStatisticData
        local lastTotal = settleData.LastSettleStatisticData or {}
        local curOtherSatisfactionNum = curTotal.Satisfaction - curTotal.EnvironmentSatisfaction - curTotal.ShopScoreSatisfaction
        local lastOtherSatisfactionNum = (lastTotal.Satisfaction or 0) - (lastTotal.EnvironmentSatisfaction or 0) - (lastTotal.ShopScoreSatisfaction or 0)
        self._GoldInfos = 
        {
            {
                ResId = self._stageResType.InitGold,
                Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd1"),
                Num = settleData.CommandAwardGold,
            },
            {
                ResId = self._stageResType.InitGold,
                Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd2"),
                Num = settleData.DiscontentAwardGold,
            },
            {
                ResId = self._stageResType.InitGold,
                Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd3"),
                Num = settleData.AwardGold - settleData.CommandAwardGold - settleData.DiscontentAwardGold,
            },
        }
        self._FavorabilityInfos = 
        {
            {
                ResId = self._stageResType.InitFriendly,
                Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd4"),
                Num = curTotal.EnvironmentSatisfaction - (lastTotal.EnvironmentSatisfaction or 0),
            },
            {
                ResId = self._stageResType.InitFriendly,
                Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd5"),
                Num = curTotal.ShopScoreSatisfaction - (lastTotal.ShopScoreSatisfaction or 0),
            },
            {
                ResId = self._stageResType.InitFriendly,
                Text = XMVCA.XBigWorldService:GetText("SG_SS_XUiSkyGardenShoppingStreetPopupRoundEnd6"),
                Num = curOtherSatisfactionNum - lastOtherSatisfactionNum,
            },
        }
        self.TxtPanelIncomeNum.text = settleData.AwardGold
        local lastSatisfactionNum = lastTotal.Satisfaction or 0
        local curSatisfactionNum = curTotal.Satisfaction or 0
        self.TxtPanelFavorabilityNum.text = curSatisfactionNum - lastSatisfactionNum .. "%"
    end

    self.BtnClose.gameObject:SetActive(true)
    self.PanelDetail.gameObject:SetActive(true)
    XTool.UpdateDynamicItem(self._DetailUi1, {self._GoldInfos}, self.ListDetail, XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList, self)
    XTool.UpdateDynamicItem(self._DetailUi2, {self._FavorabilityInfos}, self.ListDetailFavorability, XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList, self)

    XUiManager.MoveToTop(self.PanelDetail.gameObject, self.BtnClose, function ()
        self:PlayAnimation("PanelDetailDisable", function()
            XTool.UpdateDynamicItem(self._DetailUi1, nil, self.ListDetail, XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList, self)
            XTool.UpdateDynamicItem(self._DetailUi2, nil, self.ListDetailFavorability, XUiSkyGardenShoppingStreetBuildPopupRoundEndDetailList, self)

            self.PanelDetail.gameObject:SetActive(false)
            self.BtnClose.gameObject:SetActive(false)
        end)
    end)
    self:PlayAnimation("PanelDetailEnable")
end

--endregion

--region 按钮事件

function XUiSkyGardenShoppingStreetPopupRoundEnd:OnBtnCloseClick()
    self:Close()
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:OnBtnYesClick()
    self:Close()
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:OnBtnDetailClick()
    self:Switch2Detail(not self._IsDetail)
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:OnPanelConflictClick()
    XMVCA.XBigWorldUI:OpenSingleUi("UiSkyGardenShoppingStreetPopupRoundEndEventTips", XMVCA.XBigWorldService:GetText("SG_SS_YesterdayTxtDetail2Tips"), self.PanelConflict.transform.position)
end

function XUiSkyGardenShoppingStreetPopupRoundEnd:OnPanelEventClick()
    XMVCA.XBigWorldUI:OpenSingleUi("UiSkyGardenShoppingStreetPopupRoundEndEventTips", XMVCA.XBigWorldService:GetText("SG_SS_YesterdayTxtDetail1Tips"), self.PanelEvent.transform.position)
end

--endregion

--region 私有方法

function XUiSkyGardenShoppingStreetPopupRoundEnd:_RegisterButtonClicks()
    --在此处注册按钮事件
    -- self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnBack:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnYes:AddEventListener(handler(self, self.OnBtnYesClick))
    self.BtnFavorability:AddEventListener(handler(self, self.OnBtnDetailClick))
    self.BtnIncome:AddEventListener(handler(self, self.OnBtnDetailClick))
    self.PanelConflict:AddEventListener(handler(self, self.OnPanelConflictClick))
    self.PanelEvent:AddEventListener(handler(self, self.OnPanelEventClick))
end

--endregion

return XUiSkyGardenShoppingStreetPopupRoundEnd
