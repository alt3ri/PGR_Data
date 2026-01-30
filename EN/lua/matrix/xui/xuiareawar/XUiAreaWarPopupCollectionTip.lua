
---@class XUiAreaWarPopupCollectionTip : XLuaUi
---@field private _Control XAreaWarControl
local XUiAreaWarPopupCollectionTip = XLuaUiManager.Register(XLuaUi, "UiAreaWarPopupCollectionTip")

function XUiAreaWarPopupCollectionTip:OnAwake()
    self:RegisterUiEvents()

    local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
    ---@type XUiGridAreaWarItem
    self.GridAreaWarItem = XUiGridAreaWarItem.New(self.GridItem, self)
end

function XUiAreaWarPopupCollectionTip:OnStart(itemId)
    self.ItemId = itemId
end

function XUiAreaWarPopupCollectionTip:OnEnable()
    self:Refresh()
end

function XUiAreaWarPopupCollectionTip:OnDisable()
    
end

function XUiAreaWarPopupCollectionTip:OnDestroy()
    
end

function XUiAreaWarPopupCollectionTip:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSell, self.OnBtnSellClick)
    self:RegisterClickEvent(self.BtnGetBuy, self.OnBtnGetBuyClick)
    self:RegisterClickEvent(self.BtnGetFight, self.OnBtnGetFightClick)
end

function XUiAreaWarPopupCollectionTip:OnBtnCloseClick()
    self:Close()
end

function XUiAreaWarPopupCollectionTip:OnBtnSellClick()
    local ownNum = self._Control:GetItemRoom():GetItemNum(self.ItemId)
    if ownNum == 0 then return end
    
    local itemId = self.ItemId
    self:Close()
    XMVCA.XAreaWar:RequestAreaWar4AuctionInfo(function()
        XLuaUiManager.Open("UiAreaWarPopupSell", itemId)
    end)
end

function XUiAreaWarPopupCollectionTip:OnBtnGetBuyClick()
    local itemId = self.ItemId
    self:Close()
    XLuaUiManager.Open("UiAreaWarAuction", itemId)
end

function XUiAreaWarPopupCollectionTip:OnBtnGetFightClick()
    local blockId = XDataCenter.AreaWarManager.GetNextFightingBlockId()
    self:Close()
    XLuaUiManager.OpenSingleUi("UiAreaWarMain", blockId)
    XLuaUiManager.Remove("UiAreaWarCollection")
    XLuaUiManager.Remove("UiAreaWarRare")
    XLuaUiManager.Remove("UiAreaWarAuction")
    XLuaUiManager.Remove("UiAreaWarStageDetail")
end

function XUiAreaWarPopupCollectionTip:Refresh()
    self.GridAreaWarItem:RefreshItem(self.ItemId)
    self.TxtDescription.text = self._Control:GetConfig():GetItemDesc(self.ItemId)
    
    -- 出售按钮
    local ownNum = self._Control:GetItemRoom():GetItemNum(self.ItemId)
    self.BtnSell.gameObject:SetActiveEx(ownNum > 0)
    
    -- 刷新来源列表
    local isUnlock = self._Control:IsItemUnlock(self.ItemId)
    self.PanelWayBuy.gameObject:SetActiveEx(isUnlock)
    self.PanelWayFight.gameObject:SetActiveEx(isUnlock)
    self.PanelLock.gameObject:SetActiveEx(not isUnlock)
    if not isUnlock then
        local tips = XAreaWarConfigs.GetItemDetailUnlockTips()
        local unlockLv = self._Control:GetConfig():GetItemUnlockLv(self.ItemId)
        self.TxtLock.text = string.format(tips, unlockLv)
    end
end

return XUiAreaWarPopupCollectionTip
