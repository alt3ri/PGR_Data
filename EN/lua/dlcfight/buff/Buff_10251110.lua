local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251110 : XTheatre6SkillBase
local XBuffScript10251110 = XDlcScriptManager.RegBuffScript(10251110, "XBuffScript10251110", XTheatre6SkillBase)

--效果说明：
--· 【体力】属性>120点时，额外获得1层<坚毅>  。

function XBuffScript10251110:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.TargetTL = 120
    --self:LogError(".....初始化完成")
    self._stackCount = 1
    --self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -30, 0)
    self._blockController = self:GetNpc():GetBlockController()
    ------------执行------------
    --self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
end

function XBuffScript10251110:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.Stamina)
    --self:LogError(".....抓到拼刀属性"..self.originAttrib1)
    if self.originAttrib1 > self.TargetTL then
        self._blockController:AddSkillCount(self._stackCount)
    end
        --self:LogError(".....扣了敌人超算？"..self._enemyUUID)
end

return XBuffScript10251110
