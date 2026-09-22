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
    local gameControl = self._Control and self._Control.GameControl
    if not gameControl or not fightId then
        return
    end
    local fightCfg = gameControl:GetTablePunishaarFight(fightId, true)
    local enemyCfg = fightCfg and gameControl:GetTablePunishaarEnemy(fightCfg.EnemyId, true)
    if self.TxtCardName then
        self.TxtCardName.text = (enemyCfg and enemyCfg.EnemyName) or ""
    end
    if self.TxtDamageNum then
        -- ATK = Fight 表基础值 + 无尽关多轮次加成（同 CreateEnemyEntity 源，经 GetEnemyExtraAtk accessor 单源，对齐血量显示 PreFight:73 范式）#敌人ATK多轮次
        local atk = (fightCfg and fightCfg.ATK) or 0
        local extraAtk = self._Control:GetEnemyExtraAtk()
        self.TxtDamageNum.text = tostring(atk + extraAtk)
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