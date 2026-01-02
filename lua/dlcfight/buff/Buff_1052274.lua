local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1052274 : XFightBase
local XBuffScript1052274 = XDlcScriptManager.RegBuffScript(1052274, "XBuffScript1052274", Base)

--效果说明：添加时给予七实核心值*ShieldCoe*最大生命值的全伤害护盾，在buff移除时移除
function XBuffScript1052274:Init()--初始化
    Base.Init(self)
    self.ShieldCoe = 0.001
    -----------------------------配置------------------------
    XLog.Warning("盾斧切换剑盾护盾buff添加")
    self:ShieldCal()
end

---@param dt number @ delta time 
function XBuffScript1052274:Update(dt)
    Base.Update(self, dt)
   ----触发效果--------------------------------------------------------------------

end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052274:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052274:Terminate()
    Base.Terminate(self)
    XLog.Warning("buff移除")
    self._proxy:RemoveProtector()
end

function XBuffScript1052274:ShieldCal()
    self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1)
    self.MaxLife = self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
    self.ShieldVal = math.floor(self.CustomPower1 * self.ShieldCoe * self.MaxLife)
    self._proxy:AddProtector(self.ShieldVal,EDamageType.None,0)
    self._proxy:ApplyMagic(self._uuid,self._uuid,105238,4)
    XLog.Warning("打印盾值"..self.ShieldVal)
end

return XBuffScript1052274
