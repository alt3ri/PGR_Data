---@class XPunishaarEnum
local XPunishaarEnum = {}


--- 卡牌类型(小类）[与配置一致]
XPunishaarEnum.CardType = {
    Character = 1, -- 角色
    Weapon = 2, -- 武器
    Awareness = 3, -- 意识
    Resonance = 4, -- 共鸣
}

--- 卡牌类型（大类）[代码使用枚举]
XPunishaarEnum.CarMainType = {
    Main = 1, -- 主卡
    Sub = 2, -- 副卡
}

--- 详情 Tips 展示对象类型（TipsRoot 路由用）
XPunishaarEnum.TipsType = {
    MainCard = 1,  -- 主卡详情
    SubCard  = 2,  -- 副卡详情
    Enemy    = 3,  -- 敌人详情
}

--- 副卡小类 → 允许装配的主卡小类（静态映射，装配落点校验用）。
--- 当前为硬编码对应关系；将来若改为配置驱动，只需换掉 Agency:GetSubCardHostCardType 的取值来源。
XPunishaarEnum.SubCardHostCardType = {
    [XPunishaarEnum.CardType.Awareness] = XPunishaarEnum.CardType.Character,  -- 意识 → 角色
    [XPunishaarEnum.CardType.Resonance] = XPunishaarEnum.CardType.Weapon,     -- 共鸣 → 武器
}

--- 卡牌所在区域（对应服务端 XPunishaarCardAreaType）
XPunishaarEnum.CardAreaType = {
    FightArea = 1,  -- 对战区（BattleArea）
    Bag = 2,        -- 背包
}

--- 状态图标下标（PunishaarClientConfig.BuffIcons 的 Values 下标；纯客户端显示用）
--- 护盾非 buff 但与 buff 共用图标预制与同一列表，故图标配置收在同一 key 下。
XPunishaarEnum.BuffIconIndex = {
    Shield   = 1,  -- 护盾（免伤次数，敌我双方共用）
    EnemyDot = 2,  -- 敌人持续受伤（仅敌人，DoT buff 图标）
}

--- 节点类型（对应服务端 XPunishaarNodeType）
XPunishaarEnum.NodeType = {
    Shop        = 1,  -- 商店节点（ShopNode）
    Event       = 2,  -- 事件节点（EventNode）
    Fight       = 3,  -- 普通战斗节点（FightNode）
    ChoiceFight = 4,  -- 机制选择战斗节点（SelectFightNode）
    Story       = 5,  -- 剧情节点（AvgNode）
}

--- 局内界面状态（UiPunishaarFightMain 的 state 参数）
--- 服务端→FightState 映射统一在 XPunishaarRunControl.ServerNodeToFightState 维护；
--- 该枚举本身不随联调变化，只通过改映射表调整入口状态。
XPunishaarEnum.FightState = {
    Base = 0,     -- 基底态：FightMain 常驻 UI 基底，显背包允许编排（二选一/Event/Story 节点 + NormalPop 叠其上不穿帮）#66
    Shopping = 1,  -- 商店节点
    PreFight = 2,  -- 战前准备（战斗节点进入时的初始状态）
    Fighting = 3,  -- 战斗中
}

--- 节点状态（对应服务端 XPunishaarNodeStatus）
XPunishaarEnum.NodeStatus = {
    None          = 0,  -- 未初始化（新建节点默认值）
    WaitSelect    = 1,  -- 待选择（选择战斗未选定战斗 / 多候选事件未选定）
    Processing    = 2,  -- 进行中（商店/剧情进入即为此状态；战斗/事件选定后进入）
    Remedy        = 3,  -- 补强中（战斗失败耐久未归零，进入补强商店）
    RewardReplace = 4,  -- 奖励替换中（战斗胜利/事件完成后待玩家确认替换卡牌）
    Finished      = 5,  -- 已完成（满足 ExitNode 条件；商店/剧情不经此状态）
    Exited        = 6,  -- 已退出（归档到历史节点列表）
    WaitSelectShop = 7, -- 商店待选择
}

--- 奖励类型（对应服务端 XPunishaarRewardType）
XPunishaarEnum.RewardType = {
    None               = 0,
    MasterCard         = 1,  -- 主卡
    SubCard            = 2,  -- 副卡
    Gold               = 3,  -- 金币
    MaxHp              = 4,  -- 最大血量
    FightAreaGridLimit = 5,  -- 对战区槽位解锁
    BagGridLimit       = 6,  -- 背包槽位解锁
    
    
    Durability         = 101,  -- 耐久/存续值（客户端自造显示用：失败扣减耐久；非服务端 XPunishaarRewardType 类型，不走网络 marshal）
}

--- 结算类型（对应服务端 XPunishaarSettleType）
XPunishaarEnum.SettleType = {
    Finished      = 1,  -- 通关（走完全部节点）
    DurabilityEnd = 2,  -- 耐久耗尽结束
    Quit          = 3,  -- 主动退出
}

--- 关卡类型（对应 StageGroup.Type 配置字段）
XPunishaarEnum.StageType = {
    Normal  = 1,  -- 普通关
    Endless = 2,  -- 无尽关（挑战记录/破纪录模块仅此类型显示）
}

--- 关卡状态（局外关卡列表显示用）
XPunishaarEnum.StageStatus = {
    NotOpen = 0,  -- 未开启
    Opened  = 1,  -- 已开启
    HasSave = 2,  -- 有存档
    Passed  = 3,  -- 已通关
}

--- 图鉴分类（卡牌图鉴目录，对应服务端 CatalogType；与卡牌类型 CardType 不同）
XPunishaarEnum.CatalogType = {
    None      = 0,  -- 无
    Character = 1,  -- 角色
    Partner   = 2,  -- 辅助机
    Equip     = 3,  -- 意识
    Resonance = 4,  -- 共鸣
}

return XPunishaarEnum