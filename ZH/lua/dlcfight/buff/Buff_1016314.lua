local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016314 : XBuffBase
local XBuffScript1016314 = XDlcScriptManager.RegBuffScript(1016314, "XBuffScript1016314", Base)
--效果说明：敌人每回复currentCureTarget点生命，则偷取其currentCureDigit点生命

function XBuffScript1016314:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016314, 1016315, 1016316, 1016317, 1016318}  --5个等级
    self.cureTarget={5000, 5000, 5000, 5000, 5000}  --敌人奶检测量
    self.cureDigit={500, 1000, 1500, 2000, 2500}  --偷取生命量
    self.currentCureTarget = 0
    self.currentCureDigit = 0

    self.damageMagic = 1016320 --500点伤害，上下文改伤害量
    self.healMagic = 1016321 --500点奶，上下文改奶量
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.cureSum = 0
    self.cureIgnoreBuff = 1016417 -- 不读饰品6117x-1016364相关奶
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016314:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1016314:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcCureAfter)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
end

function XBuffScript1016314:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        --开局时获得该等级的参数，避免后续持续遍历
        for thisLevel, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                self.currentCureTarget = self.cureTarget[thisLevel]
                self.currentCureDigit = self.cureDigit[thisLevel]
                return
            end
        end
    end

end

function XBuffScript1016314:AfterCureCalc(eventArgs)
    local isPlayer = eventArgs.Launcher == self._uuid and eventArgs.Target == self._uuid --奶自己
    local isThisCure = eventArgs.Id == self.healMagic --奶来自该buff

    if eventArgs.Target == self.targetId and eventArgs.Id ~= self.cureIgnoreBuff then --非自奶检测
        self.cureSum = eventArgs.FinalValue + self.cureSum
        local magicTimes = math.floor(self.cureSum / self.currentCureTarget)
        for _ = 1, magicTimes do
            self._proxy:ApplyMagic(self._uuid, self.targetId, self.damageMagic, self.magicLevel)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.healMagic, self.magicLevel)
        end
        self.cureSum = self.cureSum % self.currentCureTarget
    elseif isPlayer and isThisCure then --调整奶量
        self._proxy:SetAfterCureMagicContext(eventArgs.ContextId,self.currentCureDigit)
    end

end

function XBuffScript1016314:AfterDamageCalc(eventArgs)
    if eventArgs.Launcher == self._uuid and eventArgs.Target == self.targetId and eventArgs.Id == self.damageMagic then
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, self.currentCureDigit, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016314:HandleEvent(eventType, eventArgs)
Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016314:Terminate()
Base.Terminate(self)
end

return XBuffScript1016314
