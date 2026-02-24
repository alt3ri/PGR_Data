---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")


---首席指挥官角色脚本
---@class XChar1057 : XRelinkCharBase
local XCharR5Nanami2 = XDlcScriptManager.RegCharScript(1057, "XChar1057", Base)

function XCharR5Nanami2:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    ---- 技能计时器
    self._skillTimer = 0
    ---- 角力象限镜头用
    self._WristleCameraAngle = 0
    ---- 极限技1
    self._LimitSkill1 = 105768
    ---- 极限技2
    self._LimitSkill2 = 105787
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
    ----声明自定义属性1旧值
    self.CustomEnergyGroup1Old = 0
    ----声明自定义属性2旧值
    self.CustomEnergyGroup2Old = 0
    ----超解系数倍率修正
    self.OverReleaseDamageModifyCoe = 0.001
    ----超解值计数
    self.CustomPower2 = 0
    ----存个角力响应对象
    self.WrestleTarget = 0
    --XLog.Warning("现在是1057")

    ----黑板值处理
    ----存超解系数到黑板
    self:RegBB(1057001)
    self:SetBBFloat(1057001,0.001)
    ----存超解值到黑板
    self:RegBB(1057002)
    self:SetBBInt(1057002,self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup2))

    ----重连部分效果初始化保底
    ----技能组初始化
    self:ReconnectedCheckSkillGroup()
end

----region 黑板值同步封装用，省两个值
function XCharR5Nanami2:RegBB(key)
    self._proxy:RegisterBBSync(1, self._uuid, key)
end

function XCharR5Nanami2:SetBBInt(key,value)
    self._proxy:SetBBInt(1, self._uuid, key, value)
end

function XCharR5Nanami2:SetBBFloat(key,value)
    self._proxy:SetBBFloat(1,self._uuid,key,value)
end

function XCharR5Nanami2:TryGetBBInt(key)
    return self._proxy:TryGetBBInt(1, self._uuid, key)
end

function XCharR5Nanami2:TryGetBBFloat(key)
    return self._proxy:TryGetBBFloat(1, self._uuid, key)
end
----endregion

function XCharR5Nanami2:InitEventCallBackRegister()
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
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter) --注册怪物破韧监听
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakAfter) --注册怪物break监听
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcChangeDamageBeforeCalc, self._uuid)
end

---@param dt number @ delta time
function XCharR5Nanami2:Update(dt)
    Base.Update(self, dt)

    --self:TestInputLogic()
    self:CheckInputDuringAxeWrestle()
    self:EnergyBarChangeColorCheck()
    self:EnergySwitch()
    self:CheckMoveAddParticle()
    --self:AxeHoldAttackEnhance()
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
function XCharR5Nanami2:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharR5Nanami2:Terminate()
    Base.Terminate(self)
end

function XCharR5Nanami2:OnNpcSkillActionKeyframeSendEvent(launcher,eventName,skillActionId,keyFrameId,skillId)
    Base.OnNpcSkillActionKeyframeSendEvent(self,launcher,eventName,skillActionId,keyFrameId,skillId)
    --XLog.Warning("收到了自己发送的技能帧事件")
    --XLog.Warning(eventName)
    if eventName == "AddCoreEnergyL1" then
        --XLog.Warning("跑逻辑")
        if self._proxy:CheckBuffByKind(self._uuid,1052821) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052819,1)
        else
            self._proxy:ApplyMagic(self._uuid,self._uuid,1057016,1)
        end
    end

    if eventName == "AddCoreEnergyL2" then
        --XLog.Warning("跑逻辑")
        if self._proxy:CheckBuffByKind(self._uuid,1052821) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052819,2)
        else
            self._proxy:ApplyMagic(self._uuid,self._uuid,1057016,2)
        end
    end

    if eventName == "AddCoreEnergyL3" then
        --XLog.Warning("跑逻辑")
        if self._proxy:CheckBuffByKind(self._uuid,1052821) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052819,3)
        else
            self._proxy:ApplyMagic(self._uuid,self._uuid,1057016,3)
        end
    end

    if eventName == "AddCoreEnergy1L1" then
        --XLog.Warning("跑逻辑")
        if self._proxy:CheckBuffByKind(self._uuid,1052821) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052820,1)
        else
            self._proxy:ApplyMagic(self._uuid,self._uuid,1057017,1)
        end
    end

    if eventName == "CheckCoreEnergy1" then
        local CurEnergyValue = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup2)
        if CurEnergyValue == 900 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1057024,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,1057023,1)
        elseif CurEnergyValue >= 600 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1057023,1)
        end
        --XLog.Warning("跑逻辑")
    end

    if eventName == "SupportPortal" then
        self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("支援移动后进入回击流程")
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105250,0,5)
        else
            self._proxy:CastActionEx(self._uuid,105251,0,5)
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

function XCharR5Nanami2:XNpcChangeProtectorArgs(LauncherId, TargetId, Value, TotalValue)
    Base.XNpcChangeProtectorArgs(self,LauncherId, TargetId, Value, TotalValue)
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
function XCharR5Nanami2:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
    Base.OnNpcDodge(self,SourceUUID, AttackerUUID, Type, MissileTemplateId)
    if (Type == 1) then
        --XLog.Warning("极限闪避成功:")
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1057025, 1)
    end
end

function XCharR5Nanami2:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
    --XLog.Warning("怪物破韧时,超解值增加")
    if self._proxy:CheckBuffByKind(self._uuid,1052821) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052820,3)
    else
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057017,3)
    end

end

function XCharR5Nanami2:OnNpcODBreakAfter(targetUUID)
    --XLog.Warning("怪物break时，超解值增加")
    if self._proxy:CheckBuffByKind(self._uuid,1052821) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052820,3)
    else
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057017,3)
    end

end

function XCharR5Nanami2:ChangeDamageBeforeCalc(eventArgs)
    Base.ChangeDamageBeforeCalc( self, eventArgs)
    self._uuid = self._proxy:GetSelfNpcId()
    ----超解伤害修正
    if eventArgs.Id == 1057201 then
        --XLog.Warning("修正前："..eventArgs.PhysicalPermyraid)
        --XLog.Warning("能量点："..self.CustomPower2)
        local hasOverReleaseDamageModifyCoe,OverReleaseDamageModifyCoe = self:TryGetBBFloat(1057001)
        local hasCustomPower2,CustomPower2 = self:TryGetBBInt(1057002)
        local FinalDMGRate = math.floor(eventArgs.PhysicalPermyraid *(1+(CustomPower2 * OverReleaseDamageModifyCoe)))
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyraid, eventArgs.HackDamage, eventArgs.HackPermyraid, eventArgs.isCrit)
        --XLog.Warning("修正后："..FinalDMGRate)
    end
end
function XCharR5Nanami2:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if npcUUID ~= self._uuid then
        return
    end
    if buffId == 105217 then
        self._proxy:SetNpcAnimationLayer(self._uuid,0)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105705) --切换技能组3
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105703) --还原技能组1
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105704) --还原技能组2
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052360,1) --移除常驻fov增加
    elseif buffId == 105218 then
        self._proxy:SetNpcAnimationLayer(self._uuid,1)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105710) --切换技能组3
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105713) --切换技能组为龙车1
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105715) --切换技能组为斧红球
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052359,1) --常驻fov增加
    end
    if buffId == 105219 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105709)
    end
    if buffId == 1057001 then
        --XLog.Warning("红球派生")
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105711)
    end
    if buffId == 1057003 then
        --XLog.Warning("斧红球派生")
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105716)
    end
    if buffId == 1057005 then
        --XLog.Warning("龙车派生")
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105714)
    end

end

function XCharR5Nanami2:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcRemoveBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end
    if buffId == 105219 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105703)
    end
    if buffId == 1057001 then
        --XLog.Warning("退出红球派生")
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105704)
    end
    if buffId == 1057003 then
        --XLog.Warning("退出斧红球派生")
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105715)
    end
    if buffId == 1057005 then
        --XLog.Warning("退出龙车派生")
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105713)
    end
end

function XCharR5Nanami2:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    self:SkillCVCast(skillId)

    if skillId == self._LimitSkill1 or skillId == self._LimitSkill2 then
        self._proxy:SetTeamWorkSkillNpcRemainUseCount(self._uuid,0)
    end

    if skillId == 105719 then
        --self.CustomPower2 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup2)
        self._proxy:SetBBInt(1, self._uuid, 1057002, self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup2)) --记录峰值
        --XLog.Warning("技能进入时能量点"..self.CustomPower2)
    end

    if skillId == 105721 or skillId == 105722 then
        --XLog.Warning("大招期间不被裁切")
        self._proxy:SetNpcDither(self._uuid,false)
    end

    if skillId == 105713 then
        local Bufflevel = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1)/25
        --XLog.Warning("根据锋锐添加攻击加成效果")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057021,Bufflevel,1)
    end

    if skillId == 105714 then
        --XLog.Warning("移除锋锐添加攻击加成效果")
        self._proxy:RemoveBuffByKindAndCount(self._uuid,1057021,0)
    end

    --角力相关技能进入
    if skillId == 105244 then
        --XLog.Warning("角力僵持发生")
        --self:WrestleEnterCamera()--角力发生镜头
        self:WrestleEnterCameraNew()--角力发生新镜头
    end
    if skillId == 105245 then
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
        --self:SupportBlinkCamera()
    end
    if skillId == 105252 then
        --XLog.Warning("终结角色响应")
        --self:SupportBlinkCamera()
        self:UltraBlinkCamera()
    end

    if skillId == 105259 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052136,1) --模拟扰动震屏
    end
    if skillId == 105248 then
        local RandomInt = self._proxy:Random(1,3)
        if RandomInt == 1 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052216,1)--加速1.2
        elseif RandomInt == 2 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052217,1)--加速1.3
        else
            --XLog.Warning("原速")
        end
    end
    if skillId == 105269 then
        local RandomInt = self._proxy:Random(1,4)
        if RandomInt == 1 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052218,1)--减速0.8
        elseif RandomInt == 2 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052219,1)--减速0.85
        elseif RandomInt == 3 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052220,1)--减速0.7
        else
            --XLog.Warning("原速2")
        end
    end
    if skillId == 105258 then
        self:WrestleEnterCameraNew()
        --XLog.Warning("角力僵持发生，斧")
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
        --XLog.Warning("测试瞬移流程镜头")
        self:SupportBlinkCamera()
    end
    if skillId == 105276 then
        -- XLog.Warning("测试瞬移流程镜头")
        self:SupportBlinkCamera()
    end

    self._skillTimer = 0
end

function XCharR5Nanami2:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end
    if skillId == 105715 or skillId == 105716 or skillId == 105717 or skillId == 105718 then
        --XLog.Warning("斧攻击退出增加标记")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057007,1,1)
    end

    if skillId == 105726 then
        --XLog.Warning("闪避反击退出处理隐藏")
        self._proxy:ApplyMagic(self._uuid,self._uuid,105203,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105204,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105202,1)
    end

    if skillId == 105721 or skillId == 105722 then
        --XLog.Warning("裁切还原")
        self._proxy:SetNpcDither(self._uuid,true)
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

function XCharR5Nanami2:SkillCVCast(skillId)
    --cv语音播放
    --剑盾大招
    if skillId == 105721 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052500,1)
    end
    --盾斧大招
    if skillId == 105722 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052501,1)
    end
    --超解
    if skillId == 105719 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052507,1)
    end
    --龙车起始（仅1057）
    if skillId == 105728 or skillId == 105776  then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052504,1)
    end
    --龙车结束（仅1057）
    if skillId == 105730 or skillId == 105778  then
        local index = math.random(1, 2)
        local magicid = 1052511
        if index == 2 then
            magicid = 1052512
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicid,1)
    end
    --切盾斧随机语音
    if skillId == 105713  then
        local index = math.random(1, 2)
        local magicid = 1052503
        if index == 2 then
            magicid = 1052505
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicid,1)
    end
    --切剑盾随机语音
    if skillId == 105714  then
        local index = math.random(1, 2)
        local magicid = 1052502
        if index == 2 then
            magicid = 1052512
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicid,1)
    end
    --普攻语音
    if skillId == 105701 or skillId == 105715 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052508,1)
    end
    --剑盾普攻4随机语音
    if skillId == 105704  then
        local index = math.random(1, 2)
        local magicid = 1052511
        if index == 2 then
            magicid = 1052512
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicid,1)
    end
    --盾斧普攻3概率语音
    if skillId == 105717  then
        local index = math.random(1, 2)
        if index == 2 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052511,1)
        end
    end
    --盾斧普攻4概率语音
    if skillId == 105718  then
        local index = math.random(1, 2)
        if index == 2 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052512,1)
        end
    end
end

--region 按键测试逻辑
function XCharR5Nanami2:TestInputLogic()
    if self._proxy:IsKeyDown(ENpcOperationKey.Ball4) then
        --测试技能释放
        local testskill = 105731
        XLog.Warning("放技能看效果:"..testskill)
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastAction(self._uuid,testskill)
        --self._proxy:CastActionEx(self._uuid,testskill,0,5)
        --测试技能释放
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball5) then
        --self._proxy:SetPlayerButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._uuid,false)
        --self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105211)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057111,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057112,1)
        XLog.Warning("测试能量添加")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball6) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057018,1)
        XLog.Warning("测试添加镜头效果缓冲")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball7) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052348,1)
        XLog.Warning("破韧")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball8) then
        XLog.Warning("怪物给予自己伤害")
        local npclist = self._proxy:GetNpcList()
        for _, npcuuid in apairs(npclist) do
            if npcuuid ~= self._uuid and not self._proxy:IsPlayerNpc(npcuuid) then
                XLog.Warning("怪物目标"..npcuuid)
                self._proxy:ApplyMagic(npcuuid,self._uuid,1052002,1)
            end
            end
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball9) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057020,1)
        XLog.Warning("测试添加镜头效果缓冲")
    end
end
--endregion


--region 自动连招内容
function XCharR5Nanami2:SkillAtuoCombo()
    --[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105248) and self._skillTimer >= 0.8 then --剑盾角力攻击1完成时回到僵持循环的内容
        --XLog.Debug(self._skillTimer)
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
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105253,0,5)
        else
            self._proxy:CastActionEx(self._uuid,105254,0,5)
        end
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105276) and self._skillTimer >= 0.9 then
        self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("斧终结移动后攻击流程")
        if self._proxy:CheckBuffByKind(self._uuid,105218) then
            self._proxy:CastActionEx(self._uuid,105253,0,5)
        else
            self._proxy:CastActionEx(self._uuid,105254,0,5)
        end
    end
end


--endregion

--region 角力相关表现镜头
function XCharR5Nanami2:WrestleEnterCamera() --剑盾角力进入
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

function XCharR5Nanami2:WrestleLoopingCamera() --剑盾角力持续中
    if not self._proxy:CheckBuffByKind(self._uuid,1052165) then --排除重复进入导致的镜头效果问题
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052165,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052166,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052167,1)
        --self._proxy:ApplyMagic(self._uuid,self._uuid,1052136,1) --模拟扰动震屏

    end
end

function XCharR5Nanami2:WrestleEndCamera() --剑盾角力成功
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052168,1)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052169,1)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052170,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052172,1)
end

function XCharR5Nanami2:WrestleEnterCameraNew() --角力进入新
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

function XCharR5Nanami2:WrestleFailCameraNew() --角力失败退出新
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052325,1)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052326,1)
end

function XCharR5Nanami2:WrestleSuccessCameraNew() --角力成功退出新
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052338,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052168,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052169,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052170,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052172,1)

end

--endregion

--region 镜头处理相关
function XCharR5Nanami2:SupportBlinkCamera() --支援位移镜头
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052341,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052342,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052343,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052344,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052345,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052346,1)
end

function XCharR5Nanami2:UltraBlinkCamera() --终结位移镜头
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052390,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052391,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052392,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052393,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052394,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052395,1)
end
--endregion

--region Update执行相关函数

function XCharR5Nanami2:CheckInputDuringAxeWrestle()
    if self.WrestleTarget == self._uuid then
        if  self.AxeWrestleInput == true and self._proxy:IsKeyDown(ENpcOperationKey.RelinkQte) then
            if self._WrestleTimer >= 0.4 then
                --XLog.Warning("斧前顶镜头震动")
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

function XCharR5Nanami2:CheckMoveAddParticle()
    if self._proxy:CheckNpcFullActionState(self._uuid,ENpcAction.Move,-1) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105209,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105210,1)
    elseif not  self._proxy:CheckNpcFullActionState(self._uuid,ENpcAction.Jump,-1) then
        self._proxy:RemoveBuffByKindAndCount(self._uuid,105209,0)
        self._proxy:RemoveBuffByKindAndCount(self._uuid,105210,0)
    end
end

function XCharR5Nanami2:AxeHoldAttackEnhance()
    local Attackhold,Holdtime = self._proxy:IsKeyHold(ENpcOperationKey.Attack)
    local ChecktimingA = self._proxy:CheckActionTiming(self._uuid,16)
    local ChecktimingB = self._proxy:CheckActionTiming(self._uuid,17)
    local ChecktimingC = self._proxy:CheckActionTiming(self._uuid,18)
    local AttackUp = self._proxy:IsKeyUp(ENpcOperationKey.Attack)
    if Attackhold and (ChecktimingA or ChecktimingB or ChecktimingC)  then
        --XLog.Warning("测试命中slomo")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057107,1)
    end
    if AttackUp  and (ChecktimingA  or ChecktimingB or ChecktimingC)  then
        --XLog.Warning("测试抬起恢复")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057108,1)
    end
end

function XCharR5Nanami2:EnergyBarChangeColorCheck()
    if self.CustomEnergyGroup2Old ~= self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup2) then
        self.CustomEnergyGroup2Old = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup2)
    end
    if self.CustomEnergyGroup2Old >= 300 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057018,1)
        --XLog.Warning("处理超解值红字显示")
    else
        self._proxy:ApplyMagic(self._uuid,self._uuid,1057019,1)
        --XLog.Warning("移除超解值红字显示")
    end
end

function XCharR5Nanami2:EnergySwitch()
    local EnergyChangeValue = 0
    if self.CustomEnergyGroup1Old ~= self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) then
        EnergyChangeValue = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) - self.CustomEnergyGroup1Old
        if EnergyChangeValue > 0 then
            --XLog.Warning("锋锐增长")
        elseif EnergyChangeValue < 0  then
            --local _,holdtime  = self._proxy:IsKeyHold(ENpcOperationKey.Attack)
            --XLog.Warning("锋锐消耗")
            if self._proxy:CheckBuffByKind(self._uuid,1052821) then
                self._proxy:ApplyMagic(self._uuid,self._uuid,1052820,1)
            else
                self._proxy:ApplyMagic(self._uuid,self._uuid,1057017,1)
            end
        end
        self.CustomEnergyGroup1Old = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1)
    end
end

--endregion

--region 防御弹刀相关逻辑
function XCharR5Nanami2:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    Base.OnNpcCounterSuccess(self,triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    if self._proxy:CheckNpcCurrentAction(self._uuid, 105206) or self._proxy:CheckNpcCurrentAction(self._uuid, 105224)
            or self._proxy:CheckNpcCurrentAction(self._uuid,105235) or self._proxy:CheckNpcCurrentAction(self._uuid,105236) then
        self._proxy:AbortAction(self._uuid, true)
        if self._proxy:CheckBuffByKind(self._uuid, 105217) then
            self._proxy:CastActionEx(self._uuid,105240,0.26,3.83) --剑盾受击触发弹刀释放精确格挡
        elseif self._proxy:CheckBuffByKind(self._uuid, 105218) then
            self._proxy:CastActionEx(self._uuid,105243,0,2) --斧受击触发弹刀释放精确格挡

        end
    end
end

--endregion

--region 角力监听节点(处理部分角力相关的保底内容)
function XCharR5Nanami2:OnNpcWrestleStart(launcherNpcUUID, targetNpcUUID, succeed)
    Base.OnNpcWrestleStart(self,launcherNpcUUID, targetNpcUUID, succeed)
    self.WrestleTarget = targetNpcUUID
    if targetNpcUUID ~= self._uuid then
        return
    end
    --使用旧有镜头设置
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052284,1)
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

function XCharR5Nanami2:OnNpcWrestlePursuit(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestlePursuit(self,launcherNpcUUID, targetNpcUUID)
    --XLog.Warning("角力失败")
    self.WrestleTarget = 0
    if targetNpcUUID ~= self._uuid then
        return
    end
    --延时移除角力镜头参数
    self._proxy:AddTimerTask(0.5,function()
        self._proxy:RemoveBuffByKindAndCount(targetNpcUUID,1052284,0)
    end)
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

function XCharR5Nanami2:OnNpcWrestleReversal(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestleReversal(self,launcherNpcUUID, targetNpcUUID)
    --XLog.Warning("角力成功")
    self.WrestleTarget = 0
    if targetNpcUUID ~= self._uuid then
        return
    end
    --延时移除角力镜头参数
    self._proxy:AddTimerTask(1.5,function()
        self._proxy:RemoveBuffByKindAndCount(targetNpcUUID,1052284,0)
    end)
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
function XCharR5Nanami2:OnEnterJumpWeaponHide() --进跳跃隐藏
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

function XCharR5Nanami2:OnExitJumpWeaponShow() -- 出跳跃显示
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

function XCharR5Nanami2:ReconnectedCheckSkillGroup()
    if self._proxy:CheckBuffByKind(self._uuid,105218) then
        --XLog.Warning("重连技能组初始化..105218")
        self._proxy:SetNpcAnimationLayer(self._uuid,1)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105710) --切换技能组3
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105713) --切换技能组为龙车1
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105715) --切换技能组为斧红球
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052359,1) --常驻fov增加
    elseif self._proxy:CheckBuffByKind(self._uuid,105217) then
        --XLog.Warning("重连技能组初始化..105217")
        self._proxy:SetNpcAnimationLayer(self._uuid,0)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105705) --切换技能组3
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105703) --还原技能组1
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105704) --还原技能组2
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052360,1) --移除常驻fov增加
    end
end
--endregion
return XCharR5Nanami2