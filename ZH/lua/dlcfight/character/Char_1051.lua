---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")
local EGameplayTag = require("Enum/XGameplayTag")

---Relink-R5露西亚脚本
---@class XChar1051 : XRelinkCharBase
local XCharR5Lucia1 = XDlcScriptManager.RegCharScript(1051, "XChar1051", Base)
--设置登龙伤害表（用于核心插件）
XCharR5Lucia1.DenglongDmgTbl = {
    [10516010] = true,
    [10516101] = true,
    [10516105] = true,
    [10516201] = true,
    [10516205] = true,
    [10516310] = true,
    [10516314] = true,
    [10516401] = true,
    [10516410] = true,
}
XCharR5Lucia1.DenglongEquipDmgTbl = {
    [10516010] = true,
    [10516101] = true,
    [10516105] = true,
    [10516201] = true,
    [10516205] = true,
    [10516310] = true,
    [10516314] = true,
    [10516401] = true,
    [10516410] = true,
    [10511015] = true,
    [10511025] = true,
}
--设置剑气伤害(用于核心插件)
XCharR5Lucia1.JianqiDmgTbl = {
    [10514101] = true,
    [10514601] = true,
}

function XCharR5Lucia1:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    self._canCastSkill = false
    self._useShenglong = false
    self._addDenglongBuff = true
    self._CastJianqi = false
    self._canUseTeamSkill = true
    --设置技能按键
    self._AttackButton = 105101
    self._Null = 105115

    --设置小太刀剑气技能组
    self._JianqiSkillGroup = {}
    self._JianqiSkillGroup[1] = 1051042
    self._JianqiSkillGroup[2] = 1051041
    self._JianqiSkillGroup[3] = 1051043
    self._JianqiSkillGroup[4] = 1051045

    --设置跃升登龙技能组
    self._DenglongExSkillGroup = {}
    self._DenglongExSkillGroup[1] = 1051064
    self._DenglongExSkillGroup[2] = 1051065
    self._DenglongExSkillGroup[3] = 1051066
    self._DenglongExSkillGroup[4] = 1051067
    self._DenglongExSkillGroup[5] = 1051068

    --设置剑气技能计数器
    self._jianqiCounter = 0
    self._canCastSkill = false
    --设置大太刀技能组
    self._SkillExId = {
        [1051046] = true,
        [1051047] = true,
        [1051048] = true,
        [1051049] = true,
        [1051050] = true,
        [1051051] = true,
        [1051052] = true,
        [1051053] = true,
        [1051054] = true,
        [1051055] = true,
        [1051056] = true,
        [1051057] = true,
        [1051060] = true,
        [1051061] = true,
        [1051062] = true,
        [1051063] = true,
        [1051064] = true,
        [1051065] = true,
        [1051066] = true,
        [1051067] = true,
        [1051068] = true,
        [1051091] = true,
        [1051093] = true,
        [1051080] = true,
        [1051081] = true,
        [1061082] = true,
        [1051083] = true,
        [1051085] = true,
        [1051086] = true,
        [1051088] = true,
        [1051089] = true,
        [1051096] = true,
    }
    --设置闪避技能组
    self._SkillDodgeId = {
        [1051006] = true,
        [1051007] = true,
        [1051008] = true,
        [1051009] = true,
    }

    --初始化登龙值
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1051001, 1)
    --初始化大太刀buff初始能量值
    self._proxy:ApplyMagic(self._uuid, self._uuid, 10513122, 1)
    --初始化UI状态
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1051061, 1)
    --设置小太刀标记
    if not isGainControl then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10510001, 1)
    end

    --注册技能事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)            --注册伤害前事件

    --设置极限技ID
    self._limitSkillId = 1051096

    --设置居合技能ID
    self._JuheXuli = 1051022
    self._JuheXuliSkillTypeTwo = 1051025
    self._JuheXuliSkill = 1051026

    --设置核心插件子弹发射ID
    self._lunchId = {}
    self._lunchId[1] = 10511011
    self._lunchId[2] = 10511012
    self._lunchId[3] = 10511013
    self._lunchId[4] = 10511014

    --重连时执行判断自身处于大太刀模式还是小太刀模式，从而更改技能组设置
    if self._proxy:CheckBuffByKind(self._uuid, 10513101) then
        --切换普攻按键
        self._AttackButton = 105102
        self._SkillThird = 105113
        --切换技能组按键
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._AttackButton)
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._SkillThird)
        --切换剑气技能
        self._JianqiSkillGroup[1] = 1051047
        self._JianqiSkillGroup[2] = 1051046
        self._JianqiSkillGroup[3] = 1051048
        self._JianqiSkillGroup[4] = 1051049
        --切换居合技能
        self._JuheXuli = 1051015
        self._JuheXuliSkillTypeTwo = 1051075
        self._JuheXuliSkill = 1051076
        --添加特效
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1051026)
    end

    --初始化大太刀buff倒计时相关
    ------------配置------------
    self._DataidaoBuffDownDelayTime = 0.25
    self._DataidaoBuffTimerSwitch = false
end

---@param dt number @ delta time
function XCharR5Lucia1:Update(dt)
    Base.Update(self, dt)
    --镜头测试
    -- local locktaregetid, npcid = self._proxy:GetLockTarget()
    -- local targertangle, cameraAngle = self._proxy:GetCameraPosInfo(self._uuid, npcid)
    -- --XLog.Warning("XIANGJI JINGTOU:"..cameraAngle)
    -- if (self._proxy:IsKeyDown(ENpcOperationKey.Ball4)) then
    --     self._proxy:ApplyMagic(self._uuid,self._uuid, 10516423)
    --     self._proxy:ApplyMagic(self._uuid,self._uuid, 10516424)
    --end
    --登龙可释放
    if (self._addDenglongBuff == true) then
        if (self._proxy:GetNpcAttribValue(self._uuid, 48) == 200) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1051006, 1)
            self._addDenglongBuff = false
        end
    end

    if (self._canCastSkill == true) then
        if self._proxy:CheckNpcCurrentAction(self._uuid, 1051061) or self._proxy:CheckNpcCurrentAction(self._uuid, 1051060) then
            if (self._proxy:CheckActionTiming(self._uuid, 18)) then
                ----XLog.Warning("登龙时间到")
                self._proxy:AbortAction(self._uuid, true)

                local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid, ENpcTargetType.Enemy)
                -- --无战斗目标释放技能
                if searchtarget == 0 then
                    self._proxy:CastAction(self._uuid, 1051062)
                    return
                end
                --有战斗目标释放技能
                self._proxy:CastActionToSearchTarget(self._uuid, 1051062, searchtarget)
                ----XLog.Warning("释放有目标登龙斩:")

                self._proxy:ApplyMagic(self._uuid, self._uuid, 105100601)
                self._canCastSkill = false
                self._addDenglongBuff = true
            end
        end
    end

    if self._canUseTeamSkill then
        if self._proxy:GetTeamWorkEnergy(self._uuid) >= 100 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1051023)
            self._canUseTeamSkill = false
        end
    end

    if self._DenglongX then
        if self._proxy:CheckActionTiming(self._uuid, 20) then
            self._CastDenglongX = true
        end

        if self._proxy:CheckActionTiming(self._uuid, 19) then
            self._DenglongXTimes = self._proxy:GetBuffStacks(self._uuid, 10516301) --跃升登龙计数器
            if self._CastDenglongX and self._DenglongXTimes <= 4 then
                ----XLog.Warning("释放有目标登龙斩X:")
                self._CastDenglongX = false
                ----XLog.Warning("释放有目标登龙斩X:" .. self._DenglongXTimes)
                local lockTargetNpc, npcId = self._proxy:GetLockTarget()
                --无目标释放技能
                if (npcId == 0) or (not npcId) then
                    self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastAction(self._uuid, self._DenglongExSkillGroup[self._DenglongXTimes])
                    return
                end
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToSearchTarget(self._uuid, self._DenglongExSkillGroup[self._DenglongXTimes], lockTargetNpc)
                ----XLog.Warning("释放有目标震雷斩:" .. self._DenglongXTimes)
            else
                ----XLog.Warning("释放有目标登龙斩X终结:")
                local targetNpc, targetNpcId = self._proxy:GetLockTarget()
                ----XLog.Warning(targetNpcId)
                self._proxy:SetNpcFocusTarget(self._uuid, targetNpcId)
                --无目标释放技能
                if (targetNpc == 0) or (not targetNpc) then
                    self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastAction(self._uuid, 1051068)
                    return
                end
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToSearchTarget(self._uuid, 1051068, targetNpc)
                ----XLog.Warning("释放有目标震雷斩:" .. self._DenglongXTimes)
            end
        end
    end


    if (self._GPJuhe == true) then
        --判断当前技能是否为弹刀技能
        if self._proxy:CheckNpcCurrentAction(self._uuid,1051027) or self._proxy:CheckNpcCurrentAction(self._uuid,1051028) then
            --判断技能时间轴
            if self._proxy:CheckActionTiming(self._uuid, 15) then
                ----XLog.Warning("弹刀就位")
                self._proxy:AbortAction(self._uuid, true)
                local targetNpc = self._proxy:SearchNpc(self._uuid, ENpcCampType.Camp2, 4, 15, -1)
                if (targetNpc == 0) or (not targetNpc) then
                    self._proxy:CastAction(self._uuid, 1051026)
                    --如果是2技能弹刀居合，则进入冷却
                    if self._proxy:CheckBuffByKind(self._uuid, 10512005) then
                        self._proxy:ApplyMagic(self._uuid, self._uuid, 10512006)
                    end
                    self._GPJuhe = false
                    return
                end
                ----XLog.Warning("释放技能")
                self._proxy:CastActionToTarget(self._uuid, 1051026, targetNpc)
                --如果是2技能弹刀居合，则进入冷却
                if self._proxy:CheckBuffByKind(self._uuid, 10512005) then
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 10512006)
                end
                ----XLog.Warning("释放成功")
                self._GPJuhe = false
            end
        end
    end

    if (self._DodgeJianqi == true) then
        if (self._proxy:IsKeyDown(ENpcOperationKey.Attack)) then
            if (self._proxy:CheckNpcCurrentAction(self._uuid, 1051006) or self._proxy:CheckNpcCurrentAction(self._uuid, 1051007) or self._proxy:CheckNpcCurrentAction(self._uuid, 1051008) or self._proxy:CheckNpcCurrentAction(self._uuid, 1051009)) then
                self._CastJianqi = true
            else
                self:ProcessDodgeJianqi()
            end
        end

        if (self._CastJianqi == true) then
            if (self._proxy:CheckActionTiming(self._uuid, 16)) then
                self:ProcessDodgeJianqi()
            end
        end
    end

    if self._Juhe_2 then
        if self._proxy:CheckActionTiming(self._uuid, 16) then
            if self._proxy:CheckNpcCurrentAction(self._uuid, 1051025) then
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastAction(self._uuid, 1051029)
            end
        end
    end
    --大太刀模式增伤buff倒计时
    if self._DataidaoBuffTimerSwitch then
        if (self._proxy:GetFightTime() > self._DataidaoBuffTimer) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10513124)
            self._DataidaoBuffTimer = self._proxy:GetFightTime() + self._DataidaoBuffDownDelayTime
        end
    end

    -- self._DataidaoBuffTimer = 0
    -- self._Interval = 0.25
    -- self._triggerTime = 0
    -- self._DataidaoBuffTimer = self._DataidaoBuffTimer + dt
    -- local needTriggerTime =  math.floor(self._DataidaoBuffTimer / dt)
    -- for 循环

    self:ProcessFirstJianqi()
    --按键检测
    self:JianqiKeyDown()
    --剑气连击情况判断
    self:JianqiCombo()
    --大太刀拖尾特效逻辑
    self:EquipTuoWei()
end

---@param eventType number
---@param eventArgs userdata
function XCharR5Lucia1:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharR5Lucia1:OnNpcCastActionByInputActionBeforeEvent(args)
    local launcher = args.LauncherUUID
    local contextId = args.ContextId
    local skillId = args.SkillId

    if not launcher == self._uuid then
        return
    end

    --检查当前是否拥有锁定目标
    local locktaregetid, npcid = self._proxy:GetLockTarget() --转换新索敌目标为npcuuid
    if npcid == 0 and locktaregetid == 0 then
        return
    end
    local targetPos = self._proxy:GetSearchTargetPosition(locktaregetid) -- 获取技能目标位置
    ------XLog.Warning("新索敌目标"..locktaregetid)
    self._proxy:SetCastSkillByInputActionBeforeValue(contextId, ESkillTargetType.Npc, npcid, targetPos, locktaregetid)

    -- self._proxy:SetCastSkillByInputActionBeforeValue(contextId, ESkillTargetType.Position, npcid, targetPos,locktaregetid)
end

--技能释放前事件
function XCharR5Lucia1:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort) --基类的逻辑

    if (LauncherId == self._uuid) then
        --移除顿帧影响
        self._proxy:RemoveBuff(self._uuid, 10510507)
        --剑气状态管理
        if (SkillId ~= 1051040 and SkillId ~= 1051041 and SkillId ~= 1051042 and SkillId ~= 1051043 and SkillId ~= 1051044 and SkillId ~= 1051045 and SkillId ~= 1051046 and SkillId ~= 1051047 and SkillId ~= 1051048 and SkillId ~= 1051049) then
            if (self._proxy:CheckBuffByKind(self._uuid, 10514001)) then
                ----XLog.Warning("移除剑气buff" .. SkillId)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1051400101)
            end
        end

        if (SkillId == 1051061 or SkillId == 1051060) then
            self._canCastSkill = true
            self._useShenglong = true
        end

        if (SkillId == 1051063) then
            if (self._proxy:CheckBuffByKind(self._uuid, 10513101)) then
                self._DenglongX = true
            end
        end

        if (SkillId == 1051068) then -- SkillId == 1051062 or
            -- self._proxy:ApplyMagic(self._uuid, self._uuid, 10513106)
            self._useShenglong = false
            self._DenglongX = false
        end

        --excastskill测试
        -- if (SkillId == 1051007 or Ski llId == 1051009) then
        --     self._proxy:ApplyMagic(self._uuid, self._uuid, 10510706, 1)
        -- end
        --QTE双镜头
        if (SkillId == 1051092 or SkillId == 1051093) then
            local locktaregetid, npcid = self._proxy:GetLockTarget() --转换新索敌目标为npcuuid
            if npcid == 0 and locktaregetid == 0 then
                return
            end
            local targertangle, cameraAngle = self._proxy:GetCameraPosInfo(self._uuid, npcid)
            ----XLog.Warning("角度" .. cameraAngle)
            if cameraAngle <= 180 then
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10519210)
            else
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10519209)
            end
        end
        --剑气双镜头
        if (SkillId == 1051041 or SkillId == 1051046) then
            local locktaregetid, npcid = self._proxy:GetLockTarget() --转换新索敌目标为npcuuid
            if npcid == 0 and locktaregetid == 0 then
                return
            end
            local targertangle, cameraAngle = self._proxy:GetCameraPosInfo(self._uuid, npcid)
            ----XLog.Warning("角度" .. cameraAngle)
            if cameraAngle <= 180 then
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10519210)
            else
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10519209)
            end
        end

        if (SkillId == 1051021) then
            self._DodgeButtonCheck = self._proxy:GetSkillGroupLastHitId(self._uuid,105105)
        end

        if (SkillId == 1051025) then
            self._Juhe_2 = true
            local locktaregetid, npcid = self._proxy:GetLockTarget() --转换新索敌目标为npcuuid
            if npcid == 0 and locktaregetid == 0 then
                return
            end
            self._Juhe2targetPos = self._proxy:GetSearchTargetPosition(locktaregetid)
        end

        if (SkillId == 1051096) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1051025)
        end

        if (self._proxy:CheckBuffByKind(self._uuid, 10511108)) then
            --1技能可连段
            if (SkillId ~= 1051011) then
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511109)
            end
        end
        --如果释放技能不为弹刀反击QTE，则删除10518108标记buff
        if(SkillId ~= 1051082 and SkillId ~= 1051083) then
            if not self._proxy:CheckBuffByKind(self._uuid, 10518108) then
                return
            end
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10518113)
        end
    end
end

--技能释放后事件
function XCharR5Lucia1:OnNpcCastActionAfterEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbandt)
    Base.OnNpcCastActionAfterEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbandt) --基类的逻辑

    if (LauncherId == self._uuid) then
        --剑气第一剑自动连击
        if (SkillId == 1051040) then
            self._firstJianqi = true
            ----XLog.Warning("释放了技能剑气闪避")
        end
        --播放CV
        if (SkillId == 1051060) or (SkillId == 1051061) then --登龙技能
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1051052)
        end
        if (SkillId == 1051031) then --3技能拔刀
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1051053)
        end
        if (SkillId == 1051091) then --必杀技能
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1051054)
        end
        if (SkillId == 1051011) or (SkillId == 1051026) then -- 小技能1 2 
            local CVrandom = self._proxy:Random(0, 1)
            if CVrandom == 1 then
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1051055)
            else
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1051056)
            end
        end
        if (SkillId == 1051063) then --跃升登龙
             self._proxy:ApplyMagic(self._uuid, self._uuid, 1051057)
        end

        if (SkillId == 1051084) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000458) --移除自身支援标记
            local npclist = self._proxy:GetNpcList()
            for _, npcuuid in pairs(npclist) do
                if npcuuid == 0 then
                    return
                end
                if self._proxy:CheckBuffByKind(npcuuid, 1000450) then                          --向角力中的角色发送角力成功标记
                    self._proxy:ApplyMagic(self._uuid, npcuuid, 1000454)                       --角力成功标记
                    self._proxy:ApplyMagic(self._uuid, npcuuid, 1000456)                       --移除角力接收方标记
                end
                if self._proxy:CheckBuffByKind(npcuuid, 1000452) and npcuuid ~= self._uuid then --向后续响应的角色发送终结标记
                    self._proxy:ApplyMagic(self._uuid, npcuuid, 1000458)                       --移除支援标记
                    self._proxy:ApplyMagic(self._uuid, npcuuid, 1000453)                       --施加终结标记
                end
                if self._proxy:CheckBuffByKind(npcuuid, 1000451) then                          --向角力中的怪物发送角力成功标记
                    self._proxy:ApplyMagic(self._uuid, npcuuid, 1000454)                       --角力成功标记
                end
            end
        end

        if (SkillId == 1051096) then
            self._proxy:SetTeamWorkSkillNpcRemainUseCount(self._uuid, 0)
        end

        if  SkillId ~= 1051027 and SkillId ~= 1051028 then
            ----XLog.Warning("NOT TANDAO  " ..SkillId)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10512702)
        end
        --如果释放大太刀技能则添加拖尾特效
        if self._SkillExId[SkillId] then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1051027)
        else
            if self._proxy:CheckBuffByKind(self._uuid,1051027) then
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1051028)
            end
        end

        --释放闪避后删除2技能居合蓄力进入冷却标记
        if self._SkillDodgeId[SkillId] then
            XLog.Warning("释放了闪避")
            if self._proxy:CheckBuffByKind(self._uuid,10512005) then
                self._proxy:RemoveBuff(self._uuid, 10512005)
            end
        end
    end
end

function XCharR5Lucia1:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --判断自己
    if npcUUID ~= self._uuid then
        return
    end
    if (buffId == 10513101) then
        --切换动画层
        self._proxy:SetNpcAnimationLayer(self._uuid, 1)
        --切换普攻按键
        self._AttackButton = 105102
        self._SkillThird = 105113
        --切换技能组按键
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._AttackButton)
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._SkillThird)
        --切换剑气技能
        self._JianqiSkillGroup[1] = 1051047
        self._JianqiSkillGroup[2] = 1051046
        self._JianqiSkillGroup[3] = 1051048
        self._JianqiSkillGroup[4] = 1051049
        --切换居合技能
        self._JuheXuli = 1051015
        self._JuheXuliSkillTypeTwo = 1051075
        self._JuheXuliSkill = 1051076
        --设置能量条UI
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1051062)
        
        --增伤buff
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10513118)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10513119)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10512106)
        --倒计时能量UI设置
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10513123) --倒计时能量加满
        self._DataidaoBuffTimerSwitch = true
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10513124)
        self._DataidaoBuffTimer = self._proxy:GetFightTime() + self._DataidaoBuffDownDelayTime

        --武器发光特效
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1051026)

        --次要改造3
        if self._proxy:CheckBuffByKind(self._uuid, 1051107) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10511071)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10511072)
        end
    end

    if (buffId == 10514001) then
        self._canUseJianqi = true
        if self._proxy:CheckBuffByKind(self._uuid, 10513101) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10514108, 1)
            if self._proxy:CheckBuffByKind(self._uuid, 10519210) then
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10514111, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10514112, 1)
                return
            end
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10514113, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10514114, 1)
            return
        end

        self._proxy:ApplyMagic(self._uuid, self._uuid, 10514108, 1)
        if self._proxy:CheckBuffByKind(self._uuid, 10519210) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10514106, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10514107, 1)
            return
        end
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10514109, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10514110, 1)
    end
    --屏蔽普攻键
    if (buffId == 10510706) then
        self._DodgeJianqi = true
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, 105114)
    end

    if (buffId == 10519210) then
        self._cameraOnRight = true
    end

    if (buffId == 10511108) then
        --1技能第二段切换
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, 105112)
    end

    if(buffId == 10518108) then
        --切换普攻为弹刀反击
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, 105103)
        self._proxy:StartButtonCountDown(self._uuid,ENpcOperationKey.Attack,2.5)
    end
end

function XCharR5Lucia1:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --寻找一个攻击目标
    Base.OnNpcRemoveBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --核心1-引爆伤口
    if buffId == 10511012 then
        if self._proxy:CheckBuffByKind(self._uuid,1051101) then
            self._proxy:LaunchMissile(self._uuid, self._uuid, self._lunchId[self._proxy:Random(1,4)], 10511011, 1)
        end
        if self._proxy:CheckBuffByKind(self._uuid,1051102) then
            self._proxy:LaunchMissile(self._uuid, self._uuid, self._lunchId[self._proxy:Random(1,4)], 10511021, 1)
        end
    end
    if npcUUID ~= self._uuid then
        return
    end
    if (buffId == 10513101) then
        --大太刀模式结束
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10510001)
        --切换动画层
        self._proxy:SetNpcAnimationLayer(self._uuid, 0)
        --设置普攻键
        self._AttackButton = 105101
        self._SkillThird = 105108
        --切换技能组按键
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._AttackButton)
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._SkillThird)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10513116)
        --切换剑气技能
        self._JianqiSkillGroup[1] = 1051042
        self._JianqiSkillGroup[2] = 1051041
        self._JianqiSkillGroup[3] = 1051043
        self._JianqiSkillGroup[4] = 1051045
        --切换居合技能
        self._JuheXuliSkillTypeTwo = 1051025
        self._JuheXuliSkill = 1051026
        --设置能量条UI
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1051061)

        --检测如果有增伤buff则延迟1.5s移除增伤buff
        if self._proxy:CheckBuffByKind(self._uuid, 10513118) then
            self._proxy:AddTimerTask(1.5, function()
            self._proxy:RemoveBuff(self._uuid, 10513118)
            --XLog.Warning("延迟移除了buff")
        end)
        end
        --删除武器发光特效
        self._proxy:RemoveBuff(self._uuid, 1051028)
        self._proxy:RemoveBuff(self._uuid, 1051027)
        self._proxy:RemoveBuff(self._uuid, 1051026)

        --次要改造3
        if self._proxy:CheckBuffByKind(self._uuid, 1051107) then
            self._proxy:RemoveBuff(self._uuid, 10511071)
            self._proxy:RemoveBuff(self._uuid, 10511072)
        end
    end
    if (buffId == 10513118) then
        --大太刀模式增伤结束
        self._proxy:RemoveBuff(self._uuid, 10513119)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10512107)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10513125)
        self._DataidaoBuffTimerSwitch = false
    end

    if (buffId == 10510706) then
        --弹刀状态结束
        self._DodgeJianqi = false
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._AttackButton)
        self._CastJianqi = false
    end

    if (buffId == 10514001) then
        --剑气状态结束
        self._jianqiCounter = 0
        self._canUseJianqi = false
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1051019) --删除剑气加速
        self._proxy:RemoveBuff(self._uuid, 10514108)
        self._proxy:RemoveBuff(self._uuid, 10514106)
        self._proxy:RemoveBuff(self._uuid, 10514107)
        self._proxy:RemoveBuff(self._uuid, 10514111)
        self._proxy:RemoveBuff(self._uuid, 10514112)
        self._proxy:RemoveBuff(self._uuid, 10514109)
        self._proxy:RemoveBuff(self._uuid, 10514110)
        self._proxy:RemoveBuff(self._uuid, 10514113)
        self._proxy:RemoveBuff(self._uuid, 10514114)
    end

    if (buffId == 10511108) then
        --1技能连段时间结束
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, 105106)
    end
    if(buffId == 10518108) then
        --切换弹刀反击为普攻
        if self._proxy:CheckBuffByKind(self._uuid, 10513101) then
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, 105102)
        else
            self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, 105101)
        end
        self._proxy:ClearButtonCountDown(self._uuid, ENpcOperationKey.Attack)
    end
    --拖尾特效消散结束转为常驻发光
    if (buffId == 1051028) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1051026)
    end
end

function XCharR5Lucia1:ChangeDamageBeforeCalc(eventArgs)
    Base.ChangeDamageBeforeCalc(self, eventArgs)
    self._uuid = self._proxy:GetSelfNpcId()

    if eventArgs.Launcher == self._uuid then
        --核心改造1-1
        if self._proxy:CheckBuffByKind(self._uuid, 1051101) then
            --登龙伤害加成:所有登龙伤害都可以吃到这个伤害加成
            if self.DenglongDmgTbl[eventArgs.Id] then
                ----XLog.Warning("登龙伤害加成")
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511011, 1, eventArgs.ContextId, 1)
            end
            --伤口系统:只要不是登龙伤害那就可以造成伤口
            if not self.DenglongEquipDmgTbl[eventArgs.Id] then
                self.RandomInt = self._proxy:Random(0, 1)
                ----XLog.Warning("伤口随机" .. self.RandomInt)
                if self.RandomInt == 1 then
                    self._proxy:ApplyMagic(self._uuid, eventArgs.Target, 10511012)
                end
            end
        end
        --核心改造1-2
        if self._proxy:CheckBuffByKind(self._uuid, 1051102) then
            --登龙伤害加成
            if self.DenglongDmgTbl[eventArgs.Id] then
                ----XLog.Warning("登龙伤害加成")
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511021, 1, eventArgs.ContextId, 1)
            end
            --伤口系统
            if not self.DenglongEquipDmgTbl[eventArgs.Id] then
                self.RandomInt = self._proxy:Random(0, 1)
                ----XLog.Warning("伤口随机" .. self.RandomInt)
                if self.RandomInt == 1 then
                    self._proxy:ApplyMagic(self._uuid, eventArgs.Target, 10511012)
                end
            end
        end
        --核心改造2-1
        if self._proxy:CheckBuffByKind(self._uuid, 1051103) then
            if self.JianqiDmgTbl[eventArgs.Id] then
                ----XLog.Warning("剑气伤害加成-核心2-1")
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511031, 1, eventArgs.ContextId, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511032)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511033) 
            end
            if self._proxy:CheckBuffByKind(eventArgs.Target, 1056020) then
                if eventArgs.Id == 1056021 then
                    return
                end
                if not self._proxy:CheckBuffByKind(self._uuid, 10511034) then
                    self._proxy:ApplyMagic(self._uuid, eventArgs.Target, 1056021)
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 10511034)
                end
            end
        end

        if self._proxy:CheckBuffByKind(self._uuid, 1051104) then
            if self.JianqiDmgTbl[eventArgs.Id] then
                ----XLog.Warning("剑气伤害加成-核心2-2")
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511041, 1, eventArgs.ContextId, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511032)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511033) 
            end
            if self._proxy:CheckBuffByKind(eventArgs.Target, 1056020) then
                if eventArgs.Id == 1056021 then
                    return
                end
                if not self._proxy:CheckBuffByKind(self._uuid, 10511034) then
                    self._proxy:ApplyMagic(self._uuid, eventArgs.Target, 1056021)
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 10511034)
                end
            end
        end

        --次要改造1技能
        if self._proxy:CheckBuffByKind(self._uuid, 1051105) then
            if eventArgs.Id == 10511101 or eventArgs.Id == 10511105 then
                ----XLog.Warning("插件专属：造成1技能伤害")
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511051, 1, eventArgs.ContextId, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511052, 1, eventArgs.ContextId, 1)
            end
        end
        --次要改造2技能
        if self._proxy:CheckBuffByKind(self._uuid, 1051106) then
            if eventArgs.Id == 10512401 or eventArgs.Id == 10512501 or eventArgs.Id == 10512601 then
                ----XLog.Warning("插件专属：造成2技能伤害")
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511061, 1, eventArgs.ContextId, 1)
            end
        end
    end
end

--极限闪避处理
function XCharR5Lucia1:OnNpcDodge(SourceUUID, AttackerUUID, Type)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type)
    if (SourceUUID ~= self._uuid) then
        return
    end
    if (Type == 1) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10510706, 1)
    end
end

function XCharR5Lucia1:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    Base.OnNpcCounterSuccess(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    --成功后无敌
    self._proxy:ApplyMagic(self._uuid, self._uuid, 8005905, 1)

    --强弹刀表现
    if self:ContainsGameplayTag(counterTag, EGameplayTag.Missile_Parry_Counter_Heavy) then
        ----XLog.Warning("触发完居合弹刀:")
        --放派生,做镜头
        if self._proxy:CheckNpcCurrentAction(self._uuid, 1051021) or self._proxy:CheckNpcCurrentAction(self._uuid, 1051022) or self._proxy:CheckNpcCurrentAction(self._uuid, 1051023) or self._proxy:CheckNpcCurrentAction(self._uuid, 1051020) then
            self._proxy:AbortAction(self._uuid, true)
            ----XLog.Warning("完美弹刀格挡")
            self._proxy:CastAction(self._uuid, 1051027) --剑盾受击触发弹刀释放精确格挡
            self._GPJuhe = true
        end
        return
    end
end

function XCharR5Lucia1:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    if (launcher == self._uuid) then
        if (eventName == "CastFinalJuhe") then
            if self._proxy:CheckBuffByKind(self._uuid, 1051106) then
                local success, axis = self._proxy:TryGetQueryStickAxis()
                if success then
                    local targetNpc = self._proxy:GetLockTarget()
                    if (targetNpc == 0) or (not targetNpc) then
                        ----XLog.Warning("无目标释放居合final-次要改造2")
                        -- self._proxy:AbortAction(self._uuid, true)
                        self._proxy:CastAction(self._uuid, 1051025)
                        return
                    end
                    ----XLog.Warning("有目标释放居合final-次要改造2")
                    -- self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastActionToSearchTarget(self._uuid, 1051025, targetNpc)
                    return
                end
            end

            ------XLog.Warning("蓄力全满")
            local targetNpc = self._proxy:GetLockTarget()

            if (targetNpc == 0) or (not targetNpc) then
                ----XLog.Warning("无目标释放居合final")
                -- self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastAction(self._uuid, 1051026)
                return
            end
            ----XLog.Warning("有目标释放居合final")
            -- self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToSearchTarget(self._uuid, 1051026, targetNpc)
        end

        if (eventName == "castNextCounter") then
            ----XLog.Warning("释放衔接")
            local targetNpc = self._proxy:GetLockTarget()
            if (self._proxy:CheckBuffByKind(self._uuid, 10513101)) then
                self._counterSkill = 1051086
            else
                self._counterSkill = 1051085
            end

            if (targetNpc == 0) or (not targetNpc) then
                ----XLog.Warning("无目标释放连携2段")
                -- self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastAction(self._uuid, self._counterSkill)
                return
            end
            ----XLog.Warning("有目标释放连携2段")
            -- self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToSearchTarget(self._uuid, self._counterSkill, targetNpc)
        end

        if (eventName == "castNextCounterAir") then
            ----XLog.Warning("释放衔接")
            local targetNpc = self._proxy:GetLockTarget()
            if (self._proxy:CheckBuffByKind(self._uuid, 10513101)) then
                self._counterSkill = 1051089
            else
                self._counterSkill = 1051088
            end

            if (targetNpc == 0) or (not targetNpc) then
                ----XLog.Warning("无目标释放连携3段")
                -- self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastAction(self._uuid, self._counterSkill)
                return
            end
            ----XLog.Warning("有目标释放连携3段")
            -- self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToSearchTarget(self._uuid, self._counterSkill, targetNpc)
        end

        if (eventName == "isJuheXuli") then
            ----XLog.Warning("蓄力衔接")
            local targetNpc = self._proxy:GetLockTarget()
            if (self._proxy:IsKeyHold(ENpcOperationKey.Dodge)) and (self._proxy:GetSkillGroupLastHitId(self._uuid,105105) == self._DodgeButtonCheck) then
            --检查蓄力是否为同次按压
                --XLog.Warning("按下ID相同执行打印")
                if (self._proxy:CheckBuffByKind(self._uuid, 10513101)) then
                    self._JuheXuli = 1051015
                else
                    self._JuheXuli = 1051022
                end

                if (targetNpc == 0) or (not targetNpc) then
                    -- self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastAction(self._uuid, self._JuheXuli)
                    return
                end
                -- self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToSearchTarget(self._uuid, self._JuheXuli, targetNpc)
            else
                --XLog.Warning("执行保底")
                --直接释放居合
                if (targetNpc == 0) or (not targetNpc) then
                    -- self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastAction(self._uuid, 1051024)
                    return
                end
                -- self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToSearchTarget(self._uuid, 1051024, targetNpc)
            end
        end

        if (eventName == "isJuheXuliLoop") then
            ----XLog.Warning("蓄力循环")
            local targetNpc = self._proxy:GetLockTarget()
            if (self._proxy:IsKeyHold(ENpcOperationKey.Dodge)) and (self._proxy:GetSkillGroupLastHitId(self._uuid,105105) == self._DodgeButtonCheck) then
                --检查蓄力是否为同次按压
                if (self._proxy:CheckBuffByKind(self._uuid, 10513101)) then
                    self._JuheXuli = 1051016
                else
                    self._JuheXuli = 1051023
                end

                if (targetNpc == 0) or (not targetNpc) then
                    ----XLog.Warning("居合蓄力持续")
                    self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastAction(self._uuid, self._JuheXuli)
                    return
                end
                ----XLog.Warning("居合蓄力持续")
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToSearchTarget(self._uuid, self._JuheXuli, targetNpc)
            else
                --直接释放居合
                if (targetNpc == 0) or (not targetNpc) then
                    -- self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastAction(self._uuid, 1051024)
                    return
                end
                -- self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToSearchTarget(self._uuid, 1051024, targetNpc)
            end
        end

        --2技能
        if (eventName == "isJuheXuliPro") then
            ----XLog.Warning("釋放居合極")
            --次要改造2技能
            if self._proxy:CheckBuffByKind(self._uuid, 1051106) then
                local success, axis = self._proxy:TryGetQueryStickAxis()
                if success then
                    local targetNpc = self._proxy:GetLockTarget()
                    if (targetNpc == 0) or (not targetNpc) then
                        ----XLog.Warning("无目标释放居合final-次要改造2")
                        -- self._proxy:AbortAction(self._uuid, true)
                        self._proxy:CastAction(self._uuid, self._JuheXuliSkillTypeTwo)
                        self._proxy:ApplyMagic(self._uuid, self._uuid, 10511203)
                        return
                    end
                    ----XLog.Warning("有目标释放居合final-次要改造2")
                    -- self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastActionToSearchTarget(self._uuid, self._JuheXuliSkillTypeTwo, targetNpc)
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 10511203)
                    return
                end
            end
            local targetNpc = self._proxy:GetLockTarget()
            if (targetNpc == 0) or (not targetNpc) then
                ----XLog.Warning("无目标释放居合final")
                -- self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastAction(self._uuid, self._JuheXuliSkill)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 10511203)
                return
            end
            self._proxy:CastActionToSearchTarget(self._uuid, self._JuheXuliSkill, targetNpc)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10511203)
        end
    end
end

function XCharR5Lucia1:ProcessFirstJianqi()
    if (self._firstJianqi == true) then
        if (self._proxy:CheckActionTiming(self._uuid, 16)) then
            local targetNpc = self._proxy:GetFirstSearchTarget(self._uuid, ENpcTargetType.Enemy)
            -- --无战斗目标释放技能
            if (targetNpc == 0) or (not targetNpc) then
                self._proxy:AbortAction(self._uuid, true)

                self._proxy:CastAction(self._uuid, 1051041)

                self._firstJianqi = false
                return
            end

            --有战斗目标释放技能
            -- local targetPos = self._proxy:GetNpcPosition(targetNpc)

            -- self._proxy:SetNpcFaceToPosition(self._uuid, targetPos) --转向
            -- self._proxy:SetFightTarget(self._uuid, targetNpc)      --设置战斗目标
            -- self._proxy:SetNpcFocusTarget(self._uuid, targetNpc)   --镜头锁定

            self._proxy:AbortAction(self._uuid, true)
            ----XLog.Warning("打断了当前技能")

            self._proxy:CastActionToSearchTarget(self._uuid, 1051041, targetNpc)

            ----XLog.Warning("释放剑气第一段:")
            self._firstJianqi = false
        end
    end
end

function XCharR5Lucia1:ProcessDodgeJianqi()
    local targetNpc = self._proxy:GetFirstSearchTarget(self._uuid, ENpcTargetType.Enemy)
    if (targetNpc == 0) or (not targetNpc) then
        -- self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid, self._JianqiSkillGroup[2])
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10510707)
        return
    end

    --有战斗目标释放技能

    -- self._proxy:AbortAction(self._uuid, true)
    ----XLog.Warning("打断了当前技能")

    self._proxy:CastActionToSearchTarget(self._uuid, self._JianqiSkillGroup[2], targetNpc)

    ----XLog.Warning("释放剑气第一段:")

    self._proxy:ApplyMagic(self._uuid, self._uuid, 10510707)
end

function XCharR5Lucia1:JianqiKeyDown()
    if (self._proxy:CheckBuffByKind(self._uuid, 10514001)) then
        --监听按下攻击键
        if (self._proxy:IsKeyDown(ENpcOperationKey.Attack)) then
            if (self._canUseJianqi == true) then
                self._jianqiCounter = self._jianqiCounter + 1 --剑气计数器+1
                if (self._jianqiCounter <= 3) then
                    self._useJianqi = true                    --剑气连击
                    self._canUseJianqi = false
                    ----XLog.Warning("剑气连击+" .. self._jianqiCounter)
                else
                    self._useJianqi = false
                    ----XLog.Warning("剑气无法继续连击+" .. self._jianqiCounter)
                end
            end
        end
    end
end

function XCharR5Lucia1:JianqiCombo()
    if (self._proxy:CheckBuffByKind(self._uuid, 10514001)) then
        if (self._proxy:CheckActionTiming(self._uuid, 17)) then
            ----XLog.Warning("剑气衔接点" .. tostring(self._useJianqi))
            --进行剑气连击
            if (self._useJianqi == true) then
                ----XLog.Warning("剑气时间到")
                self._proxy:AbortAction(self._uuid, true)
                ----XLog.Warning("打断了当前技能")

                local targetNpc = self._proxy:GetFirstSearchTarget(self._uuid, ENpcTargetType.Enemy)

                ----XLog.Warning("当前目标" .. targetNpc)
                --无目标释放技能
                if (targetNpc == 0) or (not targetNpc) then
                    local success, axis = self._proxy:TryGetQueryStickAxis()
                    if success and self._jianqiCounter < 3 and not self._proxy:CheckBuffByKind(self._uuid, 10513101) then
                        self._proxy:CastAction(self._uuid, 1051042)
                        self._useJianqi = false
                        ----XLog.Warning("消耗剑气缓存" .. self._jianqiCounter)
                        self._canUseJianqi = true
                        ----XLog.Warning("释放剑气移动攻击" .. self._jianqiCounter)
                        return
                    end
                    self._proxy:CastAction(self._uuid, self._JianqiSkillGroup[self._jianqiCounter])
                    self._useJianqi = false
                    ----XLog.Warning("消耗剑气缓存" .. self._jianqiCounter)
                    self._canUseJianqi = true

                    ----XLog.Warning("释放剑气攻击" .. self._jianqiCounter)
                    return
                end

                --有目标释放技能

                local success, axis = self._proxy:TryGetQueryStickAxis()
                if success and self._jianqiCounter < 3 and (not self._proxy:CheckBuffByKind(self._uuid, 10513101)) then
                    self._proxy:CastActionToSearchTarget(self._uuid, 1051042, targetNpc)
                    ----XLog.Warning("释放剑气移动攻击" .. self._jianqiCounter)
                    self._useJianqi = false
                    ----XLog.Warning("消耗剑气缓存" .. self._jianqiCounter)
                    self._canUseJianqi = true
                    ----XLog.Warning("重置输入")
                end

                self._proxy:CastActionToSearchTarget(self._uuid, self._JianqiSkillGroup[self._jianqiCounter], targetNpc)

                ----XLog.Warning("释放剑气攻击" .. self._jianqiCounter)

                self._useJianqi = false
                ----XLog.Warning("消耗剑气缓存" .. tostring(self._useJianqi))
                self._canUseJianqi = true
                ----XLog.Warning("重置输入" .. tostring(self._canUseJianqi))

                --不进行剑气连击
            else
                ----XLog.Warning("剑气结束")
                self._proxy:AbortAction(self._uuid, true)

                local targetNpc = self._proxy:SearchNpc(self._uuid, ENpcCampType.Camp2, 4, 15, -1)

                --无目标释放技能
                if (targetNpc == 0) or (not targetNpc) then
                    if not self._proxy:CheckBuffByKind(self._uuid, 10513101) then
                        self._proxy:CastActionEx(self._uuid, self._JianqiSkillGroup[4], 0.35, 5)
                    else
                        self._proxy:CastAction(self._uuid, self._JianqiSkillGroup[4])
                    end
                    self._useJianqi = false
                    self._jianqiCounter = 0
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 1051400101)
                    return
                end

                --有目标释放技能
                local targetPos = self._proxy:GetNpcPosition(targetNpc)

                self._proxy:SetNpcFaceToPosition(self._uuid, targetPos) --转向
                self._proxy:SetFightTarget(self._uuid, targetNpc)       --设置战斗目标
                self._proxy:SetNpcFocusTarget(self._uuid, targetNpc)    --镜头锁定

                if not self._proxy:CheckBuffByKind(self._uuid, 10513101) then
                    self._proxy:CastActionToTargetEx(self._uuid, self._JianqiSkillGroup[4], targetNpc, 0.35, 5)
                else
                    self._proxy:CastActionToTarget(self._uuid, self._JianqiSkillGroup[4], targetNpc)
                end
                self._useJianqi = false
                self._jianqiCounter = 0
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1051400101)
            end
        end
    end
end

function XCharR5Lucia1:EquipTuoWei()
    if self._proxy:CheckNpcCurActionIsDone(self._uuid) then
        local suc, skillId = self._proxy:TryGetCurrentAction(self._uuid)
        if self._SkillExId[skillId] then
            --XLog.Warning("yes")
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1051028)
        end
    end
end

return XCharR5Lucia1
