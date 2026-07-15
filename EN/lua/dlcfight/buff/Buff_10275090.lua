local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10275090 : XTheatre6SkillBase
local XBuffScript10275090 = XDlcScriptManager.RegBuffScript(10275090, "XBuffScript10275090", XTheatre6SkillBase)

--效果说明：
--· 下一次使用技能后，返还消耗体力的20%。未实现。

function XBuffScript10275090:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self.BuffId = 10255091 --返还体力buff
    self.Count = 0
end

function XBuffScript10275090:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if self.SkillCount == 1 then
        self.SkillCount = 0
        self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.BuffId, 1)
    end
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
    self.SkillCount = 1
end

return XBuffScript10275090
