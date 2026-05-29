local XUiPurchaseYKSwitcher = require("XUi/XUiPurchase/XUiPurchaseYKSwitcher")
local XUiPurchaseYKListItem = XClass(nil, "XUiPurchaseYKListItem")

function XUiPurchaseYKListItem:Ctor(ui, notEnoughCb)
    XUiHelper.InitUiClass(self, ui)
    self.PurchaseManager = XDataCenter.PurchaseManager
    self.PurchasePackage = nil
    self.NotEnoughCb = notEnoughCb
    self.FinishedFunc = nil
    self.YKUiItemConfig = nil
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnBtnBuyClicked)
end

---@param data XPurchasePackage
function XUiPurchaseYKListItem:SetData(data, finishedFunc)
    self.PurchasePackage = data
    self.FinishedFunc = finishedFunc
    self.YKUiItemConfig = XPurchaseConfigs.GetPurchasePackageYKUiConfig(data:GetId())
    local remainDay = not XOverseaManager.IsJP_KR_ENRegion() and data:GetDailyRewardRemainDay() or data:GetDailyRewardRemainDay() - 1
    if remainDay < 0 then
        remainDay = 0
    end
    self.TxtTimeTip.text = XUiHelper.GetText("PurchaseYKTimeTip", remainDay)
    self.TxtTimeTip.gameObject:SetActiveEx(XPurchaseConfigs.IsYKID(data:GetId()))
    
    local buyLimitTimes = data:GetBuyLimitTime()
    local curBuyTimes = math.min(buyLimitTimes, data:GetCurrentBuyTime())
    
    self.TxtCountLimit.text = XUiHelper.GetText("PurchaseYKLimitCountTip", curBuyTimes, buyLimitTimes)
    local tips = self.YKUiItemConfig.Tips
    self.TxtTip1.text = tips[1]
    self.TxtTip2.text = string.gsub(tips[2], "\\n", "\n")
    self.RImgIcon:SetRawImage(self.YKUiItemConfig.Icon)
    -- 消耗数量和图标
    self.BtnBuy:SetNameByGroup(0, data:GetConsumeCount())
    self.BtnBuy:SetRawImage(XEntityHelper.GetItemIcon(data:GetConsumeId()))
    self.BtnHelp.gameObject:SetActiveEx(not string.IsNilOrEmpty(self.YKUiItemConfig.HelpKey))
end

function XUiPurchaseYKListItem:OnBtnHelpClicked()
    XUiManager.ShowHelpTip(self.YKUiItemConfig.HelpKey)
end

function XUiPurchaseYKListItem:OnBtnBuyClicked()
    local buyFnishedFunc = function()
        if XPurchaseConfigs.IsYKID(self.PurchasePackage:GetId()) then
            -- 设置月卡信息本地缓存
            XDataCenter.PurchaseManager.SetYKLocalCache()
        end    
        if self.FinishedFunc then
            self.FinishedFunc()
        end
    end
    local notEnoughCb = function(_, payCount)
        if self.NotEnoughCb then
            self.NotEnoughCb(XPurchaseConfigs.TabsConfig.Pay, nil, payCount)
        end
    end
    self.PurchaseManager.OpenPurchaseBuyUiByPurchasePackage(self.PurchasePackage, notEnoughCb, nil, buyFnishedFunc)
end

--######################## XUiPurchaseYKList ########################
local XUiPurchaseYKList = XClass(nil, "XUiPurchaseYKList")

function XUiPurchaseYKList:Ctor(ui, uiRoot, notEnoughCb)
    XUiHelper.InitUiClass(self, ui)
    self.NotEnoughCb = notEnoughCb
    self.PurchaseManager = XDataCenter.PurchaseManager
    self.UiRoot = uiRoot
end

function XUiPurchaseYKList:OnRefresh(uiType)
    self:ShowPanel()

    if not self.YKSwitcher then
        self.YKSwitcher = XUiPurchaseYKSwitcher.New(
            self.PanelPage,
            self.UiRoot,
            self.PanelYKItem,
            self.PanelYKItemC)
    end

    local datas = self.PurchaseManager.GetYKTabPurchasePackages()
    table.sort(datas, function(aData, bData)
        local aWeight = XPurchaseConfigs.GetPurchasePackageYKUiConfig(aData:GetId()).SortWeight
        local bWeight = XPurchaseConfigs.GetPurchasePackageYKUiConfig(bData:GetId()).SortWeight
        return aWeight > bWeight
    end)
    self.PurchaseManager.SetYKContinueBuy()

    -- 月卡列表
    -- 注意：由于这里的UI是特殊布局，月卡的数量必须和占位符数量一致

    local placeholders = { self.PanelYKItem, self.PanelYKItem2, self.PanelYKItem3 }

    if self.IsEnableDoubleYK() then
        self.YKSwitcher.GameObject:SetActive(true)
        table.insert(placeholders, self.PanelYKItemC)
    else
        self.YKSwitcher.GameObject:SetActive(false)
    end

    if #datas ~= #placeholders then
        XLog.Error("XUiPurchaseYKList:OnRefresh 占位卡片的数量和获得的数据数量对不上号！")
    end

    for i = 1, math.min(#datas, #placeholders) do
        local item = XUiPurchaseYKListItem.New(placeholders[i], self.NotEnoughCb)
        item:SetData(datas[i], handler(self, self.OnRefresh))
    end

    self.YKSwitcher:Select(false)
end

-- 是否启用双月卡判断条件
function XUiPurchaseYKList.IsEnableDoubleYK()
    return XOverseaManager.IsENRegion()
end

function XUiPurchaseYKList:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiPurchaseYKList:HidePanel()
    self.GameObject:SetActiveEx(false)
end

return XUiPurchaseYKList