local Base = require("Buff/BuffBase/XBuffBase")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")

---@class XBuffScript8060044 : XBuffBase
local XBuffScript8060044 = XDlcScriptManager.RegBuffScript(8060044, "XBuffScript8060044", Base)
--效果说明：训练面板用的无限能量

function XBuffScript8060044:Ctor()
    self.magicId = 8060045 --加能量
end

function XBuffScript8060044:ScriptInit(isGainControl)
    --初始化
    Base.ScriptInit(self,isGainControl)
    ------------配置------------
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript8060044:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript8060044:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
end

function XBuffScript8060044:OnNpcCastActionAfterEvent(skillActionId, launcherId, targetId, targetSceneObjId, isAbort)
    self._uuid = self._proxy:GetSelfBuffNpcUUID()
    self.energy=self._proxy:GetNpcAttribRate(self._proxy,41)
    if self.energy < 1 then 
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,1) --能量不满就加能量
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript8060044:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript8060044:Terminate()
    Base.Terminate(self)
end

return XBuffScript8060044
