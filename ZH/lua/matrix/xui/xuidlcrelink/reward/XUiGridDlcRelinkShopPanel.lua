local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
---@class XUiGridDlcRelinkShopPanel : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkShopPanel = XClass(XUiNode, "XUiGridDlcRelinkShopPanel")

function XUiGridDlcRelinkShopPanel:OnStart()
    self.GridShop.gameObject:SetActiveEx(false)
    self:InitDynamicTable()

    self.ShopItemTextColor = {
        CanBuyColor = self._Control:GetClientConfig("ShopItemTextColor", 1),
        CanNotBuyColor = self._Control:GetClientConfig("ShopItemTextColor", 2),
    }
end

function XUiGridDlcRelinkShopPanel:Refresh(shopId)
    self.ShopId = shopId
    self:SetupDynamicTable()
end

function XUiGridDlcRelinkShopPanel:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
end

function XUiGridDlcRelinkShopPanel:SetupDynamicTable()
    self.ShopItemList = XTool.IsNumberValid(self.ShopId) and XShopManager.GetShopGoodsList(self.ShopId) or {}
    local isEmpty = XTool.IsTableEmpty(self.ShopItemList)
    self.ImgEmpty.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        self.DynamicTable:Clear()
        return
    end

    self.DynamicTable:SetDataSource(self.ShopItemList)
    self.DynamicTable:ReloadDataSync(1)
end

---@param grid XUiGridShop
function XUiGridDlcRelinkShopPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.ShopItemList[index]
        if data then
            grid:UpdateData(data, self.ShopItemTextColor)
            grid:RefreshShowLock()
            grid.Grid:SetProxyClickFunc(function()
                XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", data.RewardGoods.TemplateId)
            end)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayGridAnimation()
    end
end

function XUiGridDlcRelinkShopPanel:PlayGridAnimation()
    ---@type XUiGridShop[]
    local grids = self.DynamicTable:GetGrids()
    if XTool.IsTableEmpty(grids) then
        return
    end

    for index, grid in ipairs(grids) do
        grid.GameObject:SetActiveEx(false)
        local delay = (index - 1) * 50
        self:DelayCallRaw(function()
            grid.GameObject:SetActiveEx(true)
            XUiHelper.PlayUiNodeAnimation(grid.Transform, "GridShopEnable", function()
                XLuaUiManager.SetMask(false)
            end, function()
                XLuaUiManager.SetMask(true)
            end)
        end, delay)
    end
end

return XUiGridDlcRelinkShopPanel
