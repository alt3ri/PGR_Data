local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025307 : XTheatre6BuffBase
local XBuffScript1025307 = XDlcScriptManager.RegBuffScript(1025207, "XBuffScript1025307", XTheatre6BuffBase)

--效果说明：技能触发【暴击】时，造成的攻击伤害提升20%，且额外恢复自身5点【超算值】。

function XBuffScript1025307:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    --self._blockController = self:GetNpc():GetBlockController()
    ------------执行------------
    self.SkillChanceCheck = 0
    self._critController = self:GetNpc():GetCritController()
    self._stackCount = 20
    self.signalBuff = 1025104 --心眼buff
    self.BuffId = 1025906 --增伤1%
    self.CSRecover = 5
end

function XBuffScript1025307:OnLuaSkillStart(eventArgs)  --思考了一下，这个判定不能写成OnLuaAffixCritDamage，因为有时关键帧不在第一个伤害帧，会导致丢判定。只能在skillstart时判定是否有心眼buff
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.IfCrit = self._proxy:GetBuffStacks(self._npcUUID,self.signalBuff)
    if self.IfCrit == 0 then return end
    self.SkillChanceCheck = 1
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId,1,0, self._stackCount)
    self._proxy:Theatre6AddNpcRuntimeOverClock(self._npcUUID,self.CSRecover)
end

function XBuffScript1025307:OnLuaSkillEnd(eventArgs)  --技能结束时清掉增伤效果
    ------------执行------------
    if self.SkillChanceCheck == 0 then return end
    self.SkillChanceCheck = 0
    self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.BuffId,self._stackCount)
end

return XBuffScript1025307