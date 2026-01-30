---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")
---自走棋-影牌
---@class XCharTes1017 : XAFKCharBase
local XCharTes1017 = XDlcScriptManager.RegCharScript(1017, "XCharTes1017", Base)

function XCharTes1017:Init() --初始化
    Base.Init(self)
    --距离要求，没有在列表内说明没有距离要求，在筛选到技能释放时
end

function XCharTes1017:Update(dt)
    Base.Update(self, dt)
end

function XCharTes1017:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

--region EventCallBack
function XCharTes1017:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkillBefore)  -- OnNpcCastSkillEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)               -- OnNpcDieEvent
end

function XCharTes1017:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    if npcUUID ~= self._uuid then
        return
    end
end

function XCharTes1017:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if npcUUID ~= self._uuid then
        return
    end

    if self.kaiguan == nil then
        self.kaiguan = false
    end

    if buffId == 1012005 then--发射特效与伤害子弹
        local Juli =self._proxy:GetNpcDistance(self._uuid,casterNpcUUID,false)  --获取与目标距离

        if (Juli <=5) and (self.kaiguan == false) then
            self.kaiguan = true
            self._proxy:ApplyMagic(self._uuid, casterNpcUUID, 1012006, 1)
        elseif (Juli >5) and (self.kaiguan == true) then
            self.kaiguan = false
            self._proxy:ApplyMagic(self._uuid, casterNpcUUID, 1012007, 1)
        end
    end
end

function XCharTes1017:OnNpcCastSkillBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
end

return XCharTes1017
