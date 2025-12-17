---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋莉莉丝脚本
---@class XCharTes1012 : XAFKCharBase
local XCharTes1012 = XDlcScriptManager.RegCharScript(1012, "XCharTes1012", Base)

function XCharTes1012:Init() --初始化
    Base.Init(self)

    self.ShadowcardA = nil
    self.ShadowcardB = nil
    self.ShadowcardC = nil
    self.cardBuild1 = 0
    self.cardBuild2 = 0
    self.cardBuild3 = 0

end

---@param dt number @ delta time
function XCharTes1012:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharTes1012:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharTes1012:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkillAfter)         -- OnNpcCastSkillEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XCharTes1012:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 1012001  then--生成影牌-普攻
        self.cardBuild1 = self.cardBuild1 + 1
        local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标
        if self._proxy:CheckActorExist(target) then --检测目标是否存活
            if self.cardBuild1 == 1 then
                self:GenerateShadowcardA()
            else
                local targetPosition = self._proxy:GetNpcPosition(target)
                self._proxy:SetNpcFaceToPosition(self.ShadowcardA,targetPosition)
                local YingpaiAPosition = self._proxy:GetNpcPosition(self.ShadowcardA) --获取影牌A位置
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10170209,10170209,YingpaiAPosition,YingpaiAPosition,1)--影牌发射特效
                self._proxy:ApplyMagic(self._uuid, self.ShadowcardA, 1012003, 1)
                local targetPosition2 = self._proxy:GetNpcPosition(target)
                self._proxy:SetNpcPosition(self.ShadowcardA,targetPosition2,true)
                self._proxy:AddTimerTask(0.2, function()--延迟0.2秒后，释放影牌技能
                    if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                        return
                    end
                    self._proxy:CastActionToTarget(self.ShadowcardA,101702,target)
                    local YingpaiAPosition2 = self._proxy:GetNpcPosition(self.ShadowcardA)
                    self._proxy:LaunchMissileFromPosToPos(self._uuid,10170210,10170210,YingpaiAPosition2,YingpaiAPosition2,1)--影牌落地特效
                end)
                self._proxy:AddTimerTask(0.6, function()--延迟0.6秒后，释放影牌技能
                    if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                        return
                    end
                    local YingpaiAPosition3 = self._proxy:GetNpcPosition(self.ShadowcardA)
                    self._proxy:LaunchMissileFromPosToPos(self._uuid,10170204,10170204,YingpaiAPosition3,YingpaiAPosition3,1)--影牌落地伤害
                end)
                self._proxy:AddTimerTask(0.65, function()--延迟0.65秒后，解除隐藏影牌
                    if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                        return
                    end
                    self._proxy:ApplyMagic(self._uuid, self.ShadowcardA, 1012009, 1)
                end)
            end
        else
            return
        end
    end
    if buffId == 1012004  then--生成影牌-红球
        self.cardBuild2 = self.cardBuild2 + 1
        local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标
        if self._proxy:CheckActorExist(target) then  --检测目标是否存活
            if self.cardBuild2 == 1 then
                self:GenerateShadowcardB()
            else
                local targetPosition = self._proxy:GetNpcPosition(target)
                self._proxy:SetNpcFaceToPosition(self.ShadowcardB,targetPosition)
                local YingpaiAPosition = self._proxy:GetNpcPosition(self.ShadowcardB)--获取影牌B位置
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10170209,10170209,YingpaiAPosition,YingpaiAPosition,1)--影牌发射特效
                self._proxy:ApplyMagic(self._uuid, self.ShadowcardB, 1012003, 1)
                local targetPosition2 = self._proxy:GetNpcPosition(target)
                self._proxy:SetNpcPosition(self.ShadowcardB,targetPosition2,true)
                self._proxy:AddTimerTask(0.2, function()--延迟0.2秒后，释放影牌技能
                    if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                        return
                    end
                    self._proxy:CastActionToTarget(self.ShadowcardB,101704,target)
                    local YingpaiAPosition2 = self._proxy:GetNpcPosition(self.ShadowcardB)
                    self._proxy:LaunchMissileFromPosToPos(self._uuid,10170210,10170210,YingpaiAPosition2,YingpaiAPosition2,1)--影牌落地特效
                end)
                self._proxy:AddTimerTask(0.6, function()--延迟0.6秒后，释放影牌技能
                    if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                        return
                    end
                    local YingpaiAPosition3 = self._proxy:GetNpcPosition(self.ShadowcardB)
                    self._proxy:LaunchMissileFromPosToPos(self._uuid,10170404,10170404,YingpaiAPosition3,YingpaiAPosition3,1)--影牌落地伤害
                end)
                self._proxy:AddTimerTask(0.65, function()--延迟0.65秒后，解除隐藏影牌
                    if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                        return
                    end
                    self._proxy:ApplyMagic(self._uuid, self.ShadowcardB, 1012009, 1)
                end)
            end
        else
            return
        end
    end

    if buffId == 1012005  then--生成影牌-蓝球2段
        self.cardBuild3 = self.cardBuild3 + 1
        local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标
        if self._proxy:CheckActorExist(target) then  --检测目标是否存活
            if self.cardBuild3 == 1 then
                self:GenerateShadowcardC()
            else
                local targetPosition = self._proxy:GetNpcPosition(target)
                self._proxy:SetNpcFaceToPosition(self.ShadowcardC,targetPosition)
                local YingpaiAPosition = self._proxy:GetNpcPosition(self.ShadowcardC)--获取影牌C位置
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10170209,10170209,YingpaiAPosition,YingpaiAPosition,1)--影牌发射特效
                self._proxy:ApplyMagic(self._uuid, self.ShadowcardC, 1012003, 1)
                local targetPosition2 = self._proxy:GetNpcPosition(target)
                self._proxy:SetNpcPosition(self.ShadowcardC,targetPosition2,true)
                self._proxy:AddTimerTask(0.2, function()--延迟0.2秒后，释放影牌技能
                    if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                        return
                    end
                    self._proxy:CastActionToTarget(self.ShadowcardC,101706,target)
                    local YingpaiAPosition2 = self._proxy:GetNpcPosition(self.ShadowcardC)
                    self._proxy:LaunchMissileFromPosToPos(self._uuid,10170210,10170210,YingpaiAPosition2,YingpaiAPosition2,1)--影牌落地特效
                end)
                self._proxy:AddTimerTask(0.6, function()--延迟0.6秒后，释放影牌技能
                    if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                        return
                    end
                    local YingpaiAPosition3 = self._proxy:GetNpcPosition(self.ShadowcardC)
                    self._proxy:LaunchMissileFromPosToPos(self._uuid,10170604,10170604,YingpaiAPosition3,YingpaiAPosition3,1)--影牌落地伤害
                end)
                self._proxy:AddTimerTask(0.65, function()--延迟0.65秒后，解除隐藏影牌
                    if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                        return
                    end
                    self._proxy:ApplyMagic(self._uuid, self.ShadowcardC, 1012009, 1)
                end)
            end
        else
            return
        end
    end

end

function XCharTes1012:OnNpcCastSkillBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastSkillBeforeEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    if skillId == 101210 then
        local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标
        local targetRota2 = {x = 0, y = 180, z =0}
        local targetBehindPos = self._proxy:GetNpcOffsetPositionByFacing(target, targetRota2, 1)
        self._proxy:SetNpcPosition(self._uuid, targetBehindPos)
    end

    if skillId == 101230 then --闪避技能
        self:FaceTargetSide()
    end

end


function XCharTes1012:GenerateShadowcardA() --生成影牌A召唤物
    local camp = self._proxy:GetNpcCamp(self._uuid)
    local targetPos = self._proxy:GetNpcPosition(self._uuid) --获取目标位置
    local targetRota = {x = 0, y = 180, z = 0}  --获取目标旋转

    self.ShadowcardA = self._proxy:GenerateNpc(1017, camp, targetPos, targetRota)--在自身位置生成影牌
    self._proxy:CastActionToTarget(self.ShadowcardA,101703,self.ShadowcardA)
end

function XCharTes1012:GenerateShadowcardB()    --生成影牌B召唤物
    local camp = self._proxy:GetNpcCamp(self._uuid)
    local targetPos = self._proxy:GetNpcPosition(self._uuid) --获取目标位置
    local targetRota = {x = 0, y = 180, z = 0}  --获取目标旋转
    self.ShadowcardB = self._proxy:GenerateNpc(1017, camp, targetPos, targetRota)--在自身位置生成影牌
    self._proxy:CastActionToTarget(self.ShadowcardB,101705,self.ShadowcardB)
end

function XCharTes1012:GenerateShadowcardC()    --生成影牌C召唤物
    local camp = self._proxy:GetNpcCamp(self._uuid)
    local targetPos = self._proxy:GetNpcPosition(self._uuid) --获取目标位置
    local targetRota = {x = 0, y = 180, z = 0}  --获取目标旋转
    self.ShadowcardC = self._proxy:GenerateNpc(1017, camp, targetPos, targetRota)--在自身位置生成影牌
    self._proxy:CastActionToTarget(self.ShadowcardC,101707,self.ShadowcardC)
end

function XCharTes1012:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)  --当有Npc受到伤害时
    if targetId ~= self._uuid then
        return
    end

    if self._proxy:CheckBuffByKind(self._uuid, 1012008) then
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, 101219)
    end
end

function XCharTes1012:FaceTargetSide()--看向侧面
    local own = self._uuid
    local targetPosition = self._proxy:GetNpcPosition(self._proxy:GetFightTargetId(own))  --获取自己战斗目标的位置
    local distance = 3
    local euler = {x=0,y=45,z=0} --概率左右，增加变化

    if self:GetRandomSuccess(50) then
        euler = {x=0,y=-45,z=0}
    end

    local pos = self._proxy:GetNpcOffsetPosition(self._uuid,targetPosition,euler,distance) --获取和目标一个偏移的位置，用来看向这个位置

    self._proxy:SetNpcFaceToPosition(self._uuid,pos) --看向侧面
end--向侧面望去

function XCharTes1012:GetRandomSuccess(maybe)--概率成功
    local isSuccess = false

    if self._proxy:Random(0,100) < maybe then
        isSuccess = true
    end

    return isSuccess
end

function XCharTes1012:Terminate()
    Base.Terminate(self)
end

return XCharTes1012
