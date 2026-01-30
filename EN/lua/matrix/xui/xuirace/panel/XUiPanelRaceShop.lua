local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")

---@class XUiPanelRaceShop : XUiNode
---@field Parent XUiRaceMissionShop
---@field _Control XRaceControl
local XUiPanelRaceShop = XClass(XUiNode, "XUiPanelRaceShop")

local MaskKey = "XUiRaceShopPanel"

function XUiPanelRaceShop:OnStart()
    self:InitDynamicTable()
    self.GridShop.gameObject:SetActiveEx(false)

    local shopColors = self._Control:GetClientConfigs("ShopColor")
    self.UiParams = {
        CanBuyColor = shopColors[1],
        CanNotBuyColor = shopColors[2],
    }
end

function XUiPanelRaceShop:OnDisable()
    if XLuaUiManager.IsMaskShow(MaskKey) then
        XLuaUiManager.SetMask(false, MaskKey)
    end
end

function XUiPanelRaceShop:InitDynamicTable()
    self.DynamicShopTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicShopTable:SetProxy(XUiGridShop)
    self.DynamicShopTable:SetDelegate(self)
end

function XUiPanelRaceShop:UpdateShopShow(shopId, isAnim)
    self._IsAnim = isAnim
    self.ShopItemList = XTool.IsNumberValid(shopId) and XShopManager.GetShopGoodsList(shopId) or {}

    self.DynamicShopTable:SetDataSource(self.ShopItemList)
    self.DynamicShopTable:ReloadDataSync(1)
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.ShopItemList))
end

---@param grid XUiGridShop
function XUiPanelRaceShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopItemList[index]
        if data then
            grid:UpdateData(data, self.UiParams)
            grid:RefreshShowLock()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if not self._IsAnim then
            return
        end
        local grids = self.DynamicShopTable:GetGrids()
        local gridCount = XTool.GetTableCount(grids)
        if XTool.IsTableEmpty(grids) or #grids <= 0 then
            --非完整完成不播动画
            return
        end
        for i, grid in ipairs(grids) do
            grid.GameObject:SetActiveEx(false)
        end
        local index = 0
        XLuaUiManager.SetMask(true, MaskKey)
        for i, grid in ipairs(grids) do
            XScheduleManager.ScheduleOnce(function()
                if not XTool.UObjIsNil(grid.GameObject) then
                    grid.GameObject:SetActiveEx(true)
                    local animTrans = XUiHelper.TryGetComponent(grid.Transform, "Animation/GridShopAnimEnable", nil)
                    if animTrans then
                        animTrans:PlayTimelineAnimation()
                    end
                    index = index + 1
                    if index >= gridCount then
                        XLuaUiManager.SetMask(false, MaskKey)
                    end
                end
            end, 50 * i)
        end
    end
end

return XUiPanelRaceShop
