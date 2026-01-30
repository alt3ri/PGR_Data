local XLineArithmetic2Enum = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Enum")
local XLineArithmetic2Action = require("XModule/XLineArithmetic2/Game/Action/XLineArithmetic2Action")

---@class XLineArithmetic2ActionCancelSelect: XLineArithmetic2Action
local XLineArithmetic2ActionCancelSelect = XClass(XLineArithmetic2Action, "XLineArithmetic2ActionCancelSelect")

function XLineArithmetic2ActionCancelSelect:Ctor()
    self._Type = XLineArithmetic2Enum.ACTION.CANCEL_SELECT
end

---@param game XLineArithmetic2Game
---@param model XLineArithmetic2Model
function XLineArithmetic2ActionCancelSelect:Execute(game, model)
    self._State = XLineArithmetic2Enum.ACTION_STATE.FINISH
    game:ClearLineGridList()
end

return XLineArithmetic2ActionCancelSelect
