---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")
--local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
---共斗_极昼丽芙_第一风格角色脚本
---@class XCharR4LivH : XRelinkCharBase
local XCharR4LivH = XDlcScriptManager.RegCharScript(1053, "XCharR4LivH", Base)
--核心改造2伤害ID
XCharR4LivH._coreLazerDamgMagic = {
    [105302031] = true,
    [105302032] = true,
    [105302033] = true,
    [105302034] = true,
    [105302035] = true,
    [105302036] = true,
    [10580131] = true,
    [10580132] = true,
    [10580133] = true,
    [10580134] = true,
}
function XCharR4LivH:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self._proxy:SetNpcSoftLockTargetConfig(self._uuid, 2)
    self._teamList = {}
    self._teamCount = 0
    --风格标记BUFF：决定了下面某些逻辑只有第一风格会跑or第二风格会跑~(●'◡'●)~
    self._LivMod1 = 10535001
    self._LivMod2 = 10580005
    --风格技能组ID管理
    self._LivMod2_SG15Id = 105815 --第二风格专属强化1技能
    --通用技能组ID初始化
    if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
        --XLog.Warning("第一风格通用技能组初始化")
        self._LivMod_SG01Id = 105301
        self._LivMod_SG02Id = 105302
        self._LivMod_SG04Id = 105304
        self._LivMod_SG05Id = 105305
        self._LivMod_SG07Id = 105307
        self._LivMod_SG08Id = 105308
        self._LivMod_SG12Id = 105312
        self._LivMod_SG13Id = 105313
        self._LivMod_SG14Id = 105314
    elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
        --XLog.Warning("第二风格通用技能组初始化")
        self._LivMod_SG01Id = 105801
        self._LivMod_SG02Id = 105802
        self._LivMod_SG04Id = 105804
        self._LivMod_SG05Id = 105805
        self._LivMod_SG07Id = 105807
        self._LivMod_SG08Id = 105808
        self._LivMod_SG12Id = 105812
        self._LivMod_SG13Id = 105813
        self._LivMod_SG14Id = 105814
    end
    --核心被动变量
    self._coreCount = 0
    self._coreLevel = 0
    --普攻6 id
    self._atk06Id = 105306
    self._counterId = 105309
    --技能1 id
    self._skill10Id = 105310
    self._skill11Id = 105311
    self._skill12Id = 105812 --第二风格专属强化1技能
    --技能2 id
    self._skill20Id = 105320
    self._skill21Id = 105321
    --技能3 id
    self._skill3Id = 105330
    self._skill32Id = 105332
    self._skill33Id = 105333
    self._skill34Id = 105334
    --技能4 id
    self._skill4Id = 105340
    self._skill41Id = 105341
    --连携弹刀 id
    self._parryCounter1 = 105372
    self._parryCounter2 = 105374
    --极限技
    self._limitSkill = 105360
    --被动【援助治疗】子弹列表
    self._cureLaunchId = { [1] = 10539907, [2] = 10539908 }
    self._cureMissileId = { [1] = 10539905, [2] = 10539906 }
    --治疗magicID
    self._healTeamEffect = 105306019
    self._healSelfEffect = 105306020
    self._coreHealDotMagic = 1053080011
    self._coreHealHitMagic = 1053080012
    self._skill31HealMagic = 105308002  --第一风格的治疗magic
    self._skill31HealMagicPro = 1053080021  --核心改造1的治疗magic
    self._skill32HealMagic = 1053080022 --第一风格的治疗magic
    self._skill31HealMagic2 = 1053080023 --第二风格的治疗magic
    self._skill32HealMagic2 = 1053080024 --第二风格的治疗magic
    self._ultHealMagicPro = 10530801
    self._limitHeal = 105308005
    --技能4增伤magicID
    self._skill4AtkUp = 105308004
    self._skill4AtkUp2 = 10530812
    --核心buffID
    self._coreHealUp = 10530802
    self._coreAtkUp = 10530803
    --极昼形态标记magicID
    self._coreStateMagic = 105305002
    --核心被动能量magicID
    self._coreMagic10 = 105308006
    self._coreMagic20 = 105308007
    self._coreMagicD40 = 10530807
    self._coreMagicD80 = 10530808
    self._coreMagicD120 = 105308009
    --第二风格核心长按条件magicID
    self._skill3Mod2Magic = 10580006
    --注册技能事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid)
    --NPC时间
    self._npcTime = 0
    self._npcTimeTest = 0
    --专属装备magicID
    --核心改造
    self._coreMod1G = 10531001
    self._coreMod1R = 10531002
    self._coreMod2G = 10531003
    self._coreMod2R = 10531004
    --次要改造
    self._secMod1 = 10531005
    self._secMod2 = 10531006
    self._secMod3 = 10531007
    self._secMod4 = 10531008
    --专属装备变量合集
    self._coreMod1Open = false
    self._secMod1Open = false 
    --专属装备BUFFID合集
    self._coreMod1Atkup = 105308013
    self._coreMod2DamgUp = 105308026
    self._coreMod2LazerDamgeUp = 105308020
    self._secMod3AddCore = 105308015
    self._secMod3ActiveCD = 105308025
    --核心改造2红初始化时提升伤害上限
    if self._proxy:CheckBuffByKind(self._uuid, self._coreMod2R) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMod2DamgUp, 1)
    end
    --次级改造3、4双风格特判减CD
    self._CDGroupID = 1
    if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
        self._CDGroupID = 1
    elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
        self._CDGroupID = 2
    end
    self._secMod3CD = { [1] = 105308016, [2] = 105308021 }
    self._secMod4Skill31CD = { [1] = 105308017, [2] = 105308022 }
    self._secMod4Skill32CD = { [1] = 105308018, [2] = 105308023 }
    self._secMod4Skill4CD = { [1] = 105308019, [2] = 105308024 }

end

--region EventCallBack
function XCharR4LivH:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
end

---@param dt number @ delta time
function XCharR4LivH:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharR4LivH:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharR4LivH:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --次要改造3-狂暴技逻辑1000497BOSS的狂暴技标记
    if buffId == 1000497 and self._proxy:CheckBuffByKind(self._uuid, self._secMod3) and not self._proxy:CheckBuffByKind(self._uuid, self._secMod3ActiveCD) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._secMod3CD[self._CDGroupID], 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._secMod3ActiveCD, 1)
        if not self._proxy:CheckBuffByKind(self._uuid, self._coreStateMagic) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._secMod3AddCore, 1)
            self:CoreManager(true, 12)
        end
    end

    if npcUUID ~= self._uuid then
        return
    end
    --直播前瞻专属代码
    --if buffId == 8005908 then
    --    self._proxy:CastAction(self._uuid,105340)
    --end

    --技能4双镜头
    if buffId == 105305014 then
        local locktaregetid, npcid = self._proxy:GetLockTarget()--转换新索敌目标为npcuuid
        if npcid == 0 and locktaregetid == 0 then
            return
        end
        local targertangle, cameraAngle = self._proxy:GetCameraPosInfo(self._uuid, npcid)
        --XLog.Warning("角度  " ..cameraAngle)
        if cameraAngle > 185 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 105303012, 1)
            --XLog.Warning("角度1  " ..cameraAngle)
        elseif cameraAngle <= 185 and cameraAngle >= 175 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1053030122, 1)
            --XLog.Warning("角度2  " ..cameraAngle)
        elseif cameraAngle < 175 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1053030121, 1)
            --XLog.Warning("角度3  " ..cameraAngle)
        end
    end
    if buffId == 105305015 then
        if self._proxy:CheckBuffByKind(self._uuid, 105303012) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 105303014, 1)
            --XLog.Warning("角度1!")
        elseif self._proxy:CheckBuffByKind(self._uuid, 1053030121) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1053030141, 1)
            --XLog.Warning("角度3!")
        elseif self._proxy:CheckBuffByKind(self._uuid, 1053030122) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1053030142, 1)
            --XLog.Warning("角度2!")
        end
    end

    --强化一技能改变技能组
    if buffId == 10580001 and self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._LivMod2_SG15Id)
        self._proxy:StartButtonCountDown(self._uuid,ENpcOperationKey.Ball1,1.5)
    end

    --强化二技能改变技能组
    if buffId == 105305004 then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball2, self._LivMod_SG12Id)
        self._proxy:StartButtonCountDown(self._uuid,ENpcOperationKey.Ball2,2.5)
    end

    --极昼状态开启magic监听
    if buffId == self._coreStateMagic then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10536011, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10536012, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10536013, 1)
        --次级改造1变身时清除强化普攻2的条件buff（因为必定会变成强化普攻1所以不应该清楚对应条件buff），且重置技能组和按钮倒计时
        if self._secMod1Open and self._proxy:CheckBuffByKind(self._uuid, self._secMod1) then
            self._secMod1Open = false
            self._proxy:RemoveBuffByKindAndCount(self._uuid, 1053050011, 1)
            --极昼状态切换技能3治疗为防护罩，普攻替换为长按普攻1
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._LivMod_SG08Id)
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG13Id)
            --self._proxy:ClearButtonCountDown(self._uuid, ENpcOperationKey.Attack)
            self._proxy:StartButtonCountDown(self._uuid,ENpcOperationKey.Attack,8)
        elseif not self._secMod1Open then
            --常规变身，极昼状态切换技能3治疗为防护罩，普攻替换为长按普攻1
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._LivMod_SG08Id)
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG13Id)
            self._proxy:StartButtonCountDown(self._uuid,ENpcOperationKey.Attack,8)
        end
        --次级改造4逻辑
        if self._proxy:CheckBuffByKind(self._uuid, self._secMod4) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._secMod4Skill4CD[self._CDGroupID], 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._secMod4Skill31CD[self._CDGroupID], 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._secMod4Skill32CD[self._CDGroupID], 1)
        end
    end

end

function XCharR4LivH:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcRemoveBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then return end
    --极昼状态结束技能3改回默认技能组
    if buffId == self._coreStateMagic then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 105305003, 1)
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._LivMod_SG07Id)
        self._proxy:ClearButtonCountDown(self._uuid, ENpcOperationKey.Attack)
        --通过装备改造技能4进入核心后，检查被动层数若符合修改技能组为核心强化普攻
        if self._coreLevel == 3 and self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
            --第一风格：核心长按普攻开启
            self._coreMod1Open = true
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG02Id)
        elseif self._coreLevel >= 2 and self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
            --第二风格：核心长按普攻开启
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._skill3Mod2Magic, 1)
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG02Id)
        elseif self._coreLevel ~= 3 and self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
            --第一风格：以上检查都没有通过，走换回技能组逻辑，且核心等于3时核心普攻不换做保底
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG01Id)
        elseif self._coreLevel >= 2 and self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
            --第二风格：以上检查都没有通过，再走通用换回技能组逻辑，且核心等于3时核心普攻不换做保底
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG01Id)
        end
        --第二风格变身被动攻击力提升buff移除
        if self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
            self._proxy:RemoveBuffByKindAndCount(self._uuid, self._coreAtkUp, 1)
        end
        --XLog.Warning("极昼状态结束！！！") 
    end
    --第二风格：强化一技能还原技能组
    if buffId == 10580001 and self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._LivMod_SG04Id)
        self._proxy:ClearButtonCountDown(self._uuid, ENpcOperationKey.Ball1)
    end

    --强化二技能还原技能组
    if buffId == 105305004 then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball2, self._LivMod_SG05Id)
        self._proxy:ClearButtonCountDown(self._uuid, ENpcOperationKey.Ball2)
    end

end

function XCharR4LivH:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then
        return
    end

    --核心2段技能组替换
    if SkillId == self._skill32Id then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG14Id)
    end
    --次级改造1，技能组重置，强普条件重置
    if SkillId == self._skill34Id and self._proxy:CheckBuffByKind(self._uuid, self._secMod1) then
        --变量记录本次变身是由技能4发起的
        self._secMod1Open = true
        self._proxy:RemoveBuffByKindAndCount(self._uuid, self._coreStateMagic, 1)
    end
    --第二风格核心变身后self._skill3Mod2Magic移除
    if SkillId == self._skill3Id then
        self._proxy:RemoveBuffByKindAndCount(self._uuid, self._skill3Mod2Magic, 1)
    end
    --防护罩快速信息逻辑
    if SkillId == self._skill41Id then
        self._proxy:ShowQuickMessage(3)
    end

end

function XCharR4LivH:OnNpcCastActionAfterEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionAfterEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then
        return
    end

    -- 被动叠层
    if not self._proxy:CheckBuffByKind(self._uuid, self._coreStateMagic) then
        if SkillId == self._atk06Id then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMagic10, 1)
            self:CoreManager(true, 1)
            --XLog.Warning("普攻核心被动加2层")
        end
        if SkillId == self._skill10Id or SkillId == self._skill11Id then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMagic20, 1)
            self:CoreManager(true, 2)
            --XLog.Warning("技能1核心被动加2层")
        end
        if SkillId == self._skill20Id or SkillId == self._skill21Id then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMagic10, 1)
            self:CoreManager(true, 1)
            --XLog.Warning("技能2核心被动加1层")
        end
        --第二风格专属强化1技能
        if SkillId == self._skill12Id then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMagic20, 1)
            self:CoreManager(true, 2)
        end
        --核心改造2+被动buff移除逻辑
        if SkillId == self._skill33Id then
            --第二风格：攻击力buff免疫关闭
            if self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10530809, 1)
            end
            --核心改造2
            if self._proxy:CheckBuffByKind(self._uuid, self._coreMod2G) or self._proxy:CheckBuffByKind(self._uuid, self._coreMod2R) then
                self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMagic20, 1)
                self:CoreManager(true, 2)
            end
        end
    end

    if SkillId == self._skill3Id then
        if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMagicD120, 1) --第一风格清除12层
            self:CoreManager(false, 12)
        elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMagicD80, 1) --第二风格清除8层
            self:CoreManager(false, 8)
            self._proxy:RemoveBuffByKindAndCount(self._uuid, 105305001, 2)
        end
    end

    --第二风格技能3-1技能4被动扣除
    if self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
        if SkillId == self._skill4Id or SkillId == self._skill34Id then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMagicD40, 1)
            self:CoreManager(false, 4)
            self._proxy:RemoveBuffByKindAndCount(self._uuid, 105305001, 1)
        end
    end

    -- 技能2衔接删除
    if SkillId == self._skill21Id then
        self._proxy:RemoveBuff(self._uuid, 105305004)
    end

    --激光2段退出极昼形态
    if SkillId == self._skill33Id then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 105305003, 1)
    end

    --极限技复活
    if SkillId == self._limitSkill then
        self._proxy:SetTeamWorkSkillNpcRemainUseCount(self._uuid, 0)
        self:TeamListManager(2)
        self._proxy:AddTimerTask(1, function()
            for i, v in ipairs(self._teamList) do
                --复活死去的队友并对其添加复活特效
                self._proxy:RebornNpc(self._uuid, self._teamList[i])
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], 105306018, 1) --丽芙复活特效
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], 1000477, 1)
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], 1000478, 1)
                --print("成功复活！玩家：", uuid)
            end
        end)
    end

    --闪避反击
    if SkillId == self._counterId then
        self._proxy:RemoveBuff(self._uuid, 105305016) --移除闪避反击条件buff
    end

end

function XCharR4LivH:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type, MissileTemplateId)
    --XLog.Warning("counter成功")
    if (Type == 1) then
        --XLog.Warning("闪避成功加buff")
        self._proxy:ApplyMagic(self._uuid, self._uuid, 105305016, 1)
    end
end

function XCharR4LivH:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    if launcher ~= self._uuid then
        return
    end

    --连携弹刀自动派生逻辑
    if (eventName == "ParryCounter1") then
        --XLog.Warning("释放衔接连携弹刀第二段")
        local targetNpc = self._proxy:GetLockTarget()
        if (targetNpc == 0) or (not targetNpc) then
            --XLog.Warning("无目标丽芙第二段连携弹刀")
            self._proxy:CastAction(self._uuid, self._parryCounter1)
            return
        end
        --XLog.Warning("有目标丽芙第二段连携弹刀")
        self._proxy:CastActionToSearchTarget(self._uuid, self._parryCounter1, targetNpc)
    elseif (eventName == "ParryCounter2") then
        --XLog.Warning("释放衔接连携弹刀第三段")
        local targetNpc = self._proxy:GetLockTarget()
        if (targetNpc == 0) or (not targetNpc) then
            --XLog.Warning("无目标丽芙第三段连携弹刀")
            self._proxy:CastAction(self._uuid, self._parryCounter2)
            return
        end
        --XLog.Warning("有目标丽芙第三段连携弹刀")
        self._proxy:CastActionToSearchTarget(self._uuid, self._parryCounter2, targetNpc)
    end

    --技能4增伤
    if eventName == "Skill34_teamAtkUp" then
        if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._skill4AtkUp, 1)
        elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._skill4AtkUp2, 1)
        end
        self:TeamListManager(1)
        for i, v in ipairs(self._teamList) do
            if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill4AtkUp, 1)
            elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill4AtkUp2, 1)
            end
        end
        --次级改造1，启动被动时增加核心buff逻辑，区分第一第二风格
        if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) and self._proxy:CheckBuffByKind(self._uuid, self._secMod1) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreHealUp, 1)
        elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) and self._proxy:CheckBuffByKind(self._uuid, self._secMod1) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreAtkUp, 1)
        end
    end

    --极昼全部的治疗逻辑
    --技能3-治疗
    if eventName == "Skill31_healSelf" then
        if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._skill31HealMagic, 1)
        elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._skill31HealMagic2, 1)
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._healSelfEffect, 1)
        --XLog.Warning("Skill31_healSelf 治疗自己！")
    elseif eventName == "Skill31_healTeam" then
        self:TeamListManager(1)
        for i, v in ipairs(self._teamList) do
            if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill31HealMagic, 1)
            elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill31HealMagic2, 1)
            end
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._healTeamEffect, 1)
            --核心改造1逻辑
            if self._proxy:CheckBuffByKind(self._uuid, self._coreMod1R) and self._proxy:CheckBuffByKind(self._uuid, self._coreMod1G) and self._coreMod1Open then
                --金红一起带
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill31HealMagicPro)
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._coreMod1Atkup)
            elseif self._proxy:CheckBuffByKind(self._uuid, self._coreMod1R) and self._coreMod1Open then
                --红-R
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill31HealMagicPro)
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._coreMod1Atkup)
            elseif self._proxy:CheckBuffByKind(self._uuid, self._coreMod1G) and self._coreMod1Open then
                --金-G
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill31HealMagicPro)
            end
            --XLog.Warning("Skill31_healSelf 治疗队友！队友是？",self._teamList[i])
        end
        self._coreMod1Open = false
    end
    --技能3-防护罩
    if eventName == "Skill32_healAll" then
        self:TeamListManager(1)
        for i, v in ipairs(self._teamList) do
            if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill32HealMagic, 1)
            elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill32HealMagic2, 1)
            end
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._healTeamEffect, 1)
            --核心改造1逻辑
            if self._proxy:CheckBuffByKind(self._uuid, self._coreMod1R) and self._proxy:CheckBuffByKind(self._uuid, self._coreMod1G) and self._coreMod1Open then
                --金红一起带
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill31HealMagicPro)
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._coreMod1Atkup)
            elseif self._proxy:CheckBuffByKind(self._uuid, self._coreMod1R) and self._coreMod1Open then
                --红-R
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill31HealMagicPro)
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._coreMod1Atkup)
            elseif self._proxy:CheckBuffByKind(self._uuid, self._coreMod1G) and self._coreMod1Open then
                --金-G
                self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._skill31HealMagicPro)
            end
            --XLog.Warning("Skill32_healAll 治疗队友！队友是？",self._teamList[i])
        end
        self._coreMod1Open = false
        if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._skill32HealMagic, 1)
        elseif self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._skill32HealMagic2, 1)
        end
    end
    --极限技
    if eventName == "Limit_heal" then
        self:TeamListManager(1)
        for i, v in ipairs(self._teamList) do
            self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._limitHeal, 1)
            self._proxy:ApplyMagic(self._uuid, self._teamList[i], self._healTeamEffect, 1)
            --XLog.Warning("Skill32_healAll 治疗队友！队友是？",self._teamList[i])
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._limitHeal, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._healSelfEffect, 1)
    end

end

function XCharR4LivH:ChangeDamageBeforeCalc(eventArgs)
    Base.ChangeDamageBeforeCalc(self, eventArgs)
    self._uuid = self._proxy:GetSelfNpcId()
    if eventArgs.Launcher ~= self._uuid then
        return
    end

    self._coreMod2LazerDamgeUp = 105308020
    self._coreMod2R = 10531004
    --初始化END
    if self._proxy:CheckBuffByKind(self._uuid, self._coreMod2R) then
        if self._coreLazerDamgMagic[eventArgs.Id] then
            --XLog.Warning("核心激光伤害加成")
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreMod2LazerDamgeUp, 1, eventArgs.ContextId, 1)
        end
    end

end

function XCharR4LivH:TeamListManager(type)
    --type = 1：非濒死队友单位列表；type = 2：濒死队友单位列表
    self._teamList = {}
    self._teamCount = 0 --队伍人数记录每次进入进行初始化，下方for函数遍历后重新赋值统计队友数量；
    --遍历列表看看现在有多少玩家
    local allTeamList = self._proxy:GetPlayerNpcList()
    local allCount = 0 --整队包括自己有多少人
    for i, v in ipairs(allTeamList) do
        allCount = i
    end
    --XLog.Warning("全队有多少人？", allCount)
    if type == 1 then
        local uuid
        local count = 1
        for i = 1, allCount do
            uuid = allTeamList[i]
            --XLog.Warning("队友是哪位？", allTeamList[i])
            if not uuid or uuid == self._uuid or uuid == 0 then
                goto continue
            end
            if not (self._proxy:CheckNpcFullActionState(uuid, ENpcAction.Reboot, -1) or self._proxy:CheckNpcFullActionState(uuid, ENpcAction.Death, -1)) then
                self._teamList[count] = uuid
                if count == 1 then
                    count = count + 1
                end
                self._teamCount = count
            end
            :: continue ::
        end
    end

    if type == 2 then
        local uuid
        local count = 1
        for i = 1, allCount do
            uuid = allTeamList[i]
            --XLog.Warning("队友是哪位？", allTeamList[i])
            if not uuid or uuid == self._uuid or uuid == 0 then
                goto continue
            end
            if self._proxy:CheckNpcFullActionState(uuid, ENpcAction.Reboot, -1) or self._proxy:CheckNpcFullActionState(uuid, ENpcAction.Death, -1) then
                self._teamList[count] = uuid
                if count == 1 then
                    count = count + 1
                end
                self._teamCount = count
            end
            :: continue ::
        end
    end
end

function XCharR4LivH:CoreManager(isAdd, count)
    --核心被动添加逻辑
    if isAdd == true and self._coreLevel < 3 then
        self._coreCount = self._coreCount + count
        --XLog.Warning("核心被动加上啦！")
        if self._coreCount > 12 then
            self._coreCount = 12
        end
        local level = math.floor(self._coreCount / 4)
        if self._coreLevel < level then
            local addCount = level - self._coreLevel  --用于决定后续核心magic要给多少层，第一风格的治疗子弹给多少个
            self._proxy:ApplyMagic(self._uuid, self._uuid, 105305001, 1, 0, addCount)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10530804, 1, 0, addCount) --核心层数自定义能量+1，用于UI表现
            --第一风格逻辑：核心被动治疗【援助治疗】逻辑，筛查队友状态并建立队友列表，以队友为目标释放治疗子弹
            if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
                self:TeamListManager(1)
                for i = 1, addCount do
                    for i, v in ipairs(self._teamList) do
                        --XLog.Warning("原来是你啊队友！", teamMateList[i])
                        self._proxy:LaunchMissile(self._uuid, self._teamList[i], self._cureLaunchId[i], self._cureMissileId[i], 1)
                    end
                end
            end
            --第一风格逻辑：【援助治疗】逻辑END
        end
        self._coreLevel = self._proxy:GetBuffStacks(self._uuid, 105305001)
        --第一风格：核心长按普攻开启
        if self._coreLevel == 3 then
            self._coreMod1Open = true
            if self._proxy:CheckBuffByKind(self._uuid, self._LivMod1) then
                self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG02Id)
            end
        end
        --第二风格：核心长按普攻开启
        if self._coreLevel >= 2 and self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self._skill3Mod2Magic, 1)
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG02Id)
        end
    end
    --核心被动清除逻辑
    if isAdd == false then
        self._coreCount = self._coreCount - count
        if self._coreCount <= 0 then
            self._coreCount = 0
        end
        self._coreLevel = self._coreLevel - math.floor(count / 4)
        if self._coreLevel <= 0 then
            self._coreLevel = 0
        end
        --第二风格专属逻辑：低于8层时换回技能组1-普攻
        if self._coreLevel < 2 and self._proxy:CheckBuffByKind(self._uuid, self._LivMod2) then
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG01Id)
        end
        if self._coreLevel == 0 then
            self._proxy:RemoveBuff(self._uuid, 105305001)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10530805, 1) --核心层数自定义能量清空，用于UI表现
            --XLog.Warning("清空被动层数")
        end
    end
end

--跳跃隐藏武器
function XCharR4LivH:OnEnterJumpWeaponHide()
    --进跳跃隐藏
    Base.OnEnterJumpWeaponHide(self)
    --XLog.Warning("跳跃隐藏")
    self._proxy:ApplyMagic(self._uuid, self._uuid, 10536016, 1)
end

function XCharR4LivH:OnExitJumpWeaponShow()
    -- 出跳跃显示
    Base.OnExitJumpWeaponShow(self)
    --XLog.Warning("离开跳跃显示")
    self._proxy:ApplyMagic(self._uuid, self._uuid, 10536017, 1)
end

function XCharR4LivH:OnNpcWaitRebootEvent(npcUUID, npcPlaceId, npcKind, isPlayer, killerUUID, magicId, deathType, deathId, rebootType, rebootId)
    Base.OnNpcWaitRebootEvent(self, npcUUID, npcPlaceId, npcKind, isPlayer, killerUUID, magicId, deathType, deathId, rebootType, rebootId)
    if npcUUID ~= self._uuid then return end
    self._coreCount = 0
    self._coreLevel = 0
    self._proxy:RemoveBuff(self._uuid, 105305001)
    self._proxy:RemoveBuffByKindAndCount(self._uuid, self._skill3Mod2Magic, 1)
    --清空48、49核心能量
    self._proxy:ApplyMagic(self._uuid, self._uuid, 105308009, 1)
    self._proxy:ApplyMagic(self._uuid, self._uuid, 10530805, 1)
    --XLog.Warning("极昼丽芙濒死！！！")
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._LivMod_SG01Id)
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._LivMod_SG07Id)
end

return XCharR4LivH
