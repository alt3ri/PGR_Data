local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251090 : XTheatre6SkillBase
local XBuffScript10251090 = XDlcScriptManager.RegBuffScript(10251090, "XBuffScript10251090", XTheatre6SkillBase)

--效果说明：
--· 扣除对手10点【超算值】；
--· 扣除自身15点【体力值】，获得1层<心眼>。

function XBuffScript10251090:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.ChanceCheck = 0
    self.CSCost = 10
    if self._skillId == 10251091 then self.TLCost = 30
    else if self._skillId == 10251092 then self.TLCost = 20
    else self.TLCost = 10
    end
    end
    self.TargetCS = 0
    --self:LogError(".....初始化完成")
    self._stackCount = 1
    self._critController = self:GetNpc():GetCritController()
    self.check = 0
    --self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -30, 0)
end

function XBuffScript10251090:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.Stamina)
    --self:LogError(".....抓到拼刀属性"..self.originAttrib1)
    if self.originAttrib1 > 0 then
        --self:LogError(".....抓到敌人"..self._enemyUUID)
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -self.TLCost, 0) --扣除10体力
        self.check = 1
    end
    self.TargetCS = self._proxy:Theatre6GetNpcRuntimeOverClock(self._enemyUUID)
    if self.TargetCS <= self.CSCost then self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.TargetCS)
    else self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.CSCost)
    end
        --self:LogError(".....扣了敌人超算？"..self._enemyUUID)
end

function XBuffScript10251090:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.check == 1 then
        self._critController:AddSkillCount(self._stackCount)
        self.check = 0
    end
end

return XBuffScript10251090

--没有对释放的技能进行过滤. 所有技能都会触发此词条    已修，技能重做了