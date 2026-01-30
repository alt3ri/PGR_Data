local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052900 : XBuffBase
local XBuffScript1052900 = XDlcScriptManager.RegBuffScript(1052900, "XBuffScript1052900", Base)

--（金）效果说明：七实T;防御（核心）;增加格挡表现；增加格挡减伤率，增加格挡后伤害倍率，剑盾完美格挡后若核心能量满值可通过长按派生超解

function XBuffScript1052900:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --XLog.Warning("Buff脚本已加载")
end

---@param dt number @ delta time 
function XBuffScript1052900:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052900:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052900:Terminate()
    Base.Terminate(self)
end


return XBuffScript1052900
