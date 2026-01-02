local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript8060006 : XBuffBase
local XBuffScript8060006 = XDlcScriptManager.RegBuffScript(8060006, "XBuffScript8060006", Base)
--效果说明：治疗别人后，给自己加攻击力

function XBuffScript8060006:Init()
    Base.Init(self)
    self.magicLevel=1 --等新接口直接获取自己的BUFF等级
    self.magicId=8060007
    self.hasLevel=false
end

function XBuffScript8060006:Update(dt)
    Base.Update(self)
    if self.hasLevel==false then
        self.hasLevel,self.magicLevel=self._proxy:TryQueryBuffLevel(self._uuid,8060006)--获取自身的BUFF等级
    end
end
--region EventCallBack
function XBuffScript8060006:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcCureAfter)
end

function XBuffScript8060006:AfterCureCalc(eventArgs)
    if not self._proxy:CheckNpc(self._uuid) and not eventArgs.Launcher==self._uuid then return end
    self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel)
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript8060006:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060006:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060006
