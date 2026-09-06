--- 大巴扎战斗模型/特效配置查询收口（纯表现层，只读 STE/Control 配置接口）。
--- 职责：
---   * GetCardModelRow(cardId)          → PunishaarCardModel 表行（ModelId/AttackAnima/NormalIdleAnima/AttackSFX）
---   * GetEnemyCfgByFightId()           → PunishaarEnemy 表行（fightId 单源：Control:GetCurrentFightId 节点 FightInfo）
---   * GetAttackSFX(ownerId, cardId)    → 统一三分支收口（Player→nil / Enemy→Enemy.AttackSFX / Card→CardModel.AttackSFX）
---   * SetEnemyAttackAnima/GetEnemyAttackAnima → 敌人攻击动画名缓存（RefreshEnemyModel 写 / PlayEnemyAttack 读）
--- 不持 fightControl/STEReader（运行时才就绪）；ownerId→cardId 转换由调用方（EffectPlayer）做。
--- 逻辑整段搬运自 XUiPunishaarModelShow（ShowCardModel/RefreshEnemyModel/GetEnemyAttackSFX）+
---   XUiPunishaarBattleEffectController（_GetEffectPrefabPath），不改变查询语义，只收口职责。#73
---@class XUiPunishaarModelConfigResolver : XUiNode
---@field protected _Control XPunishaarControl
---@field private _EnemyAttackAnima string|nil 敌人攻击动画名缓存（RefreshEnemyModel 时写，PlayEnemyAttack 时读，避免每次攻击现查 enemyCfg）
local XUiPunishaarModelConfigResolver = XClass(XUiNode, "XUiPunishaarModelConfigResolver")

local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")

--- XUiNode 生命周期钩子：New 后框架调（_Control 由框架从 parent 链注入，不业务传）。
function XUiPunishaarModelConfigResolver:OnStart()
    self._EnemyAttackAnima = nil
end

--- 取卡牌模型配置行（PunishaarCardModel）。
---@param cardId number 卡牌模板 Id（主卡 cardId 才有行）
---@return table|nil PunishaarCardModel 行（ModelId/AttackAnima/NormalIdleAnima/AttackSFX）
function XUiPunishaarModelConfigResolver:GetCardModelRow(cardId)
    return self._Control:GetTablePunishaarCardModel(cardId, true)
end

--- 取敌人配置行（PunishaarEnemy），fightId 单源：当前节点 FightInfo（经 Control:GetCurrentFightId 收口）。
--- 与 PreFight 敌人信息刷新（PanelFightBefore._RefreshRoleShow）同源，消除"契约残留旧 _FightId 优先分支命中
--- 致模型显旧敌人而敌人信息显新敌人"的不一致（PreFight 不经 _PrepareBattleData 的路径如 LeaveRemedyShop）。
--- 节点 FightInfo 是"当前节点"权威源：PreFight 契约尚未开战可能滞后，Fighting 态 CurrentNode 不变 FightInfo 仍是当前战斗 fightId。#fightId单源
---@return table|nil PunishaarEnemy 行（EnemyModel/AttackAnima/NormalIdleAnima/AttackSFX）
function XUiPunishaarModelConfigResolver:GetEnemyCfgByFightId()
    local control = self._Control
    if not control then
        return nil
    end
    local gc = control.GameControl
    if not gc then
        return nil
    end
    local fightId = control:GetCurrentFightId()
    if not fightId or fightId == 0 then
        return nil
    end

    local fightCfg = gc:GetTablePunishaarFight(fightId, true)
    local enemyId = fightCfg and fightCfg.EnemyId
    if not enemyId then
        return nil
    end
    return gc:GetTablePunishaarEnemy(enemyId, true)
end

--- 取攻击特效 prefab 路径（统一三分支收口，取代 BattleEffectController._GetEffectPrefabPath 两路查询）。
--- ⚠️ 字段名 AttackSFX 命名误导（SFX=音效语义），实际配置的是视觉特效 prefab 路径——沿用既有字段名。#73
---@param ownerId number 攻击者 entityId（GlobalEntityIds.Player/Enemy 或卡牌 entityId）
---@param cardId number|nil 卡牌模板 Id（Card 分支必传；Player/Enemy 分支忽略）
---@return string|nil prefab 路径
function XUiPunishaarModelConfigResolver:GetAttackSFX(ownerId, cardId)
    local GlobalIds = STECustomEnum.GlobalEntityIds
    if ownerId == GlobalIds.Player then
        return nil
    end
    if ownerId == GlobalIds.Enemy then
        local enemyCfg = self:GetEnemyCfgByFightId()
        return enemyCfg and enemyCfg.AttackSFX
    end
    -- 卡牌：ownerId → cardId（由调用方 EffectPlayer 用 STEReader:GetCardId 转）→ PunishaarCardModel.AttackSFX
    if not cardId then
        XLog.Error(string.format("[ConfigResolver] GetAttackSFX: cardId nil ownerId=%s", tostring(ownerId)))
        return nil
    end
    local row = self:GetCardModelRow(cardId)
    local path = row and row.AttackSFX
    if not path or path == "" then
        XLog.Error(string.format("[ConfigResolver] GetAttackSFX: AttackSFX 空 cardId=%s ownerId=%s", tostring(cardId), tostring(ownerId)))
        return nil
    end
    return path
end

--- 缓存敌人攻击动画名（RefreshEnemyModel 时调，供 PlayEnemyAttack 读，避免每次攻击现查 enemyCfg）。#73
---@param anima string|nil
function XUiPunishaarModelConfigResolver:SetEnemyAttackAnima(anima)
    self._EnemyAttackAnima = anima
end

--- 取缓存的敌人攻击动画名（PlayEnemyAttack 调）。
---@return string|nil
function XUiPunishaarModelConfigResolver:GetEnemyAttackAnima()
    return self._EnemyAttackAnima
end

return XUiPunishaarModelConfigResolver
