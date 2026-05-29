local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261070 : XTheatre6SkillBase
local XBuffScript10261070 = XDlcScriptManager.RegBuffScript(10261070, "XBuffScript10261070", XTheatre6SkillBase)

--效果说明：
-- · 【拼刀】属性>300点时，额外扣除对手20点【超算值】。
-- · 自身每有4点【怒火】，获得1点【怒火】。

function XBuffScript10261070:ScriptInit(isGainControl) --初始化
    self.targetWrestle = 300                           --拼刀目标属性
    self.targetAngerStack = 4                          --怒火目标层数
    self.addAngerStack = 1                             --怒火获得层数
    self.overClockCost = 20                            --超算值扣除量
    self.angerBuffId = 1025107                         --怒火buffId
    --注册怒火控制器
    self._AngerController = self:GetNpc():GetAngerController()
end

function XBuffScript10261070:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --获取怒火值
    local angerStack = self._proxy:GetBuffStacks(self._npcUUID, self.angerBuffId)
    --向下取整计算实际获得怒火层数
    local addAngerStack = angerStack // self.targetAngerStack * self.addAngerStack
    self._AngerController:CastStackBuff(addAngerStack, self._npcUUID)
    --拼刀属性判断
    local curWrestle = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.WrestlePoint)
    if curWrestle <= self.targetWrestle then return end
    --扣除超算值,不足的部分不扣
    local curOverClock = self._proxy:Theatre6GetNpcRuntimeOverClock(self._enemyUUID)
    local calOverClockCost = math.min(curOverClock, self.overClockCost)
    self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID, calOverClockCost)
end

return XBuffScript10261070