local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10282130 : XTheatre6SkillBase
local XBuffScript10282130 = XDlcScriptManager.RegBuffScript(10282130, "XBuffScript10282130", XTheatre6SkillBase)

-- 效果说明：每累计使用5次【触发技能】时触发：
--· 造成100%攻击伤害；
--· 获得1/2/3层<暴击>；
--· 获得7点【魅惑】，首次使用时，额外获得6点【魅惑】。

---脚本初始化函数
---@param isGainControl boolean 是否获得控制权
function XBuffScript10282130:ScriptInit(isGainControl)
    --XTheatre6SkillBase.ScriptInit(self, isGainControl)
    self._hypnoController = self:GetNpc():GetHypnoController()
    self._stackCountHypnoFirst = 6
    --self._stackCountCrit = 1
    self._stackCountCrit = {
        [1] = 1,
        [2] = 2,
        [3] = 3
    }
    self._stackCountHypno = 7
    self._SkillCount = 0
    self._SkillCountTarget = 5
    self._ChanceCheck = 0
    self._critController = self:GetNpc():GetCritController()
end



function XBuffScript10282130:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    -- 查技能表原始Type，排除被RequestInsertSkill覆盖的主动技能
    local skillConfig = self._proxy:Theatre6GetSkillConfig(eventArgs._skillId)
    if skillConfig.Type == ETheatre6SkillType.Insert then
        self._SkillCount = self._SkillCount + 1
        --self:LogError(".....抓到触发技能")
        if self._SkillCount == self._SkillCountTarget then
            self._level:RequestInsertSkill(self._npcUUID, self._skillId)
            self._SkillCount = 0
        end
    end

    if eventArgs._skillId ~= self._skillId then return end
    self._hypnoController:CastStackBuff(self._stackCountHypno, self._npcUUID)
    if self._ChanceCheck == 0 then
        self._hypnoController:CastStackBuff(self._stackCountHypnoFirst, self._npcUUID)
        self._ChanceCheck = 1
    end
end

function XBuffScript10282130:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self._critController:AddSkillCount(self._stackCountCrit[self._lv])
end

return XBuffScript10282130
