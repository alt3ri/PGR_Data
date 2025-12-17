local Base = require("Common/XFightBase")

---@class XBuffScript1015306 : XFightBase
local XBuffScript1015306 = XDlcScriptManager.RegBuffScript(1015306, "XBuffScript1015306", Base)


--效果说明：回复生命时，有50%概率额外获得临时50%【回复效率】提升

function XBuffScript1015306:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015306:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015306:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcCureBefore)
end

function XBuffScript1015306:BeforeCureCalc(eventArgs)
    if self._uuid ~= eventArgs.Target then
        return
    end
    local seed = self._proxy:Random(1, 100)
    if seed < 50 then
        local contextId = eventArgs.ContextId
        self._proxy:AddCureMagicContextValue(contextId, ENpcAttrib.HealAmpP, 0, 5000)
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015306:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015306:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015306

    