local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

-- 【超算】成功后，造成2*100%攻击伤害。
--  · 自身每有100点【超算】属性，获得1层<坚毅>，至多5层；
--  · 扣除对手50点【体力值】。
---@class XBuffScript.10264020 : XTheatre6SkillBase
local XBuff10264020 = XDlcScriptManager.RegBuffScript(10264020, "XBuffScript10264020", XTheatre6SkillBase)

function XBuff10264020:ScriptInit(isGainControl) --初始化
    self.blockStacks = 1
    self.maxBlockStacks = 5                      --最大层数
    self.overClock = 100                         --每x点超算获得1层坚毅
    self.staminaDamage = 50                      --体力消除数值
end

function XBuff10264020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._blockController = self:GetNpc():GetBlockController()
end

function XBuff10264020:OnLuaSkillEnd(eventArgs)
    --技能释放后，获得坚毅、扣除对手体力
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --获得坚毅
    local blockStacks = math.floor(self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock) /
        self.overClock)
    blockStacks = math.min(blockStacks, self.maxBlockStacks)
    self._blockController:CastStackBuff(blockStacks, self._npcUUID)
    --消除体力
    self._proxy:Theatre6ChangeStaminaValue(eventArgs._targetUUID, -self.staminaDamage,0)
end

return XBuff10264020
