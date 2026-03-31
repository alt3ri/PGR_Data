local XUiPBRCommonRolePanelStatus = require('XUi/XUiPBRGame/CommonUiTemplate/CharacterStatusPanel/XUiPBRCommonRolePanelStatus')

---@class XUiPBRSettlementUiPBRPanelAttribute : XUiPBRCommonRolePanelStatus
---@field PanelTabGroup XUiButtonGroup
local XUiPBRSettlementUiPBRPanelAttribute = XClass(XUiPBRCommonRolePanelStatus, "XUiPBRSettlementUiPBRPanelAttribute")

---@overload
function XUiPBRSettlementUiPBRPanelAttribute:OnStart(customCharId, curAttribDict, maxAttribDict)
    self.CurAttribDict = curAttribDict
    self.MaxAttribDict = maxAttribDict
    XUiPBRCommonRolePanelStatus.OnStart(self, customCharId)
end

---@overload
function XUiPBRSettlementUiPBRPanelAttribute:GetPanelAttributeCls()
    return require('XUi/XUiPBRGame/XUiPBRSettlement/RoleDetail/XUiPBRSettlementListAttribute')
end

---@overload
function XUiPBRSettlementUiPBRPanelAttribute:GetPanelExclusiveCls()
    return require('XUi/XUiPBRGame/XUiPBRSettlement/RoleDetail/XUiPBRSettlementListExclusive')
end

return XUiPBRSettlementUiPBRPanelAttribute
