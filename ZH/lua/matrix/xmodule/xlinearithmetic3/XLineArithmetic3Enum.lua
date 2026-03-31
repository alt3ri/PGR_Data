---@class XLineArithmetic3Enum
local XLineArithmetic3Enum = {}

--- 格子类型
XLineArithmetic3Enum.GridType = {
    Start = 1,      -- 起点格
    End = 2,        -- 终点格
    ExtraEnd = 3,   -- 额外终点格
    Passenger = 4,  -- 乘客格
    Station = 5,    -- 车站格
    Obstacle = 6,   -- 障碍格
    Character = 10, -- 角色格（车头）
}

--- 颜色（白色可被染色）
XLineArithmetic3Enum.Color = {
    White = 0,
    -- 其他颜色由配置表定义，如 1, 2, 3...
}

--- 附近方向优先级：上、左、下、右（用于车站取色、上下车遍历）
XLineArithmetic3Enum.Direction = {
    Up = 1,
    Left = 2,
    Down = 3,
    Right = 4,
}

--- 播放指令类型（供 UI 播放动画）
XLineArithmetic3Enum.Instruction = {
    MoveHead = 1,       -- 车头移动到某格
    Board = 2,          -- 乘客上车（格子索引，车厢索引，乘客颜色）
    Disembark = 3,      -- 乘客下车（格子索引，车厢索引，乘客颜色）
    ActivateEnd = 4,    -- 激活终点格（格子索引）
    DyePassenger = 5,   -- 乘客被染色（车厢索引，新颜色）
    DyeStationPassenger = 6, -- 车站乘客被染色（格子坐标，新颜色）
    StationColorChanged = 7, -- 车站颜色变更（格子坐标，新颜色）
    ChangePassengerEmoj = 8, -- 修改乘客表情（格子坐标/车厢索引，表情类型）
}

-- 表情
XLineArithmetic3Enum.Emoj = {
    -- 初始表情
    Initial = 1,
    -- 准备上车
    ReadyToBoard = 2,
    -- 上车之后
    AfterBoard = 3,
    -- 到颜色1的终点
    ToColor1End = 4,
    -- 到颜色2的终点
    ToColor2End = 5,
    -- 到颜色3的终点
    ToColor3End = 6,
    -- 到颜色4的终点
    ToColor4End = 7,
    -- 到颜色5的终点
    ToColor5End = 8,
    -- 到颜色6的终点
    ToColor6End = 9,
    -- 到最终终点
    ToFinalEnd = 10
}

-- 条件
XLineArithmetic3Enum.CONDITION = {
    -- 完成指定终点(指定Cell的终点被完成, params[1] = cellId)
    COMPLETE_END = 10229,  -- 完成指定终点

    -- 完成的终点格数量(params[1] = 完成的终点格数量)
    COMPLETE_END_AMOUNT = 10236, -- 完成的终点格数量
}

--- Undo 动画时长（秒），控制所有命令回退时 tween 的 duration
XLineArithmetic3Enum.UndoDuration = 0.1

--- 路径方向类型（用于显示路径格子的方向，区分来向去向）
XLineArithmetic3Enum.PathDirection = {
    -- 直线方向（4个）
    LeftToRight = 1,    -- 自左向右 →
    RightToLeft = 2,    -- 自右向左 ←
    UpToDown = 3,       -- 自上而下 ↓
    DownToUp = 4,       -- 自下而上 ↑
    -- 转弯方向（8个）
    TurnFromUpToLeft = 5,    -- 从上往左转 ┘
    TurnFromUpToRight = 6,   -- 从上往右转 └
    TurnFromDownToLeft = 7,  -- 从下往左转 ┐
    TurnFromDownToRight = 8, -- 从下往右转 ┌
    TurnFromLeftToUp = 9,    -- 从左往上转 ┘
    TurnFromLeftToDown = 10, -- 从左往下转 ┐
    TurnFromRightToUp = 11,  -- 从右往上转 └
    TurnFromRightToDown = 12,-- 从右往下转 ┌
}

return XLineArithmetic3Enum
