local Base = require("Common/XFightBase")

---@class XBuffScript1015114 : XBuffBase
local XBuffScript1015114 = XDlcScriptManager.RegBuffScript(1015114, "XBuffScript1015114", Base)

--效果说明：敌人生命低于30%时，增加【雷属性伤害提升】50点
function XBuffScript1015114:Init() --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015115  --加50雷伤的buff
    self.magicLevel = 1 --Buff等级
    self.attribType = 16    --生命值类型
    self.hasBuffApplied = false --Buff状态标记
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015114:Update(dt) --每帧执行
    Base.Update(self, dt)
    --获取敌人id
    self.targetId = self._proxy:GetFightTargetId(self._uuid)
    if self.targetId ==0 then
        return
    end
    local currentHP = self._proxy:GetNpcAttribRate(self.targetId, ENpcAttrib.Life)
    if currentHP <= 0.3 then
        if not self.hasBuffApplied then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel)
            self.hasBuffApplied = true
        end
    else
        if self.hasBuffApplied then
            self._proxy:NpcRemoveBuff(self._uuid,self.magicId)
            self.hasBuffApplied = false
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015114:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015114:Terminate()
    Base.Terminate(self)
end


return XBuffScript1015114
