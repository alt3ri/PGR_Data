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


function XUiTheatre6BattleShop:OnAwake()
    self:InitComponents()
end

function XUiTheatre6BattleShop:InitComponents()
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
end

function XUiTheatre6BattleShop:Refresh()
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
    self._Control:LeaveShopRequest(function()
        self:Close()
    end)
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
        self.RImgGold:SetRawImage(self._Control:GetCoinIcon())
    end
end

return XUiTheatre6BattleShop
