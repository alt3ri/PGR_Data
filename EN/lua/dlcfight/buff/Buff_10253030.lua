local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10253030 : XTheatre6SkillBase
local XBuffScript10253030 = XDlcScriptManager.RegBuffScript(10253030, "XBuffScript10253030", XTheatre6SkillBase)

--效果说明：
--· 【拼刀】属性>230点时，伤害额外提高100%攻击。
--· 造成3秒【晕眩】。

function XBuffScript10253030:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._damageMagicId = 10250016 --注册拼刀成功技3伤害id
    self._stackCountNormal = 1
    self._stackCountFirst = 3
    self.ChanceCheck = 0
    self.extraDamage = 10000
    --self:LogError(".....初始化完成")
    self._hasChangedDamage = true
end

function XBuffScript10253030:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    ------------执行------------
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.WrestlePoint)
    --self:LogError(".....抓到拼刀属性"..self.originAttrib1)
    if self.originAttrib1 > 230 then
        self._hasChangedDamage = false
        --self._proxy:ApplyMagic(self._uuid, self._uuid, 10251501,1,0,1)
    end
    self._proxy:Theatre6AddNpcStun(self._enemyUUID, 3)
end

function XBuffScript10253030:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    local finalPermyriad = self.extraDamage + eventArgs.PhysicalPermyriad
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage,eventArgs.HackPermyriad,eventArgs.IsCrit)
    self._hasChangedDamage = true
end

return XBuffScript10253030

--没有对释放的技能进行过滤, 该逻辑会在所有技能启动时触发    ：已改
--22行的applyMagic能否达成目标效果还要再确认    ：这个要测试下才知道
--24行的XDlcSharpFuncs是冗余的    ：妈的昏厥了