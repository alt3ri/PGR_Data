local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---首席指挥官角色脚本
---@class XChar8059 : XFightBase
local XChar8059 = XDlcScriptManager.RegCharScript(8059, "XChar8059", Base)
--region 函数: 脚本生命周期

function XChar8059:Init()
    Base.Init(self)
    local npcUuidList = self._proxy:GetNpcList()
    for i = 1, #npcUuidList, 1 do
        if self._proxy:CheckBuffByKind(npcUuidList[i], 80560011) then
            self._monsterUUID = npcUuidList[i]
        end
    end
    self.AISwitch = false
    self.PlayUUID =  self._proxy:GetPlayerNpcList()
    self.Skill1index1 = 1
    self._Skill= {
        [1] = 805902,
        [2] = 805903,
    }
end


function XChar8059:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore) --注册技能释放前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter) --注册技能释放后前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction) -- 技能释放完成事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件
end

function XChar8059:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8059:Update(dt)
    Base.Update(self, dt)

    if self.AISwitch == true and  self._proxy:CheckBuffByKind(self._uuid, 8059002) then
        self.AISwitch = false
        self:Skill()
    end

end

function XChar8059:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillActionId, magicTags)
end

function XChar8059:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)

    if LauncherId ~= self._uuid then
        return
    end

    if SkillId == 805901 then
    end

end

function XChar8059:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 80590001 then
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid,805901,self._monsterUUID)
     --[[   self._proxy:AddTimerTask(2, function()
            self._proxy:NpcDie(self._monsterUUID)
        end)]]
        for i = 1,#self.PlayUUID, 1 do
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 80560006, 1)
        end

        self._proxy:AddTimerTask(2, function()
            self._proxy:CastAction(self._uuid,805905)
        end)
    end
end


function XChar8059:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort) -- 技能释放完成时
    if launcherId ~= self._uuid then
        return
    end
    self.AISwitch = true -- 开启技能开关
end

function XChar8059:Skill()
    local Skill1key = self._Skill[self.Skill1index1] -- 获取当前技能释放序列
    self._proxy:CastActionToTarget(self._uuid,Skill1key,self._monsterUUID) -- 向最大仇恨目标按顺序释放常规技能组1
    self.Skill1index1 = self.Skill1index1 + 1 -- 每次释放技能加一次序号
end



---@param dt number @ delta time

---@param eventType number
---@param eventArgs userdata
---
---
return XChar8059