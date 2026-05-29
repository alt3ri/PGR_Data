local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---首席指挥官角色脚本
---@class XChar8055 : XFightBase
local XChar8055 = XDlcScriptManager.RegCharScript(8055, "XChar8055", Base)
--region 函数: 脚本生命周期

function XChar8055:Init()
    Base.Init(self)
    self.Move = true
    self.Attack = false
    self._proxy:SetNpcIgnoreObstacle(self._uuid, 13 , true)
end

function XChar8055:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore) --注册技能释放事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcOverDriveFull)
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcODExitBreakAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleStart)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestlePursuit)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleReversal)
    self._proxy:RegisterEvent(EWorldEvent.NpcDodge)

    -- 指定目标事件绑定
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcBeforeTriggerCounter, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAfterTriggerCounter, self._uuid)

    -- 注册自定义lua事件
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate)
end

function XChar8055:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8055:Update(dt)
    Base.Update(self, dt)
    --更新角力时间
    if  self.Attack == true then
        self.Attack = false
        self._proxy:AddTimerTask(8, function()--延迟0.6秒后，释放影牌技能
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805407,33)
        end)
        self._proxy:AddTimerTask(11, function()--延迟0.6秒后，释放影牌技能
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805408,33)
            self.Attack = true
        end)
    end
end


function XChar8055:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)

end

function XChar8055:OnNpcBeforeTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    Base.OnNpcBeforeTriggerCounter(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    -- 非技能目标不能弹刀
    XLog.Warning("打印")
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastActionToTarget(self._uuid,805409,33)
end


---@param dt number @ delta time

---@param eventType number
---@param eventArgs userdata

function XChar8055:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

end

return XChar8055