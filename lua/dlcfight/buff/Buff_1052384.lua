local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1052384 : XFightBase
local XBuffScript1052384 = XDlcScriptManager.RegBuffScript(1052384, "XBuffScript1052384", Base)

--效果说明：七实防御状态，防御禁止恢复buff，有可能异常残留
function XBuffScript1052384:Init()--初始化
    Base.Init(self)
    -----------------------------配置------------------------
    XLog.Warning("监测防御buff存在状态，若当前技能异常退出，移除效果")
end

---@param dt number @ delta time
function XBuffScript1052384:Update(dt)
    Base.Update(self, dt)
    ----触发效果--------------------------------------------------------------------
    self:CheckCurAction()
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052384:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052384:Terminate()
    Base.Terminate(self)

end

function XBuffScript1052384:CheckCurAction()
    if not (self._proxy:CheckNpcCurrentAction(self._uuid,105220) or  self._proxy:CheckNpcCurrentAction(self._uuid,105224)
            or self._proxy:CheckNpcCurrentAction(self._uuid,105234) or self._proxy:CheckNpcCurrentAction(self._uuid,105236)
            or self._proxy:CheckNpcCurrentAction(self._uuid,105238) or self._proxy:CheckNpcCurrentAction(self._uuid,105239)
            or self._proxy:CheckNpcCurrentAction(self._uuid,105240) or self._proxy:CheckNpcCurrentAction(self._uuid,105243))then
        XLog.Warning("防御异常退出")
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1052384,0)
    end

end

return XBuffScript1052384
