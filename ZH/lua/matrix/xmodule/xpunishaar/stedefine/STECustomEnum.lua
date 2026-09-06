--- 大巴扎自定义的STE枚举
local STECustomEnum = {}

-- 全局实体，这些实体的id值是固定的
-- Begin/End 为保留段占位符（不注册实体，只标段界供 XPunishaarSTEEnv:GetNewUniqueNumber 跳过 [Begin,End] 段，
--   防运行时动态分配的卡牌/Buff 实体 ID 与固定全局实体碰撞）。新增固定全局实体 ID 须落在 [Begin,End] 内并同步更新 End。
STECustomEnum.GlobalEntityIds = {
    Begin = 1000000,   -- 保留段起始占位符（== Global）
    Global = 1000000,
    Player = 1000001,
    Enemy = 1000002,
    End = 1000002,     -- 保留段结束占位符（== Enemy）
}

-- 黑板数据保留字, 这些字在玩法内含义一致，始终有效（但视上下文不一定有值）
STECustomEnum.BlackBoardKeys = {
    OwnCardId = "OwnCardId",     -- 执行者
    OwnBuffId = "OwnBuffId",    -- buffId
    ATK = "ATK",                -- 伤害计算的中间值
}

-- 实体类型标签
STECustomEnum.EntityTags = {
    -- 类型标签
    Card = "Type_Card",
    Player = "Type_Player",
    Buff = "Type_Buff",
    Enemy = "Type_Enemy",
    Global = "Type_Global",
    
    -- 状态标签
    WaittingDone = "WaittingDone",  -- 待激活
    Active = "Active",  -- 正在执行中
    
    -- 特征标签
    ByHand = "ByHand",  -- 用于卡牌，表示手动驱动
    NoConsumeBall = "NoConsumeBall",  -- 用于卡牌，表示下次触发不消耗球（一次性，触发后清除）
    Fatigued = "Fatigued",  -- 用于 Global，表示疲劳已触发（fire-once 标记，Tag 替 Property）#80
    Auto = "Auto",  -- 用于 Global，表示自动战斗开启（ByHand 牌据 tag 跳过输入检查直接激活；吃球校验不跳过）#Auto
}

-- 所有属性名的枚举（面向配置）
STECustomEnum.FieldNameEnum = {
    [1] = "HP",                 -- 当前血量
    [2] = "HPMax",              -- 血量上限
    [3] = "ATK",                -- 攻击力
    [4] = "TickCD",             -- 当前CD（单位：逻辑帧；所见即所得）
    [5] = "TickCDMax",          -- CD上限（单位：逻辑帧）
    -- [6][7] 原 ATKCD/ATKCDMax 已废弃：敌人改为卡牌式 TickCD（数字键4），不再有攻击CD概念
    [8] = "BallProductCount",   -- 产球数
    [9] = "BallConsumeCount",   -- 消耗球数
    [10] = "NoHurtTimes",        -- 护盾次数
    [11] = "Alpha",              -- 自由值
    [12] = "BallSlotCapacity",   -- 球槽容量上限
    [13] = "DoneTimes",          -- 从开局开始总的触发次数
    [14] = "TotalBallProduced",  -- 信号球生成总量（埋点统计，Global single property）
    [15] = "TotalBallConsumed",  -- 信号球消费总量（埋点统计，Global single property）
    [16] = "Layer",              -- buff 字段镜像快照值（SnapshotFieldToBuff 写入，按 BuffId 聚合供 buff 图标列表显示数值）
    [17] = "TickDoneTimes",     -- 卡牌本帧已激发次数（ResetGlobalTickData 每帧清零；限制同帧连锁激发次数，防互相 SetCardCDEnd 刷次）#同帧激发上限
}

-- 所有属性名的枚举（面向代码）
STECustomEnum.FieldNameType = {
    HP = "HP",
    HPMax = "HPMax",
    ATK = "ATK",
    TickCD = "TickCD",
    TickCDMax = "TickCDMax",
    -- 帧级数值快照（cardUid→finalVal）：buff 同帧加成+清除，UI 帧末读时修正已清，快照跨一帧由 ResetGlobalTickData 清，供 UI 显示一瞬修正值。0 有效、nil 表无快照。#buff修正快照
    TickAtkSnapshot = "TickAtkSnapshot",
    TickCdMaxSnapshot = "TickCdMaxSnapshot",
    BallProductCount = "BallProductCount",
    BallConsumeCount = "BallConsumeCount",
    NoHurtTimes = "NoHurtTimes",
    Alpha = "Alpha",
    
    Index = "Index",                                           -- 一维紧凑数组索引（== CardEntityIds 下标；忽略空间空格）
    PosIndex = "PosIndex",                                      -- 一维空间离散坐标（左对齐起点；卡有体积可跨多格，含空格）

    TickDoneCardList = "TickDoneCardList",                      -- 当前时刻触发的卡牌Id
    TickCardCDMaxChangeList = "TickCardCDMaxChangeList",        -- 当前时刻CD上限发生改变的卡牌
    TickProductBallEntityList = "TickProductBallEntityList",    -- 当前时刻产球的实体（不一定是牌）
    TickConsumeBallEntityList = "TickConsumeBallEntityList",    -- 当前时刻消耗球的实体
    TickAccelEntityList = "TickAccelEntityList",                -- 当前时刻 CD 被加速推进的实体（AccelerateCardCD 写入）
    TickClickCardIdDict = "TickClickCardIdDict",                -- 当前接收输入的卡牌Id
    WaittingDoneCardIdList = "WaittingDoneCardIdList",          -- 等待释放的卡牌id列表
    BallList = "BallList",                                      -- 球槽
    BallSlotCapacity = "BallSlotCapacity",                      -- 球槽容量上限
    FightId = "FightId",                                        -- 本场选中的 Fight.Id（场级，敌人现查配置）
    CardEntityIds = "CardEntityIds",                            -- 卡牌实体Id列表(方便搜索）
    BuffEntityIds = "BuffEntityIds",                            -- Buff实体Id列表（方便搜索）
    SubCardDict = "SubCardDict",                                -- 副卡登记表（主卡uid→副卡{cardId,level}）
    CardId = "CardId",                                          -- 卡牌配置Id

    --- 只读配置表行引用（PropertyConfig）；ReadProperty 后按 XTablePunishaarCard 类型访问字段
    --- 可直接取 .Color / .Type / .Size 等配置常量，无需单独字段
    CardConfig = "CardConfig",

    TickDamageDealtDict = "TickDamageDealtDict",  -- 帧级伤害段数字典（entityId → 本帧攻击段数，帧尾随 ResetGlobalTickData 清零）
    AccelLockUntilTickDict = "AccelLockUntilTickDict",  -- 加速冷却：entityId→解锁tick阈值（GetTick()>=阈值才允许再加速；W=TickCDMaxMin帧，perf护栏非玩法）#加速冷却

    -- #76 延时落地架构修正：原 6 并行标量 PropertyList（SchedTarget/Owner/Atk/AtkType/Times/Delay）已移除
    -- （env 级 PropertyList 非法——STE 事务快照只对 Entity 内 PropertyList 生效）；改 Instruction XClass + 对象池

    OwnEntityId = "OwnEntityId",                                -- 关联从属实体Id
    TargetEntityId = "TargetEntityId",                          -- 关联目标实体Id
    TargetFieldNameEnum = "TargetFieldNameEnum",                -- 关联目标实体字段枚举
    LifeTimes = "LifeTimes",                                    -- 生命周期值
    State = "State",                                            -- 状态（通义）
    BuffId = "BuffId",                                          -- buff配置Id
    ExTickCD = "ExTickCD",                                      -- buff Ex效果释放倒计时(帧)
    ExDoneTimes = "ExDoneTimes",                                -- buff Ex效果已释放次数
    DoneTimes = "DoneTimes",                                      -- 卡牌当局触发总次数
    TickDoneTimes = "TickDoneTimes",                              -- 卡牌本帧已激发次数（每帧 ResetGlobalTickData 清零；限同帧连锁激发次数）#同帧激发上限
    TotalBallProduced = "TotalBallProduced",                      -- 信号球生成总量（埋点统计，Global single property）
    TotalBallConsumed = "TotalBallConsumed",                      -- 信号球消费总量（埋点统计，Global single property）
    Layer = "Layer",                                               -- buff 字段镜像快照值（SnapshotFieldToBuff 每帧读实体字段终值 floor 后写入；按 BuffId 聚合求和供 buff 图标列表显示数值）
}

-- 伤害值类型枚举（配置相关）
STECustomEnum.ConfigDamageType = {
    Percent = 1, -- 基于倍率
    Alpha = 2,   -- 基于alpha值
    Const = 3, -- 基于配置固定值
    EnemyHPMax = 4, -- 基于敌人血量最大值
    EnemyCurHP = 5, -- 基于敌人当前血量
    PlayerHPMax = 6, -- 基于玩家最大血量
    PlayerCurHP = 7, -- 基于玩家当前血量
}

--- 攻击类型
STECustomEnum.ConfigATKType = {
    Normal = 1,             -- 普通攻击（受到护盾减免）
    IgnoreNoHurtTimes = 2,  -- 真实伤害
}

--- CD 扣除模式（AccelerateCardCD 的 mode 参数）
STECustomEnum.ConfigCDDeductMode = {
    Fixed = 0,  -- 扣除固定毫秒值（amount 单位=毫秒）
    Ratio = 1,  -- 扣除基于目标 CDMax 的比例（amount=浮点比例，0.5=扣 50% CDMax）
}

--- Effect 类型枚举（配置 PunishaarEffect.EffectType 字段；与 STEDefine.Effect 数字键对齐）
--- 仅列特殊语义项（1-10 见 STEDefine.Effect 注释）
STECustomEnum.ConfigEffectType = {
    SnapshotFieldToBuff = 11,  -- 字段镜像（读实体字段终值 math.floor→按 op 写 buff 自身字段；普通 on-tick effect，配在 buff 的 ExEffectGroup 里 TickBuffEx 分发跑）
}

--- 字段来源枚举（SnapshotFieldToBuff param1：读 buff 源还是 buff 目标的字段）
STECustomEnum.ConfigFieldSource = {
    Source = 1,  -- buff 源（buff.OwnEntityId，产生该 buff 的实体）
    Target = 2,  -- buff 目标（buff.TargetEntityId，buff 挂载的实体）
}

-- 基础逻辑帧率（与 XPunishaarFightControl.LogicFrame 对齐=20；CD 帧毫秒换算用此基础值，忽略二倍速影响）
STECustomEnum.BaseLogicFrame = 20
-- 预算：1 逻辑帧 = 多少毫秒（1000 / BaseLogicFrame = 50ms）。CD 帧毫秒换算直接读此常量，免运行时除法
STECustomEnum.MsPerLogicFrame = 1000 / STECustomEnum.BaseLogicFrame

-- 攻击伤害落地延时（#75）：delayMs 来源 = ClientConfig BattleEffectDuration（飞弹飞行时长 = 伤害落地延时，与技能特效方案天然耦合）
-- **配置值单位秒**（Effect.GetAttackLandDelayFrames 内 ×1000 转毫秒后算帧）；delayFrames = math.floor(delayMs / MsPerLogicFrame)
-- 二倍速只改 tick 频率不改 delayFrames 常数；未填/≤0 时兜底 DefaultBattleEffectDurationMs（500ms=0.5秒=10帧）
STECustomEnum.BattleEffectDurationKey = "BattleEffectDuration"
STECustomEnum.DefaultBattleEffectDurationMs = 500  -- 兜底延时(ms)，配置秒×1000 后同此单位算帧；=0.5秒=10帧

--- 球颜色（取值与卡牌 Color 字段同域：卡的 Color 即其产/消球的颜色）
--- 具体色值由 PunishaarCard.Color 定义，这里按实际取值补充
STECustomEnum.BallColor = {
    Red = 1,
    Yellow = 2,
    Blue = 3,
    None = 4,
}

--- 位置解析模式（仅适用一维紧凑索引 Index、1卡占1格；离散坐标 PosIndex/占格/空间布局不支持，多格空间布局归编排层）
--- 四种模式最终都归约为一个绝对 Index
STECustomEnum.PosMode = {
    Absolute       = 1,  -- 绝对位置，param = 索引
    RelativeToSelf = 2,  -- 相对自身，param = 偏移（左负右正）
    Leftmost       = 3,  -- 最左（全体卡 Index 最小），param 忽略
    Rightmost      = 4,  -- 最右（全体卡 Index 最大），param 忽略
}

STECustomEnum.BuffState = {
    Init = 0,           -- 刚实例化时的状态
    Active = 1,         -- 激活状态
    PreEnd = 2,         -- 待结束状态
    End = 3,            -- 结束状态，还原修改、移除各种引用注册
}

STECustomEnum.BuffLifeTimeType = {
    TriggerTick = 1,    -- 触发器单位增
    Tick = 2,           -- 每次单位增
}

--- Effect 触发时机类型（策划配连续值；内部把值当"左移位数"转 mask 位运算判断）
--- 局内约定：装备时与战斗开始时都在"战斗开始钩子"执行（对战斗而言二者本质相同）；
---   Other 为运行时激发（卡牌CD/敌人/buff Ex），是现有 effect 的默认时机（TriggerType 空/0 天然落此，兼容存量）。
STECustomEnum.TriggerTimeType = {
    Other = 0,          -- 其他：运行时激发（CD激发等），默认
    OnEquip = 1,        -- 装备时（局内归并到战斗开始钩子；局外预览语义留待将来）
    OnBattleStart = 2,  -- 战斗开始时
}

--- 时机 mask 常量（1 << 时机值）：调用方按上下文传入，CheckEffectTrigger 位与判断
--- 运行时激发只接受 Other；战斗开始钩子接受 装备时|战斗开始时
STECustomEnum.TriggerTimeMask = {
    Runtime = 1 << STECustomEnum.TriggerTimeType.Other,                                                    -- =1
    BattleStart = (1 << STECustomEnum.TriggerTimeType.OnEquip) | (1 << STECustomEnum.TriggerTimeType.OnBattleStart),  -- =6
}

--- VM输出事件枚举
STECustomEnum.EventEnum = {
    PlayerHPChanged = 1,
    EnemyHPChanged = 2,
    BallListChanged = 3,
    CardCdChanged = 4,      -- 卡牌CD变化（每帧推进即变，表现层收到后遍历刷所有卡CD进度）
    PlayerShieldChanged = 5, -- 玩家护盾(NoHurtTimes)变化
    EnemyShieldChanged = 6,  -- 敌人护盾变化
    CardBallProductChanged = 7,  -- 卡牌产球数变化（策划在 EffectGroup 末尾配 EmitEvent 派发；表现层收到后刷所有卡产球数显示）
    CardBallConsumeChanged = 8, -- 卡牌消球数变化（同上）
    CardAttackAnim = 9,  -- 卡牌攻击动画（Pipeline 善后派发，卡牌发动即播，表现层逐卡 PlayAttackAnima）#71
    AttackEffect = 10,  -- 攻击特效（AttackTarget 内 Emit，payload 含 ownerId/targetId；表现层帧末 Drain 后按起→终点投射场景特效）#73
    DeathAnim = 11,  -- 死亡动画触发（CheckBattleEnd death gate 帧末直接 DispatchEvent，非 vm:Emit；号段对齐 FightConfigControl.EventIds）#75
    FatigueAnim = 12,  -- 疲劳弹窗动画（EffectGroup 组末尾 EmitEvent 派发，逻辑时间超阈值挂疲劳 buff 时触发；号段对齐 FightConfigControl.EventIds）#80
    EnemyAttackPrepare = 13,  -- 敌人准备攻击（ExecuteEnemyEffects 激发时 Emit，CD 到 0 准备执行 EffectGroup；表现层订阅触发 FxEnemyAttack 特效）#EnemyAttack
    DotBuffLayerChanged = 14,  -- buff Layer 变化（SnapshotFieldToBuff 幂等值变 Emit / _DestroyBuff 销毁前 Emit；表现层 PanelEnemyHp:RefreshBuffList 订阅→GetDotBuffLayers 取聚合值→刷 buff 图标列表数值）
}

--- 球动作过滤：相邻方向（0=不约束，从1起，与 color/cardType 的 0=不约束 保持一致）
STECustomEnum.AdjacentSide = {
    Left   = 1,  -- 仅左邻（Index offset == -1）
    Either = 2,  -- 两侧任意（offset == -1 或 +1）
    Right  = 3,  -- 仅右邻（Index offset == +1）
}

STECustomEnum.TickCDMaxMin = 4 -- 约定CD最小4帧 = 0.2s

return STECustomEnum