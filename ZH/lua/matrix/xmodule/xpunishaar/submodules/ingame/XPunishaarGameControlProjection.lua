--- Control 部分类：局外 UI 投影「装备即生效」ATK/CD 实时预览（Layer-1 静态投影）。
--- 仅战斗区（FightArea）卡走投影；商品态（masterCard nil）和背包暂存区（Bag）走 fallback 显 base（delta=0）。
--- 委托 STEProjection.ProjectAtkCd 纯函数，不持 env、不跑 Effect。
local STEProjection = require("XModule/XPunishaar/STEDefine/STEProjection")

local XPunishaarGameControl = XClassPartial("XPunishaarGameControl")

--- 局外投影用的逻辑帧率（对齐 XPunishaarFightControl.LogicFrame 常量=20，毫秒→帧换算口径一致）
local ProjectionLogicFrame = 20

--- base 直读 fallback：商品态/背包态/异常路径，返回 base+0delta（delta=0→UI 显 Equal format）。
---@param cardId number
---@param level number
---@return table { atkBase, atkDelta, cdBaseMs, cdDeltaMs, ballConsumeBase, ballConsumeDelta, ballOutPutBase, ballOutPutDelta, skipped }
function XPunishaarGameControl:_ProjectionFallback(cardId, level)
    local result = { atkBase = 0, atkDelta = 0, cdBaseMs = 0, cdDeltaMs = 0,
                     ballConsumeBase = 0, ballConsumeDelta = 0, ballOutPutBase = 0, ballOutPutDelta = 0,
                     skipped = false }
    if not cardId or cardId == 0 then
        return result
    end
    local levelCfg = self:GetTablePunishaarCardLevel(cardId * 100 + (level or 1), true)
    if levelCfg then
        result.atkBase = levelCfg.ATK or 0
        result.cdBaseMs = levelCfg.CD or 0
        result.ballConsumeBase = levelCfg.BallConsume or 0
        result.ballOutPutBase = levelCfg.BallOutPut or 0
    end
    return result
end

--- 取主卡经「装备即生效」效果加成后的实时 ATK/CD/产球/消球投影（供 UI 详情页/装备态 grid 显示）
--- 仅战斗区（FightArea）卡生效；商品态/背包态返回 base+0delta（不投影）
---@param cardId number 目标卡模板 Id
---@param level number 目标卡等级
---@param masterCard table|nil 装备态传 MasterCard 实例；商品态 nil
---@return table { atkBase, atkDelta, cdBaseMs, cdDeltaMs, ballConsumeBase, ballConsumeDelta, ballOutPutBase, ballOutPutDelta, skipped }
function XPunishaarGameControl:GetCardRealtimeAtkCd(cardId, level, masterCard)
    -- 无 cardId：直接 0
    if not cardId or cardId == 0 then
        return { atkBase = 0, atkDelta = 0, cdBaseMs = 0, cdDeltaMs = 0, skipped = false }
    end

    -- 判是否走投影：masterCard 非空 且 处于 FightArea；否则走 fallback（含 Bag、商品态 masterCard=nil）
    local FightArea = XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea
    if not masterCard or masterCard.AreaType ~= FightArea then
        return self:_ProjectionFallback(cardId, level)
    end

    -- 装备态但 stage/TotalMasterCards 未就位 → fallback
    local stage = self._Model and self._Model:GetCurrentStage()
    local total = stage and stage.TotalMasterCards
    if not total then
        return self:_ProjectionFallback(cardId, level)
    end

    -- 构造 equipped：遍历 total 过滤 FightArea，收集 {cardId=TemplateId, level=Level, posIndex=StartPos, subCardId=SubCardId}，
    -- 按 StartPos 升序排序后赋 1-based 紧凑 index——此 index 是「投影确定性口径」，
    -- 非严格镜像真值装配序（真值 RunControl._PrepareBattleData L387-394 以 pairs(TotalMasterCards) 顺序 AddCard，
    -- SetupBattle 按契约数组序作 index；真值 index 非按 posIndex 升序，与本投影 index 不一定一致）。
    -- 典型装备即生效配置（自身/ConfigFilter/空间触边邻居）不依赖 Index 域，不受影响；
    -- 若策划配 Index 绝对位置类效果（Selector 2/7、Trigger condType 1）需服务端保证 StartPos 插入序或单独评审。
    -- subCardId 透传：副卡（意识/共鸣）EffectGroup 跑在 ownerId=宿主主卡 E 语境，需 equipped 携带宿主关系供投影遍历先副后主（镜像 RunBattleStartEffects L606-609）。
    local equipped = {}
    for _, card in pairs(total) do
        if card.AreaType == FightArea then
            equipped[#equipped + 1] = {
                cardId    = card.TemplateId,
                level     = card.Level or 1,
                posIndex  = card.StartPos or 0,
                subCardId = card.SubCardId or 0,
            }
        end
    end
    if #equipped == 0 then
        return self:_ProjectionFallback(cardId, level)
    end
    table.sort(equipped, function(a, b) return (a.posIndex or 0) < (b.posIndex or 0) end)
    for i, c in ipairs(equipped) do
        c.index = i
    end

    -- 找 targetCard：在 equipped 中找与 masterCard 同卡实例（posIndex 匹配）的项作 targetCard
    -- （masterCard.Id 是服务端主卡实例 Id，不在投影 equipped 字段域内；用 AreaType+StartPos 作唯一性定位）
    local targetCard
    local targetPos = masterCard.StartPos
    for _, c in ipairs(equipped) do
        if c.posIndex == targetPos and c.cardId == cardId then
            targetCard = c
            break
        end
    end
    if not targetCard then
        -- 异常：masterCard 指向的 FightArea 槽位在 equipped 中找不到（数据不一致）→ fallback
        return self:_ProjectionFallback(cardId, level)
    end

    -- 本 partial 已在 GameControl 上（self=GameControl）：Effect/EffectGroup/Trigger 单点登记于此 + Card/CardLevel 经 GetControl() 委派
    return STEProjection.ProjectAtkCd(self, targetCard, equipped, ProjectionLogicFrame)
end

return XPunishaarGameControl
