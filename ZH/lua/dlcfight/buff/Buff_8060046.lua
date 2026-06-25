local Base = require("Buff/BuffBase/XBuffBase")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")

---@class XBuffScript8060046 : XBuffBase
local XBuffScript8060046 = XDlcScriptManager.RegBuffScript(8060046, "XBuffScript8060046", Base)
--效果说明：训练面板用的无限能量

function XBuffScript8060046:Ctor()
    self.EnterMagicId = 1000473 --加OD值
    self.ExitMagicId = 8005959 --强制break退出OD
end

function XBuffScript8060046:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self,isGainControl)
    ------------配置------------
    self._proxy:ApplyMagic(self._uuid,self._uuid,self.EnterMagicId)
end

---@param dt number @ delta time
function XBuffScript8060046:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end


---@param eventType number
---@param eventArgs userdata
function XBuffScript8060046:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060046:Terminate() --当该脚本被移除时调用
    Base.Terminate(self)
    self._proxy:ApplyMagic(self._uuid,self._uuid,self.ExitMagicId) --强制break退出OD
end

return XBuffScript8060046
