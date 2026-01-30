local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060023 : XBuffBase
local XBuffScript8060023 = XDlcScriptManager.RegBuffScript(8060023, "XBuffScript8060023", Base)
--效果说明：加攻击减血量
function XBuffScript8060023:Ctor()
    self.magicIds={8060024,8060025,8060043} --各个血量区间的攻击BUFF
end
function XBuffScript8060023:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self,isGainControl)
    ------------配置------------
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.hasLevel=false
end
---@param dt number @ delta time
function XBuffScript8060023:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060023)--获取自身的BUFF等级
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicIds[1],self.magicLevel)
        self._proxy:AddNpcAttribAdditive(self._uuid,0,0,-2000)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicIds[3],self.magicLevel)
    end
end

--region EventCallBack
function XBuffScript8060023:InitEventCallBackRegister()
    --按需求解除注释进行注册
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript8060023:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060023:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060023
