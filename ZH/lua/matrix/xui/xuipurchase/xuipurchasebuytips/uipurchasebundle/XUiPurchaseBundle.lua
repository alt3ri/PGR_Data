local XUiPanelPurchaseItemListBase = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelPurchaseItemListBase')
local XUiPurchaseBundleGrid = require("XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseBundle/XUiPurchaseBundleGrid")

---@class XUiPurchaseBundle : XUiPanelPurchaseItemListBase
---@field Parent XUiPurchaseBuyTips
---@field _Control
local XUiPurchaseBundle = XClass(XUiPanelPurchaseItemListBase, "XUiPurchaseBundle")

function XUiPurchaseBundle:OnStart()
    self._GridMain = XUiPurchaseBundleGrid.New(self.BtnBigGift, self)
    ---@type XUiPurchaseBundleGrid[]
    self._Grids = {}
    self.BtnGift.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnClickHelp)
    -- 特殊处理，外部UI通过checkFunc字段传递的CallBack
    self.CallBack = self.Parent.CheckBuyFun
    self.Parent.CheckBuyFun = handler(self, self.CheckBuy)
    self.Parent.BeforeBuyReqFun = handler(self, self.BeforeBuyFunc)
end

function XUiPurchaseBundle:OnClickHelp()
    XLuaUiManager.Open("UiFubenDialog", XUiHelper.GetText("PurchaseComboTitle"), XUiHelper.GetText("PurchaseComboContent"))
end

---@param data XPurchaseComboData|XUiPurchaseComboSubGridData
function XUiPurchaseBundle:InitGoodsShow(data)
    self._Data = data
    self.TxtName.text = data.Name
    self.TxtSection.text = XUiHelper.GetText('PurchaseBuyTimesProgress', data.BuyTimes, data.BuyLimitTimes)

    -- 因为折扣标签只有一个且在捆绑包选项上，这里折扣显示统一以捆绑包数据为准
    local mainData = XTool.IsTableEmpty(data.MainComboData) and data or data.MainComboData
    
    if mainData.Discount then
        self.Tag.gameObject:SetActiveEx(true)
        self.TxtDiscount.text = XUiHelper.GetDiscountTextV2(data.Discount)
    else
        self.Tag.gameObject:SetActiveEx(false)
    end
    self:SetDataSelected(data)
    if data.MainComboData then
        self._GridMain:Update(data.MainComboData)
        XTool.UpdateDynamicItem(self._Grids, data.MainComboData.SubDatas, self.BtnGift, XUiPurchaseBundleGrid, self)
    else
        self._GridMain:Update(data)
        XTool.UpdateDynamicItem(self._Grids, data.SubDatas, self.BtnGift, XUiPurchaseBundleGrid, self)
    end
    self:UpdateTime()
end

---@param data XPurchaseComboData|XUiPurchaseComboSubGridData
function XUiPurchaseBundle:SetDataSelected(data)
    local subDatas
    if data.MainComboData then
        data.MainComboData.IsSelected = false
        subDatas = data.MainComboData.SubDatas
    else
        subDatas = data.SubDatas
    end
    if subDatas then
        for i = 1, #subDatas do
            subDatas[i].IsSelected = false
        end
    end
    data.IsSelected = true
end

function XUiPurchaseBundle:_SetMainDataSelected()
    if self._Data.MainComboData then
        self._GridMain:OnClick()
    end
end

function XUiPurchaseBundle:OnEnable()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, XScheduleManager.SECOND)
    end

    XEventManager.AddEventListener(XEventId.EVENT_PURCHASE_SELECT_COMBO_MAIN, self._SetMainDataSelected, self)
end

function XUiPurchaseBundle:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end

    XEventManager.RemoveEventListener(XEventId.EVENT_PURCHASE_SELECT_COMBO_MAIN, self._SetMainDataSelected, self)
end

function XUiPurchaseBundle:UpdateTime()
    --有失效时间只显示失效时间。
    -- 失效时间
    if self._Data.Price and self._Data.TimeToInvalid > 0 then
        local remainTime = self._Data.TimeToInvalid - XTime.GetServerNowTimestamp()
        if remainTime > 0 then
            self.ImgTime.gameObject:SetActive(true)
            if self._Data.Discount then
                self.TXtTime.text = XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.PURCHASELB))
            else
                self.TXtTime.text = XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.PURCHASELB))
            end
        else
            self.ImgTime.gameObject:SetActive(false)
            self.TXtTime.text = TextManager.GetText("PurchaseLBSettOff")
            XScheduleManager.UnSchedule(self._Timer)
            self._Timer = false
        end
    end
end


function XUiPurchaseBundle:CheckBuy(count, disCountCouponIndex)
    count = count or 1
    disCountCouponIndex = disCountCouponIndex or 0

    if self._Data.BuyLimitTimes > 0 and self._Data.BuyTimes == self._Data.BuyLimitTimes then --卖完了，不管。
        XUiManager.TipText("PurchaseLiSellOut")
        return 0
    end

    if self._Data.TimeToShelve > 0 and self._Data.TimeToShelve > XTime.GetServerNowTimestamp() then --没有上架
        XUiManager.TipText("PurchaseBuyNotSet")
        return 0
    end

    if self._Data.TimeToUnShelve > 0 and self._Data.TimeToUnShelve < XTime.GetServerNowTimestamp() then --下架了
        XUiManager.TipText("PurchaseSettOff")
        return 0
    end

    if self._Data.TimeToInvalid > 0 and self._Data.TimeToInvalid < XTime.GetServerNowTimestamp() then --失效了
        XUiManager.TipText("PurchaseSettOff")
        return 0
    end

    local consumeCount = self._Data.Price
    if disCountCouponIndex and disCountCouponIndex ~= 0 then
        local disCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(self._Data, disCountCouponIndex)
        consumeCount = math.floor(disCountValue * consumeCount)
    else
        if XPurchaseConfigs.GetTagType(self._Data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then -- 计算打折后的钱(普通打折或者选择了打折券)
            local disCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self._Data)
            consumeCount = math.floor(disCountValue * consumeCount)
        end
    end

    consumeCount = count * consumeCount -- 全部数量的总价
    if consumeCount > 0 and consumeCount > XDataCenter.ItemManager.GetCount(self._Data.ConsumeId) then --钱不够
        local tips = XUiHelper.GetCountNotEnoughTips(self._Data.ConsumeId)
        local payCount = consumeCount - XDataCenter.ItemManager.GetCount(self._Data.ConsumeId)
        XUiManager.TipMsg(tips,XUiManager.UiTipType.Wrong)
        if self._Data.ConsumeId == XDataCenter.ItemManager.ItemId.PaidGem then
            self.CallBack(XPurchaseConfigs.TabsConfig.HK)
        elseif self._Data.ConsumeId == XDataCenter.ItemManager.ItemId.HongKa then
            self.CallBack(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
            return 3
        end
        return 0
    end

    return 1
end

function XUiPurchaseBundle:BeforeBuyFunc(realBuyFunc)
    if self._Data.MainComboData then
        -- 是子包
        -- 提示引导玩家可以购买捆绑包

        -- 新增判断，如果父捆绑包没有折扣，则不引导买捆绑包
        if self._Data.MainComboData.Price == self._Data.MainComboData.OriginalPrice then
            realBuyFunc()
        else
             XLuaUiManager.Open('UiPurchaseDialog', function()
                realBuyFunc()
            end, function()
                XEventManager.DispatchEvent(XEventId.EVENT_PURCHASE_SELECT_COMBO_MAIN)
            end)
        end
    else
        -- 是捆绑包
        -- 替代作为实际购买的逻辑
        local updateCb = self.Parent.UpdateCb
        
        XDataCenter.PurchaseManager.PurchaseComboRequest(self._Data.Id, function()
            if updateCb then
                updateCb()
            end
        end)

        XLuaUiManager.Close('UiPurchaseBuyTips')
    end
end

return XUiPurchaseBundle