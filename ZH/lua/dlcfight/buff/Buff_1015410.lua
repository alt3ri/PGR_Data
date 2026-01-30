local Base = require("Common/XFightBase")

---@class XBuffScript1015410 : XFightBase
local XBuffScript1015410 = XDlcScriptManager.RegBuffScript(1015410, "XBuffScript1015410", Base)

--效果说明：每经过1秒未受到伤害，自身冰伤提升20，受到伤害后清空
function XBuffScript1015410:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.triggerCD = 1     --宝珠生效CD
    self.magicId = 1015411 --魔法id
    self.magicLevel = 1 --初始魔法等级
    self.magicCount = 1   --buff层数计数
    self.magicMaxCount = 3 --最大层数
    ------------执行------------
    self.Health = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life) --记录初始血量
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
end

---@param dt number @ delta time 
function XBuffScript1015410:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    local deltaHealth = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life) - self.Health   --生命变化值
    self.Health = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)      --重置生命计数

    --如果血量减少，则删除增伤Buff
    if deltaHealth < 0 then
        XLog.Warning("血量变化为：" .. deltaHealth)
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --删除Buff后同时重置CD
        self.magicCount = 1 --删除后重置等级
        return
    end


    --达到最大等级就返回
    if  self.magicCount > self.magicMaxCount then
        return
    end
    --CD没好就返回
    if self._proxy:GetNpcTime(self._uuid) < self.cdTimer then
        return
    end

    XLog.Warning("当前等级为：" .. self.magicCount)
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给角色调整增伤等级
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
    self.magicCount = self.magicCount + 1
end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015410:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015410:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015410
