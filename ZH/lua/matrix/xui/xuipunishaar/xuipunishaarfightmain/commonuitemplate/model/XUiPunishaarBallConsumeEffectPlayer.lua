--[[
-- 消球动效动画队列控制器（替代旧 cursor 方案 #消球动效动画队列）：
-- STE 帧末 drain 球动画 step 队列（ConsumeBall/ProduceBall）→ UI EnqueueStep + StartPlay。
-- FIFO 串行播放，每步操作当前 UI grid（消球取队头该色球位+隐藏 grid/产球挤头），全播完 Refresh 对齐 STE 最终态。
-- 旧 cursor 方案"始终错位"根因：pairs 无序 + UI grid 上一帧态 ≠ STE 当前态 + 产球挤序不感知；
-- 队列每步增量操作 grid 解：UI grid 始终对齐 STE 每步后的状态。
-- 池化 3 色 trail GO（XUiHelper.Tween 移动），预热走 Little's Law，OnDisable ForceStop（清队列+回池+Refresh）。
]]

local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")

---@class XUiPunishaarBallAnimTrail 消球 trail（消球步 spawn 的飞行特效实例，跨 Tween 回调持有 _ActiveTrails #消球动效动画队列）
---@field go UnityEngine.GameObject trail GO（池化，SetActiveEx 显隐）
---@field color number BallColor（回池按色找 pool）
---@field gridRef XUiGridBattleBall|nil 被消球 grid（delay 结束隐藏；nil=无 trail 路径）
---@field timerId number Tween 句柄（单 timer 无切换，UnSchedule 通用）
---@field gridHidden boolean grid 是否已隐藏（onRefresh 一次性 flag）
---@field activeIndex number 在 _ActiveTrails 的位置（O(1) 移除）

local XUiPunishaarBallConsumeEffectPlayer = XClass(XUiNode, "XUiPunishaarBallConsumeEffectPlayer")

-- 颜色→prefab key 映射（文件 scope 不读 XMVCA，运行时 OnStart 内初始化）
local ColorToPrefabKey

local DEFAULT_DURATION = 1 -- 移动时长保底（秒；配置 BallEffectFlyAnimTime 缺时用；XUiHelper.Tween 接收秒）#消球动效动画队列
local DEFAULT_DELAY = 0.1  -- trail 球位停留保底（秒；配置 BallEffectStayAnimTime 缺时用；spawn 后 delay 不动+球 grid 还显 → delay 结束球消失+trail 飞）

function XUiPunishaarBallConsumeEffectPlayer:OnStart()
    local parent = self.Parent  -- XUiPunishaarFightMainPanelFighting
    self._PanelBattleBall = parent.PanelBattleBall
    self._PanelBattleCardList = parent.PanelBattleCardList
    self._Pools = {}           -- color → XPool
    ---@type XUiPunishaarBallAnimTrail[]
    self._ActiveTrails = {}    -- 活跃 trail 列表
    self._ActiveCount = 0
    self._TrailPool = {}       -- trail table 池（复用 trail table 避每球新建 #消球动效动画队列）
    -- 动画队列字段（替代旧 _ConsumeCursor）#消球动效动画队列
    ---@type XUiPunishaarBallAnimStep[]
    self._StepQueue = {}       -- FIFO step 列表
    self._StepCount = 0
    self._CurStepIndex = 0
    self._IsPlaying = false

    -- 颜色→prefab key 映射（运行时初始化，STECustomEnum.BallColor: Red=1/Yellow=2/Blue=3）
    local ballColor = STECustomEnum.BallColor
    ColorToPrefabKey = {
        [ballColor.Red] = "EffectTrailPink",
        [ballColor.Yellow] = "EffectTrailYellow",
        [ballColor.Blue] = "EffectTrailBlue",
    }

    -- 3 色各建池（Instantiate 自 prefab，挂 PanelBallConsumeEffectRoot 下）
    for color, prefabKey in pairs(ColorToPrefabKey) do
        local prefab = self[prefabKey]
        if prefab then
            self._Pools[color] = XPool.New(
                function()
                    local go = XUiHelper.Instantiate(prefab, self.Transform)
                    go.gameObject:SetActiveEx(false)
                    return go
                end,
                function(item)
                    item.gameObject:SetActiveEx(false)
                end,
                false  -- isDebug=false（GameObject 不能开 debug 检测，XPool 会 table.copy 致问题）
            )
        end
    end
end

function XUiPunishaarBallConsumeEffectPlayer:OnEnable()
    -- 订阅由 PanelFighting:OnEnable 统一管理；预热 _RefreshPreheat 内逐层取 FightControl
    -- （OnEnable 早于 PanelFighting:OnEnable EnterFight，FightControl nil 早退，PanelFighting:OnEnable 再调 #核实2）
    self:_RefreshPreheat()
end

--- 预热刷新（OnEnable / PanelFighting:OnEnable 调）
function XUiPunishaarBallConsumeEffectPlayer:_RefreshPreheat()
    local fightControl = self._Control and self._Control.GameControl and self._Control.GameControl.FightControl
    if not fightControl then
        return  -- FightControl 未就绪（OnEnable 早于 EnterFight；PanelFighting:OnEnable EnterFight 后再调）
    end
    local preheatByColor = self:CalcPreheatByColor(fightControl)
    for color, preheat in pairs(preheatByColor) do
        local pool = self._Pools[color]
        if pool then
            -- Preload 补足到 preheat（内部算 need=preheat-current，current>=preheat 不 Create 避免冗余实例化 #核实:91）
            pool:Preload(preheat)
        end
    end
end

function XUiPunishaarBallConsumeEffectPlayer:OnDisable()
    self:ForceStop()
end

function XUiPunishaarBallConsumeEffectPlayer:OnDestroy()
    self:ForceStop()
end

--- 入队一步（STEControl 帧末 dispatch BallAnimSteps，UI 回调遍历调）。#消球动效动画队列
---@param actionType number STECustomEnum.BallAnimStepType
---@param cardUid number
---@param color number BallColor
---@param count number
function XUiPunishaarBallConsumeEffectPlayer:EnqueueStep(actionType, cardUid, color, count)
    self._StepCount = self._StepCount + 1
    ---@type XUiPunishaarBallAnimStep
    local step = self._StepQueue[self._StepCount]
    if not step then
        step = {}
        self._StepQueue[self._StepCount] = step
    end
    step.actionType = actionType
    step.cardUid = cardUid
    step.color = color
    step.count = count
end

--- 开始播放（UI 回调 EnqueueStep 完后调；播放中追加不重启，_PlayNext 在 tween 完回调里继续）。#消球动效动画队列
function XUiPunishaarBallConsumeEffectPlayer:StartPlay()
    if self._IsPlaying then
        return
    end
    if self._StepCount == 0 then
        return
    end
    self._IsPlaying = true
    self._CurStepIndex = 0
    self:_PlayNext()
end

--- 播放下一步
function XUiPunishaarBallConsumeEffectPlayer:_PlayNext()
    self._CurStepIndex = self._CurStepIndex + 1
    if self._CurStepIndex > self._StepCount then
        -- 全播完：全量 Refresh 对齐 STE 最终态 + 清队列
        self._PanelBattleBall:Refresh()
        self:_ClearQueue()
        self._IsPlaying = false
        return
    end
    local step = self._StepQueue[self._CurStepIndex]
    if step.actionType == STECustomEnum.BallAnimStepType.ConsumeBall then
        self:_PlayConsumeStep(step)
    elseif step.actionType == STECustomEnum.BallAnimStepType.ProduceBall then
        self:_PlayProduceStep(step)
    else
        self:_OnStepFinished()
    end
end

--- 消球步：spawn trail 在球位 → 单 Tween（delay 阶段不动+球 grid 还显 → delay 结束隐藏 grid + 标量 lerp 朝卡）。#消球动效动画队列
--- 单 Tween（替代 ScheduleOnce+Tween 双 timer）：1 timer/trail 无 id 切换（健壮）；gridHidden flag 一次性隐藏；
--- 标量 lerp + transform:SetPosition 零 Vector3 GC（#90 范式）。
function XUiPunishaarBallConsumeEffectPlayer:_PlayConsumeStep(step)
    local positions, grids = self._PanelBattleBall:RemoveBallsFromFront(step.color, step.count)
    local endPos = self._PanelBattleCardList:GetCardCenterPosition(step.cardUid)
    local ballCount = #positions
    -- 无 trail 路径（无球/卡找不到/pool 缺）：立即隐藏 grid（无 delay 阶段）
    if ballCount == 0 or not endPos then
        self:_HideGrids(grids, ballCount)
        self:_OnStepFinished()
        return
    end

    local duration = XMVCA.XPunishaar:GetClientNumberByKey("BallEffectFlyAnimTime")  -- 秒（XUiHelper.Tween 接收秒）
    if not XTool.IsNumberValidEx(duration) then
        duration = DEFAULT_DURATION
    end
    duration = math.max(0.01, duration)  -- 下限兜底（防配置负值致 Tween 永不结束→队列卡死 #149审M2）

    local pool = self._Pools[step.color]
    if not pool then
        self:_HideGrids(grids, ballCount)
        self:_OnStepFinished()
        return
    end

    -- 倍速：逐层取 FightControl.SpeedController（XUiNode 持 self._Control，不需上层注入 #核实2）；2x 时 delay+duration 减半
    local fightControl = self._Control and self._Control.GameControl and self._Control.GameControl.FightControl
    local speed = (fightControl and fightControl.SpeedController and fightControl.SpeedController:GetSpeed()) or 1
    if speed < 1 then
        speed = 1
    end
    duration = duration / speed
    local delay = XMVCA.XPunishaar:GetClientNumberByKey("BallEffectStayAnimTime")  -- 秒（配置；DEFAULT_DELAY 保底，#152 约定 key）
    if not XTool.IsNumberValidEx(delay) then
        delay = DEFAULT_DELAY
    end
    delay = math.max(0.01, delay)  -- 下限兜底
    delay = delay / speed
    local totalDuration = delay + duration
    local delayFraction = delay / totalDuration  -- Tween progress 阈值：t<delayFraction=delay 阶段，t>=delayFraction=lerp 阶段

    -- 终点标量缓存（减 Vector3 装箱 GC #90）
    local endX, endY, endZ = endPos.x, endPos.y, endPos.z

    local remaining = ballCount
    for i = 1, ballCount do
        local go = pool:GetItemFromPool()
        if go then
            go.gameObject:SetActiveEx(true)
            local startPos = positions[i]
            local startX, startY, startZ = startPos.x, startPos.y, startPos.z
            go.transform:SetPosition(startX, startY, startZ)  -- 标量设位（零 GC）
            ---@type XUiPunishaarBallAnimTrail
            local trail = self:_GetTrail()
            trail.go = go
            trail.color = step.color
            trail.gridRef = grids[i]
            trail.gridHidden = false
            trail.timerId = XUiHelper.Tween(totalDuration, function(t)
                if XTool.UObjIsNil(go) then
                    return true  -- go 已销毁，中断（仍调 onFinish）
                end
                if t < delayFraction then
                    -- delay 阶段：trail 在球位不动（球 grid 还显）
                else
                    -- delay 结束：隐藏球 grid（一次性）+ 标量 lerp 朝卡
                    if not trail.gridHidden then
                        trail.gridHidden = true
                        if trail.gridRef and not XTool.UObjIsNil(trail.gridRef.GameObject) then
                            trail.gridRef.GameObject:SetActiveEx(false)
                        end
                    end
                    local moveT = (t - delayFraction) / (1 - delayFraction)
                    go.transform:SetPosition(
                            startX + (endX - startX) * moveT,
                            startY + (endY - startY) * moveT,
                            startZ + (endZ - startZ) * moveT)
                end
            end, function()
                trail.timerId = nil
                if not XTool.UObjIsNil(go) then
                    pool:ReturnItemToPool(go)
                end
                self:_RemoveTrail(trail)
                self:_ReturnTrail(trail)
                remaining = remaining - 1
                if remaining <= 0 then
                    self:_OnStepFinished()  -- 本步所有 trail 完播 → 下一步
                end
            end)
            trail.activeIndex = self._ActiveCount + 1
            self._ActiveCount = self._ActiveCount + 1
            self._ActiveTrails[self._ActiveCount] = trail
        else
            -- 无 trail：立即隐藏 grid（无 delay 阶段）
            local grid = grids[i]
            if grid and not XTool.UObjIsNil(grid.GameObject) then
                grid.GameObject:SetActiveEx(false)
            end
            remaining = remaining - 1
        end
    end
    if remaining <= 0 then
        self:_OnStepFinished()
    end
end

--- 从 _ActiveTrails O(1) 移除 trail（swap 末尾 + 更新被换 trail 的 activeIndex）#消球动效动画队列
function XUiPunishaarBallConsumeEffectPlayer:_RemoveTrail(trail)
    local idx = trail.activeIndex
    local activeCount = self._ActiveCount
    if idx == activeCount then
        self._ActiveTrails[idx] = nil
    else
        local last = self._ActiveTrails[activeCount]
        self._ActiveTrails[idx] = last
        last.activeIndex = idx  -- 更新被换 trail 的 index
        self._ActiveTrails[activeCount] = nil
    end
    self._ActiveCount = activeCount - 1
end

--- 从 trail 池取（避免每球新建 trail table #消球动效动画队列）
function XUiPunishaarBallConsumeEffectPlayer:_GetTrail()
    local pool = self._TrailPool
    local n = #pool
    if n > 0 then
        local t = pool[n]
        pool[n] = nil
        return t
    end
    return {}
end

--- trail 回池（清字段防 stale 引用 #消球动效动画队列）
function XUiPunishaarBallConsumeEffectPlayer:_ReturnTrail(trail)
    trail.go = nil
    trail.color = nil
    trail.gridRef = nil
    trail.timerId = nil
    trail.gridHidden = false
    trail.activeIndex = 0
    local pool = self._TrailPool
    pool[#pool + 1] = trail
end

--- 隐藏 grids 中的 grid（无 trail 路径兜底：无球/卡找不到/pool 缺时立即隐藏，无 delay 阶段）
function XUiPunishaarBallConsumeEffectPlayer:_HideGrids(grids, count)
    for i = 1, count do
        local grid = grids[i]
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
end

--- 产球步：挤头（满）+ 不显新球（全播完 Refresh 才显），不播动效。#消球动效动画队列
function XUiPunishaarBallConsumeEffectPlayer:_PlayProduceStep(step)
    self._PanelBattleBall:ProduceBall(step.color, step.count)
    self:_OnStepFinished()
end

--- 本步完播 → 下一步
function XUiPunishaarBallConsumeEffectPlayer:_OnStepFinished()
    self:_PlayNext()
end

--- 强制停播（切态/销毁时：清队列 + 回收 trail + 全量 Refresh 对齐 STE 最终态）
function XUiPunishaarBallConsumeEffectPlayer:ForceStop()
    self._IsPlaying = false
    self:_ClearQueue()
    self:_ForceRecycleAll()
    -- Refresh 前判 GO 未销毁（OnDestroy 路径 Remove 不经 OnDisable，兄弟节点 PanelBattleBall 可能已销毁）#消球动效动画队列
    if self._PanelBattleBall and not XTool.UObjIsNil(self._PanelBattleBall.GameObject) then
        self._PanelBattleBall:Refresh()
    end
end

function XUiPunishaarBallConsumeEffectPlayer:_ClearQueue()
    for i = 1, self._StepCount do
        self._StepQueue[i] = nil
    end
    self._StepCount = 0
    self._CurStepIndex = 0
end

function XUiPunishaarBallConsumeEffectPlayer:GetIsPlaying()
    return self._IsPlaying
end

--- 强制回收所有活跃 trail（切态/销毁时调，防 tween 残留 + active-ancestor 违规）
function XUiPunishaarBallConsumeEffectPlayer:_ForceRecycleAll()
    local activeCount = self._ActiveCount
    for i = 1, activeCount do
        local trail = self._ActiveTrails[i]
        if trail then
            if trail.timerId then
                XScheduleManager.UnSchedule(trail.timerId)
                trail.timerId = nil
            end
            if not XTool.UObjIsNil(trail.go) then
                local pool = self._Pools[trail.color]
                if pool then
                    pool:ReturnItemToPool(trail.go)
                end
            end
            self:_ReturnTrail(trail)  -- trail table 回池（清字段防 stale 引用 #消球动效动画队列）
            self._ActiveTrails[i] = nil
        end
    end
    self._ActiveCount = 0
end

--- 计算每色预热数（Little's Law：L = λ × W）
--- λ[color] = Σ(consume_i / CD_i) for all consuming cards of that color
--- expected = W × λ，preheat = ceil(expected) + 1（buffer）
---@param fightControl XPunishaarFightControl 调用方逐层取（self._Control.GameControl.FightControl）传入，免 CalcPreheat 内再逐层
---@return table color → preheat count
function XUiPunishaarBallConsumeEffectPlayer:CalcPreheatByColor(fightControl)
    -- W = trail 持续时长（秒→tick，读配置 delay+duration；倍速按 1x 算最稳，2x 时 trail 短并发少 #预热修复）
    local duration = XMVCA.XPunishaar:GetClientNumberByKey("BallEffectFlyAnimTime")
    if not XTool.IsNumberValidEx(duration) then
        duration = DEFAULT_DURATION
    end
    duration = math.max(0.01, duration)
    local delay = XMVCA.XPunishaar:GetClientNumberByKey("BallEffectStayAnimTime")
    if not XTool.IsNumberValidEx(delay) then
        delay = DEFAULT_DELAY
    end
    delay = math.max(0.01, delay)
    local W = (delay + duration) * STECustomEnum.BaseLogicFrame
    local reader = fightControl and fightControl.STEReader
    if not reader then
        return table.empty
    end
    local uidList = {}
    reader:FillCardEntityIds(uidList)

    local rateByColor = {}
    local maxConsumeByColor = {}  -- 该色单卡最大 consume（覆盖突发：单次消球 spawn consume 个 trail，preheat 须 >= 此 #预热修复）
    for _, uid in ipairs(uidList) do
        local cardId = reader:GetCardId(uid)
        local level = reader:GetCardLevel(uid)
        local cardCfg = fightControl:GetTablePunishaarCard(cardId)
        local levelCfg = fightControl:GetTablePunishaarCardLevel((cardId or 0) * 100 + level)
        if cardCfg and levelCfg then
            local consume = levelCfg.BallConsume or 0  -- 消球数在 levelCfg（非 cardCfg，对齐 XUiComBattleCardShow:RefreshBallCount configConsume）
            if consume > 0 then
                local cd = reader:GetCardTickCdMax(uid) or 1
                local color = cardCfg.Color  -- 卡色=产/消球色（STECustomEnum:167 注释，对齐 GetConfigCardColor）
                if color then
                    rateByColor[color] = (rateByColor[color] or 0) + consume / cd
                    maxConsumeByColor[color] = math.max(maxConsumeByColor[color] or 0, consume)
                end
            end
        end
    end

    local preheatByColor = {}
    for color, rate in pairs(rateByColor) do
        local expected = W * rate
        local maxConsume = maxConsumeByColor[color] or 0
        preheatByColor[color] = math.max(math.ceil(expected) + 1, maxConsume)
    end
    return preheatByColor
end

return XUiPunishaarBallConsumeEffectPlayer
