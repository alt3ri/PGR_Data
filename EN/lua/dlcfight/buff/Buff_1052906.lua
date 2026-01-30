local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052906 : XBuffBase
local XBuffScript1052906 = XDlcScriptManager.RegBuffScript(1052906, "XBuffScript1052906", Base)

--(红)效果说明：七实T;防御（核心）;增加格挡表现；增加格挡减伤率，增加格挡后伤害倍率，剑盾完美格挡后若核心能量满值可通过长按派生超解

function XBuffScript1052906:ScriptInit(isGainControl) --初始化
    Base.ScriptInit(self, isGainControl)
    ------------配置------------
    --XLog.Warning("Buff脚本已加载")
    if not isGainControl then
        if not self._proxy:CheckBuffByKind(self._uuid,1057015) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052804,1)
        end
    end
end

---@param dt number @ delta time 
function XBuffScript1052906:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052906:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052906:Terminate()
    Base.Terminate(self)
    --XLog.Warning("移除添加伤害上限")
    self._proxy:RemoveBuffByKindAndCount(self._uuid,1052804)
end

return XBuffScript1052906
