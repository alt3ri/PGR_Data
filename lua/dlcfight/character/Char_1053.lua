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
    --技能4 id
    self._skill4Id = 105340
    --技能3特殊普攻 id
    self._atkSp1Id = 105331
    self._atkSp2Id = 105332
    self._atkSp3Id = 105333
    --极限技
    self._limitSkill = 105360

    --出生镜头
    --self._proxy:AddBuff(self._uuid, 1053060092)
end

---@param dt number @ delta time
function XChar1053:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar1053:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar1053:OnNpcAddBuffEvent(CasterUUID, NpcUUID, BuffTableId, BuffKinds, BuffId)
    Base.OnNpcAddBuffEvent(CasterUUID, NpcUUID, BuffTableId, BuffKinds, BuffId)
    if CasterUUID ~= self._uuid then return end
end

function XChar1053:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then return end

    --if SkillId == self._limitSkill then
    --    self._proxy:CastTeamWorkEnergy(self._uuid,100, self._limitSkill)
    --    local TeamWorkEnergy = self._proxy:GetTeamWorkEnergy(self._uuid)
    --    local TeamMaxEnergy = self._proxy:GetTeamWorkMaxEnergy()
    --    XLog.Warning("扣团队能量100","TeamWorkEnergy = ",TeamWorkEnergy,"TeamMaxEnergy = ",TeamMaxEnergy)
    --end
    --
    --if SkillId == self._skill10Id or SkillId == self._skill11Id then
    --    self._proxy:AddTeamWorkEnergy(self._uuid,100)
    --    local TeamWorkEnergy = self._proxy:GetTeamWorkEnergy(self._uuid)
    --    local TeamMaxEnergy = self._proxy:GetTeamWorkMaxEnergy()
    --    XLog.Warning("加团队能量100","TeamWorkEnergy = ",TeamWorkEnergy,"TeamMaxEnergy = ",TeamMaxEnergy)
    --end

    --if SkillId == self._skill4Id then
    --    self._teamList = self._proxy:GetPlayerNpcList()
    --    --for i = 1, 3 do
    --    --    if  self._teamList[i] == self._uuid or self._teamList[i] ~= 0  then
    --    --        self._proxy:AddBuff(self._teamList[i],105306010)
    --    --        --self._proxy:AddTimerTask(0.5,function()
    --    --            self._proxy:AddBuff(self._teamList[i],105308002)
    --    --        --end)
    --    --        print("技能4成功治疗！玩家：",self._teamList[i])
    --    --    end
    --    --end
    --end
end


function XChar1053:OnNpcCastActionAfterEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionAfterEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then return end

    if SkillId == self._atk06Id then
        self:CoreManager(true,1)
        XLog.Warning("普攻核心被动加2层")
    end
    if SkillId == self._skill10Id or SkillId == self._skill11Id then
        self:CoreManager(true,2)
        XLog.Warning("技能1核心被动加2层")
    end
    if SkillId == self._skill20Id or SkillId == self._skill21Id  then
        self:CoreManager(true,1)
        XLog.Warning("技能2核心被动加2层")
    end
    if SkillId == self._atkSp1Id or SkillId == self._atkSp2Id then
        self:CoreManager(false,4)
    elseif SkillId == self._atkSp3Id then
        self:CoreManager(false,8)
    end
    --极限技复活
    if SkillId == self._limitSkill then
        local teamList = self._proxy:GetPlayerNpcList()
        --print("玩家1=",teamList[1],"玩家2=",teamList[2],"玩家3=",teamList[3])
        local uuid
        for i = 1, 3 do
            uuid = teamList[i]
            if not uuid or uuid == self._uuid or uuid == 0 then goto continue end

            if self._proxy:CheckNpcFullActionState(teamList[i],7)
                    or self._proxy:CheckNpcFullActionState(teamList[i],9)
                    or self._proxy:CheckNpcFullActionState(teamList[i],5) then
                self._proxy:AddBuff(teamList[i],105306012)
                self._proxy:SetNpcRescuedState(self._uuid,teamList[i], ture)
                self._proxy:AddTimerTask(1.35,function()
                    self._proxy:RebornNpc(self._uuid,teamList[i])
                    print("成功复活！玩家：",teamList[i])
                end)
            end

            ::continue::
        end
    end


end

function XChar1053:OnNpcDodge(AttackerUUID, Type)
    Base.OnNpcDodge(self, AttackerUUID, Type)

    if (Type == 1) then
        self._proxy:AddBuff(self._uuid, 10510704)
    end
end

function XChar1053:CoreManager(isAdd, count)
        --local teamList = self._proxy:GetPlayerNpcList()
        --for i = 1, 3 do
        --    if  teamList[i] ~= 0 then
        --        self._proxy:AddBuff(teamList[i],105306010)
        --        --self._proxy:AddTimerTask(0.5,function()
        --            self._proxy:AddBuff(teamList[i],105308001)
        --        --end)
        --        print("被动成功治疗！玩家：",teamList[i])
        --    end
        --end
        --核心被动添加逻辑
        if isAdd == true and self._coreLevel < 3 then
            self._coreCount = self._coreCount + count
            XLog.Warning("核心被动加上啦！")
            if self._coreCount > 12 then
                self._coreCount = 12
            end
            local level = math.floor(self._coreCount/4)
            if self._coreLevel < level then
                self._proxy:AddBuff(self._uuid, 105305001)
                self._proxy:LaunchMissile(self._uuid, self._uuid, 10539904, 10539904,1)
                XLog.Warning("核心buff加1层！！！","corelevel = ",self._coreLevel)
                    if level == 3 then
                    --    self._proxy:LaunchMissile(self._uuid, self._uuid, 10539901, 10539901, 1)
                    --    --self._proxy:AddBuff(self._uuid, 105306006)
                    --    XLog.Warning("核心被动满4层")
                    --elseif level == 2 then
                    --    self._proxy:LaunchMissile(self._uuid, self._uuid, 10539902, 10539902,1)
                    --    --self._proxy:AddBuff(self._uuid, 105306007)
                    --    XLog.Warning("核心被动满8层！！！")
                    --elseif level == 3 then
                        self._proxy:LaunchMissile(self._uuid, self._uuid, 10539903, 10539903,1)
                        --self._proxy:AddBuff(self._uuid, 105306008)
                        XLog.Warning("核心被动满12层！！！！！")
                    end
            end
            self._coreLevel = self._proxy:GetBuffStacks(self._uuid,105305001)
            print("self._coreLevel",self._coreLevel)
        end
        --核心被动清空逻辑
        if isAdd == false then
            self._proxy:DestroyAllMissileDependOnLauncher(self._uuid)
            self._coreCount = self._coreCount - count
            self._coreLevel = self._coreLevel - math.floor(count/4)
            if self._coreLevel == 0 then
                self._proxy:RemoveBuff(self._uuid, 105305001)
                XLog.Warning("清空被动层数")
            end
        end
end

function XChar1053:CureManager(magicId, time)

end

return XChar1053
