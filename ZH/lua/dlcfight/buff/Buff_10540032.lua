local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript10540032 : XBuffBase
local XBuffScript10540032 = XDlcScriptManager.RegBuffScript(10540032, "XBuffScript10540032", Base)

--效果说明：光比3技能第一段动态添加护盾

function XBuffScript10540032:Init()
    --初始化
    Base.Init(self)

    --固定值护盾
    self.constantProtector = 1500

    --护盾百分比
    self.percentProtector = 0.6
    ------------配置------------
    --XLog.Warning("Buff脚本已加载"..10540032)
end

---@param dt number @ delta time 
function XBuffScript10540032:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript10540032:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --XLog.Warning("注册伤害事件")
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore)         -- OnNpcCastActionBeforeEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)      
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript10540032:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10540032:Terminate()
    Base.Terminate(self)
end


function XBuffScript10540032:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    Base.OnNpcDamageEvent(self,launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)

    if launcherId == self._uuid and targetId ~= self._uuid then
       
    end
end

function XBuffScript10540032:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then
        return
    end

    

    
    if SkillId == 105405 then
        local curLife = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
        local curMaxLife = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
        local protector = (curMaxLife - curLife) * self.percentProtector + self.constantProtector
        self._proxy:RemoveProtector()

        self._proxy:AddProtector(protector, EDamageType.None, 0)
    end


end

return XBuffScript10540032
