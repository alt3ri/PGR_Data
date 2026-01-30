local XUiGridTheatre5Container = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Container')

--- 商店容器派生 - 宝珠槽位
---@class XUiGridTheatre5ShowGemSlot: XUiGridTheatre5Container
local XUiGridTheatre5ShowGemSlot = XClass(XUiGridTheatre5Container, 'XUiGridTheatre5ShowGemSlot')

---@overload
function XUiGridTheatre5ShowGemSlot:OnStart()
    XUiGridTheatre5Container.OnStart(self)
    self:InitBindItem()
    if self.PanelUnlockPrice then
        self.PanelUnlockPrice.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5ShowGemSlot:SetLockShow(isLock)
    self.IsLock = isLock

    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(isLock)
    end
end



return XUiGridTheatre5ShowGemSlot