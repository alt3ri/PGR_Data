local XUiCommonPopupUsePackageGridCommonPopUp = require(
    "XUi/XUiCommonPopupUsePackage/XUiCommonPopupUsePackageGridCommonPopUp")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiCommonPopupUsePackage : XLuaUi
local XUiCommonPopupUsePackage = XLuaUiManager.Register(XLuaUi, "UiCommonPopupUsePackage")
function XUiCommonPopupUsePackage:OnStart(id, successCallback, challengeCountData, buyAmount)
    self.Id = id
    self.SuccessCallback = successCallback
    self.ChallengeCountData = challengeCountData
    self.BuyAmount = buyAmount
    self:AddBtnCallBack()
    self:InitDynamicTable()
    self.AssetItems = {}
    local subItems = self._Control:GetSubItems(self.Id)
    if subItems and next(subItems) then
        for key, item in pairs(subItems) do
            local go = XUiHelper.Instantiate(self.TxtCurrentElectric.gameObject, self.TxtCurrentElectric.transform
                .parent)
            local text = go:GetComponent(typeof(CS.UnityEngine.UI.Text))
            text.text = XDataCenter.ItemManager.GetCount(item)
            local icon = go.transform:Find("CurrencyIcon"):GetComponent(typeof(CS.UnityEngine.UI.RawImage))
            icon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(item))
            self.AssetItems[item] = text
        end
    end
    self:Refresh()
end

function XUiCommonPopupUsePackage:Refresh()
    for itemId, value in pairs(self.AssetItems) do
        value.text = XDataCenter.ItemManager.GetCount(itemId)
    end
    self.TxtCurrentElectric.text = XDataCenter.ItemManager.GetCount(self.Id)
    local currencyIcon = self.TxtCurrentElectric.transform:Find("CurrencyIcon"):GetComponent(typeof(CS.UnityEngine.UI
        .RawImage))
    currencyIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.Id))
    self:SetupDynamicTable()

    self.SubItems = {}
    if not self.PackageItems then
        self.PackageItems = {}
    end
    for _, item in pairs(self.PackageItems) do
        item.gameObject:SetActiveEx(false)
    end
    self.TxtElectricNumPackage.gameObject:SetActiveEx(false)
end

function XUiCommonPopupUsePackage:AddBtnCallBack()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
    self.BtnCancel:AddEventListener(handler(self, self.Close))
    self.BtnElectricExchange:AddEventListener(handler(self, self.OnBtnShowTypeClick))
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
end

function XUiCommonPopupUsePackage:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.ElectricPackageScroll)
    self.DynamicTable:SetProxy(XUiCommonPopupUsePackageGridCommonPopUp)
    self.DynamicTable:SetDelegate(self)
    self.GridCommonPopUp.gameObject:SetActiveEx(false)
end

function XUiCommonPopupUsePackage:SetupDynamicTable()
    self.ListDatas = self._Control:GetItemUsePackages(self.Id)
    self.DynamicTable:SetDataSource(self.ListDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiCommonPopupUsePackage:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.ListDatas[index], self, index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiCommonPopupUsePackage:OnBtnShowTypeClick()
    self:Close()
    XLuaUiManager.Open("UiCommonPopupBuyAsset", self.Id, self.SuccessCallback, self.ChallengeCountData, self.BuyAmount)
end

function XUiCommonPopupUsePackage:OnItemBtnClick(itemid, count)
    self.SubItems[itemid] = count

    self:SetTxtElectricNumPackage()
end

function XUiCommonPopupUsePackage:SetTxtElectricNumPackage()
    local nums = {}
    for itemid, count in pairs(self.SubItems) do
        local template = XDataCenter.ItemManager.GetItemTemplate(itemid)
        if not template or not template.SubTypeParams then
            goto continue
        end
        local rewardIndex = 2
        if not template.SubTypeParams[rewardIndex] then
            goto continue
        end
        local goodsList = XRewardManager.GetRewardList(template.SubTypeParams[rewardIndex])
        if not goodsList then
            goto continue
        end

        for _, good in pairs(goodsList) do
            local num = good.Count * count
            local goodItemId = good.TemplateId
            if not self.PackageItems[goodItemId] then
                local go = XUiHelper.Instantiate(self.TxtElectricNumPackage.gameObject,
                    self.TxtElectricNumPackage.transform.parent)
                local text = go:GetComponent(typeof(CS.UnityEngine.UI.Text))
                local icon = go.transform:Find("Icon"):GetComponent(typeof(CS.UnityEngine.UI.RawImage))
                self.PackageItems[goodItemId] = { text = text, icon = icon, gameObject = go }
            end
            nums[goodItemId] = (nums[goodItemId] or 0) + num
        end
        ::continue::
    end
    for itemid, itemUi in pairs(self.PackageItems) do
        local num = nums[itemid]
        itemUi.gameObject:SetActiveEx(num and num > 0)
        if num > 0 then
            itemUi.gameObject:SetActiveEx(true)
            itemUi.text.text = num
            itemUi.icon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(itemid))
        end
    end
end

function XUiCommonPopupUsePackage:OnBtnConfirmClick()
    local totalRewardGoodsList = {}
    local useItemCount = 0
    local addRewardGoodsListCallback = function(rewardGoodsList)
        useItemCount = useItemCount - 1
        for key, value in pairs(rewardGoodsList) do
            table.insert(totalRewardGoodsList, value)
        end
        if useItemCount <= 0 then
            XUiManager.OpenUiObtain(totalRewardGoodsList)
            self:Refresh()
            if self.SuccessCallback then
                self.SuccessCallback()
            end
        end
    end
    for itemid, count in pairs(self.SubItems) do
        if count <= 0 then
            goto continue
        end
        local recycleTime = XDataCenter.ItemManager.GetRecycleLeftTime(itemid)
        XDataCenter.ItemManager.Use(itemid, recycleTime, count, addRewardGoodsListCallback)
        useItemCount = useItemCount + 1
        ::continue::
    end
end

return XUiCommonPopupUsePackage
