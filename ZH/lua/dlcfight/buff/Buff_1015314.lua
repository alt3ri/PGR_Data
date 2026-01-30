local Base = require("Common/XFightBase")

---@class XBuffScript1015314 : XFightBase
local XBuffScript1015314 = XDlcScriptManager.RegBuffScript(1015314, "XBuffScript1015314", Base)

--效果说明：战斗开始时，战场中出现天堂之光，双方【回复效率】+10%
function XBuffScript1015314:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015315
    self.magicLevel = 1
    self.isAdd = false
    ------------执行------------

end

---@param dt number @ delta time 
function XBuffScript1015314:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self.isAdd then
        self.enemyId = self._proxy:GetFightTargetId(self._uuid)
    end

    if self.enemyId == 0 then
        --没有目标的时候下面不执行
        return
    end

    if not self.isAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:ApplyMagic(self._uuid, enemyId, self.magicId, self.magicLevel)
        self.isAdd = true
    end

end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015314:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015314:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015314

    