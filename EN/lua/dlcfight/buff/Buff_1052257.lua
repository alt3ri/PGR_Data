local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1052257 : XFightBase
local XBuffScript1052257 = XDlcScriptManager.RegBuffScript(1052257, "XBuffScript1052257", Base)

--效果说明：添加时给予七实核心值*ShieldCoe*最大生命值的全伤害护盾，在buff移除时移除
function XBuffScript1052257:ScriptInit(isGainControl)--初始化
    Base.ScriptInit(self, isGainControl)
    self.ShieldBasicValue = 2850
    self.ShieldCoe = 0.000625
    -----------------------------配置------------------------
    --XLog.Warning("剑盾切换盾斧buff添加")
    if not isGainControl then
        self:ShieldCal()
    end
end

---@param dt number @ delta time 
function XBuffScript1052257:Update(dt)
    Base.Update(self, dt)
   ----触发效果--------------------------------------------------------------------

end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052257:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052257:Terminate()
    Base.Terminate(self)
    --XLog.Warning("buff移除")
    self._proxy:RemoveProtector()
end

function XBuffScript1052257:ShieldCal()
    self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1)
    self.MaxLife = self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.Life)
    self.ShieldVal = self.ShieldBasicValue+math.floor(self.CustomPower1 * self.ShieldCoe * self.MaxLife)
    self._proxy:AddProtector(self.ShieldVal,EDamageType.None,0)
    local CurProtect = self._proxy:GetNpcProtector(self._uuid)
    --XLog.Warning("打印盾值"..CurProtect)
    --XLog.Warning("打印盾值"..self.ShieldVal)
end

return XBuffScript1052257
