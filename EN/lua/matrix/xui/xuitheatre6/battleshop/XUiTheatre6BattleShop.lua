local XUiTheatre6BattleShopGridCommodity = require(
    "XUi/XUiTheatre6/BattleShop/Grid/XUiTheatre6BattleShopGridCommodity")
local XUiTheatre6BattleShopGridRefresh = require(
    "XUi/XUiTheatre6/BattleShop/Grid/XUiTheatre6BattleShopGridRefresh")
local XUiTheatre6PanelRoleDetail = require(
    "XUi/XUiTheatre6/Character/Panel/XUiPanelTheatre6CharacterAttrDetail")
local XUiTheatre6PanelSan = require(
    "XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopSan")
local XUiPanelTheatre6TopStage = require(
    "XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopStage")
local XUiPanelTheatre6TagDetail = require(
    "XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6TagDetail")
local XUiTheatre6PanelAsset = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Asset")

-- local XUiTheatre6PanelStage = require(
--     "XUi/XUiTheatre6/Panel/XUiTheatre6PanelStage")
---@class XUiTheatre6BattleShop : XLuaUi
---@field _Control XTheatre6Control
---@field TxtShopName UnityEngine.UI.Text
---@field GridCommodity UiObject
---@field GridRefresh UiObject
---@field PanelRoleDetail UiObject
---@field PanelSan UiObject
---@field ListBuff XDynamicTableNormal
---@field UiTheatre6GridBuff UiObject
---@field UiPanelNone UnityEngine.RectTransform
---@field BtnExit XUiComponent.XUiButton
---@field BubbleAttributeDetail UiObject
---@field BubbleAttackDetail UnityEngine.RectTransform
---@field BubbleSkillDetail UiObject
---@field BubbleRelicDetail UiObject
---@field BubbleTagDetail UiObject
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field PanelStage UiObject
local XUiTheatre6BattleShop = XLuaUiManager.Register(XLuaUi, "UiTheatre6BattleShop")

local ItemType = {
    Skill = 1,
    AttrPack = 2,
}

function XUiTheatre6BattleShop:OnAwake()
    self:InitComponents()
end

function XUiTheatre6BattleShop:InitComponents()
    self._CoinIcon = self._Control:GetCoinIcon()
    self._SanIcon = self._Control:GetSanIcon()
    -- self:BindExitBtns()
    self.BtnExit:AddEventListener(handler(self, self.OnBtnExitClick))
    self.PanelRoleDetail = XUiTheatre6PanelRoleDetail.New(self.PanelRoleDetail, self, nil, nil, true)
    self:SetupSellDragArea()
    self.PanelRoleDetail:Open()

    self.PanelSan = XUiTheatre6PanelSan.New(self.PanelSan, self)
    self.PanelSan:Open()

    self.PanelStage = XUiPanelTheatre6TopStage.New(self.PanelStage, self)
    self.PanelStage:Open()
    self.TxtShopName.text = XUiHelper.GetText("Theatre6BattleShopName")


    self._PanelAsset = XUiTheatre6PanelAsset.New(self.PanelAsset, self)
    self._PanelAsset:Refresh()
    self.BubbleTagDetail = XUiPanelTheatre6TagDetail.New(self.BubbleTagDetail, self)
    self.BubbleTagDetail:Close()
    self:OnDragSell(false)
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self._PanelBuff = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6BottomBuffList").New(self.ListBuff, self)
    self._PanelBuff:UpdateView()
    require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6MessyCodeFx").New(self.MessyCodeFx, self)

    self.BtnBuySan:AddEventListener(handler(self, self.OnBtnBuySanClick))
    self:InitSanButton()
end

function XUiTheatre6BattleShop:SetupSellDragArea()
    self.PanelRoleDetail:AddExternalDragAreaToSkillBag(
        self.PanelSell,
        handler(self, self.OnSkillDropToSell),
        handler(self, self.OnDragSell)
    )
end

function XUiTheatre6BattleShop:OnSkillDropToSell(skillId)
    self._Control:SellSkillGood(skillId, function()
        self:Refresh()
    end)
end

function XUiTheatre6BattleShop:OnStart(...)
    self._Control:EnterShop()
    self.GridCommodity.gameObject:SetActiveEx(false)
    self.GridRefresh.gameObject:SetActiveEx(false)
    self:Refresh()
    self:AddEvent()
end

function XUiTheatre6BattleShop:AddEvent()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_BUY_GOOD, self.OnGoodBought, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_UPDATE_SKILL, self._RefreshTagHighlightSource, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_GOLD_CHANGE, self.UpdatePurchaseSanPrice, self)
end

function XUiTheatre6BattleShop:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_BUY_GOOD, self.OnGoodBought, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_UPDATE_SKILL, self._RefreshTagHighlightSource, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_GOLD_CHANGE, self.UpdatePurchaseSanPrice, self)
end

function XUiTheatre6BattleShop:OnDestroy()
    self._Control:ClearTagHighlightSourceTagIds()
    self:RemoveEvent()
end

function XUiTheatre6BattleShop:OnGoodBought()
    self:_RefreshTagHighlightSource()
end

---根据当前未售出的技能商品 + 遗物商品聚合 tag 高亮源
---  技能商品贡献其 BuildTags 全部
---  遗物商品贡献"装备 dominant tag ∩ 自身 BuildTags"
function XUiTheatre6BattleShop:_RefreshTagHighlightSource()
    local skillIds = {}
    local relicIds = {}
    for _, good in ipairs(self._Control:GetShopGoods() or {}) do
        if not good.IsSell then
            if good.Type == ItemType.Skill then
                table.insert(skillIds, good.GoodId)
            elseif good.Type == ItemType.AttrPack then
                table.insert(relicIds, good.GoodId)
            end
        end
    end
    self._Control:SetTagHighlightSourceTagIds(
        self._Control:CollectShopOrTaskHighlightSourceTags(skillIds, relicIds)
    )
end

function XUiTheatre6BattleShop:Refresh()
    self:_RefreshTagHighlightSource()
    local shopGoods = self._Control:GetShopGoods()

    self:RefreshCommodityList(shopGoods)
    self:RefreshGrid()
end

function XUiTheatre6BattleShop:RefreshCommodityList(goodDatas)
    self._GridCommodityUiList = self._GridCommodityUiList or {}
    for _, grid in pairs(self._GridCommodityUiList) do
        grid:Close()
    end
    for index, goodData in ipairs(goodDatas) do
        if not self._GridCommodityUiList[index] then
            local go = XUiHelper.Instantiate(self.GridCommodity, self.GridCommodity.transform.parent)
            go.name = "GridCommodity" .. goodData.Position
            self._GridCommodityUiList[index] = XUiTheatre6BattleShopGridCommodity.New(go, self)
        end
        self._GridCommodityUiList[index]:Open()
        self._GridCommodityUiList[index]:Refresh(goodData)
        if not self._GridCommodityUiList[index].IsLock then
             self._GridCommodityUiList[index]:PlayAnimationWithMask("ListCommodityReShow")
        end
    end
end

function XUiTheatre6BattleShop:RefreshGrid()
    if not self._RefreshGridUi then
        self._RefreshGridUi = XUiTheatre6BattleShopGridRefresh.New(self.GridRefresh, self)
    end
    self._RefreshGridUi.Transform:SetAsLastSibling()
    self._RefreshGridUi:Open()
    self._RefreshGridUi:Refresh()
end

function XUiTheatre6BattleShop:OnRefreshGridClick()
    self._Control:ShopFreshRequest(function()
        self:Refresh()
        XDataCenter.GuideManager.CheckGuideOpen()	-- 触发引导
    end)
end

function XUiTheatre6BattleShop:OnBtnExitClick()
    if self:TryOpenSellSkillPanel() then
        return
    end
    -- if self:HasCanBuyCommodity() or self:HasRefreshCount() then
    --     XLuaUiManager.Open("UiTheatre6PopupCommon", "", XUiHelper.GetText("Theatre6BattleShopTipExitConfirm"), nil, handler(self, self.OnConfirmGiveUp))
    -- else
    self:ExitShop()
    -- end
end

function XUiTheatre6BattleShop:OnBtnBackClick()
    self:Close()
end

function XUiTheatre6BattleShop:TryOpenSellSkillPanel()
    return self._Control:CheckForceSellSkillBlock()
end

function XUiTheatre6BattleShop:OnConfirmGiveUp()
    self:ExitShop()
end

function XUiTheatre6BattleShop:ExitShop()
    self._Control:LeaveShopRequest() --下个界面会PopThenOpen
end

function XUiTheatre6BattleShop:HasCanBuyCommodity()
    for _, grid in pairs(self._GridCommodityUiList) do
        if not grid:IsSellOut() then
            return true
        end
    end
    return false
end

function XUiTheatre6BattleShop:HasRefreshCount()
    return self._Control:GetCurRefreshCount() > 0
end

function XUiTheatre6BattleShop:OnDragSell(isDragging, skillId)
    self.PanelSell.gameObject:SetActiveEx(isDragging)
    if isDragging then
        local skillConfig = self._Control:GetSkillCfgById(skillId)
        self.TxtSellNum.text = skillConfig.SellPrice
        self.RImgGold:SetRawImage(self._CoinIcon)
    end
end

--region 购买san值

function XUiTheatre6BattleShop:InitSanButton()
    if not self._Control:CanPurchaseSan() then
        self.BtnBuySan.gameObject:SetActiveEx(false)
        return
    end
    self._BuySanColor = self._Control:GetClientConfigValue("ShopRefreshColor", 3)
    self.BtnBuySan.gameObject:SetActiveEx(true)
    self.BtnBuySan:SetRawImage(self._CoinIcon)
    self.BtnBuySan:SetNameByGroup(1, self._Control:GetShopSanNum())
    self.RImgSan1:SetRawImage(self._SanIcon)
    self.RImgSan2:SetRawImage(self._SanIcon)
    self:UpdatePurchaseSanPrice()
end

function XUiTheatre6BattleShop:UpdatePurchaseSanPrice()
    local price = self._Control:GetPurchaseSanPrice()
    local leftTimes = self._Control:GetPurchaseSanLeftTimes()
    if self._Control:IsPurchaseSanCoinNoEnough() then
        self.BtnBuySan:SetNameByGroup(0, string.format("<color=#%s>%s</color>", self._BuySanColor, price))
    else
        self.BtnBuySan:SetNameByGroup(0, price)
    end
    self.BtnBuySan:SetNameByGroup(2, leftTimes)
    self.BtnBuySan:SetButtonState(self._Control:IsPurchaseSanMaxTimes() and XUiButtonState.Disable or XUiButtonState.Normal)
end

function XUiTheatre6BattleShop:OnBtnBuySanClick()
    if self._Control:IsPurchaseSanMaxTimes() then
        self._Control:ShowTip(self._Control:GetClientConfigValue("PurchaseSanMaxTimes"))
        return
    end

    if self._Control:IsPurchaseSanCoinNoEnough() then
        self._Control:ShowTip(self._Control:GetClientConfigValue("PurchaseSanCoinNoEnough"))
        return
    end

    if self._Control:IsSanMax() then
        self._Control:ShowTip(self._Control:GetClientConfigValue("PurchaseSanMaxSan"))
        return
    end

    self._Control:RequestShopBuySan(function()
        self:UpdatePurchaseSanPrice()
    end)
end

--endregion

return XUiTheatre6BattleShop
