---@diagnostic disable: param-type-mismatch, unnecessary-if, undefined-field
---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")
--local XPlayerNpcContainer = require("Level/Common/XPlayerNpcContainer")
---共斗_霁梦丽芙_第一风格角色脚本
---@class XCharR5LivH : XRelinkCharBase
local XCharR5LivH = XDlcScriptManager.RegCharScript(1055, "XCharR5LivH", Base)
--核心改造2伤害ID

function XCharR5LivH:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    -- 约定：所有 SkillId/BuffId/MissileId 尽量在这里记录成变量，后续逻辑只引用变量名，避免回调里散落裸数字
    --记录技能ID
    self._attack4Id = 1055004
    self._attack4stId = 1055029
    self._attack5ChargeId = 1055005
    self._attack5ShootId = 1055006
    self._attack5ExChargeId = 1055025
    self._attack5ExShootId = 1055026
    self._core1Id = 1055020             -- core1 技能；释放后将 Attack 技能组切到 core2
    self._core2Id = 1055021
    self._whiteCombo4SkillIds = { 1055016, 1055017, 1055018, 1055019 }

    --记录BUFFID
    self._attack5ChargeBuff = 105501102
    self._attack5ChargeEffectBuff1 = 105501201
    self._attack5ChargeEffectBuff2 = 105501202
    self._normalBuff = 105501103        -- 普通阶段标记（用于技能组还原/表现）
    self._dodgeSuccessBuff = 105501106  -- 闪避成功时额外标记（与闪反/派生窗口相关）
    self._teamHealBuff = 105501027      -- skill3 帧事件触发的全队治疗
    -- 核心2：第二段伤害命中后，把“标记 Buff”层数转化为同等级“易伤 Buff”，并清空标记
    self._core2MarkBuff = 105501108
    self._core2VulnBuff = 105501109
    -- 核心技能充能判定：
    self._coreSkillReadyBuff = 105501104    -- 105501104：核心技能可使用标记（当前脚本里与强化阶段共用同一个 buff）
    self._coreSkillChargeAttrib = 49        -- 49号属性：核心技能充能（当前值==最大值视为充满）

    -- 种花/吃花：队友吃到我的治疗后，触发我自身回能
    self._flowerHealBuff = 105501006           -- 我对队友的治疗 buff（NpcCure 回调里的 magicId）
    self._flowerEnergyRecoverBuff = 105501303  -- 触发自身回能的 buff

    --记录子弹ID / 种花发射
    -- 花子弹模板（LaunchMissile 第4参）；发射表行 ID 见下方两组 trigger
    self._flowerMissileId = 105500705
    -- flowerTrigger1：4 发，发射 ID 105500705~708；flowerTrigger2：4 发，发射 ID 105500709~712
    self._flowerTrigger1LaunchIds = { 105500705, 105500706, 105500707, 105500708 }
    self._flowerTrigger2LaunchIds = { 105500709, 105500710, 105500711, 105500712 }
    self._flowerMissileList = {}

    -- 白球技能：white3Effect -> 发射 105501802，并记录 UUID 与位置
    --          white4Effect -> 在 105501802 记录的位置再发射 105501912，并销毁 105501802（按 UUID）
    self._white3LaunchId = 105501802
    self._white3MissileId = 105501802
    self._white4LaunchId = 105501912
    self._white4MissileId = 105501912
    self._white3MissileInfo = {} -- [missileUUID] = { pos = {x=,y=,z=} }
    -- linkEffect 帧事件：AddLink 从本体 WeaponCase1 挂点连到目标 HitCase 挂点（骨骼跟随）
    self._linkEffectFxName1 = "FxR5LifuTongyongEle021"
    self._linkEffectFxName2 = "FxR5LifuTongyongEle022"
    self._linkEffectFromJoint = "WeaponCase1"
    self._linkEffectToJoint = "HitCase"
    self._linkEffectLinkId = nil
    -- linkEffect：与连线同时打向焦点目标的一发子弹（发射表行与模板同号）
    self._linkEffectMissileLaunchId = 105502704
    self._linkEffectMissileId = 105502704
    self._skill1ExMissileId = 105502002
    self._skill1ExMissileList = {}
    -- atk5ExShoot：发射ID固定为 105500602；根据蓄力等级(0/1/2)切换不同模板子弹
    self._atk5ExShootLaunchId = 105500602
    self._atk5ExShootMissileLv0 = 105500602
    self._atk5ExShootMissileLv1 = 105500603
    self._atk5ExShootMissileLv2 = 105500604
    
    --记录伤害ID
    self._core2Damage1 = 105501025
    self._core2Damage2 = 105501026

    -- 技能组：对应配置表中 1055 的 skillGroup（105501~105509）
    self._skillGroups = {
        atk = 105501,       -- sgId = 1
        skill1 = 105502,    -- sgId = 2
        skill2 = 105503,    -- sgId = 3
        skill3 = 105504,    -- sgId = 4
        skill4 = 105505,    -- sgId = 5
        dash = 105506,      -- sgId = 6
        skill1Ex = 105507,  -- sgId = 7
        core1 = 105508,     -- sgId = 8
        core2 = 105509,     -- sgId = 9
    }

    -- 按键绑定初始化（将技能组挂到对应操作键上；后续阶段切换只需要替换 Ball1 即可）
    -- self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._skillGroups.atk)
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skillGroups.skill1)
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball2, self._skillGroups.skill2)
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball3, self._skillGroups.skill3)
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball4, self._skillGroups.skill4)
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Dodge, self._skillGroups.dash)
end

function XCharR5LivH:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess, self._uuid)               --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)             --注册伤害前事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) -- 注册帧事件内发送事件执行
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)                                           --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)                                  --注册技能释放后事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)                                       --注册退出技能事件
    self._proxy:RegisterEvent(EWorldEvent.MissileCreate)                                       --注册子弹创建事件
    self._proxy:RegisterEvent(EWorldEvent.MissileDead)                                         --注册子弹死亡事件
    --self._proxy:RegisterEvent(EWorldEvent.MechanismStop) --注册特殊机制条监听事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcChangeDamageBeforeCalc, self._uuid)
end

function XCharR5LivH:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if npcUUID ~= self._uuid then
        return
    end
end

-- 等效onskillend
function XCharR5LivH:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcExitActionEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    -- if skillId == self._attack5ChargeId then
    --     print("是否被打断", isAbort)
    --     local _, fightTarget = self._proxy:GetLockTarget()
    --     self._proxy:CastActionToTarget(self._uuid, self._attack5ShootId, fightTarget)
    --     -- self._proxy:CastAction(self._uuid, self._attack5ShootId)
    -- end
    print("isAbort", isAbort)
    if skillId == self._core2Id then
        print("技能结束，清空伤害记录表格")
        self._core2DamagedTargets = {}
        return
    end
end

-- 等效afterDamage
function XCharR5LivH:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType,
                                      realDamage, isCritical)
    if launcherId ~= self._uuid then
        return
    end
    -- 核心2第一段伤害命中后，把敌人ID存在表格里，第二段伤害必中
    if magicId == self._core2Damage1 then
        -- 确保表已经初始化（防止报错）
        self._core2DamagedTargets = self._core2DamagedTargets or {}

        -- 将目标 ID 作为键存入表中，赋值为 true
        self._core2DamagedTargets[targetId] = true

        print("记录受到 core2Damage1 伤害的目标 UUID:", targetId)
        return
    end

    if magicId == self._core2Damage2 then
        -- 核心2第二段伤害命中：把目标身上的“标记 Buff”层数(1~10)转成同等级“易伤 Buff”，并清空标记
        print("核心2第二段伤害命中")
        local stacks = self._proxy:GetBuffStacks(targetId, self._core2MarkBuff) or 0
        print("标记buff层数", stacks)
        if stacks > 0 then
            if stacks < 1 then
                stacks = 1
            elseif stacks > 10 then
                stacks = 10
            end

            -- 约定：易伤 buff 的“等级”直接使用标记层数，保证 1~10 一一对应
            self._proxy:ApplyMagic(self._uuid, targetId, self._core2VulnBuff, stacks)

            -- 清空目标身上的所有标记（按当前工程用法：RemoveBuff 传 buffId 进行全量移除）
            self._proxy:RemoveBuff(targetId, self._core2MarkBuff)
            print("清空标记buff")
        end
        return
    end
end

function XCharR5LivH:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    if launcher ~= self._uuid then
        return
    end

    -- 帧事件驱动阶段切换：由动作帧事件触发，统一走 Enter*Stage 做“buff + 技能组 + 子弹”同步
    if eventName == "changeToNormal" then
        self:EnterSkill1NormalStage()
        return
    end

    if eventName == "changeToEx" then
        self:EnterSkill1ExStage()
        return
    end

    if eventName == "atk4LongPressCheck" then
        if self._proxy:IsKeyHold(ENpcOperationKey.Attack) and self._proxy:GetSkillGroupLastHitId(self._uuid, self._skillGroups.atk) == self._AtkButtonCheck then
            print("同次按压")
            local target = self:GetLockTargetNpcUuid()
            if target == 0 then
                target = self._uuid
            end
            self._proxy:CastActionToTarget(self._uuid, self._attack5ShootId, target)
        end
        return
    end

    if eventName == "atk4ExLongPressCheck" then
        if self._proxy:IsKeyHold(ENpcOperationKey.Attack) and self._proxy:GetSkillGroupLastHitId(self._uuid, self._skillGroups.atk) == self._AtkButtonCheck then
            print("同次按压ex")
            local target = self:GetLockTargetNpcUuid()
            if target == 0 then
                target = self._uuid
            end
            self._proxy:CastActionToTarget(self._uuid, self._attack5ExChargeId, target)
        end
        return
    end

    if eventName == "atk5Loop" then
        local target = self:GetLockTargetNpcUuid()
        if target == 0 then
            target = self._uuid
        end
        local chargeBuff, chargeLevel = self._proxy:TryQueryBuffLevel(self._uuid, self._attack5ChargeBuff)
        local chargeLevel = self._proxy:GetBuffStacks(self._uuid, self._attack5ChargeBuff)
        self:AddChargeLevel(1)
        self._proxy:CastActionToTarget(self._uuid, self._attack5ChargeId, target)
        return
    end
    
    if eventName == "atk5LongPressCheck" then
        if not self._proxy:IsKeyHold(ENpcOperationKey.Attack) then
            local target = self:GetLockTargetNpcUuid()
            if target == 0 then
                target = self._uuid
            end
            self._proxy:CastActionToTarget(self._uuid, self._attack5ShootId, target)
            print("普攻蓄力版，不蓄力，直接发射")
            self:ClearChargeState()
            return
        end
    end

    if eventName == "atk5ExLongPressCheck" then
        if not self._proxy:IsKeyHold(ENpcOperationKey.Attack) then

            local target = self:GetLockTargetNpcUuid()
            if not target or target == 0 then
                target = self._uuid
            end
            print("114514")
            self._proxy:CastActionToTarget(self._uuid, self._attack5ExShootId, target)
            return
        end
    end

    -- atk5ExJumptoShoot：由动作帧事件驱动“跳转到发射技能”，复用已有的 self._attack5ExShootId（不走输入校验）
    -- 目标：默认取 GetLockTarget 对应 Npc；若无锁定则对自己释放，避免空目标导致释放失败
    if eventName == "atk5ExJumptoShoot" then
        local target = self:GetLockTargetNpcUuid()
        if not target or target == 0 then
            target = self._uuid
        end
        self._proxy:CastActionToTarget(self._uuid, self._attack5ExShootId, target)
        print("114514")
        return
    end

    -- atk5ExShoot：强化蓄力普攻发射子弹
    -- 约束：发射ID固定用 self._atk5ExShootLaunchId；子弹模板随蓄力等级变化(0/1/2)
    if eventName == "atk5ExShoot" then
        local level = self._chargeLevel or 0  -- self._chargeLevel 由 AddChargeLevel 维护；不存在则按 0 级处理
        if level < 0 then
            level = 0
        elseif level > 2 then
            level = 2
        end

        local missileId = self._atk5ExShootMissileLv0
        if level == 1 then
            missileId = self._atk5ExShootMissileLv1
        elseif level == 2 then
            missileId = self._atk5ExShootMissileLv2
        end

        -- 目标优先锁定目标；无锁定则对自己发射（避免空目标导致发射失败）
        local target = self:GetLockTargetNpcUuid()
        if not target or target == 0 then
            target = self._uuid
        end

        self._proxy:LaunchMissile(self._uuid, target, self._atk5ExShootLaunchId, missileId)
        -- 发射后清空蓄力层级与对应表现 Buff，避免下次进入动作时残留
        self:ClearChargeState()
        return
    end

    -- 种花：两组帧事件，各打 4 发花导弹（发射表行不同，模板统一 self._flowerMissileId）
    if eventName == "flowerTrigger1" then
        self:LaunchFlowerMissilesByLaunchIds(self._flowerTrigger1LaunchIds)
        return
    end

    if eventName == "flowerTrigger2" then
        self:LaunchFlowerMissilesByLaunchIds(self._flowerTrigger2LaunchIds)
        return
    end

    if eventName == "skill4Heal" then
        -- 对全队（存活玩家，含自己）施加治疗效果；死亡/非法单位跳过
        local teamList = self._proxy:GetPlayerNpcList()
        for _, uuid in ipairs(teamList) do
            if uuid ~= 0 and self._proxy:CheckNpc(uuid) and (not self._proxy:IsNpcDead(uuid)) then
                self._proxy:ApplyMagic(self._uuid, uuid, self._teamHealBuff, 1)
            end
        end
        return
    end

    if eventName == "white3Effect" then
        -- white3Effect：发射 105501802 子弹，并记录 UUID 与位置（用于 white4Effect 复位/跟随）
        -- 注意：这里不抽公共函数，按帧事件直接落地逻辑
        self._white3MissileInfo = self._white3MissileInfo or {}

        local casterPos = self._proxy:GetNpcPosition(self._uuid)
        -- white3 仍使用“对目标发射”路径：目标传自己，保持原本发射行为
        local suc, missileUuid = self._proxy:LaunchMissile(self._uuid, self._uuid, self._white3LaunchId, self._white3MissileId, 1)
        if suc and missileUuid then
            local ok, missilePos = self._proxy:TryGetMissilePositionByUUID(missileUuid)
            if ok and missilePos then
                self._white3MissileInfo[missileUuid] = { pos = missilePos }
            else
                self._white3MissileInfo[missileUuid] = { pos = casterPos }
            end
        end
        return
    end

    if eventName == "white4Effect" then
        -- white4Effect：在 white3 记录的位置发射 105501912，并销毁对应 105501802 子弹（按 UUID）
        if self._white3MissileInfo then
            for missileUuid, info in pairs(self._white3MissileInfo) do
                local pos = info and info.pos

                -- 如果缓存 pos 不存在，退回拉取当前子弹位置
                if not pos then
                    local ok, missilePos = self._proxy:TryGetMissilePositionByUUID(missileUuid)
                    if ok and missilePos then
                        pos = missilePos
                    end
                end

                if pos then
                    -- 按指定位置发射：在缓存的 white3 子弹位置，从 pos 到 pos
                    self._proxy:LaunchMissileFromPosToPos(self._uuid, self._white4LaunchId, self._white4MissileId, pos, pos, 1)
                end

                self._proxy:DestroyMissileByUUID(missileUuid)
                self._white3MissileInfo[missileUuid] = nil
            end
        end
        return
    end

    -- linkEffect：AddLink 连接自身 WeaponCase1 与目标 HitCase，updateAlways=true 随挂点更新
    if eventName == "linkEffect" then
        local target = self:GetLockTargetNpcUuid()
        if target == 0 or not self._proxy:CheckNpc(target) then
            return
        end
        -- if self._linkEffectLinkId and self._proxy:CheckLink(self._linkEffectLinkId) then
        --     self._proxy:RemoveLink(self._uuid, self._linkEffectLinkId)
        -- end
        self._linkEffectLinkId1 = self._proxy:AddLink(self._uuid, self._uuid, target, self._linkEffectFromJoint, self._linkEffectToJoint, self._linkEffectFxName1, true)
        self._linkEffectLinkId2 = self._proxy:AddLink(self._uuid, self._uuid, target, self._linkEffectFromJoint, self._linkEffectToJoint, self._linkEffectFxName2, true)
        -- 连线表现同时，对同一目标按 105502704 发射（发射ID与子弹模板均为 105502704）
        -- self._proxy:LaunchMissile(self._uuid, target, self._linkEffectMissileLaunchId, self._linkEffectMissileId, 1)
        return
    end

    if eventName == "core2Attack" then
        if not self._core2DamagedTargets then
            print("当前没有记录任何受击目标")
            return
        end

        -- 遍历记录表，处理每一个目标
        for recordTargetId, _ in pairs(self._core2DamagedTargets) do
            print("正在处理目标:", recordTargetId)
            self._proxy:ApplyMagic(self._uuid, recordTargetId, self._core2Damage2)
        end
        XCharR5LivH:ClearCore2DamagedTargets()
        return
    end

    if eventName == "atk5ExAbsorb1" then
        self:CleanupMissilesAndCharge()
        return
    end

    if eventName == "atk5ExCharge" then
        self:AddChargeLevel(1)
        return
    end

end

--基本等效onskillbegin
function XCharR5LivH:OnNpcCastActionAfterEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionAfterEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if LauncherId ~= self._uuid then
        return
    end

    -- core1 开始释放后：把 Attack 操作键的技能组换成 core2（便于接续核心第二段等）
    if SkillId == self._core1Id then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._skillGroups.core2)
        return
    end

    -- core2 开始释放后：Attack 还原为普攻技能组
    if SkillId == self._core2Id then
        self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._skillGroups.atk)
        return
    end

    -- 白球连段 4 连技能开始后：如果充能已满且还没“可使用标记”，就补标记
    if self._whiteCombo4SkillIds and self._whiteCombo4SkillIds[1] then
        for _, id in ipairs(self._whiteCombo4SkillIds) do
            if SkillId == id then
                local cur = self._proxy:GetNpcAttribValue(self._uuid, self._coreSkillChargeAttrib)
                local max = self._proxy:GetNpcAttribMaxValue(self._uuid, self._coreSkillChargeAttrib)
                if cur == max then
                    local readyStacks = self._proxy:GetBuffStacks(self._uuid, self._coreSkillReadyBuff) or 0
                    if readyStacks <= 0 then
                        self._proxy:ApplyMagic(self._uuid, self._uuid, self._coreSkillReadyBuff, 1)
                    end
                end
                break
            end
        end
    end
    if SkillId == self._attack5ShootId then
        -- print("发射子弹成功，清理所有蓄力等级与特效")
        self:ClearChargeState()
        return
    end
    if SkillId == self._attack5ChargeId then
        self:CleanupMissilesAndCharge()
    end
end

--基本等效onbeforeskillbegin
function XCharR5LivH:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    Base.OnNpcCastActionBeforeEvent(self, SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort) --基类的逻辑
    if LauncherId ~= self._uuid then
        return
    end
    if SkillId == self._attack4Id or SkillId == self._attack4stId then
        self._AtkButtonCheck = self._proxy:GetSkillGroupLastHitId(self._uuid, self._skillGroups.atk)
    end
end

-- 当子弹死亡/销毁时
function XCharR5LivH:OnMissileDeadEvent(MissileUUID)
    -- print("子弹移除了",MissileUUID)

    -- flower：吸花用的缓存清理
    if self._flowerMissileList and self._flowerMissileList[MissileUUID] then
        self._flowerMissileList[MissileUUID] = nil
        print("记录花子弹销毁, UUID:", MissileUUID)
    end

    -- white3：white4Effect 用到的缓存清理（避免白色子弹提前死亡导致白4找不到位置/缓存）
    if self._white3MissileInfo and self._white3MissileInfo[MissileUUID] then
        self._white3MissileInfo[MissileUUID] = nil
    end
end


-- 闪避成功后开启闪反窗口
function XCharR5LivH:OnNpcDodge(SourceUUID, AttackerUUID, Type, MissileTemplateId)
    Base.OnNpcDodge(self, SourceUUID, AttackerUUID, Type, MissileTemplateId)
    XLog.Warning("counter成功")
    if Type == 1 then
        XLog.Warning("闪避成功加buff")
        -- 仅在“成功闪避”时挂标记（用于后续派生/窗口判断）
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._dodgeSuccessBuff, 1)
    end
end

-- NpcCure：治疗结算事件（用于“种花/吃花”联动回能）
-- 当队友受到“我施加的治疗 magicId”时，给自己添加回能 buff（与种花/吃花资源循环相关）
function XCharR5LivH:OnNpcCureEvent(launcherId, targetId, magicId, kind, value, skillId)
    Base.OnNpcCureEvent(self, launcherId, targetId, magicId, kind, value, skillId)

    -- 只关心“治疗来源是我”的情况
    if launcherId ~= self._uuid then
        return
    end

    -- 目标必须在队伍列表里（teammateList）；吃花的目标允许是自己
    if not targetId or targetId == 0 then
        return
    end

    local inTeam = false
    local teamList = self._proxy:GetPlayerNpcList()
    for _, uuid in ipairs(teamList) do
        if uuid == targetId then
            inTeam = true
            break
        end
    end
    if not inTeam then
        return
    end

    -- 种花/吃花：只要“受疗者在队伍列表里”且 magicId 匹配，就触发我自身回能
    if magicId == self._flowerHealBuff then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self._flowerEnergyRecoverBuff, 1)
    end
end

-----------------自定义函数区-----------------

-- 当前锁定目标：GetLockTarget 返回 (锁定目标 UID, 所属 Npc 的 UUID)，技能/子弹目标用第二返回值
function XCharR5LivH:GetLockTargetNpcUuid()
    local _, actorUuid = self._proxy:GetLockTarget()
    if not actorUuid or actorUuid == 0 then
        return 0
    end
    return actorUuid
end

--- 按配置的一组发射 ID 连发多枚花导弹，并写入 self._flowerMissileList 供吸花/销毁逻辑使用
---@param launchIdList number[] 来自 ScriptInit 的 _flowerTrigger1LaunchIds / _flowerTrigger2LaunchIds
function XCharR5LivH:LaunchFlowerMissilesByLaunchIds(launchIdList)
    if not launchIdList then
        return
    end
    for _, launchId in ipairs(launchIdList) do
        local suc, uuid = self._proxy:LaunchMissile(self._uuid, self._uuid, launchId, self._flowerMissileId)
        if suc and uuid then
            self._flowerMissileList[uuid] = true
            print("记录花子弹生成, UUID:", uuid, "launchId:", launchId)
        end
    end
end

-- 普攻核心蓄力管理函数
-- @param count: 本次增加的层数
function XCharR5LivH:AddChargeLevel(count)
    -- 初始化层级
    self._chargeLevel = self._chargeLevel or 0

    -- 记录旧层级，用于后续判断是否需要更换特效 Buff
    local oldLevel = self._chargeLevel

    -- 更新层级，最高限制为 2
    self._chargeLevel = math.min(self._chargeLevel + count, 2)

    -- 如果层级没变（已经满了），就不重复执行 Buff 逻辑
    if oldLevel == self._chargeLevel and self._chargeLevel >= 2 then
        return
    end

    -- A. 处理基础蓄力 Buff (self._attack5ChargeBuff)
    -- 根据增加的 count，循环添加对应层数的 Buff
    for i = 1, count do
        -- 只有当前层级还没到 2 的时候才加，确保总数不超过 2
        -- 注意：这里假设 AddBuff 调用一次加一层
        self._proxy:AddBuff(self._uuid, self._attack5ChargeBuff)
    end

    -- 根据当前最新层级添加对应特效
    if self._chargeLevel == 1 then
        self._proxy:AddBuff(self._uuid, self._attack5ChargeEffectBuff1)
        print("蓄力等级更新: 1, 获得特效1")
    elseif self._chargeLevel == 2 then
        self._proxy:AddBuff(self._uuid, self._attack5ChargeEffectBuff2)
        print("蓄力等级更新: 2, 获得特效2")
    end
end

-- 普攻蓄力版用，吸花逻辑
function XCharR5LivH:CleanupMissilesAndCharge()
    if not self._flowerMissileList then return end

    local myPos = self._proxy:GetNpcPosition(self._uuid)
    if not myPos then return end

    -- 收集并按距离排序
    local missileData = {}
    for uuid, _ in pairs(self._flowerMissileList) do
        local success, mPos = self._proxy:TryGetMissilePositionByUUID(uuid)
        if success and mPos then
            local distSq = (mPos.x - myPos.x) ^ 2 + (mPos.y - myPos.y) ^ 2 + (mPos.z - myPos.z) ^ 2
            table.insert(missileData, { uuid = uuid, dist = distSq })
        end
    end

    local currentCount = #missileData
    if currentCount == 0 then return end

    table.sort(missileData, function(a, b) return a.dist < b.dist end)

    -- 执行逻辑
    if currentCount == 1 then
        -- 销毁 1 颗，加 1 层蓄力
        self:DoDestroyMissile(missileData[1].uuid)
        self:AddChargeLevel(1)
    else
        -- 销毁 2 颗（最近的），加 2 层蓄力
        for i = 1, 2 do
            self:DoDestroyMissile(missileData[i].uuid)
        end
        self:AddChargeLevel(2)
    end
end

-- 普攻蓄力版用，吸花逻辑
function XCharR5LivH:DoDestroyMissile(uuid)
    if uuid then
        self._proxy:DestroyMissileByUUID(uuid)
        self._flowerMissileList[uuid] = nil
    end
end

-- 专门负责重置所有蓄力相关的 变量、Buff 和 特效
function XCharR5LivH:ClearChargeState()
    print("执行蓄力状态重置，原等级为：", self._chargeLevel)

    -- 1. 重置逻辑计数变量
    self._chargeLevel = 0

    -- 2. 移除基础蓄力标记 Buff
    self._proxy:RemoveBuff(self._uuid, self._attack5ChargeBuff)

    -- 3. 移除所有蓄力等级特效 Buff
    self._proxy:RemoveBuff(self._uuid, self._attack5ChargeEffectBuff1)
    self._proxy:RemoveBuff(self._uuid, self._attack5ChargeEffectBuff2)
end

-- 核心2用，技能结束或造成伤害后，把记录伤害目标的表清空
function XCharR5LivH:ClearCore2DamagedTargets()
    -- 直接将表置空，释放之前的记录
    if self._core2DamagedTargets then
        for key, _ in pairs(self._core2DamagedTargets) do
            self._core2DamagedTargets[key] = nil
        end
    end
    print("已清空 core2Damage1 的受击目标记录")
end

-- 从 normal 阶段进入 ex 阶段：
-- 1) 给自己加 exBuff
-- 2) 把 Ball1 技能组切到 skill1Ex
-- 3) 生成一发 105502002 子弹并记录 UUID
function XCharR5LivH:EnterSkill1ExStage()
    -- 加强化状态 Buff
    -- 说明：如果该 buff 已由技能/状态机在别处添加，这里可不重复添加；若帧事件是唯一入口，则需要打开这一行
    -- self._proxy:ApplyMagic(self._uuid, self._uuid, self._exBuff, 1)

    -- 切换 Ball1 到 Ex 技能组
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skillGroups.skill1Ex)

    -- Ex 阶段：Attack 切到 core1，便于起核心第一段；后续由 core1/core2 释放回调切换 atk / core2
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._skillGroups.core1)

    -- 生成 105502002 子弹（用于 Ex 阶段的持续表现/判定），并记录 UUID 以便回到 normal 时清理
    -- local suc, missileUuid = self._proxy:LaunchMissile(self._uuid, self._uuid, self._skill1ExMissileId, self._skill1ExMissileId)
    -- if suc and missileUuid then
    --     self._skill1ExMissileList[missileUuid] = true
    -- end
end

-- 从 ex 阶段回到 normal 阶段：
-- 1) 给自己加 normalBuff
-- 2) 把 Ball1 技能组还原成 skill1
-- 3) 把之前生成的 105502002 子弹全部移除
function XCharR5LivH:EnterSkill1NormalStage()
    -- 加普通状态 Buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self._normalBuff, 1)

    -- 还原 Ball1 技能组
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Ball1, self._skillGroups.skill1)

    -- 离开 Ex：Attack 还原为普攻（避免仍挂在 core1/core2）
    self._proxy:SetSkillGroup(self._uuid, ENpcOperationKey.Attack, self._skillGroups.atk)

    -- 移除所有 105502002 子弹
    if self._skill1ExMissileList then
        for uuid, _ in pairs(self._skill1ExMissileList) do
            self._proxy:DestroyMissileByUUID(uuid)
            self._skill1ExMissileList[uuid] = nil
        end
    end
end

return XCharR5LivH
