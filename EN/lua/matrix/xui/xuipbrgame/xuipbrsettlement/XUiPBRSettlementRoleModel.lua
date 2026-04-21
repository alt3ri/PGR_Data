local XUiPBRRoleModel = require("XUi/XUiPBRGame/XUiPBRCharacterDetail/XUiPBRRoleModel")

---@class XUiPBRSettlementRoleModel: XUiPBRRoleModel
---@field protected _Control
---@field Parent
local XUiPBRSettlementRoleModel = XClass(XUiPBRRoleModel, "XUiPBRSettlementRoleModel")
local XUiPBRSettlementUiModel = require("XUi/XUiPBRGame/XUiPBRSettlement/XUiPBRSettlementUiModel")

function XUiPBRSettlementRoleModel:OnStart()
    XUiPBRRoleModel.OnStart(self)
    
    self.UiModelNode = XUiPBRSettlementUiModel.New(self.Parent.UiModelGo, self)
end

function XUiPBRSettlementRoleModel:RefreshShowBySettle(isWin)
    self.UiModelNode:RefreshShowBySettle(isWin)
end

return XUiPBRSettlementRoleModel