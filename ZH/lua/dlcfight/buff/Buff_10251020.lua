local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251020 : XTheatre6SkillBase
local XBuffScript10251020 = XDlcScriptManager.RegBuffScript(10251020, "XBuffScript10251020", XTheatre6SkillBase)

--效果说明：【拼刀】属性>10点时，额外造成【击飞】。

function XBuffScript10251020:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.ChanceCheck = 0
    self._stackCount = 1
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self:LogError(".....初始化完成")
end

function XBuffScript10251020:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.WrestlePoint)
    self:LogError(".....抓到拼刀属性"..self.originAttrib1)
    if self.originAttrib1 > 300 then
        --self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
        self._HitFlyController:AddSkillCount(self._stackCount)
    end
end

return XBuffScript10251020