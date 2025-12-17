local Base = require("Common/XFightBase")

---@class XBuffScript1015102 : XBuffBase
local XBuffScript1015102 = XDlcScriptManager.RegBuffScript(1015102, "XBuffScript1015102", Base)

--效果说明：初始增加雷属性伤害10点，增加的伤害每秒提升1点，上限100点
function XBuffScript1015102:Init() --初始化
    Base.Init(self)
    ------------配置------------
    self.initialBuffLevel = 1  -- 初始buff等级
    self.initialBuff = 1015103  --初始+10点的buff
    self.growBuffId = 1015101     -- 每秒+1的雷伤BUFF
    self.triggerCD = 1            -- BUFF叠加间隔（秒）
    self.maxCount = 90  --最大叠加次数
    ------------执行------------
    XLog.Warning("1015102:该加buff了")
    self.currentStacks = 0
    self.cdTimer = 0
    self.isMax = false
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.initialBuff, self.initialBuffLevel) --加初始10点雷伤buff
end

---@param dt number @ delta time
function XBuffScript1015102:Update(dt) --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    XLog.Warning("1015102:该加buff了")
    if self.isMax then return end

    if not self.isMax then
        local currentTime = self._proxy:GetNpcTime(self._uuid)
        if currentTime - self.cdTimer >= 1 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self.growBuffId,self.initialBuffLevel) --加1点可叠加90层的雷伤buff
            self.currentStacks = self.currentStacks + 1
            self.cdTimer = self._proxy:GetNpcTime(self._uuid)
            if self.currentStacks >= self.maxCount then
                self.isMax = true
            end
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015102:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015102:Terminate()
    Base.Terminate(self)
end


return XBuffScript1015102