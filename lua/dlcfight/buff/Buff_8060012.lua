local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060012 : XBuffBase
local XBuffScript8060012 = XDlcScriptManager.RegBuffScript(8060012, "XBuffScript8060012", Base)
--效果说明：攻击乘区达到门槛则加爆伤

function XBuffScript8060012:Ctor()
    self.magicId=8060013
    self.attribType=72--Attack3AmpP攻击乘区属性
    self.thresholdNum=5000; --触发需要的攻击门槛
end

function XBuffScript8060012:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self,isGainControl)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.hasLevel=false
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript8060012:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行-------------
    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060012)--获取自身的BUFF等级
    end
    local atkNum=self._proxy:GetNpcAttribValue(self._uuid,self.attribType) --初始化的时候就判断加上
    if atkNum>=self.thresholdNum and not self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel) --上BUFF
    elseif atkNum<self.thresholdNum and self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
        self._proxy:RemoveBuff(self._uuid,self.magicId)
    end
end
---@param eventType number
---@param eventArgs userdata
function XBuffScript8060012:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060012:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060012
