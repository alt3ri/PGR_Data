local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

--累计使用10/8/6次技能后触发：
-- · 造成2*50%攻击伤害；
-- · 必定【暴击】。
-- · 获得1层<心眼>。
---@class XBuffScript.10251605 : XTheatre6SkillBase
local XBuff10251605 = XDlcScriptManager.RegBuffScript(10251605, "XBuffScript10251605", XTheatre6SkillBase)

function XBuff10251605:ScriptInit(isGainControl) --初始化
    ---技能使用计次
    self.skillCount = 0
    if self._skillId == 10252081 then self.targetCount = 10
    else if self._skillId == 10252082 then self.targetCount = 8
        else self.targetCount = 6
        end
    end
    ---添加心眼层数
    self._stackCount = 1
    self._critController = self:GetNpc():GetCritController()
end

function XBuff10251605:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then
        ---如果不是自己释放，则技能计数+1
        self.skillCount = self.skillCount + 1
        ---如果技能技术>=8，则调用技能，获得心眼
        if self.skillCount >= self.targetCount then
            self.skillCount = 0
            self._level:RequestInsertSkill(self._npcUUID, self._skillId) --调用技能
            return self._critController:AddSkillCount(1)
        end
    elseif eventArgs._skillId == self._skillId then
        ---如果是自己释放，释放完毕后，获得心眼
        return self._critController:AddSkillCount(1)
    end
end

return XBuff10251605
