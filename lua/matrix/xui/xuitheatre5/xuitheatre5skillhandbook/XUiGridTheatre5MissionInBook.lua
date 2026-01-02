local XUiGridTheatre5Item = require("XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Item")

---@class XUiGridTheatre5MissionInBook:XUiGridTheatre5Item
local XUiGridTheatre5MissionInBook = XClass(XUiGridTheatre5Item, 'XUiGridTheatre5MissionInBook')

function XUiGridTheatre5MissionInBook:RefreshShow(data)
    XUiGridTheatre5Item.RefreshShow(self, data)

    if self.RawImgLock then
        self.RawImgLock.gameObject:SetActiveEx(not data.IsUnlock)
    end
end

return XUiGridTheatre5MissionInBook