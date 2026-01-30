local Base = require("Common/XFightBase")

---@class XBuffScript1015408 : XFightBase
local XBuffScript1015408 = XDlcScriptManager.RegBuffScript(1015408, "XBuffScript1015408", Base)

--效果说明：当自身血量处于30~70%之间时，获得30点临时冰伤提升
function XBuffScript1015408:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015409
    self.magicLevel = 1
    self.lowHealthRate = 0.3
    self.highHealthRate = 0.7
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015408:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015408:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)    --受伤时
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcCureAfter)      --治疗时
end

function XBuffScript1015408:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --自己受伤时判断是否需要更新Buff
    self:UpdateBuff(launcherId)
end
    

function XBuffScript1015408:AfterCureCalc(eventArgs)
    --自己治疗时判断是否需要更新Buff
    self:UpdateBuff(eventArgs.Launcher)
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015408:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015408:Terminate()
    Base.Terminate(self)
end

function XBuffScript1015408:UpdateBuff(launcherId)
    --根据是否有buff激活，以及当前生命值，决定要施加Buff还是删除Buff
    if launcherId ~= self._uuid then
        return
    end
    --更新buff逻辑
    local curHpRate = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life)
    local isHpRateOk = curHpRate <= self.highHealthRate and curHpRate >= self.lowHealthRate
    local isBuffActive = self._proxy:CheckBuffByKind(self._uuid, self.magicId)
    if isHpRateOk and (not isBuffActive) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel)
    end
    if not isHpRateOk and isBuffActive then
        self._proxy:RemoveBuff(self._uuid,self.magicId)
    end
end

return XBuffScript1015408
