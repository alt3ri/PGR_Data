local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025403 : XTheatre6BuffBase
local XBuffScript1025403 = XDlcScriptManager.RegBuffScript(1025403, "XBuffScript1025403", XTheatre6BuffBase)


--效果说明：每造成过1次【击倒】，敌人被【击倒】时，扣除其1点【体力值】与【超算值】。

function XBuffScript1025403:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    self.staminaCost = 1   --体力值扣减
    self.overClockCost = 1 --超算值扣减
    self.hitDownCnt = 0    --击飞次数
    self.cntCheck = 0      --重复触发开关，每个技能仅能触发1次
    ------------执行------------
end

function XBuffScript1025403:OnLuaAffixHitDown(eventArgs)
    --self:LogError("SkillEnd")
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.cntCheck == 0 then
        self.hitDownCnt = self.hitDownCnt + 1
        --扣除对手超算值
        local curEnemyOverClock = self._proxy:Theatre6GetNpcRuntimeOverClock(self._enemyUUID)
        local calOverClockCost = math.min(curEnemyOverClock, self.overClockCost * self.hitDownCnt)
        self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID, calOverClockCost)
        --扣除对手体力
        local curEnemyStamina = self._proxy:GetNpcGameplayAttribValue(self._enemyUUID, ETheatre6AttribType.Stamina)
        local calStaminaCost = math.min(curEnemyStamina, self.staminaCost * self.hitDownCnt)
        self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -calStaminaCost, 0)
        --防重复检测
        self.cntCheck = 1
    end
end

function XBuffScript1025403:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.cntCheck = 0
end

return XBuffScript1025403
