local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282040 : XTheatre6SkillBase
local XBuffScript10282040 = XDlcScriptManager.RegBuffScript(10282040, "XBuffScript10282040", XTheatre6SkillBase)

--效果说明： 对手每使用5次【主动技能】时触发：
--· 造成100%攻击伤害；
--· 获得3点【魅惑】。

function XBuffScript10282040:ScriptInit(isGainControl) --初始化
    --self._stackCount = 1
    self._stackCount = {
        --不同等级的默认剧毒层数
        [1] = 1,
        [2] = 2,
        [3] = 3
    }
    self.Count = 0
    self._stackCountSkill = 5
    self._hypnoController = self:GetNpc():GetHypnoController()
end

function XBuffScript10282040:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then  -- 抓对面用技能
        if eventArgs._skillType ~= ETheatre6SkillType.Main then return end -- 不是主动技能不计数
        self.Count = self.Count + 1
        if self.Count == self._stackCountSkill then
            self._level:RequestInsertSkill(self._npcUUID,self._skillId)
            self.Count = 0
        end
    elseif eventArgs._launcherUUID == self._npcUUID then
        if eventArgs._skillId ~= self._skillId then return end
        self._hypnoController:CastStackBuff(self._stackCount[self._lv], self._npcUUID)
    end
end

return XBuffScript10282040