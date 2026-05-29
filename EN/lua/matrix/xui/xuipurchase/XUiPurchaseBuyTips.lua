local XUiPanelDaily = require("XUi/XUiSocial/XUiPanelDaily")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local TextManager = CS.XTextManager
local DropdownOptionData = CS.UnityEngine.UI.Dropdown.OptionData
local XUiPurchaseSignTip = require("XUi/XUiPurchase/XUiPurchaseSignTip/XUiPurchaseSignTip")
local XUiSignWeekCard = require("XUi/XUiSignIn/XUiSignWeekCard")
local XUiBatchPanel = require("XUi/XUiPurchase/XUiBatchPanel")

local XUiPanelNormalPurchaseItemList = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelNormalPurchaseItemList')
local XUiPanelDailyPurchaseItemList = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelDailyPurchaseItemList')
local XUiPanelRandomSelectPurchaseItemList = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelRandomSelectPurchaseItemList')
local XUiPanelChoicePurchaseItemList = require('XUi/XUiPurchase/XUiPurchaseBuyTips/UiPanelPurchaseItemList/XUiPanelChoicePurchaseItemList')
local XUiPurchaseBundle = require("XUi/XUiPurchase/XUiPurchaseBuyTips/UiPurchaseBundle/XUiPurchaseBundle")
local XUiButton = require("XUi/XUiCommon/XUiButton")

local RestTypeConfig
local LBGetTypeConfig
local UpdateTimerTypeEnum = {
    SettOff = 1,
    SettOn = 2
}
local CurrentSchedule = nil
-- v1.28 采购优化-购买CD
local PurchaseBuyPayCD = CS.XGame.ClientConfig:GetInt("PurchaseBuyPayCD") / 1000

---@class XUiPurchaseBuyTips:XLuaUi
local XUiPurchaseBuyTips = XLuaUiManager.Register(XLuaUi, "UiPurchaseBuyTips")

--region 生命周期

function XUiPurchaseBuyTips:OnAwake()
    self:Init()
end

function XUiPurchaseBuyTips:OnStart(data, checkBuyFun, updateCb, beforeBuyReqFun, uiTypeList)
    if not data then
        return
    end

    self.Data = data
    self.CheckBuyFun = checkBuyFun
    self.UpdateCb = updateCb
    self.BeforeBuyReqFun = beforeBuyReqFun
    self.UiTypeList = uiTypeList
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, 1100)

    RestTypeConfig = XPurchaseConfigs.RestTypeConfig
    LBGetTypeConfig = XPurchaseConfigs.LBGetTypeConfig
    self.CurState = false
    self.TimerFun = {} -- 计时器方法表
    self.TitleGoPool = {}
    self.ItemPool = {}
    self.PurchaseSignTipDic = {}    -- 签到礼包的奖励预览脚本实例，key:PrefabPath，value:PurchaseSignTip
    self.OpenBuyTipsList = {}

    -- 检查是否是签到礼包
    if self:CheckSignLBAndOpen(self.Data.SignInId, XUiPurchaseSignTip, false) then
        return
    elseif self.Data.PurchaseSignInInfo then
        local rewardCount = #self.Data.PurchaseSignInInfo.PurchaseSignInRewardInfos
        if rewardCount == 3 then
            -- 3天登录礼包
            local XUiSignThreeDay = require("XUi/XUiSignIn/XUiSignThreeDay")
            if self:CheckSignLBAndOpen(self.Data.PurchaseSignInInfo.PurchaseSignInShowId, XUiSignThreeDay, true) then
                return
            end
        else
            -- 周卡签到礼包（7天）
            if self:CheckSignLBAndOpen(self.Data.PurchaseSignInInfo.PurchaseSignInShowId, XUiSignWeekCard, true) then
                self:StartTimer()
                return
            end
        end
    elseif XTool.IsNumberValid(self.Data.CompanyPackage) and XTool.IsNumberValid(self.Data.CompanyPackageCount) then
        -- 月卡Plus
        local XUiSignMonthPlus = require("XUi/XUiSignIn/XUiSignMonthPlus")
        local customPrefab = CS.XGame.ClientConfig:GetString("MonthCardPlusPrefab")
        local data = XDataCenter.PurchaseManager.GetPurchasePackageById(self.Data.CompanyPackage)
        if self:CheckSignLBAndOpen(nil, XUiSignMonthPlus, false, customPrefab) then
            return
        end
    else
        self.PanelSignGiftPack.gameObject:SetActiveEx(false)
    end

    self.PanelCommon.gameObject:SetActiveEx(true)
    self:AutoRegisterListener()

    self.TxtName.text = data.Name
    local path = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
    if path and path.AssetPath then
        self.RawImageIcon:SetRawImage(path.AssetPath)
    end

    self:InitSelectionData()
    self:RefreshBuyTimesProgress()

    -- 下列方法存在公用变量，注意调用顺序
    self:CheckLBIsUseMail()
    -- self:SetList()
    self:InitAndRegisterTimer()
    self:InitAndCheckNormalDiscount()
    self:CheckLBRewardIsHave()
    self:CheckLBCouponDiscount()
    self:InitAndCheckMultiply()
    self:SetBuyDes()

    self:StartTimer()

    -- 如果是月卡，则在不能购买时强制置灰按钮
    if XPurchaseConfigs.IsYKID(self.Data.Id) then
        local signCardConf = XSignInConfigs.GetSignCardConfigByPurchasePackageId(self.Data.Id)
        if self.Data.BuyLimitRemainDay > signCardConf.CanBuyDay then
            self._BtnBuy:SetButtonState(CS.UiButtonState.Disable)
            self.BtnBuy:SetButtonState(CS.UiButtonState.Disable)
        end
    end

end

function XUiPurchaseBuyTips:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
    -- SetList 放在Enable中跳出充值界面返回显示的时候重新刷新奖励列表
    self:SetList()
end

function XUiPurchaseBuyTips:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PURCHASE_QUICK_BUY_SKIP, self.Close, self)
end

function XUiPurchaseBuyTips:OnDestroy()
    self:DestroyTimer()
    XDataCenter.PurchaseManager.ClearPurchaseSelectionData()

    if XTool.IsTableEmpty(self.PurchaseSignTipDic) then
        return
    end

    for _, v in pairs(self.PurchaseSignTipDic) do
        if v.OnClose then
            v:OnClose()
            CS.UnityEngine.Object.Destroy(v.GameObject)
        elseif v.Close then
            v:Close()
            CS.UnityEngine.Object.Destroy(v.GameObject)
        end
    end
end

--endregion

--region 初始化

function XUiPurchaseBuyTips:Init()
    self.PanelAssetPay.gameObject:SetActiveEx(true)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAssetPay, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa)
    XDataCenter.ItemManager.AddCountUpdateListener({
        XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.HongKa
    }, handler(self, self.RefreshItemCount), self)
    self._PanelNormalItemList = XUiPanelNormalPurchaseItemList.New(self.PanelNormalReward, self)
    self._PanelNormalItemList:Close()

    self._PanelDailyItemList = XUiPanelDailyPurchaseItemList.New(self.PanelPeriodReward, self)
    self._PanelDailyItemList:Close()

    self._PanelChoiceItemList = XUiPanelChoicePurchaseItemList.New(self.PanelChoiceReward, self)
    self._PanelChoiceItemList:Close()

    self._PanelRandomItemList = XUiPanelRandomSelectPurchaseItemList.New(self.PanelRandomReward, self)
    self._PanelRandomItemList:Close()

    self.PanelBundle.gameObject:SetActiveEx(false)
    self._PanelBundle = XUiPurchaseBundle.New(self.PanelBundle, self)
    self._PanelBundle:Close()

    self:SetUiActive(self.BtnLeft, false)
    self:SetUiActive(self.BtnRight, false)
    self:SetUiActive(self.TxtSection, false)

    self.TxtRed.gameObject:SetActiveEx(false)
    ---@type XUiButtonLua
    self._BtnBuy = XUiButton.New(self.BtnBuy)
end

function XUiPurchaseBuyTips:AutoRegisterListener()
    self.BtnBuy.CallBack = function()
        self:OnBtnBuyClick()
    end
    self.BtnBgClick.CallBack = function()
        self:CloseTips()
    end

    self.DrdSort.onValueChanged:RemoveAllListeners()
    self.DrdSort.onValueChanged:AddListener(function(index)
        self:OnCouponDropDownValueChanged(index)
    end)
end

function XUiPurchaseBuyTips:InitSelectionData()
    -- 初始化前先尝试清空之前的缓存（如果有的话）
    XDataCenter.PurchaseManager.ClearPurchaseSelectionData()

    if not XTool.IsTableEmpty(self.Data.SelectDataForClient) then
        XDataCenter.PurchaseManager.InitPurchaseSelectionData()
        self._HasSelfChoice = not XTool.IsTableEmpty(self.Data.SelectDataForClient.SelectGroups)
        self._HasRandomSelection = not XTool.IsTableEmpty(self.Data.SelectDataForClient.RandomGoods)
    end

    --- 初始化福袋、自选礼包的多次购买相关
    if self._HasRandomSelection or self._HasSelfChoice then
        if XTool.IsNumberValid(self.Data.BuyLimitTimes) and self.Data.BuyLimitTimes > 1 then
            self._CurShowBuyTimes = self.Data.BuyTimes == self.Data.BuyLimitTimes and self.Data.BuyTimes or self.Data.BuyTimes + 1

            self:SetUiActive(self.BtnLeft, true)
            self:SetUiActive(self.BtnRight, true)
            self:SetUiActive(self.TxtSection, true)

            if self.BtnLeft then
                self.BtnLeft.CallBack = handler(self, self.OnBtnLeftClick)
            end

            if self.BtnRight then
                self.BtnRight.CallBack = handler(self, self.OnBtnRightClick)
            end

            self:RefreshBuyTimeShowBtnState()
        else
            self._CurShowBuyTimes = 1
        end
    end
end

function XUiPurchaseBuyTips:InitBatchPanel()
    local batchPanelParam = {
        MaxCount = self.MaxBuyCount,
        MinCount = 1,
        BtnAddCallBack = function()
            self:OnBtnAddClick()
        end,
        BtnReduceCallBack = function()
            self:OnBtnReduceClick()
        end,
        BtnAddLongCallBack = function()
            self:BtnAddLongClick()
        end,
        BtnReduceLongCallBack = function()
            self:BtnReduceLongClick()
        end,
        BtnMaxCallBack = function()
            self:OnBtnMaxClick()
        end,
        SelectTextChangeCallBack = function(count)
            self:OnSelectTextChange(count)
        end,
        SelectTextInputEndCallBack = function(count)
            self:OnSelectTextInputEnd(count)
        end,
    }
    self.BatchPanel = XUiBatchPanel.New(self, self.PanelBatch, batchPanelParam)
end

function XUiPurchaseBuyTips:InitAndRegisterTimer(textComponent)
    textComponent = textComponent and textComponent or self.TXtTime
    self.RemainTime = 0
    self.UpdateTimerType = nil
    self.NowTime = XTime.GetServerNowTimestamp()
    if self.Data.TimeToInvalid and self.Data.TimeToInvalid > 0 then
        self.RemainTime = self.Data.TimeToInvalid - self.NowTime
        self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
        if self.RemainTime > 0 then
            --大于0，注册。
            textComponent.gameObject:SetActiveEx(true)

            -- TXTtime组件显示关联它的父节点背景图片
            if textComponent == self.TXtTime then
                textComponent.transform.parent.gameObject:SetActiveEx(true)
            end

            self:RegisterTimerFun(self.Data.Id, function()
                self:UpdateTimerFun(textComponent)
            end)
            textComponent.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
        else
            textComponent.gameObject:SetActiveEx(false)

            -- TXTtime组件显示关联它的父节点背景图片
            if textComponent == self.TXtTime then
                textComponent.transform.parent.gameObject:SetActiveEx(false)
            end

            self:RemoveTimerFun(self.Data.Id)
        end
    else
        if (self.Data.TimeToShelve == nil or self.Data.TimeToShelve == 0) and (self.Data.TimeToUnShelve == nil or self.Data.TimeToUnShelve == 0) then
            textComponent.gameObject:SetActiveEx(false)
            -- TXTtime组件显示关联它的父节点背景图片
            if textComponent == self.TXtTime then
                textComponent.transform.parent.gameObject:SetActiveEx(false)
            end
        else
            textComponent.gameObject:SetActiveEx(true)
            -- TXTtime组件显示关联它的父节点背景图片
            if textComponent == self.TXtTime then
                textComponent.transform.parent.gameObject:SetActiveEx(true)
            end
            if self.Data.TimeToUnShelve > 0 then
                self.RemainTime = self.Data.TimeToUnShelve - self.NowTime
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOff
                textComponent.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
            else
                self.RemainTime = self.Data.TimeToShelve - self.NowTime
                self.UpdateTimerType = UpdateTimerTypeEnum.SettOn
                textComponent.text = TextManager.GetText("PurchaseSetOnTime", XUiHelper.GetTime(self.RemainTime))
            end
            if self.RemainTime > 0 then
                --大于0，注册。
                self:RegisterTimerFun(self.Data.Id, function()
                    self:UpdateTimerFun(textComponent)
                end)
            else
                self:RemoveTimerFun(self.Data.Id)
            end
        end
    end
end

function XUiPurchaseBuyTips:InitAndCheckNormalDiscount()
    self.NormalDisCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.Data)
    self.IsDisCount = XPurchaseConfigs.GetTagType(self.Data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount and self.NormalDisCountValue < 1
    if self.Data.Discount and self.Data.Discount > 0 then
        self.IsDisCount = true
    end

    if self.Data.ConsumeCount == 0 then
        self._BtnBuy:SetActive("PanelTxt/TxtPriceOri", false)
        self.RawImageConsume.gameObject:SetActiveEx(false)
        self._BtnBuy:SetText("PanelTxt/TxtPrice", TextManager.GetText("PurchaseFreeText")) --免费
    else
        self.RawImageConsume.gameObject:SetActiveEx(true)
        if self.IsDisCount then
            -- 打折的
            if self.Data.ConsumeCount then
                self:PayCoinStates(self.Data.ConsumeId,self.Data.ConsumeCount * self.NormalDisCountValue)
                -- self._BtnBuy:SetText("PanelTxt/TxtPrice", self.Data.ConsumeCount * self.NormalDisCountValue)
                self._BtnBuy:SetText("PanelTxt/TxtPriceOri", self.Data.ConsumeCount)
                self._BtnBuy:SetActive("PanelTxt/TxtPriceOri", true)

            elseif self.Data.Price then
                self:PayCoinStates(self.Data.ConsumeId,self.Data.Price)
                -- self._BtnBuy:SetText("PanelTxt/TxtPrice", self.Data.Price)
                if self.Data.OriginalPrice and self.Data.OriginalPrice ~= self.Data.Price then
                    self._BtnBuy:SetText("PanelTxt/TxtPriceOri", self.Data.OriginalPrice)
                    self._BtnBuy:SetActive("PanelTxt/TxtPriceOri", true)
                else
                    self._BtnBuy:SetActive("PanelTxt/TxtPriceOri", false)
                end
            end
        else
            self._BtnBuy:SetActive("PanelTxt/TxtPriceOri", false)
            self:PayCoinStates(self.Data.ConsumeId,self.Data.ConsumeCount or self.Data.Price)
            -- self._BtnBuy:SetText("PanelTxt/TxtPrice", self.Data.ConsumeCount or self.Data.Price)
        end

        local icon = XDataCenter.ItemManager.GetItemIcon(self.Data.ConsumeId)
        if icon then
            self.RawImageConsume:SetRawImage(icon)
        end
    end
end

function XUiPurchaseBuyTips:InitAndCheckMultiply()
    self.CurrentBuyCount = 1 -- 每次打开把购买数量重置为1
    local isSellOut = self.Data.BuyLimitTimes and self.Data.BuyLimitTimes > 0 and self.Data.BuyTimes == self.Data.BuyLimitTimes
    if not isSellOut and self.Data.CanMultiply then
        -- 批量购买开关
        self.MaxBuyCount = XDataCenter.PurchaseManager.GetPurchaseMaxBuyCount(self.Data)
        self:InitBatchPanel()
        self.PanelBatch.gameObject:SetActiveEx(true)
        self:RefreshBtnBuyPrice()
    else
        self.MaxBuyCount = nil
        self.PanelBatch.gameObject:SetActiveEx(false)
    end
end
--endregion

--region 事件回调
function XUiPurchaseBuyTips:OnBtnAddClick()
    self.CurrentBuyCount = self.CurrentBuyCount + 1
    if self.MaxBuyCount and self.CurrentBuyCount > self.MaxBuyCount then
        self.CurrentBuyCount = self.MaxBuyCount
    end
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:OnBtnReduceClick()
    self.CurrentBuyCount = self.CurrentBuyCount - 1
    if self.CurrentBuyCount < 1 then
        self.CurrentBuyCount = 1
    end
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:BtnAddLongClick()
    self:OnBtnAddClick()
end

function XUiPurchaseBuyTips:BtnReduceLongClick()
    self:OnBtnReduceClick()
end

function XUiPurchaseBuyTips:OnBtnMaxClick()
    local consumeCount = self.Data.ConsumeCount
    consumeCount = math.floor(self.NormalDisCountValue * consumeCount)
    local canBuyCount = math.floor(XDataCenter.ItemManager.GetCount(self.Data.ConsumeId) / consumeCount)
    if canBuyCount <= 0 then
        canBuyCount = 1
    end -- 最小可购买数量为1

    if not self.MaxBuyCount then
        if canBuyCount < self.BatchPanel.MaxCount then
            self.CurrentBuyCount = canBuyCount
        else
            self.CurrentBuyCount = self.BatchPanel.MaxCount
        end
    else
        if canBuyCount < self.MaxBuyCount then
            self.CurrentBuyCount = canBuyCount
        else
            self.CurrentBuyCount = self.MaxBuyCount
        end
    end
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:OnBtnBuyClick()
    --v1.28-采购优化-礼包购买冷却
    local now = CS.UnityEngine.Time.realtimeSinceStartup
    if not self.LastBuyTime or (self.LastBuyTime and now - self.LastBuyTime > PurchaseBuyPayCD) then
        if self._IsLock then
            XUiManager.TipMsg(self._LockDesc)
            return
        end

        if not self._CanBuy or not self._CompleteSelection then
            return
        end

        self.LastBuyTime = now
        self:OnCheckSelectionContainOwn(function()
            if self.CheckBuyFun then
                -- 存在检测函数
                local result = self.CheckBuyFun(self.CurrentBuyCount, self.CurDiscountCouponIndex)
                if result == 1 then
                    if self.BeforeBuyReqFun then
                        -- 购买前执行函数
                        self.BeforeBuyReqFun(function()
                            self:BuyPurchaseRequest()
                        end)
                        return
                    end
                    self:BuyPurchaseRequest()
                elseif result ~= 3 then
                    self:CloseTips()
                end
            else
                self:BuyPurchaseRequest()
            end
        end)
    end
end

function XUiPurchaseBuyTips:OnCouponDropDownValueChanged(index)
    if index == 0 then
        self.CurDiscountCouponIndex = index
        self:RefreshDiscount(index)
    else
        local discountInfo = self.CurData.DiscountCouponInfos[index]
        local couponItemId = discountInfo.ItemId
        local couponName = XDataCenter.ItemManager.GetItemName(couponItemId)
        if XPurchaseConfigs.GetTagType(self.CurData.Tag) == XPurchaseConfigs.PurchaseTagType.Discount then
            -- 配置了打折需要进行比较
            local normalDisCountValue = XDataCenter.PurchaseManager.GetLBDiscountValue(self.CurData)
            local normalDiscountConsume = math.floor(normalDisCountValue * self.CurData.ConsumeCount)
            local couponDisCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(self.CurData, index)
            local couponDisCountConsume = math.floor(couponDisCountValue * self.CurData.ConsumeCount)
            if couponDisCountConsume >= normalDiscountConsume then
                -- 普通打折比选择的打折券便宜
                self.BuyUiTips.DrdSort.value = self.CurDiscountCouponIndex and self.CurDiscountCouponIndex or 0
                XUiManager.TipMsg(TextManager.GetText("NormalDiscountIsBetter") .. couponName)
                return
            end
        end
        local needCount = discountInfo.ItemCount
        local count = XDataCenter.ItemManager.GetCount(couponItemId)
        if count < needCount then
            self.BuyUiTips.DrdSort.value = self.CurDiscountCouponIndex and self.CurDiscountCouponIndex or 0
            XUiManager.TipMsg(TextManager.GetText("CouponCountInsufficient", needCount))
            return
        end
        self.CurDiscountCouponIndex = index
        self:RefreshDiscount(index)
    end
end

function XUiPurchaseBuyTips:OnSelectTextChange(count)
    self.CurrentBuyCount = count
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:OnSelectTextInputEnd(count)
    self.CurrentBuyCount = count
    self:RefreshBtnBuyPrice()
end

function XUiPurchaseBuyTips:CloseTips()
    if (self.Data or {}).SignInId and self.Data.SignInId ~= 0 then
        -- 签到礼包展示预览关闭
        if self.PurchaseSignTipDic[self.CurPrefabPath] then
            self.PurchaseSignTipDic[self.CurPrefabPath]:OnClose()
            self.CurPrefabPath = nil
        end
    else
        for _, v in pairs(self.ItemPool) do
            v.Transform:SetParent(self.PoolGo)
            v.GameObject:SetActiveEx(false)
        end

        for _, v in pairs(self.TitleGoPool) do
            v:SetParent(self.PoolGo)
            v.gameObject:SetActiveEx(false)
        end

        if self.UpdateTimerType then
            self:RemoveTimerFun(self.Data.Id)
        end
    end

    self:Close()
end

function XUiPurchaseBuyTips:OnBtnLeftClick()
    if self._CurShowBuyTimes > 1 then
        self._CurShowBuyTimes = self._CurShowBuyTimes - 1
        self:SetList()
        self:RefreshBuyTimeShowBtnState()
        self:RefreshBuyTimesProgress()
        self:CheckLBRewardIsHave()
    end
end

function XUiPurchaseBuyTips:OnBtnRightClick()
    if self._CurShowBuyTimes < self.Data.BuyTimes + 1 and self._CurShowBuyTimes < self.Data.BuyLimitTimes then
        self._CurShowBuyTimes = self._CurShowBuyTimes + 1
        self:SetList()
        self:RefreshBuyTimeShowBtnState()
        self:RefreshBuyTimesProgress()
        self:CheckLBRewardIsHave()
    end
end

function XUiPurchaseBuyTips:OnCheckSelectionContainOwn(cb)
    if self:CheckSelectionContainsOwn() or self:CheckNormalAndDailyContainsOwn() then
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText('PurchaseContainOwnTips'), nil, nil, function()
            if cb then
                cb()
            end
        end)
    else
        if cb then
            cb()
        end
    end
end
--endregion

--region 界面刷新
function XUiPurchaseBuyTips:RefreshBuyButtonStatus(ignoreUiRefresh)
    self:CheckCanBuyWithBuyTimes()
    self._CompleteSelection = true
    self._IsLock, self._LockDesc = XDataCenter.PurchaseManager.IsLBLock(self.Data)
    ---@type XPurchaseSelectionData
    local selectionData = XDataCenter.PurchaseManager.GetPurchaseSelectionData()
    if self._HasSelfChoice then
        local selectCount = XTool.GetTableCount(selectionData.SelfChoices)
        if selectCount < XTool.GetTableCount(self.Data.SelectDataForClient.SelectGroups) then
            self._CompleteSelection = false
        end
    end

    if self._HasRandomSelection then
        local selectCount = XTool.GetTableCount(selectionData.RandomBoxChoices)
        if selectCount < self.Data.SelectDataForClient.RandomSelectCount then
            self._CompleteSelection = false
        end
    end

    --- 单向控制，仅锁定后上锁，防止其他逻辑上锁后，这里IsLock=false又把它解锁了
    if self._IsLock then
        self._PanelChoiceItemList:SetIsNormalAllOwn(true)
        self._PanelRandomItemList:SetIsNormalAllOwn(true)
    end

    if not ignoreUiRefresh then
        self.TxtRed.gameObject:SetActiveEx(not self._CompleteSelection and self._CanBuy and not self._IsLock)
        self.BtnBuy:SetButtonState((self._CompleteSelection and not self._IsLock) and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    end
end

function XUiPurchaseBuyTips:RefreshDiscount(discountItemIndex)
    -- 打折券刷新显示
    if discountItemIndex == 0 then
        if XPurchaseConfigs.GetTagType(self.Data.Tag) == XPurchaseConfigs.PurchaseTagType.Discount and self.NormalDisCountValue < 1 then
            -- 打折的
            self.RawImageConsume.gameObject:SetActiveEx(true)
            -- self.BtnBuy:SetName(math.modf(self.Data.ConsumeCount * self.NormalDisCountValue))
            self:PayCoinStates(self.Data.ConsumeId,math.modf(self.Data.ConsumeCount * self.NormalDisCountValue))
            local icon = XDataCenter.ItemManager.GetItemIcon(self.Data.ConsumeId)
            if icon then
                self.RawImageConsume:SetRawImage(icon)
            end
            self._BtnBuy:SetActive("PanelTxt", true)
            -- self._BtnBuy:SetText("PanelTxt/TxtPrice", self.Data.ConsumeCount)
            self:PayCoinStates(self.Data.ConsumeId,self.Data.ConsumeCount)
        else
            -- self.BtnBuy:SetName(self.Data.ConsumeCount)
            self:PayCoinStates(self.Data.ConsumeId,self.Data.ConsumeCount)
            self._BtnBuy:SetActive("PanelTxt", false)
        end
    else
        local couponDisCountValue = XDataCenter.PurchaseManager.GetLBCouponDiscountValue(self.Data, discountItemIndex)
        self.RawImageConsume.gameObject:SetActiveEx(true)
        -- self.BtnBuy:SetName(math.modf(self.Data.ConsumeCount * couponDisCountValue))
        self:PayCoinStates(self.Data.ConsumeId,math.modf(self.Data.ConsumeCount * couponDisCountValue))
        self._BtnBuy:SetActive("PanelTxt", true)
        -- self._BtnBuy:SetText("PanelTxt/TxtPrice", self.Data.ConsumeCount)
        self:PayCoinStates(self.Data.ConsumeId,self.Data.ConsumeCount)
    end
end

-- 更新倒计时
function XUiPurchaseBuyTips:UpdateTimerFun(textComponent)
    textComponent = textComponent and textComponent or self.TXtTime
    self:UpdateCouponRemainTime()

    self.RemainTime = self.RemainTime - 1

    if self.RemainTime <= 0 then
        self:RemoveTimerFun(self.Data.Id)
        if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
            textComponent.text = TextManager.GetText("PurchaseLBSettOff")
            return
        end

        textComponent.text = ""
        return
    end

    if self.UpdateTimerType == UpdateTimerTypeEnum.SettOff then
        textComponent.text = TextManager.GetText("PurchaseSetOffTime", XUiHelper.GetTime(self.RemainTime, XUiHelper.TimeFormatType.PURCHASELB))
        return
    end

    textComponent.text = TextManager.GetText("PurchaseSetOnTime", XUiHelper.GetTime(self.RemainTime))
end

function XUiPurchaseBuyTips:UpdateCouponRemainTime()
    -- 打折券倒计时更新
    if not self.IsHasCoupon then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()
    local remainTime = self.AllCouponMaxEndTime - nowTime
    if remainTime > 0 then
        self.TxtTimeCoupon.text = TextManager.GetText("CouponEndTime", XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.SHOP))
    else
        self.DrdSort.value = 0
        self.TxtTimeCoupon.text = ""
        self.DrdSort.gameObject:SetActiveEx(false)
        self.IsHasCoupon = false
    end
end

function XUiPurchaseBuyTips:SetList()
    -- 直接获得的道具
    self.ListDirData = {}
    self.ListDayData = {}
    local rewards0 = self.Data.RewardGoodsList or {}

    if self.Data.SubDatas then
        rewards0 = self:RewardDataFilter(self.Data)
    end
    
    for _, v in pairs(rewards0) do
        v.LBGetType = LBGetTypeConfig.Direct
        table.insert(self.ListDirData, v)
    end
    -- v1.31-采购优化-涂装增加CG展示道具
    for _, v in pairs(rewards0) do
        if v.RewardType == XRewardManager.XRewardType.Fashion then
            local subItems = XDataCenter.FashionManager.GetFashionSubItems(v.TemplateId)
            if subItems then
                local isHave = XRewardManager.CheckRewardOwn(v.RewardType, v.TemplateId)
                for _, itemTemplateId in ipairs(subItems) do
                    table.insert(self.ListDirData, { TemplateId = itemTemplateId, Count = 1, LBGetType = LBGetTypeConfig.Direct,
                                                     IsSubItem = true, IsHave = isHave })
                end
            end
        end
    end
    -- 每日获得的道具
    local rewards1 = self.Data.DailyRewardGoodsList or {}
    for _, v in pairs(rewards1) do
        v.LBGetType = LBGetTypeConfig.Day
        table.insert(self.ListDayData, v)
    end

    -- 如果PanelCommon隐藏了，这些界面也不能显示
    if self.PanelCommon.gameObject.activeSelf == true then
        if self.Data.IsComboData then
            self._PanelBundle:Open()
            self._PanelBundle:InitGoodsShow(self.Data)
            self:RefreshBtnBuyPrice()
            -- 隐藏默认物品
            self.PanelLeft.gameObject:SetActiveEx(false)
        end

        if not XTool.IsTableEmpty(self.ListDirData) then
            self._PanelNormalItemList:Open()
            self._PanelNormalItemList:InitGoodsShow(self.ListDirData, self.Data.ConsumeCount ~= 0, self.Data.ConvertSwitch == 0)
        else
            self._PanelNormalItemList:Close()
        end

        if not XTool.IsTableEmpty(self.ListDayData) then
            self._PanelDailyItemList:Open()
            self._PanelDailyItemList:InitGoodsShow(self.ListDayData, self.Data.Desc or '')
        end

        if not XTool.IsTableEmpty(self.Data.SelectDataForClient) then
            if not XTool.IsTableEmpty(self.Data.SelectDataForClient.RandomGoods) then
                self._PanelRandomItemList:Open()
                self._PanelRandomItemList:Refresh(self.Data, self._CurShowBuyTimes)
            end

            if not XTool.IsTableEmpty(self.Data.SelectDataForClient.SelectGroups) then
                self._PanelChoiceItemList:Open()
                self._PanelChoiceItemList:Refresh(self.Data, self._CurShowBuyTimes)
            end
        end
    end
end

function XUiPurchaseBuyTips:SetBuyDes()
    if self.Data.BuyLimitTimes and self.Data.BuyLimitTimes ~= 0 then
        local clientResetInfo = self.Data.ClientResetInfo or {}
        if XTool.IsTableEmpty(clientResetInfo) then
            --不限时
            -- if self.Data.CanMultiply and self.MaxBuyCount and self.MaxBuyCount > 0 then
            if true and self.MaxBuyCount and self.MaxBuyCount > 0 then
                self.TxtLimitBuy.gameObject:SetActiveEx(true)
                self.TxtLimitBuy.text = TextManager.GetText("PurchaseCanBuyText", self.MaxBuyCount)
            else
                self.TxtLimitBuy.gameObject:SetActiveEx(false)
            end
        else
            -- 限时刷新
            local textKey = nil
            if clientResetInfo.ResetType == RestTypeConfig.Interval then
                self.TxtLimitBuy.gameObject:SetActiveEx(true)
                self.TxtLimitBuy.text = TextManager.GetText("PurchaseRestTypeInterval", clientResetInfo.DayCount, self.Data.BuyTimes, self.Data.BuyLimitTimes)
                return
            elseif clientResetInfo.ResetType == RestTypeConfig.Day then
                textKey = "PurchaseRestTypeDay"
            elseif clientResetInfo.ResetType == RestTypeConfig.Week then
                textKey = "PurchaseRestTypeWeek"
            elseif clientResetInfo.ResetType == RestTypeConfig.Month then
                textKey = "PurchaseRestTypeMonth"
            end

            if not textKey then
                self.TxtLimitBuy.text = ""
                self.TxtLimitBuy.gameObject:SetActiveEx(false)
                return
            end
            self.TxtLimitBuy.gameObject:SetActiveEx(true)
            self.TxtLimitBuy.text = TextManager.GetText(textKey, self.Data.BuyTimes, self.Data.BuyLimitTimes)
        end
    else
        self.TxtLimitBuy.gameObject:SetActiveEx(false)
    end
end

function XUiPurchaseBuyTips:RefreshBtnBuyPrice()
    if not self.Data.ConsumeCount then
        if self.Data.Price then
            -- self._BtnBuy:SetText("PanelTxt/TxtPrice", self.Data.Price)
            self:PayCoinStates(self.Data.ConsumeId,self.Data.Price)
        end
        return
    end

    local consumeCount = self.Data.ConsumeCount
    if self.Data.ConvertSwitch and self.Data.ConvertSwitch < consumeCount and self.Data.ConvertSwitch > 0 then
        consumeCount = self.Data.ConvertSwitch
    end
    local disCountConsume = math.floor(self.NormalDisCountValue * consumeCount)
    -- self._BtnBuy:SetText("PanelTxt/TxtPrice", consumeCount * self.CurrentBuyCount)
    self:PayCoinStates(self.Data.ConsumeId,consumeCount * self.CurrentBuyCount)
end

function XUiPurchaseBuyTips:RefreshBuyTimeShowBtnState()
    if self.BtnLeft then
        self.BtnLeft:SetButtonState(self._CurShowBuyTimes > 1 and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    end

    if self.BtnRight then
        local isShow = self._CurShowBuyTimes < self.Data.BuyTimes + 1 and self._CurShowBuyTimes < self.Data.BuyLimitTimes
        self.BtnRight:SetButtonState(isShow and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    end
end

function XUiPurchaseBuyTips:RefreshBuyTimesProgress()
    if self.TxtSection then
        self.TxtSection.text = XUiHelper.GetText('PurchaseBuyTimesProgress', self._CurShowBuyTimes, self.Data.BuyLimitTimes)
    end

    if self.TXtIsBuyTag then
        -- 不限制购买的礼包不显示购买状态文本
        if not XTool.IsNumberValid(self.Data.BuyLimitTimes) then
            self.TXtIsBuyTag.gameObject:SetActiveEx(false)
        else
            self.TXtIsBuyTag.gameObject:SetActiveEx(true)

            local isNoBuy = false
            if XTool.IsNumberValid(self._CurShowBuyTimes) then
                isNoBuy = self._CurShowBuyTimes > self.Data.BuyTimes
            else
                isNoBuy = self.Data.BuyTimes < self.Data.BuyLimitTimes
            end
            self.TXtIsBuyTag.text = isNoBuy and XUiHelper.GetText('PurchaseNoBuyLabel') or XUiHelper.GetText('PurchaseHadBuyLabel')
        end
    end
end

--- 刷新道具是否包含已拥有的提示显示
function XUiPurchaseBuyTips:RefreshRewardContainsOwnShow()
    local hasAnyOwnReward = self:CheckNormalAndDailyContainsOwn() or self:CheckSelectionContainsOwn()

    self.TxtHave.gameObject:SetActiveEx(hasAnyOwnReward)
    self.TxtHave.text = TextManager.GetText("PurchaseLBHaveFashion")
end
--endregion

--region 定时器

function XUiPurchaseBuyTips:StartTimer()
    if self.IsTimerStart then
        return
    end

    if CurrentSchedule then
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
    end

    CurrentSchedule = XScheduleManager.ScheduleForever(function()
        self:UpdateTimer()
    end, 1000)
    self.IsTimerStart = true
end

function XUiPurchaseBuyTips:DestroyTimer()
    if CurrentSchedule then
        XScheduleManager.UnSchedule(CurrentSchedule)
        CurrentSchedule = nil
        self.IsTimerStart = false
    end
end

function XUiPurchaseBuyTips:UpdateTimer()
    if not XTool.IsTableEmpty(self.TimerFun) then
        for _, fun in pairs(self.TimerFun) do
            fun()
        end
    end
end

--endregion

--region 其他

--- 基于购买次数方面的可购买判断，不考虑已拥有等情况
---@return @是否是多页签
function XUiPurchaseBuyTips:CheckCanBuyWithBuyTimes()
    -- 如果界面有多购买页签，需要根据当前的页签索引来判断
    if XTool.IsNumberValid(self._CurShowBuyTimes) then
        -- 没有购买记录，或者页签指向的新购买，都是可以购买的
        self._CanBuy = not XTool.IsNumberValid(self.Data.BuyTimes) and true or self._CurShowBuyTimes > self.Data.BuyTimes
        return true
    else
        -- 没有购买记录，或者购买次数未达上限，都是可以购买的
        if XTool.IsNumberValid(self.Data.BuyLimitTimes) then
            self._CanBuy = not XTool.IsNumberValid(self.Data.BuyTimes) or self.Data.BuyTimes < self.Data.BuyLimitTimes
        else
            self._CanBuy = true
        end
        return false
    end
end

function XUiPurchaseBuyTips:RegisterTimerFun(id, fun)
    if id and fun then
        self.TimerFun[id] = fun
    end
end

function XUiPurchaseBuyTips:RemoveTimerFun(id)
    if self.TimerFun[id] then
        self.TimerFun[id] = nil
    end
end

function XUiPurchaseBuyTips:CheckSignLBAndOpen(signInId, signInPrefabClass, isWeekCard, customPrefab)
    local isCustom = not string.IsNilOrEmpty(customPrefab) --V4.0:有些特殊礼包没有SignId
    if XTool.IsNumberValid(signInId) or isCustom then
        -- 签到礼包展示预览
        self.PanelCommon.gameObject:SetActiveEx(false)

        self.PanelSignGiftPack.gameObject:SetActiveEx(true)

        self.BtnSignGiftPackBgClose.CallBack = function()
            self:CloseTips()
        end
        self.BtnSignGiftPackClose.CallBack = function()
            self:CloseTips()
        end
        for _, v in pairs(self.PurchaseSignTipDic) do
            v.GameObject:SetActiveEx(false)
        end

        self.CurPrefabPath = isCustom and customPrefab or XSignInConfigs.GetSignPrefabPath(signInId)
        local purchaseSignTip = self.PurchaseSignTipDic[self.CurPrefabPath]
        if not purchaseSignTip then
            -- 生成对应prefab的实例
            local go = self.SignGiftPackNode:LoadPrefabEx(self.CurPrefabPath)
            go.gameObject:SetLayerRecursively(self.SignGiftPackNode.gameObject.layer)
            purchaseSignTip = signInPrefabClass.New(go, self)

            self.PurchaseSignTipDic[self.CurPrefabPath] = purchaseSignTip
        end

        if isWeekCard then
            purchaseSignTip:Open()
            purchaseSignTip:Refresh(signInId, false, self.Data)
        else
            purchaseSignTip:Refresh(self.Data, function()
                self:OnBtnBuyClick()
            end)
            purchaseSignTip.GameObject:SetActiveEx(true)
        end

        return true
    else
        return false
    end
end

function XUiPurchaseBuyTips:CheckLBIsUseMail()
    local isUseMail = self.Data.IsUseMail or false
    self.TxtContinue.gameObject:SetActiveEx(isUseMail)
end

function XUiPurchaseBuyTips:CheckLBRewardIsHave()
    if self.Data.ConvertSwitch and self.Data.ConvertSwitch < self.Data.ConsumeCount then
        -- 礼包存在已拥有物品折扣
        local remainPrice = self.Data.ConvertSwitch
        if remainPrice < 0 then
            remainPrice = 0
        end
        if remainPrice == 0 then
            -- 全部都拥有
            self.TxtHave.gameObject:SetActiveEx(true)
            self.TxtHave.text = TextManager.GetText("PurchaseLBOwnAll")
            self._BtnBuy:SetText("PanelTxt/TxtPrice", TextManager.GetText("PurchaseLBDontNeed"))
            self.BtnBuy:SetDisable(true, false)
            self._BtnBuy:SetActive("PanelTxt/TxtPriceOri", false)
        else
            -- 未拥有和拥有同时存在
            self.TxtHave.gameObject:SetActiveEx(true)
            self.TxtHave.text = TextManager.GetText("PurchaseLBHaveFashion")
            self.BtnBuy:SetDisable(false)
            if self.IsDisCount then
                remainPrice = math.modf(remainPrice * self.NormalDisCountValue)
            end
            --self.BtnBuy:SetName(remainPrice)
            -- self._BtnBuy:SetText("PanelTxt/TxtPrice", remainPrice)
            self:PayCoinStates(self.Data.ConsumeId,remainPrice)
            self._BtnBuy:SetActive("PanelTxt/TxtPriceOri", true)
            self._BtnBuy:SetText("PanelTxt/TxtPriceOri", self.Data.ConsumeCount)
        end
    else
        -- 默认检测是否已拥有逻辑
        local rewardList = self:GetRewardGoodsListForOwnCheck()
        local isHave, isLimitTime = XRewardManager.CheckRewardGoodsListIsOwnForPackage(rewardList)
        local isShowHave = isHave and not isLimitTime

        -- 捆绑包逻辑
        --if self.Data.IsSoldOut then
        --    isShowHave = true
        --end

        self._CommonRewardIsHave = isHave
        self.TxtRed.gameObject:SetActiveEx(isShowHave)

        if isShowHave then
            if #self.Data.RewardGoodsList > 1 then
                self.BtnBuy:SetDisable(isShowHave, not isShowHave)
            else
                self.BtnBuy:SetDisable(isShowHave, not isShowHave)
            end
            self.TxtRed.text = TextManager.GetText("PurchaseLBHaveFashionCantBuy")

            self._PanelChoiceItemList:SetIsNormalAllOwn(true)
            self._PanelRandomItemList:SetIsNormalAllOwn(true)
        else
            self.BtnBuy:SetDisable(false)
            if (self.Data.BuyLimitTimes > 0 and self.Data.BuyTimes == self.Data.BuyLimitTimes) or
                    (self.Data.TimeToShelve > 0 and self.Data.TimeToShelve <= self.NowTime) or
                    (self.Data.TimeToUnShelve > 0 and self.Data.TimeToUnShelve <= self.NowTime) or
                    self.Data.IsSoldOut then
                --卖完了，不管。
                self.TXtTime.text = ""
                self.TXtTime.transform.parent.gameObject:SetActiveEx(false)
                if self.UpdateTimerType then
                    self:RemoveTimerFun(self.Data.Id)
                end
                self._BtnBuy:SetActive("PanelTxt/TxtPriceOri", false)
                self.BtnBuy:SetButtonState(XUiButtonState.Disable)
                self.TxtRed.gameObject:SetActiveEx(false)
            else
                self:RefreshBuyButtonStatus()
                self:RefreshRewardContainsOwnShow()
            end
        end
    end
end

function XUiPurchaseBuyTips:CheckLBCouponDiscount()
    if self.Data.DiscountCouponInfos and #self.Data.DiscountCouponInfos > 0 then
        self.CurDiscountCouponIndex = 0
        self.DrdSort.gameObject:SetActiveEx(true)
        self.DrdSort:ClearOptions()
        local od = DropdownOptionData(TextManager.GetText("UnUsedCouponDiscount"))
        self.DrdSort.options:Add(od)
        self.DrdSort.captionText.text = TextManager.GetText("UnUsedCouponDiscount")
        self.AllCouponMaxEndTime = 0
        for _, optionData in ipairs(self.Data.DiscountCouponInfos) do
            local itemId = optionData.ItemId
            local itemName = XDataCenter.ItemManager.GetItemName(itemId)
            local count = XDataCenter.ItemManager.GetCount(itemId)
            local od = DropdownOptionData(itemName .. TextManager.GetText("DiscountCouponRemain", count))
            self.DrdSort.options:Add(od)
            if optionData.EndTime > self.AllCouponMaxEndTime then
                self.AllCouponMaxEndTime = optionData.EndTime
            end
        end
        self.DrdSort.value = 0
        self.TxtTimeCoupon.text = TextManager.GetText("CouponEndTime", XUiHelper.GetTime(self.AllCouponMaxEndTime - self.NowTime, XUiHelper.TimeFormatType.SHOP))
        self.IsHasCoupon = true
    else
        self.DrdSort.gameObject:SetActiveEx(false)
        self.IsHasCoupon = false
    end
end

function XUiPurchaseBuyTips:BuyPurchaseRequest()
    if self.Data and self.Data.Id then

        if self._IsLock then
            XUiManager.TipMsg(self._LockDesc)
            return
        end

        if not self._CanBuy or not self._CompleteSelection then
            return
        end

        if not self.CurrentBuyCount or self.CurrentBuyCount == 0 then
            self.CurrentBuyCount = 1
        end
        local discountCouponId = nil
        if self.CurDiscountCouponIndex and self.CurDiscountCouponIndex ~= 0 then
            discountCouponId = self.CurData.DiscountCouponInfos[self.CurDiscountCouponIndex].Id
        end

        ---@type XPurchaseSelectionData
        local selectionData = XDataCenter.PurchaseManager.GetPurchaseSelectionData()
        local randomSelection = nil
        local selectGroups = nil
        local selectGroupGoodsIds = nil

        if not XTool.IsTableEmpty(selectionData) then
            randomSelection = selectionData.RandomBoxChoices

            if not XTool.IsTableEmpty(selectionData.SelfChoices) then
                selectGroups = {}
                selectGroupGoodsIds = {}
                for i, v in pairs(selectionData.SelfChoices) do
                    table.insert(selectGroups, i)
                    table.insert(selectGroupGoodsIds, v)
                end
            end
        end

        local requestCb = function()
            XDataCenter.WeaponFashionManager.SetNotifyWeaponFashionTransformObtainShowLock(false)

            if self.UpdateCb then
                self.UpdateCb()
            end
        end

        XDataCenter.WeaponFashionManager.SetNotifyWeaponFashionTransformObtainShowLock(true)
        XDataCenter.PurchaseManager.PurchaseRequest(self.Data.Id, requestCb, self.CurrentBuyCount, discountCouponId, self.UiTypeList, randomSelection, selectGroups, selectGroupGoodsIds)
        self:CloseTips()
    end
end

function XUiPurchaseBuyTips:SetUiActive(ui, active)
    if not ui or not ui.gameObject then
        return
    end

    if ui.gameObject.activeSelf == active then
        return
    end

    ui.gameObject:SetActiveEx(active)
end

function XUiPurchaseBuyTips:GetSelectGroupRewardGoodsByGroupIdAndId(groupId, id)
    if self.Data and self.Data.SelectDataForClient and self.Data.SelectDataForClient.SelectGroups then
        for i, v in pairs(self.Data.SelectDataForClient.SelectGroups) do
            if v.GroupId == groupId then
                for i2, v2 in pairs(v.SelectGoods) do
                    if v2.Id == id then
                        return v2.RewardGoods
                    end
                end
            end
        end
    end
end

function XUiPurchaseBuyTips:GetRandomRewardGoodsById(id)
    if self.Data and self.Data.SelectDataForClient and self.Data.SelectDataForClient.RandomGoods then
        for i, v in pairs(self.Data.SelectDataForClient.RandomGoods) do
            if v.Id == id then
                return v.RewardGoods
            end
        end
    end
end

--- 检查自选、福袋的道具中是否有已拥有的
function XUiPurchaseBuyTips:CheckSelectionContainsOwn()
    if self._HasSelfChoice then
        ---@type XPurchaseSelectionData
        local data = XDataCenter.PurchaseManager.GetPurchaseSelectionData()

        if data then
            if not XTool.IsTableEmpty(data.SelfChoices) then
                for groupId, index in pairs(data.SelfChoices) do
                    local rewardGoods = self:GetSelectGroupRewardGoodsByGroupIdAndId(groupId, index)
                    if rewardGoods and XRewardManager.CheckRewardOwn(rewardGoods.RewardType, rewardGoods.TemplateId) then
                        return true
                    end
                end
            end
        end
    end

    if self._HasRandomSelection then
        ---@type XPurchaseSelectionData
        local data = XDataCenter.PurchaseManager.GetPurchaseSelectionData()

        if data then
            if not XTool.IsTableEmpty(data.RandomBoxChoices) then
                for i, rewwardId in pairs(data.RandomBoxChoices) do
                    local rewardGoods = self:GetRandomRewardGoodsById(rewwardId)
                    if rewardGoods and XRewardManager.CheckRewardOwn(rewardGoods.RewardType, rewardGoods.TemplateId) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

--- 获取用于"已拥有"检测的奖励列表
--- 捆绑包：排除已购买（IsSoldOut）子礼包的道具，避免因已购子包的道具误判整包不可买
--- 非捆绑包：原样返回 RewardGoodsList
function XUiPurchaseBuyTips:GetRewardGoodsListForOwnCheck()
    if self.Data.IsComboData and self.Data.SubDatas then
        local result = {}
        for _, subData in ipairs(self.Data.SubDatas) do
            if not subData.IsSoldOut then
                for _, reward in ipairs(subData.RewardGoodsList) do
                    result[#result + 1] = reward
                end
            end
        end
        return result
    end
    return self.Data.RewardGoodsList
end

--- 检查普通和每日礼包是否存在已拥有
function XUiPurchaseBuyTips:CheckNormalAndDailyContainsOwn()
    local rewardList = self:GetRewardGoodsListForOwnCheck()
    if XRewardManager.CheckRewardGoodsListIsOwn(rewardList) then
        return true
    end

    if XRewardManager.CheckRewardGoodsListIsOwn(self.Data.DailyRewardGoodsList) then
        return true
    end

    return false
end
--endregion

function XUiPurchaseBuyTips:RefreshItemCount(itemId, priceTxt)
    if itemId ~= self.CurItemId then
        return
    end
    self:PayCoinStates(self.CurItemId, self.CurPriceTxt)
end

function XUiPurchaseBuyTips:PayCoinStates(itemId, priceTxt)
    self.CurPriceTxt = priceTxt
    self.CurItemId = itemId
    local colorEnough = CS.XGame.ClientConfig:GetString("UiPurchaseBuyTipsButtonColor1")
    local colorUnenough = CS.XGame.ClientConfig:GetString("UiPurchaseBuyTipsButtonColor2")
    local itemCount = XDataCenter.ItemManager.GetItem(itemId).Count
    local priceText = ""
    if itemCount >= tonumber(priceTxt) then
        priceText = string.format("<color=%s>%s</color>", colorEnough, priceTxt)
    else
        priceText = string.format("<color=%s>%s</color>", colorUnenough, priceTxt)
    end
    self.BtnBuy:SetName(priceText)
end

---@param data XPurchaseComboData
function XUiPurchaseBuyTips:RewardDataFilter(data)
    local result = {}

    for i, v in pairs(data.RewardGoodsList) do
        result[i] = v
    end

    if data.SubDatas then
        ---@param v XUiPurchaseComboSubGridData
        for i, v in pairs(data.SubDatas) do
            if v.IsSoldOut then
                for i, reward in pairs(v.RewardGoodsList) do
                    local isin = false
                    local targetIndex = 0
                    
                    for index, resultData in pairs(result) do
                        if resultData.Id == reward.Id then
                            isin = true
                            targetIndex = index
                            break
                        end
                    end

                    if isin then
                        table.remove(result, targetIndex)
                    end
                end
            end
        end
    end
    
    return result
end 