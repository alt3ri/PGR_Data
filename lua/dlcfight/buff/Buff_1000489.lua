local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1000489 : XFightBase
local XBuffScript1000489 = XDlcScriptManager.RegBuffScript(1000489, "XBuffScript1000489", Base)

function XBuffScript1000489:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

	self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
end

function XBuffScript1000489:Update(dt)
    Base.Update(self, dt)
end

function XBuffScript1000489:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)

    -- 排除非伤害事件
    if eventType ~= EWorldEvent.NpcDamage then
        return
    end

    -- 血量小于等于1（0.1误差区间）时恢复80%的最大血量
    local curHealth = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    if curHealth <= 1.1 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000491, 1)
    end
end

function XBuffScript1000489:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.NpcDamage)

    Base.Terminate(self)
end

return XBuffScript1000489