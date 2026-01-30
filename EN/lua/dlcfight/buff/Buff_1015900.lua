local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015900 : XBuffBase
local XBuffScript1015900 = XDlcScriptManager.RegBuffScript(1015900, "XBuffScript1015900", Base)
--效果说明：生命值小于等于20%时，进入【背水】状态

function XBuffScript1015900:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.signalId = 1015901      --背水标记Buff
    self.signalLevel = 1
    self.effectHpRate = 0.2     --触发背水效果的Hp比例
    ------------执行------------
    self.enhBuffIdDict = {
        [1] = 1015928           --增强Buff[1]：自身生命值低于20%时，也可触发斩杀的属性提升效果
    }
    self.enhRuneIdDict = {
        [1] = 20928             --增强Buff[1]对应的符纹Id
    }
end

---@param dt number @ delta time
function XBuffScript1015900:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    local percentHp = self._proxy:GetNpcAttribRate(self._uuid,ENpcAttrib.Life)
    local isBuffActive = self._proxy:CheckBuffByKind(self._uuid,self.signalId)
    --身上有标记buff，且高于触发要求的hp时，移除标记buff
    if percentHp > self.effectHpRate and isBuffActive then
        self._proxy:RemoveBuff(self._uuid,self.signalId)
    end
    --生命值满足触发要求时，获得标记
    if percentHp <= self.effectHpRate and (not isBuffActive) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.signalId,self.signalLevel)
    end
end


--region EventCallBack

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015900:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015900:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015900
