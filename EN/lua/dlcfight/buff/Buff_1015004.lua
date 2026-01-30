local Base = require("Common/XFightBase")

---@class XBuffScript1015004 : XFightBase
local XBuffScript1015004 = XDlcScriptManager.RegBuffScript(1015004, "XBuffScript1015004", Base)

--效果说明：自身生命值越低，【火属性伤害提升】越高（上限50点），每降低20%，获得10点。起始10点
function XBuffScript1015004:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015005      --增伤MagicId
    self.magicLevel = 1         --初始Magic等级，1015005最大等级是5级
    self.health = 20            --百分比，每降低x%的生命
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1015004:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    local healthPercent = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life) * 100
    local level = math.ceil(healthPercent / self.health)    --计算等级
    --如果等级没有变化，则返回
    if level == self.magicLevel then
        return
    end
    --如果等级有变化，则更新Buff，如果等级为0则删除Buff
    self.magicLevel = level
    if self.magicLevel == 0 then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
    else
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015004:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015004:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015004
