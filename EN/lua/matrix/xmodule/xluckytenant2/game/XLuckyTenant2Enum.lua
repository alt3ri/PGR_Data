local XLuckyTenant2Enum = {
    Item = {
        Piece = 1,
        RefreshProp = 98,
        DeleteProp = 99,
    },
    PropId = {
        RefreshProp = 99998,
        DeleteProp = 99999,
    },
    -- 羁绊类型
    Bond = {
        Finance = 1,      -- 金融
        Monster = 2,      -- 怪物
        Role = 3,         -- 角色
        Weapon = 4,       -- 武器
        Box = 5,          -- 宝盒
        RedTide = 6,      -- 红潮
    },
    -- 羁绊ID与感染状态技能类型ID的映射关系
    -- 用于Type601（红潮被动01）和Type208（子虫死亡传染）
    BondToInfectionSkillMap = {
        [1] = 101,  -- 金融羁绊 → 金融感染状态技能(Type101)
        [4] = 404,  -- 武器羁绊 → 武器感染状态技能(Type404)
        [5] = 505,  -- 宝盒羁绊 → 宝盒感染状态技能(Type505)
    },
    -- 技能类型与感染状态技能类型ID的映射关系
    SkillTypeToInfectionSkillMap = {
        [101] = 102,  -- 金融感染状态技能(Type101)
        [404] = 408,  -- 武器感染状态技能(Type408)
        [505] = 506,  -- 宝盒感染状态技能(Type506)
    },
    -- 羁绊升级要求类型
    BondUpgradeRequire = {
        TypeCount = 1,    -- 凑不同的关联棋子id种类（不计重复棋子）
        TotalCount = 2,   -- 凑关卡棋子总数量（计重复棋子）
    },
    -- 可触发的动态状态
    TriggerState = {
        Infection = 1,    -- 感染（被传染）
        Revive = 2,       -- 复活
        Death = 3,       -- 死亡
        Immortal = 4,     -- 不死
        Upgrade = 5,     -- 升级
        Eliminated = 6,   -- 被消除
        Fission = 7,     -- 裂变
        Production = 8,   -- 生产倒计时（用于Type101/102/201等周期性生产技能）
    },
    -- 技能类型（根据配置表LuckyTenant2ChessSkill.stab中的Type字段）
    -- 注意：配置表中的Type字段直接作为技能类型使用
    -- 每个技能ID（SkillId）对应一个Type值，Type值在配置表中定义
    Skill = {
        -- ==================== 金融羁绊技能类型（Type 101-105）====================
        Type101 = 101, -- 金融被动01 - 可被传染，每N回合在相邻空位产生金币棋子
        Type102 = 102, -- 金融状态技能（被传染）- 每N回合在相邻空位产生金币棋子
        Type103 = 103, -- 金融羁绊lv.1 - 基础金币额外+N；被消除金币+N
        Type105 = 105, -- 金融羁绊lv.3 - 基础金币+N，被消除金币*倍数
        
        -- ==================== 怪物羁绊技能类型（Type 201-210）====================
        Type201 = 201, -- 怪物被动01 - 每N回合在相邻空位产生子虫
        Type202 = 202, -- 怪物被动02 - 怪物相邻无空位时，不生成子虫，基础金币+N
        Type203 = 203, -- 怪物lv1 - 子虫基础金币+N，消除金币+M
        Type204 = 204, -- 怪物lv2 - 当子虫、怪物在死亡或被消除时，额外得基础金币*N
        Type205 = 205, -- 怪物lv3 - 子虫改为N回合后死亡
        Type207 = 207, -- 怪物lv4 - 当子虫死亡或被消除时，可传染相邻棋子，每成功传染1枚+N金币收益
        Type208 = 208, -- 子虫技能02（死亡传染）- 子虫死亡时传染相邻棋子，每成功传染1个+N金币
        Type209 = 209, -- 怪物状态技能01（倒计时）- 每N回合在相邻空位产生子虫
        Type210 = 210, -- 子虫技能01 - 存在N回合后死亡
        
        -- ==================== 角色羁绊技能类型（Type 301-306）====================
        Type301 = 301, -- 角色被动01 - 每N回合等级+M（SkillMode=1: 升级等级模式, SkillMode=2: 减少倒计时模式）
        Type302 = 302, -- 角色被动02 - 等级关联金币
        Type303 = 303, -- 角色羁绊lv.1 - 角色升级倒计时减少
        Type304 = 304, -- 角色羁绊lv.2 - 可发动消除（配合305和306）
        Type305 = 305, -- 角色羁绊lv.3 - 鞭尸增强（配合304）
        Type306 = 306, -- 角色羁绊lv.4 - 范围扩大增强（配合304）
        
        -- ==================== 武器羁绊技能类型（Type 401-408）====================
        Type401 = 401, -- 武器被动01 - 相邻2枚同品质武器可融合提升品质，属性叠加
        Type402 = 402, -- 武器被动02 - 等级每+1级，基础金币根据品质额外增加
        Type403 = 403, -- 武器羁绊lv1 - 可融合武器碎片升级
        Type404 = 404, -- 武器羁绊lv2 - 可被传染，被传染后激活Type408
        Type405 = 405, -- 武器羁绊lv3 - 让相邻N枚棋子等级+M，成功后自身等级+K
        Type406 = 406, -- [已废弃]
        Type407 = 407, -- 武器羁绊lv4 - 有N%概率让相邻棋子倒计时清零，成功后自身等级+M
        Type408 = 408, -- 武器状态技能（被传染）- 可融合任意相邻武器，等级额外+N
        
        -- ==================== 宝盒羁绊技能类型（Type 501-508）====================
        Type501 = 501, -- 宝盒被动01 - 倒计时N回合后死亡，并在相邻空位产生棋子
        Type502 = 502, -- 宝盒被动02 - 宝盒死亡后，原地产生1个宝盒
        Type503 = 503, -- 宝盒羁绊lv.1 - 宝盒倒计回合上限-N
        Type504 = 504, -- 宝盒羁绊lv.2 - 宝盒相邻棋子升级时，宝盒倒计时-N
        Type505 = 505, -- 宝盒羁绊lv.3 - 可被传染，感染后宝盒倒计时-N
        Type507 = 507, -- 宝盒羁绊lv.4 - 宝盒死亡时，宝盒品质+1，被消除金币+N
        Type506 = 506, -- 宝盒状态技能02（被传染）- 感染后宝盒倒计时-N，死亡时只产出同品质怪物棋子
        Type508 = 508, -- 宝盒状态技能01（倒计时）- 倒计时N回合后死亡，产生随机棋子或金币
        
        -- ==================== 红潮羁绊技能类型（Type 601-603）====================
        Type601 = 601, -- 红潮被动01 - 每回合传染相邻棋子
        Type602 = 602, -- 红潮羁绊lv.1 - 相邻棋子每发生1次被消除，红潮基础金币+N
        Type603 = 603, -- 红潮羁绊lv.2 - 相邻棋子存在倒计时时，概率将倒计回合清零，且基础金币+N
    },
    Operation = {
        None = 0,
        Score = 1,              -- 得分
        DeletePiece = 2,       -- 删除
        AddNewPieceToBag = 3,  -- 增加新棋子到背包
        TransformPiece = 4,    -- 变形成为新的棋子
        AddPieceValue = 5,     -- 增加棋子分数
        SetPieceByPosition = 6, -- 从背包里设置棋子到棋盘上
        AddPassiveSkill = 7,   -- 增加一个被动技能
        SetValueUponDeletion = 8, -- 设置消除得分
        Update = 9,            -- 更新棋子信息
        AddPieceLevel = 10,    -- 增加棋子等级
        AddPieceState = 11,    -- 增加棋子状态
        RemovePieceState = 12, -- 移除棋子状态
        AddPieceQuality = 13,  -- 增加棋子品质
    },
    Quality = {
        None = 0,
        White = 0,     -- 灰色/白色（新增，给子虫、金币使用）
        Grey = 1,
        Green = 2,
        Blue = 3,
        Purple = 4,
        Orange = 5,
        Max = 5,        -- 最大品质
    },
    PieceType = {
        Monster = 1,
        Weapon = 2,
        Role = 3,
        Box = 4,
        RedTide = 5,
        Finance = 6,
        Special = 7,   -- 特殊棋子（子虫、金币、武器碎片）
    },
    -- 已知棋子配置 ID（用于技能条件判断等；无 bondId 的棋子 id 1/2/3/4 均从配置 StateSkillId 取技能）
    -- 配置表 LuckyTenant2Chess.tab 中上述四类棋子必须填写 StateSkillId，否则技能为空；可用 ConfigModel:ValidateNoBondIdPieceStateSkillIds() 检查
    PieceId = {
        Coin = 1,              -- 金币
        Subworm = 2,           -- 子虫棋子 ID（Type201/203/204/205/207 等均以此判断子虫）
        WeaponFragmentLv4 = 3, -- 4 级武器碎片
        WeaponFragmentLv6 = 4, -- 6 级武器碎片
    },
    GameState = {
        ShowQuestGoalsOnFirstRound = 1, -- 第一回合弹出任务目标
        Roll = 2,                       -- 掷骰子（计算分数, 得分）
        Animation = 3,
        CheckQuestCompletionStatus = 4, -- 检查任务完成情况
        ShowNextQuestGoals = 5,         -- 弹出任务目标
        SelectPiece = 6,                -- 选择棋子
        GameOver = 7,                   -- 失败
        NormalClear = 8,                -- 普通通关
        PerfectClear = 9,               -- 通关
        Guide = 10,                     -- 指引中等待
    },
    -- 回合进度（用于恢复游戏时判断玩家退出时所处的阶段）
    RoundProgress = {
        SelectPiece = 1,  -- 选棋阶段
        Roll = 2,         -- Roll阶段（计算分数）
        Animation = 3,    -- 动画阶段
    },
    -- 技能优先级（根据需求文档3.4.1）
    SkillPriority = {
        Attribute = 1,      -- 属性（基础金币）、额外加的金币
        Revive = 2,         -- 复活
        Countdown = 3,      -- 倒计时
        Upgrade = 4,        -- 升级
        OpenBox = 5,        -- 开宝盒
        Eliminate = 6,      -- 消除+被消除金币
        Death = 7,          -- 自爆（死亡）
        Fission = 8,        -- 裂变
        Infection = 9,      -- 传染
        FissionAfterInfection = 10, -- （被传染再次）裂变
    },
    -- Condition类型（根据需求文档10.1）
    -- 注意：Round、TagAmount、Identical用于随机池条件判断；其他用于技能条件判断
    Condition = {
        Round = 1,                  -- 达到多少回合（用于随机池条件判断）
        TagAmount = 2,              -- tag数量达到多少（用于随机池条件判断）
        Identical = 3,              -- 相同id棋子达到多少（用于随机池条件判断）
        BondLevel = 4,              -- 指定羁绊id{0}等级是否={1}（用于技能条件判断）
        PieceQuality = 5,           -- 本棋子是否为指定品质等级{0}数组中的一个（用于技能条件判断）
        PieceBond = 6,              -- 本棋子是否为指定羁绊{0}的棋子（用于技能条件判断）
        HasState = 7,               -- 本棋子是否含有状态{0}（用于技能条件判断）
        AdjacentHasState = 8,       -- 本棋子的相邻棋子是否含有状态{0}（用于技能条件判断）
        StateInCountdown = 9,       -- 触发状态技能{0}后，是否在倒计时{1}回合内
        OnBoard = 10,               -- 本棋子在棋盘上
    },
    -- 任务Condition类型（根据需求文档10.2）
    TaskCondition = {
        SingleClearScore = 1,        -- 单次通关金币数超过{0}
        TotalScore = 2,             -- 累计金币超过{0}
    },
    Animation = {
        Shake = 1,                   -- 抖动
        SetPiece = 2,              -- 刷新棋子
        AddScore = 3,              -- 增加棋子分数
        GetScore = 4,              -- 获得分数
        DeletePiece = 5,           -- 删除棋子
        AddPiece = 6,              -- 添加棋子
        PlayRollAnimation = 7,
        Wait = 8,
        UpdateChessboard = 9,
        End = 10,
    },
    -- 动画数据类型（用于 AnimationGroup）
    AnimationType = {
        GetScore = 1,              -- 获得分数动画
        AddPiece = 2,              -- 添加棋子动画
        DeletePiece = 3,           -- 删除棋子动画
        UpdatePiece = 4,           -- 更新棋子动画
        ActivateSkillEnable = 5,   -- 主动发动技能的棋子播放
        AffectedBySkillEnable = 6, -- 受技能影响的棋子播放（目标格子）
        Duang = 7,                 -- Duang 特效
        Countdown = 8,             -- 倒计时特效（沙漏）
        InfectionSourceEnable = 9, -- 感染来源棋子播放（如 Type210 结算时，在拥有 Type207 时展示感染特效）
    },
    Cost = 1,
    QualityIcon = {
        Circle = 1,
        Quad = 2,
    },
    -- 游戏常量
    GameConstants = {
        MAX_SKILL_LOOP = 9,          -- 技能循环最大次数
        MAX_SKILL_PRIORITY = 10,     -- 技能最大优先级
        MAX_PIECES_AMOUNT = 99,      -- 背包最大棋子数量
        MAX_PIECE_LEVEL = 20,        -- 棋子最大等级
        MIN_PIECE_LEVEL = 0,         -- 棋子最小等级
        MAX_ROLE_LEVEL = 20,         -- 角色羁绊棋子最大等级
        MAX_QUALITY = 5,             -- 棋子最大品质
        DEFAULT_STAGE_ID = 101,      -- 默认关卡ID
    },
    -- 格子特效类型（用于 _WasGridEffectPlayedInGroup / _MarkGridEffectPlayedInGroup）
    GridEffectType = {
        Countdown = "Countdown",
        Delete = "Delete",
        WeaponSkill = "WeaponSkill",
        Infection = "Infection",
        RoleEliminate = "RoleEliminate",
        BoxUpgrade = "BoxUpgrade",
    },
    -- UI 常量（XUiLuckyTenant2Game 等）
    UiConstants = {
        TIME_SCALE_SPEED_UP = 2,              -- 加速时的时间缩放倍率
        TIME_SCALE_NORMAL = 1,                 -- 正常时间缩放
        SCHEDULE_NEXT_STATE_DELAY_MS = 1000,  -- 状态切换定时器间隔（毫秒）
        ADD_SCORE_DISPLAY_DURATION_MS = 3000, -- 加分数飘字显示时长（毫秒）
        SHAKE_ANIMATION_DURATION = 0.15,      -- 晃动动画时长（秒）
        SHAKE_SCALE_FACTOR = 1.1,             -- 晃动时缩放系数
        HIGHLIGHT_ANIMATION_DURATION = 0.2,   -- 高亮动画时长（秒）
        HIGHLIGHT_SCALE_FACTOR = 1.15,        -- 高亮时缩放系数
        DELETE_ANIMATION_DURATION = 0.3,      -- 删除动画时长（秒）
    },
}

return XLuckyTenant2Enum

