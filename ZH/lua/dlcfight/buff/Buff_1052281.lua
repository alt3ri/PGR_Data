local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052281 : XBuffBase
local XBuffScript1052281 = XDlcScriptManager.RegBuffScript(1052281, "XBuffScript1052281", Base)

--效果说明：拥有该效果时，造成伤害时，额外对目标造成一次伤害

function XBuffScript1052281:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --XLog.Warning("Buff脚本1052281斧反击额外伤害")
end

---@param dt number @ delta time 
function XBuffScript1052281:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1052281:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --XLog.Warning("注册伤害事件")
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052281:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052281:Terminate()
    Base.Terminate(self)
end

function XBuffScript1052281:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    Base.OnNpcDamageEvent(self,launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if targetId ~= self._uuid then
        --XLog.Warning("命中目标")
        if self._proxy:CheckBuffByKind(self._uuid,105218) and self._proxy:CheckBuffByKind(self._uuid,1052283) then
            --XLog.Warning("不在冷却且斧")
            if not self._proxy:CheckBuffByKind(self._uuid,1052282) then
                --XLog.Warning("额外伤害，添加冷却，移除计数")
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052282,1)  -- 添加冷却
                self._proxy:ApplyMagic(self._uuid,targetId,1052045,1) -- 附加伤害，伤害流程中加伤害
                self._proxy:RemoveBuffByKindAndCount(self._uuid,1052283,1) --移除一层强化计数
            end
        end
    end

end

return XBuffScript1052281
