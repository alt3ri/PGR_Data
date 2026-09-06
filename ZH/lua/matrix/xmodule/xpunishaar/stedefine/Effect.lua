local STEEnum = require("STEVM/STEEnum")
local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
local Selector = require("XModule/XPunishaar/STEDefine/Selector")
local STEHelper = require("STEVM/STEHelper")

local Effect = {}

--region 攻击伤害落地延时（#75）

-- 延时帧数缓存（模块级，常量；首次排程时懒算，免每攻击读 ClientConfig）
local _AttackLandDelayFrames

--- 取攻击伤害落地延时（逻辑帧数）。delayMs 来源 ClientConfig BattleEffectDuration（飞弹飞行时长 = 伤害落地延时）；
--- **配置值单位秒**（非毫秒），需 ×1000 转毫秒后算帧 #75 单位修正；
--- delayFrames = math.floor(delayMs / MsPerLogicFrame)，常数不随倍速变（二倍速改 tick 频率不改常数）。
--- 配置未填/≤0 时兜底 DefaultBattleEffectDurationMs。供 AttackTarget 排程 + CheckBattleEnd death gate 共用。
---@return number
function Effect.GetAttackLandDelayFrames()
    if _AttackLandDelayFrames then
        return _AttackLandDelayFrames
    end
    -- 配置值单位秒，转毫秒算帧（原当毫秒算致 math.floor(0.5/50)=0 立即 land）#75 单位修正
    local durSec = XMVCA.XPunishaar:GetClientNumberByKey(STECustomEnum.BattleEffectDurationKey, 1)
    local durMs
    if not durSec or durSec <= 0 then
        durMs = STECustomEnum.DefaultBattleEffectDurationMs  -- 500ms 兜底
    else
        durMs = durSec * 1000  -- 秒→毫秒
    end
    _AttackLandDelayFrames = math.floor(durMs / STECustomEnum.MsPerLogicFrame)
    return _AttackLandDelayFrames
end

--endregion

--region 内部Effect，用于封装、复用，不暴露给策划

--- 计算一段攻击的伤害值（纯读，不写黑板）；供 _ReadDamageSource 复用。
---@param vm STEVM.VM
---@param damageType number STECustomEnum.ConfigDamageType.*
---@param value number
---@return number atk 计算结果（0 表示无效 damageType 或值为零）
function Effect._ComputeAtk(vm, damageType, value)
    if damageType == STECustomEnum.ConfigDamageType.Percent then
        -- 自身攻击力乘固定倍率
        local entityId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
        local atk = vm:Read(entityId, STECustomEnum.FieldNameType.ATK)
        return atk * value
    elseif damageType == STECustomEnum.ConfigDamageType.Alpha then
        -- 自身攻击力乘alpha
        local entityId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
        local atk = vm:Read(entityId, STECustomEnum.FieldNameType.ATK)
        -- 获取自身的alpha值
        local alpha = vm:Read(entityId, STECustomEnum.FieldNameType.Alpha)
        return atk * alpha
    elseif damageType == STECustomEnum.ConfigDamageType.Const then
        -- 基于固定值，直接将值设置回去
        return value
    elseif damageType == STECustomEnum.ConfigDamageType.EnemyCurHP then
        local selectResult = Selector.GetEnemy(vm)
        -- 兼容可能的多选，这里只针对顺位第一个敌人
        local entityId
        if type(selectResult) == "table" then
            entityId = selectResult[1]
        else
            entityId = selectResult
        end
        if not entityId then
            return 0
        end  -- Selector 返回空（无敌人），防御 vm:Read(nil) #M1
        -- 获取当前生命值，手动约束不超过上限
        local hpMax = vm:Read(entityId, STECustomEnum.FieldNameType.HPMax)
        local curHp = vm:Read(entityId, STECustomEnum.FieldNameType.HP)
        return math.min(curHp, hpMax) * value
    elseif damageType == STECustomEnum.ConfigDamageType.EnemyHPMax then
        local selectResult = Selector.GetEnemy(vm)
        -- 兼容可能的多选，这里只针对顺位第一个敌人
        local entityId
        if type(selectResult) == "table" then
            entityId = selectResult[1]
        else
            entityId = selectResult
        end
        if not entityId then
            return 0
        end  -- Selector 返回空（无敌人），防御 vm:Read(nil) #M1
        -- 获取生命最大值
        local hpMax = vm:Read(entityId, STECustomEnum.FieldNameType.HPMax)
        return hpMax * value
    elseif damageType == STECustomEnum.ConfigDamageType.PlayerCurHP then
        local selectResult = Selector.GetPlayer(vm)
        -- 兼容可能的多选，这里只针对顺位第一个目标
        local entityId
        if type(selectResult) == "table" then
            entityId = selectResult[1]
        else
            entityId = selectResult
        end
        if not entityId then
            return 0
        end  -- Selector 返回空（无敌人），防御 vm:Read(nil) #M1
        -- 获取当前生命值，手动约束不超过上限
        local hpMax = vm:Read(entityId, STECustomEnum.FieldNameType.HPMax)
        local curHp = vm:Read(entityId, STECustomEnum.FieldNameType.HP)
        return math.min(curHp, hpMax) * value
    elseif damageType == STECustomEnum.ConfigDamageType.PlayerHPMax then
        local selectResult = Selector.GetPlayer(vm)
        -- 兼容可能的多选，这里只针对顺位第一个目标
        local entityId
        if type(selectResult) == "table" then
            entityId = selectResult[1]
        else
            entityId = selectResult
        end
        if not entityId then
            return 0
        end  -- Selector 返回空（无敌人），防御 vm:Read(nil) #M1
        -- 获取生命最大值
        local hpMax = vm:Read(entityId, STECustomEnum.FieldNameType.HPMax)
        return hpMax * value
    end
    
    return 0
end

--- 计算一段攻击的伤害值, 将结果存入黑板中，键名约定为"ATK"
--- 单段取整约定：_ComputeAtk 内部运算数（atk/alpha/value/curHp/hpMax）保持浮点原值参与运算，
---   仅在存黑板前对计算结果 math.floor（"攻击发出前"取整，单段整数）。下游 atkTotal=atk×times 整数，
---   HP/HPMax 配置整数 + 扣减项整数 → HP 全程整数（消除浮点漂移 + 死亡判定临界）；显示层不变仍 floor。
---   :73 飘字 floor(atkTotal/times) 在本约定下整除 no-op，保留作防御。
---@param vm STEVM.VM
function Effect._ReadDamageSource(vm, damageType, value)
    vm:SetToBlackBoard(STECustomEnum.BlackBoardKeys.ATK, math.floor(Effect._ComputeAtk(vm, damageType, value)))
end

--- 实例化一个buff实体（经派生 env 的对象池：命中复用空壳，池空新建；注册在 AcquireBuff 内完成一次）
--- targetEntityId/targetFieldNameEnum 可为 nil（纯 Ex 驱动 buff：不带 modifier，效果靠 buff 表 Ex 字段）
---@param vm STEVM.VM
function Effect._InitBuffEntity(vm, uid, buffId, ownEntityId, targetEntityId, targetFieldNameEnum)
    ---@type XPunishaarSTEEnv
    local env = vm:GetEnv()

    env:AcquireBuff(uid, buffId, ownEntityId, targetEntityId, targetFieldNameEnum)

    -- 建时置 Active（编排层控状态机；Init 态留给"建好但延迟生效"的将来场景）
    vm:Store(uid, STECustomEnum.FieldNameType.State, STEEnum.ValChangeType.Set, STECustomEnum.BuffState.Active)

    -- Ex 运行态置未初始化哨兵 -1：TickAllBuffs 首次处理时据 buff 表 ExFirstImmediate/ExEffectCD 设真正初值
    -- （effect 函数拿不到 control/logicFrame，故 Ex 初始化延迟到有 control 的 TickAllBuffs 做）
    vm:Store(uid, STECustomEnum.FieldNameType.ExTickCD, STEEnum.ValChangeType.Set, -1)
    vm:Store(uid, STECustomEnum.FieldNameType.ExDoneTimes, STEEnum.ValChangeType.Set, 0)

    -- 添加到全局列表中方便遍历
    local handler = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BuffEntityIds)

    vm:PropAppend(handler, uid)
end

--- 查找已存在的同 (buffId, ownEntityId, targetEntityId, targetFieldNameEnum) 的 buff
--- 覆盖判定用：四要素全同视为"同一个 buff"。找到返回其 uid，无则 nil
---@param vm STEVM.VM
function Effect._FindSameBuff(vm, buffId, ownEntityId, targetEntityId, targetFieldNameEnum)
    local buffList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BuffEntityIds)
    local len = vm:PropLen(buffList)
    for i = 1, len do
        local uid = vm:PropGet(buffList, i)
        if vm:Read(uid, STECustomEnum.FieldNameType.BuffId) == buffId
                and vm:Read(uid, STECustomEnum.FieldNameType.OwnEntityId) == ownEntityId
                and vm:Read(uid, STECustomEnum.FieldNameType.TargetEntityId) == targetEntityId
                and vm:Read(uid, STECustomEnum.FieldNameType.TargetFieldNameEnum) == targetFieldNameEnum then
            return uid
        end
    end
    return nil
end

--- 销毁单个 buff：撤临时修正 + 摘全局索引 + 销毁实体
--- 覆盖(立即终止旧buff)与回收(RecycleBuffs 处理 PreEnd)共用；不检查状态，调用方决定何时销毁
---@param vm STEVM.VM
function Effect._DestroyBuff(vm, uid)
    -- 1. 撤临时修正（sourceId == uid）
    local target = vm:Read(uid, STECustomEnum.FieldNameType.TargetEntityId)
    local fieldEnum = vm:Read(uid, STECustomEnum.FieldNameType.TargetFieldNameEnum)
    local fieldName = STECustomEnum.FieldNameEnum[fieldEnum]

    if target and fieldName then
        vm:RemoveModifier(target, fieldName, uid)
    end

    -- 销毁前若 Layer≠0，发 DotBuffLayerChanged 让表现层重刷 buff 图标列表（撤掉该 buff 的图标）。
    -- 必须在 RemoveScope（销毁实体/字段）前读 Layer+buffId；vm:Emit 帧末 drain 派发，不阻塞销毁。
    local layer = vm:Read(uid, STECustomEnum.FieldNameType.Layer) or 0
    if layer ~= 0 then
        vm:Emit(STECustomEnum.EventEnum.DotBuffLayerChanged)
        XLog.Debug(string.format("Buff [uid%s] 销毁：Layer=%s，发 DotBuffLayerChanged",
                tostring(uid), tostring(layer)))
    end

    -- 2. 从全局索引摘除（按值删）
    local buffList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BuffEntityIds)
    vm:PropRemoveValue(buffList, uid)

    -- 3. 销毁实体
    vm:GetEnv():RemoveScope(uid)

    XLog.Debug(string.format("Buff [uid%s] 销毁：撤销对 %s.%s 的修正", tostring(uid), tostring(target), tostring(fieldName)))
end

--- 按被击实体 id 发对应 HP 变更事件(仅 Player/Enemy;其它实体无对应枚举,静默)
---@param vm STEVM.VM
function Effect._EmitHpChanged(vm, targetId)
    if targetId == STECustomEnum.GlobalEntityIds.Player then
        vm:Emit(STECustomEnum.EventEnum.PlayerHPChanged)
    elseif targetId == STECustomEnum.GlobalEntityIds.Enemy then
        vm:Emit(STECustomEnum.EventEnum.EnemyHPChanged)
    end
end

--- 按被击实体 id 发对应护盾变更事件(仅 Player/Enemy;其它实体无对应枚举,静默)
---@param vm STEVM.VM
function Effect._EmitShieldChanged(vm, targetId)
    if targetId == STECustomEnum.GlobalEntityIds.Player then
        vm:Emit(STECustomEnum.EventEnum.PlayerShieldChanged)
    elseif targetId == STECustomEnum.GlobalEntityIds.Enemy then
        vm:Emit(STECustomEnum.EventEnum.EnemyShieldChanged)
    end
end
--endregion

--region 公开到配置表中的Effect

--- 单目标私有（单/多分支收敛至此，不临时 table 整合，零 GC）#72
function Effect._ModifyOne(vm, target, fieldName, op, rightVal)
    local before
    if XMain.IsEditorDebug then
        before = vm:Read(target, fieldName)
    end
    vm:Store(target, fieldName, op, rightVal)
    if XMain.IsEditorDebug then
        local after = vm:Read(target, fieldName)
        XLog.Debug(string.format("[Effect] ModifyNumberField uid=%s field=%s op=%s rightVal=%s %s→%s",
                tostring(target), tostring(fieldName), tostring(op), tostring(rightVal),
                tostring(before), tostring(after)))
    end
end

--- 针对某个值进行修正
---@param vm STEVM.VM
function Effect.ModifyNumberField(vm, entityIds, targetFieldEnum, op, rightVal)
    -- 将字段从枚举转换成key
    local fieldName = STECustomEnum.FieldNameEnum[targetFieldEnum]
    if string.IsNilOrEmpty(fieldName) then
        vm:Error("指定字段枚举不存在：" .. tostring(targetFieldEnum))
        return
    end
    if not entityIds then
        return
    end
    -- 单/多分支收敛到 _ModifyOne（零 GC，不临时 table 整合）#72
    if type(entityIds) == "table" then
        for _, target in ipairs(entityIds) do
            Effect._ModifyOne(vm, target, fieldName, op, rightVal)
        end
    else
        Effect._ModifyOne(vm, entityIds, fieldName, op, rightVal)
    end
end

--- 单目标私有（单/多分支收敛至此，零 GC）#72
function Effect._TempModifyOne(vm, target, targetFieldEnum, fieldName, op, rightVal, buffId, ownCardId)
    -- 覆盖：存在四要素全同的旧 buff → 原地复用同一实体与 uid（不销毁重建）
    local oldUid = Effect._FindSameBuff(vm, buffId, ownCardId, target, targetFieldEnum)
    if oldUid then
        XLog.Debug(string.format("Buff 覆盖：原地刷新 [uid%s]（buffId%s own%s target%s field%s）",
                tostring(oldUid), tostring(buffId), tostring(ownCardId), tostring(target), tostring(targetFieldEnum)))
        vm:RemoveModifier(target, fieldName, oldUid)
        vm:AddModifier(target, fieldName, op, rightVal, oldUid)
        vm:Store(oldUid, STECustomEnum.FieldNameType.LifeTimes, STEEnum.ValChangeType.Set, 0)
        vm:Store(oldUid, STECustomEnum.FieldNameType.State, STEEnum.ValChangeType.Set, STECustomEnum.BuffState.Active)
        -- Ex 运行态复位（对齐新建路径 _InitBuffEntity：覆盖=原地刷新重置，Ex 节奏从头计，勿留旧 buff 倒计时余量/已释放次数）审查条目5
        vm:Store(oldUid, STECustomEnum.FieldNameType.ExTickCD, STEEnum.ValChangeType.Set, -1)
        vm:Store(oldUid, STECustomEnum.FieldNameType.ExDoneTimes, STEEnum.ValChangeType.Set, 0)
    else
        local uid = vm:GetEnv():GetNewUniqueNumber()
        vm:AddModifier(target, fieldName, op, rightVal, uid)
        Effect._InitBuffEntity(vm, uid, buffId, ownCardId, target, targetFieldEnum)
    end

    -- buff 修正卡牌 ATK/CD 时记一帧快照供 UI 显示：buff 同帧加成+清除，UI 帧末读时修正已清（RecycleBuffs 在 Drain 前），
    -- 快照跨一帧由 ResetGlobalTickData 清，UI 帧末读快照显 up 一瞬、下帧清回 normal。finalVal=0 亦有效（如 CD 改 0），快照无值返 nil。#buff修正快照
    if fieldName == STECustomEnum.FieldNameType.ATK or fieldName == STECustomEnum.FieldNameType.TickCDMax then
        if vm:HasTag(target, STECustomEnum.EntityTags.Card) then
            local snapshotField = fieldName == STECustomEnum.FieldNameType.ATK
                and STECustomEnum.FieldNameType.TickAtkSnapshot
                or STECustomEnum.FieldNameType.TickCdMaxSnapshot
            local snapshotDict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, snapshotField)
            local finalVal = vm:Read(target, fieldName)
            if snapshotDict and finalVal ~= nil then
                vm:PropSet(snapshotDict, target, finalVal)
            end
        end
    end
end

--- 临时修正某个值
--- 覆盖规则：同 (buffId, ownCardId, target, targetFieldEnum) 的 buff 视为同一个，
---   施加新的前先立即终止旧的（撤旧 modifier + 销毁旧实体），不叠加。
---@param vm STEVM.VM
function Effect.TempModifyNumberField(vm, entityIds, targetFieldEnum, op, rightVal, buffId)
    local ownCardId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
    local fieldName = STECustomEnum.FieldNameEnum[targetFieldEnum]
    if string.IsNilOrEmpty(fieldName) then
        vm:Error("指定字段枚举不存在：" .. tostring(targetFieldEnum))
        return
    end
    if not entityIds then
        return
    end
    -- 单/多分支收敛到 _TempModifyOne（零 GC）#72
    if type(entityIds) == "table" then
        for _, target in ipairs(entityIds) do
            Effect._TempModifyOne(vm, target, targetFieldEnum, fieldName, op, rightVal, buffId, ownCardId)
        end
    else
        Effect._TempModifyOne(vm, entityIds, targetFieldEnum, fieldName, op, rightVal, buffId, ownCardId)
    end
end

--- 立即落地单目标伤害（AttackTarget notDelayEnum 非0 / isNotDelayAttack=true 路径）。
--- acquire+Init+Execute+Return，副作用同 TickScheduledDamages per-ins（dict 登记+Store HP/护盾+Emit+飘字缓冲），
---   但在当前事务内 land（回滚同撤，比延迟路径更原子）。
--- landTick Execute 不读（仅时间轮 bucketing 用），传 env:GetTick() 占位。
---@param vm STEVM.VM
---@param env XPunishaarSTEEnv
---@param target number 目标 entityId
---@param owner number 攻击者 entityId（TickDamageDealtDict 登记键）
---@param atk number 总伤害（已×attackTimes）
---@param atkType number
---@param attackTimes number 段数
function Effect._LandDamageNow(vm, env, target, owner, atk, atkType, attackTimes)
    local damageDict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickDamageDealtDict)
    local ins = env:AcquireInstruction()
    ins:Init(target, owner, atk, atkType, attackTimes, env:GetTick())
    ins:Execute(vm, damageDict)
    env:ReturnInstruction(ins)
end

--- 针对目标进行伤害计算
--- #75 改排程：atk>0 时不再立即 Store HP/Emit HPChanged/登记 TickDamageDealtDict（全移落地）；
---   改为 env:ScheduleDamage(target, owner, atk*attackTimes, attackType, attackTimes, delayFrames) 入并行倒计时队列，
---   由 TickScheduledDamages 在 delay 帧后落地（land-time 登记 dict + Store HP + Emit）。
---   落地逻辑已移入 XPunishaarInstruction:Execute（#76 重构：env 级 PropertyList 非法→Instruction XClass + 对象池）。
---   AttackEffect payload（飞弹 VFX 发射）仍在本帧 Emit——先宣告先命中，VFX 飞行 = delay。
---   notDelayEnum 非0 时同帧立即落地（当前事务内 land，回滚同撤，比延迟更原子）；0/nil 走延迟排程。
---   VFX payload 仅延迟路径填（notDelay 无飞弹）；AttackEffect 事件两条路径都 Emit（攻击相关响应表现可能需要，非仅 VFX）。
---@param vm STEVM.VM
---@param notDelayEnum number|nil 0/nil=延迟排程（+VFX payload，landTick 后 TickScheduledDamages 落地）；非0=同帧立即落地（原子，无 VFX payload）
function Effect.AttackTarget(vm, entityIds, attackType, attackTimes, damageType, value, notDelayEnum)
    if not entityIds then
        return
    end
    if not attackTimes or attackTimes <= 0 then
        vm:Error(string.format("AttackTarget: attackTimes 非法（须>0），请检查配置；当前值=%s", tostring(attackTimes)))
        return
    end
    Effect._ReadDamageSource(vm, damageType, value)
    local atk = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.ATK)
    if atk <= 0 then
        return
    end
    local times = attackTimes
    local ownId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
    ---@type XPunishaarSTEEnv
    local env = vm:GetEnv()
    
    -- 传参只能传数值，这里转换成布尔值
    local isNotDelayAttack = XTool.IsNumberValidEx(notDelayEnum) and true or false

    if not isNotDelayAttack then   -- 目前约定延迟攻击和特效配合
        -- 攻击特效 payload（atk>0 即发射，事务内只写缓冲 + Emit，不碰 UI/场景）#73
        -- payload 不依赖伤害结果：atk>0 即发射；表现层帧末 Drain 后按 (own→tgt) 起终点投射
        -- 多目标每 (own, tgt) 对单独追加（payload 不去重）；vm:Emit 同键去重，帧末只派发一次 AttackEffect
        -- attackTimes + atk（单段值，atk*times 前）为扣血飘字预留：前端按段各显 atkPerHit
        if type(entityIds) == "table" then
            for _, target in ipairs(entityIds) do
                env:AppendAttackEffect(ownId, target, times, atk)
            end
        else
            env:AppendAttackEffect(ownId, entityIds, times, atk)
        end
    end
    
    -- 无条件 Emit AttackEffect：notDelay 路径虽不填 VFX payload（无飞弹），但攻击相关响应表现（非 VFX 监听者）可能需要该事件，故两条路径都 Emit
    vm:Emit(STECustomEnum.EventEnum.AttackEffect)

    -- 排程/落地伤害（atk*attackTimes 总值快照锁定，源 ATK 后续变化不影响已排程/已落地值）#75
    -- #77 队列机制优化：env 时间轮分桶，ScheduleDamage 第6参 landTick（绝对到点 tick，仅延迟路径用）
    -- notDelay=true 立即同事务落地（Effect._LandDamageNow，原子）；false 延迟排程（landTick 后 TickScheduledDamages 落地）
    local atkTotal = atk * times
    if type(entityIds) == "table" then
        if isNotDelayAttack then
            for _, target in ipairs(entityIds) do
                Effect._LandDamageNow(vm, env, target, ownId, atkTotal, attackType, times)
            end
        else
            local landTick = env:GetTick() + Effect.GetAttackLandDelayFrames()
            for _, target in ipairs(entityIds) do
                -- 校验 scopeId 值有效性（nil=配置错误→报错+事务回滚）；实体不存在=正常情况（可能已销毁）→静默跳过不排程
                if target == nil then
                    vm:Error("AttackTarget: 延后排程目标 scopeId 为 nil（配置错误）")
                elseif not env:GetScope(target) then
                    -- 实体不存在，静默跳过
                else
                    env:ScheduleDamage(target, ownId, atkTotal, attackType, times, landTick)
                end
            end
        end
    else
        if isNotDelayAttack then
            Effect._LandDamageNow(vm, env, entityIds, ownId, atkTotal, attackType, times)
        else
            local landTick = env:GetTick() + Effect.GetAttackLandDelayFrames()
            -- 同上：scopeId nil=报错；实体不存在=静默跳过
            if entityIds == nil then
                vm:Error("AttackTarget: 延后排程目标 scopeId 为 nil（配置错误）")
            elseif not env:GetScope(entityIds) then
                -- 实体不存在，静默跳过
            else
                env:ScheduleDamage(entityIds, ownId, atkTotal, attackType, times, landTick)
            end
        end
    end
end

--- 单目标私有（单/多分支收敛至此）#72
function Effect._CreateBuffOne(vm, target, buffId, ownCardId)
    local uid = vm:GetEnv():GetNewUniqueNumber()
    Effect._InitBuffEntity(vm, uid, buffId, ownCardId, target, nil)
    XLog.Debug(string.format("生成 Ex 驱动 buff [uid%s buffId%s] own%s target%s",
            tostring(uid), tostring(buffId), tostring(ownCardId), tostring(target)))
end

--- 直接生成一个 buff（自身无 modifier 效果，实际效果由 buff 表 Ex 字段驱动，见 TickAllBuffs 的 Ex 执行）。
--- buff 挂在选定 target 上；owner=执行者；不带 targetFieldNameEnum（纯 Ex 驱动）。
---@param vm STEVM.VM
---@param entityIds any 选中的目标（单 id 或列表）
---@param buffId number buff 配置 Id
function Effect.CreateBuff(vm, entityIds, buffId)
    if not entityIds then
        return
    end
    local ownCardId = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnCardId)
    -- 单/多分支收敛到 _CreateBuffOne #72
    if type(entityIds) == "table" then
        for _, target in ipairs(entityIds) do
            Effect._CreateBuffOne(vm, target, buffId, ownCardId)
        end
    else
        Effect._CreateBuffOne(vm, entityIds, buffId, ownCardId)
    end
end

--- 单目标私有（单/多分支收敛至此）#72
function Effect._AddNoConsumeBallTagOne(vm, target)
    vm:AddTag(target, STECustomEnum.EntityTags.NoConsumeBall)
    XLog.Debug(string.format("卡牌 [uid%s] 获得「下次不消耗球」标签", tostring(target)))
end

--- 给指定卡牌添加「下次触发不消耗球」标签（一次性，卡牌下次激发时消费并清除，见 ExecuteOneCardEffects）。
---@param vm STEVM.VM
---@param entityIds any 选中的卡牌（单 id 或列表）
function Effect.AddNoConsumeBallTag(vm, entityIds)
    if not entityIds then
        return
    end
    -- 单/多分支收敛到 _AddNoConsumeBallTagOne #72
    if type(entityIds) == "table" then
        for _, target in ipairs(entityIds) do
            Effect._AddNoConsumeBallTagOne(vm, target)
        end
    else
        Effect._AddNoConsumeBallTagOne(vm, entityIds)
    end
end

--- 消耗指定颜色指定数量的球（按 FIFO，有多少消多少——数量不足时消耗到没有为止，不报错）。
--- 独立实现（不复用 Pipeline 的 local ConsumeBall）；球池真变化才发事件。
---@param vm STEVM.VM
---@param color number 球颜色（STECustomEnum.BallColor）
---@param count number 期望消耗数量
function Effect.ConsumeBallByColor(vm, entityIds, color, count)
    if not count or count <= 0 then
        return
    end
    local ballList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallList)
    local removed = 0
    local index = 1
    -- 删除后元素前移，命中时 index 不前进
    while index <= vm:PropLen(ballList) and removed < count do
        if vm:PropGet(ballList, index) == color then
            vm:PropRemoveByKey(ballList, index)
            removed = removed + 1
        else
            index = index + 1
        end
    end
    if removed > 0 then
        vm:Emit(STECustomEnum.EventEnum.BallListChanged)
        -- 埋点统计：信号球消费总量累加（循环后一次 Store，非每球；事务可回滚）
        vm:Store(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TotalBallConsumed, STEEnum.ValChangeType.Add, removed)
    end
    XLog.Debug(string.format("Effect 消球：色%s 请求%s 实消%s，剩余球池[%s]",
            tostring(color), tostring(count), tostring(removed), tostring(vm:PropLen(ballList))))
end

--- 产出指定颜色指定数量的球（入队尾；球池满则挤压队头最早产的球 FIFO #球槽挤压）。
--- 独立实现（不复用 Pipeline 的 local ProduceBall）；实际产出 >0 才发事件。
---@param vm STEVM.VM
---@param color number 球颜色
---@param count number 期望产出数量
function Effect.ProduceBallByColor(vm, entityIds, color, count)
    if not count or count <= 0 then
        return
    end
    local ballList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallList)
    local capacity = vm:Read(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallSlotCapacity)
    local produced = 0
    for _ = 1, count do
        if vm:PropLen(ballList) >= capacity then
            -- 池满，挤压队头最早产的球（FIFO），新球入队尾 #球槽挤压
            vm:PropRemoveByKey(ballList, 1)
        end
        vm:PropAppend(ballList, color)
        produced = produced + 1
    end
    if produced > 0 then
        vm:Emit(STECustomEnum.EventEnum.BallListChanged)
        -- 埋点统计：信号球生成总量累加（循环后一次 Store，非每球；事务可回滚）
        vm:Store(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TotalBallProduced, STEEnum.ValChangeType.Add, produced)
    end
    XLog.Debug(string.format("Effect 产球：色%s 请求%s 实产%s（满则挤压队头 FIFO），当前球池[%s/%s]",
            tostring(color), tostring(count), tostring(produced),
            tostring(vm:PropLen(ballList)), tostring(capacity)))
end

--- 向事件总线派发一个指定事件（低业务语义函数的事件补足）。
--- 用途：ModifyNumberField 等通用函数自身不派发业务事件；策划在 EffectGroup 里于其后编排本 Effect，
---   显式声明"这次修改在业务上意味着什么事件"（如改护盾后配 EmitEvent(EnemyShieldChanged)）。
--- 高业务语义函数（AttackTarget 等）仍代码内置直接派发，不依赖本 Effect。
---@param vm STEVM.VM
---@param entityIds any 选中目标（本 Effect 不使用，签名统一保留）
---@param eventType number 事件枚举（STECustomEnum.EventEnum）
function Effect.EmitEvent(vm, entityIds, eventType)
    if eventType then
        vm:Emit(eventType)
    end
end

--region 字段镜像 buff 快照

--- 字段镜像：读实体某字段终值（math.floor 取整）→ 按 op 写入 buff 自身某字段。
--- 普通 on-tick effect：配在 buff 的 ExEffectGroup 里，TickBuffEx 分发跑（OwnBuffId 由 TickBuffEx:264 设）。
--- 通用（buffField 可配任意 buff 字段；buff 图标数值显示约定 buffField=Layer=16，聚合 GetDotBuffLayers 读 Layer）。
--- 幂等仅对 op=Set：buff 当前值==新值则 no-op（不 Store 不 Emit）。非 Set（Add/Sub/Mul/Div）每次执行+Emit，
---   每 Ex 周期累加 → 策划自负（非当前需求，op 通用性为保留扩展）。
--- entityIds 不用（写当前 OwnBuffId）；ScopeType 须配（任意，selector 结果被忽略，同 EmitEvent 范式）。
---@param vm STEVM.VM
---@param entityIds any 选中目标（不用，签名统一保留）
---@param srcOrTgt number STECustomEnum.ConfigFieldSource（1=buff源 OwnEntityId / 2=buff目标 TargetEntityId）
---@param entityField number STECustomEnum.FieldNameEnum（读该实体此字段终值）
---@param buffField number STECustomEnum.FieldNameEnum（写入 buff 自身此字段；DoT 显示用 Layer=16）
---@param op number STEEnum.ValChangeType（Set/Add/Sub/Mul/Div）
function Effect.SnapshotFieldToBuff(vm, entityIds, srcOrTgt, entityField, buffField, op)
    local buffUid = vm:GetFromBlackBoard(STECustomEnum.BlackBoardKeys.OwnBuffId)
    if not buffUid then
        return
    end
    -- 解析读哪个实体（buff 源/目标，从 buff 自身字段取 entityId）
    local entityFieldId
    if srcOrTgt == STECustomEnum.ConfigFieldSource.Source then
        entityFieldId = STECustomEnum.FieldNameType.OwnEntityId
    else
        entityFieldId = STECustomEnum.FieldNameType.TargetEntityId
    end
    local entity = vm:Read(buffUid, entityFieldId)
    if not entity then
        return
    end
    -- 配置字段枚举数值→字符串 key（FieldNameEnum 是 config 面向数值枚举；vm:Read/Store 取字符串，同 ModifyNumberField 范式）
    local entityFieldKey = STECustomEnum.FieldNameEnum[entityField]
    local buffFieldKey = STECustomEnum.FieldNameEnum[buffField]
    if not entityFieldKey or not buffFieldKey then
        vm:Error(string.format("SnapshotFieldToBuff: 字段枚举不存在 entityField=%s buffField=%s",
                tostring(entityField), tostring(buffField)))
        return
    end
    local raw = vm:Read(entity, entityFieldKey)
    if raw == nil then
        return
    end
    local value = math.floor(raw)  -- 读终值 + 取整
    local cur = vm:Read(buffUid, buffFieldKey) or 0
    if op == STEEnum.ValChangeType.Set and cur == value then
        return  -- 幂等（仅 Set）：同值 no-op，不 Store 不 Emit
    end
    vm:Store(buffUid, buffFieldKey, op, value)
    vm:Emit(STECustomEnum.EventEnum.DotBuffLayerChanged)
end

--endregion

--- 让指定的牌CD归零（单实体私有，SetCardCDEnd 单/多目标收敛至此，不临时 table 整合 #L3）
---@param vm STEVM.VM
---@param target any 卡牌实体 uid
function Effect._SetCardCDEndOne(vm, target)
    local before
    if XMain.IsEditorDebug then
        before = vm:Read(target, STECustomEnum.FieldNameType.TickCD)
    end
    vm:Store(target, STECustomEnum.FieldNameType.TickCD, STEEnum.ValChangeType.Set, 0)

    -- 立即入待激发表，使当帧收敛循环下一轮即可筛出（否则要等下帧 TickAllCards）
    if vm:HasTag(target, STECustomEnum.EntityTags.Card) and not vm:HasTag(target, STECustomEnum.EntityTags.WaittingDone) then
        local handler = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.WaittingDoneCardIdList)
        vm:PropAppend(handler, target)
        vm:AddTag(target, STECustomEnum.EntityTags.WaittingDone)
    end

    if XMain.IsEditorDebug then
        XLog.Debug(string.format("[Effect] SetCardCDEnd uid=%s TickCD %s→0",
                tostring(target), tostring(before)))
    end
end

--- 让指定的牌CD归零
---@param vm STEVM.VM
---@param entityIds any 选中的卡牌（单 id 或列表）
function Effect.SetCardCDEnd(vm, entityIds)
    if type(entityIds) == "table" then
        for _, target in ipairs(entityIds) do
            Effect._SetCardCDEndOne(vm, target)
        end
    else
        Effect._SetCardCDEndOne(vm, entityIds)
    end
end

--endregion

--- 加速指定卡牌的 CD：推进 amount 帧；若跨零则当帧入待激发表（同 SetCardCDEnd 的激活路径）。
--- 与 SetCardCDEnd（强制清零）的差异：按量推进，未跨零只缩短不激活。
--- 帧级记录：每个推进过的实体登记到 Global.TickAccelEntityList（随 ResetGlobalTickData 清零），
---   供未来 Trigger 查询"本帧哪些实体被加速过 CD"。
---@param vm STEVM.VM
---@param entityIds any 选中的卡牌（单 id 或列表）
---@param amount number 推进的 CD 帧数（<=0 不处理）
--- 加速单张卡牌 CD 的私有封装（单/多目标分支共用，避免临时 table 整合）。
--- 运算在毫秒域：帧→毫秒（基于 BaseLogicFrame，忽略二倍速）→ 扣除 → 毫秒→帧 赋值。
---@param vm STEVM.VM
---@param target any 单个目标 entityId
---@param amount number 扣除量（mode=Fixed=毫秒 / mode=Ratio=浮点比例 0.5=50%）
---@param mode number STECustomEnum.ConfigCDDeductMode（0=Fixed / 1=Ratio 基于 CDMax）
---@param accelList PropertyList 帧级加速记录列表
function Effect._AccelerateOne(vm, target, amount, mode, accelList)
    -- 加速冷却 gate（perf护栏，非玩法）：同卡在 W=TickCDMaxMin 帧内只允许被加速一次。
    -- Global.AccelLockUntilTickDict[target]=解锁tick；未到则跳过本次推进（不扣CD、不续锁、不入accelList）。#加速冷却
    local lockDict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.AccelLockUntilTickDict)
    if vm:GetEnv():GetTick() < (vm:PropGet(lockDict, target) or 0) then
        return
    end
    local cd = vm:Read(target, STECustomEnum.FieldNameType.TickCD) or 0
    local cdMax = vm:Read(target, STECustomEnum.FieldNameType.TickCDMax) or 0
    -- 1 帧 = 50ms（STECustomEnum.MsPerLogicFrame 预算常量，免运行时除法）
    local msPerFrame = STECustomEnum.MsPerLogicFrame
    -- 帧→毫秒（二倍速只改帧消耗速度，不改 CD 字段值，毫秒语义稳定）
    local cdMs = cd * msPerFrame
    local cdMaxMs = cdMax * msPerFrame
    -- 扣除量（毫秒域运算）
    local deductMs
    if mode == STECustomEnum.ConfigCDDeductMode.Ratio then
        deductMs = cdMaxMs * (amount or 0)  -- 浮点比例（0.5=扣 50% CDMax）
    else
        deductMs = amount or 0  -- Fixed：固定毫秒
    end
    local newCdMs = cdMs - deductMs
    if newCdMs < 0 then
        newCdMs = 0
    end
    -- 毫秒→帧（math.floor 向下取整，对齐 CardEntity 初始化 CreateCardEntity L227 的毫秒→帧范式；剩余 CD 可 0 就绪态，不加 max(1) 下限）
    local newCd = math.floor(newCdMs / msPerFrame)
    vm:Store(target, STECustomEnum.FieldNameType.TickCD, STEEnum.ValChangeType.Set, newCd)
    -- 续加速冷却锁：仅当本次真正缩短了 CD（newCd<cd）才续锁，避免无实际推进的加速（cd 已 0 就绪态 / Ratio cdMax=0 致 deductMs=0）误占锁、4 帧内挡掉后续有效加速。#加速冷却
    if newCd < cd then
        vm:PropSet(lockDict, target, vm:GetEnv():GetTick() + STECustomEnum.TickCDMaxMin)
    end
    if XMain.IsEditorDebug then
        XLog.Debug(string.format("[Effect] AccelerateCardCD uid=%s mode=%s amount=%s TickCD %s→%s (cdMs %s→%s deduct %sms)",
                tostring(target), tostring(mode), tostring(amount),
                tostring(cd), tostring(newCd), tostring(cdMs), tostring(newCdMs), tostring(deductMs)))
    end
    -- 跨零且为卡牌且未在待激活队列：注入使当帧 OutputCanActiveCardIds 可筛出
    if newCd == 0
            and vm:HasTag(target, STECustomEnum.EntityTags.Card)
            and not vm:HasTag(target, STECustomEnum.EntityTags.WaittingDone) then
        local handler = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.WaittingDoneCardIdList)
        vm:PropAppend(handler, target)
        vm:AddTag(target, STECustomEnum.EntityTags.WaittingDone)
    end
    -- Contains 守卫去重（同帧同实体多 Effect 只记一次 #L4）；走 vm:PropContains 转发协议
    if not vm:PropContains(accelList, target) then
        vm:PropAppend(accelList, target)
    end
end

--- 加速指定卡牌的 CD：按 mode 扣除 CD；若跨零则当帧入待激发表（同 SetCardCDEnd 的激活路径）。
--- 运算在毫秒域（帧↔毫秒基于 BaseLogicFrame，忽略二倍速），结果 math.floor 取整回帧赋值。
--- 帧级记录：每个推进过的实体登记到 Global.TickAccelEntityList（随 ResetGlobalTickData 清零），
---   供未来 Trigger 查询"本帧哪些实体被加速过 CD"。
---@param vm STEVM.VM
---@param entityIds any 选中的卡牌（单 id 或列表）
---@param amount number 扣除量（mode=Fixed=毫秒 / mode=Ratio=浮点比例 0.5=50% CDMax）
---@param mode number STECustomEnum.ConfigCDDeductMode（0=Fixed 固定毫秒 / 1=Ratio 基于 CDMax 比例）
function Effect.AccelerateCardCD(vm, entityIds, amount, mode)
    if not amount or amount <= 0 then
        return
    end
    if not entityIds then
        return
    end
    local accelList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TickAccelEntityList)
    -- 单/多分支收敛：相同逻辑入 _AccelerateOne 私有函数，单 id 直调、多 id 循环调，不临时 table 整合（#L3）
    if type(entityIds) == "table" then
        for _, target in ipairs(entityIds) do
            Effect._AccelerateOne(vm, target, amount, mode, accelList)
        end
    else
        Effect._AccelerateOne(vm, entityIds, amount, mode, accelList)
    end
end

return Effect
