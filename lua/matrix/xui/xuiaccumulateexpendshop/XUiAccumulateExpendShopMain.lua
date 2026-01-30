---@class XUiAccumulateExpendShopMain : XUiAccumulateExpendShopMainPartial
---@field private _Control  XShopControl
local XUiAccumulateExpendShopMain = XLuaUiManager.Register(XLuaUi, "UiAccumulateExpendShopMain")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridShop = require("XUi/XUiShop/XUiGridShop")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

local CanBuyColor = CS.XGame.ClientConfig:GetString("AccumulateExpendShopCanBuyColor")
local CanNotBuyColor = CS.XGame.ClientConfig:GetString("AccumulateExpendShopCanNotBuyColor")
local ShopItemTextColor = {
    CanBuyColor = CanBuyColor,
    CanNotBuyColor = CanNotBuyColor,
}


function XUiAccumulateExpendShopMain:Ctor(...)
end

function XUiAccumulateExpendShopMain:OnAwake()

end

function XUiAccumulateExpendShopMain:OnStart(...)
    self._Control:EnterAccumulateExpendShop()

    XMVCA.XShop:EnterAccumulateExpendShop()
    self:GetCurActivityConfig()
    self:InitView()
    self:_RegisterButtonClicks()
    self:CheckTimeEnd()
end

function XUiAccumulateExpendShopMain:OnDestroy()
    XScheduleManager.UnSchedule(self.Timer)
end

function XUiAccumulateExpendShopMain:OnGetLuaEvents()
    return {
        XEventId.EVENT_NOTIFY_ACCUMULATE_EXPEND_SHOP_DATA,
    }
end

function XUiAccumulateExpendShopMain:OnNotify(event, ...)
    if event == XEventId.EVENT_NOTIFY_ACCUMULATE_EXPEND_SHOP_DATA then
        self:CheckTimeEnd()
        self:RefreshAccumemlateDataTxt()
    end
end

--region 配置获取
function XUiAccumulateExpendShopMain:GetCurActivityConfig()
    self.ShopDataEntity = self._Control:GetAccumulateExpendShopModel()
    self.ActivityConfig = self.ShopDataEntity:GetActivityConfigs()
    self.ShopId         = self.ActivityConfig.ShopId
    self.IsNextDay      = self.ShopDataEntity:IsSign()
end

--endregion

function XUiAccumulateExpendShopMain:InitView()
    local shopId = self:GetCurShopId()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelItemList)
    self.DynamicTable:SetProxy(XUiGridShop)
    self.DynamicTable:SetDelegate(self)
    self:ShowShop(shopId)

    self:RefreshTime()
    self:RefreshAccumemlateDataTxt()
    self.Timer = XScheduleManager.ScheduleForever(function()
        self:RefreshTime()
    end, 1000)

    local goldIcon = XDataCenter.ItemManager.GetItemIcon(self.ActivityConfig.ShopItemId)
    self.RImgGold:SetRawImage(goldIcon)
    self.RImgGold1:SetRawImage(goldIcon)
    self.TxtNum.text = self.ActivityConfig.ItemExchangeRate
    self.HongkaNum.text = self.ActivityConfig.ItemExchangeRate

    self:HideBubble()
end

function XUiAccumulateExpendShopMain:RefreshAccumemlateDataTxt()
    self.IsNextDay    = self.ShopDataEntity:IsSign()
    local rewardItems = XRewardManager.GetRewardList(self.ShopDataEntity:GetCurDateSignReward())
    if rewardItems then
        self.GridReward = self.GridReward or XUiGridCommon.New(self, self.Grid256New)
        self.GridReward:Refresh(rewardItems[1])
        self.PanelDailyReward.gameObject:SetActiveEx(true)
        self.SignBtn:ShowReddot(true)
    else
        self.PanelDailyReward.gameObject:SetActiveEx(false)
        self.SignBtn:ShowReddot(false)
    end
    -- self.HongkaNum.text = self.ShopDataEntity:GetTotalConsumeCount()
    self.CoinNum.text   = self.ShopDataEntity:GetConvertedCount()
    self.TxtMax.gameObject:SetActiveEx(self.ShopDataEntity:GetConvertedCount() >= self.ActivityConfig.ShopItemMaxCount)
end

function XUiAccumulateExpendShopMain:RefreshTime()
    self.SignBtn.gameObject:SetActiveEx(self.IsNextDay)
    if not self.IsNextDay then
        self.SignTxtTime.text = XUiHelper.GetText("Maverick3DaliyRewardTime", self:GetTomorrowTime())
    else
        self.SignTxtTime.text = ""
    end

    self.TxtTime.text = XUiHelper.GetInTimeDesc(
        XFunctionManager.GetStartTimeByTimeId(self.ActivityConfig.TimeId),
        XFunctionManager.GetEndTimeByTimeId(self.ActivityConfig.TimeId))
    self:CheckTimeEnd()
end

function XUiAccumulateExpendShopMain:_RegisterButtonClicks()
    self._PanelAsset = XUiHelper.NewPanelActivityAssetSafe(
        { XDataCenter.ItemManager.ItemId.HongKa, self.ActivityConfig.ShopItemId },
        self.PanelSpecialTool, self)

    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnMainUi:AddEventListener(handler(self, XLuaUiManager.RunMain))
    self.BtnClose:AddEventListener(handler(self, self.HideBubble))
    self.BtnTips:AddEventListener(handler(self, self.ShowBubble))
    self.BtnHelp:AddEventListener(handler(self, self.ShowHelp))
    self.SignBtn:AddEventListener(function()
        self._Control:AccumulateExpendShopSign()
    end)
end

function XUiAccumulateExpendShopMain:ShowHelp()
    XLuaUiManager.Open("UiAccumulateExpendShopLog")
end

--region 商品展示
function XUiAccumulateExpendShopMain:ShowShop(shopId)
    XShopManager.GetShopInfo(shopId, function()
        self:UpdateInfo(shopId)
    end)
end

function XUiAccumulateExpendShopMain:UpdateInfo(shopId)
    if XTool.UObjIsNil(self.PanelItemList) then
        return
    end
    self.GoodsList = self.ShopDataEntity:SortGoodList(shopId)
    self.DynamicTable:SetDataSource(self.GoodsList)
    self.DynamicTable:ReloadDataASync()
end

--动态列表事件
function XUiAccumulateExpendShopMain:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self, self, self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.GoodsList[index]
        grid:UpdateData(data, ShopItemTextColor, self:GetCurShopId())
        self:RefreshGrid(grid, data)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiAccumulateExpendShopMain:RefreshGrid(grid, data)
    local isOpen = true
    if #data.ConsumeList == 0 then
        grid.PanelPrice1.gameObject:SetActiveEx(true)
        grid.TxtNewPrice1.text = XUiHelper.GetText("PurchaseFreeText")
        local goldIcon = XDataCenter.ItemManager.GetItemIcon(self.ActivityConfig.ShopItemId)
        grid.RImgPrice1:SetRawImage(goldIcon)
    end
    for _, conditionId in pairs(data.ConditionIds) do
        if conditionId and conditionId ~= 0 then
            isOpen = XConditionManager.CheckCondition(conditionId)
            if not isOpen then
                local desc = XConditionManager.GetConditionTemplate(conditionId).Desc
                grid.TxtLock.text = desc
                break
            end
        end
    end

    grid.ImgLock.gameObject:SetActiveEx(not isOpen)
end

function XUiAccumulateExpendShopMain:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, cb, "000000ff")
end

function XUiAccumulateExpendShopMain:RefreshBuy()
    local shopId = self:GetCurShopId()
    self:UpdateInfo(shopId)
end

function XUiAccumulateExpendShopMain:GetCurShopId()
    return self.ShopId
end

--endregion

function XUiAccumulateExpendShopMain:ShowBubble()
    self.PanelBubble.gameObject:SetActiveEx(true)
end

function XUiAccumulateExpendShopMain:HideBubble()
    self.PanelBubble.gameObject:SetActiveEx(false)
end

function XUiAccumulateExpendShopMain:GetTomorrowTime()
    local now = XTime.GetServerNowTimestamp()
    local todayFreshTime = XTime.GetSeverTodayFreshTime()
    local tomorrowFreshTime = XTime.GetSeverTomorrowFreshTime()
    local tempTime = now >= todayFreshTime and tomorrowFreshTime  or todayFreshTime

    self.IsNextDay = self.IsNextDay or tempTime - XTime.GetServerNowTimestamp() <= 0
    local timeStr = XUiHelper.GetTime(tempTime- XTime.GetServerNowTimestamp(),
        XUiHelper.TimeFormatType.ACTIVITY)
    return timeStr
end

function XUiAccumulateExpendShopMain:CheckTimeEnd()
    local configId = self._Control:GetAccumulateExpendShopModel():GetActivityId()
    if configId == 0 then
        XUiManager.TipText("ActivityMainLineEnd")
        XLuaUiManager.RunMain()
        return
    end
    local config = self.ShopDataEntity:GetActivityConfigs()
    if not config or not XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
        XUiManager.TipText("ActivityMainLineEnd")
        XLuaUiManager.RunMain()
        return
    end
end

return XUiAccumulateExpendShopMain
