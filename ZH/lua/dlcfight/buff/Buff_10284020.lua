local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10284020 : XTheatre6SkillBase
local XBuffScript10284020 = XDlcScriptManager.RegBuffScript(10284020, "XBuffScript10284020", XTheatre6SkillBase)

--效果说明：· 获得3层<暴击>。
--· {被动}本局游戏中每次造成【暴击】时，获得10点【体力值】，并扣除对手等量【体力值】。

function XBuffScript10284020:ScriptInit(isGainControl) --初始化
    self._stackbuff = 1028101
    self._stackCount = 3
    self._critController = self:GetNpc():GetCritController()
    --self:LogError(".....初始化完成")
    self.SkillChanceCheck = 0
    self.TLRecover = 10
    self.TLCost = 10
end

function XBuffScript10284020:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    self.SkillChanceCheck = 0
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._critController:AddSkillCount(self._stackCount)
end

function XBuffScript10284020:OnLuaAffixCritDamage(eventArgs)
    --self:LogError(".....抓到暴击")
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.SkillChanceCheck == 0 then
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复自己N体力
        self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.TLCost, 0) --扣除对面N体力
        self.SkillChanceCheck = 1
    end
end

return XBuffScript10284020