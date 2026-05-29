---@class XUiTheatre6BattleShopGridRefresh : XUiNode
---@field _Control XTheatre6Control
---@field UiTxtNum UnityEngine.UI.Text
---@field UiTxtDesc UnityEngine.UI.Text
local XUiTheatre6BattleShopGridRefresh = XClass(XUiNode, "XUiTheatre6BattleShopGridRefresh")

local CoinStatus = {
    Free = 1,
    Enough = 2,
    NoEnough = 3
}
function XUiTheatre6BattleShopGridRefresh:InitComponents()
    self._NormalColor = self.UiTxtNum and self.UiTxtNum.color or nil
    self.BtnGrid:AddEventListener(handler(self, self.OnBtnGridClick))
end

function XUiTheatre6BattleShopGridRefresh:OnStart()
    self:InitComponents()
end
function XUiTheatre6BattleShopGridRefresh:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_GOLD_CHANGE
    }
end

function XUiTheatre6BattleShopGridRefresh:OnNotify(evt, ...)
    if evt == XEventId.EVENT_THEATRE6_GOLD_CHANGE then
        self:RefreshBuyBtnStatus()
    end
end
function XUiTheatre6BattleShopGridRefresh:Refresh()
    local freeRefreshCount = 0 --todo
    
    local refreshCount = self._Control:GetShopRefreshCount()
    local refreshTxt = XUiHelper.GetText("Theatre6ShopStatus2")
    self.BtnGrid:SetNameByGroup(1, refreshCount)--刷新次数

    self.BtnGrid:SetRawImageVisible(freeRefreshCount <= 0)
    if freeRefreshCount <= 0 then
        self.BtnGrid:SetRawImage(self._Control:GetCoinIcon())--付费刷新货币图标
        refreshTxt = XUiHelper.GetText("Theatre6ShopStatus1")
    end


    self.BtnGrid:SetDisable(refreshCount <= 0)
    if refreshCount <= 0 then
        refreshTxt = XUiHelper.GetText("Theatre6ShopStatus3")
    end
    self.BtnGrid:SetNameByGroup(0, refreshTxt)

    self:RefreshBuyBtnStatus()
end

function XUiTheatre6BattleShopGridRefresh:RefreshBuyBtnStatus()
    local price = self._Control:GetRefreshPrice()

    local coinEnough = self._Control:IsCoinEnough(price)
    local showPrice = tostring(price)

    if not coinEnough then
        showPrice = string.format("<color=#%s>%s</color>", self._Control:GetClientConfigValue("ShopRefreshColor",CoinStatus.NoEnough),price)
    end
    self.BtnGrid:SetNameByGroup(2,  showPrice)--价格
end

function XUiTheatre6BattleShopGridRefresh:OnBtnGridClick()
  local refreshCount = self._Control:GetShopRefreshCount()
  if refreshCount <= 0 then
        return
    end
    self.Parent:OnRefreshGridClick()
end

return XUiTheatre6BattleShopGridRefresh
