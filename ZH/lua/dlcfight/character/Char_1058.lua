---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---共斗_极昼丽芙_第二风格角色脚本；
---以下有很多1053开头的ID，大部分原因可总结为复用第一风格1053角色的子弹发射ID和效果ID(纯表现向ID)，均可在单位A011表中查找到；
---@class XCharR4LivH2 : XRelinkCharBase
local XCharR4LivH2 = XDlcScriptManager.RegCharScript(1058, "XCharR4LivH2", Base)

function XCharR4LivH2:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    self._proxy:SetNpcSoftLockTargetConfig(self._uuid, 2)
    self._teamList = self._proxy:GetPlayerNpcList()
    --核心被动变量
    self._coreCount = 0
    self._coreLevel = 0
    --普攻6 id
    self._atk06Id = 105806
    self._counterId = 105809
    --技能1 id
    self._skill10Id = 105810
    self._skill11Id = 105811
    self._skill12Id = 105812
    --技能2 id
    self._skill20Id = 105820
    self._skill21Id = 105821
    --技能3 id
    self._skill32Id = 105832
    self._skill33Id = 105833
    self._skill34Id = 105834
    --技能4 id
    self._skill40Id = 105840
    self._skill41Id = 105841
    --技能3特殊普攻 id
    self._atkSp1Id = 105831
    self._atkSp2Id = 105832
    self._atkSp3Id = 105833
    --极限技
    self._limitSkill = 105860
    --连携弹刀 id
    self._parryCounter1 = 105872
    self._parryCounter2 = 105874
    --注册技能事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent,self._uuid)
end

---@param dt number @ delta time
function XCharR4LivH2:Update(dt)
    Base.Update(self, dt)
    self:CheckLimitEnergyAddBuff()
    --count = count + 1
    --if self._proxy:CheckNpcFullActionState(self._uuid, ENpcAction.Reboot,-1)  then
    --    XLog.Warning( self._uuid," Bro！老姐我死了！救啊，别愣着了！")
    --else
    --    XLog.Warning(" Reboot=",self._uuid,"...",self._proxy:CheckNpcFullActionState(self._uuid, ENpcAction.Reboot,-1))
    --end
end

---@param eventType number
---@param eventArgs userdata
function XCharR4LivH2:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharR4LivH2:CheckLimitEnergyAddBuff()
    if not self._proxy:CheckBuffByKind(self._uuid,105305013) then
        local LimitSkillEnergy = self._proxy:GetTeamWorkEnergy(self._uuid)
        if LimitSkillEnergy >= 100 then
            --XLog.Warning("加极限技能buff效果")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053050131,1)
        end
    end
end

function XCharR4LivH2:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then return end
    --直播前瞻专属代码
    --if buffId == 8005908 then
    --    self._proxy:CastAction(self._uuid,105840)
    --end

    --技能4双镜头
    if buffId == 105305014  then
        local locktaregetid,npcid = self._proxy:GetLockTarget()--转换新索敌目标为npcuuid
        if npcid == 0 and locktaregetid == 0 then
            return
        end
        local targertangle,cameraAngle = self._proxy:GetCameraPosInfo(self._uuid,npcid)
        --XLog.Warning("角度  " ..cameraAngle)
        if cameraAngle > 185 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,105303012,1)
            --XLog.Warning("角度1  " ..cameraAngle)
        elseif cameraAngle <= 185 and cameraAngle >= 175 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053030122,1)
            --XLog.Warning("角度2  " ..cameraAngle)
        elseif cameraAngle < 175 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053030121,1)
            --XLog.Warning("角度3  " ..cameraAngle)
        end
    end
    if buffId == 105305015  then
        if self._proxy:CheckBuffByKind(self._uuid,105303012)  then
            self._proxy:ApplyMagic(self._uuid,self._uuid,105303014,1)
            --XLog.Warning("角度1!")
        elseif self._proxy:CheckBuffByKind(self._uuid,1053030121) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053030141,1)
            --XLog.Warning("角度3!")
        elseif self._proxy:CheckBuffByKind(self._uuid,1053030122) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053030142,1)
            --XLog.Warning("角度2!")
        end
    end
    
    --强化一技能改变技能组
    if buffId == 10580001 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105813)
    end
    --强化二技能改变技能组
    if buffId == 105305004 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105812)
    end
    
    --极昼状态开启magic监听
    if buffId == 10580003 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,10580600,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10580601,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,10580602,1)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105808)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Attack,105802)
    end

end

function XCharR4LivH2:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcRemoveBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    --强化一技能还原技能组
    if buffId == 10580001 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105804)
    end
    --强化二技能还原技能组
    if buffId == 105305004 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105805)
    end

    --极昼状态关闭magic监听
    if buffId == 10580003 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,10580004,1)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Attack,105801)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105807)
        --XLog.Warning("极昼状态结束！！！") 
    end

end

function XCharR4LivH2:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then return end
end


function XCharR4LivH2:OnNpcCastActionAfterEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionAfterEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then return end
    -- 被动叠层
    if SkillId == self._atk06Id then
        self:CoreManager(true,1,false)
        --XLog.Warning("普攻核心被动加2层")
    end
    if SkillId == self._skill10Id or SkillId == self._skill11Id  then
        self:CoreManager(true,2,false)
        --XLog.Warning("技能1核心被动加2层")
    end
    if SkillId == self._skill20Id   then
        self:CoreManager(true,1,false)
        --XLog.Warning("技能2核心被动加1层")
    end
    if SkillId == self._skill32Id or SkillId == self._skill33Id or SkillId == self._skill34Id or SkillId == self._skill40Id or SkillId == self._skill41Id then
        self:CoreManager(false,4,false)
    end
    --强化开启被动
    if SkillId == self._skill12Id then
        self:CoreManager(true,2,true)
    elseif SkillId == self._skill21Id then
        self:CoreManager(true,1,true)
    end 
    -- 技能2衔接删除
    if SkillId == self._skill21Id then
        self._proxy:RemoveBuff(self._uuid,105805004)
    end
    --极限技复活
    if SkillId == self._limitSkill then
        self._proxy:AddTimerTask(1,function()
            local teamList = self._proxy:GetPlayerNpcList()
            --print("玩家1=",teamList[1],"玩家2=",teamList[2],"玩家3=",teamList[3])
            local uuid
            for i = 1, 3 do
                uuid = teamList[i]
                if not uuid or uuid == self._uuid or uuid == 0 then goto continue end
                if self._proxy:CheckNpcFullActionState(uuid, ENpcAction.Reboot, -1) or self._proxy:CheckNpcFullActionState(uuid, ENpcAction.Death, -1) then
                    self._proxy:RebornNpc(self._uuid, uuid)
                    --print("成功复活！玩家：", uuid)
                end
                ::continue::
            end
        end)
    end
    --闪避反击
    if SkillId == self._counterId then
        self._proxy:RemoveBuff(self._uuid,105305016) --移除闪避反击条件buff
    end


end

function XCharR4LivH2:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type, MissileTemplateId)
    --XLog.Warning("counter成功")
    if (Type == 1) then
        --XLog.Warning("闪避成功加buff")
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10510706,1)
        self._proxy:ApplyMagic(self._uuid, self._uuid,105305016,1)
    end
end

function XCharR4LivH2:OnNpcSkillActionKeyframeSendEvent(launcher,eventName,skillActionId,keyFrameId,skillId)
    if launcher ~= self._uuid then return end

    --连携弹刀自动派生逻辑
    if(eventName == "ParryCounter1") then
        --XLog.Warning("释放衔接连携弹刀第二段")
        local targetNpc = self._proxy:GetLockTarget()
        if (targetNpc == 0) or (not targetNpc) then
            --XLog.Warning("无目标丽芙第二段连携弹刀")
            self._proxy:CastAction(self._uuid,self._parryCounter1)
            return
        end
        --XLog.Warning("有目标丽芙第二段连携弹刀")
        self._proxy:CastActionToSearchTarget(self._uuid, self._parryCounter1, targetNpc)
    elseif (eventName == "ParryCounter2")then
        --XLog.Warning("释放衔接连携弹刀第三段")
        local targetNpc = self._proxy:GetLockTarget()
        if (targetNpc == 0) or (not targetNpc) then
            --XLog.Warning("无目标丽芙第三段连携弹刀")
            self._proxy:CastAction(self._uuid,self._parryCounter2)
            return
        end
        --XLog.Warning("有目标丽芙第三段连携弹刀")
        self._proxy:CastActionToSearchTarget(self._uuid, self._parryCounter2, targetNpc)
    end

end


function XCharR4LivH2:CoreManager(isAdd, count,isOpen)
    local level = self._proxy:GetNpcAttribValue(self._uuid,48)
    self._coreLevel = math.floor(level/10)
    XLog.Warning("核心被动层数 = ",self._coreLevel)
    --核心被动开启逻辑
    if isOpen == true and self._coreLevel >= 1 then
        self._proxy:ApplyMagic(self._uuid, self._uuid,10580003,1)
    end
    --核心被动添加逻辑
    if isAdd == true and self._coreLevel < 3 then
        self._coreCount = self._coreCount + count
        if self._coreCount > 12 then
            self._coreCount = 12
        end
        --local level = math.floor(self._coreCount/4)
        --if self._coreLevel < level then
        --    self._proxy:ApplyMagic(self._uuid,self._uuid, 105305001,1)
        --    self._proxy:LaunchMissile(self._uuid, self._uuid, 10539904, 10539904,1)
        --    --XLog.Warning("核心buff加1层！！！","corelevel = ",self._coreLevel)
        --end
        --print("self._coreLevel",self._coreLevel)
    end
    --核心被动清空逻辑
    if isAdd == false then
        self._coreCount = self._coreCount - count
        local level = self._proxy:GetNpcAttribValue(self._uuid,48)
        self._coreLevel = math.floor(level/10)
        --if self._coreLevel == 0 then
        --    self._proxy:RemoveBuff(self._uuid, 105305001)
        --    --XLog.Warning("清空被动层数")
        --elseif self._coreLevel == 1 then
        --    self._proxy:RemoveBuff(self._uuid, 105305001)
        --    self._proxy:ApplyMagic(self._uuid,self._uuid, 105305001,1)
        --    XLog.Warning("清至1层buff")
        --elseif self._coreLevel == 2 then
        --    self._proxy:RemoveBuff(self._uuid, 105305001)
        --    self._proxy:ApplyMagic(self._uuid,self._uuid, 105305001,1,nil,2)
        --    XLog.Warning("清至2层buff")
        --end
    end
end

function XCharR4LivH2:OnNpcWaitRebootEvent(npcUUID, npcPlaceId, npcKind, isPlayer, killerUUID, magicId, deathType, deathId, rebootType, rebootId)
    --if npcUUID ~= self._uuid then return end
    self._coreCount = 0
    self._coreLevel = 0
    self._proxy:RemoveBuff(self._uuid, 105305001)
    self._proxy:ApplyMagic(self._uuid, self._uuid,105308009,1)
    --XLog.Warning("极昼丽芙濒死！！！")
    self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Attack,105801)
    self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105807)
end

return XCharR4LivH2
