local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10253010 : XTheatre6SkillBase
local XBuffScript10253010 = XDlcScriptManager.RegBuffScript(10253010, "XBuffScript10253010", XTheatre6SkillBase)

--效果说明：本场战斗中每次造成【击飞】时，自身【拼刀】属性提升10点；造成5秒【晕眩】。

function XBuffScript10253010:ScriptInit(isGainControl) --初始化
    self._damageMagicId = 10250012 --注册拼刀成功技1伤害id
    self._buffStacks = 10 --增加10点拼刀属性
    self._stunTime = 5 --5秒眩晕
    --self:LogError("....【拼刀成功技能1】初始化完成")
    self._HitFlyController = self:GetNpc():GetHitFlyController()

end

--function XBuffScript10253010:OnLuaSkillStart(eventArgs)
    ------------执行------------
    --if eventArgs._skillId ~= self._skillId then return end
    --if eventArgs._launcherUUID ~= self._npcUUID then return end
    --self._hasChangedDamage = false
    --self._wrestlePoint = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint)
    --self:LogError(".....抓到拼刀属性"..self._wrestlePoint)
    --self._exDamageRate = self._wrestlePoint * 60
--end

function XBuffScript10253010:OnLuaAffixHitFly(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self:AddTheatre6Attrib(ETheatre6AttribType.WrestlePoint, self._buffStacks, self._npcUUID, self._npcUUID)
end

function XBuffScript10253010:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
    self._hasChangedDamage = true
end

function XBuffScript10253010:OnLuaSpecialHit(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:Theatre6AddNpcStun(eventArgs._targetUUID, self._stunTime) -- 增加5秒眩晕
    self._HitFlyController:AddSkillCount(self._stackCount)
end

return XBuffScript10253010
