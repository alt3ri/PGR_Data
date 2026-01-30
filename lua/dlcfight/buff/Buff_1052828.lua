local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1052828 : XBuffBase
local XBuffScript1052828 = XDlcScriptManager.RegBuffScript(1052828, "XBuffScript1052828", Base)

--效果说明：七实;t通用减抗;攻击命中目标时按照自身风格给与不同程度减抗

function XBuffScript1052828:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --XLog.Warning("Buff脚本已加载"..1052828)
end

---@param dt number @ delta time 
function XBuffScript1052828:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1052828:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --XLog.Warning("注册伤害事件")
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1052828:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1052828:Terminate()
    Base.Terminate(self)
end


function XBuffScript1052828:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    Base.OnNpcDamageEvent(self,launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if launcherId == self._uuid and targetId ~= self._uuid then
    --XLog.Warning("玩家攻击造成伤害"..targetId)
        local Template = self._proxy:GetNpcTemplate(launcherId)
        --XLog.Warning("脚本id"..Template.Id)
        if Template.Id  == 1052 then
            self._proxy:ApplyMagic(self._uuid,targetId,1052829,1) --七实t易伤
        elseif Template.Id == 1057 then
            self._proxy:ApplyMagic(self._uuid,targetId,1052829,1) --七实c易伤
        end

    end
end

return XBuffScript1052828
