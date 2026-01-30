local Base = require("Common/XFightBase")

---@class XBuffScript1015222 : XFightBase
local XBuffScript1015222 = XDlcScriptManager.RegBuffScript(1015222, "XBuffScript1015222", Base)

--效果说明：每损失10%的生命，使下一个护盾的护盾强度临时提升50，最多可提升200
function XBuffScript1015222:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015223
    self.buffKind = 1015223
    self.magicLevel = 1
    self.isAdd = false
    self.accumulateHp = 0
    ------------执行------------
    self.maxHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    self.historyHp = self.maxHp
end

---@param dt number @ delta time 
function XBuffScript1015222:Update(dt)
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
    -- 计算够不够10%
    self.magicLevel = math.floor(math.abs(self.accumulateHp) / self.maxHp * 100 / 10)
    -- 生效效果
    if self.magicLevel >= 1 and self.magicLevel <= 4 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.isAdd = true
    end
end

--region EventCallBack
function XBuffScript1015222:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddProtector)
end

function XBuffScript1015222:XNpcAddProtectorArgs(LauncherId, TargetId, Value, TotalValue, MagicId)
    if TargetId == self._uuid and self.isAdd then
        self._proxy:RemoveBuff(self._uuid, self.buffKind)
        self.isAdd = false
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015222:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015222:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015222

    