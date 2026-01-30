local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1056023 : XBuffBase
local XBuffScript1056023 = XDlcScriptManager.RegBuffScript(1056023, "XBuffScript1056023", Base)

--效果说明：用于添加剑损脚本

function XBuffScript1056023:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --XLog.Warning("剑气命中buff脚本")
    self._proxy:ApplyMagic(self._casterUUID,self._uuid,1056024,1,0,1)
    if not (self._proxy:CheckBuffByKind(self._uuid,1051020)) then
        self._proxy:ApplyMagic(self._casterUUID,self._uuid,1056020)
    end

    -- if not (self._proxy:CheckBuffByKind(self._uuid,1056022)) then
    --     XLog.Warning("添加伤害")
    --     self._proxy:ApplyMagic(self._casterUUID,self._uuid,1056022)
    --     return
    -- end
    -- XLog.Warning("延长触发")
    -- self._proxy:ChangeBuffTimeByTemplateId(1056022,2, EBuffModifyType.Value,EBuffValueRefType.BornTime)
     
end

---@param dt number @ delta time 
function XBuffScript1056023:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1056023:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1056023:Terminate()
    Base.Terminate(self)
end

return XBuffScript1056023
