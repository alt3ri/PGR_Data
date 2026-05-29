local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251120 : XTheatre6SkillBase
local XBuffScript10251120 = XDlcScriptManager.RegBuffScript(10251120, "XBuffScript10251120", XTheatre6SkillBase)

--效果说明：
--· 恢复自身10点【体力值】。
--· 此次技能若是【暴击】，额外造成【击飞】。

function XBuffScript10251120:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.TLRecover = 10
    --self:LogError(".....初始化完成")
    self._stackbuff = 1025104
    self._critController = self:GetNpc():GetCritController()
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    --self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -30, 0)
    self._stackCount = 1
end

function XBuffScript10251120:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.Stamina)
    --self:LogError(".....抓到拼刀属性"..self.originAttrib1)
        --self:LogError(".....抓到敌人"..self._enemyUUID)
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复10体力
        --self:LogError(".....扣了敌人超算？"..self._enemyUUID)
end

function XBuffScript10251120:OnLuaSpecialHit(eventArgs)
    ------------执行------------
    if eventArgs._missileHitCount ~= 1 then return end
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._proxy:CheckBuffByKind(self._npcUUID,self._stackbuff) then
        self._HitFlyController:AddSkillCount(self._stackCount)
        --self:LogError("1120触发了击飞附魔")
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,1025194)
    end
end

return XBuffScript10251120

--没有对释放的技能进行过滤. 所有技能都会触发此词条    已修，技能重做了