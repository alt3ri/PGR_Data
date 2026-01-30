local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1051104 : XBuffBase
local XBuffScript1051104 = XDlcScriptManager.RegBuffScript(1051104, "XBuffScript1051104", Base)

--效果说明：用于添加伤害上限加成buff

function XBuffScript1051104:Init()
    --初始化
    Base.Init(self)
    ------------配置------------

    local template = self._proxy:GetNpcTemplate(self._uuid)
    if template.Id == 1056 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10511042)
    end
end

---@param dt number @ delta time 
function XBuffScript1051104:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1051104:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1051104:Terminate()
    Base.Terminate(self)
end

return XBuffScript1051104
