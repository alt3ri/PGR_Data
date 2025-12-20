local CSUiButtonState = CS.UiButtonState
local stringFormat = string.format

---@class XUiGridAreaWarBuyItem : XUiNode
---@field private _Control XAreaWarControl
local XUiGridAreaWarBuyItem = XClass(XUiNode, "XUiGridAreaWarBuyItem")

function XUiGridAreaWarBuyItem:OnStart()
    local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
    ---@type XUiGridAreaWarItem
    self.GridAreaWarItem = XUiGridAreaWarItem.New(self.Transform, self)
end

function XUiGridAreaWarBuyItem:Init()
    -- 刷新代币图标
    local icon = XItemConfigs.GetItemIconById(XDataCenter.ItemManager.ItemId.AreaWarAuctionCoin)
    self.Normal:GetObject("RImgToken"):SetRawImage(icon)
    self.Press:GetObject("RImgToken"):SetRawImage(icon)
    self.Disable:GetObject("RImgToken"):SetRawImage(icon)
end

-- 设置道具Id
function XUiGridAreaWarBuyItem:SetItemId(itemId)
    self.ItemId = itemId
    self:Refresh()
end

-- 刷新道具，基于拥有数量的显示
function XUiGridAreaWarBuyItem:Refresh()
    local auction = self._Control:GetAuction()
    local isUnlock = self._Control:IsItemUnlock(self.ItemId)
    local isExit = auction:IsExitItem(self.ItemId)
    local isDisable = not isUnlock or not isExit
    
    -- 刷新道具
    self.GridAreaWarItem:RefreshItem(self.ItemId)
    
    -- 刷新价格
    local price = isDisable and self._Control:GetConfig():GetAuctionBasePrice(self.ItemId) or auction:GetItemMinPrice(self.ItemId)
    self.Normal:GetObject("TxtPrice").text = price
    self.Press:GetObject("TxtPrice").text = price
    self.Disable:GetObject("TxtPrice").text = price
    
    -- 未解锁/交易行未存在商品
    self.Button:SetButtonState(isDisable and CSUiButtonState.Disable or CSUiButtonState.Normal)
    if isDisable then
        if not isUnlock then
            self.Disable:GetObject("TxtTips").gameObject:SetActiveEx(false)
            self.Disable:GetObject("ImgLock").gameObject:SetActiveEx(true)
            local unlockLv = self._Control:GetConfig():GetItemUnlockLv(self.ItemId)
            local unlockTips = XAreaWarConfigs.GetItemUnlockTips()
            self.Disable:GetObject("TxtLock").text = stringFormat(unlockTips, unlockLv)
        elseif not isExit then
            self.Disable:GetObject("TxtTips").gameObject:SetActiveEx(false)
            self.Disable:GetObject("ImgLock").gameObject:SetActiveEx(true)
            self.Disable:GetObject("TxtLock").text = XAreaWarConfigs.GetAuctionBuyNoEnoughShopTips()
        end
    end
end

return XUiGridAreaWarBuyItem
