---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---首席指挥官角色脚本
---@class XChar1054 : XRelinkCharBase
local XChar1054 = XDlcScriptManager.RegCharScript(1054, "XChar1054", Base)

function XChar1054:Init()
    Base.Init(self)
    self.GeDangRL = false
end

function XChar1054:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore) --注册技能释放事件
end

function XChar1054:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar1054:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
     if targetId == self._uuid then

        if self._proxy:CheckBuffByKind(self._uuid, 1054075) then
            if self.GeDangRL ==  false then
                self.GeDangRL =  true
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid,105420,0,1.33) --剑盾受击触发弹刀释放右精确格挡
            else
                self.GeDangRL =  false
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid,105419,0,1.33) --剑盾受击触发弹刀释放左精确格挡
            end
        end

    end
end

function XChar1054:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)

    if LauncherId ~= self._uuid then
        return
    end

    if (SkillId == 105413) or (SkillId == 105414)   then
        if self._proxy:CheckBuffByKind(self._uuid, 1054079) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1054078, 1)
        else
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1054081, 1)
        end
    end

end




---@param dt number @ delta time

---@param eventType number
---@param eventArgs userdata

function XChar1054:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

end

return XChar1054