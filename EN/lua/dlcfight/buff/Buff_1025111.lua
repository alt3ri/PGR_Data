local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")

---@class XBuffScript1025111 : XTheatre6BuffBase
local XBuffScript1025111 = XDlcScriptManager.RegBuffScript(1025111, "XBuffScript1025111", XTheatre6BuffBase)

--效果说明：肉鸽6疲劳
function XBuffScript1025111:ScriptInit()
    --初始化
    --Base.Init(self)
    ------------配置------------
    self._timePlayerTired = 0                                        --玩家疲劳时间点，默认总是比敌人疲劳时间点多1个dt
    self._timeEnemyTired = 0                                         --敌人疲劳时间点
    self._isSettleTime = false                                       --是否进入了倒计时阶段
    self._isTiredTime = false                                        --是否进入了疲劳阶段
    self._isBattleTime = false                                       --是否进入了战斗阶段
    self._isEnd = false                                              --是否已经结算
    self._isDiedByTired = false                                      --是否有npc因为疲劳伤害而死亡
    self._tiredDamageLevel = 3                                       --疲劳伤害等级（1秒提升1级）
    self._tiredDamageTarget = 2                                      --疲劳目标（1为自己，2为对手，每一轮疲劳优先对手扣血）
    self._currentPhase = 0                                           --当前阶段
    self._lastPhase = 0                                              --上一阶段
    ------------执行------------
    self._startCameraTime = 0     --展示镜头阶段开始时间
    self._tiredArgA = 100
    self._tiredArgB = 2
    self._robotNextAttack = 0    --用于计算机器人下一次攻击力的变量
    self._robotAttack = self._tiredArgA * ((self._tiredDamageLevel/3) ^ self._tiredArgB)    --空白机器人的疲劳攻击力
    self._damageMagicId = 10251503
    self.tiredDmg = 50 --初始疲劳伤害
    -- self:LogError("疲劳初始化")
    self._levelTime = 0
    self.timer = self._proxy:GetFightTime(self._npcUUID)
end

function XBuffScript1025111:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)    -- OnNpcCastSkillEvent
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter, self._npcUUID)
end

---@param dt number @ delta time
function XBuffScript1025111:Update(dt)
    --每帧执行
    if self.timer > self._proxy:GetFightTime(self._npcUUID) then return end
    self.timer = self.timer + 1
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self._damageMagicId, 1)
    --self._proxy:ApplyMagic(self._enemyUUID, self._enemyUUID, self._dmgMagicId, 1)
    -- self:LogError("疲劳伤害触发")
    self.tiredDmg = self.tiredDmg + self.tiredDmg * 0.3
end

function XBuffScript1025111:AfterDamageCalc(eventArgs)
    --self:LogError("本次疲劳伤害"..self._damageMagicId)
    if eventArgs.Id ~= self._damageMagicId then return end
    local extraDmg = self.tiredDmg
    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, extraDmg, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
    --self:LogError("本次疲劳伤害"..extraDmg)
end

return XBuffScript1025111
