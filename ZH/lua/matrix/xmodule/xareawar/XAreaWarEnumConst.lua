local XAreaWarEnumConst = {
    MAX_ORDER_NUM = 100,        -- 最大订单数量
    -- 订单购买结果
    AUCTION_BUY_RESULT_TYPE = {
        SUCCESS = 0,            -- 成功购买
        COUNT_LIMIT = 1,        -- 数量不足
        PRICE_CHANGE = 2,       -- 价格变化
    },
    SUBMIT_NUM = 1,             -- 提交珍稀道具需要的数量
    -- 服务器交易行挂了，请求协议的间隔时间
    SERVER_BREAK_RPC_OFFSET_TIEM = 5,
    ORIGIN_PROBABILITY = 100,   -- 初始概率
    ITEM_EFFECT_TYPE = {
        USING_EFFECT = 1,
        GLOBAL_EFFECT = 2,
    },
    -- 出售提示类型
    SELL_TIPS_TYPE = {
        NONE = 0,
        KEEP_ONE = 1, -- 保留最少一个
        UN_SUBMIT = 2, -- 未提交点亮的珍稀藏品
    },
    -- 提升道具掉落概率的生效道具最低品质
    SHOW_PROBABILITY_MIN_QUALITY = 4,
    -- 道具品质
    ITEM_QUALITY = {
        GREEN = 1,
        BLUE = 2,
        PURPLE = 3,
        GOLD = 4,
        RED = 5,
    },
}

return XAreaWarEnumConst
