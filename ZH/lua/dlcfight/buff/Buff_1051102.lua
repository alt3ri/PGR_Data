local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1051102 : XBuffBase
local XBuffScript1051102 = XDlcScriptManager.RegBuffScript(1051102, "XBuffScript1051102", Base)

--效果说明：用于添加伤害上限加成buff

function XBuffScript1051102:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    local template = self._proxy:GetNpcTemplate(self._uuid)
    if template.Id == 1051 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10511022)
    end
end

---@param dt number @ delta time 
function XBuffScript1051102:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1051102:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1051102:Terminate()
    Base.Terminate(self)
end

return XBuffScript1051102
