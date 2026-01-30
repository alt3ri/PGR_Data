local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010428 : XAfkItemSkillMagicBase
local XBuffScript1010428 = XDlcScriptManager.RegBuffScript(1010428, "XBuffScript1010428", Base)
--效果：当CD好了且受到伤害时触发

function XBuffScript1010428:Init() --初始化
    ---------配置------------
    self.magicId = 1010428
    ---------父类逻辑初始化------------
    Base.Init(self)
    self.damageTrigger = false
end

function XBuffScript1010428:InitEventCallBackRegister()  --监听受伤时事件
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1010428:ItemSkillMagicCondition() --条件，返回True表示成功，返回False表示失败
    return self:CheckCd() and self.damageOk  --条件是Cd好了的时候受到伤害
end

function XBuffScript1010428:ItemSkillMagicTrigger() --条件，返回True表示成功，返回False表示失败
    Base.ItemSkillMagicTrigger(self)
    self.damageOk = false  --重置DamageOk
end

function XBuffScript1010428:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    Base.OnNpcDamageEvent(self,launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)

    if targetId ~= self._uuid then  --不是自己受伤不用管
        return
    end

    if not self:CheckCd() then     --Cd没好不用管
        return
    end

    self.damageOk = true

end

return XBuffScript1010428
