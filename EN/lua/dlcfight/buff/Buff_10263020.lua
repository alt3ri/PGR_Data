local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10263020 : XTheatre6SkillBase
local XBuffScript10263020 = XDlcScriptManager.RegBuffScript(10263020, "XBuffScript10263020", XTheatre6SkillBase)

--效果说明：
--· 首次出手期间，每次【击倒】对手均将恢复自身10点【体力值】；
--· 造成5秒【晕眩】与【击倒】。

function XBuffScript10263020:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._damageMagicId = 10250016 --注册拼刀成功技1伤害id，临时
    self.TLRecover = 10
    --self:LogError(".....初始化完成")
    self._HitDownController = self:GetNpc():GetHitDownController()
    self.ChanceCheck = 0
end

function XBuffScript10263020:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    self._HitFlyController:AddSkillCount(self._stackCount)
    self._proxy:Theatre6AddNpcStun(self._enemyUUID, 5)
end

function XBuffScript10263020:OnLuaAffixHitDown(eventArgs )
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck <= 2 then
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复5体力
    end
end

function XBuffScript10263020:OnLuaAttackerChange(eventArgs)
    ------------执行------------
    self.ChanceCheck = self.ChanceCheck + 1
end

return XBuffScript10263020
