local XUiSkyGardenShoppingStreetBuildBtnList = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetBuildBtnList")

---@class XUiSkyGardenShoppingStreetBuildPanelInsideList : XUiNode
local XUiSkyGardenShoppingStreetBuildPanelInsideList = XClass(XUiNode, "XUiSkyGardenShoppingStreetBuildPanelInsideList")

function XUiSkyGardenShoppingStreetBuildPanelInsideList:OnStart(cb, isShowGetShopOnly)
    self._BuildingList = {}
    self._selectBuildingIdCb = cb
    self._isShowGetShopOnly = isShowGetShopOnly
end

function XUiSkyGardenShoppingStreetBuildPanelInsideList:RefreshInsideShopList(shopId)
    local stageId = self._Control:GetCurrentStageId()
    local shoppingConfig = self._Control:GetStageShopConfigsByStageId(stageId)
    local parentType = XMVCA.XSkyGardenShoppingStreet.InsideBuildingParentType
    local shopData = {
        [parentType.Consumpt] = { SortType = parentType.Consumpt, ShopConfigs = {} },
        [parentType.Passenger] = { SortType = parentType.Passenger, ShopConfigs = {} },
        [parentType.Environment] = { SortType = parentType.Environment, ShopConfigs = {} },
    }

    local isFound = false
    local defaultId = false
    for _, configId in ipairs(shoppingConfig.InsideShopGroup) do
        local config = self._Control:GetShopConfigById(configId, true)
        local shopId = config.Id
        local pType = config.SortType
        local showData = shopData[pType]
        if showData then
            local hasShopAreaId = self._Control:GetAreaIdByShopId(shopId)
            if self._isShowGetShopOnly then
                if hasShopAreaId then
                    table.insert(showData.ShopConfigs, config)
                    if not defaultId then
                        defaultId = shopId
                    end
                    if not isFound and not hasShopAreaId then
                        defaultId = shopId
                        isFound = true
                    end
                end
            else
                table.insert(showData.ShopConfigs, config)
                if not defaultId then
                    defaultId = shopId
                end
                if not isFound and not hasShopAreaId then
                    defaultId = shopId
                    isFound = true
                end
            end
        end
    end

    XTool.UpdateDynamicItemByUiCache(self._BuildingList, shopData, self.PanelBuild.transform.parent, XUiSkyGardenShoppingStreetBuildBtnList, self)
    self:SelectBuilding(shopId or defaultId)
end

function XUiSkyGardenShoppingStreetBuildPanelInsideList:IsShowBtnUpgrade()
    local func = self.Parent.IsShowBtnUpgrade
    if func then return func(self.Parent) end
    return true
end

function XUiSkyGardenShoppingStreetBuildPanelInsideList:SelectBuilding(shopId)
    local isSwitchFinish = self._selectBuildingIdCb(shopId)
    if not isSwitchFinish then return end

    -- if self._SelectShopId == shopId then return end
    if self._SelectBtn then
        self._SelectBtn:SetSelect(false)
    end

    self._SelectBtn = nil
    local isFound = false
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
    if self._SelectBtn then
        self._SelectBtn:SetSelect(true)
    end
end

return XUiSkyGardenShoppingStreetBuildPanelInsideList
