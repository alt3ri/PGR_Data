local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetBuildGridAttribute = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuildGridAttribute")
local XUiSkyGardenShoppingStreetUpgradeGridUpgrade = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetUpgradeGridUpgrade")
local XUiSkyGardenShoppingStreetBuildPanelInsideList = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetBuildPanelInsideList")
local XUiSkyGardenShoppingStreetBuildBtnTab = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetBuildBtnTab")

---@class XUiSkyGardenShoppingStreetUpgrade : XLuaUi
---@field PanelTop UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnYes XUiComponent.XUiButton
---@field GridUpgrade UnityEngine.RectTransform
---@field GridAttribute UnityEngine.RectTransform
---@field ImgBg UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
---@field TxtConstNumA UnityEngine.UI.Text
---@field TxtConstNumB UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetUpgrade = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetUpgrade")

--region 生命周期

function XUiSkyGardenShoppingStreetUpgrade:OnAwake()
    self._BuildingAttrs2 = {}
    self._BuildingAttrs = {}
    self._UpgradeInfo = {}
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)
    self:_RegisterButtonClicks()
    self._defaultSize = self.ImgBar.transform.sizeDelta
end

function XUiSkyGardenShoppingStreetUpgrade:OnGetLuaEvents()
    return {
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH,
    }
end

function XUiSkyGardenShoppingStreetUpgrade:OnNotify(event)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH then
        self:_RefreshView()
    end
end

function XUiSkyGardenShoppingStreetUpgrade:OnStart(pos, isInside, needCacheShopId)
    self._Pos = pos
    self._IsInside = isInside
    self._NeedCacheShopId = needCacheShopId

    local shopAreaData = self._Control:GetShopAreaByUiPos(self._Pos, self._IsInside)
    self._ShopId = shopAreaData:GetShopId()

    self.PanelInsideList.gameObject:SetActive(self._IsInside)
    if self.PanelOutsideList then
        self.PanelOutsideList.gameObject:SetActive(not self._IsInside)
    end
    if self._IsInside then
        self.UiPanelInsideList = XUiSkyGardenShoppingStreetBuildPanelInsideList.New(self.PanelInsideList, self, function(shopId)
            if shopId == self._ShopId and self._IsInitInsideShopPage then return false end
            if self._IsInitInsideShopList then
                XMVCA.XSkyGardenShoppingStreet:AddOpenBlackMaskLoading(nil, function()
                    self:_RefreshViewWithShopId(shopId)
                end)
            else
                self:_RefreshViewWithShopId(shopId)
            end
            return true
        end, true)
        self.UiPanelInsideList:RefreshInsideShopList(self._ShopId)
        self._IsInitInsideShopList = true
        self._IsInitInsideShopPage = true
    else
        self:RefreshOutsideShopList()
    end
end

function XUiSkyGardenShoppingStreetUpgrade:RefreshOutsideShopList()
    if not self.BtnTab1 then return end
    if not self._BuildingList then self._BuildingList = {} end
    local outSideBuilding = self._Control:GetShopAreas(self._IsInside)
    if not self._outSideBuildings then
        self._outSideBuildings = {}
        for _, shopAreaData in ipairs(outSideBuilding) do
            if shopAreaData:HasShop() then
                table.insert(self._outSideBuildings, shopAreaData)
            end
        end
    end
    XTool.UpdateDynamicItem(self._BuildingList, self._outSideBuildings, self.BtnTab1, XUiSkyGardenShoppingStreetBuildBtnTab, self)
    self:SelectBuilding(self._ShopId)
end

function XUiSkyGardenShoppingStreetUpgrade:SelectBuilding(shopId)
    -- if self._SelectShopId == shopId then return end
    if self._SelectBtn then
        self._SelectBtn:SetSelect(false)
    end

    self._SelectBtn = nil
    local isFound = false
    if self._IsInside then
        for _, btnList in pairs(self._BuildingList) do
            if isFound then break end
            local btns = btnList:GetBtns()
            for _, btn in pairs(btns) do
                if isFound then break end
                if btn:GetShopId() == shopId then
                    self._SelectBtn = btn
                    isFound = true
                    break
                end
            end
        end
    else
        for _, btn in pairs(self._BuildingList) do
            if isFound then break end
            if btn:GetShopId() == shopId then
                self._SelectBtn = btn
                isFound = true
                break
            end
        end
    end
    if self._SelectBtn then
        self._SelectBtn:SetSelect(true)
    end

    self:_RefreshViewWithShopId(shopId)
end

function XUiSkyGardenShoppingStreetUpgrade:_RefreshViewWithShopId(shopId)
    if self._ShopId ~= shopId then
        self:PlayAnimation("ShopQieHuan")
    end
    self._Pos = self._Control:GetUiPositionByShopId(shopId, self._IsInside)
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._Pos, self._IsInside)
    local shopId = shopAreaData:GetShopId()
    self._ShopId = shopId
    if self._NeedCacheShopId then
        self._Control:SetUiSelectShopId(shopId)
    end
    local shopLevel = shopAreaData:GetShopLevel()
    local upgradeBranch = shopAreaData:GetShopUpgradeBranchIds()
    local shopCfg = self._Control:GetShopConfigById(shopId, self._IsInside)

    self.TxtNum.text = shopLevel
    if self.TxtTitle then
        self.TxtTitle.text = shopCfg.Name
    end

    local placeId = self._Control:GetAreaIdByUiPos(self._Pos, self._IsInside)
    if self._PlaceId ~= placeId then
        self._Control:X3CSetVirtualCamera(placeId, XMVCA.XSkyGardenShoppingStreet.X3CCameraPosIndex.Left, shopAreaData:GetShopResId(), XMVCA.XSkyGardenShoppingStreet.X3CShopVCamIndexType.Upgrade)
        self._PlaceId = placeId
    end

    self._AttrDatas = self._Control:GetShopAttributes(shopId, shopLevel, self._IsInside)
    XTool.UpdateDynamicItem(self._BuildingAttrs, self._AttrDatas, self.GridAttribute, XUiSkyGardenShoppingStreetBuildGridAttribute, self)

    self.TxtMaxNum.text = shopLevel
    if not upgradeBranch or #upgradeBranch <= 0 then
        self.TxtLvNum.text = shopLevel
        self.TxtNow.text = ""
        self.TxtNext.text = ""--XMVCA.XBigWorldService:GetText("SG_SS_BuildLevelMax")
        self.ImgBar.transform.sizeDelta = self._defaultSize
        self.BtnYes2:SetButtonState(CS.UiButtonState.Disable)
        self.PanelMax.gameObject:SetActive(true)
        self.PanelUpgrade.gameObject:SetActive(false)
        local attr2 = self._Control:GetShopAttributes(shopId, shopLevel, self._IsInside)
        XTool.UpdateDynamicItem(self._BuildingAttrs2, attr2, self.GridAttributeMax, XUiSkyGardenShoppingStreetBuildGridAttribute, self)
        return
    end
    self.PanelMax.gameObject:SetActive(false)
    self.PanelUpgrade.gameObject:SetActive(true)

    -- XUiSkyGardenShoppingStreetUpgradeGridUpgrade
    self._UpgradeAttrDatas = self._Control:GetShopAttributes(shopId, shopLevel + 1, self._IsInside, true)
    XTool.UpdateDynamicItem(self._UpgradeInfo, upgradeBranch, self.GridUpgrade, XUiSkyGardenShoppingStreetUpgradeGridUpgrade, self)

    local upgradeConfig = self._Control:GetShopLevelConfigById(shopId, shopLevel + 1, self._IsInside)
    local cost = upgradeConfig.Cost
    local reduceCost = self._Control:ShopUpgradeCostReduceBySubType(shopCfg.SubType, cost)
    local enoughRes = self._Control:EnoughStageResById(reduceCost)
    self.TxtConstNumA.gameObject:SetActive(enoughRes)
    self.TxtConstNumB.gameObject:SetActive(not enoughRes)
    if enoughRes then
        self.TxtConstNumA.text = reduceCost
    else
        self.TxtConstNumB.text = reduceCost
    end
    local showDiscount = reduceCost ~= cost
    self.TxtDiscount.gameObject:SetActive(showDiscount)
    if showDiscount then
        self.TxtDiscount.text = cost
    end
    if not self._IsInside then
        if self.PanelConsume then self.PanelConsume.gameObject:SetActive(false) end
    end

    local buffId = upgradeConfig.BuffId
    if buffId and buffId > 0 then
        local buffConfig = self._Control:GetBuffConfigById(buffId)
        self.TxtScienceDetail2.text = self._Control:ParseBuffDescById(buffId)
        self.RImgScience:SetRawImage(buffConfig.Icon)
        self.PanelScience.gameObject:SetActive(true)
    else
        self.PanelScience.gameObject:SetActive(false)
    end
    
    self.PanelOutsideUnlock.gameObject:SetActive(not self._IsInside)
    if not self._IsInside then
        self.TxtLvNum.text = shopLevel
        local isMaxLv = shopLevel >= self._Control:GetShopMaxLevel(shopId)
        if not isMaxLv then
            local configLv = self._Control:GetShopLevelConfigById(shopId, shopLevel + 1, self._IsInside)
            local maxCustomerNumNeed = configLv.NeedCustomerNum
            local currentNum = shopAreaData:GetRunTotalCustomerNum()
            self.TxtNow.text = XMVCA.XBigWorldService:GetText("SG_SS_UpgradeText1", currentNum)
            self.ImgBar.transform.sizeDelta = CS.UnityEngine.Vector2(self._defaultSize.x * math.min(currentNum / maxCustomerNumNeed, 1), self._defaultSize.y)
            local canUpgrade = currentNum >= maxCustomerNumNeed
            if canUpgrade then
                self.TxtNext.text = XMVCA.XBigWorldService:GetText("SG_SS_BuildBtnCanUpgrade")
            else
                self.TxtNext.text = XMVCA.XBigWorldService:GetText("SG_SS_UpgradeText2", math.max(0, maxCustomerNumNeed - currentNum))
            end
            self._CanUpgrade = canUpgrade
            self.BtnYes:ShowReddot(canUpgrade)
        else
            self._CanUpgrade = true
            self.TxtNext.text = ""--XMVCA.XBigWorldService:GetText("SG_SS_BuildLevelMax")
            self.TxtNow.text = ""
            self.ImgBar.transform.sizeDelta = self._defaultSize
            self.BtnYes:ShowReddot(false)
        end
    else
        self._CanUpgrade = true
        self.BtnYes:ShowReddot(false)
    end
    self:SelectUpgradeInfo()
end

function XUiSkyGardenShoppingStreetUpgrade:_RefreshView()
    if self._IsInside then
        self._IsInitInsideShopList = false
        self._IsInitInsideShopPage = false
        self.UiPanelInsideList:RefreshInsideShopList(self._ShopId)
        self._IsInitInsideShopPage = true
        self._IsInitInsideShopList = true
    else
        self:RefreshOutsideShopList()
    end
end

--endregion

function XUiSkyGardenShoppingStreetUpgrade:GetAttrDatas()
    return self._AttrDatas
end

function XUiSkyGardenShoppingStreetUpgrade:GetUpgradeAttrDatas()
    return self._UpgradeAttrDatas
end

function XUiSkyGardenShoppingStreetUpgrade:SelectUpgradeInfo(index)
    if self._SelectIndex then
        self._UpgradeInfo[self._SelectIndex]:SetSelect(false)
    end
    self._SelectIndex = index
    if self._SelectIndex then
        self._UpgradeInfo[self._SelectIndex]:SetSelect(true)
        self.BtnYes:SetButtonState(self._CanUpgrade and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
        self.BtnYes:SetName(XMVCA.XBigWorldService:GetText("CommmonSure"))
    else
        self.BtnYes:SetButtonState(CS.UiButtonState.Disable)
        self.BtnYes:SetName(XMVCA.XBigWorldService:GetText("SG_SS_Unselect"))
    end
end

function XUiSkyGardenShoppingStreetUpgrade:GetShopAreaData()
    return self._Control:GetShopAreaByUiPos(self._Pos, self._IsInside)
end

--region 按钮事件

function XUiSkyGardenShoppingStreetUpgrade:OnBtnBackClick()
    self:_ClosePanel()
end

function XUiSkyGardenShoppingStreetUpgrade:OnBtnYesClick()
    if not self._SelectIndex then return end
    self._Control:UpgradeShop(self._Pos, self._IsInside, self._SelectIndex, function(cb)
        self:PlayAnimation("PanelOldLvUp", cb)
        self:_RefreshView()
    end)
end

function XUiSkyGardenShoppingStreetUpgrade:OnBtnHelpClick()
    if self._IsInside then
        self._Control:ShowTeachInfoStreetTeachIdInside()
    else
        self._Control:ShowTeachInfoStreetTeachIdOuside()
    end
end

--endregion

--region 私有方法

function XUiSkyGardenShoppingStreetUpgrade:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnYes:AddEventListener(handler(self, self.OnBtnYesClick))
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
    -- self.BtnYes2.CallBack = function (...) self:OnBtnBackClick() end
end

function XUiSkyGardenShoppingStreetUpgrade:_ClosePanel()
    if self._isClosePanel then return end
    self._isClosePanel = true
    
    if self._NeedCacheShopId then
        if self._IsInside then
            XMVCA.XSkyGardenShoppingStreet:AddOpenBlackMaskLoading(nil, function()
                self:Close()
            end)
        else
            self:Close()
        end
    else
        XMVCA.XSkyGardenShoppingStreet:AddOpenBlackMaskLoading(nil, function()
            self:Close()
        end)
    end
end

--endregion

return XUiSkyGardenShoppingStreetUpgrade
