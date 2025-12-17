local XUiTheatre5PVEChooseRewardItem = require("XUi/XUiTheatre5/XUiTheatre5PVEPopupChooseReward/XUiTheatre5PVEChooseRewardItem")

---@field Parent XUiTheatre5PopupStrengthen
---@class XUiTheatre5PopupStrengthenItem:XUiTheatre5PVEChooseRewardItem
local XUiTheatre5PopupStrengthenItem = XLuaUiManager.Register(XUiTheatre5PVEChooseRewardItem, "UiTheatre5PopupStrengthenItem")

function XUiTheatre5PopupStrengthenItem:OnStart()
    XUiTheatre5PVEChooseRewardItem.OnStart(self)
    XUiHelper.RegisterClickEvent(self, self.BtnConfirm, self.OnClickConfirm)
    self._IsSelected = false

    self.PanelTag = self.PanelTag or XUiHelper.TryGetComponent(self.Transform, "UiTheatre5GridGem/PanelTag", "RectTransform")
    if self.PanelTag then
        self.PanelTag.gameObject:SetActiveEx(false)
    end
end

function XUiTheatre5PopupStrengthenItem:SetSelected(value)
    self._IsSelected = value

    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(value)
    end

    -- 选中后显示强化后的属性
    self:Update(self._Theatre5Item)
end

function XUiTheatre5PopupStrengthenItem:GetSelected()
    return self._IsSelected
end

function XUiTheatre5PopupStrengthenItem:OnClickConfirm()
    self.Parent:Confirm(self._Theatre5Item)
end

function XUiTheatre5PopupStrengthenItem:UpdateDesc()
    local itemCfg = self._Control:GetTheatre5ItemCfgById(self._Theatre5Item.ItemId)
    self.TxtDes.text = self._Control:GetItemDesc(itemCfg, self._IsSelected)

    if self.TxtDes02 then
        local addDesc = self._Control:GetItemAddDesc(itemCfg, self._IsSelected)
        if addDesc then
            self.TxtDes02.gameObject:SetActiveEx(true)
            self.TxtDes02.text = XMVCA.XTheatre5:GetText("StrengthenDescAdd") .. addDesc
        else
            self.TxtDes02.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTheatre5PopupStrengthenItem:GetRuneAttr()
    local runeAttrCfg = self._Control:GetRuneAttr(self._Theatre5Item, self._IsSelected)
    return runeAttrCfg
end

return XUiTheatre5PopupStrengthenItem