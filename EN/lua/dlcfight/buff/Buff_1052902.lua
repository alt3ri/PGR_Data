local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052902 : XBuffBase
local XBuffScript1052902 = XDlcScriptManager.RegBuffScript(1052902, "XBuffScript1052902", Base)

--效果说明：七实;盾冲（技能））;增加盾冲位移效果，增加盾冲流程增加防御帧，可通过摇杆释放

function XBuffScript1052902:Init()
    --初始化
    Base.Init(self)
    ------------配置------------

end

---@param dt number @ delta time 
function XBuffScript1052902:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack


--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052902:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052902:Terminate()
    Base.Terminate(self)
end


return XBuffScript1052902
