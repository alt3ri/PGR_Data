---@class XUiAreaWarPopupRecord : XLuaUi
---@field private _Control XAreaWarControl
local XUiAreaWarPopupRecord = XLuaUiManager.Register(XLuaUi, "UiAreaWarPopupRecord")

function XUiAreaWarPopupRecord:OnAwake()
    self.PanelTips.gameObject:SetActiveEx(false)
    self:InitTokenIcon()
    self:RegisterUiEvents()
    self:InitDynamicTable()
end

function XUiAreaWarPopupRecord:OnStart()
end

function XUiAreaWarPopupRecord:OnEnable()
    self:Refresh()
end

function XUiAreaWarPopupRecord:OnDisable()
    
end

function XUiAreaWarPopupRecord:OnDestroy()
    self._Control:GetItemRoom():ClearHistoryOrders()
end

function XUiAreaWarPopupRecord:OnGetLuaEvents()
    return {
        XEventId.EVENT_AREA_WAR_ITEM_ROOM_ORDER_CHANGE
    }
end

function XUiAreaWarPopupRecord:OnNotify(evt, ...)
    if evt == XEventId.EVENT_AREA_WAR_ITEM_ROOM_ORDER_CHANGE then
        self:RefreshOrderList()
    end
end

function XUiAreaWarPopupRecord:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnOk, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.PanelTips, self.OnPanelTipsClick)
end

function XUiAreaWarPopupRecord:OnBtnCloseClick()
    self:Close()
end

function XUiAreaWarPopupRecord:OnPanelTipsClick()
    self.PanelTips.gameObject:SetActiveEx(false)
end

function XUiAreaWarPopupRecord:Refresh()
    self:RefreshOrderList()
end

-- 刷新代币图标
function XUiAreaWarPopupRecord:InitTokenIcon()
    -- 刷新代币图标
    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin)
    local uiObj = self.GridDetail:GetComponent(typeof(CS.UiObject))
    uiObj:GetObject("RImgToken"):SetRawImage(icon)
    uiObj:GetObject("RImgIncomeIcon"):SetRawImage(icon)
    -- 收益详情
    self.RImgIconTotalPrice:SetRawImage(icon)
    self.RImgIconHandlingFee:SetRawImage(icon)
    self.RImgIconIncome:SetRawImage(icon)
end

function XUiAreaWarPopupRecord:InitDynamicTable()
    self.GridDetail.gameObject:SetActiveEx(false)
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    local XUiGridAreaWarHistoryOrder = require("XUi/XUiAreaWar/XUiGridAreaWarHistoryOrder")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelOrderList)
    self.DynamicTable:SetProxy(XUiGridAreaWarHistoryOrder, self)
    self.DynamicTable:SetDelegate(self)
end

-- 刷新订单列表
function XUiAreaWarPopupRecord:RefreshOrderList()
    local itemRoom = self._Control:GetItemRoom()
    self.OrderList = XTool.Clone(itemRoom:GetHistoryOrders())
    table.sort(self.OrderList, function(a, b) 
        return a.OrderId > b.OrderId
    end)
    self.DynamicTable:SetDataSource(self.OrderList)
    self.DynamicTable:ReloadDataSync()
end

---@param grid XUiGridAreaWarHistoryOrder
function XUiAreaWarPopupRecord:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local order = self.OrderList[index]
        grid:RefreshOrder(order)
    end
end

-- 显示收入明细
---@param order XAreaWarAuctionOrder
function XUiAreaWarPopupRecord:ShowIncomeDetail(order, pos)
    local SELL_RATE = XAreaWarConfigs.GetAuctionSellRate() -- 出售手续费万分比，配置1000则为10%
    self.PanelTips.gameObject:SetActiveEx(true)
    local allPrice = order.Num * order.Price -- 总价
    local sellCharge = math.floor(SELL_RATE / 10000 * allPrice) -- 出售手续费
    local income = allPrice - sellCharge -- 净收入
    self.TxtTotalPriceNum.text = tostring(allPrice)
    self.TxtHandlingFeeNum.text = tostring(sellCharge)
    self.TxtIncomeNum.text = tostring(income)
    
    self.LinkBtnHelpPos.position = pos
end

return XUiAreaWarPopupRecord
