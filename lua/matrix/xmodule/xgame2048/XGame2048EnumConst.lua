--- 2048玩法活动 玩法内部使用的枚举定义
local XGame2048EnumConst = {
    --- 关卡类型
    StageType = {
        Normal = 1, --普通关
        Endless = 2, --无尽关
    },
    --- 结算类型
    SettleType = {
        StepEmpty = 1,
        CannotMove = 2,
        Reset = 3,
        ByHand = 4,
    },
    --- 格子类型
    GridType = {
        FeverTurnAdds = 1, -- 加时方块
        ICE = 2, -- 冰块方块，不可移动但可参与同分合成
        Transfer = 3, -- 传导方块
        Normal = 4, -- 数字方块
        Doubling = 5, -- 翻倍方块，合成后十字方向数值翻倍
        Star = 6, -- 星星方块，任意合成
        Rock = 7,
        Dispel = 8, -- 3期新增消除方块，核心方块
        Transmit = 9, -- 3期新增传送方块，针对核心方块
        HeartShape = 10, -- 心形方块，针对核心方块
        Water = 11, -- 水方块
        Fire = 12, -- 火方块
    },
    -- 行为队列类型
    ActionType = {
        None = 1,
        NormalMove = 2,
        NormalMerge = 3,
        NormalDispel = 4, -- 分数格子消除
        RockReduce = 5, -- 石头计数减小
        NormalReduce = 6, -- 分数方块降级
        NewBlockBorn = 7, --新方块生成
        RockShake = 8, -- 石头被撞击震动
        FeverLevelUp = 9, -- fever等级提升
        NormalLevelUp = 10, -- 数字方块(被翻倍效果）升级
        TransferLevelUp = 11, -- 传导方块升级
        ICELevelUp = 12, -- 冰块升级
        FeverUpLevelUp = 13, -- 加时方块升级
        FeverLevelUpCheck = 14, -- 盘面升级检查
        DispelGridDirectionChanged = 15, -- 消除方块方向改变
        GridChanged = 16, -- 通用方块变更, 时机在ferver等级提升之后
        GridChangedAfterMerge = 17, -- 通用方块变更，时机是合并之后
        GridChangedAfterDoubleLevelUp = 18, -- 通用方块变更，时机是在各种翻倍效果执行之后
        OpenDispelRangeEffect = 19, -- 打开消除范围特效，与消除操作同时
        CloseDispelRangeEffect = 20, -- 关闭消除范围特效，在消除操作之后
    },
    -- 行为队列优先级，相同优先级的将会在同一时刻执行, 优先级数越小的最先执行
    -- key: 对应ActionType里的枚举值
    ActionPriority = {
        [1] = 1,
        [2] = 2, -- 移动
        [3] = 3, -- 合并
        [8] = 3, -- 石头被撞击震动
        [15] = 3, -- 消除方块方向改变
        [17] = 4, -- 通用方块变更，时机是合并之后
        [10] = 4, -- 数字方块(被翻倍效果）升级
        [12] = 4, -- 冰块（被翻倍效果）升级
        [13] = 4, -- 加时方块（被翻倍效果）升级
        [11] = 5, -- 传导方块升级
        [18] = 5, -- 通用方块变更，时机是在各种翻倍效果执行之后
        [7] = 6, -- 新方块生成
        [5] = 7, -- 分数降级
        [6] = 7, -- 石头降级
        [4] = 8, -- 消除
        [9] = 8, -- fever等级提升
        [19] = 8, -- 打开消除范围特效
        [14] = 9, -- 盘面升级检查
        [16] = 9, -- 通用方块变更
        [20] = 9, -- 关闭消除范围特效
    },
    
    -- 角色模型动作优先级
    -- 排在前面的优先
    ShowActionPriority = {
        Star = 10,
        Bomb = 20,
        Rock = 30,
        Remove = 40,
        Buff = 50,
        Item = 60,
    },
    -- 引导滑动方向
    DragDirectionByGuide = {
        Up = 1,
        Down = 2,
        Left = 3,
        Right = 4
    },
    -- 模型动画事件类型
    BoardShowConditionType = {
        NoOperationStayTime = 1, -- 无操作时长
        TargetGridMerge = 2, -- 合成目标方块
        FeverLevelUp = 3, -- fever等级提升
    },
    
    -- 合成效果类型
    MergeEffectType = {
        Doubling = 1, -- 周围四个方向的数字、传导方块升级
        Transfer = 2, -- 周围四个方向的传导方块升级
    },
    
    -- 消除方块的方向
    GridDispelDirection = {
        Up = 1,
        Down = 2,
        Left = 3,
        Right = 4,
    },
    
    --- 消除方块升级消除规则
    GridDispelCleanUpRule = {
        DiretionOnly = 0, -- 根据方向进行消除
        WaterFireSelect = 1, -- 水火方块选择
    },
    
    --- 游戏状态
    GameState = {
        None = 0,
        WaterFireSelection = 1,
    },
    
    --- Buff类型, 与服务端枚举一致
    BuffType = {
        GenTypeBlock = 1, -- 生成特定类型方块
        ReplaceTypeBlock = 2, -- 替换为特定类型块
        ClientShow = 3, -- 纯客户端显示
    }
}

return XGame2048EnumConst