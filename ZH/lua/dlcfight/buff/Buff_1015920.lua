local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015920 : XBuffBase
local XBuffScript1015920 = XDlcScriptManager.RegBuffScript(1015920, "XBuffScript1015920", Base)

--效果说明：生命值高于80%时，每造成1000点伤害，可延长0.5秒开局类属性提升效果的持续时间

function XBuffScript1015920:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015921          --标记Buff
    self.runeId = 20920            --符纹ID赋值
    self.magicLevel = 1
    self.signalId = 1015901     --【浑身】状态标记，标记管理脚本见1015900
    self.signalCtrlId = 1015900 --【浑身】状态管理Buff
    self.calDmg = 0             --伤害统计
    self.targetDmg = 1000       --每x点伤害触发一次标记
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【浑身】管理Buff
end

---@param dt number @ delta time 
function XBuffScript1015920:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015920:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
end

function XBuffScript1015920:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    local isSignalActive = self._proxy:CheckBuffByKind(self._uuid,self.signalId)
    if self._uuid == launcherId and self._uuid ~= targetId and isSignalActive then
        self.calDmg = self.calDmg + physicalDamage + elementDamage + realDamage
        local buffStacks = math.floor(self.calDmg, self.targetDmg)
        self.calDmg = self.calDmg % self.targetDmg
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel, 0, buffStacks)
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015920:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015920:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015920

    