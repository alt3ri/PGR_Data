local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")

-- 这是玩家的操作生成的一系列action
---@class XLineArithmetic2Action
local XLineArithmetic2Action = XClass(nil, "XLineArithmetic2Action")

function XLineArithmetic2Action:Ctor()
    self._Type = XLineArithmetic2Enum.ACTION.NONE
    self._State = XLineArithmetic2Enum.ACTION_STATE.NONE
    ---@type XLineArithmetic2OperationRecord
    self._Record = false
end

function XLineArithmetic2Action:Execute()
    self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
end

function XLineArithmetic2Action:IsFinish()
    return self._State == XLineArithmetic2Enum.ACTION_STATE.FINISH
end

function XLineArithmetic2Action:GetType()
    return self._Type
end

function XLineArithmetic2Action:SetRecord(record)
    self._Record = record
end

return XLineArithmetic2Action
