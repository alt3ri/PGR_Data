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

    self:RefreshRemainDayList(data)
end

-- 资源月卡每月可购买一次，可能有多个过期时间，过滤出有效（>0）的剩余天数
function XUiPurchaseYKListItem:GetValidRemainDayList(data)
    local remainList = {}
    for _, day in ipairs(data:GetResMonthlyCardRemainDayList()) do
        if day > 0 then
            table.insert(remainList, day)
        end
    end
    return remainList
end

-- 帮助界面追加用：拼接剩余时长文本；未购买（<=0）返回空串
function XUiPurchaseYKListItem:BuildRemainDayText(data)
    local remainList = self:GetValidRemainDayList(data)
    if #remainList <= 0 then
        return ""
    end

    local parts = {}
    for i, d in ipairs(remainList) do
        table.insert(parts, XUiHelper.GetText("PurchaseYKRemainDayItem" .. i, d))
    end
    return table.concat(parts, XUiHelper.GetText("PurchaseYKRemainDaySep"))
end

-- 三个文本框按剩余天数列表顺序 1 对 1 赋值，多余的隐藏
function XUiPurchaseYKListItem:RefreshRemainDayList(data)
    -- UI 文本框与文本 key（PurchaseYKRemainDayItem1/2/3）均为固定 3 个，超出需另行扩展
    local txtRemainList = { self.TxtTimeRemain, self.TxtTimeRemain2, self.TxtTimeRemain3 }
    if not self.TxtValid or not txtRemainList[1] then
        return
    end

    local remainList = self:GetValidRemainDayList(data)

    -- 未购买任何一条整行不显示；隐藏文本共用的父对象，避免其底图残留
    local hasAny = #remainList > 0
    self.TxtValid.transform.parent.gameObject:SetActiveEx(hasAny)
    if not hasAny then
        return
    end

    self.TxtValid.text = XUiHelper.GetText("PurchaseYKValidIng")
    for i, txt in ipairs(txtRemainList) do
        local day = remainList[i]
        txt.gameObject:SetActiveEx(day ~= nil)
        if day then
            txt.text = XUiHelper.GetText("PurchaseYKRemainDayItem" .. i, day)
        end
    end
end

function XUiPurchaseYKListItem:OnBtnHelpClicked()
    local helpKey = self.YKUiItemConfig.HelpKey
    -- 血清月卡/武器研发：帮助界面末尾追加当前剩余生效时间（纯文本教程样式）
    local remainText = self:BuildRemainDayText(self.PurchasePackage)
    if not string.IsNilOrEmpty(remainText) then
        local config = XMVCA.XHelpCourse:GetHelpCourseCfgByFunction(helpKey)
        if config and config.IsShowCourse == XEnumConst.HelpCourse.UiHelpType.SimpleContent then
            local describe = config.Describe .. XUiHelper.GetText("PurchaseYKHelpRemainDesc", remainText)
            XUiManager.UiFubenDialogTip(config.Name, describe)
            return
        end
    end
    XUiManager.ShowHelpTip(helpKey)
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

function XUiPurchaseYKList:Ctor(ui, uiRoot, notEnoughCb, customParam)
    XUiHelper.InitUiClass(self, ui)
    self.NotEnoughCb = notEnoughCb
    self.PurchaseManager = XDataCenter.PurchaseManager
    self.UiRoot = uiRoot
    self.CustomParam = customParam
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
        self.YKSwitcher:Open()
        table.insert(placeholders, self.PanelYKItemC)
    else
        self.YKSwitcher:Close()
    end

    if #datas ~= #placeholders then
        XLog.Error("XUiPurchaseYKList:OnRefresh 占位卡片的数量和获得的数据数量对不上号！")
    end

    for i = 1, math.min(#datas, #placeholders) do
        local item = XUiPurchaseYKListItem.New(placeholders[i], self.NotEnoughCb)
        item:SetData(datas[i], handler(self, self.OnRefresh))
    end

    if self.IsEnableDoubleYK() then
        if self.CustomParam == nil then
            local ykData = self.PurchaseManager.GetYKInfoData()
            self.YKSwitcher:Select(ykData and ykData.Id == XPurchaseConfigs.EnYKCID)
        else
            self.YKSwitcher:Select(self.CustomParam.JumpToCardC)
        end
    else
        self.PanelYKItemC.gameObject:SetActiveEx(false)
    end
end

-- 是否启用双月卡判断条件
function XUiPurchaseYKList.IsEnableDoubleYK()
    return XOverseaManager.IsENRegion()
end

function XUiPurchaseYKList:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiPurchaseYKList:HidePanel()
    if self.YKSwitcher then
        self.YKSwitcher:Close()
    end
    self.GameObject:SetActiveEx(false)
end

return XUiPurchaseYKList