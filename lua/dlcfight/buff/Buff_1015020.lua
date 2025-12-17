local Base = require("Common/XFightBase")

---@class XBuffScript1015020 : XFightBase
local XBuffScript1015020 = XDlcScriptManager.RegBuffScript(1015020, "XBuffScript1015020", Base)

--效果说明：每移动5m，提升自身【火属性伤害提升】20点，上限100点
function XBuffScript1015020:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015021
    self.magicKind = 1015021
    self.magicLevel = 1
    self.magicCd = 1
    self.accMove = 0
    self.distance = 5
    ------------执行------------
    self.originPos = self._proxy:GetNpcPosition(self._uuid)
    self.historyPos = self.originPos
end

---@param dt number @ delta time 
function XBuffScript1015020:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if self.distance <= 25 then
        self.accMove = self._proxy:GetNpcToPositionDistance(self._uuid, self.historyPos, true) + self.accMove
        self.historyPos = self._proxy:GetNpcPosition(self._uuid)
        if self.accMove - self.distance >= 0 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self.distance = self.distance + 5
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015020:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015020:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015020

    