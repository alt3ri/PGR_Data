---@class XUiPBRSettlementUiModel: XUiNode
---@field protected _Control
---@field Parent
local XUiPBRSettlementUiModel = XClass(XUiNode, "XUiPBRSettlementUiModel")

function XUiPBRSettlementUiModel:RefreshShowBySettle(isWin)
    if self.Di then
        self.Di.gameObject:SetActiveEx(isWin)
    end

    if self.Di2 then
        self.Di2.gameObject:SetActiveEx(not isWin)
    end
end

return XUiPBRSettlementUiModel