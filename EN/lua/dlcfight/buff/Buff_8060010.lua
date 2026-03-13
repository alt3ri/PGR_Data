local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060010 : XBuffBase
local XBuffScript8060010 = XDlcScriptManager.RegBuffScript(8060010, "XBuffScript8060010", Base)
--效果说明：生命值达到门槛则加爆伤
function XBuffScript8060010:Ctor()
    self.magicId=8060011
    self.attribType=0--生命属性
    self.thresholdNum=16000; --触发需要的生命值门槛
end

function XBuffScript8060010:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self,isGainControl)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.hasLevel=false
end

---@param dt number @ delta time
function XBuffScript8060010:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行-------------
    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060010)--获取自身的BUFF等级
        local hpNum=self._proxy:GetNpcAttribValue(self._uuid,self.attribType) --血量门槛判断
        if hpNum>=self.thresholdNum and not self._proxy:CheckBuffByKind(self._uuid,self.magicId) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel) --上BUFF
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript8060010:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060010:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060010
