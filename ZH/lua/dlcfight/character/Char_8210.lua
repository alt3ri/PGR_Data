---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋-解构囚徒
---@class XCharTes8210 : XAFKCharBase
local XCharTes8210 = XDlcScriptManager.RegCharScript(8210, "XCharTes8210", Base)

function XCharTes8210:Update(dt)
    Base.Update(self, dt)
end

function XCharTes8210:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

--region EventCallBack
function XCharTes8210:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
end

function XCharTes8210:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 8210002 then--发射特效与伤害子弹
        local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标

        if not (target and target ~= 0 and self._proxy:CheckNpc(target)) then --检查目标有效性：（合法、不为0、且检查npc还存在）
            return
        end

        local targetPos = self._proxy:GetNpcPosition(target) --获取目标位置

        self._proxy:LaunchMissileFromPosToPos(self._uuid,82100704,82100704,targetPos,targetPos,1)--从目标位置向目标位置发特效
        self._proxy:LaunchMissileFromPosToPos(self._uuid,82100705,82100705,targetPos,targetPos,1)--从目标位置向目标位置发子弹
    end
end

function XCharTes8210:OnNpcCastSkillBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
end

return XCharTes8210
