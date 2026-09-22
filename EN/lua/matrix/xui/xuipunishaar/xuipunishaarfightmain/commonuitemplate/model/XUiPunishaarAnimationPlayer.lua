--- 大巴扎战斗模型动画播放器（纯表现层）。
--- 职责：
---   * PlayCardAttack(slot, cardId, fromBegin)  卡牌攻击动画（查 ConfigResolver 取 AttackAnima，调 ModelPool panel:PlayAnimaCross）
---   * PlayCardIdle(slot, cardId)               卡牌 Idle 动画
---   * PlayEnemyAttack(fromBegin)             敌人攻击动画（读 ConfigResolver 缓存的 _EnemyAttackAnima）
---   * BindFightControl/UnbindFightControl      订阅/注销 CardAttackAnim 事件（自驱，PanelFighting 不再管动画）
--- 自驱订阅 CardAttackAnim：FightControl 就绪后由 ModelShow:BindFightControl 转发调用，OnEnable 阶段不订阅
---   （FightControl 在 PanelFighting:OnEnable 的 EnterFight 后才就绪）。#73
--- 逻辑搬运自 XUiPunishaarModelShow:PlayAttackAnima/PlayIdleAnima/PlayEnemyAttackAnima +
---   XUiPunishaarFightMainPanelFighting:_PlayAttackAnim，不改变语义，只收口职责。
---@class XUiPunishaarAnimationPlayer : XUiNode
---@field private _ModelPool XUiPunishaarModelPool
---@field private _ConfigResolver XUiPunishaarModelConfigResolver
---@field protected _Control XPunishaarControl
---@field private _TickDoneCardsBuf table 卡牌激活缓冲（FillTickDoneCards 复用，不每帧 new）
local XUiPunishaarAnimationPlayer = XClass(XUiNode, "XUiPunishaarAnimationPlayer")

--- XUiNode 生命周期钩子：New 后框架调（_Control 由框架从 parent 链注入，不业务传）。
function XUiPunishaarAnimationPlayer:OnStart()
    self._TickDoneCardsBuf = nil
end

--- sibling refs downward 注入（ModelShow:OnStart 创建后调，非 Ctor 传、非 upward 访问）。
---@param modelPool XUiPunishaarModelPool
---@param configResolver XUiPunishaarModelConfigResolver
function XUiPunishaarAnimationPlayer:SetSiblings(modelPool, configResolver)
    self._ModelPool = modelPool
    self._ConfigResolver = configResolver
end

--- 取 FightControl（每次重读不缓存——防 ExitFight 释放后 stale ref）
---@return XPunishaarFightControl|nil
function XUiPunishaarAnimationPlayer:_GetFightControl()
    local control = self._Control
    local gameControl = control and control.GameControl
    return gameControl and gameControl.FightControl
end

--- 卡牌攻击动画（slot 默认 1，fromBegin=true 打断重播，播完由动画状态机自动过渡回 Idle #71）。
---@param slotIndex number|nil 卡牌挂点索引 1..N（默认 1）
---@param cardId number
---@param fromBegin boolean|nil true=打断重播
function XUiPunishaarAnimationPlayer:PlayCardAttack(slotIndex, cardId, fromBegin)
    local panel = self._ModelPool:GetCardModelPanel(slotIndex or 1)
    if not panel then
        return
    end
    local row = self._ConfigResolver:GetCardModelRow(cardId)
    if row and not string.IsNilOrEmpty(row.AttackAnima) then
        panel:PlayAnimaCross(row.AttackAnima, fromBegin)
    end
end

--- 播 Idle 动画（主动切回待机，供状态切换/卡牌刷新时调）#71
---@param slotIndex number|nil 卡牌挂点索引 1..N（默认 1）
---@param cardId number
function XUiPunishaarAnimationPlayer:PlayCardIdle(slotIndex, cardId)
    local panel = self._ModelPool:GetCardModelPanel(slotIndex or 1)
    if not panel then
        return
    end
    local row = self._ConfigResolver:GetCardModelRow(cardId)
    if row and not string.IsNilOrEmpty(row.NormalIdleAnima) then
        panel:PlayAnimaCross(row.NormalIdleAnima)
    end
end

--- 敌人攻击动画（fromBegin=true 打断重播，播完由动画状态机自动过渡回 Idle）。
--- AttackAnima 由 RefreshEnemyModel 时 ConfigReader 缓存（enemyCfg.AttackAnima），避免每次攻击现查。#73
---@param fromBegin boolean|nil true=从头播打断重播
function XUiPunishaarAnimationPlayer:PlayEnemyAttack(fromBegin)
    local panel = self._ModelPool:GetEnemyModelPanel()
    if not panel then
        return
    end
    local anima = self._ConfigResolver:GetEnemyAttackAnima()
    if not string.IsNilOrEmpty(anima) then
        panel:PlayAnimaCross(anima, fromBegin)
    end
end

--- FightControl 就绪后由 ModelShow:BindFightControl 转发调用，注册 CardAttackAnim 监听。
---@param fightControl XPunishaarFightControl
function XUiPunishaarAnimationPlayer:BindFightControl(fightControl)
    if not fightControl then
        return
    end
    fightControl:AddEventListener(fightControl.EventIds.CardAttackAnim, self._OnCardAttackAnim, self)
end

--- PanelFighting:OnDisable 经 ModelShow:UnbindFightControl 转发调用，注销 CardAttackAnim 监听。
function XUiPunishaarAnimationPlayer:UnbindFightControl()
    local fightControl = self:_GetFightControl()
    if fightControl then
        fightControl:RemoveEventListener(fightControl.EventIds.CardAttackAnim, self._OnCardAttackAnim, self)
    end
end

--- CardAttackAnim 事件回调：FillTickDoneCards 取本帧激活卡 → 逐卡 PlayCardAttack(fromBegin=true 打断重播）#71
function XUiPunishaarAnimationPlayer:_OnCardAttackAnim()
    local fightControl = self:_GetFightControl()
    local reader = fightControl and fightControl.STEReader
    if not reader then
        return
    end
    if not self._TickDoneCardsBuf then
        self._TickDoneCardsBuf = {}
    end
    for i = #self._TickDoneCardsBuf, 1, -1 do
        self._TickDoneCardsBuf[i] = nil
    end
    local count = reader:FillTickDoneCards(self._TickDoneCardsBuf)
    for i = 1, count do
        local uid = self._TickDoneCardsBuf[i]
        local cardId = reader:GetCardId(uid)
        local slotIndex = reader:GetCardIndex(uid)
        if cardId and slotIndex then
            self:PlayCardAttack(slotIndex, cardId, true)
        end
    end
end

return XUiPunishaarAnimationPlayer
