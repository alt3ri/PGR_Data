local XUiGridTheatre5Item = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Item')

--- 回合结算技能统计
---@class XUiGridTheatre5SettleSkill: XUiGridTheatre5Item
local XUiGridTheatre5SettleSkill = XClass(XUiGridTheatre5Item, 'XUiGridTheatre5SettleSkill')

function XUiGridTheatre5SettleSkill:SetIsNormalAttack(isNormalATK)
    self.IsNormalATK = isNormalATK
end

---@overload
function XUiGridTheatre5SettleSkill:RefreshShowById(itemId)
    XUiGridTheatre5Item.RefreshShowById(self, itemId)
    
    ---@type XTableTheatre5Item
    local itemCfg = self._Control:GetTheatre5ItemCfgById(itemId)

    if itemCfg then
        if self.TxtName then
            self.TxtName.text = itemCfg.Name
        end
    end
end

---@overload
function XUiGridTheatre5SettleSkill:OnGridBtnClickEvent()
    if self.IsNormalATK then
        return
    end
    
    self.IsSelected = not self.IsSelected

    self:RefreshSelectState()

    if self.IsSelected then
        self._Control:SetItemSelected(self)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.ItemId, self.OwnerContainerType, self.Parent.DetailPos)
    else
        self._Control:SetItemSelected(nil)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
    end
end

return XUiGridTheatre5SettleSkill