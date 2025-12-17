local Base = require("Common/XFightBase")

---@class XBuffScript1015316 : XFightBase
local XBuffScript1015316 = XDlcScriptManager.RegBuffScript(1015316, "XBuffScript1015316", Base)

--效果说明：生命值首次低于20%时，接下来的5s内，免疫所有伤害，每局1次
function XBuffScript1015316:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015317
    self.magicLevel = 1
    self.isAdd = false
    self.hpRate = 0.2
    self.count = 0
    self.countMax = 1 --生效次数
    self.canAdd = false
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1
end

---@param dt number @ delta time 
function XBuffScript1015316:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 加无敌buff
    if self.canAdd and not self.isAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.isAdd = true
        self.count = self.count + 1
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end
end

--region EventCallBack
function XBuffScript1015316:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
end

function XBuffScript1015316:AfterDamageCalc(eventArgs)
    if eventArgs.Target ~= self._uuid then
        return
    end
    if self.count >= self.countMax then
        return
    end
    -- 拿护盾和血量
    self.shield = self._proxy:GetNpcProtector(self._uuid)
    self.currentHp = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    self.minHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life) * self.hpRate
    -- 最大伤害为护盾+多于20%血量的值
    self.maxDamage = self.shield + self.currentHp - self.minHp
    -- 取最大值
    self.damage = math.max(0, self.maxDamage)

    -- 拿本次伤害
    if eventArgs.PhysicalDamage == 0 then
        if eventArgs.ElementDamage > self.damage then
            self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, eventArgs.PhysicalDamage, self.damage, eventArgs.FinalHackDamage)
            self.canAdd = true
        end
    elseif eventArgs.PhysicalDamage > self.damage then
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, self.damage, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
        self.canAdd = true
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015316:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015316:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015316