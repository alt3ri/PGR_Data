local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10252040 : XTheatre6SkillBase
local XBuffScript10252040 = XDlcScriptManager.RegBuffScript(10252040, "XBuffScript10252040", XTheatre6SkillBase)

--效果说明：本场战斗中我方生命值首次低于20%时触发：
--· 自身每有10点【拼刀】属性，扣除对手1点【体力值】。

function XBuffScript10252040:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.ChanceCheck = 0
    --self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
end

function XBuffScript10252040:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcAttribValue(self._npcUUID,ENpcAttrib.Life) * 5
    --self:LogError("Life*5=***"..self.originAttrib1)
    self.originAttrib2 = self._proxy:GetNpcAttribMaxValue(self._npcUUID,ENpcAttrib.Life)
    --self:LogError("MaxLife=***"..self.originAttrib2)
    if self.originAttrib1 <= self.originAttrib2 then
        if self.ChanceCheck == 0 then
            self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
            --self:LogError("RequestHappened***")
            self.ChanceCheck = 1
        end
    end
end

function XBuffScript10252040:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib3 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint) // 10
    self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.originAttrib3, 0)
end

return XBuffScript10252040

--调试打印不要提交到线上
--扣除对方体力值这件事翰林是做在技能结束通知里面的, 两边讨论一下看看要不要对齐
--其实也可以做在那个指定的子弹上, 再加个通知就行