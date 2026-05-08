local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10252060 : XTheatre6SkillBase
local XBuffScript10252060 = XDlcScriptManager.RegBuffScript(10252060, "XBuffScript10252060", XTheatre6SkillBase)

--效果说明：释放【拼刀成功技能】后触发：
--· 造成3层【点燃】。

function XBuffScript10252060:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._stackCountBurn = 3
    --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025105,1,0, 3)
end

function XBuffScript10252060:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Wrestle then return end
    self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
end

function XBuffScript10252060:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self:GetEnemyNpc():GetBurnController():CastStackBuff(self._stackCountBurn, self._enemyUUID)
end

return XBuffScript10252060

--19行的3最好写成ETheatre6SkillType.Wrestle,已改
--19行skillType应该为_skillType, 已改. 需要检查一下为啥会出现这种错误