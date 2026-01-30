local Base = require("Common/XFightBase")

---@class XBuffScript1015000 : XFightBase
local XBuffScript1015000 = XDlcScriptManager.RegBuffScript(1015000, "XBuffScript1015000", Base)

--效果说明：每10秒获得一次【火属性伤害提升】提升10%，持续5秒
function XBuffScript1015000:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.triggerCD = 10         --加Buff CD
    self.duration = 5           --Buff持续时间
    self.magicId = 1015001      --造成伤害的魔法id
    self.magicLevel = 1         --魔法等级
    ------------执行------------
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
    self.durTimer = self._proxy:GetNpcTime(self._uuid) + self.duration  --计算删除Buff的Timer
end

---@param dt number @ delta time 
function XBuffScript1015000:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --检查两个Timer，满足条件时分别执行添加Buff、删除Buff的操作，添加Buff时更新两个Timer
    if self._proxy:GetNpcTime(self._uuid) >= self.cdTimer then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
        self.durTimer = self._proxy:GetNpcTime(self._uuid) + self.duration  --计算删除Buff的Timer
    end
    if self._proxy:GetNpcTime(self._uuid) > self.durTimer then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015000:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015000:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015000
