---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")
local EGameplayTag = require("Enum/XGameplayTag")

---首席指挥官角色脚本
---@class XCharR5Bianka1 : XRelinkCharBase
local XCharR5Bianka1 = XDlcScriptManager.RegCharScript(1054, "XCharR5Bianka1", Base)

function XCharR5Bianka1:Init()
    Base.Init(self)
    self.IsLastDefenseOnRight = false
    --- 两种防御Action的Id表
    self._defenseActionId = {
        Left = 105419,
        Right = 105420
    }
    --- 上一次防御所用的ActionId
    self._lastDefenceActionId = self._defenseActionId.Right

    --耗血限制
    self.costLifeLimit = 0.2;
    --- 当前actionId
    self._curActionId = 0;

    self._curAttackHeal = 0;

    --- 角色action的Id表
    self._actions = {
        ---  三技能一段响指
        Skill31St = 105405,

        --强化普攻

        PowerAttack1 = 105406,

        PowerAttack2 = 105407,

        PowerAttack3 = 105408,

        PowerAttack4 = 105409,

        PowerAttack5 = 105410,

        --登龙剑    
        DragonSword = 105412,
        --- 前闪避
        DodgeForward = 105413,
        --- 2技能开始蓄力
        Skill2StartCharge = 105415,
        --- 2技能蓄力
        Skill2Charge = 105416,
        --  1技能1段    
        Skill11St = 105421,
        --  1技能2段 
        Skill12Nd = 105422,
        --  1技能3段 
        Skill13Rd = 105423,
        --- 2技能大回旋
        Skill2RoundSlash = 105424,
        --- 见切
        ForeSightSlash = 105425,
        --- 防御开始
        DefenseStart = 105427,
        --- 防御循环
        DefenseLoop = 105428,
        --- 防御循环回待机
        DefenseLoopToIdle = 105429,
    }

    --- 效果ID
    self._magics = {
        --- 剑舞状态标记
        BladeDanceStateMark = 10540001,
        --- 剑舞维持标记
        BladeDanceSustainMark = 10540003,
        --- 相杀相机位置偏移
        OffsetCameraPosEffect = 10542503,
        --- 相杀相机旋转偏移
        OffsetCameraRotEffect = 10542504,
        --- 相杀成功护盾值
        OffsetShield = 10542506,
        --- 防御标记
        DefenseMark = 10540006,
        --- 防御减伤
        DefenseDmgReduction = 10540020,
        --- 见切成功标记
        ForeSightSuccess = 10540022,
        --- 见切成功护盾值
        ForeSightShield = 10542505,
        --- 见切成功能量
        ForeSightEnergy = 10542507,
        --- 规避见切重复回能
        ForeSightBlockDupEnergy = 10542508,
        --- 进入角力相机位置偏移
        EnterWrestleCamPos = 10543003,
        --- 进入角力相机旋转偏移
        EnterWrestleCamRot = 10543005,
        --- 持有护盾常驻霸体
        ShieldSA = 10540025,
        --- 技能2格挡标记
        Skill2DefenseMark = 10540008,
        --- 技能2格挡FOV变动
        Skill2DefenseFOVChange = 10542410,
        --- 技能2规避重复添加GP能量
        Skill2DefenseBlockDupGuardPointEnergy = 10542411,
        --- 技能2GP能量
        Skill2DefenseGuardPointEnergy = 10542405,
        --- 闪避按下状态
        DodgeKeyDown = 10540018,
        --- 闪避抬起状态
        DodgeKeyUp = 10540019,
        --- 1技能变为1段
        SwitchToSkill1 = 10540017,
        --- 1技能变为2段
        SwitchToSkill2 = 10540015,
        --- 1技能变为3段
        SwitchToSkill3 = 10540016,
        --- 空能标记
        HasEnergyMark = 10540027,
        --- 剑舞连砍伤害1
        BladeDanceSlash3DmgOne = 10540804,
        --- 剑舞连砍伤害2
        BladeDanceSlash3DmgTwo = 10540805,
        --- 一技能耗血
        SelfDamageSkill1Magic = 10540033,
        --- 二技能耗血
        SelfDamageSkill2Magic = 10540034,
        --- 自回血占位magic
        SelfHealMagic = 10540035,
    }

    --- 效果移除ID
    self._removerMagics = {
        --- 移除防御标记
        [10540006] = 10540007,
        [10540020] = 10540021,
        [10540022] = 10540023,
        [10543003] = 10543004,
        [10543005] = 10543006,
        --- 移除技能2格挡标记
        [10540008] = 10540009,
        --- 移除持有护盾常驻霸体
        [10540025] = 10540026,
        --- 移除空能标记
        [10540027] = 10540028
    }

    --- 技能组ID
    self._skillGroupIds = {
        --- 普攻
        LightAttack = 1,
        --- 技能1-1
        LightSkill1_1 = 2,
        --- 技能1-2
        LightSkill1_2 = 22,
        --- 技能1-3
        LightSkill1_3 = 23,
        --- 技能2
        LightSkill2 = 3,
        --- 技能3
        LightSkill3 = 4,
        --- 登龙
        LightHelmBreaker = 13,
        --- 闪避/防御
        LightDodgeGuard = 5,
        --- 大招
        LightUltra = 6,
        --- 强化普攻
        LightExAttack = 7
    }

    --- 帧事件
    self._keyframeEvents = {
        QETChargeToQTEAtk = "Jump105435"
    }

    --- 子弹模板ID
    self._missileTemplateIds = {
        --- 技能2弹刀子弹
        Skill2ParryMissile = 10542405
    }

    --- 子弹发射ID
    self._missileLaunchIds = {
        --- 技能2弹刀子弹发射器
        Skill2ParryMissile = 10542405
    }

    --- 技能2弹刀子弹UUID
    self._skill2ParryMissileUUID = nil

    -- 技能组ID加前缀
    for k, v in pairs(self._skillGroupIds) do
        self._skillGroupIds[k] = 105400 + v
    end
end

function XCharR5Bianka1:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件
    -- 伤害修改事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcChangeDamageBeforeCalc, self._uuid)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleReversal)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestlePursuit)
    self._proxy:RegisterEvent(EWorldEvent.NpcChangeProtector)
end

function XCharR5Bianka1:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharR5Bianka1:Update(dt)
    Base.Update(self, dt)

    --检查闪避按键的按下与抬起状态，防御动作在松开后未自动回idle的保底方案
    if self._proxy:IsKeyDown(ENpcOperationKey.Dodge) then--闪避按键按下
        self:ApplyMagicToSelf(self._magics.DodgeKeyDown, 1)
    end

    if self._proxy:IsKeyUp(ENpcOperationKey.Dodge) then--闪避按键抬起
        self:ApplyMagicToSelf(self._magics.DodgeKeyUp, 1)
    end

    local curEnergy = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.CustomEnergyGroup1)
    if curEnergy > 0 and not self:HasBuffOnSelf(self._magics.HasEnergyMark) then
        self:ApplyMagicToSelf(self._magics.HasEnergyMark, 1)
    end
    if curEnergy <= 0 and self:HasBuffOnSelf(self._magics.HasEnergyMark) then
        self:RemoveBuffForSelf(self._magics.HasEnergyMark)
    end
end

--region 事件
function XCharR5Bianka1:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    Base.OnNpcDamageEvent(self, launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)

    if launcherId == self._uuid and targetId ~= self._uuid then
        self._proxy:ApplyMagic(self._uuid,targetId,10540031,1) --光比t易伤
    end

    if targetId ~= self._uuid then
        return
    end

    local curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid)

    -- 如果有格挡效果，则根据上一个格挡动作，播放与之相异的格挡动作（左 -> 右 -> 左 -> 右 ......）
    if self:HasBuffOnSelf(self._magics.DefenseMark) then
        if self._lastDefenceActionId == self._defenseActionId.Left then
            self._lastDefenceActionId = self._defenseActionId.Right
        else
            self._lastDefenceActionId = self._defenseActionId.Left
        end
        self:CastActionWithAbort(self._lastDefenceActionId)
    end

    -- 技能2格挡释放
    if self:HasBuffOnSelf(self._magics.Skill2DefenseMark) then
        self:CastActionWithAbortToTarget(self._actions.Skill2RoundSlash, curFocusTarget)
        self:ApplyMagicsToSelf({
            self._magics.Skill2DefenseFOVChange,
            self._magics.Skill2DefenseGuardPointEnergy,
            self._magics.Skill2DefenseBlockDupGuardPointEnergy
        }, 1)
    end
end

function XCharR5Bianka1:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if npcUUID ~= self._uuid then
        return
    end

    -- 进入剑舞状态
    if buffId == self._magics.BladeDanceStateMark then
        -- 普攻 替换为 强化普攻
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._skillGroupIds.LightExAttack)
        -- 3技能 替换为 登龙
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._skillGroupIds.LightHelmBreaker)
    end

    -- 进入防御状态
    if buffId == self._magics.DefenseMark then
        --防御时，检查自身是否有剑舞连击标记，若有则重新添加
        if self:HasBuffOnSelf(self._magics.BladeDanceSustainMark) then
            self:ApplyMagicToSelf(self._magics.BladeDanceSustainMark, 1)
        end
        -- 防御减伤
        self:ApplyMagicToSelf(self._magics.DefenseDmgReduction, 1)
    end

    -- 切换1技能至第2段
    if buffId == self._magics.SwitchToSkill2 then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skillGroupIds.LightSkill1_2)
    end

    -- 切换1技能至第3段
    if buffId == self._magics.SwitchToSkill3 then --切换技能组
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skillGroupIds.LightSkill1_3)
    end

    -- 切换1技能至第1段
    if buffId == self._magics.SwitchToSkill1 then --切换技能组
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skillGroupIds.LightSkill1_1)
    end

end

function XCharR5Bianka1:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcRemoveBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end

    -- 退出防御状态
    if buffId == self._magics.DefenseMark then
        -- 移除防御减伤
        self:RemoveBuffForSelf(self._magics.DefenseDmgReduction)
    end

    -- 退出剑舞状态
    if buffId == self._magics.BladeDanceStateMark then
        -- 普攻 替换为 常规普攻
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._skillGroupIds.LightAttack)
        -- 3技能 替换为 响指
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._skillGroupIds.LightSkill3)
    end
end

function XCharR5Bianka1:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then
        return
    end

    
    --直升机斩回血

    if SkillId == self._actions.PowerAttack3 or SkillId == self._actions.PowerAttack4 or SkillId == self._actions.PowerAttack5 then
        local curEnergy = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.CustomEnergyGroup1)
        if self._curAttackHeal == 0 then
            local count = curEnergy > 8 and (curEnergy // 8) + 1 or 1
            self._curAttackHeal = math.floor(self:GetLifeRelation(1) * 0.5 / count)
        end
        if curEnergy > 0 then 
            self._proxy:NpcCureRelinkByValue(self._uuid, self._uuid, self._curAttackHeal, self._magics.SelfHealMagic, 0)
        end
    end

     if SkillId == self._actions.DragonSword then
        self._curAttackHeal = 0
     end

    --一二技能百分比耗血
    local lifePercent = self:GetLifeRelation(0)
    if (SkillId == self._actions.Skill12Nd or SkillId == self._actions.Skill11St or SkillId == self._actions.Skill13Rd) and lifePercent > self.costLifeLimit then
        self:ApplyMagicToSelf(self._magics.SelfDamageSkill1Magic, 1)
    end

    if SkillId == self._actions.Skill2StartCharge and lifePercent > self.costLifeLimit then
        self:ApplyMagicToSelf(self._magics.SelfDamageSkill2Magic, 1)
    end

    -- 闪避和见切施加剑舞持续标记
    if SkillId == self._actions.DodgeForward or SkillId == self._actions.ForeSightSlash then
        if self:HasBuffOnSelf(self._magics.BladeDanceSustainMark) then
            self:ApplyMagicToSelf(self._magics.BladeDanceSustainMark, 1)
        end
    end
        --self:ApplyMagicToSelf(self._magics.BladeDanceSustainMark, 1)
        --self._proxy:NpcCureRelinkByValue(self._uuid, self._uuid, 1000 , self._magics.SelfHealMagic, 0)
end

function XCharR5Bianka1:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    -- 记录当前actionId
    self._curActionId = skillId

    -- 技能2开始，生成子弹
    if skillId == self._actions.Skill2StartCharge then
        local isLaunchSuccess, missileUUID = self._proxy:LaunchMissile(self._uuid, self._uuid, self._missileLaunchIds.Skill2ParryMissile, self._missileTemplateIds.Skill2ParryMissile, 1)
        if isLaunchSuccess then
           self._skill2ParryMissileUUID = missileUUID
        end
    end
end

function XCharR5Bianka1:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcExitActionEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    -- 取消记录当前actionId
    self._curActionId = 0

    -- 销毁技能2弹刀子弹
    if skillId == self._actions.Skill2Charge then
        if self._skill2ParryMissileUUID ~= nil then
            self._proxy:DestroyMissileByUUID(self._skill2ParryMissileUUID)
            self._skill2ParryMissileUUID = nil
        end
    end
end

function XCharR5Bianka1:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type, MissileTemplateId)
    if SourceUUID ~= self._uuid then
        return
    end

    -- 闪避成功时处于见切动作内
    if self._curActionId == self._actions.ForeSightSlash then
        -- 施加见切成功效果
        self:ApplyMagicsToSelf({
            self._magics.ForeSightSuccess,
            self._magics.ForeSightShield}, 1)
    end
end

function XCharR5Bianka1:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    Base.OnNpcSkillActionKeyframeSendEvent(self, launcher, eventName, skillActionId, keyFrameId, skillId)
    if launcher ~= self._uuid then
        return
    end

    local curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid)

    -- 技能2蓄力开始 -> 技能2蓄力
    if eventName == "Skill2XuliLoop" then
        self:CastActionWithAbort(self._actions.Skill2Charge)
    end

    -- 技能2蓄力 -> 技能2大回旋
    if eventName == "Skill2XuliEnd" then
        self:CastActionWithAbortToTarget(self._actions.Skill2RoundSlash, curFocusTarget)
    end

    -- 防御开始
    if eventName == "ShanbiXuliStart" then
        self:CastActionWithAbortToTarget(self._actions.DefenseStart, curFocusTarget)
    end

    if eventName == "ShanbiXuliLoop" then
        self:CastActionWithAbortToTarget(self._actions.DefenseLoop, curFocusTarget)
    end

    if eventName == "ReDeFense1" then  -- 播放格挡动作后，重新回到格挡姿态维持动作（在按住闪避键时）
        self._proxy:CastActionToTarget(self._uuid, 105428, curFocusTarget)
        self:CastActionWithAbortToTarget(self._actions.DefenseLoop, curFocusTarget)
    end

    if eventName == "Reidle" then -- 播放格挡动作后，回到idle动作（在抬起闪避键时）
        self._proxy:CastActionToTarget(self._uuid, 105429, curFocusTarget)
    end
end

function XCharR5Bianka1:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    Base.OnNpcCounterSuccess(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    if counterNpcUUID ~= self._uuid then
        return
    end

    local curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid)

    -- TODO: 临时根据当前动作来判断，实际需要子弹TemplateID
    if self._curActionId == self._actions.ForeSightSlash then
        self:ApplyMagicsToSelf({
            --[[self._magics.OffsetCameraPosEffect,
            self._magics.OffsetCameraRotEffect,]]
            self._magics.ForeSightSuccess,
            self._magics.OffsetShield}, 1)
    end

    if self._curActionId == self._actions.Skill2StartCharge or self._curActionId == self._actions.Skill2Charge then
        if self._skill2ParryMissileUUID ~= nil then
            self._proxy:DestroyMissileByUUID(self._skill2ParryMissileUUID)
            self._skill2ParryMissileUUID = nil

            -- 弹刀成功释放二段
            self:CastActionWithAbortToTarget(self._actions.Skill2RoundSlash, curFocusTarget)
            self:ApplyMagicsToSelf({
                self._magics.Skill2DefenseFOVChange,
                self._magics.Skill2DefenseGuardPointEnergy,
                self._magics.Skill2DefenseBlockDupGuardPointEnergy
            }, 1)
        end
    end
end

function XCharR5Bianka1:OnNpcWrestleReversal(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestleReversal(self, launcherNpcUUID, targetNpcUUID)
    if self._uuid ~= targetNpcUUID then
        return
    end
end

function XCharR5Bianka1:OnNpcWrestlePursuit(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestlePursuit(self, launcherNpcUUID, targetNpcUUID)
    if self._uuid ~= targetNpcUUID then
        return
    end
end

function XCharR5Bianka1:XNpcChangeProtectorArgs(LauncherId, TargetId, Value, TotalValue)
    Base.XNpcChangeProtectorArgs(self, LauncherId, TargetId, Value, TotalValue)
    if TargetId ~= self._uuid then
        return
    end

    -- 给盾且没霸体时，添加霸体
    if TotalValue > 0 and not self:HasBuffOnSelf(self._magics.ShieldSA) then
        self:ApplyMagicToSelf(self._magics.ShieldSA)
    end

    -- 没盾且有霸体时，移除霸体
    if TotalValue <= 0 and self:HasBuffOnSelf(self._magics.ShieldSA) then
        self:RemoveBuffForSelf(self._magics.ShieldSA)
    end
end

function XCharR5Bianka1:ChangeDamageBeforeCalc(eventArgs)
    Base.ChangeDamageBeforeCalc(self, eventArgs)


    if eventArgs.Launcher ~= eventArgs.Target and eventArgs.Target == self._uuid then --受击流程，伤害来源不是自己
    --按生命减伤
        local lifePercent = self:GetLifeRelation(0)
        local curPhysicalReductionP = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.PhysicalReductionP)
        local physicalReductionP = math.min( math.max( (37000 - 30000 * lifePercent) / 7, 1000), 4000) - curPhysicalReductionP
        --local physicalReductionP = lifePercent - self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.PhysicalReductionP)
        self._proxy:AddNpcAttribAdditive(self._uuid, ENpcAttrib.PhysicalReductionP, physicalReductionP, 0)
        --XLog.Error("[Relink比安卡]: " .. tostring(lifePercent))
    end

    -- 剑舞连斩加伤
    if eventArgs.Id == self._magics.BladeDanceSlash3DmgOne or eventArgs.Id == self._magics.BladeDanceSlash3DmgTwo then
        if self:HasBuffOnSelf(self._magics.HasEnergyMark) then
            local powerUpPhysicalPermyraid = eventArgs.PhysicalPermyriad * 1.5
            self._proxy:SetBeforeDamageMagicContext(
                    eventArgs.ContextId,
                    powerUpPhysicalPermyraid,
                    eventArgs.ElementPermyriad,
                    eventArgs.HackDamage,
                    eventArgs.HackPermyraid,
                    eventArgs.IsCrit)
        end
    end
end
--endregion

--region 重写
function XCharR5Bianka1:OnEnterJumpWeaponHide()
    -- 隐藏武器
    self:ApplyMagicToSelf(10540029, 1)
end

function XCharR5Bianka1:OnExitJumpWeaponShow()
    -- 显示武器
    self:ApplyMagicToSelf(10540030, 1)
end
--endregion

--region 常用函数封装
--- 施加一个效果，免写代理
--- @param launcherNpcUUID number @源UUID
--- @param targetNpcUUID number @目标UUID
--- @param magic number @效果ID
--- @param level number @效果等级
function XCharR5Bianka1:ApplyMagic(launcherNpcUUID, targetNpcUUID, magic, level)
    self._proxy:ApplyMagic(launcherNpcUUID, targetNpcUUID, magic, level)
end

--- 施加一个数组的效果
--- @param launcherNpcUUID number @源UUID
--- @param targetNpcUUID number @目标UUID
--- @param magics number[] @效果ID数组
--- @param level number @效果等级
function XCharR5Bianka1:ApplyMagics(launcherNpcUUID, targetNpcUUID, magics, level)
    for idx, magic in ipairs(magics) do
        self:ApplyMagic(launcherNpcUUID, targetNpcUUID, magic, level)
    end
end

--- 自己对自己施加一个效果
--- @param magic number @效果ID
--- @param level number @效果等级
function XCharR5Bianka1:ApplyMagicToSelf(magic, level)
    self:ApplyMagic(self._uuid, self._uuid, magic, level)
end

--- 自己对自己施加一个数组的效果
--- @param magics number[] @效果ID数组
--- @param level number @效果等级
function XCharR5Bianka1:ApplyMagicsToSelf(magics, level)
    self:ApplyMagics(self._uuid, self._uuid, magics, level)
end

--- 移除效果
--- @param launcherNpcUUID number @源UUID
--- @param targetNpcUUID number @目标UUID
--- @param magic number @效果ID
--- @return boolean @是否成功移除（如果失败，检查removerMagics配置）
function XCharR5Bianka1:RemoveBuff(launcherNpcUUID, targetNpcUUID, magic)
    local removerMagic = self._removerMagics[magic]
    if removerMagic == nil then
        return false
    end
    self:ApplyMagic(launcherNpcUUID, targetNpcUUID, removerMagic, 1)
    return true
end

--- 为自己移除效果
--- @param magic number @效果ID
--- @return boolean @是否成功移除（如果失败，检查removerMagics配置）
function XCharR5Bianka1:RemoveBuffForSelf(magic)
    return self:RemoveBuff(self._uuid, self._uuid, magic)
end

--- 检测自身是否持有效果
--- @param magicId number @效果ID
--- @return boolean @是否有效果
function XCharR5Bianka1:HasBuffOnSelf(magicId)
    return self._proxy:CheckBuffByKind(self._uuid, magicId)
end

--- 打断当前技能并立即释放技能
--- @param actionId number @action独特ID
function XCharR5Bianka1:CastActionWithAbort(actionId)
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastAction(self._uuid, actionId)
end

--- 打断当前技能，并立即向目标释放技能，带有目标有效性检查（不通过则采用无目标释放）
--- @param actionId number @action独特ID
--- @param target number @目标ID
function XCharR5Bianka1:CastActionWithAbortToTarget(actionId, target)
    self._proxy:AbortAction(self._uuid, true)

    -- 检测目标有效性，随后决定对目标释放，还是直接释放
    if target ~= nil and self._proxy:CheckNpc(target) then
        self._proxy:CastActionToTarget(self._uuid, actionId, target)
    else
       self._proxy:CastAction(self._uuid, actionId)
    end
end

function XCharR5Bianka1:GetLifeRelation(target)
    if target == nil then
    return 0
    end
    local curLife = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    local curMaxLife = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    if target == 0 then
        return  curLife / curMaxLife
    end
    if target == 1 then
        return  curMaxLife - curLife
    end
end
--endregion

--region 工具函数
--- 输出带有比安卡前缀标识的调试日志
function XCharR5Bianka1:LogDebug(text)
    XLog.Debug("[Relink比安卡]: " .. tostring(text))
end

--- 输出带有比安卡前缀标识的报错日志
function XCharR5Bianka1:LogError(text)
    XLog.Error("[Relink比安卡]: " .. tostring(text))
end

--- 输出带有比安卡前缀标识的警告日志
function XCharR5Bianka1:LogWarning(text)
    XLog.Warning("[Relink比安卡]: " .. tostring(text))
end
--endregion

return XCharR5Bianka1