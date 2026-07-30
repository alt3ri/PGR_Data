---
---@class XUiPurchaseBuyCoatingTips: XLuaUi
---@field protected _Control
---@field BtnBuy XUiComponent.XUiButton
local XUiPurchaseBuyCoatingTips = XLuaUiManager.Register(XLuaUi, "UiPurchaseBuyCoatingTips")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiGridPurchaseCommon = require("XUi/XUiPurchase/XUiPurchaseBuyCoatingTips/XUiGridPurchaseCommon")

--region Ui生命周期

function XUiPurchaseBuyCoatingTips:OnAwake()
    self.BtnBgClick:AddEventListener(handler(self, self.Close))
    self.BtnBuy:AddEventListener(handler(self, self.OnBtnBuyClick))

end

---@param viewModel CoatingBuyTipsViewModel
function XUiPurchaseBuyCoatingTips:OnStart(viewModel, buyCb, closeDetailCb)
    self._BuyCb = buyCb
    self._CloseDetailCb = closeDetailCb
    self._ViewModel = viewModel

    self.TxtName.text = viewModel.Title or ''
    self.Desc.text = viewModel.SubTitle or ''
    self.WorldDesc.text = viewModel.DetailDesc or ''

    self._IsTimeLimit = viewModel.IsTimeLimit or false
    self._EndTime = viewModel.EndTime
    self._IsSettOff = false

    self.ImgTime.gameObject:SetActiveEx(self._IsTimeLimit)

    if self._IsTimeLimit then
        self:RefreshTime()
    end
    
    -- 刷新奖励显示
    XUiHelper.RefreshCustomizedList(self.GridItem.transform.parent, self.GridItem, viewModel.RewardDataList and #viewModel.RewardDataList or 0, function(index, go)
        ---@type XUiGridPurchaseCommon
        local grid = XUiGridPurchaseCommon.New(self, go)
        local rewardData = viewModel.RewardDataList[index]


        if rewardData.Disable then
            local params = { Disable = true } --屏蔽点击
            grid:Refresh(rewardData, params)
        else
            grid:Refresh(rewardData)
        end
    end)
    
    -- 价格显示
    self:RefreshPriceShow(viewModel)
    
    -- 资源栏
    if not XTool.IsTableEmpty(viewModel.AssetsItemIds) then
        self.PanelAsset.gameObject:SetActiveEx(true)
        self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, table.unpack(viewModel.AssetsItemIds))
    else
        self.PanelAsset.gameObject:SetActiveEx(false)
    end
end

function XUiPurchaseBuyCoatingTips:OnEnable()
    self:RefreshTime()
    self:StartTimer()
    if self._ViewModel then
        self:RefreshPriceShow(self._ViewModel)
    end
end

function XUiPurchaseBuyCoatingTips:OnDisable()
    self:DestroyTimer()
end

function XUiPurchaseBuyCoatingTips:OnDestroy()
    self:DestroyTimer()
    self._BuyCb = nil
    self._CloseDetailCb = nil
    self._ViewModel = nil
end

--endregion

--region 倒计时

function XUiPurchaseBuyCoatingTips:RefreshTime()
    if not self._IsTimeLimit then return end
    if not XTool.IsNumberValidEx(self._EndTime) then
        self.ImgTime.gameObject:SetActiveEx(false)
        return
    end
    local remain = self._EndTime - XTime.GetServerNowTimestamp()
    if remain > 0 then
        self.TxtTime.text = XUiHelper.GetText("PurchaseSetOffTime",
            XUiHelper.GetTime(remain, XUiHelper.TimeFormatType.PURCHASELB))
    else
        self.TxtTime.text = XUiHelper.GetText("PurchaseLBSettOff")
        self:OnSettOff()
    end
end

function XUiPurchaseBuyCoatingTips:OnSettOff()
    self._IsSettOff = true
    self:DestroyTimer()
    --self.BtnBuy:SetButtonState(CS.UiButtonState.Disable)
end

function XUiPurchaseBuyCoatingTips:StartTimer()
    if not self._IsTimeLimit or self._IsSettOff or self._Timer then return end
    self._Timer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then return end
        self:RefreshTime()
    end, 1000)
end

function XUiPurchaseBuyCoatingTips:DestroyTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPurchaseBuyCoatingTips:CheckIsSettOff()
    if not self._IsTimeLimit then return false end
    if self._IsSettOff then return true end
    if not XTool.IsNumberValidEx(self._EndTime) then return false end
    return (self._EndTime - XTime.GetServerNowTimestamp()) <= 0
end

--endregion

---@param viewModel CoatingBuyTipsViewModel
function XUiPurchaseBuyCoatingTips:RefreshPriceShow(viewModel)
    -- 显示原价
    if XTool.IsNumberValidEx(viewModel.OriginCost) and viewModel.OriginCost ~= viewModel.RealCost then
        self.BtnBuy:ActiveTextByGroup(1, true)
        self.BtnBuy:SetNameByGroup(1, viewModel.OriginCost)
    else
        self.BtnBuy:ActiveTextByGroup(1, false)
    end
    
    -- 显示售价
    local costStr = ''

    if XTool.IsNumberValidEx(viewModel.ItemId) then
        -- 如果有传入货币Id，则需要和实际拥有量进行比较，判断是否够钱
        local haveCount = XDataCenter.ItemManager.GetCount(viewModel.ItemId)

        -- 这里和采购弹窗保持一致
        local colorEnough = CS.XGame.ClientConfig:GetString("UiPurchaseBuyTipsButtonColor1")
        local colorUnenough = CS.XGame.ClientConfig:GetString("UiPurchaseBuyTipsButtonColor2")
        
        if haveCount < viewModel.RealCost then
            costStr = string.format("<color=%s>%s</color>", colorUnenough, viewModel.RealCost)
        else
            costStr = string.format("<color=%s>%s</color>", colorEnough, viewModel.RealCost)
        end
    else
        costStr = tostring(viewModel.RealCost)
    end

    self.BtnBuy:SetNameByGroup(0, costStr)
    
    -- 显示图标
    local itemIcon = viewModel.ItemId and XDataCenter.ItemManager.GetItemIcon(viewModel.ItemId) or ''

    if not string.IsNilOrEmpty(itemIcon) then
        self.BtnBuy:SetRawImage(itemIcon)
    end
end

function XUiPurchaseBuyCoatingTips:OnBtnBuyClick()
    if self:CheckIsSettOff() then
        XUiManager.TipMsg(XUiHelper.GetText("PurchaseLBSettOff"))
        self:Close()
        if self._CloseDetailCb then self._CloseDetailCb() end
        return
    end
    local cb = self._BuyCb

    self:Close()

    if cb then
        cb()
    end
end

return XUiPurchaseBuyCoatingTips


---@class CoatingBuyTipsViewModel
---@field Title string @界面顶部标题名称
---@field SubTitle string @界面描述标题
---@field DetailDesc string @详细描述
---@field IsTimeLimit boolean @是否存在时间限制
---@field EndTime number | nil @礼包失效/下架的绝对服务器时间戳（仅采购礼包入口设置，用于每秒实时计算倒计时与下架拦截）
---@field LeftTime number | nil @[已废弃/兼容] 旧的静态剩余时间，现改用 EndTime 实时计算，不再读取
---@field CustomLeftTimeFormat string @自定义的剩余时间显示文本格式
---@field RewardDataList table[] @奖励数据
---@field RealCost number 实际售价
---@field OriginCost number | nil 原价
---@field ItemId number 货币Id
---@field AssetsItemIds number[] | nil 资源栏展示item