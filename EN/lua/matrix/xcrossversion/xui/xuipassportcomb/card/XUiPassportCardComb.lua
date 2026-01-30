local XUiPassportCardGrid = require("XCrossVersion/XUi/XUiPassportComb/Card/XUiPassportCombCardGrid")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

---@field _Control XPassportCombControl
---@class UiPassportCombCard:XLuaUi
local XUiPassportCardComb = XLuaUiManager.Register(XLuaUi, "UiPassportCardComb")

local CSXTextManagerGetText = CS.XTextManager.GetText
local tableInsert = table.insert

local _BuyLimitTimes = 0

--购买通行证
function XUiPassportCardComb:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.HongKa)
    self:RegisterButtonEvent()
    -- self.PanelAsset.gameObject:SetActiveEx(false) -- 日服没有虹卡，隐藏虹卡资源框 -- 英文服使用虹卡
    self:InitTextBuyCaption()
end

function XUiPassportCardComb:OnStart(passportId, closeCb)
    self.PassportId = passportId
    self.CloseCb = closeCb

    self.DynamicTable = XDynamicTableNormal.New(self.PanelIconList.transform)
    self.DynamicTable:SetProxy(XUiPassportCardGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.PanelBagItem.gameObject:SetActive(false)
    self:UpdateDynamicTable(passportId)

    self:UpdateDesc(passportId)
    self:UpdateFashionShow(passportId)
    self:InitBtnXqActive(passportId)
    self:GetBuyLimit()
end

function XUiPassportCardComb:GetBuyLimit()
    _BuyLimitTimes = self._Control:GetPassportTypeInfoRepeatBuyTimes(self.PassportId)
    local buyTimes = self._Control:GetPassportBuyTimes(self.PassportId)
    self.TagTxt.text = buyTimes .. "/" .. _BuyLimitTimes
    local free = self._Control:GetPassportTypeInfoFree(self.PassportId)
    self.TagTxt.gameObject:SetActiveEx(not free)
end

function XUiPassportCardComb:OnEnable()
    self:Refresh()
end

function XUiPassportCardComb:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiPassportCardComb:InitTextBuyCaption()
    local time = self._Control:GetPassportBuyPassPortEarlyEndTime()
    local timeDesc = time > 0 and XUiHelper.GetTimeDesc(time, 2) or 0 .. CSXTextManagerGetText("Second")
    timeDesc = string.gsub(timeDesc, "^%s*(.-)%s*$", "%1")
    -- timeDesc = string.gsub(timeDesc, " ", "") 英文服需要数字与min之间有空格 20 min
    local buyCaptionDesc = CSXTextManagerGetText("PassportBuyCaptionDesc", timeDesc)
    self.TextBuyTime.text = buyCaptionDesc
end

function XUiPassportCardComb:InitBtnXqActive(passportId)
    local fashionId = self._Control:GetPassportBuyFashionShowFashionId(passportId)
    self.BtnXq.gameObject:SetActiveEx(not XTool.IsTableEmpty(fashionId))
end

function XUiPassportCardComb:Refresh()
    local passportId = self:GetPassportId()
    local reachMax = false
    local passportInfo = self._Control:GetPassportInfos(passportId)
    if passportInfo then
        reachMax = passportInfo:GetBuyTimes() >= _BuyLimitTimes
    end
    self.BtnBuy:SetDisable(reachMax, not reachMax)

    local costItemId = self._Control:GetPassportTypeInfoCostItemId(passportId)
    local costItemCount = self._Control:GetPassportTypeInfoCostItemCount(passportId)
    local costItemName = ""     --策划需求，不显示道具名字
    local btnName = reachMax and CSXTextManagerGetText("AlreadyBuy") or CSXTextManagerGetText("PassportBtnBuyPassportDesc", costItemCount, costItemName)
    self.BtnBuy:SetName(btnName)

    if self.IconBtnBuy then
        local costItemIcon = XItemConfigs.GetItemIconById(costItemId)
        self.IconBtnBuy:SetRawImage(costItemIcon) -- 英文服使用虹卡
        -- self.IconBtnBuy:SetRawImage("Assets/Product/Texture/Image/UiPurchase/UiPurchaseYuan1.png") -- 直购写死日元图标
        self.IconBtnBuy.gameObject:SetActiveEx(not reachMax)
    end
    self:GetBuyLimit()
end

function XUiPassportCardComb:UpdateFashionShow(passportId)
    local isHavePassportId = XTool.IsNumberValid(passportId)
    if isHavePassportId then
        local icon = self._Control:GetPassportBuyFashionShowIcon(passportId)
        self.RImgShow:SetRawImage(icon)
    end

    self.RImgShow.gameObject:SetActiveEx(isHavePassportId)
end

function XUiPassportCardComb:UpdateDesc(passportId)
    self.TxtName.text = self._Control:GetPassportTypeInfoName(passportId)

    local icon = self._Control:GetPassportTypeInfoIcon(passportId)
    self.RImgIcon:SetRawImage(icon)

    local buyDesc = self._Control:GetPassportTypeInfoBuyDesc(passportId)
    self.TxtMessage.text = string.gsub(buyDesc, "\\n", "\n")
end

function XUiPassportCardComb:UpdateDynamicTable(passportId)
    self.BuyRewardShowIdList = self._Control:GetBuyRewardShowIdList(passportId)
    self.DynamicTable:SetDataSource(self.BuyRewardShowIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPassportCardComb:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local passportRewardId = self.BuyRewardShowIdList[index]
        grid:Refresh(passportRewardId)
    end
end

function XUiPassportCardComb:RegisterButtonEvent()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self:RegisterClickEvent(self.BtnXq, self.OnBtnXqClick)
    self.BtnBuy.CallBack = handler(self, self.OnBtnBuyClick)
end

function XUiPassportCardComb:OnBtnXqClick()
    local passportId = self:GetPassportId()
    local fashionId = self._Control:GetPassportBuyFashionShowFashionId(passportId)
    local isWeaponFahion = self._Control:IsPassportBuyFashionShowIsWeaponFahion(passportId)
    XLuaUiManager.Open("UiFashionDetailComb", fashionId, isWeaponFahion)
end

function XUiPassportCardComb:OnBtnBuyClick()
    local passportId = self:GetPassportId()
    if not self._Control:CheckStopToBuyBeforeTheEnd() then
        return
    end
    
    local costItemId = self._Control:GetPassportTypeInfoCostItemId(passportId)
    local haveCostItemCount = XDataCenter.ItemManager.GetCount(costItemId)
    local costItemCount = self._Control:GetPassportTypeInfoCostItemCount(passportId)
    local passportName = self._Control:GetPassportTypeInfoName(passportId)
    local costItemName = XItemConfigs.GetItemNameById(costItemId)
    local title = CSXTextManagerGetText("BuyConfirmTipsTitle")
    -- local desc = CSXTextManagerGetText("PassportBuyPassportTipsDesc", costItemCount, passportName)
    local desc = CSXTextManagerGetText("PassportBuyPassportTipsDesc", costItemCount, costItemName, passportName)
    local sureCallback = function()
        if haveCostItemCount < costItemCount then -- 英文服使用虹卡
            -- XUiManager.TipText("ShopItemHongKaNotEnough")
            XUiHelper.OpenPurchaseBuyHongKaCountTips()
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
            return
        end
        self._Control:RequestPassportBuyPassport(passportId, handler(self, self.Refresh))
    end

    XUiManager.DialogTip(title, desc, XUiManager.DialogType.Passport, nil, sureCallback)
end

function XUiPassportCardComb:GetPassportId()
    return self.PassportId
end