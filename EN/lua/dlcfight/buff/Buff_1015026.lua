local Base = require("Common/XFightBase")

---@class XBuffScript1015026 : XFightBase
local XBuffScript1015026 = XDlcScriptManager.RegBuffScript(1015026, "XBuffScript1015026", Base)

--效果说明：每造成10次火伤，下次释放技能时【火属性伤害提升】100点
function XBuffScript1015026:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015027
    self.magicKind = 1015027
    self.magicLevel = 1
    self.isAdd = false
    self.count = 0
    ------------执行------------ 
end

---@param dt number @ delta time 
function XBuffScript1015026:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015026:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015026:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    -- 对方受击
    if targetId ~= self._uuid and elementType == 1 then
        self.count = self.count + 1
        if not self.isAdd and self.count == 10 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self.isAdd = true
        end

        if self.count > 10 and self.isAdd then
            self.count = 0
            self._proxy:RemoveBuff(self._uuid, self.magicKind)
            self.isAdd = false
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015026:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015026:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015026
