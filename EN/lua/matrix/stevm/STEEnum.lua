--- STEFramework 2.0 枚举常量集中定义
---
--- 形式化定义(规范#55):所有跨模块共享的枚举只在此文件定义一次,
--- 生产端与消费端都 require 本表,禁止各自硬编码数字。
---
---@class STEEnum
local STEEnum = {}

--- 数值变更方式:Effect 修改 Field 时采用哪种运算。
---@class STEEnum.ValChangeType
STEEnum.ValChangeType = {
    Set      = 1, -- 直接赋值
    Add      = 2, -- 加
    Subtract = 3, -- 减
    Multiply = 4, -- 乘
    Divide   = 5, -- 除(消费端需自行做除零保护)
}

--- 布尔/比较运算类型:Trigger 的判断算子。
---@class STEEnum.OpType
STEEnum.OpType = {
    And            = 1, -- 逻辑与
    Or             = 2, -- 逻辑或
    Equals         = 3, -- ==
    NotEquals      = 4, -- ~=
    Bigger         = 5, -- >
    BiggerOrEquals = 6, -- >=
    Smaller        = 7, -- <
    SmallerOrEquals= 8, -- <=
}

--- 框架内对象池类型
STEEnum.InnerPoolsKey = {
    BlackBoard = 1, -- 黑板数据
    ExecContext = 2, -- 调用上下文
    ModOp = 3, -- PropertyModifiedNum 运算队列项 {op,value,sourceId}（事务快照/回滚高频复用）
    DictSnap = 4, -- 字典型快照 copy（PropertyDict/Tags 快照 + ModifiedNum wrapper）
    ListSnap = 5, -- 数组型快照 copy（PropertyList 快照 + ModifiedNum ops 数组）
}

return STEEnum
