local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")

---超限启航·角色详情左侧选角格子：领航员显示 PanelLeader、隐藏体力条；普通角色显示体力条
---@class XUiTransfiniteTowerRoleGrid : XUiBattleRoomRoleGrid
---@field PanelLeader UnityEngine.GameObject
---@field PanelStaminaBar UnityEngine.GameObject
---@field ImgStaminaExpFill UnityEngine.UI.Image
local XUiTransfiniteTowerRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiTransfiniteTowerRoleGrid")

function XUiTransfiniteTowerRoleGrid:SetData(entity, ...)
    XUiBattleRoomRoleGrid.SetData(self, entity, ...)
    local entityId = entity:GetId()
    local isLeader = XMVCA.XTransfiniteTower:IsLeaderEntity(entityId)
    self.PanelLeader.gameObject:SetActiveEx(isLeader)
    -- 领航员不显示体力条；普通角色显示并按剩余体力填充
    self.PanelStaminaBar.gameObject:SetActiveEx(not isLeader)
    if not isLeader then
        local ratio, energy = XMVCA.XTransfiniteTower:GetEntityStaminaRatio(entityId)
        self.ImgStaminaExpFill.fillAmount = ratio
        self.ImgStaminaExpFill.color = XMVCA.XTransfiniteTower:GetEnergyColor(energy)
    end
end

return XUiTransfiniteTowerRoleGrid
