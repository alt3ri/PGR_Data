local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---当前技能结束后, 给自身角色叠加三层心眼
---@class XBuffScript.1025401 : XTheatre6SkillBase
local XBuff1025401 = XDlcScriptManager.RegBuffScript(1025401, "XBuffScript1025401", XTheatre6SkillBase)

function XBuff1025401:ScriptInit(isGainControl) --初始化
    self._count = 5
    self._stackCount = 3
    self._critController = self:GetNpc():GetCritController()
end

-- function XBuff1025401:OnLuaSkillStart(eventArgs)
-- self:LogError("SkillStart")
-- end

function XBuff1025401:OnLuaSkillEnd(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._count = self._count + 1
    if self._count < 3 then return end
    self._count = 0
    return self._critController:AddSkillCount(self._stackCount)
end

-- function XBuff1025401:OnLuaAttackerChange(eventArgs)
--     self:LogError("attacker change")
-- end

-- function XBuff1025401:OnLuaAffixCritDamage(eventArgs)
--     self:LogError("crit damage")
-- end

return XBuff1025401