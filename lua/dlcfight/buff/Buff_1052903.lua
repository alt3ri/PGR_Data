local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052903 : XBuffBase
local XBuffScript1052903 = XDlcScriptManager.RegBuffScript(1052903, "XBuffScript1052903", Base)

--效果说明：七实;切手（技能）;切手过程增加霸体，减伤；完成切手后5s内，核心值获取效率提升

function XBuffScript1052903:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    XLog.Warning("脚本1052903")

end

---@param dt number @ delta time 
function XBuffScript1052903:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1052903:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter) --注册技能释放后事件
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052903:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052903:Terminate()
    Base.Terminate(self)
end



function XBuffScript1052903:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if skillId == 105213 or skillId == 105214 or skillId == 105713 or skillId == 105714 then
        XLog.Warning("怪物破韧时,获得伤害提升")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052831,1) --5秒内标记
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052821,1) --5秒内伤害提升
    end

end
return XBuffScript1052903
