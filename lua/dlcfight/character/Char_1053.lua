---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---首席指挥官角色脚本
---@class XChar1053 : XRelinkCharBase
local XChar1053 = XDlcScriptManager.RegCharScript(1053, "XChar1053", Base)

function XChar1053:Init()
    Base.Init(self)
    self._proxy:SetNpcSoftLockTargetConfig(self._uuid, 2)
    self._teamList = self._proxy:GetPlayerNpcList()
    --核心被动变量
    self._coreCount = 0
    self._coreLevel = 0
    --普攻6 id
    self._atk06Id = 105306
    --技能1 id
    self._skill10Id = 105310
    self._skill11Id = 105311
    --技能2 id
    self._skill20Id = 105320
    self._skill21Id = 105321
    --技能3 id
    self._skill3Id = 105330
    self._skill34Id = 105334
    --技能4 id
    self._skill4Id = 105340
    --技能3特殊普攻 id
    self._atkSp1Id = 105331
    self._atkSp2Id = 105332
    self._atkSp3Id = 105333
    --极限技
    self._limitSkill = 105360
    --切换3技能-默认不可使用
    self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,-1)
end

---@param dt number @ delta time
function XChar1053:Update(dt)
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
function XChar1053:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar1053:CheckLimitEnergyAddBuff()
    if not self._proxy:CheckBuffByKind(self._uuid,105305013) then
        local LimitSkillEnergy = self._proxy:GetTeamWorkEnergy(self._uuid)
        if LimitSkillEnergy >= 100 then
            --XLog.Warning("加极限技能buff效果")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053050131,1)
        end
    end
end

function XChar1053:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then return end
    --直播前瞻专属代码
    --if buffId == 8005908 then
    --    self._proxy:CastAction(self._uuid,105340)
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
            self._proxy:ApplyMagic(self._uuid,self._uuid,105303012)
            --XLog.Warning("角度1  " ..cameraAngle)
        elseif cameraAngle <= 185 and cameraAngle >= 175 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053030122)
            --XLog.Warning("角度2  " ..cameraAngle)
        elseif cameraAngle < 175 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053030121)
            --XLog.Warning("角度3  " ..cameraAngle)
        end
    end
    if buffId == 105305015  then
        if self._proxy:CheckBuffByKind(self._uuid,105303012)  then
            self._proxy:ApplyMagic(self._uuid,self._uuid,105303014)
            --XLog.Warning("角度1!")
        elseif self._proxy:CheckBuffByKind(self._uuid,1053030121) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053030141)
            --XLog.Warning("角度3!")
        elseif self._proxy:CheckBuffByKind(self._uuid,1053030122) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1053030142)
            --XLog.Warning("角度2!")
        end
    end
        
end

function XChar1053:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcRemoveBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId == 105305002 then
        self._proxy:AddBuff(self._uuid,105305003)
        --XLog.Warning("极昼状态结束！！！")
    end
end

function XChar1053:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then return end
end


function XChar1053:OnNpcCastActionAfterEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionAfterEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then return end
    -- 被动叠层
    if SkillId == self._atk06Id then
        self:CoreManager(true,1)
        --XLog.Warning("普攻核心被动加2层")
    end
    if SkillId == self._skill10Id or SkillId == self._skill11Id then
        self:CoreManager(true,2)
        --XLog.Warning("技能1核心被动加2层")
    end
    if SkillId == self._skill20Id or SkillId == self._skill21Id  then
        self:CoreManager(true,1)
        --XLog.Warning("技能2核心被动加1层")
    end
    if SkillId == self._skill3Id or SkillId == self._skill34Id then
        self:CoreManager(false,12)
    end
    -- 技能2衔接删除
    if SkillId == self._skill21Id then
        self._proxy:RemoveBuff(self._uuid,105305004)
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
                    self._proxy:AddBuff(uuid,105306012)
                    self._proxy:RebornNpc(self._uuid, uuid)
                    self._proxy:AddBuff(uuid,105306018)
                    --print("成功复活！玩家：", uuid)
                end
                ::continue::
            end
        end)
    end


end

function XChar1053:OnNpcDodge(SourceUUID, AttackerUUID, Type)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type)
    if (Type == 1) then
        self._proxy:AddBuff(self._uuid, 10510704)
    end
end

function XChar1053:CoreManager(isAdd, count)
        --核心被动添加逻辑
        if isAdd == true and self._coreLevel < 3 then
            self._coreCount = self._coreCount + count
            --XLog.Warning("核心被动加上啦！")
            if self._coreCount > 12 then
                self._coreCount = 12
            end
            local level = math.floor(self._coreCount/4)
            if self._coreLevel < level then
                self._proxy:AddBuff(self._uuid, 105305001)
                self._proxy:LaunchMissile(self._uuid, self._uuid, 10539904, 10539904,1)
                --XLog.Warning("核心buff加1层！！！","corelevel = ",self._coreLevel)
            end
            self._coreLevel = self._proxy:GetBuffStacks(self._uuid,105305001)
            if self._coreLevel == 3 then
                self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105305)
            end
            --print("self._coreLevel",self._coreLevel)
        end
        --核心被动清空逻辑
        if isAdd == false then
            self._coreCount = self._coreCount - count
            self._coreLevel = self._coreLevel - math.floor(count/4)
            if self._coreLevel == 0 then
                self._proxy:RemoveBuff(self._uuid, 105305001)
                self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,-1)
                --XLog.Warning("清空被动层数")
            end
        end
end

function XChar1053:OnNpcWaitRebootEvent(npcUUID, npcPlaceId, npcKind, isPlayer, killerUUID, magicId, deathType, deathId, rebootType, rebootId)
    --if npcUUID ~= self._uuid then return end
    self._coreCount = 0
    self._coreLevel = 0
    self._proxy:RemoveBuff(self._uuid, 105305001)
    self._proxy:AddBuff(self._uuid, 105308009)
    --XLog.Warning("极昼丽芙濒死！！！")
    self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,-1)
end

return XChar1053
