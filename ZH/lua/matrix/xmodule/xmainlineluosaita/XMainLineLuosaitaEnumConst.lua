local XMainLineLuosaitaEnumConst = {
    FIRST_SECTION_ID = 1,       -- 第一个阶段Id
    -- 阶段状态
    SECTION_STATUS = {
        ONGOING = 0,    -- 进行中
        FINISH = 1,     -- 已通过
    },
    -- 块状态
    BLOCK_STATUS = {
        NONE = 0,     -- 未占领
        OCCUPIED = 1, -- 已占领
    },
    -- 位置类型
    POS_TYPE = {
        ARMY = 1,       -- 我军
        ENEMY = 2,      -- 敌军
        CHARACTER = 3,  -- 角色
        STAGE = 4,      -- 关卡
        EMPTY = 5,      -- 空节点
    },
    -- 讲话类型
    TALK_TYPE = {
        NONE = 0,
        NORMAL = 1,
        INFO = 2,
        WARNING = 3,
    },
    -- 文件类型
    DOCUMENT_TYPE = {
        STORY = 1,          -- 叙事文件
        ITEM = 2,           -- 提升道具
        ASSIST_ARMY = 3,    -- 支援军队
    },
}

return XMainLineLuosaitaEnumConst
