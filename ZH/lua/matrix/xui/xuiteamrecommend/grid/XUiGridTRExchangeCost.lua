-- 引用LuaUi：UiTeamRecommendExchangeCostPopup
---@class XUiGridTRExchangeCost : XUiNode
local XUiGridTRExchangeCost = XClass(XUiNode, "XUiGridTRExchangeCost")

function XUiGridTRExchangeCost:OnStart()
    self.NormalUiObj = XTool.InitUiObjectByUi({}, self.Normal)
    self.SelectUiObj = XTool.InitUiObjectByUi({}, self.Select)

    self.BtnBuy.CallBack = function() self.Parent:OnSelectRoute(self.Index) end
end

function XUiGridTRExchangeCost:Refresh(route, index, selectedIndex)
    self.Index = index

    local isSelect = index == selectedIndex
    self.NormalUiObj.Icon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(route.ConsumeId))
    self.SelectUiObj.Icon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(route.ConsumeId))
    self.Normal.gameObject:SetActiveEx(not isSelect)
    self.Select.gameObject:SetActiveEx(isSelect)
    self:RefreshConsumeCount(route.ConsumeId, route.ConsumeCount)
end

function XUiGridTRExchangeCost:RefreshConsumeCount(itemId, count)
    local text = CS.XTextManager.GetText("ShopGridCommonCount", count)
    local isEnough = XDataCenter.ItemManager.GetCount(itemId) >= count
    local color = isEnough and CS.UnityEngine.Color.black or CS.UnityEngine.Color.red
    self.NormalUiObj.TxtNum.text = text
    self.SelectUiObj.TxtNum.text = text
    self.NormalUiObj.TxtNum.color = color
    self.SelectUiObj.TxtNum.color = color
end

return XUiGridTRExchangeCost
