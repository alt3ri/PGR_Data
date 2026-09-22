--- STEProjection: 局外 UI 投影用「装备即生效」ATK/CD 实时预览（Layer-1 静态投影）
---
--- 纯函数 module（非 XClass，不持 env，不跑 Effect，不 require STEVM.VM）。
--- 仅复用 ValueOp.Apply 这一纯函数，对 targetCard 的 ATK/CD 经「装备即生效」效果加成后的值做静态投影。
---
--- 镜像口径：
---   base 来源 = CardLevel 表（同 CreateCardEntity L227：atkBase=levelCfg.ATK；cdBaseMs=levelCfg.CD；
---     cd 帧 = max(1, floor(cdBaseMs/1000 * logicFrame))）
---   effect 链 = RunBattleStartEffects 的 CardEntityIds 序（数组序遍历 equippedCards），
---     仅投 EffectType==1(ModifyNumberField) 且 targetFieldEnum∈{ATK(3),TickCDMax(5)} 的 effect，
---     时机 mask = TriggerTimeMask.BattleStart(6)（装备时|战斗开始时）。
---   Selector/Trigger 位置类逻辑镜像 STEDefine.Selector/Trigger/STEQuery；runtime 类（球池/HP/概率/tick 列表）保守 false。
---
---   index 域口径（重要，非严格镜像真值）：
---     投影 equipped 按 StartPos 升序赋 1-based 紧凑 index，是「投影确定性口径」；
---     真值装配序（RunControl._PrepareBattleData L387-394）以 pairs(TotalMasterCards) 顺序 AddCard，
---     SetupBattle 按契约数组序作 index——即真值 index 非按 posIndex 升序，投影与真值的 index 域不一定一致。
---     典型装备即生效配置（自身 scopeType=1 / ConfigFilter=6 / 空间触边邻居=8）不依赖 Index 域，不受影响；
---     若策划配 Index 绝对位置类效果（Selector scopeType=2/7、Trigger condType=1）需服务端保证 StartPos 插入序
---     或单独评审（投影 index 与真值 index 错位时结果可能失真）。
---
--- EffectParams 约定 1-based：[1]=targetFieldEnum, [2]=op(ValChangeType), [3]=rightVal。
--- CD 投影：rightVal 单位=帧（与 TickCDMax 字段同域，非毫秒）；最终 cdDeltaMs = curCdFrames/logicFrame*1000 - cdBaseMs。
--- Divide 除零 / 未知 op → ValueOp.Apply 返回 nil，本 effect 不应用并标记 skipped=true（后续 effect 继续）。

local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
local ValueOp = require("STEVM/Engine/ValueOp")

-- 枚举局部别名（零 drift，require 一次）
local TriggerTimeType = STECustomEnum.TriggerTimeType
local TriggerTimeMask = STECustomEnum.TriggerTimeMask
local PosMode = STECustomEnum.PosMode
local AdjacentSide = STECustomEnum.AdjacentSide

--- 取数组参数；缺省（arr 为空或 arr[i] 为 nil）返回 default。
--- 用 ~= nil 判定，避免 0（config 数值参数中常表"无筛选"）被误判缺失——等价于 `arr and arr[i] or default` 但无 a-and-b-or-c 短路陷阱。
---@param arr table|nil
---@param i number
---@param default any
---@return any
local function ArrayParam(arr, i, default)
    if arr and arr[i] ~= nil then
        return arr[i]
    end
    return default
end

---@class STEProjection  -- 纯函数 module
local STEProjection = {}

--region 位置解析（镜像 STEQuery.ResolveIndex，但不依赖 vm，直接用 equippedCards 的紧凑 index 域）

--- 把 (mode, param) 解析成绝对 Index（基于 equippedCards 的 1..N 紧凑域）。
---@param mode number STECustomEnum.PosMode
---@param param number|nil
---@param E table 执行者卡 { index, ... }
---@param equippedCards table[] 已装备集（紧凑 index 1..N）
---@return number|nil
local function ResolveIndexStatic(mode, param, E, equippedCards)
    if mode == PosMode.Absolute then
        return param
    elseif mode == PosMode.RelativeToSelf then
        if not E or not E.index then return nil end
        return E.index + (param or 0)
    elseif mode == PosMode.Leftmost then
        return 1
    elseif mode == PosMode.Rightmost then
        if equippedCards then
            return #equippedCards
        end
        return nil
    end
    return nil
end
STEProjection._ResolveIndexStatic = ResolveIndexStatic

--endregion

--region Selector 静态镜像

--- 判断目标卡 C 是否被 (scopeType, scopeParams) 选中的执行者 E 命中。
--- 镜像 STEDefine.Selector 各原语，仅保留位置/配置类；runtime 字段比较类保守 false。
---@param scopeType number EffectCfg.ScopeType（STEDefine.Selector 下标）
---@param scopeParams table EffectCfg.ScopeParams
---@param E table 执行者卡 { cardId, level, index, posIndex, cardCfg? }
---@param C table 目标卡 { cardId, level, index, posIndex, cardCfg? }
---@param equippedCards table[] 已装备集
---@param control XPunishaarControl 配置 reader 宿主
---@return boolean
local function IsSelectorHit(scopeType, scopeParams, E, C, equippedCards, control)
    if not scopeType or not C or not E then
        return false
    end
    if scopeType == 1 then
        -- 自身：E 与 C 同卡（cardId + index 相同）
        return E.cardId == C.cardId and E.index == C.index
    elseif scopeType == 2 then
        -- 位置（GetCardIdByPos）：mode,param = scopeParams[1],[2]；C.index==targetIndex
        local mode = scopeParams and scopeParams[1]
        local param = scopeParams and scopeParams[2]
        local targetIndex = ResolveIndexStatic(mode, param, E, equippedCards)
        if not targetIndex then return false end
        return C.index == targetIndex
    elseif scopeType == 3 or scopeType == 4 then
        -- Player/Enemy：非卡牌 ATK/CD 字段
        return false
    elseif scopeType == 5 then
        -- runtime 字段比较（GetCardsByFieldCompare）：保守不应用，不设 skipped（只用于 Divide 除零）
        return false
    elseif scopeType == 6 then
        -- 配置筛选（GetCardsByConfigFilter）：color,cardType,includeSelf = scopeParams[1..3]
        local color = ArrayParam(scopeParams, 1, 0)
        local cardType = ArrayParam(scopeParams, 2, 0)
        local includeSelf = ArrayParam(scopeParams, 3, 0)
        if includeSelf == 0 and E.cardId == C.cardId and E.index == C.index then
            return false
        end
        local cfg = C.cardCfg or (control and control:GetTablePunishaarCard(C.cardId, true))
        if not cfg then return false end
        local colorOk = color == 0 or cfg.Color == color
        local typeOk = cardType == 0 or cfg.Type == cardType
        return colorOk and typeOk
    elseif scopeType == 7 then
        -- 紧凑邻居（GetAdjacentCardsByIndex）：side = scopeParams[1]
        local side = scopeParams and scopeParams[1]
        if side == AdjacentSide.Left then
            return C.index == E.index - 1
        elseif side == AdjacentSide.Right then
            return C.index == E.index + 1
        elseif side == AdjacentSide.Either then
            return C.index == E.index - 1 or C.index == E.index + 1
        end
        return false
    elseif scopeType == 8 then
        -- 空间邻居（GetAdjacentCardsBySpatial）：side = scopeParams[1]
        -- Left→C.posIndex + C.Size == E.posIndex；Right→E.posIndex + E.Size == C.posIndex；Either→任一
        local side = scopeParams and scopeParams[1]
        local function sizeOf(card)
            if not card then return 1 end
            if card.Size then return card.Size end
            local cfg = card.cardCfg or (control and control:GetTablePunishaarCard(card.cardId, true))
            if cfg and cfg.Size then
                return cfg.Size
            end
            return 1
        end
        local ePos = E.posIndex or 0
        local cPos = C.posIndex or 0
        local eSize = sizeOf(E)
        local cSize = sizeOf(C)
        local leftHit = cPos + cSize == ePos
        local rightHit = ePos + eSize == cPos
        if side == AdjacentSide.Left then
            return leftHit
        elseif side == AdjacentSide.Right then
            return rightHit
        elseif side == AdjacentSide.Either then
            return leftHit or rightHit
        end
        return false
    end
    -- 未知 scopeType：保守 false
    return false
end
STEProjection._IsSelectorHit = IsSelectorHit

--endregion

--region Trigger 条件静态镜像

--- Trigger 条件分流（镜像 STEDefine.Trigger 各原语）。
--- 位置类镜像；runtime 类（球池/HP/概率/tick 列表/finalValue）保守 false。
---@param condType number triggerCfg.ConditionType（STEDefine.Trigger 下标）
---@param condParams table triggerCfg.ConditionParams
---@param E table 执行者卡
---@param C table 目标卡
---@param equippedCards table[] 已装备集
---@param control XPunishaarControl 配置 reader 宿主
---@return boolean
local function CheckConditionStatic(condType, condParams, E, C, equippedCards, control)
    if not condType or condType == 0 then
        return true
    end
    if condType == 1 then
        -- CheckSelfPosMatch(mode, param)：E.index == targetIndex
        local mode = condParams and condParams[1]
        local param = condParams and condParams[2]
        local targetIndex = ResolveIndexStatic(mode, param, E, equippedCards)
        if not targetIndex or not E.index then return false end
        return E.index == targetIndex
    elseif condType == 12 then
        -- CheckNeighborMainCardMatch(side, color, cardType)：在 equippedCards 中找 E 的左/右空间邻居，查其 Color/Type 匹配
        local side = condParams and condParams[1]
        local color = ArrayParam(condParams, 2, 0)
        local cardType = ArrayParam(condParams, 3, 0)
        local function sizeOf(card)
            if not card then return 1 end
            if card.Size then return card.Size end
            local cfg = card.cardCfg or (control and control:GetTablePunishaarCard(card.cardId, true))
            if cfg and cfg.Size then
                return cfg.Size
            end
            return 1
        end
        local ePos = E.posIndex or 0
        local eSize = sizeOf(E)
        local function neighborMatches(neighbor)
            if not neighbor then return false end
            local cfg = neighbor.cardCfg or (control and control:GetTablePunishaarCard(neighbor.cardId, true))
            if not cfg then return false end
            local colorOk = color == 0 or cfg.Color == color
            local typeOk = cardType == 0 or cfg.Type == cardType
            return colorOk and typeOk
        end
        local leftHit, rightHit = false, false
        if side == AdjacentSide.Left or side == AdjacentSide.Either then
            -- E 的左空间邻居：neighbor.posIndex + neighbor.Size == E.posIndex
            for _, nc in ipairs(equippedCards or {}) do
                if nc.posIndex and (nc.posIndex + sizeOf(nc) == ePos) then
                    if neighborMatches(nc) then leftHit = true break end
                end
            end
        end
        if side == AdjacentSide.Right or side == AdjacentSide.Either then
            -- E 的右空间邻居：E.posIndex + E.Size == neighbor.posIndex
            for _, nc in ipairs(equippedCards or {}) do
                if nc.posIndex and (ePos + eSize == nc.posIndex) then
                    if neighborMatches(nc) then rightHit = true break end
                end
            end
        end
        if side == AdjacentSide.Left then
            return leftHit
        elseif side == AdjacentSide.Right then
            return rightHit
        elseif side == AdjacentSide.Either then
            return leftHit or rightHit
        end
        return false
    end
    -- 其余 condType（2~11）均依赖 runtime tick 列表 / 球池 / HP / finalValue / 概率，装备即生效投影无这些上下文，保守 false
    return false
end
STEProjection._CheckConditionStatic = CheckConditionStatic

--- 时机+条件判定（镜像 Pipeline.CheckEffectTrigger）。
---@param control XPunishaarControl 配置 reader 宿主
---@param triggerId number|nil EffectCfg.TriggerId
---@param mask number 接受的时机 mask（STECustomEnum.TriggerTimeMask.*）
---@param E table 执行者卡
---@param C table 目标卡
---@param equippedCards table[] 已装备集
---@return boolean
local function CheckTriggerStatic(control, triggerId, mask, E, C, equippedCards)
    -- 无 trigger：时机=Other；仅当 mask 接受 Other 才通过（无条件）
    if not triggerId or triggerId == 0 then
        return (mask & (1 << TriggerTimeType.Other)) ~= 0
    end
    local triggerCfg = control and control:GetTablePunishaarTrigger(triggerId, true)
    if not triggerCfg then
        return (mask & (1 << TriggerTimeType.Other)) ~= 0
    end
    -- 先判时机：TriggerType 空/0=Other；不在接受 mask 内直接否
    local triggerType = triggerCfg.TriggerType or TriggerTimeType.Other
    if (mask & (1 << triggerType)) == 0 then
        return false
    end
    -- 再判条件：ConditionType 空/0=无条件通过
    local condType = triggerCfg.ConditionType
    if not condType or condType == 0 then
        return true
    end
    return CheckConditionStatic(condType, triggerCfg.ConditionParams, E, C, equippedCards, control)
end
STEProjection._CheckTriggerStatic = CheckTriggerStatic

--endregion

--region 主投影入口

--- 单卡 ATK/CD 经「装备即生效」效果加成后的投影（Layer-1 静态投影）
---@param control XPunishaarControl 配置 reader 宿主（用其 GetTablePunishaarEffect/EffectGroup/Trigger/Card/CardLevel）
---@param targetCard table { cardId, level, index, posIndex }
---@param equippedCards table[] 已装备集（含 C 自身）：每元素 { cardId, level, index, posIndex }
---@param logicFrame number 逻辑帧率（大巴扎=20）
---@return table { atkBase, atkDelta, cdBaseMs, cdDeltaMs, ballConsumeBase, ballConsumeDelta, ballOutPutBase, ballOutPutDelta, skipped }
function STEProjection.ProjectAtkCd(control, targetCard, equippedCards, logicFrame)
    local result = { atkBase = 0, atkDelta = 0, cdBaseMs = 0, cdDeltaMs = 0,
                     ballConsumeBase = 0, ballConsumeDelta = 0, ballOutPutBase = 0, ballOutPutDelta = 0,
                     skipped = false }
    if not control or not targetCard or not targetCard.cardId or targetCard.cardId == 0 then
        return result
    end
    logicFrame = logicFrame or 20

    -- 1. base：levelCfg（key = cardId*100 + level）
    local levelCfg = control:GetTablePunishaarCardLevel(targetCard.cardId * 100 + (targetCard.level or 1), true)
    if not levelCfg then
        return result
    end
    local atkBase = levelCfg.ATK or 0
    local cdBaseMs = levelCfg.CD or 0
    local ballConsumeBase = levelCfg.BallConsume or 0
    local ballOutPutBase = levelCfg.BallOutPut or 0
    result.atkBase = atkBase
    result.cdBaseMs = cdBaseMs
    result.ballConsumeBase = ballConsumeBase
    result.ballOutPutBase = ballOutPutBase

    -- 无 equipped 或仅自身：直接返回 base+0delta
    if not equippedCards or #equippedCards == 0 then
        return result
    end

    -- 2. cur 链：atk 同 base；cd 帧 = max(1, floor(ms/1000 * logicFrame))（镜像 CreateCardEntity L227）；球数同 base
    local curAtk = atkBase
    local curCdFrames = math.max(1, math.floor(cdBaseMs / 1000 * logicFrame))
    local curBallConsume = ballConsumeBase
    local curBallOutPut = ballOutPutBase

    -- 3. 遍历 equippedCards（数组序，镜像 RunBattleStartEffects 的 CardEntityIds 序）
    local mask = TriggerTimeMask.BattleStart

    -- 跑指定 effect group 的 ModifyNumberField(EffectType=1) effect，作用在 curAtk/curCdFrames/curBallConsume/curBallOutPut（targetCard 当前投影值）。
    -- E=执行者身份（局内 ownerId 语境）；命中 targetFieldEnum=ATK(3)/TickCDMax(5)/BallProductCount(8)/BallConsumeCount(9) 经 CheckTrigger+Selector 后 ValueOp.Apply。
    -- 闭包共享 curAtk/curCdFrames/result upvalue（投影单次调用，非热路径，闭包不每帧重建）。
    ---@param E table 执行者卡（主卡身份，副卡 effect 经 ownerId=宿主主卡 E 语境跑）
    ---@param groupId number|nil EffectGroupId（来自主卡或副卡 cardCfg.EffectGroupId；nil/0 时 no-op）
    local function RunGroup(E, groupId)
        if not groupId or groupId == 0 then return end
        local groupCfg = control:GetTablePunishaarEffectGroup(groupId, true)
        local effectIds = groupCfg and groupCfg.EffectIds
        if not effectIds then return end
        for _, effectId in ipairs(effectIds) do
            local effectCfg = control:GetTablePunishaarEffect(effectId, true)
            if effectCfg and effectCfg.EffectType == 1 then
                -- ModifyNumberField：EffectParams = [1]=targetFieldEnum, [2]=op, [3]=rightVal
                local params = effectCfg.EffectParams
                local targetFieldEnum = params and params[1]
                -- 数值枚举判定：FieldNameEnum 反向映射 ATK=3 / TickCDMax=5 / BallProductCount=8 / BallConsumeCount=9；
                -- 只投这四个字段（卡牌详情/装备态预览关心 ATK/CD/产球/消球），直接数值比较
                if targetFieldEnum == 3 or targetFieldEnum == 5 or targetFieldEnum == 8 or targetFieldEnum == 9 then
                    -- 时机+条件判定
                    if CheckTriggerStatic(control, effectCfg.TriggerId, mask, E, targetCard, equippedCards) then
                        -- Selector 命中
                        if IsSelectorHit(effectCfg.ScopeType, effectCfg.ScopeParams, E, targetCard, equippedCards, control) then
                            local op = params[2]
                            local rightVal = params[3]
                            if targetFieldEnum == 3 then
                                -- ATK
                                local newv = ValueOp.Apply(curAtk, op, rightVal)
                                if newv ~= nil then
                                    curAtk = newv
                                else
                                    result.skipped = true
                                end
                            elseif targetFieldEnum == 5 then
                                -- CD（单位=帧）
                                local newv = ValueOp.Apply(curCdFrames, op, rightVal)
                                if newv ~= nil then
                                    curCdFrames = newv
                                else
                                    result.skipped = true
                                end
                            elseif targetFieldEnum == 8 then
                                -- 产球数（BallProductCount）
                                local newv = ValueOp.Apply(curBallOutPut, op, rightVal)
                                if newv ~= nil then
                                    curBallOutPut = newv
                                else
                                    result.skipped = true
                                end
                            else
                                -- 消球数（BallConsumeCount, targetFieldEnum==9）
                                local newv = ValueOp.Apply(curBallConsume, op, rightVal)
                                if newv ~= nil then
                                    curBallConsume = newv
                                else
                                    result.skipped = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for _, E in ipairs(equippedCards) do
        if E and E.cardId and E.cardId ~= 0 then
            local eCardCfg = E.cardCfg or control:GetTablePunishaarCard(E.cardId, true)
            if eCardCfg then
                -- 副卡先（镜像局内 RunBattleStartEffects L606-609：副卡 EffectGroup 跑在 ownerId=宿主主卡 E 语境，
                --   E 用主卡身份，Selector/Trigger 在主卡 owner 语境判，与局内一致；副卡无 level，不读 CardLevel）。
                --   漏此步=意识/共鸣副卡的装备时 effect 局外预览为 0 delta（bug 修复）。
                local subCardId = E.subCardId or 0
                if subCardId ~= 0 then
                    local subCardCfg = control:GetTablePunishaarCard(subCardId, true)
                    RunGroup(E, subCardCfg and subCardCfg.EffectGroupId)
                end
                -- 主卡
                RunGroup(E, eCardCfg.EffectGroupId)
            end
        end
    end

    -- 4. curCdMs 回毫秒；球数无单位换算（整数 base+delta 直接取）
    local curCdMs = curCdFrames / logicFrame * 1000
    result.atkDelta = curAtk - atkBase
    result.cdDeltaMs = curCdMs - cdBaseMs
    result.ballConsumeDelta = curBallConsume - ballConsumeBase
    result.ballOutPutDelta = curBallOutPut - ballOutPutBase
    return result
end

--endregion

return STEProjection
