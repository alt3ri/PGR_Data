local XUiPBRCommonRolePanelStatus = require('XUi/XUiPBRGame/CommonUiTemplate/CharacterStatusPanel/XUiPBRCommonRolePanelStatus')

---@class XUiPBRPauseUiPBRPanelStatus : XUiPBRCommonRolePanelStatus
---@field _Control XPBRGameControl
local XUiPBRPauseUiPBRPanelStatus = XClass(XUiPBRCommonRolePanelStatus, "XUiPBRPauseUiPBRPanelStatus")

---@overload
function XUiPBRPauseUiPBRPanelStatus:OnStart()
    self.CustomCharId = self._Control.InGameControl:GetCurSelectCharId()

    self:InitComponents()
end

---@overload
function XUiPBRPauseUiPBRPanelStatus:GetPanelAttributeCls()
    return require('XUi/XUiPBRGame/XUiPBRPause/RoleDetail/XUiPBRPauseListAttribute')
end

---@overload
function XUiPBRPauseUiPBRPanelStatus:GetPanelExclusiveCls()
    return require('XUi/XUiPBRGame/XUiPBRPause/RoleDetail/XUiPBRPauseListExclusive')
end

return XUiPBRPauseUiPBRPanelStatus
