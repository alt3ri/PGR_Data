--- 大巴扎战斗受伤飘字播放器（纯表现层，New 在 FlashTextRoot 上）。
--- 弱耦合：订阅 SpawnDamageNumber 事件(targetId, atkPerHit, attackTimes, isCrit, pos) → spawn+动画+回池，内部管定位/动画/池。
--- 玩家 pos 用内部锚点 PlayerDamageTxtPoint（独立，不知血条）；敌人 pos 由 coordinator 算好随 event 发送（不知模型）。
---@class XUiPunishaarDamageNumberPlayer : XUiNode
---@field UiPunishaarDamageTxt UnityEngine.GameObject 飘字预制体（FlashTextRoot 的 UiObject 自动绑定）
---@field PlayerDamageTxtPoint UnityEngine.Transform 玩家飘字定位锚点（FlashTextRoot 的 UiObject 自动绑定）
---@field private _DamagePool XPool 飘字对象池（双方复用单池，isDebug=false）
---@field private _ActiveNumbers XDictionary 在播飘字登记（grid→true，防双重归池；XDictionary 原位 Clear 复用）
---@field private _ForceRecycleList table _ForceRecycleAll 收集用 scratch（复用）
---@field private _OnGridFinishedHandler function grid 完播回调（预创建复用）
---@field protected _Control XPunishaarControl
local XUiPunishaarDamageNumberPlayer = XClass(XUiNode, "XUiPunishaarDamageNumberPlayer")

local XUiGridDamagePopTxt = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiFighting/XUiGridDamagePopTxt")
local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")

function XUiPunishaarDamageNumberPlayer:OnStart()
    self:_EnsurePool()
end

--- 幂等建池。FlashTextRoot 非战斗默认 Close → New 时 inactive → OnStart 可能不调，故 _OnSpawnDamageNumber 也调补建。
function XUiPunishaarDamageNumberPlayer:_EnsurePool()
    if self._DamagePool then
        return
    end
    self._ActiveNumbers = XTool.XDictionaryNew()
    self._ForceRecycleList = {}
    self._OnGridFinishedHandler = handler(self, self._OnGridFinished)
    if not self.UiPunishaarDamageTxt then
        XLog.Error("[DamageNumber] EnsurePool: UiPunishaarDamageTxt 未绑定（FlashTextRoot 的 UiObject 未引用 prefab？）")
        return
    end
    -- 校验 prefab 含 Enable Timeline：飘字回池依赖 PlayAnimation finCb 完播，缺则 grid 永不归池致池耗尽
    local animRoot = self.UiPunishaarDamageTxt.transform:Find("Animation")
    local enableTrans = animRoot and animRoot:FindTransform("Enable")
    if not enableTrans then
        XLog.Error("[DamageNumber] EnsurePool: prefab 缺 Animation/Enable Timeline（回池依赖完播 finCb，缺失则泄漏）")
        return
    end
    self.UiPunishaarDamageTxt.gameObject:SetActiveEx(false)
    self._DamagePool = XPool.New(
        function()
            local go = XUiHelper.Instantiate(self.UiPunishaarDamageTxt, self.Transform)
            return XUiGridDamagePopTxt.New(go, self)
        end,
        function(item) item:ResetForReuse() end,
        false)
end

---@return number, number 半径（0=不偏移）
function XUiPunishaarDamageNumberPlayer:_GetDamageTxtRandomRangeByTarget(target)
    if target == STECustomEnum.GlobalEntityIds.Player then
        return self:_GetPlayerHurtTxtRandomRange()
    end
    
    return self:_GetEnemyHurtTxtRandomRange()
end

--- 取敌人飘字 X、Y轴随机偏移半径（ClientConfig 配置，懒缓存）。多伤害同到达时避免重叠。
---@return number, number 半径（0=不偏移）
function XUiPunishaarDamageNumberPlayer:_GetEnemyHurtTxtRandomRange()
    if self._EnemyHurtPopupRandomRangeX == nil then
        self._EnemyHurtPopupRandomRangeX = XMVCA.XPunishaar:GetClientNumberByKey("EnemyHurtPopupRandomRangeX") or 0
    end

    if self._EnemyHurtPopupRandomRangeY == nil then
        self._EnemyHurtPopupRandomRangeY = XMVCA.XPunishaar:GetClientNumberByKey("EnemyHurtPopupRandomRangeY") or 0
    end
    
    return self._EnemyHurtPopupRandomRangeX, self._EnemyHurtPopupRandomRangeY
end

--- 取玩家飘字 X、Y轴随机偏移半径（ClientConfig 配置，懒缓存）。多伤害同到达时避免重叠。
---@return number, number 半径（0=不偏移）
function XUiPunishaarDamageNumberPlayer:_GetPlayerHurtTxtRandomRange()
    if self._PlayerHurtPopupRandomRangeX == nil then
        self._PlayerHurtPopupRandomRangeX = XMVCA.XPunishaar:GetClientNumberByKey("PlayerHurtPopupRandomRangeX") or 0
    end

    if self._PlayerHurtPopupRandomRangeY == nil then
        self._PlayerHurtPopupRandomRangeY = XMVCA.XPunishaar:GetClientNumberByKey("PlayerHurtPopupRandomRangeY") or 0
    end

    return self._PlayerHurtPopupRandomRangeX, self._PlayerHurtPopupRandomRangeY
end

---@return XPunishaarFightControl|nil
function XUiPunishaarDamageNumberPlayer:_GetFightControl()
    local control = self._Control
    local gameControl = control and control.GameControl
    return gameControl and gameControl.FightControl
end

---@param fightControl XPunishaarFightControl
function XUiPunishaarDamageNumberPlayer:BindFightControl(fightControl)
    if not fightControl then
        return
    end
    fightControl:AddEventListener(fightControl.EventIds.SpawnDamageNumber, self._OnSpawnDamageNumber, self)
end

function XUiPunishaarDamageNumberPlayer:UnbindFightControl()
    local fightControl = self:_GetFightControl()
    if fightControl then
        fightControl:RemoveEventListener(fightControl.EventIds.SpawnDamageNumber, self._OnSpawnDamageNumber, self)
    end
    self:_ForceRecycleAll()
end

--- SpawnDamageNumber 事件回调。玩家 pos 用 PlayerDamageTxtPoint（内部锚点）；敌人用 coordinator 发的 pos。
---@param targetId number 受击目标 entityId（Player/Enemy）
---@param atkPerHit number 单段伤害值
---@param attackTimes number 段数
---@param isCrit boolean|nil
---@param pos UnityEngine.Vector3|nil 敌人 FlashTextRoot-local 坐标（玩家 nil）
function XUiPunishaarDamageNumberPlayer:_OnSpawnDamageNumber(targetId, atkPerHit, attackTimes, isCrit, pos)
    self:_EnsurePool()
    if targetId == STECustomEnum.GlobalEntityIds.Player then
        if not self.PlayerDamageTxtPoint then
            XLog.Error("[DamageNumber] PlayerDamageTxtPoint 未绑定（FlashTextRoot 的 UiObject 未引用？）")
            return
        end
        pos = self.Transform:InverseTransformPoint(self.PlayerDamageTxtPoint.position)
    end
    if not self._DamagePool or not pos then
        return
    end
    
    local rangeX, rangeY = self:_GetDamageTxtRandomRangeByTarget(targetId)
    -- 显示中飘字总数上限（纯表现层数量约束，perf 护栏）：在显数达上限则丢后续段（按段丢），
    -- 不碰池（无论有无可复用对象）。0/缺省=不限。#并发飘字上限
    local cap = self:_GetMaxConcurrentDamagePop()

    for seg = 1, attackTimes do
        if cap > 0 and self._ActiveNumbers:GetCount() >= cap then
            break
        end
        local grid = self._DamagePool:GetItemFromPool()
        if not grid then
            XLog.Error("[DamageNumber] GetItemFromPool 返 nil（池异常）")
            return
        end
        self._ActiveNumbers:Add(grid, true)
        grid.Transform:SetParent(self.Transform, false)
        
        local xOffset = rangeX > 0 and CS.UnityEngine.Random.Range(-rangeX, rangeX) or 0
        local yOffset = rangeY > 0 and CS.UnityEngine.Random.Range(-rangeY, rangeY) or 0

        grid.Transform:SetLocalPosition(pos.x + xOffset, pos.y + yOffset, pos.z)
        grid:SetFinishedCallback(self._OnGridFinishedHandler)
        grid:Play(atkPerHit, isCrit)
    end
end

--- grid 完播回调：仅当仍登记在册才回池（防双重归池→别名灾难）。
---@param grid XUiGridDamagePopTxt
function XUiPunishaarDamageNumberPlayer:_OnGridFinished(grid)
    if self._ActiveNumbers:ContainsKey(grid) then
        self._ActiveNumbers:RemoveByKey(grid)
        self._DamagePool:ReturnItemToPool(grid)
    end
end

--- 强制回收在播飘字。不在 pairs 遍历中增删：先收集到 scratch 再逐个回池，最后 XDictionary:Clear 原位清。
function XUiPunishaarDamageNumberPlayer:_ForceRecycleAll()
    if not self._DamagePool or not self._ActiveNumbers then
        return
    end
    local list = self._ForceRecycleList
    local n = 0
    for grid in pairs(self._ActiveNumbers) do
        n = n + 1
        list[n] = grid
    end
    for i = 1, n do
        self._DamagePool:ReturnItemToPool(list[i])
        list[i] = nil
    end
    self._ActiveNumbers:Clear()
end

function XUiPunishaarDamageNumberPlayer:OnDestroy()
    self:_ForceRecycleAll()
    if self._DamagePool then
        self._DamagePool:Clear()
    end
end

--region 并发飘字上限（纯表现层数量约束，perf 护栏）#并发飘字上限

--- 显示中飘字总数上限（ClientConfig 懒缓存；0/缺省=不限）。在显数= _ActiveNumbers:GetCount()（XDictionary 自维护）。
---@return number
function XUiPunishaarDamageNumberPlayer:_GetMaxConcurrentDamagePop()
    if self._MaxConcurrentDamagePop == nil then
        self._MaxConcurrentDamagePop = XMVCA.XPunishaar:GetClientNumberByKey("PunishaarMaxConcurrentDamagePop") or 0
    end
    return self._MaxConcurrentDamagePop
end

--endregion

return XUiPunishaarDamageNumberPlayer
