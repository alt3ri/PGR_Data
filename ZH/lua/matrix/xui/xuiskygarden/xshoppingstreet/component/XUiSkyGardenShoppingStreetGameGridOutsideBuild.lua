---@class XUiSkyGardenShoppingStreetGameGridOutsideBuild : XUiNode
---@field UiSkyGardenShoppingStreetGameGridOutsideBuild XUiComponent.XUiButton
---@field PanelLock UnityEngine.RectTransform
---@field PanelUnLock UnityEngine.RectTransform
---@field PanelRecommend UnityEngine.RectTransform
---@field TxtNameLock UnityEngine.UI.Text
---@field TxtName UnityEngine.UI.Text
---@field TxtNum UnityEngine.UI.Text
---@field ImgUpgrade UnityEngine.UI.Image
---@field ImgRed UnityEngine.UI.Image
local XUiSkyGardenShoppingStreetGameGridOutsideBuild = XClass(XUiNode, "XUiSkyGardenShoppingStreetGameGridOutsideBuild")
local XUiSkyGardenShoppingStreetGameGridConflict = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetGameGridConflict")

--region 生命周期
function XUiSkyGardenShoppingStreetGameGridOutsideBuild:OnStart(pos, isInside)
    self:_RegisterButtonClicks()
    self._EventUi = {}
    self._EventData = {}

    self._ShopAreaPos = pos
    self._IsInside = isInside
    self.RedUpgrade.gameObject:SetActive(false)
    self.ImgUpgrade.gameObject:SetActive(false)

    self:ResetConflictEvent()
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:OnEnable()
    self:RefreshBuilding()
end

--endregion

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:RemoveBubbleCount()
    if not self._EventData then return end
    local count = #self._EventData
    if count ~= 0 then
        XMVCA.XSkyGardenShoppingStreet:ChangeBubbleCount(3, -count)
    end
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:AddBubbleCount()
    if not self._EventData then return end
    local count = #self._EventData
    if count ~= 0 then
        XMVCA.XSkyGardenShoppingStreet:ChangeBubbleCount(3, count)
    end
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:AddConflictEvent(eventData)
    self:RemoveBubbleCount()
    table.insert(self._EventData, eventData)
    XTool.UpdateDynamicItem(self._EventUi, self._EventData, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
    self:AddBubbleCount()
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:ResetConflictEvent()
    self:RemoveBubbleCount()
    self._EventData = {}
    XTool.UpdateDynamicItem(self._EventUi, nil, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)

    self:HideCoinEffect()
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:OnConflictEventClick(i)
    self:RemoveBubbleCount()
    local taskData = self._EventData[i]
    table.remove(self._EventData, i)
    XTool.UpdateDynamicItem(self._EventUi, self._EventData, self.UiSkyGardenShoppingStreetGameGridConflict, XUiSkyGardenShoppingStreetGameGridConflict, self)
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetPopupEvent", taskData)
    self:AddBubbleCount()
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:RefreshBuilding()
    self._ShopArea = self._Control:GetShopAreaByUiPos(self._ShopAreaPos, self._IsInside)
    local isEmpty = self._ShopArea:IsEmpty()
    if isEmpty or not self._ShopArea:IsUnlock() then
        self.Edit.gameObject:SetActive(false)
        self.PanelUnLock.gameObject:SetActive(false)
        self.RedUpgrade.gameObject:SetActive(false)
        self.ImgUpgrade.gameObject:SetActive(false)
        self.ImgRed.gameObject:SetActive(false)
        self.UiSkyGardenShoppingStreetGameGridConflict.gameObject:SetActive(false)
        self.UiSkyGardenShoppingStreetGameGridOutsideBuild.NeedCallBack = false
        return
    end
    self.UiSkyGardenShoppingStreetGameGridOutsideBuild.NeedCallBack = true
    self._IsUnlock = self._ShopArea:IsUnlock()
    local notHasShop = self._ShopArea:GetShopLevel() <= 0
    local showLock = not self._IsUnlock or notHasShop
    self.PanelLock.gameObject:SetActive(showLock)
    self.PanelUnLock.gameObject:SetActive(not showLock)

    local shopId = self._ShopArea:GetShopId()
    local config = self._Control:GetShopConfigById(shopId, self._IsInside)
    if not showLock then
        self.TxtName.text = config.Name
        self.TxtNum.text = self._ShopArea:GetShopLevel()
    else
        self.TxtNameLock.text = config.Name
    end
    self.PanelRecommend.gameObject:SetActive(self._Control:GetRecommendShopId() == shopId)
    
    self.RedUpgrade.gameObject:SetActive(self._IsEditMode and self._ShopArea:CanShowUpgradeTips())

    local canUnlockOutside = self._Control:CanUnlockOutisdeShop()
    self.ImgRed.gameObject:SetActive(self._IsEditMode and canUnlockOutside and notHasShop)
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:SetEditMode(isEditMode)
    self._IsEditMode = isEditMode
    self.Edit.gameObject:SetActive(isEditMode)
    self:RefreshBuilding()
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:HideCoinEffect()
    if self.Effect then
        self.Effect.gameObject:SetActive(false)
    end
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:ShowCoinEffect()
    if self.Effect then
        self.Effect.gameObject:SetActive(true)
    end
end

--region 按钮事件

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:OnUiSkyGardenShoppingStreetGameGridOutsideBuildClick()
    if self._Control:IsRunningGame() then return end
    if not self._IsUnlock then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_BuildingLock"))
        return
    end
    XMVCA.XSkyGardenShoppingStreet:AddOpenBlackMaskLoading(nil, function()
        -- 解锁
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetBuild", self._ShopAreaPos, self._IsInside)
    end)
end

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:OnRedUpgradeClick()
    XMVCA.XSkyGardenShoppingStreet:AddOpenBlackMaskLoading(nil, function()
        -- 升级
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetUpgrade", self._ShopAreaPos, self._IsInside, false)
    end)
end

--endregion

--region 私有方法

function XUiSkyGardenShoppingStreetGameGridOutsideBuild:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.UiSkyGardenShoppingStreetGameGridOutsideBuild:AddEventListener(handler(self, self.OnUiSkyGardenShoppingStreetGameGridOutsideBuildClick))
    self.RedUpgrade:AddEventListener(handler(self, self.OnRedUpgradeClick))
end

--endregion

return XUiSkyGardenShoppingStreetGameGridOutsideBuild
