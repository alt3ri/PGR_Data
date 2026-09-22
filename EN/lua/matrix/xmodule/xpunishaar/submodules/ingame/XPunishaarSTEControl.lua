--- 对接STE框架相关的控制器
---@class XPunishaarSTEControl : XControl
---@field _MainControl XPunishaarFightControl
---@field private _Model
local XPunishaarSTEControl = XClass(XControl, "XPunishaarSTEControl")
local STEHelper = require("STEVM/STEHelper")
local STECustomEnum = require("XModule/XPunishaar/STEDefine/STECustomEnum")
local XList = require("XCommon/XList")

---@type XPunishaarSTEPipeline
local XPunishaarSTEPipeline = require("XModule/XPunishaar/SubModules/InGame/XPunishaarSTEPipeline")

function XPunishaarSTEControl:OnInit()
    -- 准备激发的卡牌Id队列
    ---@type XQueue
    self._ReadyActiveCardIdQueue = XQueue.New()

    -- 敌人 EffectGroupId 现查缓冲（复用，避免每帧新建 table）
    self._EnemyGroupIdBuffer = {}

    -- 帧末事件 Drain 缓冲（XList 复用，避免每帧 local event = {} GC）
    ---@type XList
    self._DrainEventList = XList.New()

    -- 自动战斗开关缓存（镜像 SpeedController 范式：缓存+InitFromSave+getter，不每帧读 vm）#Auto
    self._AutoEnabled = false
    -- 埋点：本局曾真正启用过自动战斗（门控通过 _AutoEnabled=true 时记 true，once true 永 true，仿 FightControl._UsedDoubleSpeed）#IsAutoFight
    self._UsedAutoFight = false

    -- 单卡同帧激发次数上限缓存（每局 InitNewGame 读一次 ClientConfig；math.huge=不限/缺省）#同帧激发上限
    self._MaxCardTickActivate = math.huge
end

function XPunishaarSTEControl:AddAgencyEvent()

end

function XPunishaarSTEControl:RemoveAgencyEvent()

end

function XPunishaarSTEControl:OnRelease()
    self:OnEndGame()
end

--- 初始化新一局
---@param initData XPunishaarBattleInitData 开战契约（只读快照）
function XPunishaarSTEControl:InitNewGame(initData)
    -- 用业务派生 env（挂 BuffEntity 对象池等 env 级服务）；框架便利接口 NewEnvironment 保留他用
    -- env 是 STE 的内部资产，由 STEControl（STE 门面）持有；对外只经 GetEnv 暴露读取
    -- 种子来源于契约（真实局服务器下发 / 回放复用），战斗内部不再现取时间，保证确定性可复现
    local XPunishaarSTEEnv = require("XModule/XPunishaar/STEDefine/XPunishaarSTEEnv")
    ---@type XPunishaarSTEEnv
    self._STEEnv = XPunishaarSTEEnv.New(initData:GetSeed())

    -- 球槽容量 + 本场 FightId：来自契约（FightId 供敌人执行现查 Fight 配置）
    self:CreateGlobalEntity(initData:GetBallSlotCapacity(), initData:GetBallSlotMax(), initData:GetFightId())

    -- 开局预置球：按契约逐个入池，沿用容量上限（满则溢出丢弃）
    self:PlaceInitBalls(initData)

    self._ReadyActiveCardIdQueue:Clear()

    -- 单卡同帧激发次数上限（每局读一次 ClientConfig；缺省/非法→math.huge 不限，保默认行为）#同帧激发上限
    local maxActivate = XMVCA.XPunishaar:GetClientNumberByKey("PunishaarMaxCardTickActivate")
    self._MaxCardTickActivate = (XTool.IsNumberValidEx(maxActivate) and maxActivate > 0) and maxActivate or math.huge

    -- 保留开战契约只读引用：供 Reader 经 cardIndex 取 level（底图 Level 维度，#64）。
    -- initData 是只读快照，存引用不复制；换局时 OnEndGame 置 nil。
    self._BattleInitData = initData
end

function XPunishaarSTEControl:OnEndGame()
    if self._STEEnv then
        self._STEEnv:Release()
        self._STEEnv = nil
    end
    self._BattleInitData = nil
    self._AutoEnabled = false
    self._UsedAutoFight = false
end

--region 自动战斗（Global Auto 特征 tag）

--- 从持久化读取自动战斗偏好应用（FightControl:InitNewGame 调，跨局/跨登录偏好生效）#Auto
--- 开启则给 Global 实体打 Auto 特征 tag：Pipeline.OutputCanActiveCardIds ByHand 牌分支据 tag 跳过输入检查。
--- 仅设缓存+tag，不驱动 updater（变速归 FightControl:SetUpdaterSpeed / SpeedController）。
--- 无环境/未开局静默跳过（InitNewGame 之前调不该发生，但防御）。
--- 当前关卡是否启用自动战斗（PunishaarStageGroup.EnableCardAutoMode）#Auto
--- 关卡未启用则无论缓存是否开启都不打 Auto tag、BtnAuto 不显；缓存值保留（下次启用关卡仍读缓存）
---@return boolean
function XPunishaarSTEControl:IsAutoModeEnabledByStage()
    local stage = self._Model and self._Model:GetCurrentStage()
    if not stage then
        return false
    end
    local cfg = XMVCA.XPunishaar:GetTablePunishaarStageGroupById(stage.StageId, true)
    return cfg and cfg.EnableCardAutoMode == true or false
end

function XPunishaarSTEControl:InitAutoModeFromSave()
    if not self._STEEnv then
        return
    end
    local enabled = self._Model and self._Model:GetAutoModeEnabled() and true or false
    -- 门控：当前关卡未启用自动战斗则不应用（无论缓存）；缓存值保留供下次启用关卡读取
    self._AutoEnabled = enabled and self:IsAutoModeEnabledByStage()
    if self._AutoEnabled then
        self._UsedAutoFight = true  -- 埋点：开局即自动（门控通过）记曾用 #IsAutoFight
        STEHelper.RunStep(self._STEEnv, function(vm)
            vm:AddTag(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.EntityTags.Auto)
        end, false)
    end
end

--- 设置自动战斗开关（UI BtnAuto toggle 即时调用）：写持久化 + 即时打/摘 Global Auto tag #Auto
--- 持久化经 Model._SaveUtil（per-player，镜像 SpeedIndex）；tag 即时生效，本帧起 ByHand 牌自动激活。
---@param enabled boolean
function XPunishaarSTEControl:SetAutoMode(enabled)
    if not self._STEEnv then
        return
    end
    -- 门控：当前关卡未启用自动战斗则不允许开启（BtnAuto 隐藏时点不到，防御；关闭不受限）
    if enabled and not self:IsAutoModeEnabledByStage() then
        return
    end
    self._AutoEnabled = enabled and true or false
    if self._AutoEnabled then
        self._UsedAutoFight = true  -- 埋点：玩家开启自动（门控通过）记曾用，once true 永 true #IsAutoFight
    end
    if self._Model then
        self._Model:SetAutoModeEnabled(self._AutoEnabled)
    end
    STEHelper.RunStep(self._STEEnv, function(vm)
        if self._AutoEnabled then
            vm:AddTag(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.EntityTags.Auto)
        else
            vm:RemoveTag(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.EntityTags.Auto)
        end
    end, false)
end

--- 读自动战斗开关当前缓存态（供 UI 显态，不每帧读 vm）#Auto
---@return boolean
function XPunishaarSTEControl:GetAutoMode()
    return self._AutoEnabled == true
end

--- 本局曾真正启用过自动战斗（埋点用，once true 永 true，仿 FightControl._UsedDoubleSpeed）#IsAutoFight
---@return boolean
function XPunishaarSTEControl:IsAutoFightUsed()
    return self._UsedAutoFight == true
end

--endregion


--- 按卡牌紧凑索引取该卡 level（读契约 _BattleInitData:GetSortedCardLevelByIndex，posIndex 排序后与 entity.Index 对齐）。
--- 供 Reader:GetCardLevel 经 GetCardIndex 委托调用（底图 Level 维度）。
--- #82：读契约 _SortedCards（构造期 _PrepareBattleData:BuildSortedCards 产出），不经 pairs 序 _Cards（避 Index↔pairs 序错位）。
---@param index number 卡牌紧凑索引（== CardEntityIds 下标 == reader:GetCardIndex）
---@return number|nil
function XPunishaarSTEControl:GetCardLevelByIndex(index)
    if not self._BattleInitData or not index then return nil end
    return self._BattleInitData:GetSortedCardLevelByIndex(index)
end

--- 获取当前局 STE 环境（供平级子控制器如 Reader 取用；换局时本引用被替换，恒为当前局）
---@return XPunishaarSTEEnv
function XPunishaarSTEControl:GetEnv()
    return self._STEEnv
end

--- 抽干本帧累积的表现层事件到 out（填充式，调用方自清 out），返回事件个数。
--- STE 门面：上层（帧尾派发）经此取事件，不直接伸手进 env。事件为 STECustomEnum.EventEnum 键。
--- 换局后 _STEEnv 被替换，此处恒对当前局总线操作；无环境时返回 0。
---@param out table 调用方提供并自清的容器,本帧事件键按序写入
---@return number count
function XPunishaarSTEControl:DrainPresentEvents(out)
    if not self._STEEnv then
        return 0
    end
    local bus = self._STEEnv:GetEventSystem()
    if not bus then
        return 0
    end
    return bus:Drain(out)
end

--- 取本帧攻击特效 payload（帧末由表现层调用，与 DrainPresentEvents 配合）。
--- STE 门面：上层经此取 payload 列表，不直接伸手进 env。换局后 _STEEnv 替换，恒对当前局；无环境返回 0。
---@param out XList 调用方提供并自清
---@return number count
function XPunishaarSTEControl:DrainAttackEffectPayloads(out)
    if not self._STEEnv then
        return 0
    end
    return self._STEEnv:DrainAttackEffects(out)
end

--- 取本帧落地伤害（帧末表现层调）。门面转发 env，无环境返 0。
---@param out XList 调用方提供并自清
---@return number count
function XPunishaarSTEControl:DrainDamageLanded(out)
    if not self._STEEnv then
        return 0
    end
    return self._STEEnv:DrainDamageLanded(out)
end

--- STE环境推进逻辑步
function XPunishaarSTEControl:STETick()
    self._STEEnv:AdvanceTick()
    
    -- 先清空上一帧的帧级缓存
    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.ResetGlobalTickData, false)
    
    -- 轮询卡牌+CD（玩家方）
    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.TickAllCards, false)
    -- 敌人 CD（推CD阶段：玩家方之后，严格"先玩家后怪物"）
    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.TickEnemy, false)
    
    -- 轮询检查可执行的卡牌
    -- 退出判据：本轮「真正激发成功」数为 0 即停。
    -- （不能用「入队数」判据：B 方案下 skip 的卡不移出 waitting，会被下一轮重复筛出，
    --   若用入队数则球不足/配置错的卡会导致本帧内无限循环。见下）
    local MAX_ROUND = 32   -- 兜底上限，防御意外的不收敛（正常远达不到）
    local round = 0
    repeat
        if self:GetIsRelease() then
            return
        end
        
        round = round + 1
        self._ReadyActiveCardIdQueue:Clear()

        -- 收集一次可以激活的卡牌（透传单卡同帧激发上限缓存）#同帧激发上限
        STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.OutputCanActiveCardIds, false, nil, self._ReadyActiveCardIdQueue, self._MainControl, self._MaxCardTickActivate)

        -- 本轮真正激发成功的卡数（skip / 回滚 均不计入）
        local activatedCount = 0

        while self._ReadyActiveCardIdQueue:Count() > 0 do
            if self:GetIsRelease() then
                return
            end
            
            local entityId = self._ReadyActiveCardIdQueue:Dequeue()

            -- 每张卡的效果都是一个原子事务；committed 且返回 true 才算激发成功
            local committed, activated = STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.ExecuteOneCardEffects, true, nil, entityId, self._MainControl)
            if committed and activated then
                activatedCount = activatedCount + 1
            end
        end

        -- 敌人执行（本轮玩家方之后：严格"先玩家后怪物"）。原子事务，成功计入本轮激发数。
        -- 补充约定：卡牌或敌人任一有执行，就再遍历一轮，使跨阵营基于对方动作的 effect 当帧立即连锁。
        local enemyCommitted, enemyActivated = STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.ExecuteEnemyEffects, true, nil, self._MainControl, self._EnemyGroupIdBuffer)
        if enemyCommitted and enemyActivated then
            activatedCount = activatedCount + 1
        end

        -- 本轮无任何卡成功激发 → 剩余的卡都是 skip（球不足等），本帧不再重试，留待下帧
    until activatedCount <= 0 or round >= MAX_ROUND

    if round >= MAX_ROUND then
        XLog.Error(string.format("STETick 激发轮次达到上限 %d，可能存在不收敛的连锁，已强制中断", MAX_ROUND))
    end

    -- 待落地伤害推进（ExecuteEnemyEffects 后、TickAllBuffs 前：让 buff 计量看到扣血后 HP）#75
    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.TickScheduledDamages, false)

    -- buff 生命周期：先推进计量（判定到期→PreEnd），再独立回收（撤修正+销毁）
    -- 必须在卡牌发动循环之后：次数型 buff 的 CountDownTrigger 可能依赖本帧 TickDoneCardList
    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.TickAllBuffs, false, nil, self._MainControl, self._MainControl:GetLogicFrame())
    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.RecycleBuffs, false)

    -- 战斗疲劳节奏（RecycleBuffs 后、OnTickEnd 前；atomic=false 非事务，fire-once+死亡不触发）#80
    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.TickBattlePacing, false, nil, self._MainControl, self._MainControl:GetLogicFrame())

    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.OnTickEnd, false)
    
    -- 帧末派发事件（_DrainEventList 复用，Drain :Append 填充，ipairs 遍历派发）
    self._STEEnv:GetEventSystem():Drain(self._DrainEventList)

    if self._DrainEventList:GetCount() > 0 then
        for i = 1, self._DrainEventList:GetCount() do
            local v = self._DrainEventList:GetValueByIndex(i)
            self._MainControl:DispatchEvent(v)
        end
    end

    self._DrainEventList:Clear()
end

--region 外部输入

--- 接收外部输入
function XPunishaarSTEControl:ReceiveCardClick(uid)
    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.SetTickClickCardData, false, nil, uid)
end

--endregion

--region 实体创建

function XPunishaarSTEControl:CreateGlobalEntity(ballSlotCapacity, ballSlotMax, fightId)
    local cls = require("XModule/XPunishaar/STEDefine/Entities/GlobalEntity")

    STEHelper.NewEntity(cls, STECustomEnum.GlobalEntityIds.Global, self._STEEnv, ballSlotCapacity, ballSlotMax, fightId)
end

function XPunishaarSTEControl:CreatePlayerEntity(initHp)
    local cls = require("XModule/XPunishaar/STEDefine/Entities/PlayerEntity")

    STEHelper.NewEntity(cls, STECustomEnum.GlobalEntityIds.Player, self._STEEnv, initHp)
end

--- 创建敌人实体：数值全由 Fight 表查出（HP/ATK/CD）。CD 为毫秒，建实体前转逻辑帧（同卡牌）。
---@param fightId number 本场 Fight.Id
---@param extraHp number|nil 无尽关多轮次额外 HP（局外 _PrepareBattleData 算好经 initData 传）
---@param extraAtk number|nil 无尽关多轮次额外 ATK（同上）
function XPunishaarSTEControl:CreateEnemyEntity(fightId, extraHp, extraAtk)
    local cls = require("XModule/XPunishaar/STEDefine/Entities/EnemyEntity")

    local fightCfg = self._MainControl:GetTablePunishaarFight(fightId)
    if not fightCfg then
        XLog.Error(string.format("Fight 配置不存在：fightId=%s", tostring(fightId)))
        return
    end

    -- CD 毫秒 → 逻辑帧：floor(ms/1000 × 帧率)，与卡牌一致。TickCD 最小 1（无论配多少，防 CD=0 每帧/死循环）
    local tickCd = math.max(1, math.floor(fightCfg.CD / 1000 * self._MainControl:GetLogicFrame()))

    -- 敌人 HP/ATK = Fight 表基础值 + 无尽关多轮次加成（extra 由局外 _PrepareBattleData 算好经 initData 传，局内只相加）
    local hp = fightCfg.HP + (extraHp or 0)
    local atk = fightCfg.ATK + (extraAtk or 0)

    STEHelper.NewEntity(cls, STECustomEnum.GlobalEntityIds.Enemy, self._STEEnv, hp, atk, tickCd)
end

--- 创建卡牌实体：只需 cardId + level + index + posIndex，数值(ATK/CD/产消球)从 CardLevel 表读取。
--- CardLevel 主键 Id = cardId*100 + level（与导表规则一致）。
--- index = 一维紧凑数组索引（== CardEntityIds 下标，装配按卡序自动生成）；posIndex = 离散空间坐标（外部契约提供）。
--- extraAtk = 副卡烘焙进主卡的额外 ATK（无副卡时为 0）。
--- 手动牌标签（ByHand）在此内部依 cardId 的 ReleaseMode 自行打（实体标签是实体自己的事，装配层不管）。
---@param extraAtk number 副卡叠加的额外 ATK（烘焙进 base）
function XPunishaarSTEControl:CreateCardEntity(cardId, level, index, posIndex, extraAtk)
    local levelCfg = self._MainControl:GetTablePunishaarCardLevel(cardId * 100 + level)
    if not levelCfg then
        XLog.Error(string.format("CardLevel 配置不存在：cardId=%s level=%s", tostring(cardId), tostring(level)))
        return
    end

    local cls = require("XModule/XPunishaar/STEDefine/Entities/CardEntity")
    local uid = self._STEEnv:GetNewUniqueNumber()

    -- 副卡 ATK 烘焙进主卡 base（战斗内不换卡，故一次算死不可逆）
    local finalAtk = levelCfg.ATK + (extraAtk or 0)

    -- CD 毫秒 → 逻辑帧：帧 = floor(毫秒/1000 × 帧率)，与 buff 时间型阈值换算一致。TickCD 最小 1（防 CD=0 每帧激发）
    local tickCd = math.max(1, math.floor(levelCfg.CD / 1000 * self._MainControl:GetLogicFrame()))

    -- 卡牌配置行：传入 CardEntity 作为 PropertyConfig，供 Trigger/Selector 读取 Color/Type/Size 等常量
    local cardCfg = self._MainControl:GetTablePunishaarCard(cardId)

    STEHelper.NewEntity(cls, uid, self._STEEnv,
            cardId, finalAtk, tickCd, levelCfg.BallOutPut, levelCfg.BallConsume, index, posIndex, cardCfg, STECustomEnum.TickCDMaxMin)

    -- id注册到global中，并打类型/特征标签（手动牌从 Card 表 ReleaseMode 读，1=手动）
    local isByHand = cardCfg and cardCfg.ReleaseMode == 1
    STEHelper.RunStep(self._STEEnv, function(vm)
        ---@type GlobalEntity
        local globalEntity = self._STEEnv:GetScope(STECustomEnum.GlobalEntityIds.Global)
        globalEntity.Fields.CardEntityIds:Append(uid)

        vm:AddTag(uid, STECustomEnum.EntityTags.Card)
        if isByHand then
            vm:AddTag(uid, STECustomEnum.EntityTags.ByHand)
        end
    end, false)

    return uid
end

--- 开局预置球：按契约逐个入池，沿用球槽容量上限（满则溢出丢弃）。
---@param initData XPunishaarBattleInitData 开战契约
function XPunishaarSTEControl:PlaceInitBalls(initData)
    local count = initData:GetInitBallCount()
    if count <= 0 then
        return
    end
    STEHelper.RunStep(self._STEEnv, function(vm)
        local ballList = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallList)
        local capacity = vm:Read(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallSlotCapacity)
        for i = 1, count do
            if vm:PropLen(ballList) >= capacity then
                XLog.Error(string.format("[开局球] 初始球总数超容量 %s，剩余丢弃", tostring(capacity)))
                break
            end
            vm:PropAppend(ballList, initData:GetInitBall(i))
        end
    end, false)
end

--endregion

--region 战斗装配（纯翻译契约 → 建实体，不认识任何数据来源）

--- 依据开战契约装配一局（Global 已在 InitNewGame 中创建）。
--- 纯翻译：只把契约字段翻译成建实体调用，不 require 任何具体来源。
---@param initData XPunishaarBattleInitData 开战契约
function XPunishaarSTEControl:SetupBattle(initData)
    self:CreatePlayerEntity(initData:GetPlayerHp())
    -- 敌人 HP/ATK 基础值由 Fight 表查出（模式A）；无尽关多轮次 extra 经 initData 契约传（局外算好）
    self:CreateEnemyEntity(initData:GetFightId(), initData:GetEnemyExtraHp(), initData:GetEnemyExtraAtk())

    -- 收集契约卡并按 posIndex 升序排序后再建实体：保证 Index==i 是空间紧凑序（忽略空格），
    -- 供 GetCardByIndex / GetLeft/RightAdjacentCard / CheckSelfPosMatch / GetCardIdByPos 等空间左右判定正确。
    -- posIndex 排序由契约 _PrepareBattleData:BuildSortedCards 构造期产出（_SortedCards），局内只读 GetSortedCard(i)。
    local count = initData:GetCardCount()
    if count <= 0 then
        return
    end

    for i = 1, count do
        local c = initData:GetSortedCard(i)

        -- 副卡：无 level/ATK（已约定 #43），不再读 CardLevel 表也不烘焙 extraAtk
        -- 副卡非实体，登记到 SubCardDict 供激发时反查跑效果（值只含 cardId，无 level #43）
        local extraAtk = 0

        -- index 按空间序自动生成（== CardEntityIds 下标 == 空间紧凑序，忽略空格）
        local uid = self:CreateCardEntity(c.cardId, c.level, i, c.posIndex, extraAtk)

        -- 登记副卡（值为 {cardId}，装配期写、战斗内只读 #43：去 level）
        if uid and c.subCardId then
            STEHelper.RunStep(self._STEEnv, function(vm)
                local subDict = vm:ReadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.SubCardDict)
                vm:PropSet(subDict, uid, { cardId = c.subCardId })
            end, false)
        end
    end
end

--- 战斗开始钩子：开局一次性执行所有卡牌+敌人的「装备时/战斗开始时」时机 effect。
--- 由 FightControl 在 SetupBattle 之后、StartGame 之前调用一次。原子事务（执行 effect 会改状态）。
function XPunishaarSTEControl:RunBattleStartEffects()
    STEHelper.RunStep(self._STEEnv, XPunishaarSTEPipeline.RunBattleStartEffects, true, nil, self._MainControl, self._EnemyGroupIdBuffer)
end

--endregion

--- 读取并打印当前关键实体状态（纯读）
function XPunishaarSTEControl:TestDumpState(tag)
    STEHelper.RunStep(self._STEEnv, function(vm)
        local pHp = vm:Load(STECustomEnum.GlobalEntityIds.Player, STECustomEnum.FieldNameType.HP)
        local eHp = vm:Load(STECustomEnum.GlobalEntityIds.Enemy, STECustomEnum.FieldNameType.HP)
        local line = string.format("[%s] PlayerHP=%s EnemyHP=%s", tostring(tag), tostring(pHp), tostring(eHp))

        -- 遍历卡牌实体表（不依赖 TestCardData 结构），uid 为实体 id、CardId 为配置 id
        local cardIds = vm:LoadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.CardEntityIds)
        local cardLen = vm:PropLen(cardIds)
        for i = 1, cardLen do
            local uid = vm:PropGet(cardIds, i)
            local cardId = vm:Read(uid, STECustomEnum.FieldNameType.CardId)
            local cd = vm:Load(uid, STECustomEnum.FieldNameType.TickCD)
            local atk = vm:Read(uid, STECustomEnum.FieldNameType.ATK)   -- 打 ATK 观察 buff 临时修正(建立/覆盖/到期)
            line = line .. string.format(" | Card[uid%s cid%s].TickCD=%s ATK=%s", tostring(uid), tostring(cardId), tostring(cd), tostring(atk))
        end

        -- 球池：展示有序序列（队头=最早产）
        local ballList = vm:LoadProperty(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.BallList)
        local ballLen = vm:PropLen(ballList)
        local balls = {}
        for i = 1, ballLen do
            balls[#balls + 1] = tostring(vm:PropGet(ballList, i))
        end
        line = line .. string.format(" | 球池[%d]={%s}", ballLen, table.concat(balls, ","))

        XLog.Debug(line)
    end, false)
end

--- 读取 Player / Enemy 当前 HP（纯读），供胜负判定
---@return number playerHp, number enemyHp
function XPunishaarSTEControl:GetHp()
    local pHp, eHp
    STEHelper.RunStep(self._STEEnv, function(vm)
        pHp = vm:Load(STECustomEnum.GlobalEntityIds.Player, STECustomEnum.FieldNameType.HP)
        eHp = vm:Load(STECustomEnum.GlobalEntityIds.Enemy, STECustomEnum.FieldNameType.HP)
    end, false)
    return pHp, eHp
end

--- 读取信号球生成总量（纯读埋点统计）。无环境/未开局返回 0。
---@return number
function XPunishaarSTEControl:GetBallProduced()
    local val
    STEHelper.RunStep(self._STEEnv, function(vm)
        val = vm:Load(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TotalBallProduced)
    end, false)
    return val or 0
end

--- 读取信号球消费总量（纯读埋点统计）。无环境/未开局返回 0。
---@return number
function XPunishaarSTEControl:GetBallConsumed()
    local val
    STEHelper.RunStep(self._STEEnv, function(vm)
        val = vm:Load(STECustomEnum.GlobalEntityIds.Global, STECustomEnum.FieldNameType.TotalBallConsumed)
    end, false)
    return val or 0
end

--endregion

return XPunishaarSTEControl
