local Base = require("Common/XFightBase")

---@class XBuffScript1015300 : XFightBase
local XBuffScript1015300 = XDlcScriptManager.RegBuffScript(1015300, "XBuffScript1015300", Base)

--效果说明：每损失10%的生命，【回复效率】增加10点（上限200点）
function XBuffScript1015300:Init()
    --初始化

    Base.Init(self)
    ------------配置------------
    self.magicId = 1015301
    self.magicLevel = 1
    self.accumulateHp = 0
    ------------执行------------
    self.maxHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    self.historyHp = self.maxHp
end

---@param dt number @ delta time
function XBuffScript1015300:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 获取当前hp
    self.currentHp = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    -- 获取hp变动值
    self.changeHp = self.currentHp - self.historyHp
    -- 更新历史hp
    self.historyHp = self.currentHp
    -- 如果是损失生命值
    if self.changeHp < 0 then
        -- 累计损失生命值
        self.accumulateHp = self.accumulateHp + self.changeHp
    end
    -- 计算损失了多少个10%
    self.magicLevel = math.floor(math.abs(self.accumulateHp) / self.maxHp * 100 / 10)
    -- 生效效果
    if self.magicLevel >= 1 and self.magicLevel <= 20 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015300:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015300:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015300
