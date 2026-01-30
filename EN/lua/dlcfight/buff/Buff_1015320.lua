local Base = require("Common/XFightBase")

---@class XBuffScript1015320 : XFightBase
local XBuffScript1015320 = XDlcScriptManager.RegBuffScript(1015320, "XBuffScript1015320", Base)

--效果说明：当角色生命值发生变动时，每变动1%，为角色增加1点火/冰/雷属性伤害加成，上限100点
function XBuffScript1015320:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId1 = 1015321
    self.magicId2 = 1015322
    self.magicId3 = 1015323
    self.magicLevel = 1
    self.count = 1
    self.changeCount = 0
    ------------执行------------
    self.historyHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
end

---@param dt number @ delta time 
function XBuffScript1015320:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.currentHp = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    self.maxHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    -- 计算变动了多少个1%
    self.changeCount = math.floor(math.abs(self.currentHp - self.historyHp) / self.maxHp * 100)
    if self.count <= 100 and self.changeCount >= 1 then
        self.historyHp = self.currentHp
        -- 循环叠层
        for i = 1, self.changeCount + 1 do
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId1, self.magicLevel)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId2, self.magicLevel)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId3, self.magicLevel)
            self.count = self.count + 1
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015320:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015320:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015320

    