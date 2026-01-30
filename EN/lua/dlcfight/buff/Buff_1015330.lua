local Base = require("Common/XFightBase")

---@class XBuffScript1015330 : XFightBase
local XBuffScript1015330 = XDlcScriptManager.RegBuffScript(1015330, "XBuffScript1015330", Base)


--效果说明：攻击敌人时，以敌人半径3m召唤一个区域，进出这个区域时，获得2秒的回复效率提升+100

function XBuffScript1015330:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015331
    self.magicLevel = 1
    self.nowPos = false
    self.hisPos = false
    ------------执行------------

end

---@param dt number @ delta time 
function XBuffScript1015330:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.targetId = self._proxy:GetFightTargetId(self._uuid)

    if self.targetId == 0 then
        --没有目标的时候下面不执行
        return
    end

    self.currentPos = self._proxy:CheckNpcDistance(self._uuid, self.targetId, 3)
    -- 判断在不在3米里
    if self.currentPos then
        self.nowPos = true
    else
        self.nowPos = false
    end

    if self.nowPos ~= self.hisPos then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    end

    self.hisPos = self.nowPos
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015330:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015330:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015330

    