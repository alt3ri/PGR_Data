---@class XUiSkyGardenShoppingStreetGameGridInsideBuild : XUiNode
---@field PanelLock UnityEngine.RectTransform
---@field PanelUnLock UnityEngine.RectTransform
---@field ImgRed UnityEngine.UI.Image
---@field UiSkyGardenShoppingStreetGameGridInsideBuild XUiComponent.XUiButton
---@field ImgAdd UnityEngine.UI.Image
---@field ImgBg UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field ImgUpgrade UnityEngine.UI.Image
local XUiSkyGardenShoppingStreetGameGridInsideBuild = XClass(XUiNode, "XUiSkyGardenShoppingStreetGameGridInsideBuild")
local XUiSkyGardenShoppingStreetGameGridConflict = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetGameGridConflict")

--region 生命周期
function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnStart(pos, isInside)
    self:_RegisterButtonClicks()
    self._EventUi = {}
    self:ResetConflictEvent()

    self._ShopAreaPos = pos
    self._IsInside = isInside
    self._ShopArea = self._Control:GetShopAreaByUiPos(self._ShopAreaPos, self._IsInside)
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnEnable()
    self:RefreshBuilding()
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnGetLuaEvents()
    return {
        XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH,
    }
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnNotify(event, pos, isInside)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_BUILD_REFRESH then
        local position = self._Control:GetAreaIdByUiPos(self._ShopAreaPos, self._IsInside)
        if position == pos then
            self:RefreshBuilding()
        end
    end
end
--endregion

function XUiSkyGardenShoppingStreetGameGridInsideBuild:RefreshBuilding()
    if not self._ShopArea:IsUnlock() then
        self.UiSkyGardenShoppingStreetGameGridInsideBuild.NeedCallBack = false
        self.Edit.gameObject:SetActive(false)
        self.PanelUnLock.gameObject:SetActive(false)
        self.Effect.gameObject:SetActive(false)
        self.UiSkyGardenShoppingStreetGameGridConflict.gameObject:SetActive(false)
        return
    end
    self.UiSkyGardenShoppingStreetGameGridInsideBuild.NeedCallBack = true
    local isUnlock = self._ShopArea:IsUnlock()
    local hasBuilding = not self._ShopArea:IsEmpty()
    self.PanelLock.gameObject:SetActive(not hasBuilding)
    self.PanelUnLock.gameObject:SetActive(isUnlock and hasBuilding)
    self.ImgLock.gameObject:SetActive(not isUnlock)
    self.ImgAdd.gameObject:SetActive(isUnlock)
    if hasBuilding then
        local shopAreaData = self._Control:GetShopAreaByUiPos(self._ShopAreaPos, self._IsInside)
        local config = self._Control:GetShopConfigById(shopAreaData:GetShopId(), self._IsInside)
        self.TxtName.text = config.Name
        self.TxtNum.text = shopAreaData:GetShopLevel()

        local isShowScore = config.SortType == 1
        self.PanelBar.gameObject:SetActive(self._IsEditMode and isShowScore)
        if isShowScore then
            local maxShopScore = tonumber(self._Control:GetGlobalConfigByKey("MaxShopScore"))
            local score = shopAreaData:GetShopScore()
            self.ImgBar.fillAmount = score / maxShopScore
        end

        local hasFeedbacktips = self._Control:HasFeedbackTips(self._ShopAreaPos, self._IsInside)
        self.RedFeedback.gameObject:SetActive(self._IsEditMode and hasFeedbacktips)
        self.RedUpgrade.gameObject:SetActive(self._IsEditMode and shopAreaData:CanShowUpgradeTips())
    end
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:AddConflictEvent(eventData)
    table.insert(self._EventData, eventData)
    XTool.UpdateDynamicItem(self._EventUi, self._EventData, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:ResetConflictEvent()
    self._EventData = {}
    XTool.UpdateDynamicItem(self._EventUi, nil, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)

    self:HideCoinEffect()
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnConflictEventClick(i)
    local taskData = self._EventData[i]
    table.remove(self._EventData, i)
    XTool.UpdateDynamicItem(self._EventUi, self._EventData, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetPopupEvent", taskData)
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:SetEditMode(isEditMode)
    self._IsEditMode = isEditMode
    self.Edit.gameObject:SetActive(isEditMode)
    self:RefreshBuilding()
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:HideCoinEffect()
    if self.Effect then
        self.Effect.gameObject:SetActive(false)
    end
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:ShowCoinEffect()
    if self.Effect then
        self.Effect.gameObject:SetActive(false)
        self.Effect.gameObject:SetActive(true)
    end
end

--region 按钮事件

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnUiSkyGardenShoppingStreetGameGridInsideBuildClick()
    if self._Control:IsRunningGame() then return end
    local isUnlock = self._ShopArea:IsUnlock()
    if not isUnlock then
        -- 提示
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_BuildingLock"))
        return
    end
    local hasBuilding = not self._ShopArea:IsEmpty()
    if hasBuilding then
        XMVCA.XSkyGardenShoppingStreet:AddOpenBlackMaskLoading(nil, function()
            -- 详情
            XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetInsideBuild", self._ShopAreaPos, self._IsInside)
        end)
    else
        local hasShop2Build = false
        local stageId = self._Control:GetCurrentStageId()
        local shoppingConfig = self._Control:GetStageShopConfigsByStageId(stageId)
        for _, shopId in pairs(shoppingConfig.InsideShopGroup) do
            if not self._Control:GetAreaIdByShopId(shopId) then
                hasShop2Build = true
                break
            end
        end
        if not hasShop2Build then
            XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_NotShopToBuildTips"))
            return
        end
        XMVCA.XSkyGardenShoppingStreet:AddOpenBlackMaskLoading(nil, function()
            -- 解锁
            XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetBuild", self._ShopAreaPos, self._IsInside)
        end)
    end
end

function XUiSkyGardenShoppingStreetGameGridInsideBuild:OnRedUpgradeClick()
    XMVCA.XSkyGardenShoppingStreet:AddOpenBlackMaskLoading(nil, function()
        -- 升级
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetUpgrade", self._ShopAreaPos, self._IsInside, false)
    end)
end

--endregion

--region 私有方法

function XUiSkyGardenShoppingStreetGameGridInsideBuild:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.UiSkyGardenShoppingStreetGameGridInsideBuild:AddEventListener(handler(self, self.OnUiSkyGardenShoppingStreetGameGridInsideBuildClick))
    self.RedUpgrade:AddEventListener(handler(self, self.OnRedUpgradeClick))
end

--endregion

return XUiSkyGardenShoppingStreetGameGridInsideBuild
