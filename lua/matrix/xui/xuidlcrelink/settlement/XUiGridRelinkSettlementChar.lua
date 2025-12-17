local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
---@class XUiGridRelinkSettlementChar : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiRelinkSettlement
local XUiGridRelinkSettlementChar = XClass(XUiNode, "XUiGridRelinkSettlementChar")

function XUiGridRelinkSettlementChar:OnStart(case)
    ---@type XUiPanelRoleModel
    self.RoleModel = XUiPanelRoleModel.New(case, self.Parent.Name, nil, true)
end

---@param player XWorldPlayerData
function XUiGridRelinkSettlementChar:Refresh(player)
    local isSelf = player.Id == XPlayer.Id
    self.BtnInfo.gameObject:SetActiveEx(true)
    self.BtnInfo:SetButtonState(isSelf and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.BtnInfo:SetNameByGroup(0, player.Name)
    self.ImgView.gameObject:SetActiveEx(not isSelf)
    self.ImgMedalIcon.gameObject:SetActiveEx(player.IsLeader)

    self.RoleModel:ShowRoleModel()
    self.RoleModel:UpdateCharacterModel(player.Id, nil, self.Parent.Name, nil, nil)
end

return XUiGridRelinkSettlementChar
