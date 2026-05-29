local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPassportCardGrid = require("XUi/XUiPassport/Card/XUiPassportCardGrid")

local CSXTextManagerGetText = CS.XTextManager.GetText

---@field _Control XPassportControl
---@class XUiPassportCardPanel:XUiNode
local XUiPassportCardPanel = XClass(XUiNode, "XUiPassportCardPanel")

function XUiPassportCardPanel:OnStart(passportId)
    self.PassportId = passportId
    self:InitDynamicTable()
    self:RegisterButtonEvent()
    self:UpdateDesc()
    self:UpdateDynamicTable()
end

function XUiPassportCardPanel:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelIconList.transform)
    self.DynamicTable:SetProxy(XUiPassportCardGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.PanelBagItem.gameObject:SetActive(false)
end

function XUiPassportCardPanel:RegisterButtonEvent()
    self.BtnBuy:AddEventListener(handler(self, self.OnBtnBuyClick))
end

function XUiPassportCardPanel:Refresh()
    local passportId = self.PassportId
    local isUnLock = self._Control:GetPassportInfos(passportId) and true or false
    self.BtnBuy:SetDisable(isUnLock, not isUnLock)

    local costItemId = self._Control:GetPassportTypeInfoCostItemId(passportId)
    local costItemCount = self._Control:GetPassportTypeInfoCostItemCount(passportId)
    local costItemName = ""
    local btnName = isUnLock and CSXTextManagerGetText("AlreadyBuy") or CSXTextManagerGetText("PassportBtnBuyPassportDesc", costItemCount, costItemName)
    self.BtnBuy:SetName(btnName)

    if self.IconBtnBuy then
        local costItemIcon = XItemConfigs.GetItemIconById(costItemId)
        self.IconBtnBuy:SetRawImage(costItemIcon)
        self.IconBtnBuy.gameObject:SetActiveEx(not isUnLock)
    end
end

function XUiPassportCardPanel:UpdateDesc()
    local passportId = self.PassportId
    local name = self._Control:GetPassportTypeInfoName(passportId)
    self.TxtCardName.text = name

    local icon = self._Control:GetPassportTypeInfoIcon(passportId)
    self.RImgIcon:SetRawImage(icon)

    local buyDesc = self._Control:GetPassportTypeInfoBuyDescBase(passportId)
    self.TxtIntro.text = string.gsub(buyDesc, "\\n", "\n")

    if self.TxtIntroCloud then
        local cloudDesc = self._Control:GetPassportTypeInfoBuyDescCloudGame(passportId)
        self.TxtIntroCloud.text = string.gsub(cloudDesc, "\\n", "\n")
        self.PanelCloud.gameObject:SetActiveEx(cloudDesc ~= "")
    end
end

function XUiPassportCardPanel:UpdateDynamicTable()
    self.BuyRewardShowIdList = self._Control:GetBuyRewardShowIdList(self.PassportId)
    self.DynamicTable:SetDataSource(self.BuyRewardShowIdList)
    self.DynamicTable:ReloadDataSync()
end

function XUiPassportCardPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self.Parent)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local passportRewardId = self.BuyRewardShowIdList[index]
        grid:Refresh(passportRewardId)
    end
end

function XUiPassportCardPanel:OnBtnBuyClick()
    local passportId = self.PassportId
    if not self._Control:CheckStopToBuyBeforeTheEnd() then
        return
    end

    local costItemId = self._Control:GetPassportTypeInfoCostItemId(passportId)
    local haveCostItemCount = XDataCenter.ItemManager.GetCount(costItemId)
    local costItemCount = self._Control:GetPassportTypeInfoCostItemCount(passportId)
    local passportName = self._Control:GetPassportTypeInfoName(passportId)
    local costItemName = XItemConfigs.GetItemNameById(costItemId)
    local title = CSXTextManagerGetText("BuyConfirmTipsTitle")
    local desc = CSXTextManagerGetText("PassportBuyPassportTipsDesc", costItemCount, costItemName, passportName)
    local sureCallback = function()
        if haveCostItemCount < costItemCount then
            XUiHelper.OpenPurchaseBuyHongKaCountTips()
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
            return
        end
        self._Control:RequestPassportBuyPassport(passportId, function()
            self:Refresh()
            self.Parent:RefreshAllPanels()
        end)
    end

    XUiManager.DialogTip(title, desc, nil, nil, sureCallback)
end

return XUiPassportCardPanel
