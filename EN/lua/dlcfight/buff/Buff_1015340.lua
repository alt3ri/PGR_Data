local Base = require("Common/XFightBase")

---@class XBuffScript1015340 : XFightBase
local XBuffScript1015340 = XDlcScriptManager.RegBuffScript(1015340, "XBuffScript1015340", Base)

--效果说明：攻击存在负面效果的目标时，获得持续2s的回复效率提升100
function XBuffScript1015340:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015341
    self.magicLevel = 1
    self.buffKind = 200
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1015340:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015340:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015340:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    self.targetId = self._proxy:GetFightTargetId(self._uuid)
    if launcherId == self._uuid and targetId == self.targetId then
        local buffNum = self._proxy:GetBuffCountByKind(self.targetId, self.buffKind)
        if buffNum > 0 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015340:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015340:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015340

    