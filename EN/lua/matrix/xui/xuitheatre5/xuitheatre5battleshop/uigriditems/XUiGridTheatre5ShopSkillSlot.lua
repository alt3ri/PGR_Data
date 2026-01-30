local XUiGridTheatre5ShopContainer = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopContainer')

--- 技能三选一的容器
---@class XUiGridTheatre5ShopSkillSlot: XUiGridTheatre5ShopContainer
---@field CurUiGrid XUiGridTheatre5ShopItem
local XUiGridTheatre5ShopSkillSlot = XClass(XUiGridTheatre5ShopContainer, 'XUiGridTheatre5ShopSkillSlot')

function XUiGridTheatre5ShopSkillSlot:RefreshShow()
    local isSelected = false
    
    if self.CurUiGrid and self.CurUiGrid.ItemData then
        -- IsSelected 字段是追加的标记字段，在ShopControl完成三选一回调后设置标记
        isSelected = self.CurUiGrid.ItemData.IsSelected

        if isSelected then
            self.CurUiGrid:Close()
        end
    end

    if self.FxBurn then
        self.FxBurn.gameObject:SetActiveEx(isSelected)
    end
end

return XUiGridTheatre5ShopSkillSlot