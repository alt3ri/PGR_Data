---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---Relink七实芒星之迹风格1角色脚本
---@class XChar1052 : XRelinkCharBase
local XCharR5Nanami1 = XDlcScriptManager.RegCharScript(1052, "XChar1052", Base)

function XCharR5Nanami1:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    ---- 技能计时器
    self._skillTimer = 0
    ---- 角力象限镜头用
    self._WristleCameraAngle = 0
    ---- 极限技1
    self._LimitSkill1 = 105268
    ---- 极限技2
    self._LimitSkill2 = 105274
    ---- 斧角力流程输入监听开关
    self.AxeWrestleInput = false
    ---- 角力用白龙锁定部位id
    self.LockPartForWrestle = 8001006
    ----角力期间部位锁定记录id（占位用，无实际对应id）
    self.LockTargetKeeper = 8001001
    ----斧角力期间计时
    self._WrestleTimer = 0
    ----斧角力期间输入计数
    self._WrestleInputCount = 0
    ----剑解气势系数
    self.BladeReleaseCoe = 0.0015
    ----超解气势系数
    self.OverReleaseCoe = 0.0015
    ----超解气势系数增长系数
    self.OverReleaseCoeAdd = 0.5
    ----存个角力响应对象
    self.WrestleTarget = 0

    ----黑板值处理
    ----存能量黑板值
    self._proxy:RegisterBBSync(1, self._uuid, 1052001)
    self._proxy:SetBBInt(1, self._uuid, 1052001, self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1))
    --self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) --初始声明自定义能量属性
    ----存剑解气势系数到黑板
    self:RegBB(1052002)
    self:SetBBFloat(1052002,0.0015)
    ----存超解气势系数到黑板
    self:RegBB(1052003)
    self:SetBBFloat(1052003,0.0015)
    ----存超解气势增长系数到黑板
    self:RegBB(1052004)
    self:SetBBFloat(1052004,0.5)

    ----重连部分效果初始化保底
    ----技能组初始化
    self:ReconnectedCheckSkillGroup()
end

----region 黑板值同步封装用，省两个值
function XCharR5Nanami1:RegBB(key)
    self._proxy:RegisterBBSync(1, self._uuid, key)
end

function XCharR5Nanami1:SetBBInt(key,value)
    self._proxy:SetBBInt(1, self._uuid, key, value)
end

function XCharR5Nanami1:SetBBFloat(key,value)
    self._proxy:SetBBFloat(1,self._uuid,key,value)
end

function XCharR5Nanami1:TryGetBBInt(key)
    return self._proxy:TryGetBBInt(1, self._uuid, key)
end

function XCharR5Nanami1:TryGetBBFloat(key)
    return self._proxy:TryGetBBFloat(1, self._uuid, key)
end
----endregion

function XCharR5Nanami1:InitEventCallBackRegister()
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


local timeScale = 1
---@param dt number @ delta time
function XCharR5Nanami1:Update(dt)
    Base.Update(self, dt)
    --self:TestInputLogic()
    self:CheckInputDuringAxeWrestle()
    self:UpdateDefendRecover()
    self:CheckMoveAddParticle()
    if self._proxy:CheckNpcCurrentAction(self._uuid,105259) then
        --更新角力时间
        self._WrestleTimer = self._WrestleTimer + dt
    end
    if self._proxy:CheckNpcFullActionState(self._uuid, 3, -1) then
        -- 更新技能时间
        self._skillTimer = self._skillTimer + dt
        self:SkillAtuoCombo()
        return
    end
end

---@param eventType number
---@param eventArgs userdata
function XCharR5Nanami1:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcHurtProtector then
        self:XNpcHurtProtectorArgs(eventArgs.LauncherId, eventArgs.TargetId, eventArgs.Value, eventArgs.TotalValue)
    end

end

function XCharR5Nanami1:OnNpcSkillActionKeyframeSendEvent(launcher,eventName,skillActionId,keyFrameId,skillId)
    Base.OnNpcSkillActionKeyframeSendEvent(self,launcher,eventName,skillActionId,keyFrameId,skillId)
    --XLog.Warning("收到了自己发送的技能帧事件")
    --XLog.Warning(eventName)
    if eventName == "AddCoreEnergyL1" then
        if self._proxy:CheckBuffByKind(self._uuid,1052821) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052818,1)
        else
            self._proxy:ApplyMagic(self._uuid,self._uuid,105238,1)
        end
    end

    if eventName == "AddCoreEnergyL2" then
        if self._proxy:CheckBuffByKind(self._uuid,1052821) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052818,2)
        else
            self._proxy:ApplyMagic(self._uuid,self._uuid,105238,2)
        end
    end

    if eventName == "AddCoreEnergyL3" then
        if self._proxy:CheckBuffByKind(self._uuid,1052821) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052818,3)
        else
            self._proxy:ApplyMagic(self._uuid,self._uuid,105238,3)
        end
    end

    if eventName == "SupportPortal" then
        self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("支援移动后进入回击流程")
        local _,locktargetUUID = self._proxy:GetLockTarget(self._uuid)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionToTargetEx(self._uuid,105250,locktargetUUID,0,5)
        else
            self._proxy:CastActionToTargetEx(self._uuid,105251,locktargetUUID,0,5)
        end
    end

    if eventName == "WrestleAtkLoop" then
       self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("帧事件，攻击完成后回归")
        self._proxy:CastActionEx(self._uuid,105245,0,5)
    end

    if eventName == "RandomEmoji" then
        --XLog.Warning("帧事件，极限技或大招随机表情")
        local index = math.random(1, 3)
        local messageid = 14
        if index == 2 then
            messageid = 15
        elseif index == 3 then
            messageid = 16
        end
            self._proxy:ShowQuickMessage(messageid)
    end
end

function XCharR5Nanami1:Terminate()
    Base.Terminate(self)
end


function XCharR5Nanami1:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if launcherId ~= targetId and targetId == self._uuid then
        if self._proxy:CheckBuffByKind(self._uuid, 105233) and self._proxy:CheckBuffByKind(self._uuid, 8005501) then
            self._proxy:AbortAction(self._uuid, true)
            --旧弹刀逻辑，通过buff确认区分，目前已不通过
            --XLog.Warning("完美弹刀格挡")
            self._proxy:CastActionEx(self._uuid,105240,0.26,3.83) --剑盾受击触发弹刀释放精确格挡
            if self._proxy:CheckBuffByKind(self._uuid, 105218) then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052283,1) --添加斧反击标记
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid,105243,0,2) --斧受击触发弹刀释放精确格挡
            end
            --
        elseif self._proxy:CheckBuffByKind(self._uuid, 105233) then
            self._proxy:AbortAction(self._uuid, true)
            --XLog.Warning("精确格挡受击")
            self._proxy:CastActionEx(self._uuid,105220,0.26,3.83) --剑盾受击释放精确格挡
            if self._proxy:CheckBuffByKind(self._uuid, 105218) then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052283,1) --添加斧反击标记
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid,105238,0,2) --斧受击释放精确格挡
            end
        elseif self._proxy:CheckBuffByKind(self._uuid, 105234) then
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionEx(self._uuid,105234,0.26,3.83) --剑盾受击释放普通格挡
            if self._proxy:CheckBuffByKind(self._uuid, 105218) then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052283,1) --添加斧反击标记
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid,105239,0,2) --斧受击释放普通格挡
            end
        end

    end
end

function XCharR5Nanami1:XNpcChangeProtectorArgs(LauncherId, TargetId, Value, TotalValue)
    Base.XNpcChangeProtectorArgs(self)
    --XLog.Warning("TotalValue"..TotalValue)
    --XLog.Warning("Value"..Value)
    if  TargetId == self._uuid and TotalValue > 0 then
        --XLog.Warning("添加弱霸体")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052388,1)
    elseif TargetId == self._uuid and TotalValue == 0 then
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1052388,0)
        --XLog.Warning("移除弱霸体")
    end
end

---计算伤害前
    function XCharR5Nanami1:ChangeDamageBeforeCalc(eventArgs)
    Base.ChangeDamageBeforeCalc( self, eventArgs)
    self._uuid = self._proxy:GetSelfNpcId()
    ----超解伤害修正
    if eventArgs.Id == 1052001 then
        --self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) -- 确认消耗后的能量状况
        local CurCustomPower1 =  self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) --获取当前的能量
        local HasCustomPower, customPower = self._proxy:TryGetBBInt(1,self._uuid, 1052001) --获取黑板记录的峰值
        local HasOverReleaseCoeAdd,OverReleaseCoeAdd = self:TryGetBBFloat(1052004) --获取黑板中的气势强化系数
        local HasOverReleaseCoe , OverReleaseCoe = self:TryGetBBFloat(1052003) -- 获取黑板中的气势系数
        if self._proxy:CheckBuffByKind(self._uuid,1052383) then  --气势强化与否
            --XLog.Warning("强化修正前伤害倍率："..eventArgs.PhysicalPermyraid)
            local FinalDMGRate = eventArgs.PhysicalPermyraid * (1 +(customPower-CurCustomPower1)* OverReleaseCoe *(1+OverReleaseCoeAdd))
            --XLog.Warning("强化修正后伤害倍率："..FinalDMGRate)
            self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate , eventArgs.ElementPermyraid, eventArgs.HackDamage, eventArgs.HackPermyraid, eventArgs.isCrit)
        else
            --XLog.Warning("修正前伤害倍率："..eventArgs.PhysicalPermyraid)
            local FinalDMGRate = eventArgs.PhysicalPermyraid * (1 +(customPower-CurCustomPower1)* OverReleaseCoe)
            --XLog.Warning("修正后伤害倍率："..FinalDMGRate)
            self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyraid, eventArgs.HackDamage, eventArgs.HackPermyraid, eventArgs.isCrit)
        end
        self._proxy:SetBBInt(1, self._uuid, self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1)) -- 清除黑板中的峰值
    end
----剑解伤害修正
    if eventArgs.Id == 1052017 then
    local HasBladeReleaseCoe, BladeReleaseCoe = self:TryGetBBFloat(1052002)
        --XLog.Warning("修正前伤害倍率：".. eventArgs.PhysicalPermyraid)
        local FinalDMGRate =  eventArgs.PhysicalPermyraid * (1 + (100 * BladeReleaseCoe))
        --XLog.Warning("修正后伤害倍率："..FinalDMGRate)
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyraid, eventArgs.HackDamage, eventArgs.HackPermyraid, eventArgs.isCrit)
    end

----防御减伤相关逻辑处理
    if eventArgs.Launcher ~= eventArgs.Target and eventArgs.Target == self._uuid then --受击流程，伤害来源不是自己
        if (self._proxy:CheckNpcCurrentAction(self._uuid,105206) or self._proxy:CheckNpcCurrentAction(self._uuid,105224)
                or self._proxy:CheckNpcCurrentAction(self._uuid,105225) )  --处于防御技能类中
                and not (self._proxy:CheckBuffByKind(self._uuid,105233) or self._proxy:CheckBuffByKind(self._uuid,105234)) then --非格挡情况下
            self:CheckDefendResources() --检测防御受击相关时当前闪避资源
            self._proxy:ApplyMagic(self._uuid,self._uuid,105259,1)  --防御减伤
        elseif self._proxy:CheckBuffByKind(self._uuid,105234) then
            self:CheckDefendResources() --检测防御受击相关时当前闪避资源
            if self._proxy:CheckBuffByKind(self._uuid,1052900) then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052800,1)  --防御插件金减伤
                self._proxy:ApplyMagic(self._uuid,self._uuid,105260,1)  --触发格挡减伤
            elseif self._proxy:CheckBuffByKind(self._uuid,1052906) then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052801,1)  --防御插件红减伤
                self._proxy:ApplyMagic(self._uuid,self._uuid,105260,1)  --触发格挡减伤
            else
                self._proxy:ApplyMagic(self._uuid,self._uuid,105260,1)  --触发格挡减伤
            end
        elseif self._proxy:CheckBuffByKind(self._uuid,105233) then
            self:CheckDefendResources() --检测防御受击相关时当前闪避资源
            if self._proxy:CheckBuffByKind(self._uuid,1052900) then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052800,1)  --防御插件金减伤
                self._proxy:ApplyMagic(self._uuid,self._uuid,105261,1)  --触发完美格挡减伤
            elseif self._proxy:CheckBuffByKind(self._uuid,1052906) then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052801,1)  --防御插件红减伤
                self._proxy:ApplyMagic(self._uuid,self._uuid,105261,1)  --触发完美格挡减伤
            else
                self._proxy:ApplyMagic(self._uuid,self._uuid,105261,1)  --触发完美格挡减伤
            end
        end
    end

    ----格挡增伤相关处理
    if eventArgs.Id == 1052021 or eventArgs.Id == 1052022 or eventArgs.Id == 1052028 or eventArgs.Id == 1052029 then
        if self._proxy:CheckBuffByKind(self._uuid,1052900) then
            -- XLog.Warning("格挡金")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052802,1,eventArgs.ContextId,1)  --格挡伤害金增益
        elseif self._proxy:CheckBuffByKind(self._uuid,1052906) then
            -- XLog.Warning("格挡红")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052803,1,eventArgs.ContextId,1)  --格挡伤害红增益
        end
    end

end

function XCharR5Nanami1:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if npcUUID ~= self._uuid then
        return
    end

    --切换剑盾与斧相关动画状态与技能ui显示
    if buffId == 105217 then
        self._proxy:SetNpcAnimationLayer(self._uuid,0)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105205) --切换技能组3
        --self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105203) --还原技能组1
        --self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105204) --还原技能组2
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052360,1) --移除常驻fov增加
    elseif buffId == 105218 then
        self._proxy:SetNpcAnimationLayer(self._uuid,1)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105210) --切换技能组3
        --self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105211) --空置技能组1
        --self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105211) --空置技能组2
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052359,1) --常驻fov增加
    end

    if buffId == 105219 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105209)
    end
    --原角力流程buff模拟阶段（已废弃）
    --[[
    if buffId == 1000450 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105276,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105289,1) --关闭碰撞
        --XLog.Warning("多人联弹触发")
    end
    if buffId == 1000462 then
        self._proxy:AbortAction(self._uuid,true)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105245,0,5)
            --XLog.Warning("多人联弹进入僵持循环,剑盾")
        elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
            self._proxy:CastActionEx(self._uuid,105259,0,5)
            --XLog.Warning("多人联弹进入僵持循环,斧")
        end
    end
    if buffId == 1000455 then
        self._proxy:AbortAction(self._uuid,true)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105246,0,5)
            --XLog.Warning("多人联弹僵持失败，剑盾")
        elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
            self._proxy:CastActionEx(self._uuid,105260,0,5)
            --XLog.Warning("多人联弹僵持失败，斧")
            self._proxy:ApplyMagic(self._uuid,self._uuid,105286,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105287,1)
        end
    end
    if buffId == 1000454 then
        self._proxy:AbortAction(self._uuid,true)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105247,0,5)
            self._proxy:ApplyMagic(self._uuid,self._uuid,1000460,1)
            --XLog.Warning("多人联弹僵持成功，剑盾")
        elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
            self._proxy:CastActionEx(self._uuid,105261,0,5)
            self._proxy:ApplyMagic(self._uuid,self._uuid,1000460,1)
            --XLog.Warning("多人联弹僵持成功，斧")
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,105286,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105287,1)
    end
    --]]
end

function XCharR5Nanami1:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcRemoveBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --[[
    if buffId == 105255 then
        --XLog.Warning("防御标记delay移除：")
        if self._proxy:CheckNpcCurrentAction(self._uuid,105224) and self._proxy:IsKeyHold(2,0.2) then
            self:DefendSkillLoop()
        elseif self._proxy:CheckNpcCurrentAction(self._uuid,105236) and self._proxy:IsKeyHold(2,0.2)  then
            self:DefendSkillLoop()
        elseif (self._proxy:CheckNpcCurrentAction(self._uuid,105238)and self._proxy:IsKeyHold(2,0.2)) or
                (self._proxy:CheckNpcCurrentAction(self._uuid,105239)and self._proxy:IsKeyHold(2,0.2)) then
            --XLog.Warning("斧受击防御恢复")
            self:BehitSkillRecoverInDefend()
        end
    end
    ]]
    if buffId == 105219 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105203)
    end
    if buffId == 105276 then
        --XLog.Warning("角力buff前置")
        self._proxy:AbortAction(self._uuid,true)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            --XLog.Warning("检测剑盾")
            self._proxy:CastActionEx(self._uuid,105244,0,5)
            --XLog.Warning("多人联弹进入,剑盾角力")
        elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
            self._proxy:CastActionEx(self._uuid,105258,0,5)
            --XLog.Warning("多人联弹进入,斧角力")
        end
    end
end

function XCharR5Nanami1:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    self:SkillCVCast(skillId)

    if skillId == self._LimitSkill1 or skillId == self._LimitSkill2 then
        self._proxy:SetTeamWorkSkillNpcRemainUseCount(self._uuid,0)
    end

    if skillId == 105221 or skillId == 105222 then
        --XLog.Warning("大招期间不被裁切")
        self._proxy:SetNpcDither(self._uuid,false)
    end


    if skillId == 105219 then
        --核心技能能量值消耗
        self._proxy:SetBBInt(1, self._uuid, 1052001, self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1)) --记录峰值
        --XLog.Warning("记录当前能量值："..self.CurCustomPower1)
    end

    if skillId == 105235 or skillId == 105236 or skillId == 105237 or skillId == 105265 then
        --XLog.Warning("记录连段")
        if self._proxy:CheckBuffByKind(self._uuid,1052367) then
            --XLog.Warning("记录连段3中")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052370,1)
        elseif self._proxy:CheckBuffByKind(self._uuid,1052366) then
            --XLog.Warning("记录连段2中")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052369,1)
        elseif self._proxy:CheckBuffByKind(self._uuid,1052365) then
            --XLog.Warning("记录连段1中")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052368,1)
        end
    end

    --角力相关技能进入
    if skillId == 105244 then
        -- XLog.Warning("角力僵持发生")
        --self:WrestleEnterCamera()--角力发生镜头
        self:WrestleEnterCameraNew()--角力发生新镜头
    end
    if skillId == 105256 then
        --XLog.Warning("角力弹开后派生")
    end
    if skillId == 105245 then
        --XLog.Warning("角力僵持持续")
        --self:WrestleLoopingCamera()--角力维持镜头
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052136,1) --模拟扰动震屏
    end
    if skillId == 105246 then
        --XLog.Warning("角力僵持失败")
        self:WrestleFailCameraNew()
    end
    if skillId == 105247 then
        --XLog.Warning("角力僵持成功")
        --self:WrestleEndCamera()--角力退出镜头
        self:WrestleSuccessCameraNew()
    end

    if skillId == 105249 then
        --XLog.Warning("支援角色响应")
        self:SupportBlinkCamera()
    end
    if skillId == 105252 then
        --XLog.Warning("终结角色响应")
        --self:SupportBlinkCamera()
        self:UltraBlinkCamera()
    end
    if skillId == 105256 then
        --XLog.Warning("角力成功派生1")
    end
    if skillId == 105257 then
        --XLog.Warning("角力成功派生2")
    end
    if skillId == 105250 then
        --XLog.Warning("移动后地面回击1")
    end
    if skillId == 105251 then
        --XLog.Warning("移动后地面回击2")
    end
    if skillId == 105253 then
        --XLog.Warning("移动后空中回击1")
    end
    if skillId == 105254 then
        --XLog.Warning("移动后空中回击2")
    end
    if skillId == 105258 then
        self:WrestleEnterCameraNew()
        --XLog.Warning("角力僵持发生，斧")
    end
    if skillId == 105259 then
        --XLog.Warning("角力僵持持续，斧")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052136,1) --模拟扰动震屏
    end
    if skillId == 105260 then
        --XLog.Warning("角力僵持失败，斧")
        self:WrestleFailCameraNew()
    end
    if skillId == 105261 then
        --XLog.Warning("角力僵持成功，斧")
        self:WrestleSuccessCameraNew()
    end
    if skillId == 105271 then
        -- XLog.Warning("测试瞬移流程镜头")
        self:SupportBlinkCamera()
    end
    if skillId == 105276 then
        -- XLog.Warning("测试瞬移流程镜头")
        self:SupportBlinkCamera()
    end

    --弹刀派生相关进入
    if skillId == 105241 or skillId == 105226 then
        -- XLog.Warning("弹刀派生镜头问题")
        local _,Angle  = self._proxy:GetCameraPosInfo(self._uuid,0,0)
        -- XLog.Warning("镜头朝向与控制器朝向角度"..Angle)
        if Angle < 70 or Angle > 220 then
            return
        else
            self:CounterAttackCamera()
        end
    end
    self._skillTimer = 0
end

function XCharR5Nanami1:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    if skillId == 105226 or skillId == 105227 or skillId == 105241 or skillId == 105242 then
        --XLog.Warning("确认退出格挡派生事件")
            self._proxy:ApplyMagic(self._uuid,self._uuid,105203,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105204,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105202,1)
    end

    if skillId == 105213 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105200,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105201,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105205,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052185,1)
    end

    if skillId == 105214 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105203,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105204,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105202,1)
    end

    if skillId == 105221 or skillId == 105222 then
        --XLog.Warning("裁切还原")
        self._proxy:SetNpcDither(self._uuid,true)
    end

    if skillId == 105246 or skillId == 105247 or skillId == 105260 or skillId == 105261 then
        --self._proxy:ApplyMagic(self._uuid,self._uuid,105290,1)  --开启碰撞
    end
    if skillId == 105215 then
        --XLog.Warning("斧普攻1退出")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052365,1)
    elseif skillId == 105216 then
        --XLog.Warning("斧普攻2退出")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052366,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052371,1)
    elseif skillId == 105217 then
        --XLog.Warning("斧普攻3退出")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052367,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052372,1)
    elseif skillId == 105218 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052373,1)
    end
    if skillId == 105261 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end

    if skillId == 105253 then
        --XLog.Warning("剑盾终结攻击退出处理隐藏")
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,105203,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105204,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105202,1)
        end
    end
    self._skillTimer = 0
    self._WrestleInputCount = 0
end

function XCharR5Nanami1:SkillCVCast(skillId)
    --cv语音播放
    --剑盾大招
    if skillId == 105221 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052500,1)
    end
    --盾斧大招
    if skillId == 105222 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052501,1)
    end
    --超解
    if skillId == 105219 or skillId == 105227 or skillId == 105242  then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052507,1)
    end
    --切盾斧随机语音
    if skillId == 105213  then
        local index = math.random(1, 2)
        local magicid = 1052503
        if index == 2 then
            magicid = 1052505
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicid,1)
    end
    --切剑盾随机语音
    if skillId == 105214  then
        local index = math.random(1, 2)
        local magicid = 1052502
        if index == 2 then
            magicid = 1052512
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicid,1)
    end
    --切格挡及防御随机语音
    if skillId == 105238 or skillId == 105243 or skillId == 105220 or skillId == 105240 then
        local index = math.random(1, 2)
        local magicid = 1052506
        if index == 2 then
            magicid = 1052510
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicid,1)
    end
    --普通格挡概率语音
    if skillId == 105239 or skillId == 105234 then
        local index = math.random(1, 3)
        if index == 2 then
            --XLog.Warning("普通防御概率语音")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052510,1)
        end
    end
    --普攻语音
    if skillId == 105201 or skillId == 105215 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052508,1)
    end
    --剑盾普攻4随机语音
    if skillId == 105204  then
        local index = math.random(1, 2)
        local magicid = 1052511
        if index == 2 then
            magicid = 1052512
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicid,1)
    end
    --盾斧普攻3概率语音
    if skillId == 105217  then
        local index = math.random(1, 2)
        if index == 2 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052511,1)
        end
    end
    --盾斧普攻4概率语音
    if skillId == 105218  then
        local index = math.random(1, 2)
        if index == 2 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052512,1)
        end
    end
end

function XCharR5Nanami1:DefendSkillLoop()
    --XLog.Warning("确认防御的循环维持")
    self._proxy:AbortAction(self._uuid, true)
    if self._proxy:CheckBuffByKind(self._uuid,105217) then
        --XLog.Warning("持续防御")
        self._proxy:CastActionEx(self._uuid,105224,0,3)
    elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
        self._proxy:CastActionEx(self._uuid,105236,0,3)
    end

end

function XCharR5Nanami1:BehitSkillRecoverInDefend()
    --XLog.Warning("执行斧防御的受击恢复逻辑")
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastActionEx(self._uuid,105236,0,3)
end

--region 按键测试逻辑
function XCharR5Nanami1:TestInputLogic()

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball4) then
        local TestAction = 105268
        local _,locktargetUUID = self._proxy:GetLockTarget()
        self._proxy:CastSkillActionNotCheck(self._uuid,TestAction,0,999)
        --self._proxy:CastSkillActionToNpcNotCheck(self._uuid,TestAction,locktargetUUID,0,999)
        --XLog.Warning("测试技能"..TestAction)
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball5) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052904,1)
        --XLog.Warning("1052900")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball6) then
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1052388,0)
        --XLog.Warning("移除护盾弱霸体")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball7) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052348,1)
        --XLog.Warning("破韧")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball8) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052386,1)
        --XLog.Warning("增加闪避能量")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball9) then
        if self._proxy:CheckNpcCurrentAction(self._uuid,105245) then
            self._proxy:CastAction(self._uuid,105248)
            --XLog.Warning("单独测试角色输入流程")
        end
    end

end
--endregion

--region 自动连招内容
function XCharR5Nanami1:SkillAtuoCombo()
    --XLog.Warning("计算"..self._skillTimer)
    --[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105245) and self._skillTimer >= 1 then
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105245,0,5)
        --XLog.Warning("僵持循环中")
        local npclist = self._proxy:GetNpcList()
        for _, npcuuid in pairs(npclist) do
            if npcuuid == 0  then
                return
            end
            if self._proxy:CheckBuffByKind(npcuuid,1000451) then
                self._proxy:SetFightTarget(self._uuid,npcuuid)
                --XLog.Warning("僵持循环中维持战斗状态稳定")
            end
        end
    end
--]]
    --[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105259) and self._skillTimer >= 1 then
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105259,0,5)
        --XLog.Warning("斧僵持循环中")
    end
--]]
    --[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105248) and self._skillTimer >= 2  then --剑盾角力攻击1完成时回到僵持循环的内容
        -- XLog.Debug(self._skillTimer)
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105245,0,5)
        --XLog.Warning("完成攻击动作后回到僵持循环")
    end
--]]
    if self._proxy:CheckNpcCurrentAction(self._uuid,105269) and self._skillTimer >= 0.6 then --剑盾角力攻击2完成时回到僵持循环的内容
        --XLog.Debug(self._skillTimer)
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105245,0,5)
        --XLog.Warning("完成攻击动作后回到僵持循环")
    end
----[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105262) and self._skillTimer >= 0.8 then --斧角力攻击动作完成时回到僵持循环的内容
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105259,0,5)
        --XLog.Warning("斧完成攻击动作后回到僵持循环")
    end
----]]

    if self._proxy:CheckNpcCurrentAction(self._uuid,105252) and self._skillTimer >= 1 then
        self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("终结移动后攻击流程")
        local _,locktargetUUID = self._proxy:GetLockTarget(self._uuid)
        if locktargetUUID ~= 0 then
            self._proxy:CastActionToTargetEx(self._uuid,105253,locktargetUUID,0,5)
        else
            local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)
            if searchtarget == 0 then
                return
            end
            self._proxy:SetSoftLock(self._uuid,searchtarget)
            local _,locktargetUUID = self._proxy:GetLockTarget(self._uuid)
            self._proxy:CastActionToTargetEx(self._uuid,105253,locktargetUUID,0,5)
        end
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105276) and self._skillTimer >= 0.9 then
        self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("斧终结移动后攻击流程")
        local _,locktargetUUID = self._proxy:GetLockTarget(self._uuid)
        if locktargetUUID ~= 0 then
            self._proxy:CastActionToTargetEx(self._uuid,105254,locktargetUUID,0,5)
        else
            local searchtarget = self._proxy:GetFirstSearchTarget(self._uuid,ENpcTargetType.Enemy)
            if searchtarget == 0 then
                return
            end
            self._proxy:SetSoftLock(self._uuid,searchtarget)
            local _,locktargetUUID = self._proxy:GetLockTarget(self._uuid)
            self._proxy:CastActionToTargetEx(self._uuid,105254,locktargetUUID,0,5)
        end

    end

--[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105271) and self._skillTimer >= 0.9 then
        self._proxy:AbortAction(self._uuid,true)
        XLog.Warning("弹刀移动后走攻击弹开动作，测试表现效果")
        self._proxy:CastActionEx(self._uuid,105255,0,5)
    end
--]]
    if self._proxy:CheckNpcCurrentAction(self._uuid,105247) and self._skillTimer >= 1.05 then
        --XLog.Warning("角力成功清除镜头")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105246) and self._skillTimer >= 0.7 then
        --XLog.Warning("角力失败清除镜头")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105260) and self._skillTimer >= 0.7 then
        --XLog.Warning("角力失败清除镜头")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105261) and self._skillTimer >= 0.95 then
        --XLog.Warning("角力失败清除镜头")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end
end
--endregion

--region 角力相关表现镜头
function XCharR5Nanami1:WrestleEnterCamera() --剑盾角力进入
    local _,npc = self._proxy:GetLockTarget()
    local _,angle = self._proxy:GetCameraPosInfo(self._uuid,npc)
    if angle >= 180 then
        self._WristleCameraAngle = 0
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052162,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052163,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052164,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052189,1)
    else
        self._WristleCameraAngle = 1
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052162,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052163,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052164,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052189,1)
    end
end

function XCharR5Nanami1:WrestleLoopingCamera() --剑盾角力持续中
    if not self._proxy:CheckBuffByKind(self._uuid,1052165) then --排除重复进入导致的镜头效果问题
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052165,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052166,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052167,1)
        --self._proxy:ApplyMagic(self._uuid,self._uuid,1052136,1) --模拟扰动震屏

    end
end

function XCharR5Nanami1:WrestleEndCamera() --剑盾角力成功
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052168,1)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052169,1)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052170,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052172,1)
end

function XCharR5Nanami1:WrestleEnterCameraNew() --角力进入新
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052313,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052314,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052315,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052316,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052317,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052318,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052319,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052320,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052321,1)

end

function XCharR5Nanami1:WrestleFailCameraNew() --角力失败退出新
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052325,1)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052326,1)
end

function XCharR5Nanami1:WrestleSuccessCameraNew() --角力成功退出新
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052338,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052168,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052169,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052170,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052172,1)
end

--endregion

--region 镜头处理相关
function XCharR5Nanami1:CounterAttackCamera() --格挡反击镜头
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052173,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052174,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052175,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052176,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052177,1)
end

function XCharR5Nanami1:SupportBlinkCamera() --支援位移镜头(含加速处理)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052341,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052342,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052343,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052344,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052345,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052346,1)
end

function XCharR5Nanami1:UltraBlinkCamera() --终结位移镜头
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052390,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052391,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052392,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052393,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052394,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052395,1)
end
--endregion

--region Update执行相关函数
function XCharR5Nanami1:UpdateDefendRecover() --tick确认当前是否应该回到防御状态中
    if self._proxy:CheckNpcCurrentAction(self._uuid,105238) or self._proxy:CheckNpcCurrentAction(self._uuid,105239) or self._proxy:CheckNpcCurrentAction(self._uuid,105243) or
            self._proxy:CheckNpcCurrentAction(self._uuid,105220) or self._proxy:CheckNpcCurrentAction(self._uuid,105234) or self._proxy:CheckNpcCurrentAction(self._uuid,105240) then
        --XLog.Warning("防御恢复长按")
        if self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.DodgeEnergy) > 0 then
            --XLog.Warning("闪避能量"..ENpcAttrib.DodgeEnergy)
            if self._proxy:IsKeyHold(ENpcOperationKey.Dodge) then
                --XLog.Warning("通过状态")
                if self._proxy:CheckActionTiming(self._uuid,16) then
                    if self._proxy:CheckBuffByKind(self._uuid,105218) then
                        --XLog.Warning("斧恢复")
                        self._proxy:AbortAction(self._uuid, true)
                        self._proxy:CastActionEx(self._uuid,105236,0,9999)
                    elseif self._proxy:CheckBuffByKind(self._uuid,105217) then
                        --XLog.Warning("剑盾恢复")
                        self._proxy:AbortAction(self._uuid, true)
                        self._proxy:ApplyMagic(self._uuid,self._uuid,1052280,1)
                        self._proxy:CastActionEx(self._uuid,105224,0,9999)
                    end
                end
            end
        end
    elseif self._proxy:CheckNpcCurrentAction(self._uuid,105224) or self._proxy:CheckNpcCurrentAction(self._uuid,105236) then
        if not self._proxy:IsKeyHold(ENpcOperationKey.Dodge) then
            if self._proxy:CheckBuffByKind(self._uuid,105218)  then
                self._proxy:CastActionEx(self._uuid,105237,0,1.3)
            elseif self._proxy:CheckBuffByKind(self._uuid,105217)   then
                self._proxy:CastActionEx(self._uuid,105225,0,1.2)
            end
        end
        if self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.DodgeEnergy) == 0 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052387,1)
            --XLog.Warning("防御能量不足")
            if self._proxy:CheckBuffByKind(self._uuid,105218) and self._proxy:IsKeyUp(ENpcOperationKey.Dodge) then
                --XLog.Warning("防御打断退出")
                self._proxy:CastActionEx(self._uuid,105237,0,1.3)
            elseif self._proxy:CheckBuffByKind(self._uuid,105217) and self._proxy:IsKeyUp(ENpcOperationKey.Dodge) then
                --XLog.Warning("防御打断退出")
                self._proxy:CastActionEx(self._uuid,105225,0,1.2)
            end
        end
    end
end

function XCharR5Nanami1:CheckMoveAddParticle()
    if self._proxy:CheckNpcFullActionState(self._uuid,ENpcAction.Move,-1) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105209,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105210,1)
    elseif not  self._proxy:CheckNpcFullActionState(self._uuid,ENpcAction.Jump,-1) then
        self._proxy:RemoveBuffByKindAndCount(self._uuid,105209,0)
        self._proxy:RemoveBuffByKindAndCount(self._uuid,105210,0)
    end
end

function XCharR5Nanami1:CheckInputDuringAxeWrestle()
    if self.WrestleTarget == self._uuid then
        if  self.AxeWrestleInput == true and self._proxy:IsKeyDown(ENpcOperationKey.RelinkQte) then
            --XLog.Warning("斧点击")
            if self._WrestleTimer >= 0.4 then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052129,1)
                self._WrestleInputCount = self._WrestleInputCount +1
                self._WrestleTimer = 0
            end
            if self._WrestleInputCount < 3 then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052361,1) --火花
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052374,1) --材质
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052378,1) --爆发
            elseif self._WrestleInputCount < 6 then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052362,1) --火花
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052375,1) --材质
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052378,1) --爆发
            else
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052363,1) --火花
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052376,1) --材质
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052379,1) --爆发
            end
        end

    end
end
--endregion

--region 防御弹刀相关逻辑
function XCharR5Nanami1:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    Base.OnNpcCounterSuccess(self,triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    if self._proxy:CheckNpcCurrentAction(self._uuid, 105206) or self._proxy:CheckNpcCurrentAction(self._uuid, 105224)
            or self._proxy:CheckNpcCurrentAction(self._uuid,105235) or self._proxy:CheckNpcCurrentAction(self._uuid,105236)then
        self._proxy:AbortAction(self._uuid, true)
        if self._proxy:CheckBuffByKind(self._uuid, 105217) then
            self._proxy:CastActionEx(self._uuid,105240,0.26,3.83) --剑盾受击触发弹刀释放精确格挡
        elseif self._proxy:CheckBuffByKind(self._uuid, 105218) then
            self._proxy:CastActionEx(self._uuid,105243,0,2) --斧受击触发弹刀释放精确格挡

        end
    end
end

function XCharR5Nanami1:CheckDefendResources() --防御资源不足时移除霸体效果
    local CurDodageRes = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.DodgeEnergy)
    --XLog.Warning("要被干碎了"..CurDodageRes)
    if CurDodageRes <= 0 then
        --XLog.Warning("移除霸体")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052387,1)

    end
end
--endregion

--region 角力监听节点(处理部分角力相关的保底内容)
function XCharR5Nanami1:OnNpcWrestleStart(launcherNpcUUID, targetNpcUUID, succeed)
    Base.OnNpcWrestleStart(self,launcherNpcUUID, targetNpcUUID, succeed)
    self.WrestleTarget = targetNpcUUID
    if targetNpcUUID ~= self._uuid then
        return
    end
    --使用旧有镜头设置
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052284,1)
    --self._proxy:ShowMechanismBar(4, 0, 0, 0, self._uuid, 0, false, true,targetNpcUUID)
    --角力进入强制设置锁定目标
    self.LockTargetKeeper = self._proxy:GetLockTarget()
    --XLog.Warning("程序角力进入 "..self.LockTargetKeeper .. " launcherUUID" .. launcherNpcUUID .. " targetNpcUUID" .. targetNpcUUID)
    self._proxy:SetHardLockToPart(targetNpcUUID,launcherNpcUUID,self.LockPartForWrestle)
    --角力进入设置碰撞关闭
    self._proxy:ApplyMagic(self._uuid,self._uuid,105289,1) --关闭碰撞
    --设置白龙不被裁切
    self._proxy:SetNpcDither(launcherNpcUUID,true)
    --移除斧形态offset内容
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052371,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052372,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052373,1)
    --角力进入隐藏小飞机
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052380,1)
    --斧角力进入开启角力输入监听
    if self._proxy:CheckBuffByKind(self._uuid,105218) then
        self.AxeWrestleInput = true
    end
end

function XCharR5Nanami1:OnNpcWrestlePursuit(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestlePursuit(self,launcherNpcUUID, targetNpcUUID)
    self.WrestleTarget = 0
    if targetNpcUUID ~= self._uuid then
        return
    end
    --延时移除角力镜头参数
    self._proxy:AddTimerTask(0.5,function()
        self._proxy:RemoveBuffByKindAndCount(targetNpcUUID,1052284,0)
    end)
    --XLog.Warning("角力失败,隐藏角力机制条")
    --self._proxy:HideMechanismBar(4)
    self.AxeWrestleInput = false
    --角力退出还原锁定配置
    self._proxy:SetHardLock(targetNpcUUID,self.LockTargetKeeper)
    --设置白龙不被裁切
    self._proxy:SetNpcDither(launcherNpcUUID,false)
    --角力退出开启碰撞
    self._proxy:ApplyMagic(self._uuid,self._uuid,105290,1) --开启碰撞
    --角力退出显示小飞机
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052381,1)
    --角力失败隐藏材质效果
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052377,1) --角力失败移除斧材质
    self.LockTargetKeeper = 8001001
end

function XCharR5Nanami1:OnNpcWrestleReversal(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestleReversal(self,launcherNpcUUID, targetNpcUUID)
    self.WrestleTarget = 0
    if targetNpcUUID ~= self._uuid then
        return
    end
    --延时移除角力镜头参数
    self._proxy:AddTimerTask(1.5,function()
        self._proxy:RemoveBuffByKindAndCount(targetNpcUUID,1052284,0)
    end)
    --XLog.Warning("角力成功，隐藏角力机制条")
    --self._proxy:HideMechanismBar(4)
    self.AxeWrestleInput = false
    --角力退出还原锁定配置
    self._proxy:SetHardLock(targetNpcUUID,self.LockTargetKeeper)
    --设置白龙不被裁切
    self._proxy:SetNpcDither(launcherNpcUUID,false)
    --角力退出开启碰撞
    self._proxy:ApplyMagic(self._uuid,self._uuid,105290,1) --开启碰撞
    --角力退出显示小飞机
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052381,1)
    self.LockTargetKeeper = 8001001
end
--endregion

--region 特殊保底用
function XCharR5Nanami1:OnEnterJumpWeaponHide() --进跳跃隐藏
    Base.OnEnterJumpWeaponHide(self._uuid)
    --XLog.Warning("跳跃隐藏")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052276,1)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,105200,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052277,1)

            self._proxy:ApplyMagic(self._uuid,self._uuid,105201,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052278,1)
        else
            self._proxy:ApplyMagic(self._uuid,self._uuid,105202,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052279,1)
        end
end

function XCharR5Nanami1:OnExitJumpWeaponShow() -- 出跳跃显示
    Base.OnExitJumpWeaponShow(self._uuid)
    --XLog.Warning("离开跳跃显示")
    self._proxy:RemoveBuffByKindAndCount(self._uuid,1052276,0)
    if self._proxy:CheckBuffByKind(self._uuid,105217) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105203,1)

        self._proxy:ApplyMagic(self._uuid,self._uuid,105204,1)
    else
        self._proxy:ApplyMagic(self._uuid,self._uuid,105205,1)
    end
end

function XCharR5Nanami1:ReconnectedCheckSkillGroup()
    if self._proxy:CheckBuffByKind(self._uuid,105218) then
        --XLog.Warning("重连技能组初始化")
        self._proxy:SetNpcAnimationLayer(self._uuid,1)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105210) --切换技能组3
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052359,1) --常驻fov增加
    elseif self._proxy:CheckBuffByKind(self._uuid,105217) then
        self._proxy:SetNpcAnimationLayer(self._uuid,0)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105205) --切换技能组3
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052360,1) --移除常驻fov增加
    end
end
--endregion
return XCharR5Nanami1