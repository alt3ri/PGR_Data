---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋-认知措糅体
---@class XCharTes8206 : XAFKCharBase
local XCharTes8206 = XDlcScriptManager.RegCharScript(8206, "XCharTes8206", Base)

function XCharTes8206:Update(dt)
    Base.Update(self, dt)
end

function XCharTes8206:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

--region EventCallBack
function XCharTes8206:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
end

function XCharTes8206:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 8206008  then--发射特效与伤害子弹
        local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标

        if not (target and target~=0 and self._proxy:CheckNpc(target) )then --检查目标有效性：（合法、不为0、且检查npc还存在）
            return
        end

        local targetPos = self._proxy:GetNpcPosition(target) --获取目标位置

        self._proxy:LaunchMissileFromPosToPos(self._uuid,82060401,82060401,targetPos,targetPos,1)--从目标位置向目标位置发特效
        self._proxy:LaunchMissileFromPosToPos(self._uuid,82060405,82060405,targetPos,targetPos,1)--从目标位置向目标位置发子弹
    end
end

function XCharTes8206:OnNpcCastActionBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
end

return XCharTes8206
