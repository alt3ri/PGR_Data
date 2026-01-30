return {
    GRID = {
        NONE = 0, -- 空白格
        BASE = 1, -- 普通格子
        BULLET_COLOR_ONE = 2, -- 染色子弹
        COLOR_SCORE = 3, -- 染色后获得加分的格子
        END = 4, -- 终点
        BULLET_COLOR_THROUGH = 5, -- 染色子弹,穿透
        OBSTACLE = 6, -- 障碍格子
        BULLET_FILL = 7, -- 填补子弹
        END_FILL = 41, -- 终点-填充发射器
        END_COLOR_ONE = 42, -- 终点-染色发射器
        END_COLOR_THROUGH = 43, -- 终点-穿透染色发射器
    },
    OPERATION = {
        NONE = 0, -- do nothing
        CLICK = 1, -- 点击
        DRAG = 2, -- 拖动
        CONFIRM = 3, -- 松手确认
    },
    OPERATION_STATE = {
        NONE = 0,
        SUCCESS = 1,
        FAIL = 2,
    },
    ANIMATION = {
        NONE = 0,
        MOVE_GRID = 1,
        GROUP = 2,  -- 并列播放
        GRID_EAT = 3,
        COLOR = 4,
        WAIT = 5,
        GRID_ENABLE = 6,
        GROUP_LINE = 7, -- 有前后顺序的播放
        UPDATE_MAP = 8,
    },
    ANIMATION_STATE = {
        NONE = 0,
        PLAYING = 1,
        FINISH = 2,
    },
    CONDITION = {
        -- 分数达到指定分数
        SCORE = 10235,
        -- 完成的终点格数量
        END_AMOUNT = 10236,
    },
    ACTION = {
        NONE = 0,
        LINK_GRID = 1,
        EAT = 2,
        READY_SHOT = 3,
        SHOT = 4,
    },
    ACTION_STATE = {
        NONE = 0,
        PLAYING = 1,
        FINISH = 2,
    },
    SHOT_STATE = {
        NONE = 0,
        READY = 1,
        SHOT = 2,
    },
    COLOR = {
        NONE = 0,
        BLUE = 1,
        RED = 2,
        PURPLE = 3,
    },
    COLOR_ANIMATION = {
        NONE = 0,
        TO_RED_BLUE_SINGLE = "BrushEnable", --红蓝色单个染色动画
        TO_RED_BLUE_THROUGH = "PaintBrushEnable", --红蓝色穿透染色动画
        TO_PURPLE = "PurpleEnable", --单色染紫色
        PURPLE_TO_RED = "RedEnable", --紫色染红色
        PURPLE_TO_BLUE = "BlueEnable", --紫色染蓝色
    }
}
