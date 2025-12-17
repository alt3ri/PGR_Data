local XUiSkyGardenShoppingStreetInsideBuildFood = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildFood")
local XUiSkyGardenShoppingStreetInsideBuildGoods = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildGoods")
local XUiSkyGardenShoppingStreetInsideBuildDessert = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildDessert")
---@class XUiSkyGardenShoppingStreetInsideBuildStrategy : XUiNode
---@field PanelFood UnityEngine.RectTransform
---@field PanelGoods UnityEngine.RectTransform
---@field PanelDessert UnityEngine.RectTransform
---@field TxtTips UnityEngine.UI.Text
---@field BtnSave XUiComponent.XUiButton
local XUiSkyGardenShoppingStreetInsideBuildStrategy = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildStrategy")

--region 生命周期
function XUiSkyGardenShoppingStreetInsideBuildStrategy:OnStart()
    self:_RegisterButtonClicks()
    ---@type XUiSkyGardenShoppingStreetInsideBuildFood
    self.PanelFoodUi = nil
    ---@type XUiSkyGardenShoppingStreetInsideBuildGoods
    self.PanelGoodsUi = nil
    ---@type XUiSkyGardenShoppingStreetInsideBuildDessert
    self.PanelDessertUi = nil
    self._UisList = {}
end

function XUiSkyGardenShoppingStreetInsideBuildStrategy:OnDisable()
    if self.PanelUi then self.PanelUi:Close() end
end
--endregion

function XUiSkyGardenShoppingStreetInsideBuildStrategy:SetBuilding(pos, isInside)
    self._BuildPos = pos
    self._IsInside = isInside

    if self.PanelUi then self.PanelUi:Close() end
    
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._BuildPos, self._IsInside)
    local buildingConfig = self._Control:GetShopConfigById(shopAreaData:GetShopId(), self._IsInside)
    local shopType = XMVCA.XSkyGardenShoppingStreet.XSgStreetShopFuncType

    self.PanelFood.gameObject:SetActive(buildingConfig.FuncType == shopType.Food)
    self.PanelGoods.gameObject:SetActive(buildingConfig.FuncType == shopType.Grocery)
    self.PanelDessert.gameObject:SetActive(buildingConfig.FuncType == shopType.Dessert)

    if not self._UisList[buildingConfig.FuncType] then
        if buildingConfig.FuncType == shopType.Food then
            self._UisList[buildingConfig.FuncType] = XUiSkyGardenShoppingStreetInsideBuildFood.New(self.PanelFood, self)
        elseif buildingConfig.FuncType == shopType.Grocery then
            self._UisList[buildingConfig.FuncType] = XUiSkyGardenShoppingStreetInsideBuildGoods.New(self.PanelGoods, self)
        elseif buildingConfig.FuncType == shopType.Dessert then
            self._UisList[buildingConfig.FuncType] = XUiSkyGardenShoppingStreetInsideBuildDessert.New(self.PanelDessert, self)
        end
    end

    self.PanelUi = self._UisList[buildingConfig.FuncType]
    self.PanelUi:Open()
    self.PanelUi:SetBuilding(self._BuildPos, self._IsInside)
    self.TxtTips.text = buildingConfig.StrategyDesc
end

function XUiSkyGardenShoppingStreetInsideBuildStrategy:HasSaveTips()
    if not self.PanelUi:IsNodeShow() then return false end
    return self.PanelUi:HasSaveTips()
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuildStrategy:OnBtnSaveClick(isForce)
    if not isForce and not self:HasSaveTips() then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_SaveNotNeedTips"))
        return
    end
    self.PanelUi:OnBtnSaveClick(isForce)
end

function XUiSkyGardenShoppingStreetInsideBuildStrategy:HasResetTips()
    if not self.PanelUi:IsNodeShow() then return true end
    return self.PanelUi:HasResetTips()
end

function XUiSkyGardenShoppingStreetInsideBuildStrategy:OnBtnResetClick()
    if self:HasResetTips() then
        XMVCA.XSkyGardenShoppingStreet:Toast(XMVCA.XBigWorldService:GetText("SG_SS_ShopResetNotChange"))
    else
        XMVCA.XSkyGardenShoppingStreet:ConfirmPanel({
            ["Title"] = XMVCA.XBigWorldService:GetText("CommmonTipsTitle"),
            ["Tips"] = XMVCA.XBigWorldService:GetText("SG_SS_ResetConfirm"),
            ["SureCallback"] = function()
                self.PanelUi:Reset()
                self:OnBtnSaveClick(true)
            end,
        })
    end
end
--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuildStrategy:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnSave:AddEventListener(handler(self, self.OnBtnSaveClick))
    self.BtnReset:AddEventListener(handler(self, self.OnBtnResetClick))
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuildStrategy
