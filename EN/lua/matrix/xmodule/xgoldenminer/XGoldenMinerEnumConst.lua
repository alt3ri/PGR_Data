local EnumConst = {
    --- 改造物品类型
    ItemTypeInShop = {
        Hex = 1,
        Update = 2,
    },
    
    --- 物品选择显示类型
    ItemShowType = {
        CoreHex = 1,
        Update = 2,
        CommonHex = 3,
    },
    
    --- 海克斯类型
    HexType = {
        Core = 1,
        Common = 2
    },
    
    --- 游戏阶段
    GameState = {
        None = 0,
        CoreHexSelect = 1, -- 海克斯选择/升级阶段
        CommonHexSelect = 2, -- 通用buff选择阶段
    },

    --- 电磁链接可同步的状态类型(值与资源类型枚举值一致）
    GameLinkStoneCanSyncStates = {
        [3] = true, -- 被抓住
        [4] = true, -- 已被抓
        [8] = true, -- (Partner)被小飞碟瞄准
        [9] = true, -- (Partner)被小飞碟收取中
    },
    
    --- 弹网钩爪抓取重量计算规则
    NETHOOK_WEIGHTRULE = {
        OnlyOneMaxWeight = 1,
        OnlyOneMinWeight = 2,
    },
    
    DebuggerLogType = {
        GrabScore = 1, -- 抓取物抓取时的分数日志
        HookSpeed = 2, -- 钩爪速度日志
        StoneWeight = 3, -- 抓取物重量
        ShipMoveSpeed = 4, -- 飞船移动速度
    }
}

return EnumConst