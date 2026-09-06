--- 战前双方基本信息显示：头像 + 名称 + HP。
--- 双方（玩家方/敌方）各实例化一个，挂 PanelFightBefore 的 UiPunishaarRoleHp / UiPunishaarEnemyHp 节点。
---@class XUiGridPunishaarRoleShow: XUiNode
---@field protected _Control
---@field Parent
---@field RImgHead UnityEngine.UI.RawImage 头像图（角色 Icon）
---@field TxtName UnityEngine.UI.Text 名称文本
---@field TxtHp UnityEngine.UI.Text HP 数值文本
local XUiGridPunishaarRoleShow = XClass(XUiNode, "XUiGridPunishaarRoleShow")

--- 刷新双方基本信息：设头像/名称/HP（参数 nil 则不设，留原值）。
---@param icon string|nil 头像路径
---@param name string|nil 名称
---@param hp number|nil HP 数值
function XUiGridPunishaarRoleShow:Refresh(icon, name, hp)
    if self.RImgHead and not string.IsNilOrEmpty(icon) then
        self.RImgHead:SetRawImage(icon)
    end
    if self.TxtName and name then
        self.TxtName.text = name
    end
    if self.TxtHp and hp ~= nil then
        self.TxtHp.text = tostring(hp)
    end
end

return XUiGridPunishaarRoleShow