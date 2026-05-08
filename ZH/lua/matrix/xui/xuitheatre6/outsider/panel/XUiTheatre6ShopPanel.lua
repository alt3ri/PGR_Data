local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
---@class XUiTheatre6ShopPanel: XUiNode
local XUiTheatre6ShopPanel = XLuaUiManager.Register(XUiNode, "XUiTheatre6ShopPanel")
local MaskKey = "XUiTheatre6ShopPanel"

function XUiTheatre6ShopPanel:OnStart()
    self:InitDynamicTable()
    self.GridShop.gameObject:SetActiveEx(false)
    self.UiParams = {
        CanBuyColor = "FFFFFFFF",
        CanNotBuyColor = "E53E3EFF",
    }
end

function XUiTheatre6ShopPanel:OnEnable()

end

function XUiTheatre6ShopPanel:OnDisable()
    if XLuaUiManager.IsMaskShow(MaskKey) then
        XLuaUiManager.SetMask(false, MaskKey)
    end
end

function XUiTheatre6ShopPanel:InitDynamicTable()
    self.DynamicShopTable = XDynamicTableNormal.New(self.Parent.PanelItemList)
    self.DynamicShopTable:SetProxy(XUiGridShop)
    self.DynamicShopTable:SetDelegate(self)
end

function XUiTheatre6ShopPanel:UpdateShopShow(shopId, isAnim)
    self._IsAnim = isAnim
    self.ShopItemList = XTool.IsNumberValid(shopId) and XShopManager.GetShopGoodsList(shopId) or {}

    self.DynamicShopTable:SetDataSource(self.ShopItemList)
    self.DynamicShopTable:ReloadDataSync(1)
    self.ImgEmpty.gameObject:SetActiveEx(XTool.IsTableEmpty(self.ShopItemList))
end

function XUiTheatre6ShopPanel:OnDynamicTableEvent(event, index, grid)
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
            return
        end
        for i, grid in ipairs(grids) do
            grid.GameObject:SetActiveEx(false)
        end
        local cnt = 0
        XLuaUiManager.SetMask(true, MaskKey)
        for i, grid in ipairs(grids) do
            XScheduleManager.ScheduleOnce(function()
                if not XTool.UObjIsNil(grid.GameObject) then
                    grid.GameObject:SetActiveEx(true)
                    local animTrans = XUiHelper.TryGetComponent(grid.Transform, "Animation/GridShopAnimEnable", nil)
                    if animTrans then
                        animTrans:PlayTimelineAnimation()
                    end
                    cnt = cnt + 1
                    if cnt >= gridCount then
                        XLuaUiManager.SetMask(false, MaskKey)
                    end
                end
            end, 100 * i)
        end
    end
end

return XUiTheatre6ShopPanel
