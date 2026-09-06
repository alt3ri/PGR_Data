--- 敌人基本详情，对标节点引用：PanelTop
---@class XUiPanelPunishaarEnemyBase: XUiNode
---@field protected _Control
---@field Parent
---@field TxtCardName UnityEngine.UI.Text 敌人名（Enemy.EnemyName）
---@field TxtDamageNum UnityEngine.UI.Text ATK（Fight.ATK）
---@field TxtCdNum UnityEngine.UI.Text CD（Fight.CD/1000 秒，保留一位小数）
---@field RImgHead UnityEngine.UI.RawImage 敌人头像（Enemy.EnemyHead）
local XUiPanelPunishaarEnemyBase = XClass(XUiNode, "XUiPanelPunishaarEnemyBase")

--- 刷新敌人基础信息：fightId → Fight+Enemy 表取数值+表现 #69
---@param fightId number
function XUiPanelPunishaarEnemyBase:Refresh(fightId)
    local gc = self._Control and self._Control.GameControl
    if not gc or not fightId then return end
    local fightCfg = gc:GetTablePunishaarFight(fightId, true)
    local enemyCfg = fightCfg and gc:GetTablePunishaarEnemy(fightCfg.EnemyId, true)
    if self.TxtCardName then
        self.TxtCardName.text = (enemyCfg and enemyCfg.EnemyName) or ""
    end
    if self.TxtDamageNum then
        self.TxtDamageNum.text = tostring((fightCfg and fightCfg.ATK) or 0)
    end
    if self.TxtCdNum then
        self.TxtCdNum.text = (fightCfg and fightCfg.CD)
            and string.format("%.1f", fightCfg.CD / 1000) or "0"
    end
    if self.RImgHead and enemyCfg and not string.IsNilOrEmpty(enemyCfg.EnemyHead) then
        self.RImgHead:SetRawImage(enemyCfg.EnemyHead)
    end
end

return XUiPanelPunishaarEnemyBase