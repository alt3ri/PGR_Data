local Base = require("Common/XFightBase")

---@class XBuffScript1015202 : XFightBase
local XBuffScript1015202 = XDlcScriptManager.RegBuffScript(1015202, "XBuffScript1015202", Base)

--效果说明：生命值越低10%~70%，【护盾强度】越高（上限100点）
function XBuffScript1015202:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015203
    self.buffKind = 1015203
    self.magicLevel = 1
    self.hpTable = { 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1, 0 }
    self.magicLevelTable = { 1, 2, 3, 4, 5, 6, 7 }
    self.isAddTable = { false, false, false, false, false, false, false }
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015202:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.percentHp = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life)
    if self.percentHp <= 0.7 and self.percentHp > 0 then
        for i in ipairs(self.hpTable) do
            if self.percentHp <= self.hpTable[i] and self.percentHp > self.hpTable[i + 1] and not self.isAddTable[i] then
                self.magicLevel = self.magicLevelTable[i]
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                self.isAddTable[i] = true
            end
        end
    end

    -- 已经加过buff之后如果回血了，扣buff
    for i = #self.magicLevelTable, 1, -1 do
        if self.isAddTable[i] and self.percentHp > self.hpTable[i] then
            if i == 1 then
                self._proxy:RemoveBuff(self._uuid, self.buffKind)
                self.isAddTable[i] = false
                return
            else
                self._proxy:RemoveBuff(self._uuid, self.buffKind)
                self.magicLevel = self.magicLevelTable[i - 1]
                self.isAddTable[i] = false
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            end
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015202:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015202:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015202

    