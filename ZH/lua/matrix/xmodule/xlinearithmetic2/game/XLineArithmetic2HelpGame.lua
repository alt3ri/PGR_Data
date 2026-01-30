local XLineArithmetic2Game = require("XModule/XLineArithmetic2/Game/XLineArithmetic2Game")

---@class XLineArithmetic2HelpGame:XLineArithmetic2Game
local XLineArithmetic2HelpGame = XClass(XLineArithmetic2Game, "XLineArithmetic2HelpGame")

function XLineArithmetic2HelpGame:Ctor()
    self._IsOnline = false
end

-----@param model XLineArithmetic2Model
--function XLineArithmetic2HelpGame:Update(model)
--    ---@type XLineArithmetic2Action
--    local action = self._ActionList:Dequeue()
--    if not action then
--        return false
--    end
--    --self:Execute(model)
--    --self:ExecuteEat(model)
--    return true
--end

return XLineArithmetic2HelpGame
