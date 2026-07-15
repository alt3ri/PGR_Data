local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---首席指挥官角色脚本
---@class XChar8071 : XFightBase
local XChar8071 = XDlcScriptManager.RegCharScript(8071, "XChar8071", Base)
--region 函数: 脚本生命周期

function XChar8071:Init()
    Base.Init(self)
    self.Move = true
    self.Attack = false
    self._proxy:AddTimerTask(2, function()
        self.Attack = true
    end)
    self.Attack2 = true
    self.Attack3 = true
    self.PlayUUID =  self._proxy:GetPlayerNpcList()
    self.Target = self.PlayUUID[1] --self.Cuuid
    self.targetPos = self._proxy:GetNpcPosition(self._uuid)

end

function XChar8071:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore) --注册技能释放前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter) --注册技能释放后前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction) -- 技能释放完成事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件

    -- 指定目标事件绑定
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcBeforeTriggerCounter, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAfterTriggerCounter, self._uuid)

    -- 注册自定义lua事件
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate)

end

function XChar8071:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8071:Update(dt)
    Base.Update(self, dt)

    if not self.Move == true then
        return
    end

    if  self.Attack == true  then-- 出生
        self.Attack = false
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid,805413,self.Target)
        self._proxy:AddTimerTask(9.7, function()
            self._proxy:NpcDie(self._uuid)
        end)
    end
end


---@param dt number @ delta time

---@param eventType number
---@param eventArgs userdata

function XChar8071:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 80710005 then
        self.Attack = true
    end
end


return XChar8071