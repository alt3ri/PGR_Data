local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251080 : XTheatre6SkillBase
local XBuffScript10251080 = XDlcScriptManager.RegBuffScript(10251080, "XBuffScript10251080", XTheatre6SkillBase)

--扣除双方20点体力
--造成击飞

function XBuffScript10251080:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.ChanceCheck = 0
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    --self:LogError(".....初始化完成")
end

function XBuffScript10251080:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.WrestlePoint)
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -20, 0)
    --self:LogError(".....扣对面10点体力")
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -20, 0)
    --self:LogError(".....扣自己10点体力")
end


function XBuffScript10251080:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._HitFlyController:AddSkillCount(self._stackCount)
end

return XBuffScript10251080


--没有对释放的技能进行过滤. 所有技能都会触发此词条