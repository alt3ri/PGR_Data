local XUiButtonLongClick = require("XUi/XUiCommon/XUiButtonLongClick")

---@class XUiGridBWDelivery
---@field GridCommon XUiGridBWItem
---@field Parent XUiPanelBWDelivery | XUiPanelBWDeliveryBag
local XUiGridBWDelivery = XClass(XUiNode, "XUiGridBWDelivery")

local GridType = {
    Bag = 1,
    Deliver = 2
}

local ColorEnum = {
    Normal = XUiHelper.Hexcolor2Color("FFFFFF"),
    Red = XUiHelper.Hexcolor2Color("FF3D41")
}

function XUiGridBWDelivery:OnStart()
    self.GridCommon = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem").New(self.UiBigWorldGridCommon01, self)
    self.GridCommon:SetClickState(false)
    self._LongClickHandler = XUiButtonLongClick.New(self.Transform, 1000, self, self.OnClickItem, self.OnLongClick, self.OnLongPressUp, false)
    self.BtnDelete:AddEventListener(handler(self, self.OnClickDelete))
end

function XUiGridBWDelivery:RefreshBag(data)
    local count, consume = data.Count, data.Consume
    local params = XMVCA.XBigWorldService:GetQuestItemParams(data.Id)
    self.GridCommon:RefreshName(nil)
    self.GridCommon:RefreshIcon(params.Icon)
    self.GridCommon:RefreshQualityByQuality(params.Quality)
    
    self.ImgMask.gameObject:SetActiveEx(count <= 0)
    local isSelect = consume > 0
    self.PanelSelect.gameObject:SetActiveEx(isSelect)
    local countStr = isSelect and string.format("%d/%d", consume, count) or count
    self.GridCommon:RefreshCount(countStr)
    self.Data = data
    self.GridType = GridType.Bag
end

function XUiGridBWDelivery:Update(data)
    local count, need = data.Count, data.NeedCount
    local params = XMVCA.XBigWorldService:GetQuestItemParams(data.Id)
    local isManual = self.Parent:IsManualDeliver()
    if count <= 0 and isManual then
        self.GridCommon:Close()
        self.PanelNone.gameObject:SetActiveEx(true)
        self.BtnDelete.gameObject:SetActiveEx(false)
        self.ImgMask.gameObject:SetActiveEx(false)
    else
        self.ImgMask.gameObject:SetActiveEx(count <= 0)
        self.PanelNone.gameObject:SetActiveEx(false)
        self.BtnDelete.gameObject:SetActiveEx(isManual)
        self.GridCommon:Open()
        self.GridCommon:RefreshName(nil)
        self.GridCommon:RefreshIcon(params.Icon)
        self.GridCommon:RefreshQualityByQuality(params.Quality)
        local countStr = string.format("%d/%d", count, need)
        self.GridCommon:RefreshCount(countStr)
        local color = count >= need and ColorEnum.Normal or ColorEnum.Red
        self.GridCommon:RefreshCountColor(color)
    end
    
    self.Data = data
    self.GridType = GridType.Deliver
end

function XUiGridBWDelivery:OnClickItem()
    if GridType.Bag == self.GridType then
        self.Parent:DoBagToDeliver(self.Data)
    elseif GridType.Deliver == self.GridType and self.Data.Count > 0 then
        XMVCA.XBigWorldUI:OpenGoodsInfo(self.Data.Id)
    end
end

function XUiGridBWDelivery:OnLongClick(pressTime)
    if self.IsLongClick then
        return
    end
    self.IsLongClick = true
    XMVCA.XBigWorldUI:OpenGoodsInfo(self.Data.Id)
end

function XUiGridBWDelivery:OnLongPressUp()
    self.IsLongClick = false
end

function XUiGridBWDelivery:OnClickDelete()
    if GridType.Deliver == self.GridType then
        self.Parent:DoDeliverToBag(self.Data, false)
    elseif GridType.Bag == self.GridType then
        self.Parent:DoDeliverToBag(self.Data, true)
    end
end

return XUiGridBWDelivery