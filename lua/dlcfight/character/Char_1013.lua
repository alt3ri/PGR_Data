---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋薇拉脚本
---@class XCharTes1013 : XAFKCharBase
local XCharTes1013 = XDlcScriptManager.RegCharScript(1013, "XCharTes1013", Base)

function XCharTes1013:Init() --初始化
    Base.Init(self)
    self._proxy:SetNpcAnimationLayer(self._uuid, 0)
    self.Damage = 0
    self.Cishu = 0
    self.kaiguan = true
end

---@param dt number @ delta time 
function XCharTes1013:Update(dt)
    Base.Update(self, dt)

    if not self._proxy:CheckBuffByKind(self._uuid, 1013216) then
        return
    end

    local Target = self._proxy:GetFightTargetId(self._uuid) -- 获取战斗目标

    if not self._proxy:CheckActorExist(Target) then --检测目标是否存活
        return
    end

    local TargetHp = self._proxy:GetNpcAttribValue(Target,0) -- 检测当前敌方血量
    local TargetHpMax = self._proxy:GetNpcAttribMaxValue(Target,0) --检测当前敌方最大血量
    local TargetHpPercent = TargetHp / TargetHpMax -- 获取敌方血量百分比

    if TargetHpPercent < 0.4 and self.kaiguan == true then
        local Position = self._proxy:GetNpcPosition(Target)--获取目标位置
        self.Damage = self.Damage * 100
        self._proxy:DamageRelinkStandalone(self._uuid,Target,0,1013120,1,self.Damage,2,0,0,0)
        self.kaiguan = false
    end
end

---@param eventType number
---@param eventArgs userdata
function XCharTes1013:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharTes1013:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XCharTes1013:OnNpcCastActionBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)--动画层根据对应技能切换
    Base.OnNpcCastActionBeforeEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    if (skillId == 101303) or (skillId == 101304) or (skillId ==101307) or (skillId ==101308) or (skillId ==101309) or (skillId ==101328)then
        self._proxy:SetNpcAnimationLayer(self._uuid, 0)
    else
        self._proxy:SetNpcAnimationLayer(self._uuid, 1)
    end

    if skillId == 101327 then
        self:FaceTargetSide()
    end

    if skillId == 101322 then
        self.Cishu = self.Cishu + 1
    end

end


function XCharTes1013:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 1013209  then--火dot结算触发
        self:FireCheck()
    end

end

function XCharTes1013:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)  --当有Npc受到伤害时

    if launcherId ~= self._uuid then
        return
    end

    if not self._proxy:CheckBuffByKind(self._uuid, 1013216) then
        return
    end

    if magicId ~= 1013115 then
        return
    end

    if self.Cishu > 4 then
        return
    end

    self.Damage = self.Damage + elementDamage

end


function XCharTes1013:FaceTargetSide()--看向侧面
    local own = self._uuid
    local targetPosition = self._proxy:GetNpcPosition(self._proxy:GetFightTargetId(own))  --获取自己战斗目标的位置
    local distance = 3
    local euler = {x=0,y=90,z=0} --概率左右，增加变化

    if self:GetRandomSuccess(50) then
        euler = {x=0,y=-90,z=0}
    end

    local pos = self._proxy:GetNpcOffsetPosition(self._uuid,targetPosition,euler,distance) --获取和目标一个偏移的位置，用来看向这个位置

    self._proxy:SetNpcFaceToPosition(self._uuid,pos) --看向侧面
end--向侧面望去


function XCharTes1013:FireCheck()
    local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标

    if self._proxy:CheckBuffByKind(target, 1013202) or self._proxy:CheckBuffByKind(target, 1013212) or self._proxy:CheckBuffByKind(target, 1013213) then
        self._proxy:ApplyMagic(self._uuid, target, 1013303, 1)
    else
        self._proxy:ApplyMagic(self._uuid, target, 1013213, 1)
    end
end

function XCharTes1013:GetRandomSuccess(maybe)--概率成功
    local isSuccess = false

    if self._proxy:Random(0,100) < maybe then
        isSuccess = true
    end

    return isSuccess
end

return XCharTes1013
