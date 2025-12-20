---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")
local EGameplayTag = require("Enum/XGameplayTag")

---Relink-R5露西亚脚本
---@class XChar1051 : XRelinkCharBase
local XChar1051 = XDlcScriptManager.RegCharScript(1051, "XChar1051", Base)
function XChar1051:Ctor(proxy)
    self._proxy = proxy

    -- AI总控
    self._canCastSkill = false
    self._useShenglong = false
    self._addDenglongBuff = true
    self._CastJianqi = false
    self._canUseTeamSkill = true

end

function XChar1051:Init()
    Base.Init(self)

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

    self._proxy:AddBuff(self._uuid, 1051001)

    --注册技能事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent,self._uuid)
end

---@param dt number @ delta time
function XChar1051:Update(dt)
    Base.Update(self, dt)
    --镜头测试

    if (self._addDenglongBuff == true) then
        if (self._proxy:GetNpcAttribValue(self._uuid, 48) == 200) then
            self._proxy:AddBuff(self._uuid, 1051006)
            self._addDenglongBuff = false
        end
    end
    
    if (self._canCastSkill == true) then
        if self._proxy:CheckNpcCurrentAction(self._uuid,1051061) then
            if (self._proxy:CheckActionTiming(self._uuid, 18)) then
                XLog.Warning("登龙时间到")
                self._proxy:AbortAction(self._uuid, true)

                local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)
                -- --无战斗目标释放技能
                if searchtarget == 0 then
                    self._proxy:CastAction(self._uuid, 1051062)
                    return
                end
                --有战斗目标释放技能
                self._proxy:CastActionToSearchTarget(self._uuid, 1051062,searchtarget)
                XLog.Warning("释放有目标登龙斩:")

                self._proxy:RemoveBuff(self._uuid, 1051006)
                self._canCastSkill = false
                self._addDenglongBuff = true
            end
        end
    end

    if self._canUseTeamSkill then
        if self._proxy:GetTeamWorkEnergy(self._uuid) >= 100 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1051023)
            self._canUseTeamSkill = false
        end
    end
        
    if self._canCastSkillX then
        if self._proxy:CheckNpcCurrentAction(self._uuid,1051061) then
            if self._proxy:CheckActionTiming(self._uuid, 19) then
                XLog.Warning("大登龙时间")
                self._proxy:AbortAction(self._uuid, true)

                local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)
                --无目标释放技能
                if searchtarget == 0 then
                    self._proxy:CastAction(self._uuid, 1051062)
                    return
                end
                self._proxy:CastActionToSearchTarget(self._uuid, 1051062,searchtarget)
                
                self._DenglongX = true
                self._addDenglongBuff = true
                self._canCastSkillX = false
            end
        end
    end

    if self._DenglongX then
        self._Searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy) --索敌 
        -- local targetNpc = self._proxy:SearchNpc(self._uuid, ENpcCampType.Camp2, 4, 15, -1)
        self._NpcPosition = self._proxy:GetSearchTargetPosition(self._Searchtarget)

        if self._proxy:CheckActionTiming(self._uuid,20) then
            -- if self._proxy:IsKeyDown(ENpcOperationKey.Attack) then
                self._CastDenglongX = true
                -- self._proxy:AddTimerTask(  0.5,  function()
                --     self._CastDenglongX = false
                -- end)
            -- end
        end

        if self._proxy:CheckActionTiming(self._uuid,19) then
            self._DenglongXTimes = self._proxy:GetBuffStacks(self._uuid,10516301) --跃升登龙计数器
            if self._CastDenglongX and self._DenglongXTimes <= 4 then
                XLog.Warning("释放有目标登龙斩X:")
                self._CastDenglongX = false
                XLog.Warning("释放有目标登龙斩X:"..self._DenglongXTimes)
                
                --无目标释放技能
                if self._Searchtarget == 0 then
                    self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastAction(self._uuid, self._DenglongExSkillGroup[self._DenglongXTimes])
                    return
                end
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToPosition(self._uuid, self._DenglongExSkillGroup[self._DenglongXTimes],self._NpcPosition)
                XLog.Warning("释放有目标震雷斩:"..self._DenglongXTimes)
            else
                XLog.Warning("释放有目标登龙斩X终结:")
                local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy) --索敌 
                --无目标释放技能
                if searchtarget == 0 then
                    self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastAction(self._uuid, 1051068)
                    return
                end
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToSearchTarget(self._uuid, 1051068,searchtarget)
                XLog.Warning("释放有目标震雷斩:"..self._DenglongXTimes)
            end
        end
    end
            

    if (self._GPJuhe == true) then
        if self._proxy:CheckActionTiming(self._uuid, 15) then
            XLog.Warning("弹刀就位")

            self._proxy:AbortAction(self._uuid, true)
            local targetNpc = self._proxy:SearchNpc(self._uuid, ENpcCampType.Camp2, 4, 15, -1)
            XLog.Warning("释放技能")
            self._proxy:CastActionToTarget(self._uuid, 1051026, targetNpc)
            XLog.Warning("释放成功")
            self._GPJuhe = false
        end
    end

    if (self._DodgeJianqi == true) then
        if (self._proxy:IsKeyDown(ENpcOperationKey.Attack)) then
            self._CastJianqi = true
        end

        if (self._proxy:CheckActionTiming(self._uuid, 16)) then
            if (self._CastJianqi == true) then
                local targetNpc = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)
                -- --无战斗目标释放技能
                if (targetNpc == 0) or (not targetNpc) then
                    self._proxy:AbortAction(self._uuid, true)

                    self._proxy:CastAction(self._uuid, self._JianqiSkillGroup[2])

                    self._DodgeJianqi = false
                    self._CastJianqi = false
                    return
                end

                --有战斗目标释放技能

                self._proxy:AbortAction(self._uuid, true)
                XLog.Warning("打断了当前技能")

                self._proxy:CastActionToSearchTarget(self._uuid, self._JianqiSkillGroup[2], targetNpc)

                XLog.Warning("释放剑气第一段:")

                self._DodgeJianqi = false
                self._CastJianqi = false
            end
        end
    end

    --连携弹刀
    if self._canUseFightBack then
        if self._proxy:CheckActionTiming(self._uuid, 14) then
            --设置反击技能id
            if self._proxy:CheckNpcCurrentAction(self._uuid, 1051082) then
                self._fightBackSkillId = 1051084
            else
                self._fightBackSkillId = 1051085
            end
            --获取技能目标
            local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)
            --无目标释放技能
            if searchtarget == 0 then
                XLog.Warning("无目标释放连携弹刀反击")
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastAction(self._uuid, self._fightBackSkillId)

                self._canUseFightBack = false
                return
            end
            --有目标释放技能
            XLog.Warning("有目标释放连携弹刀反击")
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToSearchTarget(self._uuid, self._fightBackSkillId,searchtarget)
            self._canUseFightBack = false
        end
    end
            
    if self._Juhe_2 then
        if self._proxy:CheckActionTiming(self._uuid, 16) then
            if self._proxy:CheckNpcCurrentAction(self._uuid, 1051025) then
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastAction(self._uuid, 1051029)
            --     local targetNpc = self._proxy:SearchNpc(self._uuid, ENpcCampType.Camp2, 4, 20, -1)
            -- -- --无战斗目标释放技能
            --     if (targetNpc == 0) or (not targetNpc) then
            --         self._proxy:AbortAction(self._uuid, true)
            --         self._proxy:CastAction(self._uuid, 1051029)
            --         return
            --     end
            -- --有目标释放技能
            --     self._proxy:AbortAction(self._uuid, true)
            --     XLog.Warning("有目标释放连携弹刀反击"..self._uuid)
            --     XLog.Warning("有目标释放连携弹刀反击"..targetNpc)
            --     self._proxy:CastActionToPosition(self._uuid, 1051029, self._Juhe2targetPos)

                
            --     self._Juhe_2 = false
            end
        end
    end
                
    self:ProcessFirstJianqi()
    --按键检测
    self:JianqiKeyDown()
    --剑气连击情况判断
    self:JianqiCombo()
end

---@param eventType number
---@param eventArgs userdata
function XChar1051:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar1051:OnNpcCastActionByInputActionBeforeEvent(args)      
    local launcher = args.LauncherUUID
    local contextId = args.ContextId
    local skillId = args.SkillId
    
    if not launcher == self._uuid then
        return
    end
    
    --检查当前是否拥有锁定目标
    local locktaregetid,npcid = self._proxy:GetLockTarget()--转换新索敌目标为npcuuid
    if npcid == 0 and locktaregetid == 0 then
        return
    end
    local targetPos = self._proxy:GetSearchTargetPosition(locktaregetid) -- 获取技能目标位置
    --XLog.Warning("新索敌目标"..locktaregetid)
    self._proxy:SetCastSkillByInputActionBeforeValue(contextId, ESkillTargetType.Npc, npcid, targetPos,locktaregetid)

    -- self._proxy:SetCastSkillByInputActionBeforeValue(contextId, ESkillTargetType.Position, npcid, targetPos,locktaregetid)
end

--技能释放前事件
function XChar1051:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort) --基类的逻辑
    
    if(LauncherId == self._uuid) then
        --剑气状态管理
        if(SkillId ~= 1051040 and SkillId ~= 1051041 and SkillId ~= 1051042 and SkillId ~= 1051043 and SkillId ~= 1051044 and SkillId ~= 1051045 and SkillId ~= 1051046 and SkillId ~= 1051047 and SkillId ~= 1051048) then
            if(self._proxy:CheckBuffByKind(self._uuid,10514001)) then
                XLog.Warning("移除剑气buff" ..SkillId)
                self._proxy:RemoveBuff(self._uuid, 10514001)
            end
        end

        if (SkillId == 1051061) then
            if(self._proxy:CheckBuffByKind(self._uuid, 10513101)) then
                -- self._canCastSkill = true
                self._canCastSkill = true
            else
                self._canCastSkill = true
            end
            self._useShenglong = true
        end

        if(SkillId == 1051062 or SkillId == 1051068) then
            self._proxy:SetNpcAnimationLayer(self._uuid, 0)
            -- self._proxy:SetNpcInputActionGroup(self._uuid, 105101)
            self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105104)
            self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105105)
            self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105106)
            self._proxy:RemoveBuff(self._uuid, 10513101)
            self._useShenglong = false
        end

        if (SkillId == 1051068) then
            self._DenglongX = false
            self._proxy:RemoveBuff(self._uuid, 1051006)
        end
        --excastskill测试
        if (SkillId == 1051007 or SkillId == 1051009) then
            self._proxy:AddBuff(self._uuid, 10510704)
        end
        --QTE双镜头
        if (SkillId == 1051092 or SkillId == 1051093) then
            local locktaregetid,npcid = self._proxy:GetLockTarget()--转换新索敌目标为npcuuid
            if npcid == 0 and locktaregetid == 0 then
                 return
            end
            local targertangle,cameraAngle = self._proxy:GetCameraPosInfo(self._uuid,npcid)
            XLog.Warning("角度" ..cameraAngle)
            if cameraAngle <= 180 then
                self._proxy:ApplyMagic(self._uuid,self._uuid,10519210)
            else
                self._proxy:ApplyMagic(self._uuid,self._uuid,10519209)
            end
        end
        --剑气双镜头
        if (SkillId == 1051041 or SkillId == 1051046) then
            local locktaregetid,npcid = self._proxy:GetLockTarget()--转换新索敌目标为npcuuid
            if npcid == 0 and locktaregetid == 0 then
                 return
            end
            local targertangle,cameraAngle = self._proxy:GetCameraPosInfo(self._uuid,npcid)
            XLog.Warning("角度" ..cameraAngle)
            if cameraAngle <= 188 then
                self._proxy:ApplyMagic(self._uuid,self._uuid,10519210)
            else
                self._proxy:ApplyMagic(self._uuid,self._uuid,10519209)
            end
        end
        
        if(SkillId == 1051025) then
            self._Juhe_2 = true
            local locktaregetid,npcid = self._proxy:GetLockTarget()--转换新索敌目标为npcuuid
            if npcid == 0 and locktaregetid == 0 then
                return
            end
            self._Juhe2targetPos = self._proxy:GetSearchTargetPosition(locktaregetid)
        end

        if(SkillId == 1051096) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1051025)
        end
    end
end

--技能释放后事件
function XChar1051:OnNpcCastActionAfterEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbandt)
    --剑气第一剑自动连击
    if (SkillId == 1051040) then
        self._firstJianqi = true
        XLog.Warning("释放了技能剑气闪避")
    end


    if(SkillId == 1051082 or SkillId == 1051083) then
        self._canUseFightBack = true
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000458)  --移除自身支援标记
        local npclist = self._proxy:GetNpcList()
        for _, npcuuid in pairs(npclist) do
            if npcuuid == 0  then
                return
            end
            if self._proxy:CheckBuffByKind(npcuuid,1000450) then --向角力中的角色发送角力成功标记
                self._proxy:ApplyMagic(self._uuid, npcuuid,1000454) --角力成功标记
                self._proxy:ApplyMagic(self._uuid, npcuuid,1000456) --移除角力接收方标记
            end
            if self._proxy:CheckBuffByKind(npcuuid,1000452) and npcuuid ~= self._uuid then --向后续响应的角色发送终结标记
                self._proxy:ApplyMagic(self._uuid, npcuuid,1000458) --移除支援标记
                self._proxy:ApplyMagic(self._uuid, npcuuid,1000453) --施加终结标记
            end
            if self._proxy:CheckBuffByKind(npcuuid,1000451) then --向角力中的怪物发送角力成功标记
                self._proxy:ApplyMagic(self._uuid, npcuuid,1000454) --角力成功标记
            end
        end
    end
end

function XChar1051:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID,npcUUID,buffId,buffKinds,buffUUId)
    if (buffId == 10513101) then
        self._proxy:SetNpcAnimationLayer(self._uuid, 1)
        -- self._proxy:SetNpcInputActionGroup(self._uuid, 105151)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,-1)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,-1)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,-1)
        self._JianqiSkillGroup[1] = 1051047
        self._JianqiSkillGroup[2] = 1051046
        self._JianqiSkillGroup[3] = 1051048
        self._JianqiSkillGroup[4] = 1051049
    end

    if (buffId == 10514001) then
        self._canUseJianqi = true
        if self._proxy:CheckBuffByKind(self._uuid,10513101) then
            self._proxy:AddBuff(self._uuid, 10514108)
            if self._proxy:CheckBuffByKind(self._uuid,10519210) then
                self._proxy:AddBuff(self._uuid, 10514111)
                self._proxy:AddBuff(self._uuid, 10514112)
                return
            end
            self._proxy:AddBuff(self._uuid, 10514113)
            self._proxy:AddBuff(self._uuid, 10514114)   
            return
        end

        self._proxy:AddBuff(self._uuid, 10514108)
        if self._proxy:CheckBuffByKind(self._uuid,10519210) then
            self._proxy:AddBuff(self._uuid, 10514106)
            self._proxy:AddBuff(self._uuid, 10514107)
            return
        end
        self._proxy:AddBuff(self._uuid, 10514109)
        self._proxy:AddBuff(self._uuid, 10514110)        
    end

    if (buffId == 10510704) then
        self._DodgeJianqi = true
    end

    if(buffId == 10519210) then
        self._cameraOnRight = true
    end
end

function XChar1051:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --寻找一个攻击目标
    Base.OnNpcRemoveBuffEvent(self,casterNpcUUID,npcUUID,buffId,buffKinds,buffUUId)
    if (buffId == 10513101) then
        if (self._useShenglong == false) then
            self._proxy:AbortAction(self._uuid, true)

            local targetNpc = self._proxy:SearchNpc(self._uuid, ENpcCampType.Camp2, 4, 20, -1)
            -- --无战斗目标释放技能
            if (targetNpc == 0) or (not targetNpc) then
                self._proxy:CastAction(self._uuid, 1051061)
                return
            end

            --有战斗目标释放技能
            self._proxy:CastActionToTarget(self._uuid, 1051061, targetNpc)
        end
        
        self._JianqiSkillGroup[1] = 1051042
        self._JianqiSkillGroup[2] = 1051041
        self._JianqiSkillGroup[3] = 1051043
        self._JianqiSkillGroup[4] = 1051045
    end

    if (buffId == 10510704) then
        XLog.Warning("弹刀结束")
        self._DodgeJianqi = false
        self._CastJianqi = false
    end

    if(buffId == 10514001) then
        self._jianqiCounter = 0
        self._canUseJianqi = false
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

    -- if not self._proxy:CheckNpcCurrentAction(self._uuid, 1051068) then
    --     if(buffId == 10516317) then
    --         self._proxy:ApplyMagic(self._uuid,self._uuid,10516321)
    --     end
    --     if(buffId == 10516319) then
    --         self._proxy:ApplyMagic(self._uuid,self._uuid,10516322)
    --     end
    --     if(buffId == 10516321) then
    --         self._proxy:ApplyMagic(self._uuid,self._uuid,10516323)
    --     end
    --     if(buffId == 10516322) then
    --         self._proxy:ApplyMagic(self._uuid,self._uuid,10516324)
    --     end
    --     if(buffId == 10516323) then
    --         self._proxy:ApplyMagic(self._uuid,self._uuid,10516325)
    --     end
    --     if(buffId == 10516324) then
    --         self._proxy:ApplyMagic(self._uuid,self._uuid,10516326)
    --     end
    -- end
end

--极限闪避处理
function XChar1051:OnNpcDodge(SourceUUID, AttackerUUID, Type)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type) 
    
    if (Type == 1) then 
        self._proxy:AddBuff(self._uuid, 10510704)
    end
end

function XChar1051:OnNpcCounterSuccess(triggerNpcUUID,counterNpcUUID, triggerTag, counterTag)
    Base.OnNpcCounterSuccess(self,triggerNpcUUID,counterNpcUUID,triggerTag,counterTag)
    --成功后无敌
    self._proxy:ApplyMagic(self._uuid,self._uuid,8005905,1)

    --强弹刀表现
    if self:ContainsGameplayTag(counterTag, EGameplayTag.Missile_Parry_Counter_Heavy) then
        XLog.Warning("触发完居合弹刀:")
        --放派生,做镜头
        if self._proxy:CheckNpcCurrentAction(self._uuid, 1051021) or self._proxy:CheckNpcCurrentAction(self._uuid, 1051022) then
            self._proxy:AbortAction(self._uuid, true)
            XLog.Warning("完美弹刀格挡")
            self._proxy:CastAction(self._uuid,1051027) --剑盾受击触发弹刀释放精确格挡
            self._GPJuhe = true
        end
        return
    end
end

function XChar1051:OnNpcSkillActionKeyframeSendEvent(launcher,eventName,skillActionId,keyFrameId,skillId)
    if(launcher == self._uuid) then
        if(eventName == "CastFinalJuhe") then
            --XLog.Warning("蓄力全满")
            local targetNpc = self._proxy:GetLockTarget()
            
            if (targetNpc == 0) or (not targetNpc) then
                XLog.Warning("无目标释放居合final")
                -- self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastAction(self._uuid,1051026)
                return
            end
            XLog.Warning("有目标释放居合final")
            -- self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToSearchTarget(self._uuid, 1051026, targetNpc)
        end

        if(eventName == "castNextCounter") then
            XLog.Warning("释放衔接")
            local targetNpc = self._proxy:GetLockTarget()
            if(self._proxy:CheckBuffByKind(self._uuid, 10513101)) then
                self._counterSkill = 1051086
            else
                self._counterSkill = 1051085
            end
            
            if (targetNpc == 0) or (not targetNpc) then
                XLog.Warning("无目标释放居合final")
                -- self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastAction(self._uuid,self._counterSkill)
                return
            end
            XLog.Warning("有目标释放居合final")
            -- self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToSearchTarget(self._uuid, self._counterSkill, targetNpc)
        end
    end
end


function XChar1051:ProcessFirstJianqi()
    if (self._firstJianqi == true) then
        if (self._proxy:CheckActionTiming(self._uuid, 16)) then

            local targetNpc = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)
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
            XLog.Warning("打断了当前技能")

            self._proxy:CastActionToSearchTarget(self._uuid, 1051041, targetNpc)

            XLog.Warning("释放剑气第一段:")
            self._firstJianqi = false
        end
    end
end

function XChar1051:JianqiKeyDown()
    if (self._proxy:CheckBuffByKind(self._uuid, 10514001)) then
        --监听按下攻击键
        if (self._proxy:IsKeyDown(ENpcOperationKey.Attack)) then
            if (self._canUseJianqi == true) then
                self._jianqiCounter = self._jianqiCounter + 1 --剑气计数器+1
                if (self._jianqiCounter <= 3) then
                    self._useJianqi = true                    --剑气连击
                    self._canUseJianqi = false
                    XLog.Warning("剑气连击+" ..self._jianqiCounter)
                else
                    self._useJianqi = false
                    XLog.Warning("剑气无法继续连击+" ..self._jianqiCounter)
                end
            end
        end
    end
end

function XChar1051:JianqiCombo()
    if (self._proxy:CheckBuffByKind(self._uuid, 10514001)) then
        if (self._proxy:CheckActionTiming(self._uuid, 17)) then
            XLog.Warning("剑气衔接点" .. tostring(self._useJianqi))
            --进行剑气连击
            if (self._useJianqi == true) then
                XLog.Warning("剑气时间到")
                self._proxy:AbortAction(self._uuid, true)
                XLog.Warning("打断了当前技能")

                local targetNpc = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)

                XLog.Warning("当前目标" ..targetNpc)
                --无目标释放技能
                if (targetNpc == 0) or (not targetNpc) then
                    local success,axis = self._proxy:TryGetQueryStickAxis()
                    if success and self._jianqiCounter < 3 and not self._proxy:CheckBuffByKind(self._uuid, 10513101) then
                        self._proxy:CastAction(self._uuid, 1051042)
                        self._useJianqi = false
                        XLog.Warning("消耗剑气缓存" .. self._jianqiCounter)
                        self._canUseJianqi = true
                        XLog.Warning("释放剑气移动攻击" .. self._jianqiCounter)
                        return
                    end
                    self._proxy:CastAction(self._uuid, self._JianqiSkillGroup[self._jianqiCounter])
                    self._useJianqi = false
                    XLog.Warning("消耗剑气缓存" .. self._jianqiCounter)
                    self._canUseJianqi = true

                    XLog.Warning("释放剑气攻击" .. self._jianqiCounter)
                    return
                end

                --有目标释放技能
                
                local success,axis = self._proxy:TryGetQueryStickAxis()
                if success and self._jianqiCounter < 3 and (not self._proxy:CheckBuffByKind(self._uuid, 10513101)) then
                    self._proxy:CastActionToSearchTarget(self._uuid, 1051042, targetNpc)
                    XLog.Warning("释放剑气移动攻击" .. self._jianqiCounter)
                    self._useJianqi = false
                    XLog.Warning("消耗剑气缓存" .. self._jianqiCounter)
                    self._canUseJianqi = true
                    XLog.Warning("重置输入")
                end

                self._proxy:CastActionToSearchTarget(self._uuid, self._JianqiSkillGroup[self._jianqiCounter], targetNpc)

                XLog.Warning("释放剑气攻击" .. self._jianqiCounter)

                self._useJianqi = false
                XLog.Warning("消耗剑气缓存"  .. tostring(self._useJianqi))
                self._canUseJianqi = true
                XLog.Warning("重置输入" .. tostring(self._canUseJianqi))

                --不进行剑气连击
            else
                XLog.Warning("剑气结束")
                self._proxy:AbortAction(self._uuid, true)

                local targetNpc = self._proxy:SearchNpc(self._uuid, ENpcCampType.Camp2, 4, 15, -1)

                --无目标释放技能
                if (targetNpc == 0) or (not targetNpc) then
                    self._proxy:CastActionEx(self._uuid, self._JianqiSkillGroup[4],0.35,5)
                    self._useJianqi = false
                    self._jianqiCounter = 0
                    self._proxy:RemoveBuff(self._uuid, 10514001)
                    return
                end

                --有目标释放技能
                local targetPos = self._proxy:GetNpcPosition(targetNpc)

                self._proxy:SetNpcFaceToPosition(self._uuid, targetPos) --转向
                self._proxy:SetFightTarget(self._uuid, targetNpc)      --设置战斗目标
                self._proxy:SetNpcFocusTarget(self._uuid, targetNpc)   --镜头锁定

                self._proxy:CastActionToTargetEx(self._uuid, self._JianqiSkillGroup[4], targetNpc,0.35,5)
                self._useJianqi = false
                self._jianqiCounter = 0
                self._proxy:RemoveBuff(self._uuid, 10514001)
            end
        end
    end
end

return XChar1051
