local XUiBWPanelAsset = require("XUi/XUiBigWorld/XCommon/XPanelAsset/XUiBWPanelAsset")
local XUiGridBWShop = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWShop")

---@class XUiSkyGardenSGDroneShop : XUiSkyGardenSGDroneShopPartial
---@field PanelActivityAsset UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButtonExt
---@field BtnHelp XUiComponent.XUiButtonExt
---@field BtnMainUi XUiComponent.XUiButtonExt
---@field GridShopList UnityEngine.RectTransform
---@field GridShop UnityEngine.RectTransform
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDroneShop = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDroneShop")

function XUiSkyGardenSGDroneShop:OnAwake()
    self._ShopId = 0
    ---@type XDynamicTableNormal
    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.GridShopList, XUiGridBWShop)
    ---@type XUiBWPanelAsset
    self._PanelAsset = XUiBWPanelAsset.New(self.PanelActivityAsset, self, self._Control:GetShopItemIds())
    self._PanelAsset:Open()

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneShop:OnStart(shopId)
    self._ShopId = shopId
end

function XUiSkyGardenSGDroneShop:OnEnable()
    self:_Refresh()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneShop:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneShop:OnDestroy()
end

function XUiSkyGardenSGDroneShop:OnRefresh()
    self:_Refresh()
end

---@param grid XUiGridBWShop
function XUiSkyGardenSGDroneShop:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid:SetItemTextColor("f8fffd")
        grid:Refresh(data, self._ShopId)
    end
end

function XUiSkyGardenSGDroneShop:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnBack:AddEventListener(Handler(self, self.Close))
end

function XUiSkyGardenSGDroneShop:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_SHOP_BUY, self.OnRefresh, self)
end

function XUiSkyGardenSGDroneShop:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_SHOP_BUY, self.OnRefresh, self)
end

function XUiSkyGardenSGDroneShop:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneShop:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneShop:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDroneShop:_InitUi()
    self.GridShop.gameObject:SetActiveEx(false)
    self.BtnMainUi.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
end

function XUiSkyGardenSGDroneShop:_Refresh()
    local shopGoods = XMVCA.XBigWorldService:GetShopGoodsList(self._ShopId, false)

    self._DynamicTable:SetDataSource(shopGoods)
    self._DynamicTable:ReloadDataASync(1)
end

return XUiSkyGardenSGDroneShop
