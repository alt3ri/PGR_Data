local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016309 : XBuffBase
local XBuffScript1016309 = XDlcScriptManager.RegBuffScript(1016309, "XBuffScript1016309", Base)
--效果说明：敌方有护盾时，造成额外伤害，无盾则小幅吸血

function XBuffScript1016309:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016309, 1016310, 1016311, 1016312, 1016313}  --5个等级
    self.damageUpRate={0.2, 0.4, 0.6, 0.8, 1}  --对护盾的伤害倍率加值
    self.cureUpRate={0.04, 0.08, 0.12, 0.16, 0.2}  --无护盾时的回血倍率
    self.currentDamageUpRate = 0
    self.currentCureUpRate = 0

    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.healCal = 0
    self.healMagic = 1016319 --1点奶，上下文改奶量
    self.magicLevel = 1
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016309:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1016309:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcCureAfter)
end

function XBuffScript1016309:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        --开局时获得该等级的参数，避免后续持续遍历
        for thisLevel, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                self.currentDamageUpRate = self.damageUpRate[thisLevel] + 1
                self.currentCureUpRate = self.cureUpRate[thisLevel]
                return
            end
        end
    end

end

function XBuffScript1016309:AfterDamageCalc(eventArgs)

    if eventArgs.Launcher == self._uuid and eventArgs.Target == self.targetId then

        --有盾，出伤
        if self._proxy:GetNpcProtector(self.targetId) > 0 then
            local physicalDamageCal = self.currentDamageUpRate * eventArgs.PhysicalDamage
            local elementDamageCal = self.currentDamageUpRate * eventArgs.ElementDamage
            self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, physicalDamageCal, elementDamageCal, eventArgs.FinalHackDamage)

            --无盾，回血
        else
            self.healCal = math.ceil(self.currentCureUpRate * (eventArgs.PhysicalDamage + eventArgs.ElementDamage))
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.healMagic, self.magicLevel)
        end
    end

end

function XBuffScript1016309:AfterCureCalc(eventArgs)
    local isPlayer = eventArgs.Launcher == self._uuid and eventArgs.Target == self._uuid --奶自己
    local isThisCure = eventArgs.Id == self.healMagic --奶来自该buff
    if isPlayer and isThisCure then
        self._proxy:SetAfterCureMagicContext(eventArgs.ContextId,self.healCal)
        self.healCal = 0
    end

end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016309:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016309:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016309
