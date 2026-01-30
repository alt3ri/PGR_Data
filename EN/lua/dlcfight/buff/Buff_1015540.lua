local Base = require("Common/XFightBase")

---@class XBuffScript1015540 : XFightBase
local XBuffScript1015540 = XDlcScriptManager.RegBuffScript(1015540, "XBuffScript1015540", Base)

--效果说明：角色濒临死亡时，回复自身x%最大HP，一场战斗生效1次
function XBuffScript1015540:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015541 --治疗
    self.magicLevel = 1
    self.count = 0
    self.countMax = 1 --生效次数
    self.canHeal = false
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1
end

---@param dt number @ delta time 
function XBuffScript1015540:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015540:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)            -- OnNpcDamageEvent
end

function XBuffScript1015540:AfterDamageCalc(eventArgs)
    if self.count >= self.countMax then
        return
    end
    -- 拿护盾和血量

    self.shield = self._proxy:GetNpcProtector(self._uuid)
    self.hp = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    self.canCover = self.shield + self.hp
    self.damage = self.canCover - 1
    -- 拿本次伤害
    if eventArgs.PhysicalDamage == 0 then
        if eventArgs.ElementDamage >= self.canCover then
            self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, eventArgs.PhysicalDamage, self.damage, eventArgs.FinalHackDamage)
            self.canHeal = true
        end
    else
        if eventArgs.PhysicalDamage >= self.canCover then
            self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, self.damage, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
            self.canHeal = true
        end
    end
    -- 回血
    if self.canHeal then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        self.count = self.count + 1
        self.canHeal = false
    end

end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015540:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015540:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015540

    