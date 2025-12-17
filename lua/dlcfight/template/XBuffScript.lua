local Base = require("Common/XFightBase")
---@class XBuffScriptXXXX : XBuffBase
local XBuffScriptXXXX = XDlcScriptManager.RegBuffScript(0000, "XBuffScriptXXXX", Base)

---@param proxy XDlcCSharpFuncs
function XBuffScriptXXXX:Ctor(proxy)
    self._proxy = proxy ---@type XDlcCSharpFuncs
end

function XBuffScriptXXXX:Init() --初始化
    Base.Init(self)
end

---@param dt number @ delta time 
function XBuffScriptXXXX:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XBuffScriptXXXX:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScriptXXXX:Terminate()
    Base.Terminate(self)
end

--region EventCallBack
function XBuffScriptXXXX:InitEventCallBackRegister()
    --按需求解除注释进行注册
    --self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)    -- OnNpcCastActionAfterEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)         -- OnNpcExitActionEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcDie)               -- OnNpcDieEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcRevive)            -- OnNpcReviveEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcLoadComplete)      -- OnNpcLoadCompleteEvent
    --self._proxy:RegisterEvent(EWorldEvent.Behavior2ScriptMsg)   -- OnBehavior2ScriptMsgEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileHit)           -- OnMissileHitEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileDead)          -- OnMissileDeadEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileCreate)        -- OnMissileCreateEvent
end

function XBuffScriptXXXX:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    
end

function XBuffScriptXXXX:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort) 
    
end

function XBuffScriptXXXX:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort) 
    
end

function XBuffScriptXXXX:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer) 
    
end

function XBuffScriptXXXX:OnNpcReviveEvent(npcUUID, npcPlaceId, npcKind, isPlayer) 
    
end

function XBuffScriptXXXX:OnNpcLoadCompleteEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    
end

function XBuffScriptXXXX:OnBehavior2ScriptMsgEvent(npcUUID, msgType, intList, floatList) 
    
end

function XBuffScriptXXXX:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    
end

function XBuffScriptXXXX:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    
end

function XBuffScriptXXXX:OnMissileHitEvent(missileUUID, targetNpcUUID) 
    
end

function XBuffScriptXXXX:OnMissileDeadEvent(missileUUID)
    
end

function XBuffScriptXXXX:OnMissileCreateEvent(missileUUID)
    
end
--endregion

return XBuffScriptXXXX
