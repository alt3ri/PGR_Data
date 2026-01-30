---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋-0号代行者
---@class XCharTes8209 : XAFKCharBase
local XCharTes8209 = XDlcScriptManager.RegCharScript(8209, "XCharTes8209", Base)

function XCharTes8209:Update(dt)
    Base.Update(self, dt)
end

function XCharTes8209:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

--region EventCallBack
function XCharTes8209:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)               -- OnNpcDieEvent
end



function XCharTes8209:OnNpcCastSkillBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    if skillId == 820912 then
        local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标
        local targetRota2 = {x = 0, y = 180, z =0}
        local targetBehindPos = self._proxy:GetNpcOffsetPositionByFacing(target, targetRota2, 1)
        self._proxy:SetNpcPosition(self._uuid, targetBehindPos)
    end
end

function XCharTes8209:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    if npcUUID ~= self._uuid then
        return
    end
    local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标
    local SelfPos = self._proxy:GetNpcPosition(self._uuid) --获取自身位置
    self._proxy:LaunchMissileFromPosToPos(target,82091121,82091121,SelfPos,SelfPos,1)--从目标位置向目标位置发特效
end

return XCharTes8209
