---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")
local EGameplayTag = require("Enum/XGameplayTag")

---首席指挥官角色脚本
---@class XCharR5Bianka : XRelinkCharBase
local XCharR5Bianka = XDlcScriptManager.RegCharScript(1054, "XCharR5Bianka", Base)

function XCharR5Bianka:Init()
    Base.Init(self)
    self.GeDangRL = false
    self.SuoDingTarget = 0

    --- 当前actionId
    self._curActionId = 0;

    --- 角色action的Id表
    self._actions = {
        --- 见切
        ForeSightSlash = 105425
    }

    --- 效果ID
    self._magics = {
        --- 剑舞状态标记s
        BladeDanceStateMark = 10540001,
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
        --- 进入角力相机位置偏移
        EnterWrestleCamPos = 10543003,
        --- 进入角力相机旋转偏移
        EnterWrestleCamRot = 10543005,
    }

    --- 效果移除ID
    self._removerMagics = {
        --- 移除防御标记
        [10540006] = 10540007,
        [10540020] = 10540021,
        [10540022] = 10540023,
        [10543003] = 10543004,
        [10543005] = 10543006
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

    self._keyframeEvents = {

    }

    -- 技能组ID加前缀
    for k, v in pairs(self._skillGroupIds) do
        self._skillGroupIds[k] = 105400 + v
    end
end

function XCharR5Bianka:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleReversal)
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestlePursuit)
end

function XCharR5Bianka:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharR5Bianka:Update(dt)
    Base.Update(self, dt)
    --检查闪避按键的按下与抬起状态，防御动作在松开后未自动回idle的保底方案
    if self._proxy:IsKeyDown(ENpcOperationKey.Dodge) then--闪避按键按下
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10540018, 1)
    end

    if self._proxy:IsKeyUp(ENpcOperationKey.Dodge) then--闪避按键抬起
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10540019, 1)
    end

    -- 能量测试
    local curEnergy = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.CustomEnergyGroup1)
    local maxEnergy = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.CustomEnergyGroup1)

    --XLog.Debug(string.format("比安卡能量：[{%d} / {%d}], 是否在剑舞形态: ", curEnergy, maxEnergy) .. tostring(self._proxy:CheckBuffByKind(self._uuid, self._magics.BladeDanceStateMark)))
end

--region 事件
function XCharR5Bianka:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    Base.OnNpcDamageEvent(self, launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)

    if launcherId ~= targetId and targetId == self._uuid then
        self._curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid)
        if self._proxy:CheckBuffByKind(self._uuid, 10540006) then
             if self.GeDangRL ==  false then
                 self.GeDangRL =  true
                 self._proxy:AbortAction(self._uuid, true)
                 self._proxy:CastActionToTarget(self._uuid, 105420, self._curFocusTarget) --长按闪避受击触发弹刀释放右格挡
             else
                 self.GeDangRL = false
                 self._proxy:AbortAction(self._uuid, true)
                 self._proxy:CastActionToTarget(self._uuid, 105419, self._curFocusTarget) --长按闪避受击触发弹刀释放左格挡
             end
        end

        if self._proxy:CheckBuffByKind(self._uuid, 10540008)  then --2技能受击标记，buff持续期间受击则会打出反击技能。
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid, 105424, self._curFocusTarget)
        end
    end
end

function XCharR5Bianka:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
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
        if self._proxy:CheckBuffByKind(self._uuid, 10540003)  then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10540003, 1)
        end
        -- 防御减伤
        self:ApplyMagicToSelf(self._magics.DefenseDmgReduction, 1)
    end

    -- 切换1技能至第2段
    if buffId == 10540015 then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skillGroupIds.LightSkill1_2)
    end

    -- 切换1技能至第3段
    if buffId == 10540016 then --切换技能组
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skillGroupIds.LightSkill1_3)
    end

    -- 切换1技能至第1段
    if buffId == 10540017 then --切换技能组
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skillGroupIds.LightSkill1_1)
    end

end

function XCharR5Bianka:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
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

function XCharR5Bianka:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then
        return
    end

    if SkillId == 105413 then -- 闪避时，检查自身是否有剑舞连击标记，若有则重新添加
        if self._proxy:CheckBuffByKind(self._uuid, 10540003)  then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10540003, 1)
        end
    end
end

function XCharR5Bianka:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    -- 记录当前actionId
    self._curActionId = skillId;
end

function XCharR5Bianka:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcExitActionEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    -- 取消记录当前actionId
    self._curActionId = 0
end

function XCharR5Bianka:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
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

function XCharR5Bianka:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    Base.OnNpcSkillActionKeyframeSendEvent(self, launcher, eventName, skillActionId, keyFrameId, skillId)
    if launcher ~= self._uuid then
        return
    end

    if (eventName == "Skill2XuliLoop") then
        self._proxy:CastAction(self._uuid,105416) --2技能进入蓄力1阶段
    end

    if (eventName == "Skill2XuliEnd") then
        self._curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid)  -- 2技能蓄力完毕，释放大斩击
        self._proxy:CastActionToTarget(self._uuid, 105424, self._curFocusTarget)
    end

    if (eventName == "ShanbiXuliStart") then
        self._curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid) -- 长按闪避格挡姿态开始
        self._proxy:CastActionToTarget(self._uuid, 105427, self._curFocusTarget)
    end

    if (eventName == "ShanbiXuliLoop") then
        self._curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid) --长按闪避格挡姿态维持中
        self._proxy:CastActionToTarget(self._uuid, 105428, self._curFocusTarget)
    end

    if (eventName == "ReDeFense1") then  -- 播放格挡动作后，重新回到格挡姿态维持动作（在按住闪避键时）
        self._curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid)
        self._proxy:CastActionToTarget(self._uuid, 105428, self._curFocusTarget)
    end

    if (eventName == "Reidle") then -- 播放格挡动作后，回到idle动作（在抬起闪避键时）
        self._curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid)
        self._proxy:CastActionToTarget(self._uuid, 105429, self._curFocusTarget)
    end
end

function XCharR5Bianka:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    Base.OnNpcCounterSuccess(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    if counterNpcUUID ~= self._uuid then
        return
    end

    -- TODO: 临时根据当前动作来判断，实际需要子弹TemplateID
    if self._curActionId == self._actions.ForeSightSlash then
        self:ApplyMagicsToSelf({
            self._magics.OffsetCameraPosEffect,
            self._magics.OffsetCameraRotEffect,
            self._magics.ForeSightSuccess,
            self._magics.OffsetShield}, 1)
    end
end

function XCharR5Bianka:OnNpcWrestleReversal(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestleReversal(self, launcherNpcUUID, targetNpcUUID)
    if self._uuid ~= targetNpcUUID then
        return
    end

    -- 保底移除相机偏移
    self:RemoveBuffForSelf(self._magics.EnterWrestleCamPos)
    self:RemoveBuffForSelf(self._magics.EnterWrestleCamRot)
end

function XCharR5Bianka:OnNpcWrestlePursuit(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestlePursuit(self, launcherNpcUUID, targetNpcUUID)
    if self._uuid ~= targetNpcUUID then
        return
    end

    -- 保底移除相机偏移
    self:RemoveBuffForSelf(self._magics.EnterWrestleCamPos)
    self:RemoveBuffForSelf(self._magics.EnterWrestleCamRot)
end
--endregion

--region 常用函数封装
--- 施加一个效果，免写代理
--- @param launcherNpcUUID number @源UUID
--- @param targetNpcUUID number @目标UUID
--- @param magic number @效果ID
--- @param level number @效果等级
function XCharR5Bianka:ApplyMagic(launcherNpcUUID, targetNpcUUID, magic, level)
    self._proxy:ApplyMagic(launcherNpcUUID, targetNpcUUID, magic, level)
end

--- 施加一个数组的效果
--- @param launcherNpcUUID number @源UUID
--- @param targetNpcUUID number @目标UUID
--- @param magics number[] @效果ID数组
--- @param level number @效果等级
function XCharR5Bianka:ApplyMagics(launcherNpcUUID, targetNpcUUID, magics, level)
    for idx, magic in ipairs(magics) do
        self:ApplyMagic(launcherNpcUUID, targetNpcUUID, magic, level)
    end
end

--- 自己对自己施加一个效果
--- @param magic number @效果ID
--- @param level number @效果等级
function XCharR5Bianka:ApplyMagicToSelf(magic, level)
    self:ApplyMagic(self._uuid, self._uuid, magic, level)
end

--- 自己对自己施加一个数组的效果
--- @param magics number[] @效果ID数组
--- @param level number @效果等级
function XCharR5Bianka:ApplyMagicsToSelf(magics, level)
    self:ApplyMagics(self._uuid, self._uuid, magics, level)
end

--- 移除效果
--- @param launcherNpcUUID number @源UUID
--- @param targetNpcUUID number @目标UUID
--- @param magic number @效果ID
--- @return boolean @是否成功移除（如果失败，检查removerMagics配置）
function XCharR5Bianka:RemoveBuff(launcherNpcUUID, targetNpcUUID, magic)
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
function XCharR5Bianka:RemoveBuffForSelf(magic)
    return self:RemoveBuff(self._uuid, self._uuid, magic)
end
--endregion

--region 工具函数
--- 输出带有比安卡前缀标识的调试日志
function XCharR5Bianka:LogDebug(text)
    XLog.Debug("[Relink比安卡]: " .. tostring(text))
end

--- 输出带有比安卡前缀标识的报错日志
function XCharR5Bianka:LogError(text)
    XLog.Error("[Relink比安卡]: " .. tostring(text))
end

--- 输出带有比安卡前缀标识的警告日志
function XCharR5Bianka:LogWarning(text)
    XLog.Warning("[Relink比安卡]: " .. tostring(text))
end
--endregion

return XCharR5Bianka