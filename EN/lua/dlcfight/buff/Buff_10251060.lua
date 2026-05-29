local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251060 : XTheatre6SkillBase
local XBuffScript10251060 = XDlcScriptManager.RegBuffScript(10251060, "XBuffScript10251060", XTheatre6SkillBase)

--效果说明：前2次使用此技能时，获得1层<心眼>

function XBuffScript10251060:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.ChanceCheck = 0
    self._stackCount = 1
    --self:LogError(".....初始化完成")
    self._critController = self:GetNpc():GetCritController()
    --if self._skillId == 10251061 then self._exDamageRate = 10000
    --else if self._skillId == 10251062 then self._exDamageRate = 12000
    --else self._exDamageRate = 15000
    --end
    --end
    --self._damageMagicId = 10250022
end

--function XBuffScript10251060:OnLuaSkillStart(eventArgs)
    --每帧执行
    ------------执行------------
    --if eventArgs._skillId ~= self._skillId then return end
    --if eventArgs._launcherUUID ~= self._npcUUID then return end
    --if self.ChanceCheck == 0 then
        --self._proxy:ApplyMagic(self._uuid, self._uuid, 10251501,1,0,1)
        --self._critController:AddSkillCount(self._stackCount)
        --self._hasChangedDamage = false
    --end
--end

--function XBuffScript10251060:OnLuaAttackerChange(eventArgs)
    --self.ChanceCheck = 0
--end

--function XBuffScript10251060:ChangeDamageBeforeCalc(eventArgs)
    --if eventArgs.Launcher ~= self._npcUUID then return end
    --if eventArgs.Id ~= self._damageMagicId then return end
    --if self._hasChangedDamage then return end
    --local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    --self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
    --self._hasChangedDamage = true
--end

function XBuffScript10251060:OnLuaSkillEnd(eventArgs)
    --每帧执行
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck <= 1 then
        self._critController:AddSkillCount(self._stackCount)
        self.ChanceCheck = 1
    end
end

return XBuffScript10251060

--self._critController没有初始化    ：已改
--26行命名不对    ：已改