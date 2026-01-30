local XUiGridTheatre5Item = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Item')

---@class XUiGridTheatre5SettleNormalAtk: XUiGridTheatre5Item
local XUiGridTheatre5SettleNormalAtk = XClass(XUiGridTheatre5Item, 'XUiGridTheatre5SettleNormalAtk')

---@overload
function XUiGridTheatre5SettleNormalAtk:RefreshShowById(itemId)
    ---@type XTableTheatre5Item
    local itemCfg = self._Control:GetTheatre5ItemCfgById(itemId)

    if itemCfg then
        self.TxtName.text = itemCfg.Name
        self.ImgIcon:SetRawImage(itemCfg.IconRes)
    end
end

return XUiGridTheatre5SettleNormalAtk