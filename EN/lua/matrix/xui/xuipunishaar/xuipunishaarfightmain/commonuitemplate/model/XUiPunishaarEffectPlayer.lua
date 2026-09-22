--- 大巴扎战斗模型动画+特效播放器（纯表现层，取代 BattleEffectController）。
--- 职责：
---   * BindFightControl/UnbindFightControl  订阅/注销 AttackEffect 事件（自驱，PanelFighting:OnEnable/OnDisable 经 ModelShow 转发）
---   * _OnAttackEffect → Drain payload → per (owner,target) _LaunchEffect 投射飞弹
---   * _GetTransformForEntity(entityId)     entityId→Transform（Player/Enemy/Card 分支，Card 内含 STEReader:GetCardIndex 转 slotIndex）
---   * _GetPoolForPath(path)                对象池按 prefab 路径分组（_PoolDict[path]→XPool + _PrefabCache + _ActiveEffects + _EffectAnchorCache）
---   * _GetOrNewEffectAnchor(ownerId)       发动者角色挂点兄弟 EffectAnchor（场景节点，缓存避免重复 Find/New）
--- 池/生命周期范式对齐 BattleEffectController 既有（XPool + _PrefabCache + _ActiveEffects + _EffectAnchorCache），整段搬运。#73
---@class XUiPunishaarEffectPlayer : XUiNode
---@field private _ModelPool XUiPunishaarModelPool
---@field private _ConfigResolver XUiPunishaarModelConfigResolver
---@field private _AnimationPlayer XUiPunishaarAnimationPlayer
---@field protected _Control XPunishaarControl
---@field private _PoolDict table<string, XPool> 按 prefab 路径分组对象池
---@field private _PrefabCache table<string, CS.UnityEngine.Object> prefab 缓存（避免重复 Load）
---@field private _PayloadBuf XTool.XList payload 接收列表（复用，不每帧 new）
---@field private _ActiveEffects table<XUiPunishaarBattleEffect, XPool> 飞行中特效 -> 所属 pool（OnDisable 强制回收用）
---@field private _EffectAnchorCache table<number, UnityEngine.Transform> 动态创建的 EffectAnchor 缓存（ownerId -> Transform）
local XUiPunishaarEffectPlayer = XClass(XUiNode, "XUiPunishaarEffectPlayer")

local XUiPunishaarBattleEffect = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiPunishaarBattleEffect")
local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")

local EFFECT_ANCHOR_NAME = "EffectAnchor"

--- XUiNode 生命周期钩子：New 后框架调（_Control 由框架从 parent 链注入，不业务传）。
function XUiPunishaarEffectPlayer:OnStart()
    self._PoolDict = {}
    self._PrefabCache = {}
    self._PayloadBuf = XTool.XListNew()
    self._ActiveEffects = {}
    self._EffectAnchorCache = {}
end

--- sibling refs downward 注入（ModelShow:OnStart 创建后调，非 Ctor 传、非 upward 访问）。
---@param modelPool XUiPunishaarModelPool
---@param configResolver XUiPunishaarModelConfigResolver
---@param animationPlayer XUiPunishaarAnimationPlayer
function XUiPunishaarEffectPlayer:SetSiblings(modelPool, configResolver, animationPlayer)
    self._ModelPool = modelPool
    self._ConfigResolver = configResolver
    self._AnimationPlayer = animationPlayer
end

--- 取 FightControl（每次重读，不缓存——防 ExitFight 释放后 stale ref，对齐原 BattleEffectController:_GetFightControl 范式）
---@return XPunishaarFightControl|nil
function XUiPunishaarEffectPlayer:_GetFightControl()
    local control = self._Control
    local gameControl = control and control.GameControl
    return gameControl and gameControl.FightControl
end

function XUiPunishaarEffectPlayer:OnDestroy()
    -- asset 由模块 Loader 管理生命周期（XControl:GetLoader → XLoaderUtil，模块级），OnDestroy 只断引用不手动 Unload
    self._PrefabCache = nil
end

--region FightControl 订阅/注销

--- FightControl 就绪后由 ModelShow:BindFightControl 转发调用，注册 AttackEffect 监听。
--- OnEnable 阶段 FightControl 未创建（EnterFight 在 PanelFighting:OnEnable 后续），
---   故拆出此接口供 EnterFight 后显式调用，确保注册时 FightControl 已就绪。#73
---@param fightControl XPunishaarFightControl
function XUiPunishaarEffectPlayer:BindFightControl(fightControl)
    if not fightControl then
        return
    end
    fightControl:AddEventListener(fightControl.EventIds.AttackEffect, self._OnAttackEffect, self)
end

--- PanelFighting:OnDisable 经 ModelShow:UnbindFightControl 转发调用，注销监听 + 强制回收飞行中特效。
function XUiPunishaarEffectPlayer:UnbindFightControl()
    local fightControl = self:_GetFightControl()
    if fightControl then
        fightControl:RemoveEventListener(fightControl.EventIds.AttackEffect, self._OnAttackEffect, self)
    end
    self:_ForceRecycleAll()
end

--endregion

--- AttackEffect 事件回调：Drain 本帧 payload，逐条 (owner→target) 投射特效。
function XUiPunishaarEffectPlayer:_OnAttackEffect()
    local fightControl = self:_GetFightControl()
    if not fightControl or not fightControl.STEControl then
        return
    end
    self._PayloadBuf:Clear()
    local count = fightControl.STEControl:DrainAttackEffectPayloads(self._PayloadBuf)
    if count <= 0 then
        return
    end
    for i = 1, count do
        local item = self._PayloadBuf:GetValueByIndex(i)
        if item then
            self:_LaunchEffect(item.ownerId, item.targetId)
        end
    end
end

---@param ownerId number 攻击者 entityId
---@param targetId number 目标 entityId
function XUiPunishaarEffectPlayer:_LaunchEffect(ownerId, targetId)
    -- 发射中特效总数上限（纯表现层数量约束，perf 护栏）：所有路径在飞数之和达上限则丢本次发射，
    -- 不碰池（无论有无可复用对象）。0/缺省=不限。#并发特效上限
    local cap = self:_GetMaxConcurrentEffect()
    if cap > 0 and self:_CountInFlightEffects() >= cap then
        return
    end
    local startTrans = self:_GetTransformForEntity(ownerId)
    if not startTrans then
        XLog.Error(string.format("[BattleEffect] _LaunchEffect 跳过: owner=%s startTrans nil（挂点获取失败）", tostring(ownerId)))
        return
    end
    -- 起终点世界坐标标量（贝塞尔标量化，直传 Play 6 标量；GetPosition 标量 API 避 .position 装箱 #81 #向量GC）
    local startX, startY, startZ = startTrans:GetPosition()
    local endX, endY, endZ
    if ownerId == STECustomEnum.GlobalEntityIds.Enemy then
        -- 敌人攻击特殊处理：Player 无实体，落点=所有卡牌模型坐标中心点（与 targetId 无关）
        local cx, cy, cz = self._ModelPool:GetPlayerCenterPos()
        if cx then
            endX, endY, endZ = cx, cy, cz
        end
    else
        local endTrans = self:_GetTransformForEntity(targetId)
        if endTrans then
            endX, endY, endZ = endTrans:GetPosition()
        end
    end
    if not endX then
        XLog.Error(string.format("[BattleEffect] _LaunchEffect 跳过: owner=%s target=%s endPos nil（落点获取失败）",
                tostring(ownerId), tostring(targetId)))
        return
    end
    local effectAnchor = self:_GetOrNewEffectAnchor(ownerId)
    if not effectAnchor then
        XLog.Error(string.format("[BattleEffect] _LaunchEffect 跳过: owner=%s EffectAnchor 获取失败", tostring(ownerId)))
        return
    end
    -- prefab 路径收口到 ConfigResolver:GetAttackSFX（Card 分支需 cardId，由 STEReader:GetCardId 转）
    local cardId = self:_GetCardIdByEntity(ownerId)
    local prefabPath = self._ConfigResolver:GetAttackSFX(ownerId, cardId)
    if not prefabPath or prefabPath == "" then
        XLog.Error(string.format("[BattleEffect] _LaunchEffect 跳过: owner=%s prefabPath 空（AttackSFX 未配置）", tostring(ownerId)))
        return
    end
    local pool = self:_GetPoolForPath(prefabPath)
    if not pool then
        return  -- _GetPoolForPath 内已 XLog.Error
    end
    local effect = pool:GetItemFromPool()
    if not effect then
        XLog.Error(string.format("[BattleEffect] _LaunchEffect 跳过: owner=%s GetItemFromPool 返 nil path=%s", tostring(ownerId), tostring(prefabPath)))
        return
    end
    self._ActiveEffects[effect] = pool
    -- reparent 到发动者 EffectAnchor（池 createFunc 挂 ModelPool 根 Transform，取后 reparent 到角色挂点兄弟）
    effect.Transform:SetParent(effectAnchor, false)
    -- 敌人攻击时播敌人攻击动画（卡牌走 CardAttackAnim 通道，敌人对称在此播）#73
    if ownerId == STECustomEnum.GlobalEntityIds.Enemy then
        self._AnimationPlayer:PlayEnemyAttack(true)
    end
    -- VFX 时长按当前倍速缩放（VFX 速度跟随倍速，与逻辑层延时 landTick 同步）：
    -- 逻辑延时实际时间 = delayFrames*MsPerLogicFrame/speed = BattleEffectDuration/speed；VFX duration 同此式
    local fc = self:_GetFightControl()
    local speed = (fc and fc.SpeedController and fc.SpeedController:GetSpeed()) or 1
    if speed <= 0 then speed = 1 end  -- 钳制下限：0 在 Lua 是 truthy 不走 or 1，显式兜底防 baseDur/speed 除零→inf→Tween 永不归池泄漏
    local baseDur = XMVCA.XPunishaar:GetClientNumberByKey("BattleEffectDuration", 1)
    local duration = (baseDur and baseDur > 0) and (baseDur / speed) or (0.5 / speed)
    effect:Play(startX, startY, startZ, endX, endY, endZ, duration, function()
        -- 守卫：仅当仍登记在册才归池（防 ForceStop 触发/异步触发回调致同一 effect 双重归池→别名灾难）
        if self._ActiveEffects[effect] then
            self._ActiveEffects[effect] = nil
            pool:ReturnItemToPool(effect)
        end
    end)
end

--- 取（或新建）某 prefab 路径对应的对象池（按路径分组）。
---@param path string prefab Resources 路径
---@return XPool|nil
function XUiPunishaarEffectPlayer:_GetPoolForPath(path)
    if not path then
        return nil
    end
    local pool = self._PoolDict[path]
    if pool then
        return pool
    end
    local asset = self._PrefabCache[path]
    if not asset then
        -- 用模块 Loader 加载（XControl:GetLoader 返回 XLoaderUtil，替代 Resources.Load）#73
        asset = self._Control:GetLoader():Load(path)
        if XTool.UObjIsNil(asset) then
            XLog.Error(string.format("[XUiPunishaarEffectPlayer] 特效 asset 加载失败 path=%s", tostring(path)))
            return nil
        end
        self._PrefabCache[path] = asset
    end
    pool = XPool.New(function()
        -- 挂模型根 Transform（ModelPool:GetModelRootTransform 返 ModelShow.Transform，非 UI 层级），
        -- 避免场景特效 prefab 在 UI Canvas 下初始化异常/不可见 #73
        local rootTrans = self._ModelPool:GetModelRootTransform()
        local parent = rootTrans  -- 飞弹挂点根（ModelShow.Transform=UiModelGo，场景层级非 UI Canvas）
        local go = CS.UnityEngine.Object.Instantiate(asset, parent)
        -- 改 Layer 为 UiNear（递归含子节点），否则特效无法被 UiNearCamera 捕获渲染 #73
        go:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer("UiNear"))
        go:SetActiveEx(false)
        return XUiPunishaarBattleEffect.New(go, self)
    end, false)
    self._PoolDict[path] = pool
    return pool
end

--- entityId → 模型挂点 Transform（避免 Lua Vector3 拷贝：直接返 Transform 引用，SetTransform 走 C# 侧）。
--- 卡牌：entityId → slotIndex（STEReader.GetCardIndex）→ ModelPool:GetCardModelTransform(slot)
--- 敌人：GlobalEntityIds.Enemy → ModelPool:GetEnemyModelTransform
--- 玩家：GlobalEntityIds.Player → ModelPool:GetFirstCardModelTransform（弃重心算，避免 Vector3 拷贝）
---@param entityId number
---@return UnityEngine.Transform|nil
function XUiPunishaarEffectPlayer:_GetTransformForEntity(entityId)
    local GlobalIds = STECustomEnum.GlobalEntityIds

    if entityId == GlobalIds.Player then
        local trans = self._ModelPool:GetFirstCardModelTransform()
        if not trans then
            XLog.Error(string.format("[BattleEffect] _GetTransformForEntity: Player 锚点 nil（无已加载卡牌）entityId=%s", tostring(entityId)))
        end
        return trans
    end
    if entityId == GlobalIds.Enemy then
        local trans = self._ModelPool:GetEnemyModelTransform()
        if not trans then
            XLog.Error(string.format("[BattleEffect] _GetTransformForEntity: Enemy 挂点 nil entityId=%s", tostring(entityId)))
        end
        return trans
    end
    -- 卡牌：slotIndex = STEReader.GetCardIndex(entityId)（紧凑一维序）
    local fightControl = self:_GetFightControl()
    local reader = fightControl and fightControl.STEReader
    local slotIndex = reader and reader:GetCardIndex(entityId)
    if not slotIndex or slotIndex <= 0 then
        XLog.Error(string.format("[BattleEffect] _GetTransformForEntity: slotIndex 非法 entityId=%s slot=%s", tostring(entityId), tostring(slotIndex)))
        return nil
    end
    local trans = self._ModelPool:GetCardModelTransform(slotIndex)
    if not trans then
        XLog.Error(string.format("[BattleEffect] _GetTransformForEntity: GetCardModelTransform nil entityId=%s slot=%s", tostring(entityId), tostring(slotIndex)))
    end
    return trans
end

--- entityId → cardId（供 ConfigResolver:GetAttackSFX Card 分支用，Player/Enemy 返 nil）。
---@param entityId number
---@return number|nil
function XUiPunishaarEffectPlayer:_GetCardIdByEntity(entityId)
    local fightControl = self:_GetFightControl()
    local reader = fightControl and fightControl.STEReader
    return reader and reader:GetCardId(entityId)
end

--- 发动者角色挂点的兄弟 EffectAnchor（场景节点，非 UI）。
--- prefab 未提供时动态 New GameObject 挂角色挂点父级下（兄弟）；缓存避免重复 Find/New。
---@param ownerId number
---@return UnityEngine.Transform|nil
function XUiPunishaarEffectPlayer:_GetOrNewEffectAnchor(ownerId)
    local cached = self._EffectAnchorCache[ownerId]
    if not XTool.UObjIsNil(cached) then
        return cached
    end
    local startTrans = self:_GetTransformForEntity(ownerId)
    if not startTrans then
        return nil
    end
    local parent = startTrans.parent
    if not parent then
        return startTrans  -- 无父，挂自身（兜底）
    end
    local anchor = parent:Find(EFFECT_ANCHOR_NAME)
    if XTool.UObjIsNil(anchor) then
        local go = CS.UnityEngine.GameObject(EFFECT_ANCHOR_NAME)
        go.transform:SetParent(parent, false)
        anchor = go.transform
    end
    self._EffectAnchorCache[ownerId] = anchor
    return anchor
end

--- UnbindFightControl 时强制回收飞行中特效（中断 + 归池）。
function XUiPunishaarEffectPlayer:_ForceRecycleAll()
    if not self._ActiveEffects then
        return
    end
    for effect, pool in pairs(self._ActiveEffects) do
        -- 先摘登记再 ForceStop：防 ForceStop 同步触发 Play 完成回调时回调仍见 _ActiveEffects[effect]→归池，
        -- 回来 _ForceRecycleAll 再 ReturnItemToPool = 双重归池→别名灾难
        self._ActiveEffects[effect] = nil
        effect:ForceStop()
        pool:ReturnItemToPool(effect)
    end
    self._ActiveEffects = {}
end

--region 并发特效上限（纯表现层数量约束，perf 护栏）#并发特效上限

--- 所有路径在飞特效总数（XPool:UsingCount 之和；零新状态，复用 XPool 自有账）。
---@return number
function XUiPunishaarEffectPlayer:_CountInFlightEffects()
    local total = 0
    for _, pool in pairs(self._PoolDict or {}) do
        total = total + pool:UsingCount()
    end
    return total
end

--- 发射中特效总数上限（ClientConfig 懒缓存；0/缺省=不限）。
---@return number
function XUiPunishaarEffectPlayer:_GetMaxConcurrentEffect()
    if self._MaxConcurrentEffect == nil then
        self._MaxConcurrentEffect = XMVCA.XPunishaar:GetClientNumberByKey("PunishaarMaxConcurrentEffect") or 0
    end
    return self._MaxConcurrentEffect
end

--endregion

return XUiPunishaarEffectPlayer
