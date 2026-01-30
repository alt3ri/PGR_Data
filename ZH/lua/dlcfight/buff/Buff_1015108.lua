local Base = require("Common/XFightBase")

---@class XBuffScript1015108 : XFightBase
local XBuffScript1015108 = XDlcScriptManager.RegBuffScript(1015108, "XBuffScript1015108", Base)

--效果说明：雷属性伤害命中敌人时，获得20点【雷属性伤害提升】，持续0.5秒，可叠加5层
function XBuffScript1015108:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015109
    self.magicKind = 1015109
    self.magicLevel = 1
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015108:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015108:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015108:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    -- 对方受击
    if targetId ~= self._uuid then
        -- 判断是否是雷属性伤害
        if elementType == 2 then
            -- 上buff
            if not self._proxy:CheckBuffByKind(self._uuid, self.magicKind) then
                self.magicLevel = 1
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            else
                self.magicLevel = self.magicLevel + 1
                if self.magicLevel <= 5 then
                    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                else
                    self.magicLevel = 5
                    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                end
            end
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015108:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015108:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015108

    