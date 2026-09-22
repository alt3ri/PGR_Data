local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10265090 : XTheatre6SkillBase
local XBuffScript10265090 = XDlcScriptManager.RegBuffScript(10265090, "XBuffScript10265090", XTheatre6SkillBase)

--效果说明：
--· 下一次使用技能后，返还消耗体力的20%。未实现。

function XBuffScript10265090:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self:LogError(".....初始化完成")
    self.BuffId = 10255091 --返还体力buff
    self.SkillCount = 0
end

function XBuffScript10265090:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.SkillCount == 2 then
        self.SkillCount = 0
        --self:LogError("清除回体力buff")
        self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.BuffId, 1)
    end
    if self.SkillCount == 1 then
        self.SkillCount = 2
        --self:LogError("体力skillCount=2")
    end
    if eventArgs._skillId ~= self._skillId then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
    if self.SkillCount == 0 then
        self.SkillCount = 1
        --self:LogError("体力skillCount=1")
    end
end

return XBuffScript10265090
