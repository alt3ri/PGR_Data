local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1052339 : XFightBase
local XBuffScript1052339 = XDlcScriptManager.RegBuffScript(1052339, "XBuffScript1052339", Base)

--效果说明：监测特效存在状态，若当前技能异常退出，移除效果
function XBuffScript1052339:Init()--初始化
    Base.Init(self)
    -----------------------------配置------------------------
    --XLog.Warning("监测特效存在状态，若当前技能异常退出，移除效果")
end

---@param dt number @ delta time
function XBuffScript1052339:Update(dt)
    Base.Update(self, dt)
    ----触发效果--------------------------------------------------------------------
    self:CheckCurAction()
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052339:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052339:Terminate()
    Base.Terminate(self)

end

function XBuffScript1052339:CheckCurAction()
    if not (self._proxy:CheckNpcCurrentAction(self._uuid,105244) or  self._proxy:CheckNpcCurrentAction(self._uuid,105245)
            or self._proxy:CheckNpcCurrentAction(self._uuid,105246) or self._proxy:CheckNpcCurrentAction(self._uuid,105247)
            or self._proxy:CheckNpcCurrentAction(self._uuid,105248))then
        --XLog.Warning("异常退出角力")
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1052339,0)
    end

end

return XBuffScript1052339
