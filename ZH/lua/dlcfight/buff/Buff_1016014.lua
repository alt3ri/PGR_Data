local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016014 : XBuffBase
local XBuffScript1016014 = XDlcScriptManager.RegBuffScript(1016014, "XBuffScript1016014", Base)
--效果说明：敌方有护盾时，造成额外伤害

function XBuffScript1016014:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.damageUpRate = 2
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016014:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1016014:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
end

function XBuffScript1016014:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
    end
end

function XBuffScript1016014:AfterDamageCalc(eventArgs)
    if eventArgs.Launcher == self._uuid and eventArgs.Target == self.targetId then
        if self._proxy:GetNpcProtector(self.targetId) > 0 then
            local physicalDamageCal = self.damageUpRate * eventArgs.PhysicalDamage
            local elementDamageCal = self.damageUpRate * eventArgs.ElementDamage
            self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, physicalDamageCal, elementDamageCal, eventArgs.FinalHackDamage)
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016014:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016014:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016014
