--- STEFramework 2.0 共享纯数值运算 ValueOp
---
--- 角色(运算语义收口):全框架「一个旧值 op 一个运算数」的算术只有这一处实现。
---   PropertyModifiedNum 的有序队列应用、未来 VM 的 Store 写运算都复用本函数,
---   保证除法方向、各算子语义全框架单一来源(不再重复 1.0 写反的隐患)。
---
--- 纯函数(读纯净):无副作用、不报错、不发事件、不读写任何外部状态;
---   非法运算(除零、未知 op)以返回 nil 表达,由调用方决定如何处置(报错/拒绝写入)。
---
--- require('STEVM/Engine/ValueOp')
local STEEnum = require('STEVM/STEEnum')

local ValChangeType = STEEnum.ValChangeType

---@class ValueOp
local ValueOp = {}

--- 对一个旧值施加一次运算。纯数学:这些是字段数值的代数运算。
---   Set      = operand              直接赋值,忽略旧值
---   Add      = oldVal + operand     加
---   Subtract = oldVal - operand     减
---   Multiply = oldVal * operand     乘(直乘,不是 ×(1+v))
---   Divide   = oldVal / operand     除(★ 被除数是旧值、除数是 operand;修正 1.0 写反的方向)
---                                    operand == 0 → 返回 nil(非法,避免 inf/nan 污染)
---   未知 opType → 返回 nil。
---@param oldVal number 运算前的值
---@param opType number STEEnum.ValChangeType
---@param operand number 运算数
---@return number|nil newVal 运算结果;非法运算(除零/未知 op)返回 nil
function ValueOp.Apply(oldVal, opType, operand)
    if opType == ValChangeType.Set then
        return operand
    elseif opType == ValChangeType.Add then
        return oldVal + operand
    elseif opType == ValChangeType.Subtract then
        return oldVal - operand
    elseif opType == ValChangeType.Multiply then
        return oldVal * operand
    elseif opType == ValChangeType.Divide then
        -- 除法方向:newVal = oldVal / operand(被除数=旧值,除数=运算数)。
        -- operand==0 返回 nil:除零非法,交由调用方拒绝/报错,不在此处崩或发事件。
        if operand == 0 then
            return nil
        end
        return oldVal / operand
    end
    -- 未知 op:返回 nil,由调用方判定为非法运算。
    return nil
end

return ValueOp
