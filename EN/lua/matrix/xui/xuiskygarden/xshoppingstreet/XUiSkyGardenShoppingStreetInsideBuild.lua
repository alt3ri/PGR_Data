local XUiSkyGardenShoppingStreetAsset = require("XUi/XUiSkyGarden/XShoppingStreet/Component/XUiSkyGardenShoppingStreetAsset")
local XUiSkyGardenShoppingStreetInsideBuildStrategy = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildStrategy")
local XUiSkyGardenShoppingStreetInsideBuildBase = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetInsideBuildBase")
local XUiSkyGardenShoppingStreetInsideBuildGridFeedback = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetInsideBuildGridFeedback")
local XUiSkyGardenShoppingStreetBuildPanelInsideList = require("XUi/XUiSkyGarden/XShoppingStreet/Node/XUiSkyGardenShoppingStreetBuildPanelInsideList")

---@class XUiSkyGardenShoppingStreetInsideBuild : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field PanelTop UnityEngine.RectTransform
---@field PanelStrategy UnityEngine.RectTransform
---@field PanelBase UnityEngine.RectTransform
---@field Select UnityEngine.RectTransform
---@field GridFeedback UnityEngine.RectTransform
local XUiSkyGardenShoppingStreetInsideBuild = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetInsideBuild")

--region 生命周期
function XUiSkyGardenShoppingStreetInsideBuild:OnStart(pos, isInside, isCameraFromBase)
    self:_RegisterButtonClicks()
    self._Pos = pos
    self._IsInside = isInside
    self._Feedback = {}
    self._isCameraFromBase = isCameraFromBase

    local shopAreaData = self._Control:GetShopAreaByUiPos(self._Pos, self._IsInside)
    self._ShopId = shopAreaData:GetShopId()

    ---@type XUiSkyGardenShoppingStreetAsset
    self.PanelTopUi = XUiSkyGardenShoppingStreetAsset.New(self.PanelTop, self)
    ---@type XUiSkyGardenShoppingStreetInsideBuildBase
    self.PanelBaseUi = XUiSkyGardenShoppingStreetInsideBuildBase.New(self.PanelBase, self)
    self.UiPanelInsideList = XUiSkyGardenShoppingStreetBuildPanelInsideList.New(self.PanelInsideList, self, function(shopId)
        local result = self:CheckSaveTipsCallback(function()
            self.SkipSaveCheck = true
            self.UiPanelInsideList:SelectBuilding(shopId)
            self.SkipSaveCheck = false
        end, function()
            self:RefreshBuildingInfo(shopId)
        end)
        return result
    end, true)

    self.GridFeedback.gameObject:SetActive(false)
    -- self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListFeedback.gameObject, XUiSkyGardenShoppingStreetInsideBuildGridFeedback)
end

function XUiSkyGardenShoppingStreetInsideBuild:OnDisable()
    if self._CloseTimerId then
        XScheduleManager.UnSchedule(self._CloseTimerId)
        self._CloseTimerId = nil
    end
    if self.PanelStrategyUi then self.PanelStrategyUi:Close() end
end

function XUiSkyGardenShoppingStreetInsideBuild:OnEnable()
    if self._isFinishInit then
        local shopId = self._Control:GetUiSelectShopId()
        if shopId then
            self.UiPanelInsideList:RefreshInsideShopList(shopId)
            self._Control:SetUiSelectShopId()
        else
            self.UiPanelInsideList:SelectBuilding(self._ShopId)
        end
    else
        self.UiPanelInsideList:RefreshInsideShopList(self._ShopId)
        self._isFinishInit = true
    end
end
--endregion

function XUiSkyGardenShoppingStreetInsideBuild:OnDestroyShop(areaId)
    local cfgDt = tonumber(self._Control:GetGlobalConfigByKey("ShopDestroyDelay")) or 1
    local closeDelay = cfgDt * 1000
    self.BtnBack.gameObject:SetActive(false)
    self.BtnHelp.gameObject:SetActive(false)
    self.PanelFeedback.gameObject:SetActive(false)
    if self.UiPanelInsideList then self.UiPanelInsideList:Close() end
    if self.PanelStrategyUi then self.PanelStrategyUi:Close() end
    if self.PanelBaseUi then self.PanelBaseUi:Close() end
    self._CloseTimerId = XScheduleManager.ScheduleOnce(function ()
        self._Control:X3CBuildingDestroy(areaId)
        self:OnBtnBackClick()
    end, closeDelay)
end

function XUiSkyGardenShoppingStreetInsideBuild:RefreshBuildingInfo(shopId)
    self:PlayAnimation("ShopQieHuan")
    self._ShopId = shopId
    self._Pos = self._Control:GetUiPositionByShopId(shopId, self._IsInside)
    local shopAreaData = self._Control:GetShopAreaByShopId(shopId, self._IsInside)
    self.PanelBaseUi:SetBuilding(self._Pos, self._IsInside)
    self._Control:RemoveFeedbackTips(self._Pos, self._IsInside)
    local config = self._Control:GetShopConfigById(shopId, self._IsInside)
    local pType = config.SortType
    local hasInfo = pType == 1
    self.PanelStrategy.gameObject:SetActive(hasInfo)
    if hasInfo then
        if not self.PanelStrategyUi then
            self.PanelStrategyUi = XUiSkyGardenShoppingStreetInsideBuildStrategy.New(self.PanelStrategy, self)
        end
        self.PanelStrategyUi:Open()
        self.PanelStrategyUi:SetBuilding(self._Pos, self._IsInside)
    end

    self._Infos = shopAreaData:GetFeedbackDatas()
    -- local canShowFeedback = self._Infos and #self._Infos > 0
    -- if not canShowFeedback then
    --     self._Infos = {XMVCA.XBigWorldService:GetText("SG_SS_NoFeedback")}
    -- end
    
    self.PanelFeedback.gameObject:SetActive(true)
    XTool.UpdateDynamicItem(self._Feedback, self._Infos, self.GridFeedback, XUiSkyGardenShoppingStreetInsideBuildGridFeedback, self)
    -- self._DynamicTable:SetDataSource(self._Infos)
    -- self._DynamicTable:ReloadDataSync()

    -- self.ListFeedback.gameObject:SetActive(#self._Infos > 0)
    self.PanelNone.gameObject:SetActive(#self._Infos <= 0)
    self.PanelFeedback.gameObject:SetActive(hasInfo)

    local placeId = self._Control:GetAreaIdByUiPos(self._Pos, self._IsInside)
    self._Control:X3CSetVirtualCamera(placeId, XMVCA.XSkyGardenShoppingStreet.X3CCameraPosIndex.Left, shopAreaData:GetShopResId(), nil, self._isCameraFromBase)
    self._isCameraFromBase = nil
end

function XUiSkyGardenShoppingStreetInsideBuild:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self._Infos[index], index)
    end
end

function XUiSkyGardenShoppingStreetInsideBuild:CheckSaveTipsCallback(confirmCb, normalCb)
    if not self.SkipSaveCheck and self:HasSaveTips() then
        XMVCA.XSkyGardenShoppingStreet:ConfirmPanel({
            ["Title"] = XMVCA.XBigWorldService:GetText("CommmonTipsTitle"),
            ["Tips"] = XMVCA.XBigWorldService:GetText("SG_SS_SaveTipsConfirm"),
            ["SureCallback"] = function()
                self:UpdateBuildingInfo()
                if confirmCb then confirmCb() end
            end,
        })
        return false
    else
        if normalCb then normalCb() end
    end
    return true
end

function XUiSkyGardenShoppingStreetInsideBuild:UpdateBuildingInfo()
    if not self.PanelStrategyUi then return end
    self.PanelStrategyUi:SetBuilding(self._Pos, self._IsInside)
end

function XUiSkyGardenShoppingStreetInsideBuild:HasSaveTips()
    if not self.PanelStrategyUi then return false end
    return self.PanelStrategyUi:HasSaveTips()
end

function XUiSkyGardenShoppingStreetInsideBuild:SaveInfo()
    if not self.PanelStrategyUi then return end
    self.PanelStrategyUi:OnBtnSaveClick()
end

--region 按钮事件
function XUiSkyGardenShoppingStreetInsideBuild:OnBtnBackClick()
    local closeFunc = function()
        XMVCA.XSkyGardenShoppingStreet:AddOpenBlackMaskLoading(nil, function()
            self:Close()
        end)
    end
    self:CheckSaveTipsCallback(closeFunc, closeFunc)
end

function XUiSkyGardenShoppingStreetInsideBuild:GetShopId()
    local shopAreaData = self._Control:GetShopAreaByUiPos(self._Pos, self._IsInside)
    return shopAreaData:GetShopId()
end

function XUiSkyGardenShoppingStreetInsideBuild:OnBtnHelpClick()
    if self._IsInside then
        self._Control:ShowTeachInfoStreetTeachIdInside()
    else
        self._Control:ShowTeachInfoStreetTeachIdOuside()
    end
end

--endregion

--region 私有方法
function XUiSkyGardenShoppingStreetInsideBuild:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
end
--endregion

return XUiSkyGardenShoppingStreetInsideBuild
