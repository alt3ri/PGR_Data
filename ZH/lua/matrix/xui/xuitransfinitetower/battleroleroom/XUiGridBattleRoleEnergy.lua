---进战编队界面·体力槽（超限启航定制）：领航员显示无限标志，普通角色按剩余体力点亮 ImgEnergy
---@class XUiGridBattleRoleEnergy : XUiNode
---@field ImgEnergy1 UnityEngine.UI.Image
---@field ImgEnergy2 UnityEngine.UI.Image
---@field ImgEnergy3 UnityEngine.UI.Image
---@field ImgIconInfinite UnityEngine.GameObject
local XUiGridBattleRoleEnergy = XClass(XUiNode, "XUiGridBattleRoleEnergy")

---@param isLeader boolean 是否领航员（无限体力）
---@param energy number 普通角色剩余体力
function XUiGridBattleRoleEnergy:Refresh(isLeader, energy)
    -- 面板默认隐藏，New 时未触发 OnStart，故在此惰性缓存
    if not self._EnergyImgs then
        self._EnergyImgs = { self.ImgEnergy1, self.ImgEnergy2, self.ImgEnergy3 }
    end
    self.ImgIconInfinite.gameObject:SetActiveEx(isLeader)
    local color = not isLeader and XMVCA.XTransfiniteTower:GetEnergyColor(energy)
    for i = 1, #self._EnergyImgs do
        local img = self._EnergyImgs[i]
        local isShow = not isLeader and i <= energy
        img.gameObject:SetActiveEx(isShow)
        if isShow then
            img.color = color
        end
    end
end

return XUiGridBattleRoleEnergy
