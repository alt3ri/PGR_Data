local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052823 : XBuffBase
local XBuffScript1052823 = XDlcScriptManager.RegBuffScript(1052823, "XBuffScript1052823", Base)

--效果说明：拥有该效果时，对嘲讽目标造成额外一次伤害

function XBuffScript1052823:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --XLog.Warning("Buff脚本1052823")
end

---@param dt number @ delta time 
function XBuffScript1052823:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1052823:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --XLog.Warning("注册伤害事件")
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052823:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052823:Terminate()
    Base.Terminate(self)
end

----全部内容需要移动到脚本1052823中
function XBuffScript1052823:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    Base.OnNpcDamageEvent(self,launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if targetId ~= self._uuid then
        --XLog.Warning("命中嘲讽目标")
        if not self._proxy:CheckBuffByKind(self._uuid,1052832) then --不在冷却
            --XLog.Warning("不在冷却"..targetId)
            if self._proxy:CheckBuffByKind(targetId,105257) or self._proxy:CheckBuffByKind(targetId,1052836) then -- 处于嘲讽，目前特写
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052832,1)  -- 添加冷却
                self._proxy:ApplyMagic(self._uuid,targetId,1052824,1) -- 附加伤害，伤害流程中加伤害
                --XLog.Warning("命中嘲讽目标额外伤害")
            end
        end
    end

end

return XBuffScript1052823
