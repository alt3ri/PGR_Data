---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")
local EGameplayTag = require("Enum/XGameplayTag")

---首席指挥官角色脚本
---@class XCharR5Bianka2 : XRelinkCharBase
local XCharR5Bianka2 = XDlcScriptManager.RegCharScript(1059, "XCharR5Bianka2", Base)

function XCharR5Bianka2:Init()
    Base.Init(self)

    --- 当前actionId
    self._curActionId = 0;

    self.ComboCd = 0;
    --- 当前能量
    self._curEnergy = 0;

    --- 角色action的Id表
    self._actions = {

        --普攻3
        Attack03 = 150903,
        --普攻
        Attack04 = 150904,
        --电钻见切
        DrillForeSightSlash = 105908,
        --- 见切
        ForeSightSlash = 105911,
        --- 乱舞
        WhipDance = 105912,
        --- 乱舞终结
        WhipDanceEnd = 105913,
        --技能2
        Skill02 = 150918,
    }

    --- 效果ID
    self._magics = {
        --- 鞭舞状态
        WhipDanceStateMark = 10590005,
        --- 常规状态
        NormalStateMark = 10590006,
        --- 乱舞连续标记
        WhipDanceSustainMark = 10590007,

        --减cd标记
        ComboCdMark = 10590009,

        --- 见切成功能量
        ForeSightEnergy = 10590010,

        --50能量乱舞终结额外伤害标记
        WhipDanceSustainFiftyEnergyMark = 10590011,

        --100能量乱舞终结额外伤害标记
        WhipDanceSustainHundredEnergyMark = 10590012,

        --- 规避见切重复回能
        ForeSightBlockDupEnergy = 10590013,

        --- 三技能进入cd
        Skill3EnterCd = 10590015,
    }

    --- 效果移除ID
    self._removerMagics = {
    }

    --- 技能组ID
    self._skillGroupIds = {
        --- 普攻
        DarkAttack = 1,
        --- 闪避
        DarkDodge = 2,
        --- 技能1
        DarkSkill1 = 3,
        --- 技能2
        DarkSkill2 = 4,
        --- 技能3
        DarkSkill3 = 5,
        --- 强化普攻
        ExAttack = 6,
        --- 大招
        DarkUltra = 7,
        --- 退出鞭舞
        Exit = 8,
    }

    --- 帧事件
    self._keyframeEvents = {
        DrillToForesightSlash = "Jump105908",
        WhipDanceLoop = "WhipDanceLoop",
        TryWhipDanceEnd = "TryWhipDanceEnd"
    }

    --- 子弹模板ID
    self._missileTemplateIds = {
    }

    --- 子弹发射ID
    self._missileLaunchIds = {
    }

    -- 技能组ID加前缀
    for k, v in pairs(self._skillGroupIds) do
        self._skillGroupIds[k] = 105900 + v
    end
end

function XCharR5Bianka2:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcChangeDamageBeforeCalc, self._uuid) --注册修改伤害事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件
end

function XCharR5Bianka2:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XCharR5Bianka2:Update(dt)
    Base.Update(self, dt)
end

--region 事件
function XCharR5Bianka2:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    Base.OnNpcDamageEvent(self, launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if targetId ~= self._uuid then
        return
    end
end

function XCharR5Bianka2:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if npcUUID ~= self._uuid then
        return
    end

    local curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid)

    if buffId == self._magics.WhipDanceStateMark then
        -- 普攻 替换为 强化普攻
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._skillGroupIds.ExAttack)
        -- 技能3 替换为 退出鞭舞
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._skillGroupIds.Exit)

        -- 能量消耗额外伤害
        self._curEnergy = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.CustomEnergyGroup1)
    end

    if buffId == self._magics.NormalStateMark then
        -- 强化普攻 替换为 普攻
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._skillGroupIds.DarkAttack)
        -- 退出鞭舞 替换为 技能3
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._skillGroupIds.DarkSkill3)

        self._proxy:ApplyMagic(self._uuid,self._uuid,self._magics.Skill3EnterCd,1)
        
        local costEnergy = self._curEnergy - self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.CustomEnergyGroup1)
        if costEnergy >= 100 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self._magics.WhipDanceSustainHundredEnergyMark,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,self._magics.WhipDanceSustainFiftyEnergyMark,1)
        elseif costEnergy >= 50 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self._magics.WhipDanceSustainFiftyEnergyMark,1)
        end

    end
    if buffId == self._magics.WhipDanceSustainMark then
        self:CastActionToTarget(self._actions.WhipDance, curFocusTarget, true)
    end
end

function XCharR5Bianka2:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcRemoveBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end
end

function XCharR5Bianka2:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then
        return
    end

    if self.ComboCd == 11 and SkillId == 105904 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self._magics.ComboCdMark,1)
    end
end

function XCharR5Bianka2:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end
    -- 记录当前actionId
    self._curActionId = skillId


    --2技能减cd
    if skillId == 105918 then 
        self.ComboCd = self.ComboCd + 1
    end

    if skillId == 105903 and self.ComboCd == 1 then 
        self.ComboCd = self.ComboCd + 10
    end

    if skillId ~= 105918 and skillId ~= 105903 then
        self.ComboCd = 0
    end

end


function XCharR5Bianka2:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcExitActionEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    -- 取消记录当前actionId
    self._curActionId = 0
end

function XCharR5Bianka2:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type, MissileTemplateId)
    if SourceUUID ~= self._uuid then
        return
    end

    -- 闪避成功时处于见切动作内
    if (self._curActionId == self._actions.ForeSightSlash or  self._curActionId == self._actions.DrillForeSightSlash) then
        -- 施加见切成功效果
         if not(self:HasBuffOnSelf(self._magics.ForeSightBlockDupEnergy)) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,self._magics.ForeSightEnergy,1)
        end
         self._proxy:ApplyMagic(self._uuid,self._uuid,self._magics.ForeSightBlockDupEnergy,1)
    end
end

function XCharR5Bianka2:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    Base.OnNpcSkillActionKeyframeSendEvent(self, launcher, eventName, skillActionId, keyFrameId, skillId)
    if launcher ~= self._uuid then
        return
    end

    local curFocusTarget = self._proxy:GetNpcFocusTarget(self._uuid)

    if eventName == self._keyframeEvents.DrillToForesightSlash then
        self:CastActionToTarget(self._actions.DrillForeSightSlash, curFocusTarget, true)
    end

    if eventName == self._keyframeEvents.TryWhipDanceEnd then
        local curEnergy = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.CustomEnergyGroup1)
        if curEnergy <= 4 then
            self:CastActionToTarget(self._actions.WhipDanceEnd, curFocusTarget, true)
        end
    end
end

function XCharR5Bianka2:BeforeDamageCalc(eventArgs)
    Base.BeforeDamageCalc(self,eventArgs)
end


--endregion

--region 常用函数封装
--- 施加一个效果，免写代理
--- @param launcherNpcUUID number @源UUID
--- @param targetNpcUUID number @目标UUID
--- @param magic number @效果ID
--- @param level number @效果等级
function XCharR5Bianka2:ApplyMagic(launcherNpcUUID, targetNpcUUID, magic, level)
    self._proxy:ApplyMagic(launcherNpcUUID, targetNpcUUID, magic, level)
end

--- 施加一个数组的效果
--- @param launcherNpcUUID number @源UUID
--- @param targetNpcUUID number @目标UUID
--- @param magics number[] @效果ID数组
--- @param level number @效果等级
function XCharR5Bianka2:ApplyMagics(launcherNpcUUID, targetNpcUUID, magics, level)
    for idx, magic in ipairs(magics) do
        self:ApplyMagic(launcherNpcUUID, targetNpcUUID, magic, level)
    end
end

--- 自己对自己施加一个效果
--- @param magic number @效果ID
--- @param level number @效果等级
function XCharR5Bianka2:ApplyMagicToSelf(magic, level)
    self:ApplyMagic(self._uuid, self._uuid, magic, level)
end

--- 自己对自己施加一个数组的效果
--- @param magics number[] @效果ID数组
--- @param level number @效果等级
function XCharR5Bianka2:ApplyMagicsToSelf(magics, level)
    self:ApplyMagics(self._uuid, self._uuid, magics, level)
end

--- 移除效果
--- @param launcherNpcUUID number @源UUID
--- @param targetNpcUUID number @目标UUID
--- @param magic number @效果ID
--- @return boolean @是否成功移除（如果失败，检查removerMagics配置）
function XCharR5Bianka2:RemoveBuff(launcherNpcUUID, targetNpcUUID, magic)
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
function XCharR5Bianka2:RemoveBuffForSelf(magic)
    return self:RemoveBuff(self._uuid, self._uuid, magic)
end

--- 检测自身是否持有效果
--- @param magicId number @效果ID
--- @return boolean @是否有效果
function XCharR5Bianka2:HasBuffOnSelf(magicId)
    return self._proxy:CheckBuffByKind(self._uuid, magicId)
end

--- 打断当前技能并立即释放技能
--- @param actionId number @action独特ID
function XCharR5Bianka2:CastActionWithAbort(actionId)
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastAction(self._uuid, actionId)
end

--- 打断当前技能，并立即向目标释放技能，带有目标有效性检查（不通过则采用无目标释放）
--- @param actionId number @action独特ID
--- @param target number @目标ID
function XCharR5Bianka2:CastActionToTarget(actionId, target, isAbort)
    if isAbort then
        self._proxy:AbortAction(self._uuid, true)
    end

    -- 检测目标有效性，随后决定对目标释放，还是直接释放
    if target ~= nil and self._proxy:CheckNpc(target) then
        self._proxy:CastActionToTarget(self._uuid, actionId, target)
    else
       self._proxy:CastAction(self._uuid, actionId)
    end
end
--endregion

--region 工具函数
--- 输出带有比安卡前缀标识的调试日志
function XCharR5Bianka2:LogDebug(text)
    XLog.Debug("[Relink比安卡]: " .. tostring(text))
end

--- 输出带有比安卡前缀标识的报错日志
function XCharR5Bianka2:LogError(text)
    XLog.Error("[Relink比安卡]: " .. tostring(text))
end

--- 输出带有比安卡前缀标识的警告日志
function XCharR5Bianka2:LogWarning(text)
    XLog.Warning("[Relink比安卡]: " .. tostring(text))
end
--endregion

--region 重写
function XCharR5Bianka2:OnEnterJumpWeaponHide()
    -- 隐藏武器
    self:ApplyMagicToSelf(10540029, 1)
end

function XCharR5Bianka2:OnExitJumpWeaponShow()
    -- 显示武器
    self:ApplyMagicToSelf(10540030, 1)
end
--endregion

return XCharR5Bianka2