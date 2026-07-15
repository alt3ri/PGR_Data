---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---空花露西亚·誓焰角色脚本
---@class XCharR6LuciaSG : XRelinkCharBase
local XCharR6LuciaSG = XDlcScriptManager.RegCharScript(1060, "XCharR6LuciaSG", Base)

function XCharR6LuciaSG:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._coreCount = 0
    self._atkSG = 106001
    self._coreAtkSG = 106006
    self._skill1GroundSG = 106003
    self._skill1AirSG = 106004
    self._coreAtkId = 106007
    self._hpMax = self._proxy:GetNpcAttribValue(self._uuid,0)
    self._isAir = 0
    self._lastIsAir = 0
    --print("hpmax = ",self._hpMax)
end

function XCharR6LuciaSG:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent,self._uuid) -- 注册帧事件内发送事件执行
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleStart) --注册角力开始事件
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestlePursuit) --注册角力失败事件
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleReversal) --注册角力弹开事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter) --注册技能释放后事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction) --注册退出技能事件
    self._proxy:RegisterEvent(EWorldEvent.NpcChangeProtector) --注册护盾变化事件
    --self._proxy:RegisterEvent(EWorldEvent.MechanismStop) --注册特殊机制条监听事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcChangeDamageBeforeCalc, self._uuid)
end

---@param dt number @ delta time
function XCharR6LuciaSG:Update(dt)
    Base.Update(self, dt)
    self:Core_Control()
    if self._proxy:CheckNpcOnAir(self._uuid) then
        self._isAir = 1
    else
        self._isAir = 0
    end
    self:SkillGroupSetUp(self._isAir)
end

function XCharR6LuciaSG:Core_Control()
    self._coreCount = self._proxy:GetNpcAttribValue(self._uuid,48)
    if self._coreCount < 100 then
        return
    else
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._coreAtkSG)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10600270,0)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10600271,0)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10600272,0)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10600273,0)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10600274,0)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10600275,0)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10600276,0)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10600277,0)
    end
end

function XCharR6LuciaSG:SkillGroupSetUp(isAir)
    if self._lastIsAir == isAir then return end
    
    if isAir == 1 then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skill1AirSG)
        self._lastIsAir = 1
    else
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skill1GroundSG)
        self._lastIsAir = 0
    end
end

function XCharR6LuciaSG:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then
        return
    end
    if SkillId == self._coreAtkId then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._atkSG)
        self._proxy:RemoveBuff(self._uuid,10600270)
    end
end

function XCharR6LuciaSG:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type, MissileTemplateId)
    --XLog.Warning("counter成功")
    --if (Type == 1) then
    --    --XLog.Warning("闪避成功加buff")
    --    self._proxy:ApplyMagic(self._uuid, self._uuid, 105305016, 1)
    --end
end

---@param eventType number
---@param eventArgs userdata
function XCharR6LuciaSG:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)

end

function XCharR6LuciaSG:OnNpcSkillActionKeyframeSendEvent(launcher,eventName,skillActionId,keyFrameId,skillId)
    Base.OnNpcSkillActionKeyframeSendEvent(self,launcher,eventName,skillActionId,keyFrameId,skillId)
    
end

function XCharR6LuciaSG:Terminate()
    Base.Terminate(self)
end


function XCharR6LuciaSG:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if targetId == self._uuid then
        local hp = self._proxy:GetNpcAttribValue(self._uuid,0)
        local hpPer = hp/self._hpMax
        if hpPer < 0.1 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,10600240,0)
            self._proxy:PlayDramaCaption("Caption302007")
        end
    end
end

function XCharR6LuciaSG:XNpcChangeProtectorArgs(LauncherId, TargetId, Value, TotalValue)
    Base.XNpcChangeProtectorArgs(self)
end

function XCharR6LuciaSG:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if npcUUID ~= self._uuid then
        return
    end
end

function XCharR6LuciaSG:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcRemoveBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
end

function XCharR6LuciaSG:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    if skillId == 106030  then
        --XLog.Warning("裁切关闭")
        self._proxy:SetNpcDither(self._uuid,false)
    end
    
end

function XCharR6LuciaSG:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    if skillId == 106030  then
        --XLog.Warning("裁切还原")
        self._proxy:SetNpcDither(self._uuid,true)
    end
    
end

--region 特殊保底用
function XCharR6LuciaSG:OnEnterJumpWeaponHide() --进跳跃隐藏
    Base.OnEnterJumpWeaponHide(self._uuid)
end

function XCharR6LuciaSG:OnExitJumpWeaponShow() -- 出跳跃显示
    Base.OnExitJumpWeaponShow(self._uuid)
end
--endregion

return XCharR6LuciaSG