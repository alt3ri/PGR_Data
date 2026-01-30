---@class XUiPurchaseComboSubGrid : XUiNode
---@field _Control
local XUiPurchaseComboSubGrid = XClass(XUiNode, "XUiPurchaseComboSubGrid")

function XUiPurchaseComboSubGrid:OnStart(purchaseLBCb)
    self.CallBack = purchaseLBCb
    self.Button.gameObject:SetActiveEx(true)
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
end

function XUiPurchaseComboSubGrid:SetCallBack(cb)
    self.CallBack = cb
end

function XUiPurchaseComboSubGrid:OnClick()
    if self._Data then
        -- 特殊处理，通过checkFunc字段传递进去，实际上callback不是checkFunc
        if not XTool.IsTableEmpty(self._Data.SubDatas) then
            XLuaUiManager.Open("UiPurchaseBuyTips", self._Data, self.CallBack, function()
                self.Parent:UpdateAllData()
            end)
        else
            XLuaUiManager.Open("UiPurchaseBuyTips", self._Data, self.CallBack, function()
                self.Parent:UpdateAllData()
            end)
        end
    end
end

---@param data XPurchaseComboData|XUiPurchaseComboSubGridData
function XUiPurchaseComboSubGrid:Update(data)
    self._Data = data
    --self.TxtPutawayTime
    --self.ImgIconLb
    --self.PanelLabel

    self.TxtName.text = data.Name

    local iconPath = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
    if iconPath and iconPath.AssetPath then
        self.ImgIconLb:SetRawImage(iconPath.AssetPath, function()
            self.ImgIconLb:SetNativeSize()
        end)
    end


    if data.BuyLimitTimes and data.BuyLimitTimes > 0 then
        self.TxtQuota.text = XUiHelper.GetText("PurchaseLimitBuy", data.BuyTimes, data.BuyLimitTimes)
    else
        self.TxtQuota.text = ''
    end
    
    -- 卖完
    if data.IsSoldOut or (data.BuyLimitTimes and data.BuyLimitTimes > 0 and data.BuyTimes == data.BuyLimitTimes) then
        self.ImgSellout.gameObject:SetActive(true)
        self.TxtSetOut.text = XUiHelper.GetText("PurchaseSettOut")
        self.TxtFree.gameObject:SetActive(false)
        self.TxtHk.gameObject:SetActive(false)
        self.PanelLabel.gameObject:SetActiveEx(false)
        self.TxtHk2.gameObject:SetActiveEx(false)
        self.TxtPrice.gameObject:SetActiveEx(false)
        return
    end

    self.ImgSellout.gameObject:SetActive(false)
    --self.RawConsumeImage
    --self.TxtUnShelveTime
    --self.TxtFree
    --self.TxtTagDes
    --self.RedPoint
    --self.ImgTagBg
    --self.FxGo

    -- 免费
    if data.Price == 0 then
        self.TxtFree.gameObject:SetActiveEx(true)
        self.PanelLabel.gameObject:SetActiveEx(false)
    else
        self.TxtFree.gameObject:SetActiveEx(false)
        -- 折扣
        if data.OriginalPrice and data.Price ~= data.OriginalPrice then
            self.TxtHk.gameObject:SetActiveEx(false)
            self.TxtHk2.gameObject:SetActiveEx(true)
            self.TxtHk2.text = data.Price
            self.TxtPrice.text = data.OriginalPrice
            if data.Discount then
                self.PanelLabel.gameObject:SetActiveEx(true)
                self.TxtTagDes.text = XUiHelper.GetDiscountTextV2(data.Discount)
            else
                self.PanelLabel.gameObject:SetActiveEx(false)
            end
            local path = XDataCenter.ItemManager.GetItemIcon(data.ConsumeId)
            if path then
                self.RawConsumeImage2:SetRawImage(path)
            end
        else
            -- 没折扣
            self.TxtHk.gameObject:SetActiveEx(true)
            self.TxtHk2.gameObject:SetActiveEx(false)
            self.TxtHk.text = data.Price
            self.PanelLabel.gameObject:SetActiveEx(false)
            self.TxtPrice.gameObject:SetActiveEx(false)
            local path = XDataCenter.ItemManager.GetItemIcon(data.ConsumeId)
            if path then
                self.RawConsumeImage:SetRawImage(path)
            end
        end
    end

    --self.RawConsumeImage2
    --self.ImgHave
    --self.TextNotNeed
    --self.ImgTimeBg
    --self.ImgTagIcon
    --self.ImgLock
    --self.TxtLock
    self:UpdateTime()
end

function XUiPurchaseComboSubGrid:OnEnable()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            self:UpdateTime()
        end, XScheduleManager.SECOND)
    end
end

function XUiPurchaseComboSubGrid:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiPurchaseComboSubGrid:UpdateTime()
    --有失效时间只显示失效时间。
    -- 失效时间
    if self._Data.Price and self._Data.TimeToInvalid > 0 then
        local remainTime = self._Data.TimeToInvalid - XTime.GetServerNowTimestamp()
        if remainTime > 0 then
            self.TxtUnShelveTime.gameObject:SetActive(true)
            if self._Data.Discount then
                self.TxtUnShelveTime.text = XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.PURCHASELB))
            else
                self.TxtUnShelveTime.text = XUiHelper.GetText("PurchaseSetOffTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.PURCHASELB))
            end
        else
            self.TxtUnShelveTime.gameObject:SetActive(false)
            self.ImgSellout.gameObject:SetActive(true)
            self.TxtSetOut.text = XUiHelper.GetText("PurchaseLBSettOff")
            XScheduleManager.UnSchedule(self._Timer)
            self._Timer = false
        end
    end
end

return XUiPurchaseComboSubGrid