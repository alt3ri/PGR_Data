local XLifeTreeEnumConst = {}

-- 卡牌类型
XLifeTreeEnumConst.CARD_TYPE = {
    DIVINE = 1,     -- 神卡
    REGULAR = 2,    -- 普卡
    BASIC = 3,      -- 基础卡
}

-- 神卡解锁流程类型
XLifeTreeEnumConst.DIVINE_UNLOCK_PROCESS_TYPE = {
    POSITIVE = 1,           -- 正神卡
    POSITIVE_REVERSE = 2,   -- 正神卡，转逆神卡
}

-- 神卡类型
XLifeTreeEnumConst.DIVINE_TYPE = {
    UNLOCK = 0,             -- 未解锁
    POSITIVE = 1,           -- 正神卡
    REVERSE = 2,            -- 逆神卡
}
-- XUiLifeTreeCard神卡类型对应的背景动画
XLifeTreeEnumConst.DIVINE_TYPE_TO_UI_CARD_BG_ANIM = {
    [XLifeTreeEnumConst.DIVINE_TYPE.UNLOCK] = "AnimEnableBlue",
    [XLifeTreeEnumConst.DIVINE_TYPE.POSITIVE] = "AnimEnableBlue",
    [XLifeTreeEnumConst.DIVINE_TYPE.REVERSE] = "AnimEnableRed",
}

-- 神卡解锁流程对应的神卡类型配置
XLifeTreeEnumConst.DIVINE_UNLOCK_PROCESS_TO_TYPE = {
    [XLifeTreeEnumConst.DIVINE_UNLOCK_PROCESS_TYPE.POSITIVE] = { XLifeTreeEnumConst.DIVINE_TYPE.POSITIVE },
    [XLifeTreeEnumConst.DIVINE_UNLOCK_PROCESS_TYPE.POSITIVE_REVERSE] = { XLifeTreeEnumConst.DIVINE_TYPE.POSITIVE, XLifeTreeEnumConst.DIVINE_TYPE.REVERSE },
}

-- 角色状态
XLifeTreeEnumConst.CHARACTER_STATE = {
    OFFLINE = 1,            -- 未上线
    NEXT_LOCKED = 2,        -- 下一状态解锁条件未满足
    NEXT_UNLOCKABLE = 3,    -- 可解锁下一状态
}

-- 记录操作类型
XLifeTreeEnumConst.PROCESS_TYPE = {
    GUIDE = 1,      -- 引导
    PV = 2,         -- PV
    CHAPTER = 3,    -- 章节弹窗
}

return XLifeTreeEnumConst