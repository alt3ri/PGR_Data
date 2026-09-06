--- 单位尺寸的空格
---@class XUiGridBattleCardSlot: XUiNode
---@field protected _Control
---@field Parent
local XUiGridBattleCardSlot = XClass(XUiNode, "XUiGridBattleCardSlot")

function XUiGridBattleCardSlot:OnStart()
    if self.PanelNone then
        self.PanelNone.gameObject:SetActiveEx(true)
    end

    if self.PanelShopNone then
        self.PanelShopNone.gameObject:SetActiveEx(false)
    end
end

function XUiGridBattleCardSlot:RefreshUnlockState(isUnlock)
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(not isUnlock)
    end
end

return XUiGridBattleCardSlot
